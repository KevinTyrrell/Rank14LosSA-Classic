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
local setmetatable, tostring, unpack = setmetatable, tostring, unpack
--[[ Included package identifiers. ]]--
setfenv(1, R14LosSA)
local typecheck, non_nil -- Load-on-demand.
local TABLE, STRING, FUNCTION -- Load-on-demand.
local throw -- Load-on-demand.
local READ_ONLY_EXCEPTION, NO_SUCH_ELEMENT_EXCEPTION, ILLEGAL_ARGUMENT_EXCEPTION -- Load-on-demand.

-- Attempts to load the type module. Returns true if the module is loaded.
local function type_lod()
    if typecheck == nil then
        if Type == nil then return false end -- Hasn't been loaded yet.
        typecheck = Type.check
        non_nil = Type.non_nil
        TABLE, STRING, FUNCTION = Type.values() -- TODO: Check return value order.
    end
    return true
end

-- Attempts to load the exception module. Returns true if the module is loaded.
local function excep_lod()
    if throw == nil then
        if Exception == nil then return false end -- Hasn't been loaded yet.
        throw = Exception.throw
        READ_ONLY_EXCEPTION, NO_SUCH_ELEMENT_EXCEPTION = Exception.values() -- TODO: Check return value order.
    end
    return true
end

-- Invoked when a class fails to look up the specified member in its class table.
local function excep_no_element(class_name, member)
    if excep_lod() then
        throw(NO_SUCH_ELEMENT_EXCEPTION, "Class: " .. class_name .. " has no such memeber: " .. tostring(member))
    end
end

-- Invoked from a __newindex metamethod.
local function ex_read_only()
    if not excep_lod() then return end
    throw(READ_ONLY_EXCEPTION, "Instance members are read-only and cannot be modified.")
end

-- Map[class table] ==> protected static members.
-- TODO: REPLACE THIS with the whole `protected()` idea.
local class_protected_map = { }



--[[
-- USE CASES:
-- 
-- Case 1: Requesting protected table of B in class A, where class A <- class B
--      Lookup protected table of B using class A's private as a key
-- Case 2: Requesting private table of B in class A, where class A <- class B
--      Lookup private table of B using class A's private as a key
-- Case 3: Requesting protected table of A in class C, where class A <- class B <- class C
--      
]]--

--[[
-- @param super_class table Public instance of the superclass.
]]--
local function init_access_modifiers(super_class)
    -- Tables in which public, private, or protected members are defined.
    local pub_mutable = setmetatable({ }, { __metatable = false })
    local prv_mutable = setmetatable({ }, { __metatable = false })
    local prt_mutable = setmetatable({ }, { __metatable = false })

    -- Three different versions of the table same. Each with different access levels.
    local public, private, protected = { }, { }, { }
    
    -- The three tables are equal as long as they have this metamethod.
    local function __eq() return true end
    -- Differ __tostring metamethod to the public table.
    local function __tostring(tbl)
        local func = public.__tostring
        if type_lod() then
            typecheck(func, FUNCTION)
            func = func(tbl)
            typecheck(non_nil(func), STRING)
        end
        return func
    end
    -- Differ __call metamethod to the public table.
    local function __call(tbl, ...)
        local func = public.__call
        if type_lod() then typecheck(func, FUNCTION) end
        return func(tbl, ...)
    end

    -- Metatables for the three different versions of the table.
    local pub_mt = { __eq = __eq, __tostring = __tostring, __call = __call, __newindex = ex_read_only, __metatable = false }
    local prv_mt = { __eq = __eq, __tostring = __tostring, __call = __call, __newindex = ex_read_only, __metatable = false }
    local prt_mt = { __eq = __eq, __tostring = __tostring, __call = __call, __newindex = ex_read_only, __metatable = false }
     
    local public = setmetatable({ }, pub_mt)
    local private = setmetatable({ }, prv_mt)
    local protected = setmetatable({ }, prt_mt)
    
    
end




