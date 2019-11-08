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
local typecheck -- Load-on-demand.
local FUNCTION, TABLE, STRING -- Load-on-demand.
local throw -- Load-on-demand.
local ILLEGAL_ARGUMENT_EXCEPTION -- Load-on-demand.
local pairs = pairs
--[[ Included package identifiers. ]]--
setfenv(1, R14LosSA)

-- Enum comes before Type in the load order, return true if Type module gets loaded.
local function load_type_module()
    if typecheck == nil then
        if Type == nil then return false end -- Type module is not loaded yet.
        typecheck = Type.check
        FUNCTION, TABLE, STRING = Type.values() -- TODO: Ensure these are in the right order.
    end
    
    return true
end

-- Enum comes before Exception in the load order, return true if Exception module gets loaded.
local function load_excep_module()
    if throw == nil then
        if Exception == nil then return false end -- Exception module is not loaded yet.
        throw = Exception.throw
        ILLEGAL_ARGUMENT_EXCEPTION = Exception.values() -- TODO: Ordering
    end
    
    return true
end

-- provide enum with a function that returns all enum values
-- the enum class itself then takes those tables it returns and modifies them
-- the enum class sets up things like tostring, etc
-- TODO: Fix the tostring function to work properly with tables that hide their metatable
-- TODO: do this by checking if getmetatable returns nil

local Enum = (function()
    local class = { }
    
    --[[
    -- Creates a new Enum class.
    -- An enum is a set of constants, each having a unique ordinal value.
    --
    -- @param get_tables function Supplier callback function returning a table.
    -- The returned table must be non-empty and map[string] --> table
    -- Each table value corresponding to a string key must be unique and
    -- cannot have a metatable which implements a __metatable metamethod.
    -- Table values of the returned table will have their metatables overwritten.
    -- TODO: Finish comments.
    ]]--
    class.new = function(get_tables)
        if load_type_module() then
            typecheck(get_tables) end 
        -- Retrieve all the values of the specified enum.
        local values = { get_tables() } -- Multiple return values.
        if typecheck ~= nil then
            for k, v in pairs(values) do
                typecheck(k, STRING)
                typecheck(v, TABLE)
            end
        end
        
        local members = { }
        
    
    
        local ordinal = 1
        for k, v in pairs(values) do
            
        end
        

    end

    return setmetatable(class, READ_ONLY_METATABLE)
end)
