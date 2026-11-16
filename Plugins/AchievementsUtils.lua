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

CraftBench.AUPlugin = {}

local plugin = CraftBench.AUPlugin
local L = CraftBench.L

local DEFAULT_ACH_ICON = "Interface\\AchievementFrame\\UI-Achievement-TinyShield"

plugin.options = {
	type = "group",
	name = "AchievementsUtils",
	order = 2,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.AU.enabled
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.AU.enabled = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1,
		},
	},
}

local function GetCraftedItemName(recipe)
	if not recipe then return nil end
	local itemID = recipe.itemID
	if not itemID or itemID <= 0 then return nil end
	if C_Item and C_Item.GetItemInfo then
		return C_Item.GetItemInfo(itemID)
	elseif GetItemInfo then
		return GetItemInfo(itemID)
	end
	return nil
end

local function CollectAchievementsForRecipe(recipe)
	local au = _G.AchievementsUtils
	if not au or not au.FindByCriteriaName or not au.GetAchievement then return nil end
	if au.IsCriteriaIndexReady and not au:IsCriteriaIndexReady() then return nil end

	local names = {}
	if recipe.name and recipe.name ~= "" then
		names[#names + 1] = recipe.name
	end
	local itemName = GetCraftedItemName(recipe)
	if itemName and itemName ~= "" and itemName ~= recipe.name then
		names[#names + 1] = itemName
	end
	if #names == 0 then return nil end

	local seen = {}
	local results = {}
	for _, searchName in ipairs(names) do
		local list = au:FindByCriteriaName(searchName)
		if list then
			for i = 1, #list, 2 do
				local achID = list[i]
				local criteriaIndex = list[i + 1]
				if achID and not seen[achID] then
					local ach = au:GetAchievement(achID)
					if ach and not ach.completed then
						local needed = true
						if GetAchievementCriteriaInfo and criteriaIndex then
							local _, _, completed = GetAchievementCriteriaInfo(achID, criteriaIndex)
							needed = not completed
						end
						seen[achID] = true
						results[#results + 1] = {
							id = achID,
							name = ach.name,
							icon = ach.icon or DEFAULT_ACH_ICON,
							needed = needed,
						}
					end
				end
			end
		end
	end

	if #results == 0 then return nil end
	table.sort(results, function(a, b)
		if a.needed ~= b.needed then return a.needed end
		return (a.name or "") < (b.name or "")
	end)
	return results
end

function plugin.OnInitialize()
	if not CraftBench.db.profile.plugins.AU then
		CraftBench.db.profile.plugins.AU = {}
		CraftBench.db.profile.plugins.AU.enabled = true
	end
	CraftBench:AddPluginOptions(plugin.options)
end

function plugin.RecipeNamePrefix(skill, recipe)
	if not skill or not recipe then return end
	if not CraftBench.db.profile.plugins.AU or not CraftBench.db.profile.plugins.AU.enabled then return end
	if not _G.AchievementsUtils then return end

	local list = CollectAchievementsForRecipe(recipe)
	if not list then return end

	local first = list[1]
	if not first then return end
	local iconText = string.format("|T%s:14:14:0:0|t ", first.icon or DEFAULT_ACH_ICON)
	local link = GetAchievementLink and GetAchievementLink(first.id) or nil
	return iconText, first.id, link
end

function plugin.GetExtraText(skill, recipe)
	if not skill or not recipe then return end
	if not CraftBench.db.profile.plugins.AU or not CraftBench.db.profile.plugins.AU.enabled then return end
	if not _G.AchievementsUtils then return end

	local list = CollectAchievementsForRecipe(recipe)
	if not list then return end

	local parts = {}
	for _, entry in ipairs(list) do
		local color = entry.needed and "|cffffd100" or "|cff66ff66"
		parts[#parts + 1] = color .. (entry.name or tostring(entry.id)) .. "|r"
	end
	return "|rAchievementsUtils:", table.concat(parts, "\n")
end

CraftBench:RegisterRecipeNamePlugin("AUPlugin")
CraftBench:RegisterDisplayDetailPlugin("AUPlugin")
