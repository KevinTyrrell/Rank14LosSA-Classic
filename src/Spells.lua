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

local bor = bit.bor
-- Mask to determine unit type.
local UNIT_FLAG_MASK = bor(COMBATLOG_OBJECT_TYPE_MASK, COMBATLOG_OBJECT_CONTROL_MASK,
    COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_AFFILIATION_MASK)
-- Player, Controlled by Player, Friendly, Mine.
local FLAG_F_PLAYER = bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_CONTROL_PLAYER, 
    COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_AFFILIATION_MINE)
-- Pet, Controlled by Player, Hostile, and Anonymous.
local FLAG_H_ENEMY_PET = bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_CONTROL_PLAYER,
    COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER)
-- Player, Controlled by Player, Hostile, and Anonymous.
local FLAG_H_ENEMY_PLAYER = bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_CONTROL_PLAYER,
    COMBATLOG_OBJECT_REACTION_HOSTILE, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER)
-- Player, Controlled by Player, Friendly, and Party Member.
local FLAG_F_PARTY_PLAYER = bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_CONTROL_PLAYER,
    COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_AFFILIATION_PARTY)

-- Events in which RSA must react to.
local SPELL_AURA_APPLIED = "SPELL_AURA_APPLIED"
local SPELL_CAST_START = "SPELL_CAST_START"
local SPELL_AURA_REMOVED = "SPELL_AURA_REMOVED"
local SPELL_CAST_SUCCESS = "SPELL_CAST_SUCCESS"

-- Maps in-game events to their related spells.
local spell_database = { }
-- Maps spell aliases to boolean flags: true->enabled
local spell_prefs = { }

--[[
-- Attempts to play a sound file, given the right circumstances.
--
-- @param spell_name string Name of the spell from the combat log.
-- @param event_trigger string Name of the event which triggers the sound file.
-- @param sound_name string Name of the sound file.
-- @param [source] number Unit flags of the source of the spell.
-- @param [target] number Unit flags of the target of the spell.
-- @param [sound] string Name of the sound file to be played.
-- @param [alias] string Unique identifier for the spell.
]]--
local spell_entry = (function()
    local function default_val_callback() return { } end
    
    return function(spell_name, event_trigger, source, target, sound, use_sound_name)
        sound = sound or spell_name
        --[[ What this spell appears as to the user.
        -- Spells like 'Polymorph' have the same name, but use different sound alerts.
        --   but spells like Ancestral Recall and Hearthstone use the same name. ]]--
        local alias = ternary(use_sound_name == true, sound, spell_name)
        -- By default all spells are enabled.
        spell_prefs[alias] = true
        
        -- Retrieve all spell tables that relate to this event.
        local spells_for_event = get_and_put(spell_database, event_trigger, default_val_callback)
        -- Retrieve all spell tables that also share the name and spell ID.
        local spells_for_name = get_and_put(spells_for_event, spell_name, default_val_callback)
        table.insert(spells_for_name, {
            alias = alias,
            sound = sound,
            source = source,
            target = target
        })
    end
end)()

function sound_query(event, spell_name, source, target)
    local spells_for_event = spell_database[event]
    if spells_for_event == nil then return end
    local spells_for_name = spells_for_event[spell_name]
    if spells_for_name == nil then return end
    
    for _, v in pairs(spells_for_name) do
        play_sound(v.sound)
        return
    end
end

