-- Class Memberships Model
-- =======================
-- 管理学生与班级的多对多关系

local Model = package.loaded.Model
local db = require('lapis.db')

local ClassMemberships = Model:extend('class_memberships', {
    
    -- 关系定义
    relations = {
        {'class', belongs_to = 'Collections', key = 'class_id'},
        {'student', belongs_to = 'Users', key = 'student_id'}
    },
    
    -- 根据班级 ID 查找所有成员
    find_by_class = function (self, class_id, options)
        options = options or {}
        local where = 'class_id = ? AND deleted_at IS NULL'
        local params = { class_id }
        
        if options.active_only then
            where = where .. ' AND is_active = true'
        end
        
        return self:select(where, unpack(params))
    end,
    
    -- 根据学生 ID 查找所有班级
    find_by_student = function (self, student_id)
        return self:select(
            'student_id = ? AND deleted_at IS NULL',
            student_id
        )
    end,
    
    -- 检查学生是否在班级中
    is_member = function (self, class_id, student_id)
        return self:find({
            class_id = class_id,
            student_id = student_id,
            deleted_at = db.NULL
        }) ~= nil
    end,
    
    -- 添加学生到班级
    add_student = function (self, class_id, student_id, options)
        options = options or {}
        
        -- 检查是否已存在
        local existing = self:find({
            class_id = class_id,
            student_id = student_id
        })
        
        if existing then
            if existing.deleted_at then
                -- 恢复已删除的成员
                existing:update({
                    deleted_at = db.NULL,
                    is_active = true,
                    joined_at = db.raw("now()"),
                    student_note = options.student_note or existing.student_note
                })
                return existing
            else
                -- 已经是成员
                return existing, 'already_exists'
            end
        end
        
        -- 创建新成员
        return self:create({
            class_id = class_id,
            student_id = student_id,
            student_note = options.student_note,
            is_active = true
        })
    end,
    
    -- 批量添加学生
    add_students = function (self, class_id, student_ids, options)
        options = options or {}
        local results = {
            success = {},
            already_exists = {},
            failed = {}
        }
        
        for _, student_id in ipairs(student_ids) do
            local membership, err = self:add_student(class_id, student_id, options)
            if membership then
                if err == 'already_exists' then
                    table.insert(results.already_exists, student_id)
                else
                    table.insert(results.success, student_id)
                end
            else
                table.insert(results.failed, student_id)
            end
        end
        
        return results
    end,
    
    -- 移除学生（软删除）
    remove_student = function (self, class_id, student_id)
        local membership = self:find({
            class_id = class_id,
            student_id = student_id,
            deleted_at = db.NULL
        })
        
        if membership then
            membership:update({ deleted_at = db.raw("now()") })
            return true
        end
        return false
    end,
    
    -- 激活/停用学生
    toggle_active = function (self, class_id, student_id)
        local membership = self:find({
            class_id = class_id,
            student_id = student_id,
            deleted_at = db.NULL
        })
        
        if membership then
            membership:update({ is_active = not membership.is_active })
            return membership
        end
        return nil
    end,
    
    -- 获取班级成员详情（带统计）
    get_class_members_detail = function (self, class_id)
        local query = [[
            SELECT * FROM class_members_detail
            WHERE class_id = ?
            ORDER BY student_username
        ]]
        return db.query(query, class_id)
    end,
    
    -- 获取学生的班级列表
    get_student_classes = function (self, student_id)
        local query = [[
            SELECT * FROM student_classes
            WHERE student_id = ?
            ORDER BY class_name
        ]]
        return db.query(query, student_id)
    end,
    
    -- 更新学生备注
    update_note = function (self, class_id, student_id, note)
        local membership = self:find({
            class_id = class_id,
            student_id = student_id,
            deleted_at = db.NULL
        })
        
        if membership then
            membership:update({ student_note = note })
            return membership
        end
        return nil
    end,
})

return ClassMemberships
