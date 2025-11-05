-- Class Management Controller
-- ===========================
-- 班级管理控制器

local cjson = require("cjson")
local db = package.loaded.db
local yield_error = package.loaded.yield_error
local capture_errors = package.loaded.capture_errors

local Users = package.loaded.Users
local Collections = package.loaded.Collections
local ClassMemberships = package.loaded.ClassMemberships

-- 辅助函数：通过 ID 查找班级
-- Collections 的主键是 (creator_id, name)，不是 id
-- 所以需要显式指定 id 字段来查询
local function find_class_by_id(class_id)
    return Collections:select('WHERE id = ? AND is_class = true LIMIT 1', tonumber(class_id))[1]
end

ClassController = {
    -- 创建班级
    create_class = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        if not self.current_user.is_teacher then
            yield_error('只有教师可以创建班级')
        end
        
        local name = self.params.name
        if not name or name == '' then
            yield_error('班级名称不能为空')
        end
        
        -- 创建班级
        local class = Collections:create({
            name = name,
            description = self.params.description or '',
            creator_id = self.current_user.id,
            is_class = true,
            created_at = db.raw("now()"),
            updated_at = db.raw("now()")
        })
        
        return jsonResponse({ success = true, class = class })
    end),
    
    -- 获取班级列表
    list_classes = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        if not self.current_user.is_teacher and not self.current_user:isadmin() then
            yield_error('只有教师可以查看班级')
        end
        
        -- 管理员可以查看所有班级，教师只能查看自己的班级
        local classes
        if self.current_user:isadmin() then
            classes = Collections:select(
                'WHERE is_class = true ORDER BY created_at DESC'
            )
        else
            classes = Collections:select(
                'WHERE creator_id = ? AND is_class = true ORDER BY created_at DESC',
                self.current_user.id
            )
        end
        
        for _, class in ipairs(classes) do
            local stats = db.query([[
                SELECT * FROM class_stats WHERE class_id = ?
            ]], class.id)[1]
            
            class.stats = stats or {
                active_student_count = 0,
                total_student_count = 0,
                published_assignment_count = 0,
                total_assignment_count = 0
            }
        end
        
        -- 确保空数组被正确序列化为 JSON 数组而不是对象
        if #classes == 0 then
            classes = cjson.empty_array
        end
        
        return jsonResponse({ success = true, classes = classes })
    end),
    
    -- 获取班级详情
    get_class = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local class = find_class_by_id(self.params.id)
        if not class then
            yield_error('班级不存在')
        end
        
        -- 管理员可以查看所有班级，教师只能查看自己的班级
        if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
            yield_error('无权查看此班级')
        end
        
        local stats = db.query([[
            SELECT * FROM class_stats WHERE class_id = ?
        ]], class.id)[1]
        
        class.stats = stats
        
        return jsonResponse({ success = true, class = class })
    end),
    
    -- 更新班级
    update_class = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local class = find_class_by_id(self.params.id)
        if not class then
            yield_error('班级不存在')
        end
        
        -- 管理员可以编辑所有班级
        if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
            yield_error('无权编辑此班级')
        end
        
        local updates = { updated_at = db.raw("now()") }
        
        if self.params.name then
            updates.name = self.params.name
        end
        
        if self.params.description ~= nil then
            updates.description = self.params.description
        end
        
        class:update(updates)
        
        return jsonResponse({ success = true, class = class })
    end),
    
    -- 删除班级
    delete_class = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local class = find_class_by_id(self.params.id)
        if not class then
            yield_error('班级不存在')
        end
        
        -- 管理员可以删除所有班级
        if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
            yield_error('无权删除此班级')
        end
        
        -- 检查是否有作业
        local Assignments = package.loaded.Assignments
        local assignments_count = Assignments:count('collection_id = ? AND deleted = false', class.id)
        
        if assignments_count > 0 then
            yield_error('该班级还有作业，无法删除')
        end
        
        -- 删除所有成员
        db.query([[
            UPDATE class_memberships 
            SET deleted_at = now() 
            WHERE class_id = ? AND deleted_at IS NULL
        ]], class.id)
        
        class:delete()
        
        return jsonResponse({ success = true })
    end),
    
    -- 获取班级成员列表
    list_class_members = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local class = find_class_by_id(self.params.id)
        if not class then
            yield_error('班级不存在')
        end
        
        -- 管理员可以查看所有班级成员
        if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
            yield_error('无权查看此班级成员')
        end
        
        local members = db.query([[
            SELECT * FROM class_members_detail
            WHERE class_id = ?
            ORDER BY student_username
        ]], class.id)
        
        return jsonResponse({ success = true, members = members })
    end),
    
    -- 添加学生到班级
    add_class_member = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local class = find_class_by_id(self.params.id)
        if not class then
            yield_error('班级不存在')
        end
        
        -- 管理员可以管理所有班级成员
        if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
            yield_error('无权添加成员')
        end
        
        local student_id = tonumber(self.params.student_id)
        if not student_id then
            yield_error('请提供有效的学生ID')
        end
        
        local student = Users:find(student_id)
        if not student then
            yield_error('学生不存在')
        end
        
        local membership, err = ClassMemberships:add_student(
            class.id,
            student_id,
            { student_note = self.params.student_note }
        )
        
        if err == 'already_exists' then
            return jsonResponse({ success = true, already_exists = true, membership = membership })
        end
        
        return jsonResponse({ success = true, membership = membership })
    end),
    
    -- 批量添加学生到班级
    batch_add_class_members = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local class = find_class_by_id(self.params.id)
        if not class then
            yield_error('班级不存在')
        end
        
        -- 管理员可以管理所有班级成员
        if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
            yield_error('无权添加成员')
        end
        
        local student_ids = self.params.student_ids
        if not student_ids or type(student_ids) ~= 'table' then
            yield_error('请提供学生ID列表')
        end
        
        local results = ClassMemberships:add_students(class.id, student_ids)
        
        return jsonResponse({ success = true, results = results })
    end),
    
    -- 移除班级成员
    remove_class_member = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local class = find_class_by_id(self.params.id)
        if not class then
            yield_error('班级不存在')
        end
        
        -- 管理员可以管理所有班级成员
        if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
            yield_error('无权移除成员')
        end
        
        local student_id = tonumber(self.params.student_id)
        if not student_id then
            yield_error('请提供有效的学生ID')
        end
        
        local success = ClassMemberships:remove_student(class.id, student_id)
        if not success then
            yield_error('学生不在班级中')
        end
        
        return jsonResponse({ success = true })
    end),
    
    -- 切换学生激活状态
    toggle_member_active = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local class = find_class_by_id(self.params.id)
        if not class then
            yield_error('班级不存在')
        end
        
        -- 管理员可以管理所有班级成员
        if not self.current_user:isadmin() and class.creator_id ~= self.current_user.id then
            yield_error('无权修改成员状态')
        end
        
        local student_id = tonumber(self.params.student_id)
        if not student_id then
            yield_error('请提供有效的学生ID')
        end
        
        local membership = ClassMemberships:toggle_active(class.id, student_id)
        if not membership then
            yield_error('学生不在班级中')
        end
        
        return jsonResponse({ success = true, is_active = membership.is_active })
    end),
    
    -- 获取学生的班级列表
    student_classes = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        local classes = db.query([[
            SELECT * FROM student_classes
            WHERE student_id = ?
            ORDER BY class_name
        ]], self.current_user.id)
        
        return jsonResponse({ success = true, classes = classes })
    end),
    
    -- 获取所有学生列表（供添加成员时选择）
    get_all_students = capture_errors(function (self)
        if not self.current_user then
            yield_error('请先登录')
        end
        
        if not self.current_user.is_teacher and not self.current_user:isadmin() then
            yield_error('只有教师可以查看学生列表')
        end
        
        -- 获取所有非教师用户
        local students = Users:select(
            'WHERE is_teacher = false AND verified = true ORDER BY username'
        )
        
        -- 确保空数组被正确序列化
        if #students == 0 then
            students = cjson.empty_array
        end
        
        return jsonResponse({ success = true, users = students })
    end),
}
