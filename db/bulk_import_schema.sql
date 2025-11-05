-- 批量导入功能数据库迁移
-- 用于记录批量导入历史和结果

-- 批量导入历史记录表
CREATE TABLE IF NOT EXISTS bulk_import_logs (
    id SERIAL PRIMARY KEY,
    imported_by INTEGER NOT NULL,
    import_type TEXT NOT NULL,  -- 'teacher_students', 'admin_users'
    total_count INTEGER NOT NULL DEFAULT 0,
    success_count INTEGER NOT NULL DEFAULT 0,
    failed_count INTEGER NOT NULL DEFAULT 0,
    error_details JSONB,  -- 存储失败记录的详细信息
    imported_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE bulk_import_logs IS '批量导入历史记录';
COMMENT ON COLUMN bulk_import_logs.import_type IS '导入类型：teacher_students（教师导入学生）, admin_users（管理员导入用户）';
COMMENT ON COLUMN bulk_import_logs.error_details IS '失败记录详情，JSON格式：[{row: 1, username: "test", error: "原因"}]';

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_bulk_import_logs_imported_by ON bulk_import_logs(imported_by);
CREATE INDEX IF NOT EXISTS idx_bulk_import_logs_imported_at ON bulk_import_logs(imported_at);
