# 批量导入用户功能使用说明

## 功能概述

批量导入功能允许教师和管理员通过CSV文件快速创建和管理用户账号。

## 教师批量导入学生

### 访问路径
- 教师主页 → "批量导入学生" 按钮
- 直接访问：`/teacher/bulk-import-students`

### 使用步骤

1. **选择目标班级**
   - 从下拉列表中选择要导入学生的班级

2. **准备CSV数据**
   - 必填字段：`username`（用户名）、`password`（密码）
   - 可选字段：`email`（邮箱）、`nickname`（昵称）、`real_name`（真实姓名）
   - 默认值：
     - 昵称为空时，自动设为用户名
     - 真实姓名为空时，自动设为用户名
     - 邮箱为空时，自动生成 `用户名@student.local`

3. **CSV格式示例**

```csv
username,password,email,nickname,real_name
student001,pass123,s001@school.com,小明,张明
student002,pass456,s002@school.com,小红,李红
student003,pass789,,,王刚
```

第三行示例：邮箱、昵称为空，将自动设置昵称和真实姓名为"student003"

4. **上传方式**
   - 方式一：上传CSV文件
   - 方式二：直接粘贴CSV数据

5. **预览和确认**
   - 系统会解析并显示所有数据
   - 检查数据是否正确
   - 点击"确认导入"执行导入

6. **查看结果**
   - 显示成功/失败统计
   - 列出失败记录的详细原因

### 注意事项

- 如果用户已存在，将**更新**其昵称、真实姓名和邮箱信息
- 支持中英文标题行
- 学生自动添加到选中的班级

---

## 管理员批量导入用户

### 访问路径
- 管理员主页 → "批量导入用户" 按钮
- 直接访问：`/admin/bulk-import-users`

### 使用步骤

1. **准备CSV数据**
   - 必填字段：`username`、`password`
   - 可选字段：`email`、`nickname`、`real_name`、`role`（角色）
   - 默认角色：`student`（学生）

2. **支持的角色**
   - `admin` / `管理员`
   - `teacher` / `教师`
   - `student` / `学生`（默认）
   - `moderator` / `版主`
   - `standard` / `标准用户`

3. **CSV格式示例**

```csv
username,password,email,nickname,real_name,role
teacher001,pass123,t001@school.com,张老师,张明,teacher
student001,pass456,s001@school.com,小明,李明,student
admin001,admin789,admin@school.com,系统管理员,王刚,admin
```

4. **导入流程**
   - 上传CSV文件或粘贴数据
   - 预览数据（包含角色分布统计）
   - 确认导入（不可撤销操作）
   - 查看导入结果

### 注意事项

- 管理员功能，权限较高，请谨慎操作
- 支持创建所有角色的用户
- 如果用户已存在，将更新其信息和角色
- 导入操作记录在 `bulk_import_logs` 表中

---

## 权限控制

### 真实姓名权限
- **学生**：只能查看自己的真实姓名，**不能修改**
- **教师/管理员**：可以修改自己的真实姓名
- **教师导入**：可以设置学生的真实姓名

### API端点权限
- `POST /api/v1/teachers/bulk-import-students` - 需要教师或管理员权限
- `POST /api/v1/admin/bulk-import-users` - 需要管理员权限
- `POST /api/v1/users/current/realname` - 需要教师或管理员权限

---

## 技术细节

### 数据库
- 导入历史记录表：`bulk_import_logs`
  - 记录导入者、类型、成功/失败数量
  - 存储错误详情（JSON格式）

### CSV解析
- 支持引号包裹的字段
- 处理字段中的逗号和换行
- 自动检测标题行
- 支持中英文列名

### 导入日志
每次导入会记录：
- 导入者ID
- 导入类型（`teacher_students` 或 `admin_users`）
- 总数、成功数、失败数
- 错误详情（包含行号、用户名、错误原因）
- 导入时间

---

## 常见问题

### Q1: CSV文件编码问题？
A: 建议使用UTF-8编码保存CSV文件

### Q2: 批量导入会覆盖现有用户吗？
A: 不会删除用户，但会更新现有用户的昵称、真实姓名、邮箱等信息

### Q3: 导入失败怎么办？
A: 系统会显示详细的错误信息，根据提示修改CSV后重新导入

### Q4: 一次最多导入多少用户？
A: 理论上无限制，但建议单次不超过500条以保证性能

### Q5: 如何查看导入历史？
A: 导入历史存储在数据库 `bulk_import_logs` 表中，管理员可查询

---

## 示例CSV模板下载

### 教师导入学生模板
```csv
username,password,email,nickname,real_name
```

### 管理员导入用户模板
```csv
username,password,email,nickname,real_name,role
```

**提示**：复制上述模板到Excel或文本编辑器，填写数据后保存为CSV格式。
