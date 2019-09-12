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

--[[
-- Scope globals automatically into the AddOn namepsace.
-- Identifiers not found in the AddOn table are referred to _G.
-- Prevent access to the AddOn namespace's metatable.
]]--
setfenv(1, setmetatable(R14LosSA, { __index = _G, __metatable = true }))

--[[
-- Creates an object with a specified name.
-- The object's name can be retrieved by being called or 'tostring'.
-- @param name string Name of the object.
-- @param obj [table] Optional. Object reference to use.
-- @param table Object reference.
]]--
function create_named_obj(name, obj)
    local tostring = function() return name end
    obj = obj or { }
    return setmetatable(obj, { __tostring = tostring, __call = tostring, __metatable = true })
end

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

--[[ Data types of Lua, organized into a table in an enum format. ]]--
DATA_TYPES = {
    NIL = "nil", BOOLEAN = "boolean", NUMBER = "number",
    STRING = "string", USERDATA = "userdata",
    FUNCTION = "function", THREAD = "thread", TABLE = "table"
}

--[[
-- Prints a message to the user's chat frame.
-- This should be used primarily for debugging purposes.
-- @param var Variable to be printed.
-- @see tostring
]]--
_G.RSA_print = function(var)
    DEFAULT_CHAT_FRAME:AddMessage(addOnName .. ": " .. tostring(var), 1.0, 0.6, 0.2, 53, 10);
end

--[[
-- @see RSA_print
]]-- 
print = RSA_print

--[[
-- Provides a greetings to players who are logging in.
-- This can be disabled by toggling the 'greetings' config setting.
]]--
function greetings()
    print(addOnName .. " by KevinTyrrell - Version " .. RSA_VERSION())
end


--[[
-- Retrieves a value corresponding to a key in the table.
-- If the key is not yet mapped, it is then mapped to the specified value.
-- @param tbl table Table to be accessed/modified.
-- @param key object Key to lookup/associate.
-- @param default_value function Callback to return the default value for unmapped keys.
]]--
function get_and_put(tbl, key, default_value_cb)
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
trim = (function()
    local match = string.match
    return function(str)
        return match(str, '^%s*(.*%S)') or ''
    end
end)()
