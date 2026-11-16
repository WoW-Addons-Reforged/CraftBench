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

CraftBench.AtlasLootPlugin = {}

local plugin = CraftBench.AtlasLootPlugin
local L = CraftBench.L

plugin.options = {
	type = "group",
	name = "AtlasLoot",
	order = 2,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.AtlasLoot.enabled
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.AtlasLoot.enabled = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1,
		},
	},
}

function plugin.OnInitialize()
	if not CraftBench.db.profile.plugins.AtlasLoot then
		CraftBench.db.profile.plugins.AtlasLoot = {}
		CraftBench.db.profile.plugins.AtlasLoot.enabled = true
	end
	CraftBench:AddPluginOptions(plugin.options)
end

function plugin.GetExtraText(skill, recipe)
	if not skill or not recipe then return end
	if not CraftBench.db.profile.plugins.AtlasLoot or not CraftBench.db.profile.plugins.AtlasLoot.enabled then return end
	local al = _G.AtlasLoot
	if not al or not al.Data then return end

	local lines = {}
	local recipeItemID
	if recipe.spellID and al.Data.Recipe and al.Data.Recipe.GetRecipeForSpell then
		recipeItemID = al.Data.Recipe.GetRecipeForSpell(recipe.spellID)
		if recipeItemID and recipeItemID > 0 then
			local itemName = (C_Item and C_Item.GetItemInfo or GetItemInfo)(recipeItemID)
			if itemName then
				lines[#lines + 1] = "|cffffd100" .. (L["Recipe"] or "Recipe") .. ":|r " .. itemName
			end
		end
	end

	local targetID = recipeItemID or recipe.itemID
	if targetID and al.Data.VendorPrice and al.Data.VendorPrice.GetVendorPriceForItem then
		local price = al.Data.VendorPrice.GetVendorPriceForItem(targetID)
		if price then
			lines[#lines + 1] = "|cffffd100" .. (L["Vendor"] or "Vendor") .. ":|r " .. tostring(price)
		end
	end

	if #lines == 0 then return end
	return "|rAtlasLoot:", table.concat(lines, "\n")
end

CraftBench:RegisterDisplayDetailPlugin("AtlasLootPlugin")
