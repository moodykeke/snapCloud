#!/usr/bin/env lua
-- 权限改进测试脚本
-- Test script for permission improvements
--
-- 用法：lua test_permission_improvements.lua
-- Usage: lua test_permission_improvements.lua

print("=================================================")
print("权限改进测试计划")
print("Permission Improvement Test Plan")
print("=================================================\n")

print("【测试场景 1】创建者关系权限")
print("Scenario 1: Creator Relationship Permissions")
print("-------------------------------------------------")
print("设置：")
print("  - 教师A (teacher_a, is_teacher=true)")
print("  - 学生S1 (student_1, creator_id=teacher_a.id)")
print("")
print("预期结果：")
print("  ✓ teacher_a.can_view_real_name(student_1) = true")
print("  ✓ teacher_a.can_view_email(student_1) = true")
print("  ✓ teacher_a.can_view_student_stats(student_1) = true")
print("  ✓ teacher_a.can_manage_user(student_1) = true")
print("  ✓ teacher_a.can_edit_user_info(student_1) = true")
print("")

print("【测试场景 2】班级关系权限")
print("Scenario 2: Class Membership Permissions")
print("-------------------------------------------------")
print("设置：")
print("  - 教师B (teacher_b, is_teacher=true)")
print("  - 学生S1 (student_1, creator_id=teacher_a.id)")
print("  - 班级C1 (class_1, creator_id=teacher_b.id, is_class=true)")
print("  - S1加入C1 (class_memberships: student_id=S1, class_id=C1)")
print("")
print("预期结果：")
print("  ✓ teacher_b.can_view_real_name(student_1) = true  (班级教师)")
print("  ✓ teacher_b.can_view_email(student_1) = true      (班级教师)")
print("  ✓ teacher_b.can_view_student_stats(student_1) = true")
print("  ✓ teacher_b.can_manage_user(student_1) = true")
print("  ✓ teacher_b.can_edit_user_info(student_1) = true")
print("")

print("【测试场景 3】无关教师权限")
print("Scenario 3: Unrelated Teacher Permissions")
print("-------------------------------------------------")
print("设置：")
print("  - 教师C (teacher_c, is_teacher=true)")
print("  - 学生S2 (student_2, creator_id=teacher_a.id)")
print("  - S2未加入teacher_c的任何班级")
print("")
print("预期结果：")
print("  ✗ teacher_c.can_view_real_name(student_2) = false")
print("  ✗ teacher_c.can_view_email(student_2) = false")
print("  ✗ teacher_c.can_view_student_stats(student_2) = false")
print("  ✗ teacher_c.can_manage_user(student_2) = false")
print("  ✗ teacher_c.can_edit_user_info(student_2) = false")
print("")

print("【测试场景 4】版主权限（只读）")
print("Scenario 4: Moderator Permissions (Read-only)")
print("-------------------------------------------------")
print("设置：")
print("  - 版主M (moderator_m, role='moderator')")
print("  - 学生S1 (student_1)")
print("")
print("预期结果：")
print("  ✓ moderator_m.can_view_real_name(student_1) = true")
print("  ✓ moderator_m.can_view_email(student_1) = true")
print("  ✓ moderator_m.can_view_student_stats(student_1) = true")
print("  ✓ moderator_m.can_manage_user(student_1) = true")
print("  ✗ moderator_m.can_edit_role(student_1) = false  (只有管理员)")
print("  ✗ moderator_m.can_edit_teacher_status(student_1) = false")
print("")

print("【测试场景 5】管理员权限（完全控制）")
print("Scenario 5: Admin Permissions (Full Control)")
print("-------------------------------------------------")
print("设置：")
print("  - 管理员A (admin_a, role='admin')")
print("  - 学生S1 (student_1)")
print("")
print("预期结果：")
print("  ✓ admin_a.can_view_real_name(student_1) = true")
print("  ✓ admin_a.can_view_email(student_1) = true")
print("  ✓ admin_a.can_view_student_stats(student_1) = true")
print("  ✓ admin_a.can_manage_user(student_1) = true")
print("  ✓ admin_a.can_edit_role(student_1) = true")
print("  ✓ admin_a.can_edit_teacher_status(student_1) = true")
print("")

print("【测试场景 6】多班级学生")
print("Scenario 6: Student in Multiple Classes")
print("-------------------------------------------------")
print("设置：")
print("  - 教师A创建学生S (creator_id=teacher_a.id)")
print("  - 教师B创建班级C1，加入学生S")
print("  - 教师C创建班级C2，加入学生S")
print("")
print("预期结果：")
print("  ✓ teacher_a 可以查看S（创建者关系）")
print("  ✓ teacher_b 可以查看S（班级C1关系）")
print("  ✓ teacher_c 可以查看S（班级C2关系）")
print("  ✓ 所有三位教师都可以编辑S的基本信息")
print("")

print("【测试场景 7】软删除的班级成员")
print("Scenario 7: Soft-deleted Class Membership")
print("-------------------------------------------------")
print("设置：")
print("  - 学生S在班级C中，但被软删除 (deleted_at IS NOT NULL)")
print("  - 教师T是班级C的创建者")
print("")
print("预期结果：")
print("  ✗ teacher_t.can_view_real_name(student_s) = false  (已删除)")
print("  ✗ teacher_t.can_manage_user(student_s) = false")
print("  注：除非teacher_t同时也是student_s的创建者")
print("")

