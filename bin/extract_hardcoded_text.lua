#!/usr/bin/env lua
-- Hardcoded Text Extractor
-- Scans template and static files for untranslated hardcoded text in ATTRIBUTES ONLY
-- Usage: lua bin/extract_hardcoded_text.lua

local lfs = require('lfs')
local cjson = require('cjson')

-- Extractor configuration
local extractor = {
    scan_dirs = {'views', 'static'},
    file_patterns = {'%.etlua$', '%.html$'},
    
    -- ONLY scan attributes, NOT HTML content (to avoid breaking templates)
    patterns = {
        {pattern = 'placeholder%s*=%s*["\']([^"\']+)["\']', context = 'placeholder', min_length = 1},
        {pattern = 'title%s*=%s*["\']([^"\']+)["\']', context = 'title', min_length = 1},
        {pattern = 'alt%s*=%s*["\']([^"\']+)["\']', context = 'alt', min_length = 1}
    },
    
    exclude_patterns = {
        'locale%.get', '^https?://', '^/', '^%s*$', '^[%d%s%.,:;]+$',
        '^<%%-', '^<%?', '^<!%-%-', '^[{%%]', '^%$'
    },
    
    stats = {files_scanned = 0, texts_found = 0}
}

local function generate_key(text, context, file_path)
    local file_prefix = file_path:match('views/([^/]+)') or 
                       file_path:match('static/([^/]+)') or 'general'
    file_prefix = file_prefix:gsub('%.etlua$', ''):gsub('%.html$', ''):gsub('[^%w_]', '_')
    
    local key = text:lower():gsub('[^%w%s]', ''):gsub('%s+', '_'):gsub('_+', '_')
    key = key:gsub('^_', ''):gsub('_$', '')
    if #key > 50 then key = key:sub(1, 50) end
    
    if context and context ~= '' then
        context = context:gsub('[^%w_]', '_')
        key = context:lower() .. '_' .. key
    end
    
    return file_prefix .. '_' .. key
end

local function should_exclude(text)
    for _, pattern in ipairs(extractor.exclude_patterns) do
        if text:match(pattern) then return true end
    end
    return false
end

local function scan_file(file_path)
    local file = io.open(file_path, 'r')
    if not file then return end
    
    local content = file:read('*all')
    file:close()
    
    extractor.stats.files_scanned = extractor.stats.files_scanned + 1
    local file_results = {}
    
    for _, pattern_config in ipairs(extractor.patterns) do
        for match in content:gmatch(pattern_config.pattern) do
            match = match:match('^%s*(.-)%s*$')
            
            if #match >= pattern_config.min_length and not should_exclude(match) then
                local key = generate_key(match, pattern_config.context, file_path)
                table.insert(file_results, {text = match, context = pattern_config.context, key = key})
                extractor.stats.texts_found = extractor.stats.texts_found + 1
            end
        end
    end
    
    return file_results
end

local function scan_directory(dir, results)
    for entry in lfs.dir(dir) do
        if entry ~= '.' and entry ~= '..' then
            local path = dir .. '/' .. entry
            local attr = lfs.attributes(path)
            
            if attr.mode == 'directory' then
                scan_directory(path, results)
            elseif attr.mode == 'file' then
                for _, pattern in ipairs(extractor.file_patterns) do
                    if path:match(pattern) then
                        local file_results = scan_file(path)
                        if file_results and #file_results > 0 then
                            results[path] = file_results
                        end
                        break
                    end
                end
            end
        end
    end
end

print('🔍 Scanning for hardcoded text (attributes only)...\n')

local results = {}
for _, dir in ipairs(extractor.scan_dirs) do
    print('Scanning ' .. dir .. '/*...')
    scan_directory(dir, results)
end

print('\n╔════════════════════════════════════════════════════════╗')
print('║  Hardcoded Text Extraction Report                     ║')
print('╚════════════════════════════════════════════════════════╝\n')
print('📊 Statistics:')
print('  Files scanned: ' .. extractor.stats.files_scanned)
print('  Texts found:   ' .. extractor.stats.texts_found)
print('\n📝 Sample results:\n')

local count = 0
for file_path, items in pairs(results) do
    count = count + 1
    if count <= 20 then
        print('📄 ' .. file_path .. ' (' .. #items .. ' items)')
        for i = 1, math.min(3, #items) do
            local item = items[i]
            print('   [' .. item.context .. '] "' .. item.text:sub(1, 40) .. '" → ' .. item.key)
        end
        if #items > 3 then print('   ... and ' .. (#items - 3) .. ' more') end
        print('')
    end
end

os.execute('mkdir -p .auto-i18n-cache')
local output_file = io.open('.auto-i18n-cache/hardcoded_texts.json', 'w')
if output_file then
    output_file:write(cjson.encode(results))
    output_file:close()
    print('💾 Saved to: .auto-i18n-cache/hardcoded_texts.json\n')
else
    print('❌ Error: Could not save results\n')
    os.exit(1)
end
