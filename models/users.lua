-- Snap!Cloud User Model
-- =====================
--
-- A cloud backend for Snap!
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2024 by Bernat Romagosa and Michael Ball
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
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.-

local Model = package.loaded.Model
local util = require('lapis.util')
local escape = util.escape

-- Generated schema dump: (do not edit)
--
-- CREATE VIEW active_users AS
--  SELECT users.id,
--   users.created,
--   users.username,
--   users.email,
--   users.salt,
--   users.password,
--   users.about,
--   users.location,
--   users.verified,
--   users.role,
--   users.deleted,
--   users.unique_email,
--   users.bad_flags,
--   users.is_teacher,
--   users.creator_id
--    FROM public.users
--   WHERE (users.deleted IS NULL);
--
local ActiveUsers = Model:extend('active_users', {
    type = 'user',
    constraints = {
        -- TODO: add conatrains for usernames, etc.
        -- username = function(self, value) end,
        email = function (self, value)
            if not value or value == '' then
                return 'email must be present'
            end
            value = util.trim(tostring(value))
            if #value < 6 then
                return 'email must be at least 6 characters'
            elseif not string.find(value, "@") then
                return 'email must contain an "@"'
            end
        end
    },
    relations = {
        {'collections', has_many = 'Collections'},
        {'editable_collections',
            fetch = function (self)
                return package.loaded.Collections:select(
                    [[WHERE (collections.creator_id = ? OR editor_ids @> array[?]) OR
                        collections.free_for_all]],
                    self.id,
                    self.id,
                    { fields = 'name, collections.id' }
                )
            end
        },
        {'ffa_collections',
            fetch = function (self)
                return package.loaded.Collections:select(
                    [[WHERE collections.creator_id = ? AND collections.free_for_all]],
                    self.id,
                    { fields = 'name, collections.id' }
                )
            end
        },
        {'public_collections',
            fetch = function (self)
                return package.loaded.Collections:select(
                    [[WHERE collections.creator_id = ? AND published ]],
                    self.id,
                    { fields = 'name, collections.id' }
                )
            end
        },
        {'project_count',
            fetch = function (self)
                return package.loaded.Projects:select(
                    'WHERE username = ?',
                    self.username,
                    { fields = 'count(*) as count' }
                )[1].count
            end
        },
    },
    -- 获取详细的项目统计信息
    get_project_stats = function (self)
        local db = require('lapis.db')
        local result = db.query([[
            SELECT
                COUNT(*) as total,
                COUNT(*) FILTER (WHERE ispublic = true) as shared,
                COUNT(*) FILTER (WHERE ispublished = true) as published
            FROM active_projects
            WHERE username = ?
        ]], self.username)
        
        if result and #result > 0 then
            return {
                total = tonumber(result[1].total) or 0,
                shared = tonumber(result[1].shared) or 0,
                published = tonumber(result[1].published) or 0
            }
        end
        
        return { total = 0, shared = 0, published = 0 }
    end,
    follows = function (self, a_user)
        return package.loaded.Followers:find({
            follower_id = self.id,
            followed_id = a_user.id
        }) ~= nil
    end,
    isadmin = function (self)
        return self.role == 'admin'
    end,
    ismoderator = function (self)
        return self.role == 'moderator'
    end,
    isbanned = function (self)
        return self.role == 'banned'
    end,
    is_student = function (self)
        return self.role == 'student'
    end,
    has_min_role = function (self, expected_role)
        return package.loaded.Users.roles[self.role] >=
            package.loaded.Users.roles[expected_role]
    end,
    has_one_of_roles = function (self, roles)
        for _, role in pairs(roles) do
            if self.role == role then
                return true
            end
        end
        return false
    end,
    url_for = function (self, purpose)
        local urls = {
            site = '/user?username=' .. escape(self.username)
        }
        return urls[purpose]
    end,
    logging_params = function (self)
        -- Identifying info, excluding email (PII)
        return { id = self.id, username = self.username }
    end,
    discourse_email = function (self)
        if self.unique_email ~= nil and self.unique_email ~= '' then
            return self.unique_email
        end
        return self:ensure_unique_email()
    end,
    ensure_unique_email = function (self)
        -- If a user is new, then their "unique email" is an unmodified email
        -- address.
        -- When emails are not unique, we will create a new unique email.
        -- Unique emails take the form:
        --                      original-address+snap-id-01234@original.domain
        local unique_email = self.email
        if self:shares_email_with_others() then
            unique_email =
                string.gsub(self.email, '@', '+snap-id-' .. self.id .. '@')
        end
        self:update({ unique_email = unique_email })
        return unique_email
    end,
    shares_email_with_others = function (self)
        local count = package.loaded.AllUsers:count("unique_email ilike ?", self.email)
        return count > 0
    end,
    cannot_access_forum = function (self)
        return self:is_student() or self:isbanned() or self.validated == false
    end,
    
    -- 获取学生所属班级列表
    -- Get student's class memberships
    get_classes = function(self)
        if not self:is_student() then return {} end
        
        local db = package.loaded.db
        
        -- 使用student_classes视图获取班级信息
        local result = db.query([[
            SELECT 
                class_id as id,
                class_name as name,
                teacher_id,
                teacher_username
            FROM student_classes
            WHERE student_id = ?
            ORDER BY class_name
        ]], self.id)
        
        return result or {}
    end,
    
    -- 获取学生作业统计
    -- Get student's assignment statistics
    get_assignment_stats = function(self)
        if not self:is_student() then return nil end
        
        local db = package.loaded.db
        
        -- 查询学生的作业统计
        -- 作业通过collection_id关联到班级，班级ID在class_memberships中
        local result = db.query([[
            SELECT 
                COUNT(DISTINCT a.id) as total_assignments,
                COUNT(DISTINCT s.id) as submitted_count,
                AVG(s.points) as avg_points
            FROM assignments a
            LEFT JOIN submissions s ON a.id = s.assignment_id AND s.student_id = ?
            WHERE a.deleted_at IS NULL
                AND a.published = true
                AND a.teacher_id = ?
        ]], self.id, self.creator_id or 0)
        
        if not result or not result[1] then
            return {
                total = 0,
                submitted = 0,
                avg_points = 0,
                completion_rate = 0
            }
        end
        
        local row = result[1]
        local total = tonumber(row.total_assignments) or 0
        local submitted = tonumber(row.submitted_count) or 0
        local avg_points = tonumber(row.avg_points) or 0
        
        return {
            total = total,
            submitted = submitted,
            avg_points = avg_points,
            completion_rate = total > 0 
                and math.floor((submitted / total) * 100)
                or 0
        }
    end
})


-- Note: Due to client-side pre-hashing, password length isn't useful...
ActiveUsers.validations = {
    { 'username', exists = true, min_length = 4, max_length = 200 },
    { 'password', exists = true, min_length = 6 },
    { 'email', exists = true, min_length = 5 }
}

ActiveUsers.roles = {
    admin = 5,
    moderator = 4,
    reviewer = 3,
    standard = 2,
    student = 1,
    banned = 0
}

package.loaded.DeletedUsers = Model:extend('deleted_users')

-- Used for queries across the entire users table.
package.loaded.AllUsers = Model:extend('users')

return ActiveUsers
