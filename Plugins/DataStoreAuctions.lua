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

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

CraftBench.DSAPlugin = {}

local plugin = CraftBench.DSAPlugin
local L = CraftBench.L

plugin.options =
{
	type = 'group',
	name = "DataStoreAuctions",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.DSA.enabled
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.DSA.enabled = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
	},
}

function plugin.OnInitialize()
	--DA.DEBUG(0,"DSA:OnInitialize()")
	if not CraftBench.db.profile.plugins.DSA then
		CraftBench.db.profile.plugins.DSA = {}
		CraftBench.db.profile.plugins.DSA.enabled = true
	end
	CraftBench:AddPluginOptions(plugin.options)
	if DataStore then
		local player
		if CraftBench.unitName then
			player = CraftBench:unitName("player")
		else
			player = UnitName("player")
		end
		for characterName, character in pairs(DataStore:GetCharacters()) do
			--DA.DEBUG(0,"DSA:OnInitialize: characterName= "..tostring(characterName)..", character= "..tostring(character))
			if characterName == player then
				CraftBench.DSAPlayer = character
			end
		end
	end
end

function plugin.RecipeNamePrefix(skill, recipe)
	local prefix, itemID, itemName, itemCount
	if not recipe then return end
	if CraftBench.db.profile.plugins.DSA.enabled and DataStore then
		itemID = recipe.itemID
		if itemID and itemID ~= 0 then
			itemName = GetItemInfo(itemID)
		end
		--DA.DEBUG(0,"RecipeNamePrefix: itemID = "..tostring(itemID).." ("..tostring(itemName)..")")
--
-- Check for Enchanting. 
--
		if not CraftBench.isCraft and recipe.tradeID == 7411 and itemID == 0 then
			itemID = recipe.scrollID
			if itemID and itemID ~= 0 then
				itemName = GetItemInfo(itemID)
			end
			--DA.DEBUG(0,"RecipeNamePrefix: scrollID = "..tostring(itemID).." ("..tostring(itemName)..")")
		end
		if itemID and CraftBench.DSAPlayer then
			itemCount = DataStore:GetAuctionHouseItemCount(CraftBench.DSAPlayer, itemID)
			--DA.DEBUG(0,"RecipeNamePrefix: itemCount = "..tostring(itemCount))
			prefix = "   "
			if itemCount and itemCount > 0 then
				if itemCount < 10 then
					prefix = tostring(itemCount).."  "
				elseif itemCount < 100 then
					prefix = tostring(itemCount).." "
				else
					prefix = "## "
				end
			end
		end
	end
	--DA.DEBUG(0,"RecipeNamePrefix: prefix = "..tostring(prefix)..", length= "..tostring(string.len(prefix)))
	return prefix
end

CraftBench:RegisterRecipeNamePlugin("DSAPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function
