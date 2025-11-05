-- Add real_name field to users table
-- ===================================
-- 添加用户真实姓名字段，仅教师、班主任和管理员可见

-- Add real_name column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS real_name TEXT;

-- Add comment
COMMENT ON COLUMN users.real_name IS '用户真实姓名，仅教师和管理员可见，用于学生管理';

-- Update active_users view to include real_name
CREATE OR REPLACE VIEW active_users AS
SELECT 
    id,
    created,
    username,
    email,
    salt,
    password,
    about,
    location,
    verified,
    role,
    deleted,
    unique_email,
    bad_flags,
    is_teacher,
    creator_id,
    last_login_at,
    session_count,
    nickname,
    real_name
FROM users
WHERE deleted IS NULL;

-- Update class_members_detail view to include real_name
CREATE OR REPLACE VIEW class_members_detail AS
SELECT 
    cm.id,
    cm.class_id,
    cm.student_id,
    u.username AS student_username,
    u.email AS student_email,
    u.nickname AS student_nickname,
    u.real_name AS student_real_name,
    cm.joined_at,
    cm.is_active,
    cm.deleted_at,
    COALESCE(s.submitted_count, 0) AS submitted_assignment_count,
    COALESCE(s.avg_points, 0) AS average_points
FROM class_memberships cm
JOIN active_users u ON cm.student_id = u.id
LEFT JOIN (
    SELECT 
        student_id,
        COUNT(*) AS submitted_count,
        AVG(points) AS avg_points
    FROM submissions
    GROUP BY student_id
) s ON cm.student_id = s.student_id
WHERE cm.deleted_at IS NULL;
