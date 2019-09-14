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
local insert, assert, bor, ipairs, setfenv, setmetatable = table.insert, assert, bit.bor, ipairs, setfenv, setmetatable
-- Combat log flags to determine source and target of spells.
local CL_OTPLR, CL_OCP, CL_ORF, CL_OAM, CL_OTPET, CL_ORH, CL_OAO, CL_OAP = 
    COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_REACTION_FRIENDLY,
    COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_REACTION_HOSTILE,
    COMBATLOG_OBJECT_AFFILIATION_OUTSIDER, COMBATLOG_OBJECT_AFFILIATION_PARTY
--[[ Included package identifiers. ]]--
setfenv(1, R14LosSA)
local get_or_put, ternary, READ_ONLY_METATABLE = get_or_put, ternary, READ_ONLY_METATABLE
--[[ Spells Module. ]]--
local Module = { }; Spells = Module
setfenv(1, Module)

--[[ List of all unique spell event names, sorted alphabetically. ]]--
local SPELL_EVENT_NAMES = { }; Module.SPELL_EVENT_NAMES = SPELL_EVENT_NAMES
-- (Map)[API-events] --> (Map)[Spell Names] --> { Spell Tables }
local spell_database = { }
-- (Map)[Alerts] --> { Spell Tables }
local event_spell_map = { }

--[[
-- @return boolean true if the spell alert is enabled.
]]--
function get_alert(alert)
	local spell_table = event_spell_map[alert]
	if spell_table == nil then return nil end -- Invalid alert.
	return spell_table.enabled
end

--[[
-- Changes a spell's alert setting.
-- A spell alert that is disabled will not trigger.
--
-- @param alert string Spell alert name.
-- @param enabled boolean True to disable the spell alert.
-- @return enabled, if the alert name is valid. Otherwise nil.
]]--
function set_alert(alert, enabled)
	local spell_table = event_spell_map[alert]
	if spell_table == nil then return nil end -- Invalid alert.
	spell_table.enabled = enabled
	return enabled
end

local play_sound -- LOD function.

--[[
-- Queries to see if the specified spell should be alerted.
--
-- @param event string WoW API event.
-- @param spell_name string Name of the spell from the combat log.
-- @param [source] number Source unit flags.
-- @param [target] number Target unit flags.
]]--
function query(event, spell_name, source, target)
	local spells_for_event = spell_database[event]
	if spells_for_event == nil then return end
	local spells_for_name = spells_for_event[spell_name]
	if spells_for_name == nil then return end

	for _, spell_table in ipairs(spells_for_name) do
		local src, tar = spell_table.source, spell_table.target
		-- If the targets are what the sound was intended for, play the sound file.
		if (src == nil or src == source) and (tar == nil or tar == target) and spell_table.enabled then
			play_sound = play_sound or R14LosSA.play_sound -- Load on demand.
			play_sound(spell_table.sound) return
		end
	end
end

--[[
-- Object which builds spell events. (Builder Design Pattern)
]]--
local spell_builder = (function()
    local sb = { }
    -- Optional arguments to the builder.
    local source_flags, target_flags, spell, sound
    -- Callback for get_or_put
    local function make_table_cb() return { } end

    --[[ Source unit flags of the caster. If not specified, any source is used. ]]-- 
    function sb.source(flags) source_flags = flags; return sb end
    --[[ Target unit flags of the caster. If not specified, any target is used. ]]--
    function sb.target(flags) target_flags = flags; return sb end
    --[[ Name of the spell from the combat log. If not specified, alert name is used. ]]--
    function sb.spell(name) spell = name; return sb end
    --[[ Name of the sound to be played. If not specified, alert name is used. ]]--
    function sb.sound(name) sound = name; return sb end
    
    --[[
    -- Builds the current spell event. Calling this method resets the builder.
    --
    -- @param alert string Unqiue identifier for the spell alert.
    ]]--
    function sb.build(alert, event)
        assert(event_spell_map[alert] == nil) -- Event name must be unique.
        insert(SPELL_EVENT_NAMES, alert)
    
        --[[    [1] source flags of the spell       [2] target flags of the spell
                [3] name of the sound file          [3] alert active by default     ]]--
        local spell_table = {
			source = source_flags, target = target_flags,
			sound = ternary(sound ~= nil, sound, alert), enabled = true
		}
		event_spell_map[alert] = spell_table -- Allow lookups by event name (unique).

        -- Retrieve all spell tables that relate to this event.
        local spells_for_event = get_or_put(spell_database, event, make_table_cb)
        -- Retrieve all spell tables that also share the name and spell ID.
        local spells_for_name = get_or_put(spells_for_event, ternary(spell ~= nil, spell, alert), make_table_cb)
        insert(spells_for_name, spell_table)
    
        -- Reset the builder for the next spell.
        source_flags, target_flags, spell, sound = nil, nil, nil, nil
        return sb
    end
    
    return sb
end)()

