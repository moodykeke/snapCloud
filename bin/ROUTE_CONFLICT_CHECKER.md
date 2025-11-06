# 路由冲突检查工具使用说明

## 简介

`bin/check-route-conflicts.sh` 是一个自动检测 SnapCloud 项目中 API 路由和页面路由冲突的工具。

## 为什么需要这个工具？

在 SnapCloud 项目中，API 路由使用 `api_route()` 函数生成，该函数会创建包含**可选括号**的路由模式：

```lua
api_route('admin/bulk-import-users')
→ 生成模式: /(api/v1/)/admin/bulk-import-users
```

由于 `(api/v1/)` 部分是可选的，这个模式会匹配：
- ✅ `/api/v1/admin/bulk-import-users` (预期的 API 端点)
- ⚠️ `/admin/bulk-import-users` (意外匹配！)

如果同时存在页面路由 `app:get('/admin/bulk-import-users', ...)`，就会发生冲突。

## 使用方法

### 基本用法

```bash
cd /home/snapcloud/snapCloud
./bin/check-route-conflicts.sh
```

### 在开发流程中使用

**1. 添加新路由前检查**

```bash
# 在添加新的批量操作功能前
./bin/check-route-conflicts.sh

# 如果显示 ✓ 未发现路由冲突，则安全继续
```

**2. 代码审查时使用**

```bash
# 在 Pull Request 前运行
git add .
./bin/check-route-conflicts.sh

# 确保没有引入新的冲突
```

**3. 集成到 Git 钩子**

创建 `.git/hooks/pre-commit`：

```bash
#!/bin/bash
echo "检查路由冲突..."
./bin/check-route-conflicts.sh
exit $?
```

```bash
chmod +x .git/hooks/pre-commit
```

## 输出示例

### 无冲突

```
=========================================
SnapCloud 路由冲突检查工具
=========================================

[1] 扫描 API 路由 (api.lua)...
  找到 78 个 API 路由

[2] 扫描页面路由 (site.lua)...
  找到 46 个页面路由

[3] 检查潜在冲突...


=========================================
✓ 未发现路由冲突
=========================================
```

### 发现冲突

```
=========================================
SnapCloud 路由冲突检查工具
=========================================

[1] 扫描 API 路由 (api.lua)...
  找到 78 个 API 路由

[2] 扫描页面路由 (site.lua)...
  找到 46 个页面路由

[3] 检查潜在冲突...

⚠️  冲突发现！
   API路由:  /api/v1/admin/bulk-import-users
   页面路由: /admin/bulk-import-users
   说明: API路由的可选括号 /(api/v1/)/ 会同时匹配这两个路径


=========================================
✗ 发现 1 个潜在冲突

建议:
  1. 重命名页面路由，使用不同的路径
  2. 或者修改 API 路由，避免可选括号模式
  3. 参考 PROJECT_RULES.md 中的路由命名约定
=========================================
```

## 解决冲突的方法

### 方法 1: 重命名页面路由（推荐）

```lua
-- 原始（冲突）
app:get('/admin/bulk-import-users', ...)

-- 修改为
app:get('/admin/import-users', ...)  -- 使用不同的词汇
app:get('/admin/user-import', ...)   -- 改变词序
app:get('/admin/bulk-import-users-page', ...)  -- 添加后缀
```

### 方法 2: 修改 API 路由（不推荐）

修改 `api_route()` 函数，移除可选括号（会影响现有 API）。

### 方法 3: 使用路由命名空间

```lua
-- 将页面路由放在不同的命名空间
app:get('/pages/admin/bulk-import-users', ...)
```

## 常见问题

### Q: 工具会检查所有类型的冲突吗？

A: 目前只检查 API 路由（通过 `api_route()` 定义）和页面路由（通过 `app:get()` 定义）之间的冲突。不检查：
- POST/PUT/DELETE 路由冲突
- 动态参数路由（如 `:id`）
- 正则表达式路由

### Q: 为什么有些 API 路由和页面路由路径相同但没有报冲突？

A: 工具只检测完全相同的路径。如果 API 路由是 `teachers/xxx`（复数）而页面路由是 `teacher/xxx`（单数），则不会报冲突。

### Q: 发现冲突后必须立即修复吗？

A: 建议立即修复。虽然某些情况下冲突可能不会立即导致问题（如果 API 路由定义了 GET 方法），但会造成：
- 路由优先级混乱
- Cookie/会话传递问题
- 难以预测的行为

## 相关文档

- [PROJECT_RULES.md](../PROJECT_RULES.md) - 项目开发规则
  - 路由规则
  - 路由冲突避免
  - 会话丢失问题诊断

## 维护

如果需要修改检查逻辑：

```bash
# 编辑脚本
vim bin/check-route-conflicts.sh

# 测试
./bin/check-route-conflicts.sh
```

## 贡献

欢迎改进此工具！可以添加：
- 检查 POST/PUT/DELETE 路由冲突
- 检测动态参数冲突
- 生成冲突修复建议
- 输出 JSON 格式报告

---

**最后更新**: 2025-11-06  
**维护者**: SnapCloud 开发团队
