-- TOTM Banners Model
-- ===================

local db = require('lapis.db')
local Model = require('lapis.db.model').Model

local TotmBanners = Model:extend('totm_banners', {
    timestamp = true
})

function TotmBanners:get_active_banner()
    return self:find({ is_active = true })
end

function TotmBanners:set_active(banner_id)
    -- Deactivate all banners first
    db.update(self:table_name(), { is_active = false })
    
    -- Activate the selected banner
    local banner = self:find({ id = banner_id })
    if banner then
        banner:update({ is_active = true })
        return true
    end
    return false
end

function TotmBanners:get_all_banners()
    return self:select('ORDER BY created_at DESC')
end

return TotmBanners
