# SnapCloud 路由快速参考

## 🚨 常见问题速查

### 问题1: "don't know how to respond to GET"

```
症状: 访问页面时返回 500 错误
原因: 页面路由被 API 路由拦截
解决: 检查路由冲突并重命名
```

**快速检查**:
```bash
./bin/check-route-conflicts.sh
```

### 问题2: Cookie/会话丢失

```
症状: 点击链接后显示"未登录"
原因: 通常也是路由冲突导致
解决: 同问题1
```

---

## 📋 路由命名规范

### ✅ 推荐模式

| 类型 | API 路由 | 页面路由 | 说明 |
|------|----------|----------|------|
| 批量导入 | `/api/v1/admin/bulk-import-users` | `/admin/import-users` | 删除 "bulk-" 前缀 |
| 学生作业 | `/api/v1/student/assignments` | `/student/my-assignments` | 添加 "my-" 前缀 |
| 教师班级 | `/api/v1/teachers/classes` | `/teacher/classes` | 单复数区分 |

### ❌ 避免的模式

```lua
# 错误：路径完全相同
API:  /api/v1/admin/bulk-import-users  →  /(api/v1/)/admin/bulk-import-users
页面: /admin/bulk-import-users          →  /admin/bulk-import-users
# 结果：冲突！API 路由的可选括号会匹配两个路径
```

---

## 🔧 添加新功能检查清单

- [ ] 规划路由路径（API + 页面）
- [ ] 运行冲突检查：`./bin/check-route-conflicts.sh`
- [ ] 确保路径不同（参考命名规范）
- [ ] 更新所有链接（菜单、按钮等）
- [ ] 测试未登录和已登录状态
- [ ] 提交前再次运行冲突检查

---

## 📝 快速命令

```bash
# 检查路由冲突
./bin/check-route-conflicts.sh

# 搜索某个路径在哪里被使用
grep -r "bulk-import-users" api.lua site.lua views/

# 查找所有 API 路由
grep "api_route" api.lua

# 查找所有页面路由
grep "app:get" site.lua

# 重启开发服务器
pkill -f "nginx.*snapcloud" && lapis server development
```

---

## 🎯 路由设计原则

1. **分离关注点**: API 路由负责数据，页面路由负责展示
2. **避免歧义**: 路径应该清晰表明是 API 还是页面
3. **一致性**: 同类功能使用相似的命名模式
4. **可预测**: 开发者应能从路径猜测功能

---

## 📚 相关文档

- [PROJECT_RULES.md](../PROJECT_RULES.md) - 完整项目规则
- [ROUTE_CONFLICT_CHECKER.md](ROUTE_CONFLICT_CHECKER.md) - 检查工具详细说明

---

**提示**: 将此文件保存到书签或打印出来，开发时随时参考！
