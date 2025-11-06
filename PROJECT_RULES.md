# SnapCloud 项目开发规则参考

本文档记录了 SnapCloud 项目的关键开发规则、模式和约定。遵循这些规则可以避免常见错误，确保代码与项目架构保持一致。

---

## 目录

1. [路由规则](#路由规则)
2. [多语言规则](#多语言规则)
3. [权限验证规则](#权限验证规则)
4. [API 响应规则](#api-响应规则)
5. [数据库规则](#数据库规则)
6. [视图模板规则](#视图模板规则)
7. [Git 工作流规则](#git-工作流规则)

---

## 路由规则

### 1. 路由处理器返回值模式

**规则**: Lapis 框架要求路由处理器必须返回一致的数据类型（table）。

**错误模式** ❌:
```lua
app:get('/admin/something', capture_errors(function (self)
    if self.current_user then
        assert_admin(self)
        return { render = 'admin/something' }
    else
        return { redirect_to = self:build_url('/') }
    end
end))
```

**正确模式** ✅:
```lua
app:get('/admin/something', capture_errors(function (self)
    assert_exists(self.current_user)  -- 抛出异常，由 capture_errors 处理
    assert_admin(self)                -- 抛出异常，由 capture_errors 处理
    return { render = 'admin/something' }  -- 始终返回 table
end))
```

**原因**: 
- Lapis 通过 `capture_errors` 捕获异常并自动处理重定向
- if-else 结构返回不同类型的值会导致 "don't know how to respond to GET" 错误
- assert 函数通过 `yield_error` 抛出异常，不需要手动处理重定向

### 2. 路由参数捕获

**规则**: 使用命名捕获模式，参数名与 URL 路径对应。

```lua
-- 捕获单个参数
app:get('/class/:class_id/assignment/:assignment_id', ...)

-- 在处理器中访问
function (self)
    local class_id = self.params.class_id
    local assignment_id = self.params.assignment_id
    ...
end
```

### 3. JSON API 路由

**规则**: JSON API 路由必须使用 `jsonp` 响应类型。

```lua
app:post('/api/v1/something', jsonp(function(self)
    -- 处理逻辑
    return { json = { success = true, data = result } }
end))
```

---

## 多语言规则

### 1. 文本提取规则

**规则**: 使用 `i18n()` 函数包裹所有用户可见文本。

**适用范围**:
- ✅ 视图模板中的文本
- ✅ Flash 消息
- ✅ 错误消息
- ✅ 按钮标签
- ✅ 表单字段标签
- ❌ 日志消息
- ❌ 代码注释
- ❌ 数据库字段名

**示例**:

```lua
-- 视图中
<h1><%= i18n('class_detail_title') %></h1>

-- Flash 消息
self.session.flash = { 
    success = i18n('class_created_successfully') 
}

-- 错误消息
yield_error(i18n('permission_denied'))
```

### 2. 翻译文件结构

**位置**: `/locales/<language_code>.lua`

**格式**:
```lua
return {
    -- 使用下划线分隔的键名（snake_case）
    class_detail_title = "班级详情",
    assignment_created = "作业创建成功",
    
    -- 带参数的翻译（使用 %s, %d 等占位符）
    student_count = "共 %d 名学生",
    grade_display = "成绩: %s",
}
```

### 3. 自动翻译工具

**规则**: 使用项目提供的自动翻译工具。

```bash
# 提取新的硬编码文本
lua bin/extract_hardcoded_text.lua

# 自动翻译
lua bin/auto_translate.lua

# 应用翻译
lua bin/apply_translations.lua
```

**注意**:
- 提取前先备份翻译文件
- 检查自动翻译结果的准确性
- 技术术语可能需要人工校对

---

## 权限验证规则

### 1. 验证函数调用顺序

**规则**: 先验证存在性，再验证权限。

```lua
-- 正确顺序 ✅
assert_exists(self.current_user)  -- 1. 验证用户已登录
assert_teacher(self)              -- 2. 验证用户是教师
assert_class_owner(self, class)   -- 3. 验证用户拥有该班级

-- 错误顺序 ❌
assert_teacher(self.current_user)  -- 错误：传递了错误的参数
```

### 2. 权限验证函数定义位置

**文件**: `validation.lua`

**可用函数**:
- `assert_exists(value, message?)`: 验证值存在
- `assert_logged_in(self)`: 验证用户已登录
- `assert_admin(self)`: 验证用户是管理员
- `assert_teacher(self)`: 验证用户是教师
- `assert_role(self, role)`: 验证用户角色
- `assert_users_match(self, username)`: 验证当前用户匹配
- `assert_class_owner(self, class)`: 验证用户是班级所有者

**参数说明**:
- 所有 `assert_*` 函数的第一个参数都是 `self`（请求上下文）
- 不要传递 `self.current_user` 作为第一个参数

### 3. 自定义权限验证

**规则**: 在 `validation.lua` 中添加新的验证函数。

```lua
function assert_class_owner(self, class)
    if not self.current_user then
        yield_error(i18n('not_logged_in'))
    end
    if class.teacher_id ~= self.current_user.id then
        yield_error(i18n('permission_denied'))
    end
end
```

---

## API 响应规则

### 1. JSON 响应格式

**规则**: 统一使用以下格式。

**成功响应**:
```lua
return { json = {
    success = true,
    data = result,
    message = i18n('operation_successful')  -- 可选
}}
```

**错误响应**:
```lua
return { json = {
    success = false,
    error = i18n('error_message'),
    details = error_details  -- 可选，开发环境
}}
```

### 2. HTTP 状态码

**规则**: 明确设置适当的 HTTP 状态码。

```lua
-- 200 OK - 成功
return { json = { success = true }, status = 200 }

-- 201 Created - 创建成功
return { json = { success = true, id = new_id }, status = 201 }

-- 400 Bad Request - 请求参数错误
return { json = { success = false, error = "Invalid input" }, status = 400 }

-- 403 Forbidden - 权限不足
return { json = { success = false, error = "Permission denied" }, status = 403 }

-- 404 Not Found - 资源不存在
return { json = { success = false, error = "Not found" }, status = 404 }

-- 500 Internal Server Error - 服务器错误
return { json = { success = false, error = "Server error" }, status = 500 }
```

### 3. 分页响应

**规则**: 分页 API 应包含元数据。

```lua
return { json = {
    success = true,
    data = items,
    pagination = {
        page = current_page,
        per_page = items_per_page,
        total = total_items,
        total_pages = math.ceil(total_items / items_per_page)
    }
}}
```

---

## 数据库规则

### 1. 软删除

**规则**: 使用 `deleted_at` 字段实现软删除，而非真实删除数据。

**视图定义**:
```sql
-- 创建活跃记录视图
CREATE VIEW active_users AS
SELECT * FROM users WHERE deleted_at IS NULL;

CREATE VIEW active_classes AS
SELECT * FROM classes WHERE deleted_at IS NULL;
```

**Model 使用**:
```lua
-- 在 models/users.lua 中
local Users = Model:extend('active_users', {
    timestamp = true  -- 自动管理 created_at, updated_at
})
```

**软删除操作**:
```lua
-- 软删除
user:update({ deleted_at = db.format_date() })

-- 查询时自动过滤已删除记录（使用视图）
local active_users = Users:select('WHERE role = ?', 'student')
```

### 2. 时间戳字段

**规则**: 所有表应包含时间戳字段。

```sql
CREATE TABLE something (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP  -- 软删除标记
);
```

### 3. 外键约束

**规则**: 使用外键约束保证数据完整性。

```sql
CREATE TABLE class_memberships (
    id SERIAL PRIMARY KEY,
    class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ...
);
```

### 4. 视图用于复杂查询

**规则**: 为常用的复杂查询创建视图。

**示例**: `class_members_detail` 视图
```sql
CREATE VIEW class_members_detail AS
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
```

### 5. 数据库迁移

**规则**: 使用 Lapis 迁移系统管理数据库变更。

**位置**: `migrations.lua`

**格式**:
```lua
{
    [20251106000001] = function()
        return [[
            CREATE TABLE IF NOT EXISTS new_table (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        ]]
    end,
    
    [20251106000002] = function()
        return [[
            ALTER TABLE users ADD COLUMN nickname VARCHAR(255);
            ALTER TABLE users ADD COLUMN real_name VARCHAR(255);
        ]]
    end
}
```

**执行迁移**:
```bash
lapis migrate
```

---

## 视图模板规则

### 1. etlua 模板语法

**文件扩展名**: `.etlua`

**基本语法**:
```lua
-- 输出变量
<%= variable %>

-- 输出并转义 HTML
<%- html_content %>

-- Lua 代码块
<% for i, item in ipairs(items) do %>
    <li><%= item.name %></li>
<% end %>

-- 条件语句
<% if user.is_teacher then %>
    <p>教师界面</p>
<% else %>
    <p>学生界面</p>
<% end %>
```

### 2. 布局继承

**规则**: 使用 `layout` 指定父布局模板。

```lua
-- 在路由中指定布局
return { 
    render = 'teacher/class_detail',
    layout = 'layouts/teacher'  -- 使用教师布局
}
```

**布局文件**: `views/layouts/teacher.etlua`
```html
<!DOCTYPE html>
<html>
<head>
    <title><%= page_title or 'SnapCloud' %></title>
</head>
<body>
    <%- content_for('inner') %>  <!-- 子模板内容插入这里 -->
</body>
</html>
```

### 3. 数据传递

**规则**: 通过返回值传递数据到视图。

```lua
app:get('/class/:class_id', function(self)
    local class = Classes:find(self.params.class_id)
    local students = class:get_members()
    
    return { 
        render = 'teacher/class_detail',
        class = class,           -- 传递给视图
        students = students,     -- 传递给视图
        page_title = class.name  -- 传递给布局
    }
end)
```

**在视图中访问**:
```html
<h1><%= class.name %></h1>
<p>共 <%= #students %> 名学生</p>
```

### 4. 表单处理

**CSRF 保护**:
```html
<form method="POST" action="<%= url_for('create_assignment') %>">
    <%= csrf_input() %>  <!-- 必须包含 CSRF token -->
    <input type="text" name="title" required>
    <button type="submit">提交</button>
</form>
```

**表单验证**:
```lua
-- 在控制器中
app:post('/create-assignment', function(self)
    validate_csrf(self)  -- 验证 CSRF token
    
    validate_params(self, {
        { 'title', exists = true, min_length = 1 },
        { 'description', exists = true },
        { 'due_date', exists = true, is_date = true }
    })
    
    -- 创建作业...
end)
```

---

## Git 工作流规则

### 1. 分支管理

**规则**: 
- `main` 分支为主分支（来自上游仓库 snap-cloud/snapCloud）
- 功能开发使用特性分支
- 定期与上游同步

**工作流**:
```bash
# 1. 添加上游仓库（只需一次）
git remote add origin git@github.com:snap-cloud/snapCloud.git

# 2. 创建功能分支
git checkout -b feature/my-feature

# 3. 定期同步主分支
git fetch origin
git checkout main
git merge origin/main

# 4. 将主分支变更合并到功能分支
git checkout feature/my-feature
git rebase main  # 或 git merge main
```

### 2. 提交消息规范

**规则**: 使用语义化提交消息。

**格式**: `<type>(<scope>): <subject>`

**类型**:
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建、工具等

**示例**:
```bash
git commit -m "feat(class): 添加批量导入学生功能"
git commit -m "fix(auth): 修复管理员权限验证错误"
git commit -m "docs: 更新 API 文档"
```

### 3. 合并前检查

**规则**: 合并前必须完成以下检查。

**检查清单**:
```bash
# 1. 确保所有测试通过
make test

# 2. 检查代码风格
luacheck .

# 3. 确保没有合并冲突
git status

# 4. 创建备份（重要变更）
git tag backup-before-merge-$(date +%Y%m%d)
git push myfork backup-before-merge-$(date +%Y%m%d)

# 5. 查看将要合并的内容
git log origin/main..HEAD
git diff origin/main...HEAD

# 6. 执行合并
git rebase origin/main  # 或 git merge origin/main
```

### 4. 推送规则

**规则**: 
- 始终推送到自己的 fork（myfork）
- 不要直接推送到上游仓库（origin）

```bash
# 正确 ✅
git push myfork feature-branch

# 错误 ❌（除非是维护者）
git push origin feature-branch
```

---

## 常见错误及解决方案

### 1. 路由 500 错误

**症状**: "don't know how to respond to GET"

**原因**: 路由处理器返回值类型不一致

**解决方案**: 使用 `assert_exists` + `assert_*` 模式，始终返回 table

### 2. 翻译键未找到

**症状**: 页面显示 `translation_key` 而非翻译文本

**原因**: 翻译键在语言文件中不存在

**解决方案**:
```bash
# 1. 运行提取工具
lua bin/extract_hardcoded_text.lua

# 2. 检查 locales/ 目录
# 3. 手动添加缺失的翻译
```

### 3. 权限验证失败

**症状**: 即使已登录仍提示"未登录"

**原因**: 传递了错误的参数给验证函数

**解决方案**:
```lua
-- 错误 ❌
assert_admin(self.current_user)

-- 正确 ✅
assert_admin(self)
```

### 4. 视图变量未定义

**症状**: "attempt to index a nil value"

**原因**: 控制器未传递变量到视图

**解决方案**:
```lua
-- 在控制器返回值中包含所需变量
return {
    render = 'template',
    variable_name = value  -- 添加这行
}
```

### 5. 数据库查询返回已删除记录

**症状**: 软删除的记录仍然出现在查询结果中

**原因**: 使用了原始表而非视图

**解决方案**:
```lua
-- 错误 ❌
local Users = Model:extend('users')

-- 正确 ✅
local Users = Model:extend('active_users')
```

---

## 开发最佳实践

### 1. 日志记录

**规则**: 使用 Lapis 的日志函数。

```lua
-- 开发环境日志
print("[DEBUG] Processing assignment:", assignment_id)

-- 生产环境使用 ngx.log
ngx.log(ngx.INFO, "User created: ", user.username)
ngx.log(ngx.ERR, "Failed to create class: ", err)
```

### 2. 错误处理

**规则**: 使用 `capture_errors` 包装路由处理器。

```lua
app:get('/something', capture_errors(function(self)
    -- 任何 yield_error 调用都会被捕获
    -- 自动设置 flash 消息和重定向
end))
```

### 3. 性能优化

**规则**:
- 使用视图预先计算复杂查询
- 避免 N+1 查询问题
- 使用批量查询代替循环查询

```lua
-- 错误：N+1 查询 ❌
for i, class in ipairs(classes) do
    class.students = class:get_members()  -- 每个班级一次查询
end

-- 正确：批量查询 ✅
local all_members = ClassMemberships:select('WHERE class_id IN ?', class_ids)
-- 然后在内存中分组
```

### 4. 安全性

**规则**:
- 始终验证用户输入
- 使用参数化查询防止 SQL 注入
- 使用 CSRF 保护
- 不要在日志中记录敏感信息

```lua
-- 使用参数化查询 ✅
Users:select('WHERE username = ?', username)

-- 避免字符串拼接 ❌
db.query('SELECT * FROM users WHERE username = "' .. username .. '"')
```

---

## 项目结构参考

```
snapCloud/
├── controllers/        # 业务逻辑控制器
│   ├── class.lua      # 班级管理
│   ├── assignment.lua # 作业管理
│   └── user.lua       # 用户管理
├── models/            # 数据模型
│   ├── users.lua
│   ├── classes.lua
│   └── assignments.lua
├── views/             # 视图模板
│   ├── layouts/       # 布局模板
│   ├── teacher/       # 教师界面
│   └── student/       # 学生界面
├── locales/           # 多语言文件
│   ├── en.lua
│   ├── zh.lua
│   └── ...
├── bin/               # 工具脚本
│   ├── extract_hardcoded_text.lua
│   ├── auto_translate.lua
│   └── apply_translations.lua
├── db/                # 数据库脚本
│   ├── schema.sql
│   └── seeds.sql
├── static/            # 静态资源
├── site.lua           # 主路由文件
├── validation.lua     # 验证函数
├── responses.lua      # 响应辅助函数
└── migrations.lua     # 数据库迁移
```

---

## 参考资源

- **Lapis 官方文档**: https://leafo.net/lapis/
- **etlua 模板文档**: https://github.com/leafo/etlua
- **OpenResty 文档**: https://openresty.org/en/
- **PostgreSQL 文档**: https://www.postgresql.org/docs/

---

## 更新日志

- **2025-11-06**: 初始版本，基于班级管理、作业系统、批量导入功能开发经验总结

---

**注意**: 本文档会持续更新。遇到新的规则或模式时，请及时补充到相应章节。
