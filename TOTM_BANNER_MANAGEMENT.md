# TOTM横幅管理系统

## 功能说明

此功能增强了 Topic of the Month (TOTM) 管理页面，支持管理多个横幅图片。

### 新增功能

1. **横幅库管理**
   - 上传多个横幅图片
   - 查看所有已上传的横幅
   - 选择激活特定横幅
   - 删除不需要的横幅（已激活的横幅不能删除）

2. **数据库支持**
   - 新增 `totm_banners` 表存储横幅元数据
   - 支持查询横幅历史
   - 记录上传者和上传时间

3. **文件管理**
   - 横幅文件存储在 `static/img/totm/` 目录
   - 使用时间戳生成唯一文件名
   - 保留原始文件名用于显示

## 安装步骤

### 快速安装（推荐）

使用一键安装脚本：

```bash
cd /home/snapcloud/snapCloud
./install_totm_banners.sh
```

脚本会自动完成：
- ✓ 检查数据库连接
- ✓ 运行数据库迁移
- ✓ 创建存储目录
- ✓ 验证安装成功

### 手动安装

#### 数据库配置信息

开发环境默认配置（见 `config.lua`）：
- **Host**: 127.0.0.1
- **Port**: 5432
- **User**: cloud
- **Password**: snap-cloud-password
- **Database**: snapcloud

##### 1. 运行数据库迁移

```bash
cd /home/snapcloud/snapCloud

# 方法 A: 使用 lapis migrate（推荐 - 自动使用配置文件）
bin/lapis-migrate

# 方法 B: 手动执行 SQL（会提示输入密码）
psql -h 127.0.0.1 -U cloud -d snapcloud < create_totm_banners_table.sql
# 输入密码: snap-cloud-password

# 方法 C: 免密码执行
PGPASSWORD=snap-cloud-password psql -h 127.0.0.1 -U cloud -d snapcloud < create_totm_banners_table.sql

# 验证表是否创建成功
psql -h 127.0.0.1 -U cloud -d snapcloud -c "\d totm_banners"
```

##### 2. 创建横幅存储目录

```bash
mkdir -p static/img/totm
chmod 755 static/img/totm
```

#### 3. 重启服务器

```bash
# 如果使用 lapis
lapis server development

# 或重新加载 nginx
nginx -s reload
```

## 使用说明

### 访问管理页面

1. 以 moderator 或 admin 身份登录
2. 访问 `/totm` 路径
3. 你会看到三个部分：
   - **当前激活的横幅**：显示正在使用的横幅
   - **上传新横幅**：上传新的横幅图片
   - **横幅库**：显示所有已上传的横幅

### 上传横幅

1. 点击"选择文件"按钮
2. 选择图片文件（建议尺寸：1200x300px）
3. 点击"上传横幅"按钮
4. 上传成功后页面会刷新，新横幅会出现在横幅库中

### 激活横幅

1. 在横幅库中找到要激活的横幅
2. 点击"选择"按钮
3. 确认激活操作
4. 该横幅会成为当前激活的横幅，在首页显示

### 删除横幅

1. 在横幅库中找到要删除的横幅（只能删除未激活的）
2. 点击"删除"按钮
3. 确认删除操作
4. 横幅文件和数据库记录会被删除

## API 端点

新增了以下 API 端点：

- `POST /api/set_active_banner` - 激活指定横幅
  - 参数: `banner_id` (integer)
  
- `POST /api/delete_banner` - 删除指定横幅
  - 参数: `banner_id` (integer)

## 数据库结构

```sql
CREATE TABLE totm_banners (
    id SERIAL PRIMARY KEY,
    filename TEXT UNIQUE NOT NULL,
    original_name TEXT NOT NULL,
    uploader_id INTEGER,  -- 关联 users.id (无外键约束)
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE NOT NULL
);

-- 索引
CREATE INDEX totm_banners_uploader_id_idx ON totm_banners(uploader_id);
CREATE INDEX totm_banners_is_active_idx ON totm_banners(is_active);
```

**注意**: `uploader_id` 字段不使用外键约束，因为 `users` 表的主键是 `username` 而非 `id`。

## 文件列表

