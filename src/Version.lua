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
local _, R14LosSA = ...
--[[ Included global identifiers. ]]--
local setmetatable, tostring, setfenv, unpack = setmetatable, tostring, setfenv, unpack
--[[ Included package identifiers. ]]--
setfenv(1, R14LosSA)
local READ_ONLY_METATABLE = READ_ONLY_METATABLE
--[[ Version Module. ]]--
local Module = { }; Version = Module;
setfenv(1, Module)

--[[
-- Semantic Versioning
--
-- Increment Z when you fix something.
-- Increment Y when you add a new feature.
-- Increment X when you break backwards-compatibility or add major features.
--]]
local X, Y, Z = 2, 0, 1

--[[
-- Version number, seperated by section.
]]--
TABLE = { X, Y, Z }

--[[
-- Version String in form X.Y.Z.
--
-- @see Semantic Versioning: https://datasift.github.io/gitflow/Versioning.html
]]--
VERSION = tostring(X) .. "." .. tostring(Y) .. "." .. tostring(Z)

--[[
-- Determines if the specified version matches the current version.
--
-- @param other_version table Version table.
-- @return boolean True if the specified version matches the current version.
-- @see Version.VERSION
]]--
function match(other_version_number)
    local x, y, z = unpack(other_version_number)
    return X == x and Y == y and Z == z end

setmetatable(Module, READ_ONLY_METATABLE) -- Module loaded.
