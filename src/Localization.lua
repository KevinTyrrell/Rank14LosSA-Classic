--[[
-- Rank14LosSA-Classic - World of Warcraft: Classic AddOn used to
-- auditorily notify you of important spells used around you.
--
--    Copyright (C) 2020 Sergey Krupin
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
local setfenv, setmetatable = setfenv, setmetatable
--[[ Included package identifiers. ]]--
setfenv(1, R14LosSA)
local READ_ONLY_METATABLE = READ_ONLY_METATABLE
--[[ Localization Module. ]]--
local Module = { }; Localization = Module
setfenv(1, Module)

local spell_local_names = {
	["ruRU"] = {
		["Выброс адреналина"] = "Adrenaline Rush",
		["Прицельный выстрел"] = "Aimed Shot",
		["Мощь тайной магии"] = "Arcane Power",
		["Изгнание"] = "Banish",
		["Дубовая кожа"] = "Barkskin",
		["Боевая стойка"] = "Battle Stance",
		["Ярость берсерка"] = "Berserker Rage",
		["Звериный гнев"] = "Bestial Wrath",
		["Шквал клинков"] = "Blade Flurry",
		["Благословение cвободы"] = "Blessing of Freedom",
		["Благословение защиты"] = "Blessing of Protection",
		["Благословение жертвенности"] = "Blessing of Sacrifice",
		["Ослепление"] = "Blind",
		["Кровавое неистовство"] = "Blood Fury",
		["Каннибализм"] = "Cannibalize",
		["Хладнокровие"] = "Cold Blood",
		["Холодная хватка"] = "Cold Snap",
		["Возгорание"] = "Combustion",
		["Оглушающий удар"] = "Concussion Blow",
		["Антимагия"] = "Counterspell",
		["Порыв"] = "Dash",
		["Лик смерти"] = "Death Coil",
		["Инстинкт смерти"] = "Death Wish",
		["Молитва отчаяния"] = "Desperate Prayer",
		["Сдерживание"] = "Deterrence",
		["Разоружение"] = "Disarm",
		["Божественное одобрение"] = "Divine Favor",
		["Божественный щит"] = "Divine Shield",
		["Тотем оков земли"] = "Earthbind Totem",
		["Покорение стихий"] = "Elemental Mastery",
		["Исступление"] = "Enrage",
		["Гнев деревьев"] = "Entangling Roots",
		["Мастер побега"] = "Escape Artist",
		["Ускользание"] = "Evasion",
		["Прилив сил"] = "Evocation",
		["Господство Скверны"] = "Fel Domination",
		["Первая помощь"] = "First Aid",
		["Замораживающая ловушка"] = "Freezing Trap",
		["Неистовое восстановление"] = "Frenzied Regeneration",
		["Тотем заземления"] = "Grounding Totem",
		["Молот правосудия"] = "Hammer of Justice",
		["Камень возвращения"] = "Hearthstone",
		["Спячка"] = "Hibernate",
		["Ледяная глыба"] = "Ice Block",
		["Улучшенное подрезание сухожилий"] = "Improved Hamstring",
		["Внутреннее сосредоточение"] = "Inner Focus",
		["Озарение"] = "Innervate",
		["Устрашение"] = "Intimidation",
		["Зелье простой невидимости"] = "Lesser Invisibility Potion",
		["Зелье невидимости"] = "Invisibility Potion",
		["Пинок"] = "Kick",
		["Ни шагу назад"] = "Last Stand",
		["Сожжение маны"] = "Mana Burn",
		["Тотем прилива маны"] = "Mana Tide Totem",
		["Контроль над разумом"] = "Mind Control",
		["Природный захват"] = "Nature's Grasp",
		["Природная стремительность"] = "Nature's Swiftness",
		["Превращение"] = "Polymorph",
		["Придание сил"] = "Power Infusion",
		["Подготовка"] = "Preparation",
		["Присутствие разума"] = "Presence of Mind",
		["Зуботычина"] = "Pummel",
		["Быстрая стрельба"] = "Rapid Fire",
		["Готовность"] = "Readiness",
		["Безрассудство"] = "Recklessness",
		["Отражатель пламени"] = "Fire Reflector",
		["Зеркало Льда"] = "Frost Reflector",
		["Отражатель тьмы"] = "Shadow Reflector",
		["Покаяние"] = "Repentance",
		["Дефибриллировать"] = "Defibrillate",
		["Дух предков"] = "Ancestral Spirit",
		["Возрождение"] = "Rebirth",
		["Искупление"] = "Redemption",
		["Воскрешение"] = "Resurrection",
		["Возмездие"] = "Retaliation",
		["Воскрешение питомца"] = "Revive Pet",
		["Ошеломление"] = "Sap",
		["Отпугивание зверя"] = "Scare Beast",
		["Дезориентирующий выстрел"] = "Scatter Shot",
		["Соблазнение"] = "Seduction",
		["Сковывание нежити"] = "Shackle Undead",
		["Удар щитом"] = "Shield Bash",
		["Глухая оборона"] = "Shield Wall",
		["Молчание"] = "Silence",
		["Спринт"] = "Sprint",
		["Незаметность"] = "Stealth",
		["Крадущийся зверь"] = "Prowl",
		["Каменная форма"] = "Stoneform",
		["Призыв беса"] = "Summon Imp",
		["Призыв охотника Скверны"] = "Summon Felhunter",
		["Призыв демона Бездны"] = "Summon Voidwalker",
		["Призыв суккуба"] = "Summon Succubus",
		["Инфернал"] = "Inferno",
		["Ритуал Рока"] = "Ritual of Doom",
		["Размашистые удары"] = "Sweeping Strikes",
		["Спокойствие"] = "Tranquility",
		["Тотем трепета"] = "Tremor Totem",
		["Исчезновение"] = "Vanish",
		["Громовая поступь"] = "War Stomp",
		["Воля Отрекшихся"] = "Will of the Forsaken",
		["Жало виверны"] = "Wyvern Sting"
	},
	["frFR"] = {},
	["deDE"] = {},
	["enGB"] = {},
	["enUS"] = {},
	["itIT"] = {},
	["koKR"] = {},
	["zhCN"] = {},
	["zhTW"] = {},
	["esES"] = {},
	["esMX"] = {},
	["ptBR"] = {}
	
}
Module.spell_local_names = spell_local_names

setmetatable(Module, READ_ONLY_METATABLE) -- Module loaded.
