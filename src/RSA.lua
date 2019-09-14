--[[
-- Rank14LosSA-Classic - World of Warcraft: Classic AddOn used to
---- auditorily notify you of important spells used around you.
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
local addOnName, R14LosSA = ...
--[[ Included stdlib identifiers. ]]--
local string, pairs, _tostring, setmetatable, insert =
    string, pairs, tostring, setmetatable, table.insert
local lower, gmatch = string.lower, string.gmatch
--[[ Included WoW API identifiers. ]]--
local PlaySoundFile, CreateFrame, CombatLogGetCurrentEventInfo =
    PlaySoundFile, CreateFrame, CombatLogGetCurrentEventInfo
--[[ Included package identifiers. ]]--
setfenv(1, R14LosSA)
local _G, Spells, Version, Preferences, trim, print = _G, Spells, Version, Preferences, trim, print
local COLOR_RESET, COLOR_TITLE1, COLOR_TITLE2, COLOR_ENABLED, COLOR_DISABLED =
    COLOR_RESET, COLOR_TITLE1, COLOR_TITLE2, COLOR_ENABLED, COLOR_DISABLED
local query, toggle_alert, print_preferences, VERSION =
    Spells.query, Preferences.toggle_alert, Preferences.print_preferences, Version.VERSION

--[[ Cached API Strings. ]]--
local PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD"
local ADDON_LOADED = "ADDON_LOADED"
local COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED"

--[[ Frame used to hook into events. ]]--
local frame = CreateFrame("Frame")
local RegisterEvent, UnregisterEvent = frame.RegisterEvent, frame.UnregisterEvent
--[[ Begin listening to the following events: ]]--
RegisterEvent(frame, PLAYER_ENTERING_WORLD)
RegisterEvent(frame, ADDON_LOADED)

--[[
-- Disables sound files from being played.
]]--
local function sound_disable()
    UnregisterEvent(frame, COMBAT_LOG_EVENT_UNFILTERED) end

--[[
-- Enables the playing of sound files.
]]--
local function sound_enable()
    RegisterEvent(frame, COMBAT_LOG_EVENT_UNFILTERED) end

-- Prints a splash title dictating the addon's name, version, and author.
local print_splash = (function()
    local COLOR_VERSION = "|cFF4DE1FF"
    local splash = COLOR_TITLE1 .. "R14" .. COLOR_TITLE2 .. "LosSA" .. COLOR_RESET .. 
            ": v" .. COLOR_VERSION .. VERSION .. COLOR_RESET .. " by Kevin Tyrrell"
    return function() print(splash) end
end)()

-- Map of slash commands to their callback handlers.
local CLI_handlers = {
    toggle = setmetatable({ }, { 
        __tostring = function() return 
            "Toggles a specified alert (case sensitive). e.g. /rsa toggle Nature's Swiftness" end,
        __call = (function()
            local MSG_ENABLED = " is now " .. COLOR_ENABLED .. "ENABLED" .. COLOR_RESET .. "."
            local MSG_DISABLED = " is now " .. COLOR_DISABLED .. "DISABLED" .. COLOR_RESET .. "."
            local MSG_ERR = "No such alert exists. Use command '" .. COLOR_TITLE1 ..
                    "alerts'" .. COLOR_RESET .. " to see possible alerts."
            return function(_, alert_name)
                local result = toggle_alert(alert_name)
                if result == true then
                    print(alert_name .. MSG_ENABLED)
                elseif result == false then
                    print(alert_name .. MSG_DISABLED)
                else print(MSG_ERR) end
            end
        end)(),
    }),
    alerts = setmetatable({ }, {
        __tostring = function() return "Displays all possible alert names to toggle. e.g. /r14 alerts" end,
        __call = function()
            print_preferences()
        end
    })
}

-- Blizzard API requirement for setting up /slash commands.
function _G.SlashCmdList.RSA(msg, editBox)
    -- TODO: Wrote this quick and dirty. Should be done properly with regex.
    msg = trim(msg)
    if msg == "" then
        print_splash()
        for command, callback in pairs(CLI_handlers) do
            -- Print the command along with its description
            print("/" .. command .. ": " .. _tostring(callback))
        end
    else
        local param, cmd = "", nil
        for word in gmatch(msg, "%w+") do
            if cmd == nil then
                cmd = lower(word)
            elseif param == "" then
                param = word
            else param = param .. " " .. word end
        end
    
        -- Differ handling of the command to the handler.
        local cb = CLI_handlers[cmd]
        if cb ~= nil then cb(param) 
        else print("Command '" .. cmd .. "' is not recognized.") end
    end
end

-- Blizzard API requirement for naming convention.
_G.SLASH_RSA1, _G.SLASH_RSA2, _G.SLASH_RSA3, _G.SLASH_RSA4, _G.SLASH_RSA5, _G.SLASH_RSA6, _G.SLASH_RSA7, _G.SLASH_RSA8, _G.SLASH_RSA9, _G.SLASH_RSA10
    = "/rsa", "/rank14", "/r14", "/r14lossa", "/rank14lossa", "/lossa", "/sa", "/soundalerter", "/gsa", "/gladiatorlossa"    

local PATH_SOUND = "Interface\\AddOns\\" .. addOnName .. "\\res\\Voice\\"
local PATH_EXTENSION = ".ogg"
-- TODO: Allow the user to switch between the two.
local SOUND_CHANNEL_MASTER, SOUND_CHANNEL_SFX = "Master", "SFX"

--[[
-- Attempts to play a sound from the voice folder.
-- @param spell_name Name of the spell (without spaces).
-- "Master" parameter will play sounds even while game sound is muted.
-- @see PlaySoundFile
]]--
function play_sound(spell_name)
	PlaySoundFile(PATH_SOUND .. spell_name .. PATH_EXTENSION, SOUND_CHANNEL_SFX)
end

--[[
-- Called when the addon is loaded.
]]--
local function load()
    -- No need to view this event anymore.
    frame:UnregisterEvent(PLAYER_ENTERING_WORLD)
    print_splash()
    sound_enable()
end

--[[
-- Script called when any in-game event occurs.
]]--
frame:SetScript("OnEvent", function(userdata, event, ...)
	if event == PLAYER_ENTERING_WORLD then
        load()
    elseif event == ADDON_LOADED then
        Preferences.init()
        frame:UnregisterEvent(ADDON_LOADED)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, sub_event, _, _, _, source_flags, _, _, _, target_flags,
            _, _, spell_name = CombatLogGetCurrentEventInfo()
        query(sub_event, spell_name, source_flags, target_flags)
    end
    -- TODO: Enable or disable feature while inside of Battlegrounds.
end)
