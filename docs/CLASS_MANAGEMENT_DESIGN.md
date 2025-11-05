# 班级管理系统设计文档

## 一、设计目标

解决教师创建学生账号后如何按班级进行组织和管理的问题。

### 核心需求
1. **班级划分**：一个教师可以创建多个班级（如数学班、科学班）
2. **学生分组**：学生可以加入多个班级
3. **作业分配**：作业可以按班级分配
4. **数据统计**：按班级查看学生作业完成情况

## 二、数据库设计

### 2.1 复用 Collections 表作为"班级"

**设计决策**：不创建单独的 `classes` 表，而是通过 `collections` 表的新字段 `is_class` 来标识班级类型的 collection。

**优势**：
- 复用现有的权限、分享、发布机制
- Collection 已有 `creator_id`（教师）字段
- Collection 已有 `name`、`description` 等基础字段
- 作业系统已使用 `collection_id` 关联班级

**扩展字段**：
```sql
ALTER TABLE collections 
ADD COLUMN is_class BOOLEAN DEFAULT false NOT NULL;
```

### 2.2 创建 class_memberships 表

管理学生与班级的多对多关系：

```sql
CREATE TABLE class_memberships (
    id SERIAL PRIMARY KEY,
    class_id INTEGER NOT NULL,          -- 班级 ID (引用 collections)
    student_id INTEGER NOT NULL,        -- 学生 ID (引用 users)
    joined_at TIMESTAMP WITH TIME ZONE, -- 加入时间
    student_note TEXT,                  -- 学生备注（学号、座位号等）
    is_active BOOLEAN DEFAULT true,     -- 是否激活（支持临时停用）
    deleted_at TIMESTAMP WITH TIME ZONE,-- 软删除
    UNIQUE(class_id, student_id)        -- 唯一约束
);
```

**关键索引**：
- `class_memberships_class_id_idx` - 按班级查询学生
- `class_memberships_student_id_idx` - 按学生查询班级
- `class_memberships_active_idx` - 只查询激活成员

### 2.3 数据库视图

#### class_stats - 班级统计
```sql
CREATE VIEW class_stats AS
SELECT 
    c.id AS class_id,
    c.name AS class_name,
    c.creator_id AS teacher_id,
    COUNT(DISTINCT cm.student_id) FILTER (WHERE cm.is_active) AS active_student_count,
    COUNT(DISTINCT a.id) FILTER (WHERE a.published = true) AS published_assignment_count
FROM collections c
LEFT JOIN class_memberships cm ON c.id = cm.class_id
LEFT JOIN assignments a ON c.id = a.collection_id
WHERE c.is_class = true
GROUP BY c.id;
```

#### student_classes - 学生的班级列表
```sql
CREATE VIEW student_classes AS
SELECT 
    cm.student_id,
    cm.class_id,
    c.name AS class_name,
    c.creator_id AS teacher_id,
    u.username AS teacher_username
FROM class_memberships cm
JOIN collections c ON cm.class_id = c.id
JOIN users u ON c.creator_id = u.id
WHERE cm.deleted_at IS NULL AND c.is_class = true;
```

#### class_members_detail - 班级成员详情（含作业统计）
```sql
CREATE VIEW class_members_detail AS
SELECT 
    cm.id AS membership_id,
    cm.class_id,
    cm.student_id,
    u.username AS student_username,
    COUNT(DISTINCT s.assignment_id) AS submitted_assignment_count,
    AVG(s.points) AS average_points
FROM class_memberships cm
JOIN users u ON cm.student_id = u.id
LEFT JOIN submissions s ON cm.student_id = s.student_id
GROUP BY cm.id, cm.class_id, cm.student_id, u.username;
```

## 三、数据模型层

### 3.1 ClassMemberships 模型

位置：`models/class_memberships.lua`

**核心方法**：

```lua
-- 查询方法
find_by_class(class_id, options)        -- 查找班级的所有成员
find_by_student(student_id)             -- 查找学生加入的所有班级
is_member(class_id, student_id)         -- 检查学生是否在班级中
get_class_members_detail(class_id)      -- 获取班级成员详情（含统计）
get_student_classes(student_id)         -- 获取学生的班级列表

-- 写入方法
add_student(class_id, student_id, options)     -- 添加学生到班级
add_students(class_id, student_ids, options)   -- 批量添加学生
remove_student(class_id, student_id)           -- 移除学生（软删除）
toggle_active(class_id, student_id)            -- 激活/停用学生
update_note(class_id, student_id, note)        -- 更新学生备注
```

**特性**：
- **软删除**：删除学生时设置 `deleted_at`，可恢复
- **批量操作**：支持批量添加学生，返回成功/失败列表
- **状态管理**：支持激活/停用学生，不影响历史数据

### 3.2 扩展 Collections 模型

添加班级相关方法：

```lua
-- 在 Collections 模型中添加
is_class_type = function (self)
    return self.is_class == true
end

get_class_members = function (self)
    if not self:is_class_type() then
        return nil
    end
    return package.loaded.ClassMemberships:find_by_class(self.id)
end

get_class_stats = function (self)
    if not self:is_class_type() then
        return nil
    end
    local query = "SELECT * FROM class_stats WHERE class_id = ?"
    return db.query(query, self.id)[1]
end
```

## 四、系统架构图

