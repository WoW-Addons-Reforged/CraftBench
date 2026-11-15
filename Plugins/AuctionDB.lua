local addonName,addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("CraftForge") -- for DebugAids.lua
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

	https://www.curseforge.com/wow/addons/auction-house-database
	
]]--

CraftForge.AHDBPlugin = {}

local plugin = CraftForge.AHDBPlugin
local L = CraftForge.L

plugin.options =
{
	type = 'group',
	name = "AuctionDB",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftForge.db.profile.plugins.AHDB.enabled
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.AHDB.enabled = value
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
				return CraftForge.db.profile.plugins.AHDB.useShort
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.AHDB.useShort = value
				if value then
					CraftForge.db.profile.plugins.AHDB.useShort = value
				end
			end,
			order = 2
		},
		onlyPositive = {
			type = "toggle",
			name = "onlyPositive",
			desc = CraftForge.L["Only show positive values"] or "Only show positive values",
			get = function()
				return CraftForge.db.profile.plugins.AHDB.onlyPositive
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.AHDB.onlyPositive = value
				if value then
					CraftForge.db.profile.plugins.AHDB.onlyPositive = value
				end
			end,
			order = 3
		},
		reagentPrices = {
			type = "toggle",
			name = "reagentPrices",
			desc = CraftForge.L["Show prices for reagents"] or "Show prices for reagents",
			get = function()
				return CraftForge.db.profile.plugins.AHDB.reagentPrices
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.AHDB.reagentPrices = value
				if value then
					CraftForge.db.profile.plugins.AHDB.reagentPrices = value
				end
			end,
			order = 4
		},
		buyablePrices = {
			type = "toggle",
			name = "buyablePrices",
			desc = CraftForge.L["Show AH prices for buyable reagents"] or "Show AH prices for buyable reagents",
			get = function()
				return CraftForge.db.profile.plugins.AHDB.buyablePrices
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.AHDB.buyablePrices = value
				if value then
					CraftForge.db.profile.plugins.AHDB.buyablePrices = value
				end
			end,
			order = 5
		},
		useVendorCalc = {
			type = "toggle",
			name = "useVendorCalc",
			desc = CraftForge.L["Show calculated cost from vendor sell price for buyable reagents"] or "Show calculated cost from vendor sell price for buyable reagents",
			get = function()
				return CraftForge.db.profile.plugins.AHDB.useVendorCalc
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.AHDB.useVendorCalc = value
				if value then
					CraftForge.db.profile.plugins.AHDB.useVendorCalc = value
				end
			end,
			order = 6
		},
		buyFactor = {
			type = "range",
			name = "buyFactor",
			desc = CraftForge.L["Multiply vendor sell price by this to get calculated buy price"] or "Multiply vendor sell price by this to get calculated buy price",
			min = 1, max = 10, step = 1, isPercent = false,
			get = function()
				return CraftForge.db.profile.plugins.AHDB.buyFactor
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.AHDB.buyFactor = value
				CraftForge:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 10
		},
		markup = {
			type = "range",
			name = CraftForge.L["Markup %"] or "Markup %",
			min = 0, max = 2, step = 0.01, isPercent = true,
			get = function()
				return CraftForge.db.profile.plugins.AHDB.markup
			end,
			set = function(self,value)
				CraftForge.db.profile.plugins.AHDB.markup = value
			end,
			width = "double",
			order = 11,
		},
	},
}

--
-- Until we can figure out how to get defaults into the "range" variables above
--
local buyFactorDef = 4
local markupDef = 1.05

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.AHDB then
		CraftForge.db.profile.plugins.AHDB = {}
		CraftForge.db.profile.plugins.AHDB.enabled = true
		CraftForge.db.profile.plugins.AHDB.buyFactor = buyFactorDef
		CraftForge.db.profile.plugins.AHDB.markup = markupDef
	end
	CraftForge:AddPluginOptions(plugin.options)
end

local function AHDB_Price(itemID)
	if not itemID then return 0 end
--
-- AuctionDB-v1.09.0
--
	if AuctionDB and AuctionDB.AHGetAuctionInfoByLink then
		local auctionData = {}
		local itemName, itemLink = C_Item.GetItemInfo(itemID)
		if not itemLink then 
			DA.DEBUG(0,"AHDB_Price: itemLink is nil")
			return 0
		end
		auctionData = AuctionDB:AHGetAuctionInfoByLink(itemLink)
		if not auctionData then
			DA.DEBUG(0,"AHDB_Price: auctionData is nil")
			return 0
		end
		return auctionData.minBuyout or 0
--
-- AuctionDB-v2.6.0
-- Latest {ts, min, median, qty} for the item at that auction house: last scan that saw it, else its last day.
--
	elseif AuctionDB and AuctionDB.LastPrice and AuctionDB.ViewHouse then
		local house = AuctionDB:ViewHouse()
		--DA.MARK3("AHDB_Price: id= "..tostring(itemID)..", house= "..tostring(house))
		local p = AuctionDB:LastPrice(itemID, house)
		if p then
			--DA.MARK3("    p= "..DA.DUMP(p))
			return p[2] or 0
		end
	else
		DA.DEBUG(0,"AHDB_Price: id= "..tostring(itemID).." Unknown")
	end
	return 0
