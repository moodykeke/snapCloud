# 用户信息增强功能开发计划

## 📋 项目概述

**目标**: 增强用户个人信息显示，提供更清晰、更完善的信息展示，并根据不同权限显示不同内容。

**涉及页面**:
1. 管理员用户管理页面: `/user_admin`
2. 教师学生管理页面: `/learners`
3. 个人信息页面: `/profile`
4. 用户详情卡片: `views/partials/profile.etlua`

**优先级**: 高
**预计工期**: 2-3天

---

## 🎯 需求分析

### 当前问题

从截图分析，当前用户信息卡片存在以下问题：

1. **信息不完整**:
   - ✅ 显示: 用户名、邮箱、用户ID、加入日期、角色
   - ❌ 缺少: 昵称(nickname)、真实姓名(real_name)、项目数量统计、班级信息

2. **权限混乱**:
   - 所有用户信息对所有管理员都完全可见
   - 缺少细粒度的权限控制
   - 学生的真实姓名对所有人可见（应该限制）

3. **界面不直观**:
   - 信息密集，缺少视觉层次
   - 关键信息（如角色、状态）不突出
   - 缺少图标和色彩区分

4. **功能缺失**:
   - 没有快速查看学生所属班级
   - 没有显示学生的作业提交统计
   - 没有显示创建者信息（对于学生账号）

### 权限需求矩阵

| 信息字段 | 学生本人 | 教师(创建者) | 教师(其他) | 版主 | 管理员 |
|---------|---------|------------|-----------|------|-------|
| 用户名 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 邮箱 | ✅ | ✅ | ❌ | ✅ | ✅ |
| 昵称 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 真实姓名 | ✅ | ✅ | ❌ | ❌ | ✅ |
| 用户ID | ❌ | ❌ | ❌ | ✅ | ✅ |
| 加入日期 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 角色 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Creator ID | ❌ | ✅ | ❌ | ✅ | ✅ |
| 项目数量 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 所属班级 | ✅ | ✅ | ❌ | ❌ | ✅ |
| 作业统计 | ✅ | ✅ | ❌ | ❌ | ✅ |

---

## 📐 设计方案

### 1. 信息架构重组

#### A. 基础信息区 (所有人可见)
```
┌─────────────────────────────────────┐
│ 👤 用户名 (username)          [角色徽章] │
│ 📧 邮箱 (根据权限)                     │
│ 🏷️  昵称 (nickname)                   │
│ 📅 加入日期                           │
│ 📊 项目数量: X 个                     │
└─────────────────────────────────────┘
```

#### B. 身份信息区 (有权限者可见)
```
┌─────────────────────────────────────┐
│ 📝 真实姓名: XXX                      │
│ 🆔 用户ID: 12345                     │
│ 👨‍🏫 创建者: teacher@example.com      │
└─────────────────────────────────────┘
```

#### C. 学习统计区 (学生账号)
```
┌─────────────────────────────────────┐
│ 📚 所属班级: 2 个                     │
│   • 一年级A班 (张老师)                │
│   • 编程入门班 (李老师)               │
│                                      │
│ ✍️  作业完成: 15/20 (75%)            │
│ ⭐ 平均分数: 85 分                   │
└─────────────────────────────────────┘
```

#### D. 操作按钮区 (根据权限)
```
┌─────────────────────────────────────┐
│ [切换身份] [验证账号] [重置密码]      │
│ [修改邮箱] [修改用户名] [发送消息]    │
│ [封禁/解封] [删除用户]                │
└─────────────────────────────────────┘
```

### 2. UI/UX 设计原则

**遵循 PROJECT_RULES.md 规则**:
- ✅ 使用 Bootstrap 5 样式类
- ✅ 使用 Font Awesome 图标
- ✅ 多语言支持（使用 `locale.get()`）
- ✅ 响应式设计（移动端友好）
- ✅ 无障碍访问（ARIA 标签）

**视觉层次**:
1. **色彩编码**:
   - 🔴 管理员: `badge-danger` / `text-bg-danger`
   - 🔵 版主: `badge-info` / `text-bg-info`
   - 🟢 教师: `badge-success` / `text-bg-success`
   - 🟡 学生: `badge-warning` / `text-bg-warning`
   - ⚪ 标准用户: `badge-secondary` / `text-bg-secondary`

