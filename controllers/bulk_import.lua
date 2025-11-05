-- Bulk Import Controller
-- 批量导入用户功能

local util = require('lib.util')
local db = require('lapis.db')
local Users = package.loaded.Users
local ClassMemberships = package.loaded.ClassMemberships
local Collections = package.loaded.Collections
local BulkImportLogs = package.loaded.BulkImportLogs

local BulkImportController = {}

-- 教师批量导入学生
-- POST /api/v1/teachers/bulk-import-students
-- 参数: class_id, csv_data
-- CSV格式: username,password,email,nickname,real_name (标题行可选)
function BulkImportController:bulk_import_students(self)
    assert_all({'teacher', 'admin'}, self.current_user)
    
    local class_id = tonumber(self.params.class_id)
    local csv_data = self.params.csv_data
    
    if not class_id or not csv_data then
        return errorResponse('缺少必要参数', 400)
    end
    
    -- 验证班级所有权（管理员可以操作所有班级）
    local class = Collections:find({ id = class_id })
    if not class then
        return errorResponse('班级不存在', 404)
    end
    
    if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
        return errorResponse('无权限操作此班级', 403)
    end
    
    -- 解析CSV
    local lines = util.parse_csv(csv_data)
    if #lines == 0 then
        return errorResponse('CSV数据为空', 400)
    end
    
    -- 判断第一行是否为标题行
    local headers = {'username', 'password', 'email', 'nickname', 'real_name'}
    local start_row = 1
    local first_line = lines[1]
    
    -- 简单判断：如果第一行包含"username"或"用户名"，则视为标题行
    if first_line[1] and (first_line[1]:lower():find('username') or first_line[1]:find('用户名')) then
        -- 使用CSV中的标题行
        headers = {}
        for _, col in ipairs(first_line) do
            local trimmed = col:match("^%s*(.-)%s*$"):lower()
            -- 支持中英文标题
            if trimmed == 'username' or trimmed == '用户名' then
                table.insert(headers, 'username')
            elseif trimmed == 'password' or trimmed == '密码' then
                table.insert(headers, 'password')
            elseif trimmed == 'email' or trimmed == '邮箱' then
                table.insert(headers, 'email')
            elseif trimmed == 'nickname' or trimmed == '昵称' then
                table.insert(headers, 'nickname')
            elseif trimmed == 'real_name' or trimmed == 'realname' or trimmed == '真实姓名' or trimmed == '姓名' then
                table.insert(headers, 'real_name')
            else
                table.insert(headers, trimmed)
            end
        end
        start_row = 2
    end
    
    -- 转换为用户对象
    local data_rows = {}
    for i = start_row, #lines do
        table.insert(data_rows, lines[i])
    end
    
    local users_data = util.csv_to_users(headers, data_rows, true)  -- true = 应用默认值
    
    local results = {
        total = #users_data,
        success = 0,
        failed = 0,
        errors = {}
    }
    
    -- 批量创建用户并添加到班级
    for _, user_data in ipairs(users_data) do
        local success, err = pcall(function()
            -- 验证必填字段
            if not user_data.username or user_data.username == '' then
                error('用户名不能为空')
            end
            if not user_data.password or user_data.password == '' then
                error('密码不能为空')
            end
            
            -- 生成默认邮箱（如果未提供）
            if not user_data.email or user_data.email == '' then
                user_data.email = user_data.username .. '@student.local'
            end
            
            -- 检查用户是否已存在
            local existing_user = Users:find({ username = user_data.username })
            local user
            
            if existing_user then
                -- 用户已存在，更新信息（如果提供了新的值）
                local updates = {}
                if user_data.nickname and user_data.nickname ~= '' then
                    updates.nickname = user_data.nickname
                end
                if user_data.real_name and user_data.real_name ~= '' then
                    updates.real_name = user_data.real_name
                end
                if user_data.email and user_data.email ~= '' then
                    updates.email = user_data.email
                end
                
                if next(updates) then
                    existing_user:update(updates)
                end
                user = existing_user
            else
                -- 创建新用户
                user = Users:create({
                    username = user_data.username,
                    password = user_data.password,
                    email = user_data.email,
                    nickname = user_data.nickname,
                    real_name = user_data.real_name,
                    role = 'student',
                    verified = true,
                    created = db.format_date()
                })
            end
            
            -- 检查是否已在班级中
            local existing_membership = ClassMemberships:find({
                class_id = class_id,
                student_id = user.id
            })
            
            if not existing_membership then
                -- 添加到班级
                ClassMemberships:create({
                    class_id = class_id,
                    student_id = user.id,
                    joined_at = db.format_date(),
                    is_active = true
                })
            end
            
            results.success = results.success + 1
        end)
        
        if not success then
            results.failed = results.failed + 1
            table.insert(results.errors, {
                row = user_data.row_number,
                username = user_data.username,
                error = tostring(err)
            })
        end
    end
    
    -- 记录导入日志
    BulkImportLogs:create({
        imported_by = self.current_user.id,
        import_type = 'teacher_students',
        total_count = results.total,
        success_count = results.success,
        failed_count = results.failed,
        error_details = db.encode_json(results.errors),
        imported_at = db.format_date()
    })
    
    return jsonResponse({
        success = true,
        results = results
    })
