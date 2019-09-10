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
local addOnName, R14LosSA = ...
setfenv(1, R14LosSA)

--[[ Cached strings, placing them into a table would defeat the purpose. ]]--
local PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD"
local COMBAT_LOG_EVENT_UNFILTERED = "COMBAT_LOG_EVENT_UNFILTERED"

--[[ Frame used to hook into events. ]]--
local frame = CreateFrame("Frame")
--[[ Begin listening to the following events: ]]--
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

--[[
-- Disables sound files from being played.
]]--
function sound_disable()
    frame:UnregisterEvent(COMBAT_LOG_EVENT_UNFILTERED)
end

--[[
-- Enables the playing of sound files.
]]--
function sound_enable()
    frame:RegisterEvent(COMBAT_LOG_EVENT_UNFILTERED)
end

-- Blizzard API requirement for setting up /slash commands.
function _G.SlashCmdList.RSA(msg, editBox)
    msg = trim(msg)
    DEFAULT_CHAT_FRAME:AddMessage("RSA: To be completed.", 1.0, 0.6, 0.2, 53, 10);
end

-- Blizzard API requirement for naming convention.
_G.SLASH_RSA1, _G.SLASH_RSA2, _G.SLASH_RSA3, _G.SLASH_RSA4, _G.SLASH_RSA5, _G.SLASH_RSA6, _G.SLASH_RSA7, _G.SLASH_RSA8, _G.SLASH_RSA9, _G.SLASH_RSA10
    = "/rsa", "/rank14", "/r14", "/r14lossa", "/rank14lossa", "/lossa", "/sa", "/soundalerter", "/gsa", "/gladiatorlossa"

--[[
-- @return true if the flag represents a hostile player.
-- @see CombatLogGetCurrentEventInfo
]]--
local is_hostile_player = (function()
    local band = bit.band
    return function(flag)
        return band(flag, COMBATLOG_OBJECT_TYPE_MASK) == COMBATLOG_OBJECT_TYPE_PLAYER
          and band(flag, COMBATLOG_OBJECT_REACTION_MASK) == COMBATLOG_OBJECT_REACTION_HOSTILE
    end
end)()

--[[
-- @return true if the flag represents the client player.
-- @see CombatLogGetCurrentEventInfo
]]--
local is_client_player = (function()
    local band = bit.band
    return function(flag)
        return band(flag, COMBATLOG_OBJECT_AFFILIATION_MASK) == COMBATLOG_OBJECT_AFFILIATION_MINE
    end
end)()

--[[
-- Attempts to play a sound from the voice folder.
-- @param spell_name Name of the spell (without spaces).
-- "Master" parameter will play sounds even while game sound is muted.
-- @see PlaySoundFile
]]--
function play_sound(spell_name)
	PlaySoundFile("Interface\\AddOns\\" .. addOnName .. "\\res\\Voice\\" .. spell_name .. ".ogg", "SFX")
end

--[[
-- Determines if an aura exists on a specified unit.
-- @return true if the specified aura exists on the unit.
]]--
local function aura_exists(unit, aura_name)
    for i = 1, 16 do -- Classic will have 16 buff slots.
        name = UnitAura(unit, i)
        if name == nil then return false end
        if name == aura_name then return true end
    end
    return false
end

-- Keeps track of players who recently went into stealth.
local recently_stealthed = { }
--[[
-- Callback function.
-- Used to protect vanishing players from wrongly reporting 'stealth'.
]]--
local function vanish_check(player_name)
    print("Checking vanish.")
    if recently_stealthed[player_name] then
        recently_stealthed[player_name] = nil
        play_sound("Stealth")
    end
end

--[[
-- Waits a specified amount of time, then calls a callback function.
-- @param delay Amount of time to wait in seconds (ex. 0.5 for half-second)
-- @param func Callback function to be called after the delay.
-- @param ... Arguments to be passed to the callback function.
-- Source: https://wowwiki.fandom.com/wiki/USERAPI_wait
]]--
local wait = (function()
    local waitTable = {};
    local waitFrame = nil;
    
    return function(delay, func, ...)
        if(type(delay)~="number" or type(func)~="function") then
            return false; end
        if(waitFrame == nil) then
            waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
            waitFrame:SetScript("onUpdate", function(self,elapse)
                local count = #waitTable;
                local i = 1;
                while(i<=count) do
                    local waitRecord = tremove(waitTable,i);
                    local d = tremove(waitRecord,1);
                    local f = tremove(waitRecord,1);
                    local p = tremove(waitRecord,1);
                    if(d>elapse) then
                        tinsert(waitTable,i,{d-elapse,f,p});
                        i = i + 1;
                    else
                        count = count - 1;
                        f(unpack(p));
                    end
                end
            end);
        end
    
        tinsert(waitTable,{delay,func,{...}});
        return true;
    end
end)()

--[[ List of demon summoning spells in which a warlock can cast. ]]--
local WARLOCK_SUMMONS = { "Summon Voidwalker", "Summon Imp", "Summon Succubus", "Summon Felhunter", "Inferno" }

--[[
-- @return true if the client player is in a battleground.
-- @see GetRealZoneText
]]--
local is_in_battleground = (function()
	local bgs = { "Alterac Valley", "Arathi Basin", "Warsong Gulch" }
	return function()
		return bgs[GetRealZoneText()] ~= nil
	end
end)()

--[[
-- Called when the addon is loaded.
]]--
local function load()
    -- No need to view this event anymore.
    frame:UnregisterEvent(PLAYER_ENTERING_WORLD)
    greetings()
    sound_enable()
end

--[[
-- Script called when an in-game event occurs.
]]--
frame:SetScript("OnEvent", function(userdata, event, ...)
	if event == PLAYER_ENTERING_WORLD then
        load()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, sub_event, _, _, _, source_flags, _, _, _, target_flags, _, _, spell_name = CombatLogGetCurrentEventInfo()
        sound_query(sub_event, spell_name, source_flags, target_flags)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
		print("A")
    end
end)
