-- 审计日志模型
-- Audit Log Model

local Model = require('lapis.db.model').Model
local cjson = require('cjson')

local AuditLogs = Model:extend('audit_logs', {
    -- 记录审计日志
    -- @param params table: 日志参数
    --   - action: 操作类型（必需）
    --   - operator: 操作者用户对象（必需）
    --   - target_type: 目标类型（必需）
    --   - target_id: 目标ID（必需）
    --   - target_username: 目标用户名（可选）
    --   - old_value: 旧值（可选）
    --   - new_value: 新值（可选）
    --   - notes: 备注（可选）
    --   - ip_address: IP地址（可选）
    --   - user_agent: User-Agent（可选）
    log = function(self, params)
        assert(params.action, 'action is required')
        assert(params.operator, 'operator is required')
        assert(params.target_type, 'target_type is required')
        assert(params.target_id, 'target_id is required')
        
        -- 构建日志记录
        local log_data = {
            action = params.action,
            action_category = params.action_category or self:infer_category(params.action),
            
            operator_id = params.operator.id,
            operator_username = params.operator.username,
            operator_role = params.operator.role,
            
            target_type = params.target_type,
            target_id = params.target_id,
            target_username = params.target_username,
            
            old_value = params.old_value and cjson.encode(params.old_value) or nil,
            new_value = params.new_value and cjson.encode(params.new_value) or nil,
            
            notes = params.notes,
            ip_address = params.ip_address,
            user_agent = params.user_agent,
            
            success = params.success ~= false,  -- 默认为 true
            error_message = params.error_message
        }
        
        -- 插入数据库
        return self:create(log_data)
    end,
    
    -- 根据操作类型推断分类
    infer_category = function(self, action)
        local category_map = {
            set_role = 'permission_change',
            set_teacher = 'permission_change',
            verify_user = 'user_management',
            delete_user = 'user_management',
            ban_user = 'content_moderation',
            unban_user = 'content_moderation',
            delete_project = 'content_moderation',
            change_email = 'user_management',
            reset_password = 'user_management'
        }
        
        return category_map[action] or 'other'
    end,
    
    -- 查询特定用户的操作历史
    -- @param user_id: 用户ID
    -- @param options table: 查询选项
    --   - limit: 返回数量限制
    --   - offset: 偏移量
    --   - action: 筛选特定操作
    get_user_history = function(self, user_id, options)
        options = options or {}
        
        local where_clause = 'WHERE target_id = ? AND target_type = ?'
        local params = {user_id, 'user'}
        
        if options.action then
            where_clause = where_clause .. ' AND action = ?'
            table.insert(params, options.action)
        end
        
        where_clause = where_clause .. ' ORDER BY created_at DESC'
        
        if options.limit then
            where_clause = where_clause .. ' LIMIT ?'
            table.insert(params, options.limit)
        end
        
        if options.offset then
            where_clause = where_clause .. ' OFFSET ?'
            table.insert(params, options.offset)
        end
        
        return self:select(where_clause, unpack(params))
    end,
    
    -- 查询特定操作者的操作历史
    get_operator_history = function(self, operator_id, options)
        options = options or {}
        
        local where_clause = 'WHERE operator_id = ?'
        local params = {operator_id}
        
        if options.action_category then
            where_clause = where_clause .. ' AND action_category = ?'
            table.insert(params, options.action_category)
        end
        
        where_clause = where_clause .. ' ORDER BY created_at DESC LIMIT ?'
        table.insert(params, options.limit or 50)
        
        return self:select(where_clause, unpack(params))
    end,
    
    -- 获取最近的敏感操作
    get_recent_sensitive = function(self, limit)
        limit = limit or 100
        return self:select(
            [[WHERE action IN ('set_role', 'set_teacher', 'delete_user', 'ban_user', 'unban_user')
              AND created_at > NOW() - INTERVAL '30 days'
              ORDER BY created_at DESC
              LIMIT ?]],
            limit
        )
    end
})

return AuditLogs
