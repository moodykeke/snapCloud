#!/bin/bash
# TOTM 横幅管理系统安装脚本
# 使用方法: ./install_totm_banners.sh

set -e  # 遇到错误立即退出

echo "================================"
echo "TOTM 横幅管理系统安装向导"
echo "================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 数据库配置（从 config.lua 读取）
DB_HOST=${DATABASE_HOST:-127.0.0.1}
DB_PORT=${DATABASE_PORT:-5432}
DB_USER=${DATABASE_USERNAME:-cloud}
DB_PASS=${DATABASE_PASSWORD:-snap-cloud-password}
DB_NAME=${DATABASE_NAME:-snapcloud}

echo -e "${YELLOW}步骤 1/3: 检查数据库连接...${NC}"
export PGPASSWORD=$DB_PASS
if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 数据库连接成功${NC}"
else
    echo -e "${RED}✗ 数据库连接失败${NC}"
    echo "请检查数据库配置: Host=$DB_HOST, Port=$DB_PORT, User=$DB_USER, Database=$DB_NAME"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 2/3: 运行数据库迁移...${NC}"

# 检查迁移是否已运行
MIGRATION_EXISTS=$(psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM lapis_migrations WHERE name = '2025-11-05:0';" | xargs)

if [ "$MIGRATION_EXISTS" -eq "1" ]; then
    echo -e "${YELLOW}! 迁移已存在，跳过...${NC}"
else
    echo "执行迁移脚本..."
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < create_totm_banners_table.sql
    echo -e "${GREEN}✓ 数据库迁移完成${NC}"
fi

# 验证表是否创建
if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\d totm_banners" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ totm_banners 表已创建${NC}"
else
    echo -e "${RED}✗ totm_banners 表创建失败${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 3/3: 创建存储目录...${NC}"

# 创建横幅存储目录
mkdir -p static/img/totm
chmod 755 static/img/totm
echo -e "${GREEN}✓ 存储目录已创建: static/img/totm${NC}"

# 检查目录权限
if [ -w static/img/totm ]; then
    echo -e "${GREEN}✓ 目录可写${NC}"
else
    echo -e "${RED}✗ 目录不可写，请检查权限${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}安装完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "下一步操作："
echo "1. 重启服务器: lapis server development"
echo "2. 访问管理页面: http://localhost:8080/totm"
echo "3. 以 moderator 或 admin 身份登录即可使用"
echo ""
echo "查看详细文档: cat TOTM_BANNER_MANAGEMENT.md"
echo ""

# 显示数据库信息
echo "数据库统计:"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) as banner_count FROM totm_banners;"
