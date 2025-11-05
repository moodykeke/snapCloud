-- 手动运行此迁移以创建 totm_banners 表
-- 
-- 数据库配置 (见 config.lua):
--   Host: 127.0.0.1
--   Port: 5432
--   User: cloud
--   Password: snap-cloud-password (默认开发环境密码)
--   Database: snapcloud
--
-- 运行方式 1 (推荐 - 使用 lapis):
--   bin/lapis-migrate
--
-- 运行方式 2 (手动执行):
--   psql -h 127.0.0.1 -U cloud -d snapcloud < create_totm_banners_table.sql
--   (会提示输入密码: snap-cloud-password)
--
-- 运行方式 3 (免密码):
--   PGPASSWORD=snap-cloud-password psql -h 127.0.0.1 -U cloud -d snapcloud < create_totm_banners_table.sql

BEGIN;

-- Create totm_banners table
CREATE TABLE IF NOT EXISTS totm_banners (
    id SERIAL PRIMARY KEY,
    filename TEXT UNIQUE NOT NULL,
    original_name TEXT NOT NULL,
    uploader_id INTEGER,  -- 不使用外键约束，因为 users.id 不是主键
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE NOT NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS totm_banners_uploader_id_idx ON totm_banners(uploader_id);
CREATE INDEX IF NOT EXISTS totm_banners_is_active_idx ON totm_banners(is_active);

-- Insert migration record
INSERT INTO lapis_migrations (name) VALUES ('2025-11-05:0')
ON CONFLICT (name) DO NOTHING;

COMMIT;

-- Verify
SELECT 'totm_banners table created successfully!' as message;
SELECT * FROM totm_banners;
