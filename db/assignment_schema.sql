-- ========================================
-- 作业系统数据库表结构
-- Assignment System Database Schema
-- ========================================

-- 作业表 (Assignments Table)
-- 存储教师创建的作业信息
CREATE TABLE IF NOT EXISTS assignments (
    id serial PRIMARY KEY,
    
    -- 基本信息
    title varchar(255) NOT NULL,                    -- 作业标题
    description text,                                -- 作业描述/说明
    
    -- 关联信息
    teacher_id integer NOT NULL,                     -- 创建者(教师) - 不使用外键，因为users表结构特殊
    collection_id integer,                           -- 关联的班级合集(可选)
    template_project_id integer,                     -- 模板项目(可选)
    
    -- 时间控制
    created_at timestamp NOT NULL DEFAULT now(),    -- 创建时间
    due_date timestamp,                              -- 截止日期(可选)
    published boolean DEFAULT false,                 -- 是否发布(草稿/发布)
    
    -- 评分设置
    max_points integer DEFAULT 100,                  -- 满分
    allow_late boolean DEFAULT true,                 -- 是否允许迟交
    
    -- 软删除
    deleted boolean DEFAULT false,
    deleted_at timestamp
);

-- 作业提交表 (Submissions Table)
-- 存储学生的作业提交记录
CREATE TABLE IF NOT EXISTS submissions (
    id serial PRIMARY KEY,
    
    -- 关联信息
    assignment_id integer NOT NULL,                  -- 作业ID
    student_id integer NOT NULL,                     -- 学生ID
    project_id integer NOT NULL,                     -- 提交的项目ID
    
    -- 提交信息
    submitted_at timestamp NOT NULL DEFAULT now(),   -- 提交时间
    is_late boolean DEFAULT false,                   -- 是否迟交
    version integer DEFAULT 1,                       -- 提交版本(支持重新提交)
    student_note text,                               -- 学生备注/说明
    
    -- 评分信息
    status varchar(20) DEFAULT 'submitted',          -- 状态: draft, submitted, grading, graded
    points integer,                                  -- 得分
    grade varchar(10),                               -- 等级 (A/B/C/D/F 或其他)
    feedback text,                                   -- 教师反馈
    graded_at timestamp,                             -- 批改时间
    graded_by integer,                               -- 批改人
    
    -- 唯一约束：每个学生每个作业每个版本唯一
    UNIQUE(assignment_id, student_id, version)
);

-- 索引优化
CREATE INDEX IF NOT EXISTS assignments_teacher_idx ON assignments(teacher_id);
CREATE INDEX IF NOT EXISTS assignments_collection_idx ON assignments(collection_id);
CREATE INDEX IF NOT EXISTS assignments_due_date_idx ON assignments(due_date);
CREATE INDEX IF NOT EXISTS assignments_published_idx ON assignments(published);

CREATE INDEX IF NOT EXISTS submissions_assignment_idx ON submissions(assignment_id);
CREATE INDEX IF NOT EXISTS submissions_student_idx ON submissions(student_id);
CREATE INDEX IF NOT EXISTS submissions_status_idx ON submissions(status);
CREATE INDEX IF NOT EXISTS submissions_project_idx ON submissions(project_id);

-- 组合索引：查询某个学生的某个作业的最新提交
CREATE INDEX IF NOT EXISTS submissions_student_assignment_idx ON submissions(student_id, assignment_id, version DESC);

-- 视图：获取每个作业的统计信息
CREATE OR REPLACE VIEW assignment_stats AS
SELECT 
    a.id as assignment_id,
    a.title,
    a.teacher_id,
    COUNT(DISTINCT s.student_id) as total_submissions,
    COUNT(DISTINCT CASE WHEN s.status = 'graded' THEN s.student_id END) as graded_count,
    AVG(CASE WHEN s.status = 'graded' THEN s.points END) as average_points,
    COUNT(DISTINCT CASE WHEN s.is_late THEN s.student_id END) as late_submissions
FROM assignments a
LEFT JOIN submissions s ON a.id = s.assignment_id
WHERE a.deleted = false
GROUP BY a.id, a.title, a.teacher_id;

-- 视图：获取学生的作业完成情况
CREATE OR REPLACE VIEW student_assignment_progress AS
SELECT 
    u.id as student_id,
    u.username,
    COUNT(DISTINCT a.id) as total_assignments,
    COUNT(DISTINCT s.assignment_id) as submitted_assignments,
    COUNT(DISTINCT CASE WHEN s.status = 'graded' THEN s.assignment_id END) as graded_assignments,
    AVG(CASE WHEN s.status = 'graded' THEN s.points END) as average_score
FROM users u
LEFT JOIN submissions s ON u.id = s.student_id
LEFT JOIN assignments a ON s.assignment_id = a.id AND a.deleted = false AND a.published = true
WHERE u.role = 'student'
GROUP BY u.id, u.username;

COMMENT ON TABLE assignments IS '作业表：存储教师创建的作业';
COMMENT ON TABLE submissions IS '提交表：存储学生的作业提交记录';
COMMENT ON COLUMN assignments.published IS 'false=草稿，true=已发布给学生';
COMMENT ON COLUMN submissions.version IS '支持学生多次提交，version递增';
COMMENT ON COLUMN submissions.status IS 'draft=草稿, submitted=已提交, grading=批改中, graded=已评分';
