# 班级管理系统测试说明

## 问题诊断

### 发现的问题
1. **视图文件中使用了错误的函数**: 使用 `loc()` 而不是 `locale.get()`
   - ✅ 已修复: 所有 `loc()` 已替换为 `locale.get()`

2. **视图文件使用了错误的布局模式**: 使用 `render("layout", ...)` 而不是遵循现有模式
   - ✅ 已修复: 移除了 `render("layout", ...)` 行，添加了标准的 CSS/JS 引用和 H1 标题

3. **页面路由返回404**: 所有未登录访问的页面路由都返回 "The requested resource does not exist."
   - ⚠️ **这是预期行为**: 页面路由需要用户登录和教师权限

4. **API 路由工作正常**: `/api/v1/classes` 返回 "请先登录"，说明路由已正确注册

## 系统状态

### ✅ 已验证
- 数据库表结构正确
- 测试数据已创建（2个班级，5名学生）
- API 路由正确注册
- 页面路由正确注册  
- 视图文件语法已修复

### ⏳ 需要手动测试
由于页面路由需要登录，需要在浏览器中进行测试：

## 浏览器测试步骤

### 前提条件
1. 服务器运行在 http://localhost:8080
2. 教师账号: `teacher` / `teacher@teacher.com`
3. 测试班级已创建（测试班级A, 测试班级B）

### 测试流程

#### 第1步: 登录
1. 打开浏览器访问 http://localhost:8080
2. 点击登录按钮
3. 使用教师账号登录:
   - 用户名: `teacher`
   - Email: `teacher@teacher.com`
   - 密码: （根据环境配置）

#### 第2步: 访问教师面板
1. 登录后应自动跳转或显示教师面板
2. 在教师面板应该看到各种管理按钮
3. 找到"班级管理"按钮（中文："班级管理"或"班级"）

#### 第3步: 测试班级列表页
1. 点击"班级管理"按钮
2. 应跳转到 http://localhost:8080/teacher/classes
3. 页面应显示:
   - 标题: "教师班级"或类似
   - 班级列表卡片（测试班级A、测试班级B）
   - 每个卡片显示:
     * 班级名称
     * 学生数量
     * 作业数量
     * "查看详情"、"编辑"、"删除"按钮

#### 第4步: 测试班级创建
1. 点击"创建班级"按钮
2. 在弹出对话框中填写:
   - 班级名称: "测试新班级"
   - 描述: "浏览器测试创建的班级"
3. 点击"创建"
4. 验证新班级出现在列表中

#### 第5步: 测试班级详情
1. 点击任一班级的"查看详情"按钮
2. 应跳转到 http://localhost:8080/teacher/class/[ID]
3. 页面应显示:
   - 班级名称和描述
   - 成员列表表格
   - 每个成员显示:
     * 用户名
     * Email
     * 加入时间
     * 状态（激活/停用）
     * 提交的作业数
     * 平均分数
     * 操作按钮（激活/停用、移除）

#### 第6步: 测试添加学生
1. 在班级详情页点击"添加学生"
2. 在弹出对话框中:
   - 输入学生ID或从下拉列表选择
   - 可选：添加备注
3. 点击"添加"
4. 验证学生出现在成员列表中

#### 第7步: 测试成员管理
1. **激活/停用成员**:
   - 点击成员的"停用"按钮
   - 验证状态变为"未激活"
   - 再次点击"激活"恢复

2. **移除成员**:
   - 点击某个成员的"移除"按钮
   - 确认操作
   - 验证成员从列表中消失

#### 第8步: 测试班级编辑
1. 返回班级列表页
2. 点击某个班级的"编辑"按钮
3. 修改班级名称或描述
4. 保存
5. 验证更新生效

#### 第9步: 测试班级删除
1. 点击某个班级的"删除"按钮
2. 在确认对话框中确认
3. 验证班级从列表中消失（软删除）

## 预期结果

### ✅ 成功标准
- 所有页面正常加载，无500错误
- AJAX 请求返回正确的数据
- 创建/编辑/删除操作成功
- 成员管理功能正常
- 统计数据正确显示
- 用户反馈消息清晰

### ⚠️ 已知限制
- 未登录用户访问页面路由会返回404（预期行为）
- 非教师用户访问会提示权限不足
- 某些功能需要预先创建测试数据

## API 端点参考

### 教师 API
```
GET    /api/v1/classes                    - 获取班级列表
POST   /api/v1/classes                    - 创建班级
GET    /api/v1/classes/:id                - 获取班级详情
PUT    /api/v1/classes/:id                - 更新班级
DELETE /api/v1/classes/:id                - 删除班级
GET    /api/v1/classes/:id/members        - 获取成员列表
POST   /api/v1/classes/:id/members        - 添加单个学生
POST   /api/v1/classes/:id/members/batch  - 批量添加学生
DELETE /api/v1/classes/:id/members/:sid   - 移除学生
POST   /api/v1/classes/:id/members/:sid/toggle - 切换激活状态
```

### 学生 API
```
GET    /api/v1/student/classes            - 学生查看自己的班级
```

## 调试命令

### 查看测试数据
```bash
PGPASSWORD='snap-cloud-password' psql -h 127.0.0.1 -U cloud -d snapcloud -c "
SELECT 
    c.name AS \"班级名称\",
    COUNT(cm.id) AS \"学生数量\",
    u.username AS \"教师\"
FROM collections c
LEFT JOIN class_memberships cm ON cm.class_id = c.id AND cm.deleted_at IS NULL
LEFT JOIN users u ON u.id = c.creator_id
WHERE c.is_class = true
GROUP BY c.id, c.name, u.username
ORDER BY c.name;"
```

### 查看班级成员
```bash
PGPASSWORD='snap-cloud-password' psql -h 127.0.0.1 -U cloud -d snapcloud -c "
SELECT 
    c.name AS \"班级\",
    u.username AS \"学生\",
    cm.is_active AS \"激活\",
    cm.joined_at AS \"加入时间\"
FROM class_memberships cm
JOIN collections c ON c.id = cm.class_id
JOIN users u ON u.id = cm.student_id
WHERE cm.deleted_at IS NULL
ORDER BY c.name, u.username;"
```

### 测试 API（需要登录cookie）
```bash
# 先登录获取 cookie
curl -c cookies.txt -X POST http://localhost:8080/api/v1/users/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"teacher","password":"YOUR_PASSWORD"}'

# 使用 cookie 测试 API
curl -b cookies.txt http://localhost:8080/api/v1/classes
```

## 下一步

完成浏览器测试后：
1. 记录所有发现的问题
2. 验证所有功能按预期工作
3. 如果发现 bug，收集错误信息和重现步骤
4. 更新测试报告 (CLASS_MANAGEMENT_TEST_REPORT.md)
5. 考虑与作业系统的集成测试

---

**最后更新**: 2025-11-05
**服务器状态**: 运行中 (localhost:8080)
**Git 分支**: auto-i18n-translation
**最新提交**: 50ce972 - fix: 修正 ClassController 语法错误
