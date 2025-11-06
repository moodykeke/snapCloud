-- 用户信息权限检查辅助函数
-- User Information Permission Checking Helper Functions

local M = {}

-- 检查是否可以查看真实姓名
-- Check if viewer can see target user's real name
-- @param viewer: 查看者用户对象 (viewer user object)
-- @param target_user: 目标用户对象 (target user object)
-- @return boolean
M.can_view_real_name = function(viewer, target_user)
    if not viewer or not target_user then return false end
    
    -- 本人可以查看自己的真实姓名
    if viewer.id == target_user.id then return true end
    
    -- 管理员可以查看所有人的真实姓名
    if viewer:isadmin() then return true end
    
    -- 教师可以查看自己创建的学生的真实姓名
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true
    end
    
    return false
end

-- 检查是否可以查看邮箱
-- Check if viewer can see target user's email
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_view_email = function(viewer, target_user)
    if not viewer or not target_user then return false end
    
    -- 本人可以查看自己的邮箱
    if viewer.id == target_user.id then return true end
    
    -- 版主及以上可以查看所有人的邮箱
    if viewer:has_min_role('moderator') then return true end
    
    -- 教师可以查看自己创建的学生的邮箱
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true
    end
    
    return false
end

-- 检查是否可以查看学生统计信息
-- Check if viewer can see student statistics
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象 (必须是学生)
-- @return boolean
M.can_view_student_stats = function(viewer, target_user)
    if not viewer or not target_user then return false end
    
    -- 只有学生账号才有统计信息
    if not target_user:is_student() then return false end
    
    -- 学生本人可以查看自己的统计
    if viewer.id == target_user.id then return true end
    
    -- 管理员可以查看所有学生的统计
    if viewer:isadmin() then return true end
    
    -- 教师可以查看自己创建的学生的统计
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true
    end
    
    return false
end

-- 检查是否可以管理用户
-- Check if viewer can manage target user
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_manage_user = function(viewer, target_user)
    if not viewer or not target_user then return false end
    
    -- 版主及以上可以管理用户
    if viewer:has_min_role('moderator') then return true end
    
    -- 教师可以管理自己创建的学生
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true
    end
    
    return false
end

-- 检查是否可以查看用户ID和创建者信息
-- Check if viewer can see user ID and creator information
-- @param viewer: 查看者用户对象
-- @param target_user: 目标用户对象
-- @return boolean
M.can_view_admin_info = function(viewer, target_user)
    if not viewer or not target_user then return false end
    
    -- 只有版主及以上可以查看用户ID等管理信息
    return viewer:has_min_role('moderator')
end

return M