2. **图标系统**:
   - 👤 用户名: `fa-user`
   - 📧 邮箱: `fa-envelope`
   - 🏷️ 昵称: `fa-tag`
   - 📝 真实姓名: `fa-id-card`
   - 🆔 用户ID: `fa-hashtag`
   - 📅 日期: `fa-calendar`
   - 📊 项目: `fa-folder`
   - 📚 班级: `fa-users`
   - ✍️ 作业: `fa-tasks`
   - ⭐ 成绩: `fa-star`

3. **卡片布局**:
   ```html
   <div class="card user-info-card">
     <div class="card-header">
       <!-- 用户名 + 角色徽章 + 状态标签 -->
     </div>
     <div class="card-body">
       <!-- 基础信息 -->
       <!-- 身份信息 (权限控制) -->
       <!-- 学习统计 (学生账号) -->
     </div>
     <div class="card-footer">
       <!-- 操作按钮组 -->
     </div>
   </div>
   ```

### 3. 权限控制实现

#### A. 视图层权限检查
```lua
-- 检查是否可以查看真实姓名
local can_view_real_name = function(viewer, target_user)
    if viewer.id == target_user.id then
        return true  -- 本人
    end
    if viewer:isadmin() then
        return true  -- 管理员
    end
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true  -- 创建者教师
    end
    return false
end

-- 检查是否可以查看邮箱
local can_view_email = function(viewer, target_user)
    if viewer.id == target_user.id then
        return true  -- 本人
    end
    if viewer:has_min_role('moderator') then
        return true  -- 版主及以上
    end
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true  -- 创建者教师
    end
    return false
end
```

#### B. API 层权限检查
```lua
-- controllers/user.lua
UserController.get_user_detail = function(self)
    local target_user = Users:find({username = self.params.username})
    assert_exists(target_user)
    
    -- 基础信息（所有人可见）
    local info = {
        username = target_user.username,
        nickname = target_user.nickname,
        role = target_user.role,
        created = target_user.created,
        project_count = target_user:get_project_count()
    }
    
    -- 邮箱（权限控制）
    if can_view_email(self.current_user, target_user) then
        info.email = target_user.email
    end
    
    -- 真实姓名（权限控制）
    if can_view_real_name(self.current_user, target_user) then
        info.real_name = target_user.real_name
    end
    
    -- 用户ID（版主及以上）
    if self.current_user:has_min_role('moderator') then
        info.id = target_user.id
        info.creator_id = target_user.creator_id
    end
    
    -- 学习统计（学生账号 + 有权限）
    if target_user:is_student() and can_view_student_stats(self.current_user, target_user) then
        info.classes = get_student_classes(target_user)
        info.assignment_stats = get_assignment_stats(target_user)
    end
    
    return jsonp({ json = { success = true, user = info }})
end
```

---

## 🛠️ 实施步骤

### 阶段一: 数据模型和 API (Day 1)

#### 1.1 创建辅助函数模块

**文件**: `lib/user_permissions.lua`

```lua
-- 用户信息权限检查辅助函数
local M = {}

-- 检查是否可以查看真实姓名
M.can_view_real_name = function(viewer, target_user)
    if not viewer or not target_user then return false end
    if viewer.id == target_user.id then return true end
    if viewer:isadmin() then return true end
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true
    end
    return false
end

-- 检查是否可以查看邮箱
M.can_view_email = function(viewer, target_user)
    if not viewer or not target_user then return false end
    if viewer.id == target_user.id then return true end
    if viewer:has_min_role('moderator') then return true end
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true
    end
    return false
end

-- 检查是否可以查看学生统计
M.can_view_student_stats = function(viewer, target_user)
    if not viewer or not target_user then return false end
    if not target_user:is_student() then return false end
    if viewer.id == target_user.id then return true end
    if viewer:isadmin() then return true end
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true
    end
    return false
end

-- 检查是否可以管理用户
M.can_manage_user = function(viewer, target_user)
    if not viewer or not target_user then return false end
    if viewer:has_min_role('moderator') then return true end
    if viewer.is_teacher and target_user.creator_id == viewer.id then
        return true
    end
    return false
end

return M
```

**测试清单**:
- [ ] 学生查看自己的信息 → 所有信息可见
- [ ] 学生查看其他学生的信息 → 只能看到公开信息
- [ ] 教师查看自己创建的学生 → 可以看到邮箱和真实姓名
- [ ] 教师查看其他学生 → 只能看到公开信息
- [ ] 管理员查看任何用户 → 所有信息可见

