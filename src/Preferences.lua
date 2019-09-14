--[[
-- Rank14LosSA-Classic - Port of the popular vanilla addon 'Rank14LosSA'
-- (originally GladiatorlosSA) to World of Warcraft: Classic
--
--    Copyright (C) 2019 Kevin Tyrrell
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]--

--[[ AddOn Namespace ]]--
local _, R14LosSA = ...
--[[ Included global identifiers. ]]--
local setfenv, setmetatable, ipairs, pairs = setfenv, setmetatable, ipairs, pairs
--[[ Included package identifiers. ]]--
setfenv(1, R14LosSA)
local _G, Spells, Version, READ_ONLY_METATABLE, print, ternary,
    COLOR_RESET, COLOR_TITLE1, COLOR_TITLE2, COLOR_ENABLED, COLOR_DISABLED =
    _G, Spells, Version, READ_ONLY_METATABLE, print, ternary,
    COLOR_RESET, COLOR_TITLE1, COLOR_TITLE2, COLOR_ENABLED, COLOR_DISABLED
local SPELL_EVENT_NAMES, get_alert, set_alert = Spells.SPELL_EVENT_NAMES, Spells.get_alert, Spells.set_alert
--[[ Preferences Module. ]]--
local Module = { }; Preferences = Module;
setfenv(1, Module)

-- TODO: Consider having the preference table ONLY track disabled spells.

-- Creates a new preference table where all alert preferences are enabled.
local function create_preferences()
    local t = { }
    for i, alert in ipairs(SPELL_EVENT_NAMES) do
        t[alert] = true end -- All alerts are true by default.
    return t
end

-- (Map)[Alert] --> Boolean
-- Determines if a given alert is disabled or enabled.
local alert_prefs = (function()
    local saved = _G.RSA_Preferences
    if saved ~= nil then
        local ver, alt = saved.VERSION_TABLE, saved.Alerts
        if alt ~= nil then
            if ver ~= nil and Version.match(ver) then
                -- Trust the saved data if the versions are proven to match.
                for pref, enabled in pairs(alt) do
                    -- Only notify the spell tables about disabled spells. 
                    if enabled == false then set_alert(pref, false) end end
                return alt
            else
                ver = create_preferences()
                for pref, enabled in pairs(alt) do
                    -- Disabled spells are the only ones that need to be processed. 
                    if enabled == false then
                        set_alert(pref, false)
                        ver[pref] = false
                    end
                end
            end
        -- Repurposing of 'version' identifer.
        else ver = create_preferences() end

        saved.Alerts = ver
        saved.VERSION_TABLE = Version.TABLE
        return ver
    else
        local prefs = create_preferences()
        _G.RSA_Preferences = { Alerts = prefs, VERSION_TABLE = Version.TABLE }
        return prefs
    end
end)

--[[
-- Initializes the preferences module.
-- Attempts to load saved preferences from the user's account.
-- This function should be called after the player enters the game world.
--
]]--
function init()
    alert_prefs = alert_prefs() -- This is a little silly.
    Module.init = nil -- Prevent init from being called twice.
end

--[[
-- Toggles a spell alert preference on or off.
-- TODO: Remove need for correct capitalization/punctuation.
--
-- @param alert string Name of the alert to be toggled.
-- @return boolean New preference. Nil if no such alert.
]]--
function toggle_alert(alert)
    local pref = alert_prefs[alert]
    if pref == nil then return nil end
    local inverse = not pref
    alert_prefs[alert] = inverse
    set_alert(alert, inverse)
    return inverse
end

--[[
-- Prints all alert preferences to the chat window.
]]--
print_preferences = (function()
    local title = "====== " .. COLOR_TITLE1 .. "ALERT " .. COLOR_TITLE2 .. "PREFERENCES" .. COLOR_RESET .. " ======"
    return function()
        print(title)
        for i, alert in ipairs(SPELL_EVENT_NAMES) do
            local pref = alert_prefs[alert]
            print(ternary(pref == true, COLOR_ENABLED .. "Enabled", COLOR_DISABLED .. "Disabled") 
                    .. COLOR_RESET .. ": " .. alert)
        end
    end
end)()

setmetatable(Module, READ_ONLY_METATABLE) -- Module loaded.
