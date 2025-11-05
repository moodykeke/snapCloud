-- Submissions Model
-- ==================
--
-- Written for Assignment System
-- Copyright (C) 2025
--
-- This file is part of Snap Cloud.

local db = require('lapis.db')
local Model = require('lapis.db.model').Model

local Submissions = Model:extend('submissions', {
    timestamp = true,
    
    -- 关联关系
    relations = {
        {'assignment', belongs_to = 'Assignments', key = 'assignment_id'},
        {'student', belongs_to = 'Users', key = 'student_id'},
        {'project', belongs_to = 'Projects', key = 'project_id'},
        {'grader', belongs_to = 'Users', key = 'graded_by'}
    },
    
    -- 查找学生的所有提交
    find_by_student = function(self, student_id, options)
        options = options or {}
        local where_clause = 'student_id = ?'
        local params = {student_id}
        
        -- 可选筛选作业
        if options.assignment_id then
            where_clause = where_clause .. ' AND assignment_id = ?'
            table.insert(params, options.assignment_id)
        end
        
        -- 可选筛选状态
        if options.status then
            where_clause = where_clause .. ' AND status = ?'
            table.insert(params, options.status)
        end
        
        -- 排序
        local order = options.order or 'submitted_at DESC'
        
        return self:select(
            where_clause .. ' ORDER BY ' .. order,
            unpack(params)
        )
    end,
    
    -- 查找作业的所有提交
    find_by_assignment = function(self, assignment_id, options)
        options = options or {}
        local where_clause = 'assignment_id = ?'
        local params = {assignment_id}
        
        -- 可选筛选状态
        if options.status then
            where_clause = where_clause .. ' AND status = ?'
            table.insert(params, options.status)
        end
        
        -- 只获取每个学生的最新版本
        if options.latest_only then
            local query = [[
                SELECT s1.* FROM submissions s1
                INNER JOIN (
                    SELECT student_id, MAX(version) as max_version
                    FROM submissions
                    WHERE assignment_id = ?
                    GROUP BY student_id
                ) s2 ON s1.student_id = s2.student_id 
                    AND s1.version = s2.max_version
                    AND s1.assignment_id = ?
                ORDER BY s1.submitted_at DESC
            ]]
            return db.query(query, assignment_id, assignment_id)
        end
        
        return self:select(
            where_clause .. ' ORDER BY submitted_at DESC',
            unpack(params)
        )
    end,
    
    -- 获取学生对某个作业的最新提交
    find_latest_submission = function(self, assignment_id, student_id)
        local result = self:select(
            'assignment_id = ? AND student_id = ? ORDER BY version DESC LIMIT 1',
            assignment_id,
            student_id
        )
        return result[1]
    end,
    
    -- 创建新提交（自动处理版本号）
    create_submission = function(self, data)
        -- 查找现有最大版本号
        local latest = self:find_latest_submission(data.assignment_id, data.student_id)
        data.version = latest and (latest.version + 1) or 1
        
        -- 检查是否迟交
        if data.due_date then
            data.is_late = os.time() > os.time(data.due_date)
        end
        
        data.submitted_at = db.format_date()
        data.status = data.status or 'submitted'
        
        return self:create(data)
    end,
    
    -- 批改作业
    grade_submission = function(self, grader_id, points, grade, feedback)
        return self:update({
            status = 'graded',
            points = points,
            grade = grade,
            feedback = feedback,
            graded_at = db.format_date(),
            graded_by = grader_id
        })
    end,
    
    -- 获取待批改的提交
    find_pending = function(self, teacher_id)
        local query = [[
            SELECT s.* FROM submissions s
            INNER JOIN assignments a ON s.assignment_id = a.id
            WHERE a.teacher_id = ?
            AND s.status IN ('submitted', 'grading')
            AND a.deleted = false
            ORDER BY s.submitted_at ASC
        ]]
        return db.query(query, teacher_id)
    end,
    
    -- 更新状态
    update_status = function(self, new_status)
        return self:update({ status = new_status })
    end,
    
    -- 获取学生的作业统计
    get_student_stats = function(self, student_id)
        local result = db.query([[
            SELECT 
                COUNT(*) as total_submissions,
                COUNT(CASE WHEN status = 'graded' THEN 1 END) as graded_count,
                AVG(CASE WHEN status = 'graded' THEN points END) as average_score,
                COUNT(CASE WHEN is_late THEN 1 END) as late_submissions
            FROM submissions
            WHERE student_id = ?
        ]], student_id)
        
        return result[1] or {
            total_submissions = 0,
            graded_count = 0,
            average_score = 0,
            late_submissions = 0
        }
    end
})

return Submissions
