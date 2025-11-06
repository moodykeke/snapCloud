-- 用户信息权限检查辅助函数
-- User Information Permission Checking Helper Functions

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
        
        -- 教师可以查看自己创建的学生的真实姓名
        if v.is_teacher and t.creator_id == v.id then
            return true
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
        
        -- 教师可以查看自己创建的学生的邮箱
        if v.is_teacher and t.creator_id == v.id then
            return true
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
        
        -- 教师可以查看自己创建的学生的统计
        if v.is_teacher and t.creator_id == v.id then
            return true
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
        
        -- 教师可以管理自己创建的学生
        if v.is_teacher and t.creator_id == v.id then
            return true
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
        
        -- 教师可以编辑自己创建的学生的信息
        if v.is_teacher and t.creator_id == v.id then
            return true
        end
        
        return false
    end)
end

return M
