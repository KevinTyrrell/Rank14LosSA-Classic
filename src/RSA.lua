--[[
-- Store access to the global table.
-- Scope global variables out of the global table.
-- Identifiers not found here are redirected to _G.
]]--
local _G = getfenv(0)
setfenv(1, setmetatable({ }, { __index = _G, __metatable = true }))

--[[
-- Semantic Versioning
-- Ex. https://datasift.github.io/gitflow/Versioning.html
-- Increment Z when you fix something
-- Increment Y when you add a new feature
-- Increment X when you break backwards-compatibility or add major features
--]]
RSA_VERSION = (function()
    local version = { }
    version.X, version.Y, version.Z = 2, 0, 0
    
    local tostring = (function()
        local str = tostring(version.X) .. "." .. tostring(version.Y) .. "." .. tostring(version.Z)
        return function() return str end
    end)()
    return setmetatable(version, { __tostring = tostring, __call = tostring, __metatable = true })
end)()

--[[ Data types of Lua, organized into a table in an enum format. ]]--
DATA_TYPES = {
    NIL = "nil", BOOLEAN = "boolean", NUMBER = "number",
    STRING = "string", USERDATA = "userdata",
    FUNCTION = "function", THREAD = "thread", TABLE = "table"
}

--[[
-- Parses a specified value into a string.
-- @param x Value to be parsed.
-- @return string representation of the specified value.
]]--
tostring = (function()
    local tostring, type, pairs = tostring, type, pairs
    local function t(obj)
        if type(obj) == DATA_TYPES.TABLE then
            local table_str = "{"
            local flag = false
            for k, v in pairs(obj) do
                table_str = table_str .. (flag and ", " or  " ") .. "[" .. t(k) .. "]=" .. t(v)
                flag = true
            end
            return table_str .. " }"
        end
        return tostring(obj)
    end
    return t
end)()

--[[
-- Prints a message to the user's chat frame.
-- This should be used primarily for debugging purposes.
-- @param var Variable to be printed.
-- @see tostring
]]--
_G.RSA_print = function(var)
    -- RSAMenuFrame_Toggle()
    DEFAULT_CHAT_FRAME:AddMessage("RSA: " .. tostring(var), 1.0, 0.6, 0.2, 53, 10);
end
print = RSA_print

--[[
-- Provides a greetings to players who are logging in.
-- This can be disabled by toggling the 'greetings' config setting.
]]--
local function greetings()
    print("Rank14LosSA ported by KevinTyrrell - Version " .. RSAConfig.version())
end

--[[
-- Disables sound files from being played.
]]--
function sound_disable()
    RSAMenuFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

--[[
-- Enables the playing of sound files.
]]--
function sound_enable()
    RSAMenuFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

--[[
-- Defined in RSA.xml
-- Script which is called when the addon is loaded.
]]--
function _G.RSA_OnLoad()
    RSAMenuFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    sound_enable()
end

-- Blizzard API requirement for setting up /slash commands.
function _G.SlashCmdList.RSA(msg, editBox)
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
local function play_sound(spell_name)
	PlaySoundFile("Interface\\AddOns\\Rank14losSA\\Voice\\" .. spell_name .. ".ogg", "SFX")
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

-- Keeps track of players who stealthed < a second ago.
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

--[[ List of demons in which a warlock can summon. ]]--
local WARLOCK_SUMMONS = { "Summon Voidwalker", "Summon Imp", "Summon Succubus", "Summon Felhunter", "Inferno" }