#### 1.2 扩展 User Model

**文件**: `models/users.lua`

添加新方法：

```lua
-- 获取学生所属班级列表
get_classes = function(self)
    if not self:is_student() then return {} end
    
    local ClassMemberships = package.loaded.ClassMemberships
    local Classes = package.loaded.Classes
    
    local memberships = ClassMemberships:select(
        'WHERE student_id = ? AND deleted_at IS NULL',
        self.id
    )
    
    local classes = {}
    for _, membership in ipairs(memberships) do
        local class = Classes:find(membership.class_id)
        if class and not class.deleted_at then
            table.insert(classes, {
                id = class.id,
                name = class.name,
                teacher_id = class.teacher_id,
                teacher_username = Users:find(class.teacher_id).username
            })
        end
    end
    
    return classes
end

-- 获取作业统计
get_assignment_stats = function(self)
    if not self:is_student() then return nil end
    
    local Submissions = package.loaded.Submissions
    
    local db = package.loaded.db
    local result = db.query([[
        SELECT 
            COUNT(*) as total_assignments,
            COUNT(CASE WHEN s.id IS NOT NULL THEN 1 END) as submitted_count,
            AVG(s.points) as avg_points
        FROM assignments a
        LEFT JOIN submissions s ON a.id = s.assignment_id AND s.student_id = ?
        WHERE a.deleted_at IS NULL
    ]], self.id)[1]
    
    return {
        total = tonumber(result.total_assignments) or 0,
        submitted = tonumber(result.submitted_count) or 0,
        avg_points = tonumber(result.avg_points) or 0,
        completion_rate = result.total_assignments > 0 
            and math.floor((result.submitted_count / result.total_assignments) * 100)
            or 0
    }
end
```

**测试清单**:
- [ ] 学生账号调用 `get_classes()` → 返回班级列表
- [ ] 非学生账号调用 `get_classes()` → 返回空数组
- [ ] 学生账号调用 `get_assignment_stats()` → 返回统计数据
- [ ] 数据准确性验证

#### 1.3 创建新 API 端点

**文件**: `api.lua`

```lua
-- 获取用户详细信息（包含权限控制）
app:match(api_route('users/:username/detail'), respond_to({
    GET = function(self)
        return UserController.get_user_detail(self)
    end
}))
```

**文件**: `controllers/user.lua`

```lua
local user_permissions = require('lib.user_permissions')

UserController.get_user_detail = function(self)
    assert_logged_in(self)
    
    local target_user = Users:find({username = self.params.username})
    assert_exists(target_user, 'User not found')
    
    -- 基础信息
    local info = {
        username = target_user.username,
        nickname = target_user.nickname,
        role = target_user.role,
        created = target_user.created,
        verified = target_user.verified,
        is_teacher = target_user.is_teacher,
        project_count = target_user:get_project_count()
    }
    
    -- 邮箱（权限控制）
    if user_permissions.can_view_email(self.current_user, target_user) then
        info.email = target_user.email
    end
    
    -- 真实姓名（权限控制）
    if user_permissions.can_view_real_name(self.current_user, target_user) then
        info.real_name = target_user.real_name
    end
    
    -- 用户ID和创建者（版主及以上）
    if self.current_user:has_min_role('moderator') then
        info.id = target_user.id
        info.creator_id = target_user.creator_id
        if target_user.creator_id then
            local creator = Users:find(target_user.creator_id)
            if creator then
                info.creator_username = creator.username
            end
        end
    end
    
    -- 学习统计（学生账号 + 有权限）
    if target_user:is_student() and 
       user_permissions.can_view_student_stats(self.current_user, target_user) then
        info.classes = target_user:get_classes()
        info.assignment_stats = target_user:get_assignment_stats()
    end
    
    return jsonp({ json = { success = true, user = info }})
end
```

**测试清单**:
- [ ] GET `/api/v1/users/student001/detail` (未登录) → 401
- [ ] GET `/api/v1/users/student001/detail` (学生本人) → 完整信息
- [ ] GET `/api/v1/users/student001/detail` (创建者教师) → 包含邮箱和真实姓名
- [ ] GET `/api/v1/users/student001/detail` (其他教师) → 只有公开信息
- [ ] GET `/api/v1/users/student001/detail` (管理员) → 完整信息

