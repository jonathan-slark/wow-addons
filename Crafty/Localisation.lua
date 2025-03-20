--
--  Localisation Module
--

-- Use English, by default
Crafty_Localisation = setmetatable({}, { __index = function (L, key)
    return key
end})

-- Import
local L = Crafty_Localisation
local GetLocale = GetLocale

-- Make sure we don't polute the global environment
setfenv(1, {})

--[[
if GetLocale() == "frFR" then
    L["Disenchant"] = "Désenchanter"
end
--]]
