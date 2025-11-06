-- 权限缓存系统 - 请求级缓存，自动失效
-- Permission Cache System - Request-scoped cache with auto-invalidation
--
-- 设计原则：
-- 1. 缓存生命周期 = 单次HTTP请求
-- 2. 每次请求结束自动清理，避免脏数据
-- 3. 缓存键包含版本号（用户updated_at），数据变更后自动失效
-- 4. 明确标记哪些操作会导致缓存失效

local M = {}

-- 请求级缓存存储（存储在 ngx.ctx 中，请求结束自动清理）
-- Cache storage in ngx.ctx (auto-cleared after request)
local function get_cache_store()
    if not ngx then
        -- 测试环境或非OpenResty环境，使用内存缓存
        if not M._test_cache then
            M._test_cache = {}
        end
        return M._test_cache
    end
    
    if not ngx.ctx.permission_cache then
        ngx.ctx.permission_cache = {}
    end
    return ngx.ctx.permission_cache
end

-- 生成缓存键
-- @param viewer: 查看者对象
-- @param target: 目标用户对象
-- @param permission: 权限名称，如 'view_real_name'
-- @return string: 缓存键
M.make_key = function(viewer, target, permission)
    if not viewer or not target then
        return nil
    end
    
    -- 包含用户ID和updated_at作为版本号
    -- 任何用户数据变更都会导致updated_at改变，从而使缓存失效
    local viewer_version = viewer.updated or viewer.created or ''
    local target_version = target.updated or target.created or ''
    
    return string.format(
        "perm:%d:%s:%d:%s:%s",
        viewer.id,
        viewer_version,
        target.id,
        target_version,
        permission
    )
end

-- 从缓存获取
-- @param key: 缓存键
-- @return boolean|nil: 缓存的权限结果，nil表示未缓存
M.get = function(key)
    if not key then return nil end
    
    local cache = get_cache_store()
    return cache[key]
end

-- 设置缓存
-- @param key: 缓存键
-- @param value: boolean 权限检查结果
M.set = function(key, value)
    if not key then return end
    
    local cache = get_cache_store()
    cache[key] = value
end

-- 带缓存的权限检查包装器
-- @param viewer: 查看者
-- @param target: 目标用户
-- @param permission_name: 权限名称
-- @param check_func: 实际的权限检查函数
-- @return boolean: 权限检查结果
M.check_with_cache = function(viewer, target, permission_name, check_func)
    local key = M.make_key(viewer, target, permission_name)
    
    -- 尝试从缓存获取
    local cached = M.get(key)
    if cached ~= nil then
        return cached
    end
    
    -- 缓存未命中，执行实际检查
    local result = check_func(viewer, target)
    
    -- 存入缓存
    M.set(key, result)
    
    return result
end

-- 清除整个缓存（用于测试或调试）
M.clear_all = function()
    if ngx and ngx.ctx then
        ngx.ctx.permission_cache = {}
    end
    M._test_cache = {}
end

-- 清除特定用户相关的所有缓存（当用户数据变更时调用）
-- 注意：由于使用了 updated_at 作为版本号，实际上不需要手动清除
-- 用户数据更新后，updated_at 会变化，旧的缓存键自然失效
M.invalidate_user = function(user_id)
    -- 由于使用版本化缓存键，此函数实际上是空操作
    -- 仅保留接口用于日志记录
    if ngx then
        ngx.log(ngx.INFO, 
            string.format("[CACHE] User %d data changed, cache auto-invalidated by version", 
                user_id))
    end
end

return M
