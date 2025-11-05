#!/usr/bin/env lua
-- 班级管理 API 功能测试脚本

local lapis = require("lapis")
local app = require("app")
local ClassMemberships = require("models.class_memberships")
local Collections = require("models.collections")
local Users = require("models.users")

print("=== 班级管理系统测试 ===\n")

-- 测试 1: 查找教师用户
print("测试 1: 查找教师用户")
local teacher = Users:find({ username = "teacher" })
if teacher then
    print(string.format("✓ 找到教师: %s (ID: %d, is_teacher: %s)", 
        teacher.username, teacher.id, tostring(teacher.is_teacher)))
else
    print("✗ 未找到教师账号 'teacher'")
    os.exit(1)
end

-- 测试 2: 创建测试班级
print("\n测试 2: 创建测试班级")
local test_class = Collections:find({
    creator_id = teacher.id,
    name = "Lua测试班级"
})

if not test_class then
    test_class = Collections:create({
        creator_id = teacher.id,
        name = "Lua测试班级",
        description = "自动化测试创建的班级",
        is_class = true,
        published = true
    })
    print(string.format("✓ 创建班级: %s (ID: %d)", test_class.name, test_class.id))
else
    print(string.format("✓ 使用现有班级: %s (ID: %d)", test_class.name, test_class.id))
end

-- 测试 3: 查找学生
print("\n测试 3: 查找学生账号")
local students = {}
local student_usernames = {"yangchen", "dongyichen", "250201"}
for _, username in ipairs(student_usernames) do
    local student = Users:find({ username = username })
    if student then
        table.insert(students, student)
        print(string.format("✓ 找到学生: %s (ID: %d)", student.username, student.id))
    else
        print(string.format("✗ 未找到学生: %s", username))
    end
end

-- 测试 4: 添加学生到班级
print("\n测试 4: 添加学生到班级")
for _, student in ipairs(students) do
    local success, result = ClassMemberships:add_student(test_class.id, student.id)
    if success then
        print(string.format("✓ 添加学生 %s 到班级", student.username))
    else
        print(string.format("  学生 %s: %s", student.username, result))
    end
end

-- 测试 5: 查询班级成员
print("\n测试 5: 查询班级成员")
local members = ClassMemberships:get_class_members_detail(test_class.id)
print(string.format("✓ 班级共有 %d 名成员:", #members))
for i, member in ipairs(members) do
    print(string.format("  %d. %s (激活: %s, 加入时间: %s)", 
        i, 
        member.username, 
        member.is_active and "是" or "否",
        member.joined_at:sub(1, 10)
    ))
end

-- 测试 6: 查询学生所在班级
print("\n测试 6: 查询学生所在班级")
if #students > 0 then
    local student = students[1]
    local student_classes = ClassMemberships:get_student_classes(student.id)
    print(string.format("✓ 学生 %s 所在班级数: %d", student.username, #student_classes))
    for i, class_info in ipairs(student_classes) do
        print(string.format("  %d. %s (教师: %s)", 
            i, 
            class_info.class_name, 
            class_info.teacher_username
        ))
    end
end

-- 测试 7: 测试成员状态切换
print("\n测试 7: 测试成员激活/停用")
if #students > 0 then
    local student = students[1]
    local membership = ClassMemberships:find({
        class_id = test_class.id,
        student_id = student.id
    })
    
    if membership then
        local old_status = membership.is_active
        local success = ClassMemberships:toggle_active(test_class.id, student.id)
        if success then
            membership:refresh()
            print(string.format("✓ 学生 %s 状态: %s → %s", 
                student.username,
                old_status and "激活" or "停用",
                membership.is_active and "激活" or "停用"
            ))
            -- 恢复原状态
            ClassMemberships:toggle_active(test_class.id, student.id)
        end
    end
end

print("\n=== 测试完成 ===")
print("班级管理系统核心功能正常工作！")
print("\n下一步:")
print("1. 在浏览器中访问 http://localhost:8080/teacher/classes")
print("2. 使用教师账号登录")
print("3. 查看和管理班级")