```
教师 (User with is_teacher=true)
  |
  ├── 创建班级 (Collection with is_class=true)
  |     |
  |     ├── 数学1班 (id: 101)
  |     |    ├── 学生A (class_memberships: class_id=101, student_id=1)
  |     |    ├── 学生B (class_memberships: class_id=101, student_id=2)
  |     |    └── 学生C (class_memberships: class_id=101, student_id=3)
  |     |
  |     └── 科学2班 (id: 102)
  |          ├── 学生A (class_memberships: class_id=102, student_id=1)  # 学生可在多班
  |          └── 学生D (class_memberships: class_id=102, student_id=4)
  |
  └── 创建作业 (Assignments)
        ├── 作业1 (collection_id=101) → 分配给数学1班
        └── 作业2 (collection_id=102) → 分配给科学2班
```

## 五、数据流程

### 5.1 创建班级并添加学生

```lua
-- 1. 教师创建班级（实际是创建 Collection）
local Collections = package.loaded.Collections
local class = Collections:create({
    name = "数学1班",
    creator_id = teacher.id,
    is_class = true,
    description = "2024秋季数学班"
})

-- 2. 添加学生到班级
local ClassMemberships = package.loaded.ClassMemberships
ClassMemberships:add_student(class.id, student1.id, {
    student_note = "学号: 001"
})

-- 3. 批量添加学生
local student_ids = {2, 3, 4, 5}
local result = ClassMemberships:add_students(class.id, student_ids)
-- result.success: [2, 3, 4, 5]
-- result.already_exists: []
-- result.failed: []
```

### 5.2 创建作业并分配给班级

```lua
-- 1. 教师创建作业
local Assignments = package.loaded.Assignments
local assignment = Assignments:create({
    title = "第一章练习题",
    collection_id = class.id,  -- 指定班级
    teacher_id = teacher.id,
    max_points = 100,
    due_date = "2024-11-10 23:59:59"
})

-- 2. 发布作业
assignment:publish()

-- 3. 班级内所有学生都能看到这个作业
local students = ClassMemberships:find_by_class(class.id, {active_only = true})
-- students 可以通过 API 查询到这个作业
```

### 5.3 学生查看自己的班级和作业

```lua
-- 1. 学生查看自己加入的所有班级
local my_classes = ClassMemberships:get_student_classes(student.id)
-- [
--   {class_id: 101, class_name: "数学1班", teacher_username: "teacher01"},
--   {class_id: 102, class_name: "科学2班", teacher_username: "teacher01"}
-- ]

-- 2. 查看某个班级的作业
local Assignments = package.loaded.Assignments
local assignments = Assignments:find_by_collection(101, {published = true})
```

## 六、与现有系统集成

### 6.1 与作业系统的关系

- **assignments 表**已有 `collection_id` 字段，指向班级
- 当 `collection.is_class = true` 时，该作业就是班级作业
- 学生通过 `class_memberships` 查询自己所在的班级，然后查询该班级的作业

### 6.2 与批量用户创建的关系

- 教师批量创建学生时，所有学生的 `creator_id` 指向教师
- 创建后，教师可以将学生分配到不同班级
- 一个学生可以同时在多个班级中

### 6.3 权限控制

- **教师权限**：
  - 创建/修改/删除自己创建的班级
  - 向自己的班级添加/移除学生
  - 查看班级内学生的作业统计
  
- **学生权限**：
  - 查看自己加入的所有班级
  - 查看班级内的作业
  - 不能修改班级成员

## 七、优势与特点

### 7.1 灵活性

- **一对多**：一个教师可以创建多个班级
- **多对多**：一个学生可以加入多个班级
- **软删除**：移除学生不会丢失历史数据
- **状态管理**：支持临时停用学生（如休学），不影响历史记录

### 7.2 可扩展性

- 复用 Collections 机制，未来可支持班级分享、发布
- 可在 `class_memberships` 添加更多字段（如角色、权重）
- 可扩展支持分组（一个班级内再分小组）

### 7.3 数据一致性

- 外键约束确保引用完整性
- 唯一约束防止重复添加学生
- 软删除保留完整历史记录

### 7.4 性能优化

- 索引优化查询性能
- 视图预聚合统计数据
- 支持分页查询大量学生

## 八、未来扩展方向

1. **班级角色**：支持课代表、组长等角色
2. **班级分组**：一个班级内再分小组
3. **班级公告**：教师向班级发布通知
4. **班级资源库**：共享项目、素材
5. **班级统计面板**：可视化展示班级数据
6. **学期管理**：支持按学期归档班级

## 九、数据迁移

使用 `migrations.lua` 中的 `2025-11-05:3` 迁移脚本：

```bash
cd /home/snapcloud/snapCloud
bin/lapis-migrate 2025-11-05:3
```

迁移内容：
1. 扩展 `collections` 表，添加 `is_class` 字段
2. 创建 `class_memberships` 表
3. 创建 3 个统计视图
4. 创建所有必要的索引

## 十、总结

该设计通过以下方式实现了健壮的班级管理系统：

1. **复用现有架构**：利用 Collections 表，减少冗余
2. **明确关系**：class_memberships 表清晰表达学生-班级关系
3. **灵活扩展**：支持多对多关系和未来功能扩展
4. **数据完整**：软删除、状态管理保留完整历史
5. **性能优化**：索引和视图优化查询性能

这个设计可以很好地支持教师按班级组织学生，分配作业，查看统计数据等核心功能。
