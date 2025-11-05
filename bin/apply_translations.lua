#!/usr/bin/env lua
local cjson = require('cjson')
local dry_run = false
for _, arg in ipairs(arg) do if arg == '--dry-run' then dry_run = true end end

local function load_json(path)
    local f = io.open(path, 'r')
    if not f then return nil end
    local content = f:read('*all')
    f:close()
    return cjson.decode(content)
end

local function replace_in_file(filepath, old_text, new_text)
    local f = io.open(filepath, 'r')
    if not f then return false end
    local content = f:read('*all')
    f:close()
    
    -- Escape special Lua pattern characters
    local pattern = old_text:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
    -- But we need to escape % in the replacement string differently
    local replacement = new_text:gsub('%%', '%%%%')
    local new_content, count = content:gsub(pattern, replacement)
    
    if count == 0 then return false end
    if not dry_run then
        f = io.open(filepath, 'w')
        f:write(new_content)
        f:close()
    end
    return true
end

local function update_locale(lang, trans)
    local path = 'locales/' .. lang .. '.lua'
    local f = io.open(path, 'r')
    if not f then return 0 end
    local content = f:read('*all')
    f:close()
    
    local existing_keys = {}
    for key in content:gmatch('%s*([%w_]+)%s*=') do existing_keys[key] = true end
    
    local new_entries = {}
    for key, translation in pairs(trans) do
        if not existing_keys[key] then
            table.insert(new_entries, string.format('    %s = "%s",', key, translation:gsub('"', '\\"')))
        end
    end
    
    if #new_entries == 0 then return 0 end
    
    local before = content:match('^(.-)local%s+locale%s*=%s*{')
    local after = content:match('(}%s*return%s+locale%s*)$')
    local middle = content:match('local%s+locale%s*=%s*{(.-)%s*}%s*return%s+locale')
    
    local new_content = before .. 'local locale = {\n' .. middle
    if not middle:match(',$%s*$') then new_content = new_content .. ',' end
    new_content = new_content .. '\n\n    -- Auto-generated\n' .. table.concat(new_entries, '\n') .. '\n' .. after
    
    if not dry_run then
        f = io.open(path, 'w')
        f:write(new_content)
        f:close()
    end
    return #new_entries
end

print('╔════════════════════════════════════════════════════════╗')
print('║  Apply Translations                                   ║')
print('╚════════════════════════════════════════════════════════╝\n')
if dry_run then print('🔍 DRY RUN\n') end

local hardcoded = load_json('.auto-i18n-cache/hardcoded_texts.json')
local trans = load_json('.auto-i18n-cache/translations.json')
if not hardcoded or not trans then print('❌ Missing data files'); os.exit(1) end

local stats = {files = 0, replaced = 0, errors = 0}

print('📝 Applying translations...\n')
for filepath, items in pairs(hardcoded) do
    local changed = false
    for _, item in ipairs(items) do
        if trans[item.key] then
            local new_text = '<%- locale.get("' .. item.key .. '") %>'
            if replace_in_file(filepath, item.text, new_text) then
                if not changed then
                    print('✓ ' .. filepath)
                    changed = true
                    stats.files = stats.files + 1
                end
                stats.replaced = stats.replaced + 1
            else
                stats.errors = stats.errors + 1
            end
        end
    end
end

print('\n🌍 Updating locales...\n')
for _, lang in ipairs({'en', 'zh', 'de', 'es', 'fr', 'it', 'pt', 'tr', 'ca', 'hy'}) do
    local lang_trans = {}
    for key, langs in pairs(trans) do
        if langs[lang] then lang_trans[key] = langs[lang] end
    end
    local added = update_locale(lang, lang_trans)
    if added > 0 then print('✓ locales/' .. lang .. '.lua +' .. added) end
end

print('\n╔══════════════════════════════════════╗')
print('║  Summary                             ║')
print('╚══════════════════════════════════════╝\n')
print('Files:    ' .. stats.files)
print('Replaced: ' .. stats.replaced)
if stats.errors > 0 then print('Errors:   ' .. stats.errors) end
print('')