### 新增文件
- `models/totm_banners.lua` - 横幅模型
- `create_totm_banners_table.sql` - 数据库迁移脚本
- `install_totm_banners.sh` - 一键安装脚本 ⭐
- `TOTM_BANNER_MANAGEMENT.md` - 本文档

### 修改文件
- `migrations.lua` - 添加数据库迁移
- `models.lua` - 加载 TotmBanners 模型
- `disk.lua` - 更新横幅保存逻辑
- `controllers/site.lua` - 添加横幅管理控制器
- `api.lua` - 添加 API 路由
- `views/admin/totm.etlua` - 更新管理界面
- `locales/en.lua` - 英文翻译
- `locales/zh.lua` - 中文翻译
- `locales/*.lua` - 其他语言翻译模板

## 翻译键

新增的翻译键（已包含英文和中文）：

| 键名 | 英文 | 中文 |
|------|------|------|
| admin_totm_current_banner | Current Active Banner | 当前激活的横幅 |
| admin_totm_uploaded | Uploaded | 上传于 |
| admin_totm_no_active_banner | No active banner set... | 未设置激活的横幅... |
| admin_totm_upload_new | Upload New Banner | 上传新横幅 |
| admin_totm_banner_library | Banner Library | 横幅库 |
| admin_totm_active | Active | 已激活 |
| admin_totm_select | Select | 选择 |
| admin_totm_delete | Delete | 删除 |
| admin_totm_confirm_select | Set this banner as active? | 将此横幅设为激活状态？ |
| admin_totm_confirm_delete | Delete banner | 删除横幅 |
| admin_totm_banner_activated | Banner activated successfully! | 横幅激活成功！ |
| admin_totm_banner_deleted | Banner deleted successfully! | 横幅删除成功！ |

## 注意事项

1. **权限要求**：需要 moderator 或更高权限才能访问管理页面
2. **文件大小**：建议横幅图片不超过 2MB
3. **图片格式**：支持常见图片格式（PNG, JPG, GIF等）
4. **备份建议**：在删除横幅前，建议先备份重要的横幅文件
5. **激活限制**：同时只能有一个横幅处于激活状态
6. **删除限制**：不能删除当前激活的横幅，需要先激活其他横幅

## 故障排除

### 横幅不显示

1. 检查文件权限：`ls -la static/img/totm/`
2. 检查数据库记录：`SELECT * FROM totm_banners;`
3. 检查 nginx 日志：`tail -f logs/error.log`

### 上传失败

1. 检查目录是否存在：`ls -d static/img/totm`
2. 检查写入权限：`touch static/img/totm/test.txt`
3. 检查文件大小限制：nginx 配置中的 `client_max_body_size`

### 数据库错误

```bash
# 检查数据库连接
psql -h 127.0.0.1 -U cloud -d snapcloud -c "SELECT version();"
# 密码: snap-cloud-password

# 检查表是否存在
PGPASSWORD=snap-cloud-password psql -h 127.0.0.1 -U cloud -d snapcloud -c "\d totm_banners"

# 检查迁移状态
PGPASSWORD=snap-cloud-password psql -h 127.0.0.1 -U cloud -d snapcloud -c "SELECT * FROM lapis_migrations WHERE name = '2025-11-05:0';"

# 手动重新运行迁移（如果失败）
PGPASSWORD=snap-cloud-password psql -h 127.0.0.1 -U cloud -d snapcloud < create_totm_banners_table.sql
```

## 安全提示

⚠️ **重要**：
- 默认密码 `snap-cloud-password` **仅用于开发环境**
- 生产环境请使用环境变量设置强密码：
  ```bash
  export DATABASE_PASSWORD='your-strong-password'
  ```
- 不要在代码或文档中提交生产环境密码
- 确保 `.env` 文件在 `.gitignore` 中

## 未来改进

- [ ] 添加横幅预览功能
- [ ] 支持批量上传
- [ ] 添加图片裁剪工具
- [ ] 支持横幅排序
- [ ] 添加横幅使用统计
- [ ] 支持定时自动切换横幅

## 作者

- AI Assistant (2025-11-05)

## 许可证

遵循 SnapCloud 项目的 AGPL-3.0 许可证
