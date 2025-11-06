#!/bin/bash
# 用户信息增强功能测试脚本
# User Info Enhancement Test Script

echo "==========================================="
echo "用户信息增强功能测试"
echo "==========================================="
echo ""

BASE_URL="http://localhost:8080"
COOKIE_FILE="/tmp/snapcloud_test_cookies.txt"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
test_case() {
    local name="$1"
    local url="$2"
    local expected_pattern="$3"
    
    echo -n "测试: $name ... "
    
    response=$(curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" "$url")
    
    if echo "$response" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}✓ 通过${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ 失败${NC}"
        echo "  预期包含: $expected_pattern"
        echo "  响应片段: $(echo "$response" | head -c 200)"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "步骤 1: 测试profile.etlua组件增强"
echo "-------------------------------------------"

# 测试1: 访问用户管理页面（需要管理员权限）
echo ""
echo "1.1 测试用户管理页面 /user_admin"
test_case "用户管理页面加载" \
    "$BASE_URL/user_admin?page_number=1" \
    "250201"

# 测试2: 检查昵称显示
echo ""
echo "1.2 测试昵称显示"
test_case "昵称字段显示" \
    "$BASE_URL/user_admin?page_number=1" \
    "小明\|nickname"

# 测试3: 检查真实姓名显示（需要权限）
echo ""
echo "1.3 测试真实姓名显示"
test_case "真实姓名字段显示" \
    "$BASE_URL/user_admin?page_number=1" \
    "real_name\|张小明"

# 测试4: 检查班级信息显示
echo ""
echo "1.4 测试班级信息显示"
test_case "班级信息显示" \
    "$BASE_URL/user_admin?page_number=1" \
    "测试班级\|classes"

echo ""
echo "步骤 2: 测试API端点"
echo "-------------------------------------------"

# 测试5: 测试用户详情API
echo ""
echo "2.1 测试 API /api/v1/users/250201/detail"
api_response=$(curl -s -b "$COOKIE_FILE" "$BASE_URL/api/v1/users/250201/detail")
echo "$api_response" | python3 -m json.tool 2>/dev/null || echo "$api_response"

# 检查API返回的字段
if echo "$api_response" | grep -q "username"; then
    echo -e "${GREEN}✓ API返回username字段${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ API未返回username字段${NC}"
    ((TESTS_FAILED++))
fi

if echo "$api_response" | grep -q "nickname"; then
    echo -e "${GREEN}✓ API返回nickname字段${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ API未返回nickname字段${NC}"
    ((TESTS_FAILED++))
fi

echo ""
echo "步骤 3: 测试权限控制"
echo "-------------------------------------------"

# 测试6: 测试不同用户访问权限
echo ""
echo "3.1 测试权限控制（需手动验证）"
echo "  - 管理员可看到所有信息"
echo "  - 教师可看到自己创建的学生的真实姓名"
echo "  - 学生只能看到公开信息"

echo ""
echo "==========================================="
echo "测试结果汇总"
echo "==========================================="
echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
echo -e "${RED}失败: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}所有测试通过！✓${NC}"
    exit 0
else
    echo -e "${YELLOW}部分测试失败，请检查上述输出${NC}"
    exit 1
fi
