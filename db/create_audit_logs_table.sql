-- 审计日志表 - 记录所有敏感操作
-- Audit Logs Table - Record all sensitive operations

CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    
    -- 操作信息
    action VARCHAR(100) NOT NULL,                    -- 操作类型：set_role, set_teacher, delete_user等
    action_category VARCHAR(50),                     -- 操作分类：user_management, permission_change等
    
    -- 操作者信息
    operator_id INTEGER NOT NULL,                    -- 执行操作的用户ID
    operator_username VARCHAR(200),                  -- 操作者用户名（冗余，便于查询）
    operator_role VARCHAR(50),                       -- 操作时的角色（记录当时状态）
    
    -- 目标信息
    target_type VARCHAR(50) NOT NULL,                -- 目标类型：user, project, collection等
    target_id INTEGER NOT NULL,                      -- 目标对象ID
    target_username VARCHAR(200),                    -- 目标用户名（如果是用户）
    
    -- 变更详情
    old_value TEXT,                                  -- 变更前的值（JSON格式）
    new_value TEXT,                                  -- 变更后的值（JSON格式）
    
    -- 请求信息
    ip_address VARCHAR(45),                          -- 操作者IP地址（支持IPv6）
    user_agent TEXT,                                 -- User-Agent字符串
    
    -- 附加信息
    notes TEXT,                                      -- 备注或附加说明
    success BOOLEAN DEFAULT TRUE,                    -- 操作是否成功
    error_message TEXT,                              -- 如果失败，错误信息
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- 操作时间
    
    -- 索引优化
    CONSTRAINT fk_operator FOREIGN KEY (operator_id) REFERENCES active_users(id) ON DELETE SET NULL
);

-- 创建索引以优化查询性能
CREATE INDEX idx_audit_logs_operator ON audit_logs(operator_id);
CREATE INDEX idx_audit_logs_target ON audit_logs(target_type, target_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_target_user ON audit_logs(target_username);

-- 添加表注释
COMMENT ON TABLE audit_logs IS '系统审计日志，记录所有敏感操作的详细信息';
COMMENT ON COLUMN audit_logs.action IS '操作类型，如：set_role, set_teacher, delete_user, verify_user';
COMMENT ON COLUMN audit_logs.action_category IS '操作分类：user_management, permission_change, content_moderation等';
COMMENT ON COLUMN audit_logs.old_value IS '变更前的值，JSON格式存储，便于追溯';
COMMENT ON COLUMN audit_logs.new_value IS '变更后的值，JSON格式存储';
COMMENT ON COLUMN audit_logs.ip_address IS '操作者IP地址，用于安全审计';

-- 创建视图：最近的敏感操作（便于管理员查看）
CREATE OR REPLACE VIEW recent_sensitive_operations AS
SELECT 
    al.id,
    al.action,
    al.operator_username,
    al.target_username,
    al.old_value,
    al.new_value,
    al.created_at,
    al.ip_address
FROM audit_logs al
WHERE al.action IN ('set_role', 'set_teacher', 'delete_user', 'ban_user', 'unban_user')
    AND al.created_at > NOW() - INTERVAL '30 days'
ORDER BY al.created_at DESC
LIMIT 100;

COMMENT ON VIEW recent_sensitive_operations IS '最近30天的敏感操作记录';
