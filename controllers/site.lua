-- Site controller
-- ===============
--
-- Written by Bernat Romagosa and Michael Ball
--
-- Copyright (C) 2022 by Bernat Romagosa and Michael Ball
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

local yield_error = package.loaded.yield_error
local capture_errors = package.loaded.capture_errors
local db = package.loaded.db
local app = package.loaded.app

local Users = package.loaded.Users
local FeaturedCollections = package.loaded.FeaturedCollections
local BannedIPs = package.loaded.BannedIPs

require 'responses'
require 'validation'

SiteController = {
    banned_ips = capture_errors(function (self)
        if not self.params.page_number then self.params.page_number = 1 end
        local paginator = BannedIPs:paginated(
            (self.params.search_term and (db.interpolate_query(
                'WHERE ip ILIKE ? ',
                '%' .. self.params.search_term .. '%'
            )) or ' ') .. 'ORDER BY updated_at ASC',
            {
                per_page = self.params.items_per_page or 256
            }
        )
        self.num_pages = paginator:num_pages()
        return paginator:get_page(self.params.page_number)
    end),
    unban_ip = capture_errors(function (self)
        assert_admin(self)
        local ip = BannedIPs:find(self.params.ip)
        if ip and ip:delete() then
            return okResponse('IP unbanned')
        else
            yield_error('Failed to unban IP')
        end
    end),
    feature_carousel = capture_errors(function (self)
        assert_min_role(self, 'admin')

        local FeaturedCollections = package.loaded.FeaturedCollections

        -- 检查是否已存在
        local existing = FeaturedCollections:find({
            collection_id = self.params.collection_id,
            page_path = self.params.page_path
        })

        if existing then
            -- 如果已存在，返回成功消息（幂等操作）
            return okResponse('collection already featured')
        end

        -- 创建新的轮播图
        FeaturedCollections:create({
            collection_id = self.params.collection_id,
            page_path = self.params.page_path,
            type = self.params.type
        })

        return okResponse('collection featured')
    end),
    unfeature_carousel = capture_errors(function (self)
        assert_min_role(self, 'admin')

        local FeaturedCollections = package.loaded.FeaturedCollections

        local feature = FeaturedCollections:find({
            collection_id = self.params.collection_id,
            page_path = self.params.page_path
        })

        if feature then feature:delete() else yield_error() end

        return okResponse('collection unfeatured')
    end),
    set_totm = capture_errors(function (self)
        assert_min_role(self, 'moderator')

        local FeaturedCollections = package.loaded.FeaturedCollections

        -- find out whether there was a totm already
        local carousel = FeaturedCollections:find({
            page_path = 'index',
            type = 'totm'
        })

        if carousel then
            carousel:update({ collection_id = self.params.id })
        else
            FeaturedCollections:create({
                collection_id = self.params.id,
                page_path = 'index',
                type = 'totm'
            })
        end
        return okResponse('totm set to ' .. self.params.id)
    end),
    set_active_banner = capture_errors(function (self)
        assert_min_role(self, 'moderator')
        
        local TotmBanners = package.loaded.TotmBanners
        local success = TotmBanners:set_active(self.params.banner_id)
        
        if success then
            return okResponse('banner activated')
        else
            yield_error('Banner not found')
        end
    end),
    delete_banner = capture_errors(function (self)
        assert_min_role(self, 'moderator')
        
        local TotmBanners = package.loaded.TotmBanners
        local banner = TotmBanners:find({ id = self.params.banner_id })
        
        if banner then
            if banner.is_active then
                yield_error('Cannot delete active banner')
            end
            
            -- Delete file from filesystem
            os.remove('static/img/totm/' .. banner.filename)
            
            -- Delete from database
            banner:delete()
            
            return okResponse('banner deleted')
        else
            yield_error('Banner not found')
        end
    end)
}