--[[
-- Defined in RSA.xml
-- Script called when an in-game event occurs.
]]--
function _G.RSA_OnEvent(event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
        -- No more need to listen to the entering world event.
		RSAMenuFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		if not RSAConfig or not RSAConfig.version or RSAConfig.version ~= version then
			-- This is written poorly but I'm too lazy to fix it.
            RSAConfig = {
				["enabled"] = true,
                ["greetings"] = true,
				["outside"] = true,
				["version"] = RSA_VERSION,
				["buffs"] = {
					["AdrenalineRush"] = true, -- untested
					["ArcanePower"] = true, -- untested
					["Barkskin"] = true, -- untested
					["BattleStance"] = true,
					["BerserkerRage"] = true, -- untested
					["BerserkerStance"] = false, -- untested
					["BestialWrath"] = true, -- untested
					["BladeFlurry"] = true, -- untested
					["BlessingofFreedom"] = true, -- untested
					["BlessingofProtection"] = true, -- untested
					["Cannibalize"] = true, -- untested
					["ColdBlood"] = true, -- untested
					["Combustion"] = true, -- untested
					["Dash"] = true,
					["DeathWish"] = true, -- untested
					["DefensiveStance"] = false,
					["DesperatePrayer"] = true, -- untested
					["Deterrence"] = true, -- untested
					["DivineFavor"] = true, -- untested
					["DivineShield"] = true, -- untested
					["EarthbindTotem"] = true, -- untested
					["ElementalMastery"] = true, -- untested
					["Evasion"] = true, -- untested
					["Evocation"] = true, -- untested
					["FearWard"] = true, -- untested
                    ["FelDomination"] = true, -- untested
					["FirstAid"] = true, -- untested
					["FrenziedRegeneration"] = true, -- untested
					["FreezingTrap"] = true, -- untested
					["GroundingTotem"] = true, -- untested
					["IceBlock"] = true, -- untested
					["InnerFocus"] = true, -- untested
					["Innervate"] = true, -- untested
					["Intimidation"] = true, -- untested
					["LastStand"] = true, -- untested
					["ManaTideTotem"] = true, -- untested
					["Nature'sGrasp"] = true, -- untested
					["Nature'sSwiftness"] = true, -- untested
					["PowerInfusion"] = true, -- untested
					["PresenceofMind"] = true, -- untested
                    ["Prowl"] = true, -- special case
					["RapidFire"] = true, -- untesteds
					["Recklessness"] = true, -- untested
					["Reflector"]= true, -- untested
					["Retaliation"] = true, -- untested
					["Sacrifice"] = true, -- untested
					["ShieldWall"] = true, -- untested
					["Sprint"] = true,
                    ["Stealth"] = true,
					["Stoneform"] = true, -- untested
					["SweepingStrikes"] = true, -- untested
					["Tranquility"] = true, -- untested
					["TremorTotem"] = true, -- untested
					["Trinket"] = true, -- untested
                    ["Vanish"] = true,
					["WilloftheForsaken"] = true,
				},
				["casts"] = {
                    ["AimedShot"] = true, -- untested
					["EntanglingRoots"] = true, -- untested
					["EscapeArtist"] = true, -- untested
					["Fear"] = true, -- untested
					["Hearthstone"] = true,
					["Hibernate"] = true, -- untested
					["HowlofTerror"] = true, -- untested
					["MindControl"] = true, -- untested
					["Polymorph"] = true, -- untested
					["RevivePet"] = true, -- untested
					["ScareBeast"] = true, -- untested
					["WarStomp"] = true,
                    ["SummonDemon"] = true, -- special case -- untested
				},
				["debuffs"] = {
					["Blind"] = true, -- untested
					["ConcussionBlow"] = true, -- untested
					["Counterspell-Silenced"] = true, -- untested
					["DeathCoil"] = true, -- untested
					["Disarm"] = true, -- untested
					["HammerofJustice"] = true, -- untested
					["IntimidatingShout"] = true, -- untested
					["PsychicScream"] = true, -- untested
					["Repetance"] = true, -- untested
					["ScatterShot"] = true, -- untested
					["Seduction"] = true, -- untested
					["Silence"] = true, -- untested
					["SpellLock"] = true, -- untested
					["WyvernSting"] = true, -- untested
				},
				["fadingBuffs"] = {
					["BlessingofProtection"] = true, -- untested
					["Deterrence"] = true, -- untested
					["DivineShield"] = true, -- untested
					["Evasion"] = true, -- untested
					["IceBlock"] = true, -- untested
					["ShieldWall"] = true, -- untested
				},
				["use"] = {
					["Kick"] = true,
                    ["ShieldBash"] = true, -- untested
                    ["Pummel"] = true, -- untested
				},
			}
		end
        greetings()
		if RSAConfig.enabled then
			if not RSAConfig.outside then
				RSAMenuFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
				RSA_UpdateState()
			else
				sound_enable()
			end
		end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, sub_event, _, _, source_name , source_flags, _, _, dest_name, dest_flags, _, _, spell_name = CombatLogGetCurrentEventInfo()
        print({ CombatLogGetCurrentEventInfo() })
        -- Ensure the combat log event came from a hostile player.
        if true or is_hostile_player(source_flags) then
            -- Non-instant cast spells such as Fear.
            if sub_event == "SPELL_CAST_START" then
                -- Casts without targets leaves 'dest_name' nil.
                if dest_name == nil or is_client_player(dest_flags) then
                    -- Warlock spell names can vary, special check.
                    if WARLOCK_SUMMONS[spell_name] then
                        play_sound("SummonDemon") return end
                    spell_name = gsub(spell_name, "%s+", "")
                    if RSAConfig.casts[spell_name] then
                        play_sound(spell_name) end
                end
            -- Buffing and debuffing abilities.
            elseif sub_event == "SPELL_AURA_APPLIED" then
                if is_client_player(dest_flags) then
                    spell_name = gsub(spell_name, "%s+", "")
                    if RSAConfig.debuffs[spell_name] then
                        play_sound(spell_name) end
                -- Enemy casted buff on himself.
                elseif source_name == dest_name then
                    --[[ Vanish automatically places the player into stealth.
                    -- This means Rank14losSA will send alerts for both vanish and stealth.
                    -- Stagger the 'Stealth' alert by one second to prevent false positives. ]]--
                    if spell_name == "Stealth" then 
                        recently_stealthed[dest_name] = true
                        wait(1, vanish_check, dest_name)
                    elseif spell_name == "Prowl" then
                        play_sound("Stealth") -- Special Case
                    else
                        spell_name = gsub(spell_name, "%s+", "")
                        if RSAConfig.buffs[spell_name] then
                            play_sound(spell_name) end
                    end
                end
            -- Instant cast spells which do not fit into the other events.
            elseif sub_event == "SPELL_CAST_SUCCESS" then
                if spell_name == "Vanish" then
                    -- Player vanished, do NOT send an alert for 'Stealth' as well.
                    recently_stealthed[source_name] = nil
                    play_sound(spell_name)
                elseif is_client_player(dest_flags) then
                    spell_name = gsub(spell_name, "%s+", "")
                    if RSAConfig.use[spell_name] then
                        play_sound(spell_name) end
                end
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        RSA_UpdateState()
    end
end

--[[ INDETERMINATE AREA BELOW ]]--

RSA_BUFF = 54
RSA_CAST = 67
RSA_DEBUFF = 83
RSA_FADING = 91
RSA_MENU_TEXT = { "Enabled", "Enabled outside of Battlegrounds", }
RSA_MENU_SETS = { "enabled", "outside", }
RSA_MENU_WHITE = {}
RSA_MENU_WHITE[1] = true
RSA_SOUND_OPTION_NOBUTTON = {}
RSA_SOUND_OPTION_NOBUTTON[RSA_BUFF] = true
RSA_SOUND_OPTION_NOBUTTON[RSA_CAST] = true
RSA_SOUND_OPTION_NOBUTTON[RSA_DEBUFF] = true
RSA_SOUND_OPTION_NOBUTTON[RSA_FADING] = true
RSA_SOUND_OPTION_WHITE = {}
RSA_SOUND_OPTION_WHITE[1] = true
RSA_SOUND_OPTION_WHITE[RSA_BUFF + 1] = true
RSA_SOUND_OPTION_WHITE[RSA_CAST + 1] = true
RSA_SOUND_OPTION_WHITE[RSA_DEBUFF + 1] = true
RSA_SOUND_OPTION_WHITE[RSA_FADING + 1] = true
RSA_SOUND_OPTION_TEXT = {
	"When an enemy recieves a buff:",
	"Adrenaline Rush",
	"Arcane Power",
	"Barkskin",
	"Battle Stance",
	"Berserker Rage",
	"Berserker Stance",
	"Bestial Wrath",
	"Blade Flurry",
	"Blessing of Freedom",
	"Blessing of Protection",
	"Cannibalize",
	"Cold Blood",
	"Combustion",
	"Dash",
	"Death Wish",
	"Defensive Stance",
	"Desperate Prayer",
	"Deterrence",
	"Divine Favor",
	"Divine Shield",
	"Earthbind Totem",
	"Elemental Mastery",
	"Evasion",
	"Evocation",
	"Fear Ward",
	"First Aid",
	"Frenzied Regeneration",
	"Freezing Trap",
	"Grounding Totem",
	"Ice Block",
	"Inner Focus",
	"Innervate",
	"Intimidation",
	"Last Stand",
	"Mana Tide Totem",
	"Nature's Grasp",
	"Nature's Swiftness",
	"Power Infusion",
	"Presence of Mind",
	"Rapid Fire",
	"Recklessness",
	"Reflector",
	"Retaliation",
	"Sacrifice",
	"Shield Wall",
	"Sprint",
	"Stone form",
	"Sweeping Strikes",
	"Tranquility",
	"Tremor Totem",
	"Trinket",
	"Will of the Forsaken",
	"",
	"When an enemy starts casting:",
	"Entangling Roots",
	"Escape Artist",
	"Fear",
	"Hearthstone",
	"Hibernate",
	"Howl of Terror",
	"Mind Control",
	"Polymorph",
	"Revive Pet",
	"Scare Beast",
	"War Stomp",
	"",
	"When a friendly player recieves a debuff:",
	"Blind",
	"Concussion Blow",
	"Counterspell - Silenced",
	"Death Coil",
	"Disarm",
	"Hammer of Justice",
	"Intimidating Shout",
	"Psychic Scream",
	"Repetance",
	"Scatter Shot",
	"Seduction",
	"Silence",
	"Spell Lock",
	"Wyvern Sting",
	"",
	"When a buff fades:",
	"Blessing of Protection",
	"Deterrence",
	"Divine Shield",
	"Evasion",
	"Ice Block",
	"Shield Wall",
	"",
	"When an enemy uses an ability:",
	"Kick",
}

local function stringToTable(str)
	str = string.sub(str, 1, string.len(str) - 1)
	local args = {}
	for word in string.gfind(str, "[^%s]+") do
		table.insert(args, word)
	end
	return args
end

function RSA_UpdateState()
	if GetRealZoneText() == "Alterac Valley" or GetRealZoneText() == "Arathi Basin" or GetRealZoneText() == "Warsong Gulch" then
		RSA_Enable()
	else
		RSA_Disable()
	end
end


function RSA_FilterFadingBuffs(msg)
	if not RSAConfig.fadingBuffs.enabled then return end
	local t = stringToTable(msg)
	local spell = t[1]
	local i = 2
	while i < table.getn(t) - 2 do
		spell = spell..t[i]
		i = i + 1
	end
	if RSAConfig.fadingBuffs[spell] then
		RSA_PlaySoundFile(spell.."down")
	end
end

function RSA_Subtable(index)
	if index < RSA_BUFF then
		return "buffs"
	elseif index < RSA_CAST then
		return "casts"
	elseif index < RSA_DEBUFF then
		return "debuffs"
	elseif index < RSA_FADING then
		return "fadingBuffs"
	else
		return "use"
	end
end

function RSA_SoundText(index)
	if RSA_SOUND_OPTION_WHITE[index] then
		return "enabled" 
	else
		return string.gsub(RSA_SOUND_OPTION_TEXT[index], " ", "")
	end
end

function RSACheckButton_OnClick()
	if this.variable then
		if this:GetChecked() then
			RSAConfig[this.variable] = true
		else
			RSAConfig[this.variable] = false
		end
		if this.index == 1 then
			RSAMenuFrame_UpdateDependencies()
			if RSAConfig.outside and this:GetChecked() then
				RSA_Enable()
			else
				RSA_Disable()
			end
		else
			if this:GetChecked() then
				RSAMenuFrame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
				RSA_Enable()
			else
				RSAMenuFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
				RSA_UpdateState()
			end
		end
	else
		if this:GetChecked() then
			RSAConfig[RSA_Subtable(this.index)][RSA_SoundText(this.index)] = true
		else
			RSAConfig[RSA_Subtable(this.index)][RSA_SoundText(this.index)] = false
		end
		if RSA_SOUND_OPTION_WHITE[this.index] then
			RSASoundOptionFrame_Update()
		end
	end
end

function RSAMenuFrame_Toggle()
	if RSAMenuFrame:IsVisible() then
		RSAMenuFrame:Hide()
	else
		RSAMenuFrame:Show()
	end
end

function RSAMenuFrame_Update()
	local button, fontString
	for i=1,2 do
		fontString = _G["RSAMenuFrameButton"..i.."Text"]
		fontString:SetText(RSA_MENU_TEXT[i])
		button = _G["RSAMenuFrameButton"..i]
		button.variable = RSA_MENU_SETS[i]
		button.index = i
		button:SetChecked(RSAConfig[button.variable])
		if RSA_MENU_WHITE[i] then
			fontString:SetTextColor(1,1,1)
		end
	end
	RSAMenuFrame_UpdateDependencies()
end

function RSAMenuFrame_UpdateDependencies()
	if RSAConfig.enabled then
		OptionsFrame_EnableCheckBox(RSAMenuFrameButton2)
	else
		OptionsFrame_DisableCheckBox(RSAMenuFrameButton2)
	end
end

function RSASoundOptionFrame_Toggle()
	if RSASoundOptionFrame:IsVisible() then
		RSASoundOptionFrame:Hide()
	else
		RSASoundOptionFrame:Show()
	end
end

function RSASoundOptionFrame_Update()
	local button, fontString
	local offset = FauxScrollFrame_GetOffset(RSASoundOptionFrameScrollFrame)
	for i=1,17 do
		index = offset + i
		fontString = _G["RSASoundOptionFrameButton"..i.."Text"]
		fontString:SetText(RSA_SOUND_OPTION_TEXT[index])
		
		button = _G["RSASoundOptionFrameButton"..i]
		button.index = index
		
		if RSA_SOUND_OPTION_NOBUTTON[index] then
			button:Hide()
		else
			button:Show()
			button:SetChecked(RSAConfig[RSA_Subtable(index)][RSA_SoundText(index)])
		end
		
		if RSA_SOUND_OPTION_WHITE[index] then
			OptionsFrame_EnableCheckBox(button)
			fontString:SetTextColor(1,1,1)
		else
			if RSAConfig[RSA_Subtable(index)]["enabled"] then
				OptionsFrame_EnableCheckBox(button)
			else
				OptionsFrame_DisableCheckBox(button)
			end
		end
	end
	
	FauxScrollFrame_Update(RSASoundOptionFrameScrollFrame, table.getn(RSA_SOUND_OPTION_TEXT), 17, 16)
end