end

function plugin.GetExtraText(skill, recipe)
	local label, extra_text
	if not recipe then return end
	local itemID = recipe.itemID
	local auctionData = {}
	if CraftForge.db.profile.plugins.AHDB.enabled and itemID and AuctionDB then
		local itemName, itemLink = C_Item.GetItemInfo(itemID)
		if not itemLink then 
			DA.DEBUG(0,"GetExtraText: itemLink is nil")
			return
		end
		local buyout = AHDB_Price(itemID) * recipe.numMade
		extra_text = CraftForge:FormatMoneyFull(buyout, true)
		label = "|r".."AHDB "..L["Buyout"]..":"
		if CraftForge.db.profile.plugins.AHDB.reagentPrices then
			local toConcatLabel = {}
			local toConcatExtra = {}
			local cost = 0
			for i=1, #recipe.reagentData, 1 do
				local reagent = recipe.reagentData[i]
				if not reagent then
					break
				end
				local needed = reagent.numNeeded or 0
				local id = reagent.id
				if CraftForge.isRetail or CraftForge.isForever then
					id = reagent.reagentID
				end
				local reagentName, reagentLink
				if id then
					reagentName, reagentLink = C_Item.GetItemInfo(id)
				else
					reagentName = tostring(id)
				end
				local text
				local value = AHDB_Price(id) * needed
				local buyFactor = CraftForge.db.profile.plugins.AHDB.buyFactor or buyFactorDef
				if CraftForge:VendorSellsReagent(id) then
					toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s  |cff808080(%s)|r", needed, reagentName or "Unknown", L["buyable"])
					if CraftForge.db.profile.plugins.AHDB.buyablePrices then
						if CraftForge.db.profile.plugins.AHDB.useVendorCalc then
							local sellValue = select(11, C_Item.GetItemInfo(id))
							value = ( sellValue or 0 ) * needed * buyFactor
						end
						toConcatExtra[#toConcatExtra+1] = CraftForge:FormatMoneyFull(value, true)
					else
						value = 0
						toConcatExtra[#toConcatExtra+1] = ""
					end
				else
					toConcatExtra[#toConcatExtra+1] = CraftForge:FormatMoneyFull(value, true)
					toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s", needed, reagentName or "Unknown")
				end
				cost = cost + value
			end
			if CraftForge.db.profile.plugins.AHDB.useVendorCalc then
				local markup = CraftForge.db.profile.plugins.AHDB.markup or markupDef
				label = label .. "\n\n" .. table.concat(toConcatLabel,"\n") .. "\n   " .. L["Reagents"] .." * ".. markup * 100 .."%:\n"
				extra_text =  extra_text .. "\n\n" .. table.concat(toConcatExtra,"\n") .. "\n" .. CraftForge:FormatMoneyFull(cost * markup, true) .. "\n"
			else
				label = label .. "\n\n" .. table.concat(toConcatLabel,"\n") .. "\n   " .. L["Reagents"] .. ":\n"
				extra_text =  extra_text .. "\n\n" .. table.concat(toConcatExtra,"\n") .. "\n" .. CraftForge:FormatMoneyFull(cost, true) .. "\n"
			end
		end
	end
	return label, extra_text
end

function plugin.RecipeNameSuffix(skill, recipe)
	local text
	if not recipe then return end
	local itemID = recipe.itemID
	local auctionData = {}
	if CraftForge.db.profile.plugins.AHDB.enabled and itemID and AuctionDB then
		local buyout = AHDB_Price(itemID) * recipe.numMade
		if CraftForge.db.profile.plugins.AHDB.reagentPrices then
			local cost = 0
			for i=1, #recipe.reagentData, 1 do
				local needed = recipe.reagentData[i].numNeeded or 0
				local id = recipe.reagentData[i].id
				if CraftForge.isRetail or CraftForge.isForever then
					id = recipe.reagentData[i].reagentID
				end
				local value = AHDB_Price(id) * needed
				local buyFactor = CraftForge.db.profile.plugins.AHDB.buyFactor or buyFactorDef
				if CraftForge:VendorSellsReagent(id) then
					if CraftForge.db.profile.plugins.AHDB.buyablePrices then
						if CraftForge.db.profile.plugins.AHDB.useVendorCalc then
							local sellValue = select(11, C_Item.GetItemInfo(id))
							value = ( sellValue or 0 ) * needed * buyFactor
						end
					else
						value = 0
					end
				end
				cost = cost + value
			end
			if CraftForge.db.profile.plugins.AHDB.useVendorCalc then
				local markup = CraftForge.db.profile.plugins.AHDB.markup or markupDef
				cost = cost * markup
			end
			local profit = buyout - cost
			if CraftForge.db.profile.plugins.AHDB.useShort then
				text = CraftForge:FormatMoneyShort(profit, true)
			else
				text = CraftForge:FormatMoneyFull(profit, true)
			end
			if CraftForge.db.profile.plugins.AHDB.onlyPositive and profit <= 0 then
				text = nil
			end
		end
	end
	return text
end

CraftForge:RegisterRecipeNamePlugin("AHDBPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

CraftForge:RegisterDisplayDetailPlugin("AHDBPlugin")	-- we have a GetExtraText function