### 阶段二: 视图层改造 (Day 2)

#### 2.1 创建新的用户信息卡片组件

**文件**: `views/partials/user_info_card.etlua`

```html
<%
-- 用户信息卡片（增强版）
-- 参数:
--   item: 用户对象
--   viewer: 当前用户（查看者）
--   context: 显示上下文 ('admin', 'teacher', 'profile')
--   zombie: 是否为已删除用户

local user_permissions = require('lib.user_permissions')
local util = require('lib.util')

-- 权限检查
local can_view_email = user_permissions.can_view_email(viewer, item)
local can_view_real_name = user_permissions.can_view_real_name(viewer, item)
local can_view_stats = user_permissions.can_view_student_stats(viewer, item)
local can_manage = user_permissions.can_manage_user(viewer, item)

-- 角色样式
local role_colors = {
    admin = 'danger',
    moderator = 'info',
    reviewer = 'primary',
    student = 'success',
    banned = 'dark'
}
local role_icons = {
    admin = 'fa-crown',
    moderator = 'fa-shield-alt',
    reviewer = 'fa-eye',
    student = 'fa-user-graduate',
    teacher = 'fa-chalkboard-teacher',
    standard = 'fa-user'
}

local role_color = role_colors[item.role] or 'secondary'
local role_icon = role_icons[item.role] or 'fa-user'
%>

<div class="col-12 col-sm-6 col-md-4 mb-3">
  <div class="card user-info-card <%= item.role %> <%= item.verified and '' or 'unverified' %>">
    
    <!-- Header: 用户名 + 角色 + 状态 -->
    <div class="card-header bg-<%= role_color %> bg-opacity-10">
      <div class="d-flex justify-content-between align-items-center">
        <div class="user-title">
          <% if not zombie then %>
          <a class="text-decoration-none fw-bold" href="<%= item:url_for('site') %>">
          <% end %>
            <i class="fas <%= role_icon %> me-1"></i>
            <%- util.visualize_whitespace_html(item.username) %>
          <% if not zombie then %>
          </a>
          <% end %>
          
          <!-- 昵称 -->
          <% if item.nickname and item.nickname ~= '' then %>
          <div class="text-muted small">
            <i class="fas fa-tag"></i> <%= item.nickname %>
          </div>
          <% end %>
        </div>
        
        <div class="user-badges">
          <!-- 角色徽章 -->
          <% if item.role ~= 'standard' then %>
          <span class="badge text-bg-<%= role_color %> mb-1">
            <%= locale.get(item.role) %>
          </span>
          <% end %>
          
          <!-- 验证状态 -->
          <% if not item.verified then %>
          <span class="badge text-bg-warning mb-1">
            <i class="fas fa-exclamation-triangle"></i>
            <%= locale.get('unverified') %>
          </span>
          <% end %>
          
          <!-- 教师标识 -->
          <% if item.is_teacher then %>
          <span class="badge text-bg-info mb-1">
            <i class="fas fa-chalkboard-teacher"></i>
            <%= locale.get('teacher') %>
          </span>
          <% end %>
        </div>
      </div>
    </div>
    
    <!-- Body: 信息列表 -->
    <ul class="list-group list-group-flush">
      
      <!-- 邮箱（权限控制） -->
      <% if can_view_email then %>
      <li class="list-group-item">
        <i class="fas fa-envelope text-primary me-2"></i>
        <strong><%= locale.get('email') %>:</strong>
        <a href="mailto:<%= item.email %>"><%= item.email %></a>
        <% if item.unique_email and item.email ~= item.unique_email then %>
        <div class="mt-1">
          <span class="badge text-bg-secondary">unique</span>
          <code class="small"><%- util.visualize_whitespace_html(item.unique_email) %></code>
        </div>
        <% end %>
      </li>
      <% end %>
      
      <!-- 真实姓名（权限控制） -->
      <% if can_view_real_name and item.real_name and item.real_name ~= '' then %>
      <li class="list-group-item">
        <i class="fas fa-id-card text-success me-2"></i>
        <strong><%= locale.get('real_name') %>:</strong>
        <%= item.real_name %>
      </li>
      <% end %>
      
      <!-- 用户ID（版主及以上） -->
      <% if viewer:has_min_role('moderator') then %>
      <li class="list-group-item">
        <i class="fas fa-hashtag text-info me-2"></i>
        <strong><%= locale.get('user_id') %>:</strong>
        <code><%= item.id %></code>
      </li>
      <% end %>
      
      <!-- 加入日期 -->
      <li class="list-group-item">
        <i class="fas fa-calendar text-secondary me-2"></i>
        <strong><%= locale.get('join_date') %>:</strong>
        <%= string.from_sql_date(item.created) %>
      </li>
      
      <!-- 项目数量 -->
      <li class="list-group-item">
        <i class="fas fa-folder text-warning me-2"></i>
        <strong><%= locale.get('project_count') %>:</strong>
        <span class="badge text-bg-primary"><%= item:get_project_count() %></span>
      </li>
      
      <!-- 创建者信息（有权限且存在） -->
      <% if viewer:has_min_role('moderator') and item.creator_id then %>
      <li class="list-group-item">
        <i class="fas fa-user-plus text-info me-2"></i>
        <strong><%= locale.get('creator') %>:</strong>
        <a href="/user?user_id=<%= item.creator_id %>">
          ID: <%= item.creator_id %>
        </a>
      </li>
      <% end %>
      
      <!-- 学生统计（权限控制） -->
      <% if item:is_student() and can_view_stats then %>
        <% 
        local classes = item:get_classes()
        local stats = item:get_assignment_stats()
        %>
        
        <!-- 所属班级 -->
        <% if classes and #classes > 0 then %>
        <li class="list-group-item">
          <i class="fas fa-users text-primary me-2"></i>
          <strong><%= locale.get('classes') %>:</strong>
          <span class="badge text-bg-info"><%= #classes %></span>
          <div class="mt-2">
            <% for _, class in ipairs(classes) do %>
            <div class="small text-muted">
              • <%= class.name %> 
              (<a href="/user/<%= class.teacher_username %>"><%= class.teacher_username %></a>)
            </div>
            <% end %>
          </div>
        </li>
        <% end %>
        
        <!-- 作业统计 -->
        <% if stats and stats.total > 0 then %>
        <li class="list-group-item">
          <i class="fas fa-tasks text-success me-2"></i>
          <strong><%= locale.get('assignment_stats') %>:</strong>
          <div class="mt-2">
            <div class="progress mb-2" style="height: 20px;">
              <div class="progress-bar bg-success" 
                   role="progressbar" 
                   style="width: <%= stats.completion_rate %>%"
                   aria-valuenow="<%= stats.completion_rate %>" 
                   aria-valuemin="0" 
                   aria-valuemax="100">
                <%= stats.completion_rate %>%
              </div>
            </div>
            <div class="small">
              <i class="fas fa-check-circle text-success"></i>
              <%= locale.get('submitted') %>: <%= stats.submitted %>/<%= stats.total %>
              <% if stats.avg_points > 0 then %>
              <br>
              <i class="fas fa-star text-warning"></i>
              <%= locale.get('average_score') %>: <%= string.format("%.1f", stats.avg_points) %>
              <% end %>
            </div>
          </div>
        </li>
        <% end %>
      <% end %>
      
      <!-- 删除日期（僵尸用户） -->
      <% if zombie then %>
      <li class="list-group-item">
        <i class="fas fa-trash text-danger me-2"></i>
        <strong><%= locale.get('delete_date') %>:</strong>
        <%= string.from_sql_date(item.deleted) %>
      </li>
      <% end %>
      
      <!-- 角色选择器（管理员） -->
      <% if not zombie and viewer:has_min_role('moderator') then %>
      <li class="list-group-item">
        <div class="input-group input-group-sm">
          <label class="input-group-text">
            <i class="fas fa-user-tag me-1"></i>
            <%= locale.get('role') %>
          </label>
          <select class="form-select"
                  onchange="cloud.post('/users/<%= item.username %>/set_role', null, 
                    { username: '<%= item.username %>', role: this.value });">
            <% for role, _ in pairs(package.loaded.Users.roles) do %>
            <option value="<%= role %>" <%= role == item.role and 'selected' or '' %>>
              <%= locale.get(role) %>
            </option>
            <% end %>
          </select>
        </div>
      </li>
      
      <!-- 教师标识切换 -->
      <li class="list-group-item">
        <div class="form-check form-switch">
          <% local switch_id = "teacher-switch-" .. tostring(item.id) %>
          <input class="form-check-input" 
                 type="checkbox" 
                 id="<%= switch_id %>"
                 <%= item.is_teacher and 'checked' or '' %>
                 onchange="cloud.post('/users/<%= item.username %>/set_teacher', null,
                   { username: '<%= item.username %>', is_teacher: this.checked });">
          <label class="form-check-label" for="<%= switch_id %>">
            <i class="fas fa-chalkboard-teacher me-1"></i>
            <%= locale.get('teacher') %>
          </label>
        </div>
      </li>
      <% end %>
      
    </ul>
    
    <!-- Footer: 操作按钮 -->
    <% if can_manage then %>
    <div class="card-footer">
      <%= render('views.partials.user_actions', {
        item = item,
        viewer = viewer,
        zombie = zombie,
        context = context
      }) %>
    </div>
    <% end %>
    
  </div>
</div>
```

