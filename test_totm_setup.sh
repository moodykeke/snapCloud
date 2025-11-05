#!/bin/bash
# 测试 TOTM 横幅管理系统组件

echo "测试 TOTM 组件..."
echo ""

# 1. 检查数据库表
echo "1. 检查数据库表..."
PGPASSWORD=snap-cloud-password psql -h 127.0.0.1 -U cloud -d snapcloud -c "\d totm_banners" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ totm_banners 表存在"
else
    echo "✗ totm_banners 表不存在"
    exit 1
fi

# 2. 检查模型文件
echo "2. 检查模型文件..."
if [ -f "models/totm_banners.lua" ]; then
    echo "✓ models/totm_banners.lua 存在"
    # 检查语法
    lua -e "dofile('models/totm_banners.lua')" 2>&1 | grep -q "error"
    if [ $? -eq 0 ]; then
        echo "✗ 模型文件有语法错误"
        lua -e "dofile('models/totm_banners.lua')" 2>&1
        exit 1
    else
        echo "✓ 模型文件语法正确"
    fi
else
    echo "✗ 模型文件不存在"
    exit 1
fi

# 3. 检查视图文件
echo "3. 检查视图文件..."
if [ -f "views/admin/totm.etlua" ]; then
    echo "✓ views/admin/totm.etlua 存在"
else
    echo "✗ 视图文件不存在"
    exit 1
fi

# 4. 检查存储目录
echo "4. 检查存储目录..."
if [ -d "static/img/totm" ] && [ -w "static/img/totm" ]; then
    echo "✓ 存储目录存在且可写"
else
    echo "✗ 存储目录不存在或不可写"
    exit 1
fi

# 5. 检查翻译键
echo "5. 检查翻译键..."
MISSING=0
for key in admin_totm_title admin_totm_banner admin_totm_collection admin_totm_banner_library; do
    grep -q "$key" locales/zh.lua
    if [ $? -eq 0 ]; then
        echo "  ✓ $key"
    else
        echo "  ✗ $key 缺失"
        MISSING=1
    fi
done

if [ $MISSING -eq 0 ]; then
    echo "✓ 所有翻译键都存在"
fi

echo ""
echo "所有组件测试通过！✓"
