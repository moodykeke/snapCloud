-- Bulk Import Logs Model
-- 批量导入历史记录模型

local Model = package.loaded.Model

local BulkImportLogs = Model:extend('bulk_import_logs', {
    primary_key = 'id'
})

return BulkImportLogs