print("\n=================================================")
print("SQL查询测试")
print("SQL Query Tests")
print("=================================================\n")

print([[
-- 测试查询1：检查教师是否为学生的班级教师
SELECT EXISTS (
    SELECT 1 
    FROM class_memberships cm
    JOIN collections c ON cm.class_id = c.id
    WHERE cm.student_id = <student_id>
      AND c.creator_id = <teacher_id>
      AND c.is_class = true
      AND cm.deleted_at IS NULL
) AS is_class_teacher;

-- 期望：如果教师管理包含该学生的班级，返回 true
]])

print([[
-- 测试查询2：列出某教师可以查看的所有学生
SELECT DISTINCT u.id, u.username, u.real_name
FROM users u
WHERE u.deleted IS NULL
  AND (
    -- 创建者关系
    u.creator_id = <teacher_id>
    OR
    -- 班级关系
    u.id IN (
        SELECT cm.student_id
        FROM class_memberships cm
        JOIN collections c ON cm.class_id = c.id
        WHERE c.creator_id = <teacher_id>
          AND c.is_class = true
          AND cm.deleted_at IS NULL
    )
  );
]])

print("\n=================================================")
print("性能优化建议")
print("Performance Optimization Recommendations")
print("=================================================\n")

print([[
1. 索引检查：
   ✓ class_memberships.student_id (已存在)
   ✓ class_memberships.class_id (已存在)
   ✓ collections.creator_id (已存在)
   ✓ collections.is_class (已存在)

2. 查询缓存：
   ✓ 使用 permission_cache.lua 的请求级缓存
   ✓ 版本化缓存键包含 updated_at 时间戳
   ✓ 角色变更自动失效缓存

3. 查询优化：
   ✓ 使用 EXISTS 而非 COUNT(*)
   ✓ 只查询 deleted_at IS NULL 的记录
   ✓ 利用已有索引进行 JOIN

4. 监控建议：
   - 监控权限检查查询的执行时间
   - 跟踪缓存命中率
   - 分析慢查询日志
]])

print("\n=================================================")
print("手动测试步骤")
print("Manual Testing Steps")
print("=================================================\n")

print([[
1. 准备测试数据：
   ```sql
   -- 创建测试教师
   INSERT INTO users (username, email, is_teacher, role)
   VALUES 
     ('teacher_a', 'teachera@test.com', true, 'standard'),
     ('teacher_b', 'teacherb@test.com', true, 'standard'),
     ('teacher_c', 'teacherc@test.com', true, 'standard');
   
   -- 创建测试学生（teacher_a创建）
   INSERT INTO users (username, email, creator_id, real_name)
   VALUES 
     ('student_1', 'student1@test.com', 
      (SELECT id FROM users WHERE username='teacher_a'), 
      '张三'),
     ('student_2', 'student2@test.com', 
      (SELECT id FROM users WHERE username='teacher_a'), 
      '李四');
   
   -- 创建测试班级（teacher_b创建）
   INSERT INTO collections (name, creator_id, is_class)
   VALUES 
     ('数学班', (SELECT id FROM users WHERE username='teacher_b'), true),
     ('科学班', (SELECT id FROM users WHERE username='teacher_c'), true);
   
   -- 添加学生到班级
   INSERT INTO class_memberships (class_id, student_id)
   VALUES 
     ((SELECT id FROM collections WHERE name='数学班'),
      (SELECT id FROM users WHERE username='student_1')),
     ((SELECT id FROM collections WHERE name='科学班'),
      (SELECT id FROM users WHERE username='student_1'));
   ```

2. 测试权限：
   - 以 teacher_a 登录，访问 /users 查看 student_1
     → 应该看到真实姓名"张三"（创建者关系）
   
   - 以 teacher_b 登录，访问 /users 查看 student_1
     → 应该看到真实姓名"张三"（班级关系）
   
   - 以 teacher_c 登录，访问 /users 查看 student_2
     → 不应该看到真实姓名（无关系）
   
   - 以 teacher_b 登录，尝试修改 student_1 邮箱
     → 应该成功（班级教师权限）

3. 验证软删除：
   ```sql
   -- 从数学班移除 student_1
   UPDATE class_memberships
   SET deleted_at = now()
   WHERE class_id = (SELECT id FROM collections WHERE name='数学班')
     AND student_id = (SELECT id FROM users WHERE username='student_1');
   ```
   
   - 以 teacher_b 登录，访问 /users 查看 student_1
     → 不应该看到详细信息（已从班级移除）
   
   - 以 teacher_a 登录，访问 /users 查看 student_1
     → 仍可以看到详细信息（创建者关系不受影响）

4. 清理测试数据：
   ```sql
   DELETE FROM class_memberships 
   WHERE student_id IN (
     SELECT id FROM users WHERE username LIKE 'student_%'
   );
   
   DELETE FROM collections WHERE name IN ('数学班', '科学班');
   
   DELETE FROM users WHERE username LIKE 'student_%' OR username LIKE 'teacher_%';
   ```
]])

print("\n=================================================")
print("测试完成！")
print("Test Plan Complete!")
print("=================================================\n")
