local addonName,addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
--[[

CraftForge: A tradeskill window replacement.

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

CraftForge.OAPlugin = {}

local plugin = CraftForge.OAPlugin
local L = CraftForge.L

plugin.options =
{
	type = 'group',
	name = "Overachiever",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftForge.db.profile.plugins.OA.enabled
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.OA.enabled = value
				CraftForge:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.OA then
		CraftForge.db.profile.plugins.OA = {}
		CraftForge.db.profile.plugins.OA.enabled = true
	end
	CraftForge:AddPluginOptions(plugin.options)
end

function plugin.RecipeNamePrefix(skill, recipe)
	if not skill or not recipe then return end
	if Overachiever and Overachiever.GetIconForRecipe and CraftForge.db.profile.plugins.OA.enabled then
		local id, link
		local icon, list = Overachiever.GetIconForRecipe(recipe.spellID)
		--DA.DEBUG(0,"Overachiever.GetIconForRecipe("..tostring(recipe.spellID)..")= "..tostring(icon)..DA.DUMP1(list))
		if list then
			id = list[1].id
			link = GetAchievementLink(list[1].id)
		end
		if icon ~= "" then
			return icon, id, link
		end
	end
end

function plugin.GetExtraText(skill, recipe)
	if Overachiever and Overachiever.GetIconForRecipe and CraftForge.db.profile.plugins.OA.enabled then
		local label = "|rOverachiever:"
		local extra = "None"
		local icon, list = Overachiever.GetIconForRecipe(recipe.spellID)
		--DA.DEBUG(0,"Overachiever.GetIconForRecipe("..tostring(recipe.spellID)..")= "..tostring(icon)..DA.DUMP1(list))
		if list then
			for i = 1, #list, 1 do
				if i == 1 then
					extra = list[i].name
				else
					label = label .."\n"
					extra = extra .."\n"..list[i].name
				end
			end
		end
	return label, extra
	end
end

CraftForge:RegisterRecipeNamePlugin("OAPlugin") -- we have a RecipeNamePrefix or a RecipeNameSuffix function

CraftForge:RegisterDisplayDetailPlugin("OAPlugin") -- necessary for options