**关键改进**:
1. ✅ 使用权限检查函数控制信息可见性
2. ✅ 图标系统增强视觉识别
3. ✅ 色彩编码区分角色和状态
4. ✅ 学生统计信息展示
5. ✅ 响应式布局
6. ✅ 多语言支持

#### 2.2 创建用户操作按钮组件

**文件**: `views/partials/user_actions.etlua`

```html
<%
-- 用户操作按钮组件
-- 参数: item, viewer, zombie, context
%>

<div class="user-actions">
  
  <% if not zombie then %>
    
    <!-- 管理员操作 -->
    <% if viewer:isadmin() then %>
    <div class="btn-group btn-group-sm mb-2" role="group">
      <button class="btn btn-outline-secondary" 
              onclick="cloud.post('/users/<%= item.username %>/become');">
        <i class="fas fa-sign-in-alt"></i>
        <%= locale.get('become') %>
      </button>
      
      <% if not item.verified then %>
      <button class="btn btn-outline-success"
              onclick="cloud.post('/users/<%= item.username %>/verify');">
        <i class="fas fa-check-circle"></i>
        <%= locale.get('verify') %>
      </button>
      <% end %>
    </div>
    <% end %>
    
    <!-- 密码和邮箱管理 -->
    <% if viewer:has_min_role('moderator') or 
          (viewer.is_teacher and item.creator_id == viewer.id) then %>
    <div class="btn-group btn-group-sm mb-2" role="group">
      <button class="btn btn-outline-primary"
              onclick="promptChangeEmail('<%= item.username %>')">
        <i class="fas fa-at"></i>
        <%= locale.get('change_email') %>
      </button>
      
      <button class="btn btn-outline-warning"
              onclick="confirmResetPassword('<%= item.username %>')">
        <i class="fas fa-key"></i>
        <%= locale.get('reset_password') %>
      </button>
      
      <button class="btn btn-outline-info"
              onclick="promptChangeUsername('<%= item.username %>')">
        <i class="fas fa-user-edit"></i>
        <%= locale.get('change_username') %>
      </button>
    </div>
    <% end %>
    
    <!-- 消息发送（版主及以上） -->
    <% if viewer:has_min_role('moderator') then %>
    <div class="btn-group btn-group-sm mb-2" role="group">
      <button class="btn btn-outline-info"
              onclick="showComposeEmailDialog('<%= item.username %>')">
        <i class="fas fa-envelope"></i>
        <%= locale.get('send_msg') %>
      </button>
    </div>
    <% end %>
    
    <!-- 危险操作 -->
    <% if viewer:has_min_role('moderator') then %>
    <div class="btn-group btn-group-sm" role="group">
      <button class="btn btn-outline-danger"
              onclick="toggleBanUser('<%= item.username %>', <%= item.role == 'banned' and 'false' or 'true' %>)">
        <i class="fas fa-ban"></i>
        <%= item.role == 'banned' and locale.get('unban') or locale.get('ban') %>
      </button>
      
      <button class="btn btn-outline-danger"
              onclick="confirmDeleteUser('<%= item.username %>')">
        <i class="fas fa-trash"></i>
        <%= locale.get('delete_usr') %>
      </button>
    </div>
    <% end %>
    
  <% else %>
    <!-- 僵尸用户操作 -->
    <% if viewer:has_min_role('moderator') then %>
    <div class="btn-group btn-group-sm" role="group">
      <button class="btn btn-outline-success"
              onclick="confirmReviveUser('<%= item.username %>')">
        <i class="fas fa-undo"></i>
        <%= locale.get('revive_usr') %>
      </button>
      
      <button class="btn btn-outline-danger"
              onclick="confirmPermaDeleteUser('<%= item.username %>')">
        <i class="fas fa-times-circle"></i>
        <%= locale.get('perma_delete_usr') %>
      </button>
    </div>
    <% end %>
  <% end %>
  
</div>

<script>
// 用户操作相关 JavaScript 函数
function promptChangeEmail(username) {
    prompt(
        '<%= locale.get('new_email') %>',
        (email) => {
            if (email && email.trim()) {
                cloud.post(
                    '/users/' + username + '/change_email',
                    null,
                    { email: email.trim(), username: username }
                );
            }
        }
    );
}

function confirmResetPassword(username) {
    confirm(
        '<%= locale.get('confirm_reset_password', 'username') %>'.replace('username', username),
        () => {
            cloud.post('/users/' + username + '/password_reset');
        }
    );
}

function promptChangeUsername(username) {
    prompt(
        '<%= locale.get('new_username', 'username') %>'.replace('username', username),
        (newUsername) => {
            if (newUsername && newUsername.trim()) {
                cloud.post(
                    '/users/' + username + '/change_username',
                    null,
                    { new_username: newUsername.trim() }
                );
            }
        }
    );
}

function showComposeEmailDialog(username) {
    dialog(
        '<%= locale.get('compose_email') %>',
        '<%= package.loaded.dialog('compose_email') %>',
        () => {
            const form = document.querySelector('form.email-compose');
            const subject = form.querySelector('input').value;
            const contents = form.querySelector('textarea').value;
            cloud.post(
                '/users/' + username + '/send_email',
                null,
                { subject: subject, contents: contents }
            );
        }
    );
}

function toggleBanUser(username, shouldBan) {
    const action = shouldBan ? '<%= locale.get('ban') %>' : '<%= locale.get('unban') %>';
    confirm(
        '<%= locale.get('confirm_action') %>: ' + action + ' ' + username + '?',
        () => {
            cloud.post(
                '/users/' + username + '/set_role',
                null,
                { username: username, role: shouldBan ? 'banned' : 'standard' }
            );
        }
    );
}

function confirmDeleteUser(username) {
    confirm(
        '<%= package.loaded.dialog('delete_user', { username = 'USERNAME' }) %>'.replace('USERNAME', username),
        () => {
            cloud.delete('/users/' + username);
        }
    );
}

function confirmReviveUser(username) {
    confirm(
        '<%= locale.get('confirm_revive', 'username') %>'.replace('username', username),
        () => {
            cloud.post('/zombies/' + username + '/revive');
        }
    );
}

function confirmPermaDeleteUser(username) {
    confirm(
        '<%= locale.get('confirm_perma_delete', 'username') %>'.replace('username', username) +
        '<br><strong><%= locale.get('warning_no_return') %></strong>',
        () => {
            cloud.delete('/zombies/' + username);
        }
    );
}
</script>
```

