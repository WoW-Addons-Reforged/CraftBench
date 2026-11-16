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

CraftBench.ARLPlugin = {}

local plugin = CraftBench.ARLPlugin
local L = CraftBench.L
local ARLProfessionInitialized = {}

plugin.options =
{
	type = 'group',
	name = "AckisRecipeList",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.ARL.enabled
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ARL.enabled = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	if not CraftBench.db.profile.plugins.ARL then
		CraftBench.db.profile.plugins.ARL = {}
		CraftBench.db.profile.plugins.ARL.enabled = true
	end
	CraftBench:AddPluginOptions(plugin.options)
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	local bop
	if AckisRecipeList and AckisRecipeList.InitRecipeData and CraftBench.db.profile.plugins.ARL.enabled then
		local _, recipeList, mobList, trainerList = AckisRecipeList:InitRecipeData()
		local recipeData = AckisRecipeList:GetRecipeData(skill.id)
		if recipeData == nil and not ARLProfessionInitialized[recipe.tradeID] then
			ARLProfessionInitialized[recipe.tradeID] = true
			local profession = C_Spell.GetSpellName(recipe.tradeID)
			AckisRecipeList:AddRecipeData(profession)
			recipeData = AckisRecipeList:GetRecipeData(skill.id)
		end
		if recipeData then
			extra_text = AckisRecipeList:GetRecipeLocations(skill.id)
			if extra_text == "" then extra_text = nil end
		end
		label = "|r" .. L["Source"] .. ":"
	end
	return label, extra_text
end

CraftBench:RegisterDisplayDetailPlugin("ARLPlugin")
