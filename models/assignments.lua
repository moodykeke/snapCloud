-- Assignments Model
-- =================
--
-- Written for Assignment System
-- Copyright (C) 2025
--
-- This file is part of Snap Cloud.

local db = require('lapis.db')
local Model = require('lapis.db.model').Model

local Assignments = Model:extend('assignments', {
    timestamp = true,
    
    -- 关联关系
    relations = {
        {'teacher', belongs_to = 'Users', key = 'teacher_id'},
        {'collection', belongs_to = 'Collections', key = 'collection_id'},
        {'template_project', belongs_to = 'Projects', key = 'template_project_id'}
    },
    
    -- 查找教师的所有作业
    find_by_teacher = function(self, teacher_id, options)
        options = options or {}
        local where_clause = 'teacher_id = ? AND deleted = false'
        local params = {teacher_id}
        
        -- 可选筛选已发布/未发布
        if options.published ~= nil then
            where_clause = where_clause .. ' AND published = ?'
            table.insert(params, options.published)
        end
        
        -- 排序
        local order = options.order or 'created_at DESC'
        
        return self:select(
            where_clause .. ' ORDER BY ' .. order,
            unpack(params)
        )
    end,
    
    -- 查找班级的所有作业
    find_by_collection = function(self, collection_id, options)
        options = options or {}
        local where_clause = 'collection_id = ? AND deleted = false'
        
        if options.published then
            where_clause = where_clause .. ' AND published = true'
        end
        
        return self:select(
            where_clause .. ' ORDER BY created_at DESC',
            collection_id
        )
    end,
    
    -- 获取作业统计信息
    get_stats = function(self, assignment_id)
        local result = db.query([[
            SELECT 
                COUNT(DISTINCT student_id) as total_submissions,
                COUNT(DISTINCT CASE WHEN status = 'graded' THEN student_id END) as graded_count,
                AVG(CASE WHEN status = 'graded' THEN points END) as average_points,
                COUNT(DISTINCT CASE WHEN is_late THEN student_id END) as late_submissions
            FROM submissions
            WHERE assignment_id = ?
        ]], assignment_id)
        
        return result[1] or {
            total_submissions = 0,
            graded_count = 0,
            average_points = 0,
            late_submissions = 0
        }
    end,
    
    -- 软删除
    soft_delete = function(self)
        return self:update({
            deleted = true,
            deleted_at = db.format_date()
        })
    end,
    
    -- 发布作业
    publish = function(self)
        return self:update({ published = true })
    end,
    
    -- 取消发布
    unpublish = function(self)
        return self:update({ published = false })
    end,
    
    -- 检查是否已过期
    is_overdue = function(self)
        if not self.due_date then
            return false
        end
        return os.time() > os.time(self.due_date)
    end,
    
    -- 获取已发布的作业（学生可见）
    find_published = function(self, options)
        options = options or {}
        local where_clause = 'published = true AND deleted = false'
        
        -- 可选筛选班级
        if options.collection_id then
            where_clause = where_clause .. ' AND collection_id = ' .. options.collection_id
        end
        
        -- 可选筛选未过期
        if options.not_overdue then
            where_clause = where_clause .. ' AND (due_date IS NULL OR due_date > NOW())'
        end
        
        return self:select(where_clause .. ' ORDER BY created_at DESC')
    end
})

return Assignments
