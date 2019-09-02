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

--[[
-- Store access to the global table.
-- Scope global variables out of the global table.
-- Identifiers not found here are redirected to _G.
]]--
local _G = getfenv(0)






setfenv(1, setmetatable({ }, { __index = _G, __metatable = true }))