end

-- 管理员批量导入用户
-- POST /api/v1/admin/bulk-import-users
-- 参数: csv_data
-- CSV格式: username,password,email,nickname,real_name,role (标题行可选)
function BulkImportController:bulk_import_users(self)
    assert_admin(self.current_user)
    
    local csv_data = self.params.csv_data
    
    if not csv_data then
        return errorResponse('缺少CSV数据', 400)
    end
    
    -- 解析CSV
    local lines = util.parse_csv(csv_data)
    if #lines == 0 then
        return errorResponse('CSV数据为空', 400)
    end
    
    -- 判断第一行是否为标题行
    local headers = {'username', 'password', 'email', 'nickname', 'real_name', 'role'}
    local start_row = 1
    local first_line = lines[1]
    
    if first_line[1] and (first_line[1]:lower():find('username') or first_line[1]:find('用户名')) then
        headers = {}
        for _, col in ipairs(first_line) do
            local trimmed = col:match("^%s*(.-)%s*$"):lower()
            if trimmed == 'username' or trimmed == '用户名' then
                table.insert(headers, 'username')
            elseif trimmed == 'password' or trimmed == '密码' then
                table.insert(headers, 'password')
            elseif trimmed == 'email' or trimmed == '邮箱' then
                table.insert(headers, 'email')
            elseif trimmed == 'nickname' or trimmed == '昵称' then
                table.insert(headers, 'nickname')
            elseif trimmed == 'real_name' or trimmed == 'realname' or trimmed == '真实姓名' or trimmed == '姓名' then
                table.insert(headers, 'real_name')
            elseif trimmed == 'role' or trimmed == '角色' or trimmed == '权限' then
                table.insert(headers, 'role')
            else
                table.insert(headers, trimmed)
            end
        end
        start_row = 2
    end
    
    -- 转换为用户对象
    local data_rows = {}
    for i = start_row, #lines do
        table.insert(data_rows, lines[i])
    end
    
    local users_data = util.csv_to_users(headers, data_rows, true)
    
    local results = {
        total = #users_data,
        success = 0,
        failed = 0,
        errors = {}
    }
    
    -- 批量创建/更新用户
    for _, user_data in ipairs(users_data) do
        local success, err = pcall(function()
            -- 验证必填字段
            if not user_data.username or user_data.username == '' then
                error('用户名不能为空')
            end
            if not user_data.password or user_data.password == '' then
                error('密码不能为空')
            end
            
            -- 生成默认邮箱
            if not user_data.email or user_data.email == '' then
                user_data.email = user_data.username .. '@user.local'
            end
            
            -- 验证并规范化角色
            local role = 'student'  -- 默认角色
            if user_data.role and user_data.role ~= '' then
                local role_lower = user_data.role:lower()
                -- 支持中英文角色名
                if role_lower == 'admin' or role_lower == '管理员' then
                    role = 'admin'
                elseif role_lower == 'teacher' or role_lower == '教师' then
                    role = 'teacher'
                elseif role_lower == 'moderator' or role_lower == '版主' then
                    role = 'moderator'
                elseif role_lower == 'student' or role_lower == '学生' then
                    role = 'student'
                elseif role_lower == 'standard' or role_lower == '标准' then
                    role = 'standard'
                else
                    error('无效的角色: ' .. user_data.role)
                end
            end
            
            -- 检查用户是否已存在
            local existing_user = Users:find({ username = user_data.username })
            
            if existing_user then
                -- 更新现有用户
                local updates = {}
                if user_data.nickname and user_data.nickname ~= '' then
                    updates.nickname = user_data.nickname
                end
                if user_data.real_name and user_data.real_name ~= '' then
                    updates.real_name = user_data.real_name
                end
                if user_data.email and user_data.email ~= '' then
                    updates.email = user_data.email
                end
                updates.role = role
                
                existing_user:update(updates)
            else
                -- 创建新用户
                Users:create({
                    username = user_data.username,
                    password = user_data.password,
                    email = user_data.email,
                    nickname = user_data.nickname,
                    real_name = user_data.real_name,
                    role = role,
                    verified = true,
                    created = db.format_date()
                })
            end
            
            results.success = results.success + 1
        end)
        
        if not success then
            results.failed = results.failed + 1
            table.insert(results.errors, {
                row = user_data.row_number,
                username = user_data.username,
                error = tostring(err)
            })
        end
    end
    
    -- 记录导入日志
    BulkImportLogs:create({
        imported_by = self.current_user.id,
        import_type = 'admin_users',
        total_count = results.total,
        success_count = results.success,
        failed_count = results.failed,
        error_details = db.encode_json(results.errors),
        imported_at = db.format_date()
    })
    
    return jsonResponse({
        success = true,
        results = results
    })
end

return BulkImportController
