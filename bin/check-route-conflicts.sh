#!/bin/bash
# 路由冲突检查工具
# 用于检测 API 路由和页面路由之间可能的冲突

echo "========================================="
echo "SnapCloud 路由冲突检查工具"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 提取 api.lua 中的所有 API 路由
echo -e "${BLUE}[1] 扫描 API 路由 (api.lua)...${NC}"
api_routes=$(grep -oP "api_route\('\K[^']+(?=')" api.lua 2>/dev/null | sort -u)

if [ -z "$api_routes" ]; then
    echo -e "${YELLOW}  未找到 API 路由${NC}"
else
    echo -e "${GREEN}  找到 $(echo "$api_routes" | wc -l) 个 API 路由${NC}"
fi

echo ""

# 提取 site.lua 中的所有页面路由
echo -e "${BLUE}[2] 扫描页面路由 (site.lua)...${NC}"
page_routes=$(grep -oP "app:get\(['\"]\/\K[^'\"]+(?=['\"])" site.lua 2>/dev/null | sort -u)

if [ -z "$page_routes" ]; then
    echo -e "${YELLOW}  未找到页面路由${NC}"
else
    echo -e "${GREEN}  找到 $(echo "$page_routes" | wc -l) 个页面路由${NC}"
fi

echo ""
echo -e "${BLUE}[3] 检查潜在冲突...${NC}"
echo ""

conflicts_found=0

# 检查每个 API 路由是否会与页面路由冲突
while IFS= read -r api_route; do
    # API 路由模式: /(api/v1/)/path
    # 由于括号是可选的，它会匹配: /api/v1/path 和 /path
    
    # 检查是否有页面路由匹配这个 API 路由（去掉可选前缀）
    while IFS= read -r page_route; do
        if [ "$api_route" = "$page_route" ]; then
            echo -e "${RED}⚠️  冲突发现！${NC}"
            echo -e "   API路由:  /api/v1/${YELLOW}${api_route}${NC}"
            echo -e "   页面路由: /${YELLOW}${page_route}${NC}"
            echo -e "   ${RED}说明: API路由的可选括号 /(api/v1/)/ 会同时匹配这两个路径${NC}"
            echo ""
            conflicts_found=$((conflicts_found + 1))
        fi
    done <<< "$page_routes"
done <<< "$api_routes"

echo ""
echo "========================================="
if [ $conflicts_found -eq 0 ]; then
    echo -e "${GREEN}✓ 未发现路由冲突${NC}"
else
    echo -e "${RED}✗ 发现 $conflicts_found 个潜在冲突${NC}"
    echo ""
    echo -e "${YELLOW}建议:${NC}"
    echo "  1. 重命名页面路由，使用不同的路径"
    echo "  2. 或者修改 API 路由，避免可选括号模式"
    echo "  3. 参考 PROJECT_RULES.md 中的路由命名约定"
fi
echo "========================================="

exit $conflicts_found
