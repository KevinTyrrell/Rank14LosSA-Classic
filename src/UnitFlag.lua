--[[
-- Rank14LosSA-Classic - World of Warcraft: Classic AddOn used to
-- auditorily notify you of important spells used around you.
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
--[[ Included stdlib identifiers. ]]--
local bit, setmetatable = bit, setmetatable
local bor = bit.bor
--[[ Included WoW API identifiers. ]]--
local TYPE_MASK, TYPE_OBJECT, TYPE_GUARDIAN, TYPE_PET, TYPE_NPC, TYPE_PLAYER,
    CONTROL_MASK, CONTROL_NPC, CONTROL_PLAYER,
    REACTION_MASK, REACTION_HOSTILE, REACTION_NEUTRAL, REACTION_FRIENDLY,
    AFFILIATION_MASK, AFFILIATION_OUTSIDER, AFFILIATION_RAID, AFFILIATION_PARTY, AFFILIATION_MINE,
    SPECIAL_MASK, NONE, MAINASSIST, MAINTANK, FOCUS, TARGET = 
    COMBATLOG_OBJECT_TYPE_MASK, COMBATLOG_OBJECT_TYPE_OBJECT, COMBATLOG_OBJECT_TYPE_GUARDIAN,
        COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_NPC, COMBATLOG_OBJECT_TYPE_PLAYER,
    COMBATLOG_OBJECT_CONTROL_MASK, COMBATLOG_OBJECT_CONTROL_NPC, COMBATLOG_OBJECT_CONTROL_PLAYER,
    COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_REACTION_NEUTRAL,
        COMBATLOG_OBJECT_REACTION_FRIENDLY,
    COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER, COMBATLOG_OBJECT_AFFILIATION_RAID,
        COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_MINE,
    COMBATLOG_OBJECT_SPECIAL_MASK, COMBATLOG_OBJECT_NONE, COMBATLOG_OBJECT_MAINASSIST,
        COMBATLOG_OBJECT_MAINTANK, COMBATLOG_OBJECT_FOCUS, COMBATLOG_OBJECT_TARGET
--[[ Included package identifiers. ]]--
setfenv(1, R14LosSA)
local READ_ONLY_METATABLE = READ_ONLY_METATABLE