#### 2.3 更新现有页面使用新组件

**修改**: `views/admin/user_admin.etlua`
**修改**: `views/teacher/learners.etlua`

将 `item_type = 'profile'` 改为 `item_type = 'user_info_card'`

### 阶段三: 多语言支持 (Day 2 下午)

#### 3.1 添加新的翻译键

**文件**: `locales/zh.lua` (中文)

```lua
return {
    -- ... 现有翻译 ...
    
    -- 用户信息增强
    real_name = '真实姓名',
    classes = '所属班级',
    assignment_stats = '作业统计',
    submitted = '已提交',
    average_score = '平均分数',
    completion_rate = '完成率',
    creator = '创建者',
    
    -- 操作相关
    become = '切换身份',
    send_msg = '发送消息',
    compose_email = '编写邮件',
    confirm_action = '确认操作',
    confirm_revive = '确认恢复用户 %s 吗？',
    confirm_perma_delete = '确认永久删除用户 %s 吗？',
    warning_no_return = '此操作不可撤销！',
    
    -- ... 其他翻译 ...
}
```

**文件**: `locales/en.lua` (英文)

```lua
return {
    -- ... existing translations ...
    
    -- User info enhancements
    real_name = 'Real Name',
    classes = 'Classes',
    assignment_stats = 'Assignment Statistics',
    submitted = 'Submitted',
    average_score = 'Average Score',
    completion_rate = 'Completion Rate',
    creator = 'Creator',
    
    -- Actions
    become = 'Become User',
    send_msg = 'Send Message',
    compose_email = 'Compose Email',
    confirm_action = 'Confirm Action',
    confirm_revive = 'Confirm revive user %s?',
    confirm_perma_delete = 'Confirm permanently delete user %s?',
    warning_no_return = 'This action cannot be undone!',
    
    -- ... other translations ...
}
```