-- API Events in which sounds may be played for.
local AURA_APP = "SPELL_AURA_APPLIED"
local CAST_SRT = "SPELL_CAST_START"
local AURA_REM = "SPELL_AURA_REMOVED"
local CAST_SCS = "SPELL_CAST_SUCCESS"
-- Player, Controlled by Player, Friendly, Mine.
local FLAG_F_PLR = bor(CL_OTPLR, CL_OCP, CL_ORF, CL_OAM)
-- Pet, Controlled by Player, Hostile, and Anonymous.
local FLAG_H_PET = bor(CL_OTPET, CL_OCP, CL_ORH, CL_OAO)
-- Player, Controlled by Player, Hostile, and Anonymous.
local FLAG_H_PLR = bor(CL_OTPLR, CL_OCP, CL_ORH, CL_OAO)
-- Player, Controlled by Player, Friendly, and Party Member.
local FLAG_F_PTY = bor(CL_OTPLR, CL_OCP, CL_ORF, CL_OAP)

-- TODO: Big Heal, Shadowmeld -> Stealth, Spell Locked, Counterspelled, Kicked

spell_builder
    .source(FLAG_H_PLR).build("Adrenaline Rush", AURA_APP)
    .source(FLAG_H_PLR).build("Aimed Shot", CAST_SRT)
    .source(FLAG_H_PLR).build("Arcane Power", AURA_APP)
    .source(FLAG_H_PLR).build("Banish", CAST_SRT)
    .source(FLAG_H_PLR).build("Barkskin", AURA_APP)
    .source(FLAG_H_PLR).build("Battle Stance", AURA_APP)
    .source(FLAG_H_PLR).build("Berserker Rage", AURA_APP)
    .source(FLAG_H_PLR).build("Berserker Stance", AURA_APP)
    .source(FLAG_H_PLR).build("Bestial Wrath", CAST_SCS)
    .source(FLAG_H_PLR).build("Blade Flurry", AURA_APP)
    .source(FLAG_H_PLR).build("Blessing of Freedom", AURA_APP)
	.source(FLAG_H_PLR).build("Blessing of Protection", AURA_APP)
	.source(FLAG_H_PLR).spell("Blessing of Protection").build("Blessing of Protection Down", AURA_REM)
	.source(FLAG_H_PLR).build("Blessing of Sacrifice", AURA_APP)
	.target(FLAG_F_PLR).build("Blind", AURA_APP)
	.source(FLAG_H_PLR).spell("Blind").build("Blind Down", AURA_REM)
	.source(FLAG_F_PTY).target(FLAG_H_PLR).spell("Blind").build("Blind Enemy", AURA_APP)
	.target(FLAG_F_PTY).spell("Blind").build("Blind Friend", AURA_APP)
	.source(FLAG_H_PLR).build("Blood Fury", AURA_APP)
	.source(FLAG_H_PLR).build("Cannibalize", CAST_SCS)
	.source(FLAG_H_PLR).build("Cold Blood", AURA_APP)
	.source(FLAG_H_PLR).build("Cold Snap", CAST_SCS)
	.source(FLAG_H_PLR).build("Combustion", AURA_APP)
	.source(FLAG_H_PLR).target(FLAG_F_PLR).build("Concussion Blow", AURA_APP)
	.source(FLAG_H_PLR).build("Counterspell", CAST_SCS)
	.source(FLAG_H_PLR).build("Dash", AURA_APP)
	.source(FLAG_H_PLR).build("Death Coil", CAST_SCS)
	.source(FLAG_H_PLR).build("Death Wish", AURA_APP)
	.source(FLAG_H_PLR).spell("Death Wish").build("Death Wish Down", AURA_REM)
	.source(FLAG_H_PLR).build("Defensive Stance", AURA_APP)
	.source(FLAG_H_PLR).build("Desperate Prayer", CAST_SCS)
	.source(FLAG_H_PLR).build("Deterrence", AURA_APP)
	.source(FLAG_H_PLR).spell("Deterrence").build("Deterrence Down", AURA_REM)
	.source(FLAG_H_PLR).build("Disarm", AURA_APP)
	.source(FLAG_H_PLR).sound("Disarm").build("Riposte", AURA_APP)
	.source(FLAG_H_PLR).build("Divine Favor", AURA_APP)
	.source(FLAG_H_PLR).build("Divine Shield", AURA_APP)
	.source(FLAG_H_PLR).spell("Divine Shield").build("Divine Shield Down", AURA_REM)
	.source(FLAG_H_PLR).build("Earthbind Totem", CAST_SCS)
	.source(FLAG_H_PLR).build("Elemental Mastery", AURA_APP)
	.source(FLAG_H_PLR).build("Enrage", AURA_APP) -- TODO: Differentiate Warrior/Druid?       
	.source(FLAG_H_PLR).build("Entangling Roots", CAST_SRT)
	.source(FLAG_H_PLR).build("Escape Artist", CAST_SRT)
	.source(FLAG_H_PLR).build("Evasion", AURA_APP)
	.source(FLAG_H_PLR).spell("Evasion").build("Evasion Down", AURA_REM)
	.source(FLAG_H_PLR).build("Evocation", CAST_SCS)
	.source(FLAG_H_PLR).build("Fear Ward", AURA_APP)
	.source(FLAG_H_PLR).build("Fel Domination", AURA_APP)
	.source(FLAG_H_PLR).build("First Aid", CAST_SCS)
	.source(FLAG_H_PLR).build("Freezing Trap", CAST_SCS)
	.source(FLAG_H_PLR).build("Frenzied Regeneration", AURA_APP)
	.source(FLAG_H_PLR).build("Grounding Totem", CAST_SCS)
	.target(FLAG_F_PLR).build("Hammer of Justice", AURA_APP)
	.source(FLAG_H_PLR).sound("Hearthstone").build("Astral Recall", CAST_SRT)
	.source(FLAG_H_PLR).build("Hearthstone", CAST_SRT)
	.source(FLAG_H_PLR).build("Hibernate", CAST_SRT)
	.source(FLAG_H_PLR).build("Ice Block", AURA_APP)
	.source(FLAG_H_PLR).spell("Ice Block").build("Ice Block Down", AURA_REM)
	.target(FLAG_F_PLR).build("Improved Hamstring", AURA_APP)
	.source(FLAG_H_PLR).build("Inner Focus", AURA_APP)
	.source(FLAG_H_PLR).build("Innervate", AURA_APP)
	.source(FLAG_H_PLR).build("Intimidation", CAST_SCS)
	.source(FLAG_H_PLR).sound("Invisibility").build("Lesser Invisibility Potion", AURA_APP)
	.source(FLAG_H_PLR).sound("Invisibility").build("Invisibility Potion", AURA_APP)
	.source(FLAG_H_PLR).build("Kick", CAST_SCS)
	.source(FLAG_H_PLR).build("Last Stand", AURA_APP)
	.source(FLAG_H_PLR).build("Mana Burn", CAST_SRT)
	.source(FLAG_H_PLR).build("Mana Tide Totem", CAST_SCS)
	.source(FLAG_H_PLR).build("Mind Control", CAST_SRT)
	.source(FLAG_H_PLR).build("Nature's Grasp", AURA_APP)
	.source(FLAG_H_PLR).build("Nature's Swiftness", AURA_APP) -- TODO: Differentiate Druid/Shaman?
	.source(FLAG_H_PLR).target(FLAG_F_PLR).build("Polymorph", CAST_SRT)
	.spell("Polymorph").build("Polymorph Down", AURA_REM)
	.source(FLAG_F_PTY).target(FLAG_H_PLR).spell("Polymorph").build("Polymorph Enemy", CAST_SRT)
	.source(FLAG_H_PLR).target(FLAG_F_PTY).spell("Polymorph").build("Polymorph Friend", CAST_SRT)
	.source(FLAG_H_PLR).target(FLAG_F_PTY).spell("Polymorph").build("Polymorph Friend2", AURA_APP)
	.source(FLAG_H_PLR).build("Power Infusion", AURA_APP)
	.source(FLAG_H_PLR).build("Preparation", CAST_SCS)
	.source(FLAG_H_PLR).build("Presence of Mind", AURA_APP)
	.source(FLAG_H_PLR).build("Pummel", CAST_SCS)
	.source(FLAG_H_PLR).build("Rapid Fire", AURA_APP)
	.source(FLAG_H_PLR).build("Readiness", CAST_SCS)
	.source(FLAG_H_PLR).build("Recklessness", AURA_APP)
	.source(FLAG_H_PLR).build("Recklessness Down", AURA_REM)
	.source(FLAG_H_PLR).sound("Reflector").build("Fire Reflector", AURA_APP)
	.source(FLAG_H_PLR).sound("Reflector").build("Frost Reflector", AURA_APP)
	.source(FLAG_H_PLR).sound("Reflector").build("Shadow Reflector", AURA_APP)
	.source(FLAG_H_PLR).build("Repentance", AURA_APP)
	.source(FLAG_H_PLR).sound("Resurrection").spell("Defibrillate").build("Jumper Cables", CAST_SRT)
	.source(FLAG_H_PLR).sound("Resurrection").build("Ancestral Spirit", CAST_SRT)
	.source(FLAG_H_PLR).sound("Resurrection").build("Rebirth", CAST_SRT)
	.source(FLAG_H_PLR).sound("Resurrection").build("Redemption", CAST_SRT)
	.source(FLAG_H_PLR).build("Resurrection", CAST_SRT)
	.source(FLAG_H_PLR).build("Retaliation", AURA_APP)
	.source(FLAG_H_PLR).build("Revive Pet", CAST_SRT)
	.source(FLAG_F_PLR).build("Sap", AURA_APP)
	.source(FLAG_F_PTY).target(FLAG_H_PLR).spell("Sap").build("Sap Enemy", AURA_APP)
	.source(FLAG_H_PLR).target(FLAG_F_PTY).spell("Sap").build("Sap Friend", AURA_APP)
	.source(FLAG_H_PLR).build("Scare Beast", CAST_SRT)
	.source(FLAG_H_PLR).build("Scatter Shot", CAST_SCS)
	.source(FLAG_H_PET).build("Seduction", CAST_SRT)
	.source(FLAG_H_PLR).build("Shackle Undead", CAST_SRT)
	.source(FLAG_H_PLR).build("Shield Bash", CAST_SCS)
	.source(FLAG_H_PLR).build("Shield Wall", AURA_APP)
	.source(FLAG_H_PLR).spell("Shield Wall").build("Shield Wall Down", AURA_REM)
	.source(FLAG_H_PLR).build("Silence", AURA_APP)
	.source(FLAG_H_PLR).build("Sprint", AURA_APP)
	.source(FLAG_H_PLR).build("Stealth", CAST_SCS)
	.source(FLAG_H_PLR).build("Stoneform", AURA_APP)
	.source(FLAG_H_PLR).target(FLAG_F_PTY)
		.spell("Concussion Blow").sound("Stunned Friend").build("Concussion Blow2", AURA_APP)
	.source(FLAG_H_PLR).target(FLAG_F_PTY)
		.spell("Hammer of Justice").sound("Stunned Friend").build("Hammer of Justice2", AURA_APP)
	.source(FLAG_H_PLR).sound("Summon Demon").build("Summon Imp", CAST_SRT)
	.source(FLAG_H_PLR).sound("Summon Demon").build("Summon Felhunter", CAST_SRT)
	.source(FLAG_H_PLR).sound("Summon Demon").build("Summon Voidwalker", CAST_SRT)
	.source(FLAG_H_PLR).sound("Summon Demon").build("Summon Succubus", CAST_SRT)
	.sound(FLAG_H_PLR).sound("Summon Demon").build("Inferno", CAST_SRT)
	.sound(FLAG_H_PLR).sound("Summon Demon").build("Ritual of Doom", CAST_SRT)
	.source(FLAG_H_PLR).build("Sweeping Strikes", AURA_APP)
	.source(FLAG_H_PLR).build("Tranquility", CAST_SCS)
	.source(FLAG_H_PLR).build("Tremor Totem", CAST_SCS)
	.source(FLAG_H_PLR).build("Vanish", CAST_SCS)
	.source(FLAG_H_PLR).build("War Stomp", CAST_SRT)
	.source(FLAG_H_PLR).build("Will of the Forsaken", AURA_APP)
	.source(FLAG_H_PLR).build("Wyvern Sting", CAST_SCS)

setmetatable(Module, READ_ONLY_METATABLE) -- Module loaded.
