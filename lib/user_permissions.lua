-- 用户信息权限检查辅助函数
-- User Information Permission Checking Helper Functions
--
-- 权限设计原则：
-- ===============
-- 1. 本人：可以查看和编辑自己的所有信息
-- 2. 管理员（admin）：可以查看和编辑所有人的信息，可以修改角色和教师身份
-- 3. 版主（moderator）：可以查看所有人的信息（只读），不能修改角色和教师身份
-- 4. 教师（is_teacher=true）：
--    a. 创建者关系：可以查看和管理自己通过批量导入创建的学生账号
--    b. 班级关系：可以查看和管理加入自己班级的学生（无论是否为创建者）
--    c. 权限范围：真实姓名、邮箱、学生统计、基本信息编辑
-- 5. 普通用户：只能查看和编辑自己的信息
--
-- 班级教师权限说明：
-- ==================
-- - 教师A创建班级C1，导入学生S1
-- - 教师B创建班级C2，将学生S1加入班级C2
-- - 结果：
--   * 教师A可以查看S1信息（创建者关系）
--   * 教师B可以查看S1信息（班级关系）
--   * 两位教师都可以管理S1的基本信息（邮箱、密码、真实姓名等）
--

local cache = require('lib.permission_cache')
local M = {}

-- 检查是否可以查看真实姓名
-- Check if viewer can see target user's real name
-- @param viewer: 查看者用户对象 (viewer user object)
-- @param target_user: 目标用户对象 (target user object)
-- @return boolean
M.can_view_real_name = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'view_real_name', function(v, t)
        if not v or not t then return false end
        
        -- 本人可以查看自己的真实姓名
        if v.id == t.id then return true end
        
        -- 管理员和版主可以查看所有人的真实姓名（版主只读，管理员可编辑由前端控制）
        if v:has_min_role('moderator') then return true end
        
        -- 创建者可以查看被创建者的真实姓名（教师导入的学生账号）
        if t.creator_id and t.creator_id == v.id then
            return true
        end
        
        -- 班级教师可以查看本班学生的真实姓名
        if v.is_teacher and t:is_student() then
            -- 检查学生是否在该教师管理的任何班级中
            local db = require('lapis.db')
            local result = db.query([[
                SELECT EXISTS (
                    SELECT 1 
                    FROM class_memberships cm
                    JOIN collections c ON cm.class_id = c.id
                    WHERE cm.student_id = ?
                      AND c.creator_id = ?
                      AND c.is_class = true
                      AND cm.deleted_at IS NULL
                ) AS is_class_teacher
            ]], t.id, v.id)
            
            if result and result[1] and result[1].is_class_teacher then
                return true
            end
        end
        
        return false
    end)
end

-- 检查是否可以查看邮箱
-- Check if viewer can see target user's email
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_view_email = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'view_email', function(v, t)
        if not v or not t then return false end
        
        -- 本人可以查看自己的邮箱
        if v.id == t.id then return true end
        
        -- 版主及以上可以查看所有人的邮箱
        if v:has_min_role('moderator') then return true end
        
        -- 创建者可以查看被创建者的邮箱（教师导入的学生账号）
        if t.creator_id and t.creator_id == v.id then
            return true
        end
        
        -- 班级教师可以查看本班学生的邮箱
        if v.is_teacher and t:is_student() then
            local db = require('lapis.db')
            local result = db.query([[
                SELECT EXISTS (
                    SELECT 1 
                    FROM class_memberships cm
                    JOIN collections c ON cm.class_id = c.id
                    WHERE cm.student_id = ?
                      AND c.creator_id = ?
                      AND c.is_class = true
                      AND cm.deleted_at IS NULL
                ) AS is_class_teacher
            ]], t.id, v.id)
            
            if result and result[1] and result[1].is_class_teacher then
                return true
            end
        end
        
        return false
    end)
end

