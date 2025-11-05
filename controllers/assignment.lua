-- Assignment Controller
-- ====================
--
-- Handles assignment creation, submission, and grading
--
-- Copyright (C) 2025
-- This file is part of Snap Cloud.

local util = package.loaded.util
local validate = package.loaded.validate
local db = package.loaded.db
local yield_error = package.loaded.yield_error
local capture_errors = package.loaded.capture_errors
local jsonResponse = package.loaded.jsonResponse
local okResponse = package.loaded.okResponse
local errorResponse = package.loaded.errorResponse

local Assignments = package.loaded.Assignments
local Submissions = package.loaded.Submissions
local Users = package.loaded.Users
local Projects = package.loaded.Projects

AssignmentController = {
    -- ==================
    -- 教师端 API
    -- ==================
    
    -- 创建作业
    create = capture_errors(function (self)
        -- 验证权限：只有教师可以创建作业
        if not self.current_user then
            yield_error('未登录')
        end
        
        -- 验证必填字段
        validate.assert_valid(self.params, {
            { 'title', exists = true, min_length = 1, max_length = 255 },
        })
        
        -- 创建作业
        local assignment = Assignments:create({
            title = self.params.title,
            description = self.params.description,
            teacher_id = self.current_user.id,
            collection_id = self.params.collection_id,
            template_project_id = self.params.template_project_id,
            due_date = self.params.due_date,
            max_points = self.params.max_points or 100,
            allow_late = self.params.allow_late ~= false,  -- 默认允许迟交
            published = self.params.published or false
        })
        
        if not assignment then
            return errorResponse(self, '创建作业失败')
        end
        
        return jsonResponse({ assignment = assignment })
    end),
    
    -- 获取教师的所有作业
    list_teacher_assignments = capture_errors(function (self)
        if not self.current_user then
            yield_error('未登录')
        end
        
        local assignments = Assignments:find_by_teacher(self.current_user.id, {
            published = self.params.published  -- 可选筛选
        })
        
        -- 为每个作业添加统计信息
        for _, assignment in ipairs(assignments) do
            assignment.stats = Assignments:get_stats(assignment.id)
        end
        
        return jsonResponse({ assignments = assignments })
    end),
    
    -- 获取单个作业详情
    get_assignment = capture_errors(function (self)
        local assignment = Assignments:find(self.params.id)
        
        if not assignment then
            yield_error('作业不存在')
        end
        
        -- 权限检查：教师本人或学生（如果作业已发布）
        local is_teacher = self.current_user and assignment.teacher_id == self.current_user.id
        local is_student = self.current_user and self.current_user:is_student() and assignment.published
        
        if not (is_teacher or is_student) then
            yield_error('无权访问此作业')
        end
        
        -- 添加统计信息（仅教师可见）
        if is_teacher then
            assignment.stats = Assignments:get_stats(assignment.id)
        end
        
        return jsonResponse({ assignment = assignment })
    end),
    
    -- 更新作业
    update = capture_errors(function (self)
        local assignment = Assignments:find(self.params.id)
        
        if not assignment then
            yield_error('作业不存在')
        end
        
        -- 权限检查
        if not self.current_user or assignment.teacher_id ~= self.current_user.id then
            yield_error('无权修改此作业')
        end
        
        -- 更新字段
        assignment:update({
            title = self.params.title or assignment.title,
            description = self.params.description or assignment.description,
            due_date = self.params.due_date or assignment.due_date,
            max_points = self.params.max_points or assignment.max_points,
            allow_late = self.params.allow_late or assignment.allow_late,
            published = self.params.published or assignment.published
        })
        
        return jsonResponse({ assignment = assignment })
    end),
    
    -- 删除作业（软删除）
    delete = capture_errors(function (self)
        local assignment = Assignments:find(self.params.id)
        
        if not assignment then
            yield_error('作业不存在')
        end
        
        -- 权限检查
        if not self.current_user or assignment.teacher_id ~= self.current_user.id then
            yield_error('无权删除此作业')
        end
        
        assignment:soft_delete()
        
        return okResponse('作业已删除')
    end),
    
    -- 发布/取消发布作业
    toggle_publish = capture_errors(function (self)
        local assignment = Assignments:find(self.params.id)
        
        if not assignment then
            yield_error('作业不存在')
        end
        
        -- 权限检查
        if not self.current_user or assignment.teacher_id ~= self.current_user.id then
            yield_error('无权操作此作业')
        end
        
        if assignment.published then
            assignment:unpublish()
        else
            assignment:publish()
        end
        
        return jsonResponse({ assignment = assignment })
    end),
    
    -- 获取作业的所有提交
    list_submissions = capture_errors(function (self)
        local assignment = Assignments:find(self.params.assignment_id)
        
        if not assignment then
            yield_error('作业不存在')
        end
        
        -- 权限检查：必须是教师本人
        if not self.current_user or assignment.teacher_id ~= self.current_user.id then
            yield_error('无权查看提交')
        end
        
        local submissions = Submissions:find_by_assignment(self.params.assignment_id, {
            latest_only = true,  -- 只显示每个学生的最新提交
            status = self.params.status  -- 可选筛选状态
        })
        
        return jsonResponse({ submissions = submissions })
    end),
    
    -- 批改作业
    grade_submission = capture_errors(function (self)
        local submission = Submissions:find(self.params.submission_id)
        
        if not submission then
            yield_error('提交不存在')
        end
        
        -- 获取作业信息检查权限
        local assignment = Assignments:find(submission.assignment_id)
        if not assignment or assignment.teacher_id ~= self.current_user.id then
            yield_error('无权批改此作业')
        end
        
        -- 验证分数
        if self.params.points then
            if self.params.points < 0 or self.params.points > assignment.max_points then
                yield_error('分数必须在 0-' .. assignment.max_points .. ' 之间')
            end
        end
        
        submission:grade_submission(
            self.current_user.id,
            self.params.points,
            self.params.grade,
            self.params.feedback
        )
        
        return jsonResponse({ submission = submission })
    end),
    
    -- ==================
    -- 学生端 API
    -- ==================
    
    -- 获取学生可见的所有作业
    list_student_assignments = capture_errors(function (self)
        if not self.current_user then
            yield_error('未登录')
        end
        
        -- 获取所有已发布的作业
        local all_assignments = Assignments:find_published({
            collection_id = self.params.collection_id
        })
        
        -- 为每个作业添加学生的提交状态
        for _, assignment in ipairs(all_assignments) do
            local submission = Submissions:find_latest_submission(assignment.id, self.current_user.id)
            assignment.my_submission = submission
        end
        
        return jsonResponse({ assignments = all_assignments })
    end),
    
    -- 提交作业
    submit = capture_errors(function (self)
        if not self.current_user then
            yield_error('未登录')
        end
        
        -- 验证字段
        validate.assert_valid(self.params, {
            { 'assignment_id', exists = true },
            { 'project_id', exists = true }
        })
        
        -- 检查作业是否存在且已发布
        local assignment = Assignments:find(self.params.assignment_id)
        if not assignment or not assignment.published then
            yield_error('作业不存在或未发布')
        end
        
        -- 检查项目是否存在且属于当前用户
        local project = Projects:find(self.params.project_id)
        if not project or project.username ~= self.current_user.username then
            yield_error('项目不存在或无权使用')
        end
        
        -- 创建提交
        local submission = Submissions:create_submission({
            assignment_id = self.params.assignment_id,
            student_id = self.current_user.id,
            project_id = self.params.project_id,
            student_note = self.params.student_note,
            due_date = assignment.due_date
        })
        
        if not submission then
            return errorResponse(self, '提交失败')
        end
        
        return jsonResponse({ submission = submission })
    end),
    
    -- 获取学生的所有提交
    list_my_submissions = capture_errors(function (self)
        if not self.current_user then
            yield_error('未登录')
        end
        
        local submissions = Submissions:find_by_student(self.current_user.id, {
            assignment_id = self.params.assignment_id,
            status = self.params.status
        })
        
        return jsonResponse({ submissions = submissions })
    end),
    
    -- 获取学生统计
    get_my_stats = capture_errors(function (self)
        if not self.current_user then
            yield_error('未登录')
        end
        
        local stats = Submissions:get_student_stats(self.current_user.id)
        
        return jsonResponse({ stats = stats })
    end)
}

return AssignmentController
