-- 班级管理系统 Schema
-- =====================
-- 
-- 设计思路：
-- 1. 复用现有 Collections 表作为"班级"容器
-- 2. 新增 is_class 字段标识班级类型的 Collection
-- 3. 新增 class_memberships 表明确学生与班级的多对多关系
-- 4. 支持一个学生加入多个班级（比如数学班、科学班）
-- 5. 支持批量导入、移除学生

-- =====================================================
-- 第一步：扩展 collections 表，支持"班级"类型
-- =====================================================
ALTER TABLE collections 
ADD COLUMN IF NOT EXISTS is_class BOOLEAN DEFAULT false NOT NULL;

-- 为班级类型的 collection 创建索引，加速查询
CREATE INDEX IF NOT EXISTS collections_is_class_idx 
ON collections(is_class) WHERE is_class = true;

-- =====================================================
-- 第二步：创建班级成员关系表
-- =====================================================
CREATE TABLE IF NOT EXISTS class_memberships (
    id SERIAL PRIMARY KEY,
    
    -- 班级 ID（引用 collections 表中 is_class=true 的记录）
    class_id INTEGER NOT NULL,
    
    -- 学生用户 ID（引用 users 表）
    student_id INTEGER NOT NULL,
    
    -- 加入时间
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- 学生在班级中的备注（可选，如学号、座位号等）
    student_note TEXT,
    
    -- 是否激活（支持临时停用学生，比如休学）
    is_active BOOLEAN DEFAULT true NOT NULL,
    
    -- 软删除
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- 唯一约束：同一学生不能重复加入同一班级
    UNIQUE(class_id, student_id)
);

-- 索引：按班级查询学生
CREATE INDEX class_memberships_class_id_idx 
ON class_memberships(class_id) WHERE deleted_at IS NULL;

-- 索引：按学生查询班级
CREATE INDEX class_memberships_student_id_idx 
ON class_memberships(student_id) WHERE deleted_at IS NULL;

-- 索引：只查询激活的成员
CREATE INDEX class_memberships_active_idx 
ON class_memberships(class_id, is_active) 
WHERE deleted_at IS NULL AND is_active = true;

-- =====================================================
-- 第三步：创建视图 - 班级统计信息
-- =====================================================
CREATE OR REPLACE VIEW class_stats AS
SELECT 
    c.id AS class_id,
    c.name AS class_name,
    c.creator_id AS teacher_id,
    c.created_at,
    COUNT(DISTINCT cm.student_id) FILTER (WHERE cm.is_active AND cm.deleted_at IS NULL) AS active_student_count,
    COUNT(DISTINCT cm.student_id) FILTER (WHERE cm.deleted_at IS NULL) AS total_student_count,
    COUNT(DISTINCT a.id) FILTER (WHERE a.deleted = false AND a.published = true) AS published_assignment_count,
    COUNT(DISTINCT a.id) FILTER (WHERE a.deleted = false) AS total_assignment_count
FROM collections c
LEFT JOIN class_memberships cm ON c.id = cm.class_id
LEFT JOIN assignments a ON c.id = a.collection_id
WHERE c.is_class = true
GROUP BY c.id, c.name, c.creator_id, c.created_at;

-- =====================================================
-- 第四步：创建视图 - 学生的班级列表
-- =====================================================
CREATE OR REPLACE VIEW student_classes AS
SELECT 
    cm.student_id,
    cm.class_id,
    c.name AS class_name,
    c.creator_id AS teacher_id,
    u.username AS teacher_username,
    cm.joined_at,
    cm.student_note,
    cm.is_active
FROM class_memberships cm
JOIN collections c ON cm.class_id = c.id
JOIN users u ON c.creator_id = u.id
WHERE cm.deleted_at IS NULL 
  AND u.deleted IS NULL
  AND c.is_class = true;

-- =====================================================
-- 第五步：创建视图 - 班级成员详情
-- =====================================================
CREATE OR REPLACE VIEW class_members_detail AS
SELECT 
    cm.id AS membership_id,
    cm.class_id,
    c.name AS class_name,
    cm.student_id,
    u.username AS student_username,
    u.email AS student_email,
    u.created AS student_created_at,
    cm.joined_at,
    cm.student_note,
    cm.is_active,
    -- 学生在这个班级的作业统计
    COUNT(DISTINCT s.assignment_id) AS submitted_assignment_count,
    COUNT(DISTINCT s.id) FILTER (WHERE s.grade IS NOT NULL) AS graded_submission_count,
    AVG(s.points) FILTER (WHERE s.grade IS NOT NULL) AS average_points
FROM class_memberships cm
JOIN collections c ON cm.class_id = c.id
JOIN users u ON cm.student_id = u.id
LEFT JOIN submissions s ON cm.student_id = s.student_id
LEFT JOIN assignments a ON s.assignment_id = a.id AND a.collection_id = cm.class_id
WHERE cm.deleted_at IS NULL
GROUP BY cm.id, cm.class_id, c.name, cm.student_id, u.username, u.email, u.created, cm.joined_at, cm.student_note, cm.is_active;

-- =====================================================
-- 注释说明
-- =====================================================
COMMENT ON TABLE class_memberships IS '班级成员关系表，管理学生与班级的多对多关系';
COMMENT ON COLUMN collections.is_class IS '标识此 collection 是否为班级类型';
COMMENT ON COLUMN class_memberships.class_id IS '班级 ID，引用 collections 表';
COMMENT ON COLUMN class_memberships.student_id IS '学生 ID，引用 users 表';
COMMENT ON COLUMN class_memberships.is_active IS '学生在班级中是否激活（可用于临时停用）';
COMMENT ON VIEW class_stats IS '班级统计信息视图：学生数、作业数等';
COMMENT ON VIEW student_classes IS '学生的班级列表视图';
COMMENT ON VIEW class_members_detail IS '班级成员详细信息视图，包含作业统计';
