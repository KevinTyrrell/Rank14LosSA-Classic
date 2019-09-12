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
--[[ Cached variables. ]]--
local setmetatable, tostring = setmetatable, tostring
--[[ Version Module. ]]--
local Version = { }
setfenv(1, Version)

--[[
-- Semantic Versioning
--
-- Increment Z when you fix something.
-- Increment Y when you add a new feature.
-- Increment X when you break backwards-compatibility or add major features.
-- @see https://datasift.github.io/gitflow/Versioning.html
--]]
local X, Y, Z = 2, 0, 0
local str = tostring(X) .. "." .. tostring(Y) .. "." .. tostring(Z)

--[[
-- Version String in form x.y.z
]]--
VERSION = str

--[[
-- Determines if the specified version matches the current version.
--
-- @param other_version table Version table.
-- @return boolean True if the specified version matches the current version.
-- @see Version.VERSION
]]--
function match(other_version)
    return VERSION.X == other_version.X and VERSION.Y == other_version.Y and VERSION.Z == other_version.Z end

local function tostring() return str end

R14LosSA.Version = setmetatable(Version, { __tostring = tostring, __call = tostring, 
    __newindex = function() error("Cannot modify read-only table.") end })
