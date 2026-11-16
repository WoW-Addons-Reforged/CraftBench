--[[

CraftBench: A tradeskill window replacement.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]--

CraftBench.QuestiePlugin = {}

local plugin = CraftBench.QuestiePlugin
local L = CraftBench.L

plugin.options = {
	type = "group",
	name = "Questie",
	order = 2,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.Questie.enabled
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.Questie.enabled = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1,
		},
	},
}

local function GetQuestieDB()
	if _G.QuestieLoader and _G.QuestieLoader.ImportModule then
		local ok, db = pcall(_G.QuestieLoader.ImportModule, _G.QuestieLoader, "QuestieDB")
		if ok and db then return db end
	end
	return _G.QuestieDB
end

local function GetZoneNameFromNPC(npc)
	if not npc then return nil end
	local zoneID = npc.zoneID
	if not zoneID and type(npc.spawns) == "table" then
		zoneID = next(npc.spawns)
	end
	if zoneID and C_Map and C_Map.GetAreaInfo then
		local area = C_Map.GetAreaInfo(zoneID)
		if area and area ~= "" then return area end
	end
	return nil
end

local function ResolveRecipeItemID(recipe)
	if not recipe then return nil end
	if recipe.spellID and _G.AtlasLoot and _G.AtlasLoot.Data and _G.AtlasLoot.Data.Recipe and _G.AtlasLoot.Data.Recipe.GetRecipeForSpell then
		local rid = _G.AtlasLoot.Data.Recipe.GetRecipeForSpell(recipe.spellID)
		if rid and rid > 0 then return rid end
	end
	if recipe.scrollID and recipe.scrollID > 0 then
		return recipe.scrollID
	end
	if recipe.itemID and recipe.itemID > 0 then
		return recipe.itemID
	end
	return nil
end

function plugin.OnInitialize()
	if not CraftBench.db.profile.plugins.Questie then
		CraftBench.db.profile.plugins.Questie = {}
		CraftBench.db.profile.plugins.Questie.enabled = true
	end
	CraftBench:AddPluginOptions(plugin.options)
end

function plugin.GetExtraText(skill, recipe)
	if not skill or not recipe then return end
	if not CraftBench.db.profile.plugins.Questie or not CraftBench.db.profile.plugins.Questie.enabled then return end
	local QuestieDB = GetQuestieDB()
	if not QuestieDB or not QuestieDB.QueryItemSingle then return end

	local queryID = ResolveRecipeItemID(recipe)
	if not queryID then return end

	local lines = {}

	local vendors = QuestieDB.QueryItemSingle(queryID, "vendors")
	if type(vendors) == "table" and #vendors > 0 and QuestieDB.GetNPC then
		local names = {}
		for i = 1, math.min(3, #vendors) do
			local npc = QuestieDB:GetNPC(vendors[i])
			if npc and npc.name then
				local zone = GetZoneNameFromNPC(npc)
				names[#names + 1] = zone and (npc.name .. " (" .. zone .. ")") or npc.name
			end
		end
		if #names > 0 then
			lines[#lines + 1] = "|cffffd100" .. (L["Vendor"] or "Vendor") .. ":|r " .. table.concat(names, ", ")
		end
	end

	local drops = QuestieDB.QueryItemSingle(queryID, "npcDrops")
	if type(drops) == "table" and #drops > 0 and QuestieDB.GetNPC then
		local names = {}
		for i = 1, math.min(3, #drops) do
			local npc = QuestieDB:GetNPC(drops[i])
			if npc and npc.name then
				names[#names + 1] = npc.name
			end
		end
		if #names > 0 then
			lines[#lines + 1] = "|cffffd100" .. (L["Drops"] or "Drops") .. ":|r " .. table.concat(names, ", ")
		end
	end

	local quests = QuestieDB.QueryItemSingle(queryID, "relatedQuests")
	if type(quests) == "table" and #quests > 0 and QuestieDB.GetQuest then
		local qNames = {}
		for i = 1, math.min(2, #quests) do
			local q = QuestieDB.GetQuest(quests[i])
			if q and q.name then
				qNames[#qNames + 1] = q.name
			end
		end
		if #qNames > 0 then
			lines[#lines + 1] = "|cffffd100" .. (L["Quest"] or "Quest") .. ":|r " .. table.concat(qNames, ", ")
		end
	end

	if #lines == 0 then return end
	return "|rQuestie:", table.concat(lines, "\n")
end

CraftBench:RegisterDisplayDetailPlugin("QuestiePlugin")