-- 检查是否可以查看学生统计信息
-- Check if viewer can see student statistics
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象 (必须是学生)
-- @return boolean
M.can_view_student_stats = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'view_student_stats', function(v, t)
        if not v or not t then return false end
        
        -- 只有学生账号才有统计信息
        if not t:is_student() then return false end
        
        -- 学生本人可以查看自己的统计
        if v.id == t.id then return true end
        
        -- 管理员和版主可以查看所有学生的统计（监督职责）
        if v:has_min_role('moderator') then return true end
        
        -- 创建者可以查看被创建学生的统计（教师导入的学生账号）
        if t.creator_id and t.creator_id == v.id then
            return true
        end
        
        -- 班级教师可以查看本班学生的统计
        if v.is_teacher then
            local db = require('lapis.db')
            local result = db.query([[
                SELECT EXISTS (
                    SELECT 1 
                    FROM class_memberships cm
                    JOIN collections c ON cm.class_id = c.id
                    WHERE cm.student_id = ?
                      AND c.creator_id = ?
                      AND c.is_class = true
                      AND cm.deleted_at IS NULL
                ) AS is_class_teacher
            ]], t.id, v.id)
            
            if result and result[1] and result[1].is_class_teacher then
                return true
            end
        end
        
        return false
    end)
end

-- 检查是否可以管理用户
-- Check if viewer can manage target user
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_manage_user = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'manage_user', function(v, t)
        if not v or not t then return false end
        
        -- 版主及以上可以管理用户
        if v:has_min_role('moderator') then return true end
        
        -- 创建者可以管理被创建的用户（教师导入的学生账号）
        if t.creator_id and t.creator_id == v.id then
            return true
        end
        
        -- 班级教师可以管理本班学生
        if v.is_teacher and t:is_student() then
            local db = require('lapis.db')
            local result = db.query([[
                SELECT EXISTS (
                    SELECT 1 
                    FROM class_memberships cm
                    JOIN collections c ON cm.class_id = c.id
                    WHERE cm.student_id = ?
                      AND c.creator_id = ?
                      AND c.is_class = true
                      AND cm.deleted_at IS NULL
                ) AS is_class_teacher
            ]], t.id, v.id)
            
            if result and result[1] and result[1].is_class_teacher then
                return true
            end
        end
        
        return false
    end)
end

-- 检查是否可以查看用户ID和创建者信息
-- Check if viewer can see user ID and creator information
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_view_admin_info = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'view_admin_info', function(v, t)
        if not v or not t then return false end
        
        -- 只有版主及以上可以查看用户ID等管理信息
        return v:has_min_role('moderator')
    end)
end

-- 检查是否可以编辑用户角色
-- Check if viewer can edit target user's role
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_edit_role = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'edit_role', function(v, t)
        if not v or not t then return false end
        
        -- 只有管理员可以修改用户角色
        return v:isadmin()
    end)
end

-- 检查是否可以编辑教师身份
-- Check if viewer can edit teacher status
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_edit_teacher_status = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'edit_teacher_status', function(v, t)
        if not v or not t then return false end
        
        -- 只有管理员可以修改教师身份
        return v:isadmin()
    end)
end

-- 检查是否可以编辑用户基本信息（邮箱、密码等）
-- Check if viewer can edit basic user information
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_edit_user_info = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'edit_user_info', function(v, t)
        if not v or not t then return false end
        
        -- 本人可以编辑自己的信息
        if v.id == t.id then return true end
        
        -- 版主及以上可以编辑用户基本信息
        if v:has_min_role('moderator') then return true end
        
        -- 创建者可以编辑被创建用户的信息（教师导入的学生账号）
        if t.creator_id and t.creator_id == v.id then
            return true
        end
        
        -- 班级教师可以编辑本班学生的信息
        if v.is_teacher and t:is_student() then
            local db = require('lapis.db')
            local result = db.query([[
                SELECT EXISTS (
                    SELECT 1 
                    FROM class_memberships cm
                    JOIN collections c ON cm.class_id = c.id
                    WHERE cm.student_id = ?
                      AND c.creator_id = ?
                      AND c.is_class = true
                      AND cm.deleted_at IS NULL
                ) AS is_class_teacher
            ]], t.id, v.id)
            
            if result and result[1] and result[1].is_class_teacher then
                return true
            end
        end
        
        return false
    end)
end

return M
