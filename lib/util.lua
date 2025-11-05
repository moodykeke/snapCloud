-- Snap!Cloud Utilities
-- =====================
--
-- A cloud backend for Snap!
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2023 by Bernat Romagosa and Michael Ball
--
-- This file is part of Snap Cloud.
--
-- Snap Cloud is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local os = require('os')
local config = package.loaded.config

local function capitalize(str)
    return str:gsub("^%l", string.upper)
end

-- Remove the protocol and port from a URL
local function domain_name(url)
  if not url then
      return
  end
  return url:gsub('https*://', ''):gsub(':%d+$', '')
end

local function escape_html(text)
  if text == nil then return end

  text = tostring(text)
  local map = {
      ["&"] = "&amp;",
      ["<"] = "&lt;",
      [">"] = "&gt;",
      ['"'] = "&quot;",
      ["'"] = "&#039;"
  }

  return (text:gsub("[&<>\'\"]", function(m)
      return map[m]
  end))
end

local function visualize_whitespace_html(str)
    if not str then
        return "<code>[nil]</code>"
    end

    if str == "" then
        return "<code>[empty]</code>"
    end

    local map = {
        [" "] = "·",
        ["\t"] = "→",
        ["\n"] = "↵",
        ["\r"] = "⏎"
    }

    return escape_html(str):gsub("[\t\n\r ]", function(m)
        return '<code>' .. map[m] .. '</code>'
    end)
end

local function group_by_type(items)
  local result = {}
  for _, item in ipairs(items) do
    if not result[item.type] then
      result[item.type] = {}
    end
    table.insert(result[item.type], item)
  end
  return result
end

local function cache_buster ()
    if config._name == "development" then
      return os.time()
    end
    local cache = ngx.shared.session_cache
    if cache:get('cache_buster') then
      return cache:get('cache_buster')
    end
    local cache_buster_value = os.time()
    if config.release_sha then
      cache_buster_value = config.release_sha
    end
    cache:set('cache_buster', cache_buster_value)
    return cache_buster_value
end

-- 解析CSV数据
-- 支持引号包裹的字段，处理字段中的逗号和换行
local function parse_csv(csv_text)
    local lines = {}
    local current_line = {}
    local current_field = ""
    local in_quotes = false
    local i = 1
    
    while i <= #csv_text do
        local char = csv_text:sub(i, i)
        
        if char == '"' then
            if in_quotes and i < #csv_text and csv_text:sub(i+1, i+1) == '"' then
                -- 双引号转义
                current_field = current_field .. '"'
                i = i + 1
            else
                in_quotes = not in_quotes
            end
        elseif char == ',' and not in_quotes then
            table.insert(current_line, current_field)
            current_field = ""
        elseif char == '\n' and not in_quotes then
            if current_field ~= "" or #current_line > 0 then
                table.insert(current_line, current_field)
                if #current_line > 0 then
                    table.insert(lines, current_line)
                end
                current_line = {}
                current_field = ""
            end
        elseif char == '\r' and not in_quotes then
            -- 跳过回车符
        else
            current_field = current_field .. char
        end
        
        i = i + 1
    end
    
    -- 处理最后一行
    if current_field ~= "" or #current_line > 0 then
        table.insert(current_line, current_field)
        if #current_line > 0 then
            table.insert(lines, current_line)
        end
    end
    
    return lines
end

-- 将CSV行转换为用户对象数组
-- headers: 列名数组，例如 {"username", "password", "email", "nickname", "real_name", "role"}
-- rows: CSV解析后的数据行
-- apply_defaults: 是否应用默认值（nickname和real_name默认为username）
local function csv_to_users(headers, rows, apply_defaults)
    local users = {}
    
    for row_idx, row in ipairs(rows) do
        local user = {}
        for col_idx, value in ipairs(row) do
            if headers[col_idx] then
                -- 去除前后空格
                value = value:match("^%s*(.-)%s*$")
                if value ~= "" then
                    user[headers[col_idx]] = value
                end
            end
        end
        
        -- 应用默认值
        if apply_defaults and user.username then
            if not user.nickname or user.nickname == "" then
                user.nickname = user.username
            end
            if not user.real_name or user.real_name == "" then
                user.real_name = user.username
            end
        end
        
        -- 只添加至少有用户名的记录
        if user.username then
            user.row_number = row_idx + 1  -- +1 因为第一行是标题
            table.insert(users, user)
        end
    end
    
    return users
end


return {
  capitalize = capitalize,
  domain_name = domain_name,
  escape_html = escape_html,
  visualize_whitespace_html = visualize_whitespace_html,
  group_by_type = group_by_type,
  cache_buster = cache_buster,
  parse_csv = parse_csv,
  csv_to_users = csv_to_users,
}
