local addonName,addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("CraftBench") -- for DebugAids.lua
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

CraftBench.CIMIPlugin = {}

local plugin = CraftBench.CIMIPlugin
local L = CraftBench.L

plugin.options =
{
	type = 'group',
	name = "CanIMogIt",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.CIMI.enabled
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.CIMI.enabled = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	--DA.DEBUG(0,"CIMI:OnInitialize()")
	if not CraftBench.db.profile.plugins.CIMI then
		CraftBench.db.profile.plugins.CIMI = {}
		CraftBench.db.profile.plugins.CIMI.enabled = true
	end
	CraftBench:AddPluginOptions(plugin.options)
end

function plugin.RecipeNamePrefix(skill, recipe)
	--DA.DEBUG(0,"CIMI:RecipeNamePrefix("..tostring(skill)..", "..tostring(recipe)..")")
	if not skill or not recipe then return end
	if CanIMogIt and CanIMogIt.GetIconText and CraftBench.db.profile.plugins.CIMI.enabled then
		local itemLink = select(2, C_Item.GetItemInfo(recipe.itemID))
		if itemLink then
			local icon = CanIMogIt:GetIconText(itemLink)
			if icon ~= "" then
				return icon
			end
		end
	end
end

function plugin.GetExtraText(skill, recipe)
	--DA.DEBUG(0,"CIMI:GetExtraText("..tostring(skill)..", "..tostring(recipe)..")")
	if CanIMogIt and CanIMogIt.GetIconText and CraftBench.db.profile.plugins.CIMI.enabled then
		return "|rCanIMogIt:", (plugin.RecipeNamePrefix(skill, recipe) or "No")
	end
end

CraftBench:RegisterRecipeNamePlugin("CIMIPlugin") -- we have a RecipeNamePrefix or a RecipeNameSuffix function

CraftBench:RegisterDisplayDetailPlugin("CIMIPlugin") -- necessary for options