### 阶段四: 测试和优化 (Day 3)

#### 4.1 功能测试清单

**权限测试**:
- [ ] 学生查看自己的信息
  - ✅ 可以看到：用户名、邮箱、昵称、真实姓名、项目数量、所属班级、作业统计
  - ❌ 看不到：用户ID、Creator ID
  
- [ ] 学生查看其他学生的信息
  - ✅ 可以看到：用户名、昵称、项目数量
  - ❌ 看不到：邮箱、真实姓名、用户ID、班级信息
  
- [ ] 教师查看自己创建的学生
  - ✅ 可以看到：所有基础信息 + 邮箱 + 真实姓名 + 班级 + 作业统计
  - ✅ 可以操作：重置密码、修改邮箱、修改用户名
  
- [ ] 教师查看其他学生
  - ✅ 可以看到：用户名、昵称、项目数量
  - ❌ 看不到：邮箱、真实姓名、详细统计
  
- [ ] 版主查看用户
  - ✅ 可以看到：所有信息（除真实姓名需要权限）
  - ✅ 可以操作：大部分管理操作
  
- [ ] 管理员查看用户
  - ✅ 可以看到：所有信息
  - ✅ 可以操作：所有管理操作

**界面测试**:
- [ ] 响应式布局测试（手机、平板、桌面）
- [ ] 图标显示正确
- [ ] 色彩编码正确
- [ ] 徽章显示正常
- [ ] 进度条正确显示

