--[[
-- Rank14LosSA-Classic - Port of the popular vanilla addon 'Rank14LosSA'
-- (originally GladiatorlosSA) to World of Warcraft: Classic
--
--    Copyright (C) 2019 Kevin Tyrrell
--
--    This program is free software: you can redistribute itd and/or modify
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

--[[ Store access to the global table. ]]--
local _G = getfenv(0)
R14LosSA._G = _G
--[[ Include std. lib identifiers. ]]--
local tostring, error, type, pairs , match, setmetatable, getmetatable = 
    tostring, error, type, pairs, string.match, setmetatable, getmetatable
--[[ Included library identifiers. ]]--
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

--[[
-- Scope globals automatically into the AddOn namepsace.
-- Identifiers not found in the AddOn table are referred to _G.
-- Prevent access to the AddOn namespace's metatable.
]]--
setfenv(1, setmetatable(R14LosSA, { __index = _G, __metatable = true }))

--[[
-- Convinience metatable used for making tables read-only.
]]--
READ_ONLY_METATABLE= { __metatable = true,
    __newindex = function() error("Cannot modify table as it is effectively final") end }

--[[ Data types of Lua, organized into a table in an enum format. ]]--
local types = {
    NIL = "nil", BOOLEAN = "boolean", NUMBER = "number",
    STRING = "string", USERDATA = "userdata",
    FUNCTION = "function", THREAD = "thread", TABLE = "table"
}

--[[
-- All possible Lua data-types.
]]--
DATA_TYPES = types

--[[
-- Parses the specified object into a string.
-- Tables whose metatables are discovered to have a __tostring
-- metamethod are passed to the stdlib tostring function.
-- This may cause unintended side effects if a table's metatable
-- __metatable metamethod returns a table containing a __tostring
-- metamethod, but is not actually the metatable of said table.
--
-- @param obj ? Value to be parsed into a string.
-- @return string representation of the specified value.
]]--
tostring = (function()
    -- Hook into the standard tostring function.
    local tostring_hook = tostring
    local TBL = types.TABLE
    local FUN = types.FUNCTION
    local function tostring(obj)
        if type(obj) == TBL then
            local mt = getmetatable(obj)
            if type(mt) == TBL and type(mt.__tostring) == FUN then
                return tostring_hook(obj) end
            local mapping, str
            for k, v in pairs(obj) do
                mapping = "[" .. tostring(k) .. "]=" .. tostring(v)
                if str == nil then str = mapping
                else str = str .. ", " .. mapping end
            end
            return "{ " .. (str or "") .. " }"
        end
        return tostring_hook(obj)
    end
    return tostring
end)()

--[[
-- Colors escape codes for `Frame:AddMessage`.
--
-- |cAARRGGBB
-- |c <-- Color Escape
-- AA <-- Alpha Channel
-- RR <-- Red Channel
-- BB <-- Blue Channel
]]--
COLOR_RESET, COLOR_TITLE1, COLOR_TITLE2, COLOR_ENABLED, COLOR_DISABLED =
    "|r", "|cFFB157FF", "|cFFFFD857", "|cFF00CC66", "|cFFFF4019"

--[[
-- Prints a message to the user's chat frame.
-- This should be used primarily for debugging purposes.
-- TODO: Implement logging based system.
--
-- @param var Variable to be printed.
-- @see tostring
]]--
function print(var)
    DEFAULT_CHAT_FRAME:AddMessage(tostring(var)) end
_G.RSA_print = print -- Used for debugging purposes.

--[[
-- Retrieves a value corresponding to a key in the table.
-- If the key is not yet mapped, it is then mapped to the specified value.
--
-- @param tbl table Table to be accessed/modified.
-- @param key object Key to lookup/associate.
-- @param default_value function Callback to return the default value for unmapped keys.
]]--
function get_or_put(tbl, key, default_value_cb)
    local value = tbl[key]
    if value == nil then
        value = default_value_cb()
        tbl[key] = value
    end

    return value
end

--[[
-- Simulates the 'Ternary Conditional Operator' from other languages.
-- Replacement for the 'a and b or c' syntax that is error-prone.
--
-- @param condition [boolean] Condition which evaluates to true or false.
-- @param if_true ? Value to be returned if the condition is true.
-- @param if_false ? Value to be returned if the condition is false.
]]--
function ternary(condition, if_true, if_false)
    if condition == true then return if_true end
    return if_false
end

--[[
-- Trim a string of leading or following whitespace.
-- Source: http://lua-users.org/wiki/StringTrim
-- 
-- @param str string String to remove whitespace on.
-- @return Specified string with whitespace removed.
]]--
function trim(str)
    return match(str, '^%s*(.*%S)') or ''
end
