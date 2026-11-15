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

--[[
	o={}
	OEMarketInfo(item,o)

The item can be identified by anything C_Item.GetItemInfo takes (itemid, itemstring, itemlink) or a battlepet itemstring/itemlink.
Prices are returned in copper, but accurate to the last *silver* (with coppers always 0).

	o['input']			-> the item/battlepet parameter you just passed in, verbatim
	o['itemid']			-> the ID of the item you just passed in
	o['bonuses']		-> if present, a colon-separated list of bonus IDs that were considered as uniquely identifying the item for pricing
	o['species']		-> the species of the battlepet you just passed in
	o['breed']			-> the numeric breed ID of the battlepet
	o['quality']		-> the numeric quality/rarity of the battlepet
	o['age']			-> number of seconds since data was compiled
	o['globalMedian']	-> median market price across all realms in this region
	o['globalMean']		-> mean market price across all realms in this region
	o['globalStdDev']	-> standard deviation of the market price across all realms in this region
	o['market']			-> average market price of the item on this AH over the past 14 days.
	o['stddev']			-> standard deviation of market price of the item on this AH over the past 14 days.
	o['recent']			-> average market price of the item on this AH over the past 3 days.
	o['days']			-> number of days since item was last seen on the auction house, when data was compiled. valid values 0 - 250.
		o['days'] = 251 means item was seen on this AH, but over 250 days ago
		o['days'] = 252 means the item is sold by vendors in unlimited quantities
		o['days'] = 255 means item was never seen on this AH (since 6.0 patch)

	OETooltip()		-> returns a boolean whether OE tooltips are enabled
	OETooltip(true)	-> enables OE tooltips
	OETooltip(false)	-> disables OE tooltips

	https://www.curseforge.com/wow/addons/oribos-exchange
	https://undermine.exchange/
]]--

CraftForge.OEPlugin = {}

local plugin = CraftForge.OEPlugin
local L = CraftForge.L

plugin.options =
{
	type = 'group',
	name = "OribosExchange",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftForge.db.profile.plugins.OE.enabled
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.OE.enabled = value
				CraftForge:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
		useShort = {
			type = "toggle",
			name = "useShort",
			desc = CraftForge.L["Use Short money format"] or "Use Short money format",
			get = function()
				return CraftForge.db.profile.plugins.OE.useShort
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.OE.useShort = value
				if value then
					CraftForge.db.profile.plugins.OE.useShort = value
				end
			end,
			order = 2
		},
		onlyPositive = {
			type = "toggle",
			name = "onlyPositive",
			desc = CraftForge.L["Only show positive values"] or "Only show positive values",
			get = function()
				return CraftForge.db.profile.plugins.OE.onlyPositive
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.OE.onlyPositive = value
				if value then
					CraftForge.db.profile.plugins.OE.onlyPositive = value
				end
			end,
			order = 3
		},
		colorCode = {
			type = "toggle",
			name = "colorCode",
			desc = CraftForge.L["Add color to the results"] or "Add color to the results",
			get = function()
				return CraftForge.db.profile.plugins.OE.colorCode
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.OE.colorCode = value
				if value then
					CraftForge.db.profile.plugins.OE.colorCode = value
				end
			end,
			order = 4
		},
	},
}

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.OE then
		CraftForge.db.profile.plugins.OE = {}
		CraftForge.db.profile.plugins.OE.enabled = true
	end
	CraftForge:AddPluginOptions(plugin.options)
end

local function OEMarketValue(itemID)
	local o = {}
	OEMarketInfo(itemID,o)
	DA.MARK3("OEMarketValue: itemID= "..tostring(itemID)..", o= "..DA.DUMP(o))
	return o['market']
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	local bop
	if not skill or not recipe then return end
	local itemID = recipe.itemID
	if OEMarketInfo and CraftForge.db.profile.plugins.OE.enabled and itemID then
		local value = OEMarketValue(itemID)
		if value then
			extra_text = CraftForge:FormatMoneyFull(value, true);
			label = "|r"..L["OEMarket"]..":"
		end
	end
	return label, extra_text
end

--
-- Returns a text representation of value, numerical value (for sorting purposes)
--
function plugin.RecipeNameSuffix(skill, recipe)
	local text, value
	if recipe then
		local itemID = recipe.itemID
		if OEMarketInfo and CraftForge.db.profile.plugins.OE.enabled and itemID then
			value = OEMarketValue(itemID)
			if value then
				value = value * (recipe.numMade or 1)
				local matsum = 0
				if recipe.reagentData then
					for _, v in pairs(recipe.reagentData) do
						local rid = (CraftForge.isRetail or CraftForge.isForever) and v.reagentID or v.id
						local iprice = rid and OEMarketValue(rid)
						if iprice then
							matsum = matsum + (v.numNeeded or 0) * iprice
						end
					end
				end
				value = value - matsum
				if CraftForge.db.profile.plugins.OE.useShort then
					text = CraftForge:FormatMoneyShort(value, true, CraftForge.db.profile.plugins.OE.colorCode)
				else
					text = CraftForge:FormatMoneyFull(value, true, CraftForge.db.profile.plugins.OE.colorCode)
				end
				if CraftForge.db.profile.plugins.OE.onlyPositive and value <= 0 then
					text = nil
				end
			end
		end
		recipe.suffix = value
	end
	return text, value
end

CraftForge:RegisterRecipeNamePlugin("OEPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

CraftForge:RegisterDisplayDetailPlugin("OEPlugin")	-- we have a GetExtraText function