**性能测试**:
- [ ] 大量用户列表加载速度（150+用户）
- [ ] 数据库查询优化
- [ ] 缓存机制检查

#### 4.2 边界情况处理

- [ ] 用户没有昵称
- [ ] 用户没有真实姓名
- [ ] 学生不属于任何班级
- [ ] 学生没有作业记录
- [ ] 已删除用户的显示
- [ ] 未验证用户的处理

---

## 📊 数据库变更

无需新建表，使用现有字段：
- `users.nickname` ✅ (已存在)
- `users.real_name` ✅ (已存在)
- `users.creator_id` ✅ (已存在)
- `class_memberships` ✅ (已存在)
- `submissions` ✅ (已存在)

---

## 🔒 安全考虑

1. **数据隐私**:
   - 严格控制真实姓名的访问权限
   - 邮箱只对授权用户可见
   - 用户ID只对管理员可见

2. **CSRF 保护**:
   - 所有POST请求使用 `cloud.post()` (自动包含CSRF token)

3. **XSS 防护**:
   - 使用 `util.visualize_whitespace_html()` 转义用户输入
   - 使用 `package.loaded.html.escape()` 转义HTML

4. **权限验证**:
   - API层和视图层双重权限检查
   - 使用专门的权限检查函数

---

## 📝 文档更新

需要更新的文档：
- [ ] PROJECT_RULES.md - 添加用户信息权限规则
- [ ] API文档 - 新增API端点说明
- [ ] 开发者指南 - 用户信息卡片组件使用说明

---

## 🚀 部署计划

### 预发布检查清单

- [ ] 所有测试通过
- [ ] 代码审查完成
- [ ] 文档更新完成
- [ ] 性能测试通过
- [ ] 安全审计完成
- [ ] 多语言翻译完成
- [ ] 备份数据库

### 发布步骤

1. 创建功能分支 `feature/user-info-enhancement`
2. 分阶段提交代码
3. 运行自动化测试
4. 创建Pull Request
5. 代码审查
6. 合并到主分支
7. 部署到测试环境
8. 用户验收测试
9. 部署到生产环境
10. 监控和日志检查

---

## 📈 后续优化方向

1. **缓存优化**: 用户统计数据缓存
2. **批量操作**: 批量编辑用户信息
3. **导出功能**: 导出用户列表为CSV
4. **高级筛选**: 按班级、作业完成率筛选
5. **数据可视化**: 用户活跃度图表

---

**优先级**: 🔴 高优先级  
**状态**: 📝 计划中  
**负责人**: 待分配  
**预计完成**: 2025-11-09

