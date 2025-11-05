-- Add nickname field to users table
-- ===================================
-- 添加用户昵称字段，方便教师识别和管理学生

-- Add nickname column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS nickname TEXT;

-- Add comment
COMMENT ON COLUMN users.nickname IS '用户昵称，用于显示真实姓名或便于识别的名称';

-- Create index for nickname search (optional, for performance)
CREATE INDEX IF NOT EXISTS idx_users_nickname ON users(nickname) WHERE nickname IS NOT NULL;

-- Update active_users view to include nickname
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
    nickname
FROM users
WHERE deleted IS NULL;
