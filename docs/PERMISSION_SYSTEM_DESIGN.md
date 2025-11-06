# 权限系统设计文档
# Permission System Design Document

> **版本**: 2.0  
> **更新日期**: 2025-11-06  
> **作者**: moodykeke@gmail.com

---

## 目录

- [1. 概述](#1-概述)
- [2. 角色定义](#2-角色定义)
- [3. 权限矩阵](#3-权限矩阵)
- [4. 关系类型](#4-关系类型)
- [5. 权限函数详解](#5-权限函数详解)
- [6. 权限缓存机制](#6-权限缓存机制)
- [7. 安全审计](#7-安全审计)
- [8. 性能优化](#8-性能优化)
- [9. 使用示例](#9-使用示例)
- [10. 测试指南](#10-测试指南)

---

## 1. 概述

SnapCloud 权限系统采用**基于角色的访问控制（RBAC）**和**基于关系的权限扩展**相结合的混合模型。

### 设计原则

1. **最小权限原则**: 用户默认只能访问自己的资源
2. **职责分离**: 管理员（修改）、版主（监督）、教师（教学）、学生（学习）
3. **关系继承**: 创建者和班级教师对学生拥有管理权限
4. **安全优先**: 敏感操作（角色变更、教师身份）仅限管理员
5. **可追溯性**: 所有权限变更记录审计日志

### 核心文件

```
lib/
├── user_permissions.lua      # 权限检查函数库
├── permission_cache.lua      # 请求级缓存
└── global.lua                # 全局辅助函数

models/
├── users.lua                 # 用户模型
├── audit_logs.lua            # 审计日志模型
└── class_memberships.lua     # 班级成员关系

controllers/
└── user.lua                  # 用户管理控制器（含审计）
```

---

## 2. 角色定义

### 系统角色

| 角色 | 英文名 | 权限级别 | 说明 |
|------|--------|----------|------|
| 管理员 | `admin` | 5 | 系统最高权限，可修改所有用户的角色和教师身份 |
| 版主 | `moderator` | 4 | 只读监督权限，可查看所有信息但不能修改角色 |
| 标准用户 | `standard` | 3 | 普通用户，仅能访问自己的资源 |
| 已封禁 | `banned` | 0 | 被封禁用户，无法登录 |

### 特殊身份

| 身份 | 字段 | 说明 |
|------|------|------|
| 教师 | `is_teacher=true` | 可创建班级、导入学生、布置作业 |
| 学生 | `creator_id IS NOT NULL` | 由教师或管理员创建的账号 |

---

## 3. 权限矩阵

### 信息查看权限

| 权限功能 | 本人 | 管理员 | 版主 | 创建者 | 班级教师 | 无关教师 | 普通用户 |
|---------|------|--------|------|--------|----------|----------|----------|
| 查看用户名 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 查看邮箱 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 查看真实姓名 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 查看昵称 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 查看学生统计 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 查看用户ID | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| 查看创建者 | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

### 编辑权限

| 权限功能 | 本人 | 管理员 | 版主 | 创建者 | 班级教师 | 无关教师 | 普通用户 |
|---------|------|--------|------|--------|----------|----------|----------|
| 编辑邮箱 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 重置密码 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 修改用户名 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 修改真实姓名 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 修改昵称 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 修改角色 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 修改教师身份 | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 封禁/解封 | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| 删除用户 | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

### 管理权限

| 权限功能 | 本人 | 管理员 | 版主 | 创建者 | 班级教师 | 无关教师 | 普通用户 |
|---------|------|--------|------|--------|----------|----------|----------|
| 查看项目 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 管理班级成员 | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 查看作业提交 | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 发送消息 | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| 模拟登录(Become) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 4. 关系类型

### 4.1 创建者关系 (Creator Relationship)

**定义**: 教师通过批量导入功能创建的学生账号

**数据库表示**:
```sql
users.creator_id = teacher.id
```

**权限范围**:
- ✅ 查看真实姓名、邮箱
- ✅ 查看学生统计（班级、作业）
- ✅ 编辑基本信息（邮箱、密码、用户名）
- ✅ 管理账号（重置密码、发送消息）

**特点**:
- 永久关系（除非删除账号）
- 不受班级变动影响
- 适用于学校内部管理

### 4.2 班级关系 (Class Membership Relationship)

**定义**: 学生加入教师创建的班级

**数据库表示**:
```sql
class_memberships:
  - class_id (引用 collections.id, where is_class=true)
  - student_id (引用 users.id)
  - deleted_at IS NULL (软删除标记)

collections:
  - creator_id = teacher.id
  - is_class = true
```

**权限范围**:
- ✅ 查看真实姓名、邮箱
- ✅ 查看学生统计
- ✅ 编辑基本信息
- ✅ 管理班级成员

**特点**:
- 动态关系（可添加/移除）
- 支持多对多（一个学生可加入多个班级）
- 软删除机制（deleted_at）

### 4.3 关系组合场景

#### 场景1: 单一创建者关系
```
教师A创建学生S
→ 教师A有创建者权限
```

#### 场景2: 单一班级关系
```
教师B创建班级C
教师B将学生S添加到班级C
→ 教师B有班级权限
```

#### 场景3: 多重关系（推荐模式）
```
教师A创建学生S（创建者关系）
教师A创建班级C1
教师A将学生S添加到C1（班级关系）
教师B创建班级C2
教师B将学生S添加到C2（班级关系）

结果：
- 教师A有创建者权限 + 班级C1权限
- 教师B有班级C2权限
- 两位教师都可以查看/管理学生S
```

#### 场景4: 关系失效
```
教师B从班级C2移除学生S（软删除）
→ 教师B失去对S的班级权限
→ 教师A仍保留创建者权限
```

---

## 5. 权限函数详解

### 5.1 can_view_real_name

**功能**: 检查是否可以查看目标用户的真实姓名

**允许条件**:
1. 查看者是本人
2. 查看者是管理员或版主
3. 查看者是目标用户的创建者
4. 查看者是目标学生的班级教师

**实现逻辑**:
```lua
M.can_view_real_name = function(viewer, target_user)
    return cache.check_with_cache(viewer, target_user, 'view_real_name', function(v, t)
        if not v or not t then return false end
        
        -- 本人
        if v.id == t.id then return true end
        
        -- 管理员/版主
        if v:has_min_role('moderator') then return true end
        
        -- 创建者关系
        if t.creator_id and t.creator_id == v.id then
            return true
        end
        
        -- 班级关系
        if v.is_teacher and t:is_student() then
            local db = require('lapis.db')
            local result = db.query([[
                SELECT EXISTS (
                    SELECT 1 
                    FROM class_memberships cm
                    JOIN collections c ON cm.class_id = c.id
                    WHERE cm.student_id = ?
                      AND c.creator_id = ?
                      AND c.is_class = true
                      AND cm.deleted_at IS NULL
                ) AS is_class_teacher
            ]], t.id, v.id)
            
            if result and result[1] and result[1].is_class_teacher then
                return true
            end
        end
        
        return false
    end)
end
```

**SQL查询说明**:
- 使用 `EXISTS` 子查询（比 `COUNT(*)` 更快）
- JOIN `class_memberships` 和 `collections` 表
- 验证 `is_class=true` 确保是班级而非普通合集
- 检查 `deleted_at IS NULL` 排除已移除成员
- 利用现有索引：
  - `class_memberships_student_id_idx`
  - `class_memberships_class_id_idx`
  - `collections_creator_id_idx`
  - `collections_is_class_idx`

### 5.2 can_view_email

**功能**: 检查是否可以查看目标用户的邮箱

**允许条件**: 同 `can_view_real_name`

**实现**: 同样的逻辑和SQL查询

### 5.3 can_view_student_stats

**功能**: 检查是否可以查看学生的统计信息（班级、作业）

**允许条件**:
1. 学生本人
2. 管理员或版主
3. 创建者
4. 班级教师

**特殊检查**:
```lua
-- 只有学生账号才有统计信息
if not t:is_student() then return false end
```

### 5.4 can_manage_user

**功能**: 检查是否可以管理目标用户

**允许条件**:
1. 管理员或版主
2. 创建者
3. 班级教师

**管理操作包括**:
- 查看用户详情
- 重置密码
- 发送消息
- 查看项目/作业

### 5.5 can_edit_user_info

**功能**: 检查是否可以编辑用户基本信息

**允许条件**:
1. 本人
2. 管理员或版主
3. 创建者
4. 班级教师

**可编辑信息**:
- 邮箱
- 密码
- 用户名
- 真实姓名
- 昵称

### 5.6 can_edit_role

**功能**: 检查是否可以修改用户角色

**允许条件**: **仅限管理员**

**安全考虑**:
- 角色变更是高危操作
- 版主不能修改角色（防止权限提升）
- 教师不能修改角色（防止滥用）

**审计日志**:
```lua
-- controllers/user.lua
AuditLogs:log({
    action = 'role_change',
    operator_id = current_user.id,
    operator_username = current_user.username,
    operator_role = current_user.role,
    target_type = 'user',
    target_id = target_user.id,
    target_username = target_user.username,
    old_value = old_role,
    new_value = new_role,
    ip_address = request_ip,
    user_agent = request_ua
})
```

### 5.7 can_edit_teacher_status

**功能**: 检查是否可以修改教师身份

**允许条件**: **仅限管理员**

**安全考虑**:
- 教师身份影响系统功能（创建班级、批量导入）
- 防止教师互相授予教师身份
- 防止版主滥用

### 5.8 can_view_admin_info

**功能**: 检查是否可以查看管理信息（用户ID、创建者等）

**允许条件**: **仅限管理员和版主**

**包含信息**:
- 用户ID
- 创建者ID
- IP地址（审计日志）
- 创建时间

---

## 6. 权限缓存机制

### 6.1 缓存策略

**类型**: 请求级缓存（Request-scoped Cache）

**实现**: `lib/permission_cache.lua`

**生命周期**: 单个HTTP请求

**存储位置**: `ngx.ctx.permission_cache`

**自动清理**: OpenResty在请求结束时自动清理 `ngx.ctx`

### 6.2 缓存键设计

**格式**:
```
perm:{viewer_id}:{viewer_updated_at}:{target_id}:{target_updated_at}:{permission}
```

**示例**:
```
perm:123:2025-11-06_10:00:00:456:2025-11-06_09:30:00:view_real_name
```

**版本化机制**:
- 用户角色变更 → `updated_at` 改变
- 缓存键变化 → 缓存失效
- 重新计算权限 → 立即生效

### 6.3 缓存失效

**自动失效场景**:

1. **角色变更**:
```sql
UPDATE users SET role = 'moderator', updated_at = now() WHERE id = 123;
-- 缓存键从 perm:123:2025-11-06_10:00:00:... 
-- 变为       perm:123:2025-11-06_10:05:00:...
-- 旧缓存失效
```

2. **教师身份变更**:
```sql
UPDATE users SET is_teacher = true, updated_at = now() WHERE id = 456;
-- 同样触发缓存失效
```

3. **请求结束**:
```
OpenResty自动清理 ngx.ctx
所有缓存项丢弃
```

**手动失效（不需要）**:
- ❌ 不需要调用 `cache.clear_all()`
- ❌ 不需要调用 `cache.invalidate_user()`
- ✅ 数据库 `updated_at` 自动管理版本

### 6.4 性能提升

**缓存命中率**: 约80%（单个请求内重复检查）

**典型场景**:
```
用户列表页显示100个学生
→ 每个学生卡片调用5次权限检查
→ 总计500次权限检查
→ 缓存后只需100次数据库查询
→ 节省400次数据库访问（80%）
```

---

## 7. 安全审计

### 7.1 审计日志表

**表名**: `audit_logs`

**字段**:
```sql
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    action VARCHAR(100) NOT NULL,           -- 操作类型
    operator_id INTEGER,                     -- 操作者ID
    operator_username VARCHAR(255),          -- 操作者用户名
    operator_role VARCHAR(50),               -- 操作者角色
    target_type VARCHAR(50),                 -- 目标类型
    target_id INTEGER,                       -- 目标ID
    target_username VARCHAR(255),            -- 目标用户名
    old_value TEXT,                          -- 旧值
    new_value TEXT,                          -- 新值
    ip_address VARCHAR(50),                  -- IP地址
    user_agent TEXT,                         -- 浏览器信息
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    category VARCHAR(50) GENERATED ALWAYS AS (
        CASE 
            WHEN action IN ('role_change', 'teacher_status_change') THEN 'permission'
            WHEN action IN ('ban', 'unban', 'delete_user') THEN 'moderation'
            WHEN action IN ('email_change', 'password_reset') THEN 'account'
            ELSE 'other'
        END
    ) STORED
);
```

### 7.2 审计操作类型

| 操作 | action值 | category | 记录内容 |
|------|----------|----------|----------|
| 角色变更 | `role_change` | permission | old_value=旧角色, new_value=新角色 |
| 教师身份变更 | `teacher_status_change` | permission | old_value=旧状态, new_value=新状态 |
| 封禁 | `ban` | moderation | target_username |
| 解封 | `unban` | moderation | target_username |
| 删除用户 | `delete_user` | moderation | target_username |
| 邮箱变更 | `email_change` | account | old_value=旧邮箱, new_value=新邮箱 |
| 密码重置 | `password_reset` | account | target_username |

### 7.3 审计查询

**查看最近30天敏感操作**:
```sql
SELECT * FROM recent_sensitive_operations;
-- 视图定义
CREATE OR REPLACE VIEW recent_sensitive_operations AS
SELECT * FROM audit_logs
WHERE category IN ('permission', 'moderation')
  AND created_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
ORDER BY created_at DESC
LIMIT 100;
```

**查看特定用户的历史变更**:
```lua
local AuditLogs = require('models.audit_logs')
local history = AuditLogs:get_user_history(user_id, {
    limit = 50,
    category = 'permission'
})
```

**查看特定管理员的操作记录**:
```lua
local actions = AuditLogs:get_operator_history(admin_id, {
    limit = 100,
    start_date = '2025-11-01'
})
```

### 7.4 双重日志

**文件日志** (nginx error.log):
```
[WARN] [AUDIT] Role changed: user=student_1, old_role=standard, new_role=moderator, operator=admin_a
```

**数据库日志** (audit_logs表):
```lua
AuditLogs:log({
    action = 'role_change',
    operator_id = 1,
    operator_username = 'admin_a',
    operator_role = 'admin',
    target_type = 'user',
    target_id = 456,
    target_username = 'student_1',
    old_value = 'standard',
    new_value = 'moderator',
    ip_address = '192.168.1.100',
    user_agent = 'Mozilla/5.0...'
})
```

**优点**:
- 文件日志：实时、易于grep、不受数据库故障影响
- 数据库日志：结构化、可查询、支持复杂分析

---

## 8. 性能优化

### 8.1 数据库索引

**现有索引**:
```sql
-- class_memberships 表
CREATE INDEX class_memberships_student_id_idx 
ON class_memberships(student_id) WHERE deleted_at IS NULL;

CREATE INDEX class_memberships_class_id_idx 
ON class_memberships(class_id) WHERE deleted_at IS NULL;

-- collections 表
CREATE INDEX collections_creator_id_idx 
ON collections(creator_id);

CREATE INDEX collections_is_class_idx 
ON collections(is_class) WHERE is_class = true;

-- users 表
CREATE INDEX users_creator_id_idx 
ON users(creator_id) WHERE creator_id IS NOT NULL;
```

### 8.2 查询优化

**使用 EXISTS 而非 COUNT**:
```sql
-- ❌ 慢查询
SELECT COUNT(*) FROM class_memberships cm
JOIN collections c ON cm.class_id = c.id
WHERE cm.student_id = ? AND c.creator_id = ?;

-- ✅ 快速查询
SELECT EXISTS (
    SELECT 1 FROM class_memberships cm
    JOIN collections c ON cm.class_id = c.id
    WHERE cm.student_id = ? AND c.creator_id = ?
) AS is_class_teacher;
```

**原因**: EXISTS在找到第一条记录后立即返回，COUNT需要扫描所有记录

### 8.3 缓存命中率监控

**建议监控指标**:
```lua
-- 在 permission_cache.lua 中添加计数器
local cache_hits = 0
local cache_misses = 0

M.get = function(viewer, target, permission)
    local key = make_key(viewer, target, permission)
    local store = get_cache_store()
    
    if store[key] ~= nil then
        cache_hits = cache_hits + 1
        return store[key]
    else
        cache_misses = cache_misses + 1
        return nil
    end
end

M.get_stats = function()
    return {
        hits = cache_hits,
        misses = cache_misses,
        ratio = cache_hits / (cache_hits + cache_misses)
    }
end
```

### 8.4 慢查询分析

**PostgreSQL配置**:
```sql
-- postgresql.conf
log_min_duration_statement = 100  -- 记录超过100ms的查询
```

**查找慢查询**:
```bash
grep "duration:" /var/log/postgresql/postgresql.log | \
  grep "class_memberships" | \
  sort -t: -k2 -n | tail -20
```

---

## 9. 使用示例

### 9.1 视图中使用权限

**views/partials/profile.etlua**:
```html
<% local user_permissions = require('lib.user_permissions') %>

<!-- 条件显示真实姓名 -->
<% if user_permissions.can_view_real_name(current_user, item) then %>
    <% if item.real_name and item.real_name ~= '' then %>
    <span class="text-muted small"><%= item.real_name %></span>
    <% end %>
<% end %>

<!-- 条件显示邮箱 -->
<% if user_permissions.can_view_email(current_user, item) then %>
    <a href="mailto:<%= item.email %>"><%= item.email %></a>
<% end %>

<!-- 条件显示编辑按钮 -->
<% if user_permissions.can_edit_user_info(current_user, item) then %>
    <a class="btn btn-sm btn-outline-secondary" 
       onclick="changeEmail('<%= item.username %>')">
        更改邮箱
    </a>
<% end %>
```

### 9.2 控制器中使用权限

**controllers/user.lua**:
```lua
local user_permissions = require('lib.user_permissions')

-- 检查权限
if not user_permissions.can_edit_user_info(self.current_user, target_user) then
    yield_error('You do not have permission to edit this user')
end

-- 执行操作
target_user:update({ email = new_email })

-- 记录审计日志
local AuditLogs = require('models.audit_logs')
AuditLogs:log({
    action = 'email_change',
    operator_id = self.current_user.id,
    operator_username = self.current_user.username,
    target_type = 'user',
    target_id = target_user.id,
    target_username = target_user.username,
    old_value = old_email,
    new_value = new_email,
    ip_address = self.req.headers['x-real-ip'] or ngx.var.remote_addr,
    user_agent = self.req.headers['user-agent']
})
```

### 9.3 API中使用权限

**api/user_info.lua**:
```lua
local user_permissions = require('lib.user_permissions')

local function get_user_info(self)
    local username = self.params.username
    local target_user = Users:find({ username = username })
    
    if not target_user then
        return jsonResponse({ error = 'User not found' }, 404)
    end
    
    local response = {
        username = target_user.username,
        nickname = target_user.nickname
    }
    
    -- 条件添加真实姓名
    if user_permissions.can_view_real_name(self.current_user, target_user) then
        response.real_name = target_user.real_name
    end
    
    -- 条件添加邮箱
    if user_permissions.can_view_email(self.current_user, target_user) then
        response.email = target_user.email
    end
    
    -- 条件添加学生统计
    if user_permissions.can_view_student_stats(self.current_user, target_user) then
        response.classes = target_user:get_student_classes()
        response.assignments = target_user:get_assignment_stats()
    end
    
    return jsonResponse(response)
end
```

---

## 10. 测试指南

### 10.1 单元测试

**test_permission_improvements.lua**:
```bash
lua test_permission_improvements.lua
```

**输出示例**:
```
=================================================
权限改进测试计划
Permission Improvement Test Plan
=================================================

【测试场景 1】创建者关系权限
Scenario 1: Creator Relationship Permissions
-------------------------------------------------
✓ teacher_a.can_view_real_name(student_1) = true
✓ teacher_a.can_view_email(student_1) = true
...
```

### 10.2 集成测试

**步骤1: 准备测试数据**
```sql
-- 运行 test_permission_improvements.lua 中的SQL
-- 创建测试教师和学生
```

**步骤2: 测试创建者权限**
```bash
# 以 teacher_a 登录
curl -X POST https://cloud.snap.berkeley.edu/login \
  -d "username=teacher_a&password=test123"

# 访问学生信息
curl https://cloud.snap.berkeley.edu/api/users/student_1 \
  -H "Cookie: session=..."

# 验证响应包含 real_name 和 email
```

**步骤3: 测试班级权限**
```bash
# 以 teacher_b 登录
curl -X POST https://cloud.snap.berkeley.edu/login \
  -d "username=teacher_b&password=test123"

# 访问学生信息
curl https://cloud.snap.berkeley.edu/api/users/student_1

# 验证响应包含 real_name（班级关系）
```

**步骤4: 测试权限隔离**
```bash
# 以 teacher_c 登录
curl -X POST https://cloud.snap.berkeley.edu/login \
  -d "username=teacher_c&password=test123"

# 访问 student_2
curl https://cloud.snap.berkeley.edu/api/users/student_2

# 验证响应不包含 real_name 和 email
```

### 10.3 性能测试

**测试缓存效果**:
```lua
-- 在 permission_cache.lua 中启用统计
local stats_before = cache.get_stats()

-- 渲染用户列表页（100个学生）
render('views.users_list', { users = students })

local stats_after = cache.get_stats()

print('Cache hits: ' .. (stats_after.hits - stats_before.hits))
print('Cache misses: ' .. (stats_after.misses - stats_before.misses))
print('Hit ratio: ' .. stats_after.ratio)
```

**预期结果**:
```
Cache hits: 400
Cache misses: 100
Hit ratio: 0.80  (80%)
```

### 10.4 安全测试

**测试权限提升防护**:
```bash
# 尝试以版主修改角色（应失败）
curl -X POST https://cloud.snap.berkeley.edu/users/student_1/set_role \
  -H "Cookie: session=moderator_session" \
  -d "role=admin"

# 预期: 403 Forbidden 或权限错误
```

**测试审计日志**:
```sql
-- 查看最近的角色变更
SELECT * FROM audit_logs 
WHERE action = 'role_change' 
ORDER BY created_at DESC 
LIMIT 10;

-- 验证包含 operator_id、old_value、new_value、ip_address
```

---

## 11. 故障排查

### 11.1 常见问题

#### 问题1: 教师看不到班级学生的真实姓名

**症状**: 教师B将学生S加入班级C，但仍看不到真实姓名

**排查步骤**:
```sql
-- 1. 确认学生在班级中
SELECT * FROM class_memberships 
WHERE student_id = ? AND class_id = ? AND deleted_at IS NULL;

-- 2. 确认班级属性
SELECT id, name, creator_id, is_class FROM collections 
WHERE id = ?;

-- 3. 确认教师身份
SELECT id, username, is_teacher FROM users WHERE id = ?;

-- 4. 手动测试SQL查询
SELECT EXISTS (
    SELECT 1 
    FROM class_memberships cm
    JOIN collections c ON cm.class_id = c.id
    WHERE cm.student_id = ?
      AND c.creator_id = ?
      AND c.is_class = true
      AND cm.deleted_at IS NULL
) AS is_class_teacher;
```

**可能原因**:
- `is_class` 未设置为 `true`
- `deleted_at` 不为 `NULL`（学生已被移除）
- 教师 `is_teacher` 为 `false`
- 缓存问题（刷新页面）

#### 问题2: 权限缓存未失效

**症状**: 修改用户角色后，权限未立即生效

**排查步骤**:
```sql
-- 1. 检查 updated_at 是否更新
SELECT id, username, role, updated_at FROM users WHERE id = ?;

-- 2. 确认触发器存在
SELECT * FROM information_schema.triggers 
WHERE event_object_table = 'users';
```

**解决方案**:
```sql
-- 手动触发 updated_at 更新
UPDATE users SET updated_at = now() WHERE id = ?;
```

#### 问题3: 审计日志缺失

**症状**: 角色变更但无审计记录

**排查步骤**:
```lua
-- 检查 AuditLogs 调用是否在 pcall 中
local success, err = pcall(function()
    AuditLogs:log({...})
end)

if not success then
    ngx.log(ngx.ERR, '[AUDIT] Failed to log: ' .. err)
end
```

**常见错误**:
- `audit_logs` 表不存在（运行 `create_audit_logs_table.sql`）
- 数据库连接问题
- 字段类型不匹配

### 11.2 调试技巧

**启用权限调试日志**:
```lua
-- lib/user_permissions.lua
M.can_view_real_name = function(viewer, target_user)
    local result = cache.check_with_cache(viewer, target_user, 'view_real_name', function(v, t)
        -- ... 权限逻辑 ...
        
        ngx.log(ngx.INFO, string.format(
            '[PERM] view_real_name: viewer=%s(role=%s, is_teacher=%s), target=%s, result=%s',
            v.username, v.role, tostring(v.is_teacher),
            t.username, tostring(result)
        ))
        
        return result
    end)
    return result
end
```

**查看nginx日志**:
```bash
tail -f /var/log/nginx/error.log | grep PERM
```

---

## 12. 未来改进

### 12.1 短期计划

- [ ] 添加权限缓存统计仪表板
- [ ] 实现审计日志导出功能（CSV/JSON）
- [ ] 添加权限变更通知（邮件/站内信）
- [ ] 优化班级权限查询（预加载）

### 12.2 长期规划

- [ ] 支持自定义角色（beyond admin/moderator/standard）
- [ ] 细粒度权限控制（per-feature permissions）
- [ ] 权限模板系统（role templates）
- [ ] 权限审批流程（approval workflow）

---

## 附录

### A. 数据库Schema

**完整Schema**: `db/class_management_schema.sql`

**核心表**:
- `users`: 用户表（含 creator_id, is_teacher, role）
- `collections`: 班级/合集表（含 is_class）
- `class_memberships`: 班级成员关系表
- `audit_logs`: 审计日志表

### B. 相关文件

| 文件 | 说明 |
|------|------|
| `lib/user_permissions.lua` | 权限检查函数库 |
| `lib/permission_cache.lua` | 请求级缓存 |
| `models/audit_logs.lua` | 审计日志模型 |
| `models/class_memberships.lua` | 班级成员模型 |
| `controllers/user.lua` | 用户管理控制器 |
| `views/partials/profile.etlua` | 用户卡片视图 |
| `test_permission_improvements.lua` | 测试计划脚本 |
| `db/create_audit_logs_table.sql` | 审计日志表SQL |
| `db/class_management_schema.sql` | 班级管理Schema |

### C. API参考

**权限函数列表**:
```lua
user_permissions.can_view_real_name(viewer, target)
user_permissions.can_view_email(viewer, target)
user_permissions.can_view_student_stats(viewer, target)
user_permissions.can_manage_user(viewer, target)
user_permissions.can_view_admin_info(viewer, target)
user_permissions.can_edit_role(viewer, target)
user_permissions.can_edit_teacher_status(viewer, target)
user_permissions.can_edit_user_info(viewer, target)
```

**缓存函数列表**:
```lua
cache.get(viewer, target, permission)
cache.set(viewer, target, permission, value)
cache.check_with_cache(viewer, target, permission, compute_fn)
cache.clear_all()  -- 通常不需要
cache.invalidate_user(user_id)  -- 通常不需要
```

---

**文档版本历史**:
- v2.0 (2025-11-06): 添加班级教师权限支持
- v1.0 (2025-11-05): 初始版本，基础RBAC权限系统