local function make_class(class_name, super_class)
    if type_lod() then typecheck(class_name, STRING) end
    
    -- Class table -- entry point to all static members.
    local class = { }

    --[[
    -- Static access modifier member tables.
    -- Members defined in these tables have the respective access modifier level.
    -- These tables are provided to the caller so members can be defined.
    ]]--
    local public_static = setmetatable({ }, { __metatable = false })
    local private_static = setmetatable({ }, { __metatable = false })
    local protected_static = setmetatable({ }, { __metatable = false })
    class_protected_map[class] = protected_static -- Grant subclasses access to protected members.

    --[[
    -- Weak Set of all object instances.
    -- Each instance has three forms (public, private, protected),
    -- and thus is placed into the set three times, for each version.
    -- TODO: The default constructor will have to place all three 
    -- TODO: versions of the table here, and set the value to true.
    -- TODO: This may not be very optimal and may be similar to 'private()'.
    ]]--
    local instances = setmetatable({ }, { __mode = "k" })

    local hierarchy_str -- Cached hierarchy string.

    -- Static members that cannot be overriden through any of the access modifier tables.
    local default_static = {
        --[[
        -- Determines the specified instance is a member of the class.
        --
        -- @param instance table Object instance.
        -- @return boolean True if the instance is a member of the class.
        ]]--
        has_instance = function(instance)
            if type_lod() then typecheck(non_nil(instance), TABLE) end
            return instances[instance] ~= nil
        end,
        --[[
        -- @return string Name of the class, specified at creation.
        ]]--
        name = function() return class_name end,
        --[[
        -- Retrieves the hierarchy of the class, as a string.
        --
        -- @return string Hierarchy of the class, from the base class to the root.
        ]]--
        hierarchy = function() return hierarchy_str end
    }

    if super_class ~= nil then
        if typecheck ~= nil then typecheck(super_class, TABLE) end
        local super_prt = class_protected_map[super_class]
        if super_prt == nil then
            if excep_lod() then throw(ILLEGAL_ARGUMENT_EXCEPTION, "No such superclass exists.") end
            return nil
        end
        
        
        hierarchy_str = class_name .. "[" .. super_class.hierarchy .. "]"
    else
        hierarchy_str = class_name
        
    end
        
        
        --[[
        -- Private table:
            First checks the default table.
            Then checks the private table.
            Then checks the protected table & all protected ancestors
            Then checks the public table and all public ancestors
            Then throws an exception
        -- Protected table:
            checks the protected table & all protected ancestors
            Then checks the public table and all public ancestors
            Then throws an exception
        -- public table
            checks the public table and all public ancestors
            Then throws an exception
        ]]--


    --[[
    -- Entry points into the class, each with varying levels of access.
    -- Callers with access to only the public table cannot access the other tables.
    -- Callers with access to the private table can access any of the tables.
    ]]--
    local public_access = setmetatable({ }, { __newindex = ex_read_only, __metatable = false }) -- index should go to superclasses' public table, then exception
    local private_access = setmetatable({ }, { __newindex = ex_read_only, __metatable = false }) -- index should go to superclasses' private table, then to protected
    local protected_access = setmetatable({ }, { __newindex = ex_read_only, __metatable = false }) -- index should go to superclases' protected table, then public

    

    local function constructor()
        
    end



    return public_static, private_static, protected_static
end























-- TODO: Everything below this is abandoned.


local module = { }

--[[ Map[class_table] ==> Class Protected Member Table ]]--
local protected_tables = { }

function module.new(class_name, sub_class)
    if type_lod() then typecheck(class_name, STRING) end
    
    --[[ Class table -- Entry point into the class. ]]--
    local class = { }

    local public_mt, protected_mt = { __metatable = false }, { __metatable = false }
    if typecheck ~= nil then
        typecheck(sub_class, TABLE) end
    

    
    local public = setmetatable({ }, public_mt)
    local protected = setmetatable({ }, protected_mt)
    protected_tables[class] = protected

    








    -- TODO: All below is experimental.

    --[[
    -- Static and non-static class members.
    -- After class creation, this table is returned so class members can be added.
    -- Class members can be accessed either by accessing the returned class member
    -- table, or for instance methods, should be accessed from a class instance
    -- and in doing so be provided the instance as the first function parameter.
    ]]--
    local members = setmetatable({ }, { __metatable = false })

    -- Set of class instances, used for determining ownership of class instances.
    local instances = { }
    
    -- Class members that cannot be overriden.
    local default = setmetatable({
        --[[
        -- Constructor function.
        -- Either creates an instance or dictates a specified instance as a member of the class.
        -- 
        -- @param instance table Class instance created by the subclass' constructor.
        -- For the specific case of the root of the class heirarchy, specified instances are nil.
        -- The instance must be created directly from the classes' declared subclass.
        -- TODO: Enforce that requirement. `__index` of the metatable to ensure that the instance is of the subclass.
        -- @return instance table Class instance that was provided, or a fresh instance if nil.
        ]]--
        new = function(instance)
            if instance == nil then
                instance = setmetatable({ }, sub_instance_mt)
            elseif typecheck ~= nil then
                typecheck(instance, TABLE)
            end
            instances[instance] = true
        end,
        --[[
        -- Determines if a specified table is an instance of this class.
        --
        -- @param tbl table Table to be checked for ownership. 
        -- @return boolean True if the instance is an instance of this class.
        ]]--
        is_instance = function(tbl)
            -- TODO: Add nil-check.
            return instances[tbl] ~= nil
        end
    }, { __index = members }) -- Prioritize the default table before searching the member table.

    -- Metamethod for the static member metatable.
    local __index_static = function(tbl, key)
        local value = default[key]
        -- Accessing statically does not search through the subclass tables.
        if value == nil then excep_no_element(class_name, key) end
        return value
    end
    
    if sub_instance_mt ~= nil then
        if typecheck ~= nil then
            typecheck(sub_instance_mt, TABLE)
            -- TODO: Ensure it's actually the subclass metatable.
        end
    else
        
    end
    
    -- Static class table.
    return setmetatable({ }, { __index = __index_static, __newindex = excep_read_only, __metatable = false }),
        -- Table for defining function members.
        members,
        -- Table to be passed down to further sub-classes.
        sub_instance_mt
end

--[[
-- Intializes a new class with a specified names.
-- Classes can do the following:
--      * Create pre-made, read-only-ready objects.
--      * 
--      * Claim and determine ownership of an object.
-- TODO: Rewrite this.
-- TODO: Determine a way for us to check if the metatable was created by us.
-- TODO: Figure out a way to protect against modification of the sub_instance table.
]]--