-- TODO: Big Heal
-- TODO: Shadowmeld -> Stealth
spell_entry("Adrenaline Rush", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Aimed Shot", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Arcane Power", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Banish", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Barkskin", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Battle Stance", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Berserker Rage", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Berserker Stance", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Bestial Wrath", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Blade Flurry", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Blessing of Freedom", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Blessing of Protection", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Blessing of Protection", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER, nil, "Blessing of Protection Down")
spell_entry("Blessing of Sacrifice", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Blind", SPELL_AURA_APPLIED, nil, FLAG_F_PLAYER)
spell_entry("Blind", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER, nil, "Blind Down")
spell_entry("Blind", SPELL_AURA_APPLIED, FLAG_F_PARTY_PLAYER, FLAG_H_ENEMY_PLAYER, "Blind Enemy")
spell_entry("Blind", SPELL_AURA_APPLIED, nil, FLAG_F_PARTY_PLAYER, "Blind Friend")
spell_entry("Blood Fury", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Cannibalize", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Cold Blood", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Cold Snap", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Combustion", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Concussion Blow", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER, FLAG_F_PLAYER)
spell_entry("Counterspell", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Dash", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Death Coil", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Death Wish", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Death Wish", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER, nil, "Death Wish Down", true)
spell_entry("Defensive Stance", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Desperate Prayer", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Deterrence", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Deterrence", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER, nil, "Deterrence Down", true)
spell_entry("Disarm", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Riposte", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER, nil, "Disarm")
spell_entry("Divine Favor", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Divine Shield", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Divine Shield", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER, nil, "Divine Shield Down", true)
spell_entry("Earthbind Totem", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Elemental Mastery", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Enrage", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Entangling Roots", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Escape Artist", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Evasion", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Evasion", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER, nil, "Evasion Down", true)
spell_entry("Evocation", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Fear Ward", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Fel Domination", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("First Aid", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Freezing Trap", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Frenzied Regeneration", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Grounding Totem", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Hammer of Justice", SPELL_AURA_APPLIED, nil, FLAG_F_PLAYER)
spell_entry("Astral Recall", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Hearthstone")
spell_entry("Hearthstone", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Hibernate", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Ice Block", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Ice Block", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER, nil, "Ice Block Down", true)
spell_entry("Improved Hamstring", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER, FLAG_F_PLAYER)
spell_entry("Inner Focus", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Innervate", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Intimidation", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Invisibility", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER, nil, "Lesser Invisibility Potion", true)
spell_entry("Invisibility", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER, nil, "Invisibility Potion", true)
spell_entry("Kick", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Last Stand", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Mana Burn", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Mana Tide Totem", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Mind Control", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Nature's Grasp", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Nature's Swiftness", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER) -- TODO: Differentiate Druid/Shaman?
spell_entry("Polymorph", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, FLAG_F_PLAYER)
spell_entry("Polymorph", SPELL_AURA_REMOVED, nil, nil, "Polymorph Down", true)
spell_entry("Polymorph", SPELL_CAST_START, FLAG_F_PARTY_PLAYER, FLAG_H_ENEMY_PLAYER, "Polymorph Enemy", true)
spell_entry("Polymorph", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, FLAG_F_PARTY_PLAYER, "Polymorph Friend", true)
spell_entry("Polymorph", SPELL_AURA_APPLIED, nil, FLAG_F_PARTY_PLAYER, "Polymorph Friend2", true)
spell_entry("Power Infusion", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Preparation", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Presence of Mind", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Pummel", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Rapid Fire", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Readiness", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Recklessness", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Recklessness Down", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER)
spell_entry("Fire Reflector", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER, nil, "Reflector")
spell_entry("Frost Reflector", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER, nil, "Reflector")
spell_entry("Shadow Reflector", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER, nil, "Reflector")
spell_entry("Repentance", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Defibrillate", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Resurrection") -- Jumper Cables
spell_entry("Ancestral Spirit", SPELL_CAST_START, "Ancestral Spirit", FLAG_H_ENEMY_PLAYER, nil, "Resurrection")
spell_entry("Rebirth", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Resurrection")
spell_entry("Redemption", SPELL_CAST_START, "Redemption", FLAG_H_ENEMY_PLAYER, nil, "Resurrection")
spell_entry("Resurrection", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Retaliation", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Revive Pet", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Sap", SPELL_AURA_APPLIED, nil, FLAG_F_PLAYER)
spell_entry("Sap", SPELL_AURA_APPLIED, FLAG_F_PARTY_PLAYER, FLAG_H_ENEMY_PLAYER, "Sap Enemy", true)
spell_entry("Sap", SPELL_AURA_APPLIED, nil, FLAG_F_PARTY_PLAYER, "Sap Friend", true)
spell_entry("Scare Beast", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Scatter Shot", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Seduction", SPELL_CAST_START, FLAG_H_ENEMY_PET)
spell_entry("Shackle Undead", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Shield Bash", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Shield Wall", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Shield Wall", SPELL_AURA_REMOVED, FLAG_H_ENEMY_PLAYER, nil, "Shield Wall Down", true)
spell_entry("Silence", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Sprint", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Stealth", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Stoneform", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
--spell_entry("Concussion Blow", SPELL_AURA_APPLIED, nil, FLAG_F_PARTY_PLAYER, "Stunned Friend") -- TODO: Alias is not unique
spell_entry("Hammer of Justice", SPELL_AURA_APPLIED, nil, FLAG_F_PARTY_PLAYER, "Stunned Friend", true)
spell_entry("Summon Imp", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Summon Demon")
spell_entry("Summon Felhunter", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Summon Demon")
spell_entry("Summon Voidwalker", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Summon Demon")
spell_entry("Summon Succubus", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Summon Demon")
spell_entry("Inferno", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Summon Demon")
spell_entry("Ritual of Doom", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER, nil, "Summon Demon")
spell_entry("Sweeping Strikes", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Tranquility", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Tremor Totem", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("Vanish", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
spell_entry("War Stomp", SPELL_CAST_START, FLAG_H_ENEMY_PLAYER)
spell_entry("Will of the Forsaken", SPELL_AURA_APPLIED, FLAG_H_ENEMY_PLAYER)
spell_entry("Wyvern Sting", SPELL_CAST_SUCCESS, FLAG_H_ENEMY_PLAYER)
