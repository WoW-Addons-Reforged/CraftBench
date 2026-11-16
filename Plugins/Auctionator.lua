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

--
-- Includes changes from GuardsmanBogo
-- Includes changes from Dranni21312
--

CraftBench.ATRPlugin = {}

local plugin = CraftBench.ATRPlugin
local L = CraftBench.L

plugin.options =
{
	type = 'group',
	name = "Auctionator",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.ATR.enabled
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.enabled = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1
		},
		useShort = {
			type = "toggle",
			name = "useShort",
			desc = CraftBench.L["Use Short money format"] or "Use Short money format",
			get = function()
				return CraftBench.db.profile.plugins.ATR.useShort
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.useShort = value
			end,
			order = 2
		},
		onlyPositive = {
			type = "toggle",
			name = "onlyPositive",
			desc = CraftBench.L["Only show positive values"] or "Only show positive values",
			get = function()
				return CraftBench.db.profile.plugins.ATR.onlyPositive
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.onlyPositive = value
			end,
			order = 3
		},
		reagentPrices = {
			type = "toggle",
			name = "reagentPrices",
			desc = CraftBench.L["Show prices for reagents"] or "Show prices for reagents",
			get = function()
				return CraftBench.db.profile.plugins.ATR.reagentPrices
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.reagentPrices = value
			end,
			order = 4
		},
		buyablePrices = {
			type = "toggle",
			name = "buyablePrices",
			desc = CraftBench.L["Show vendor prices for buyable reagents"] or "Show vendor prices for buyable reagents",
			get = function()
				return CraftBench.db.profile.plugins.ATR.buyablePrices
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.buyablePrices = value
			end,
			order = 5
		},
		useVendorCalc = {
			type = "toggle",
			name = "useVendorCalc",
			desc = CraftBench.L["Show calculated cost from vendor sell price for buyable reagents"] or "Show calculated cost from vendor sell price for buyable reagents",
			get = function()
				return CraftBench.db.profile.plugins.ATR.useVendorCalc
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.useVendorCalc = value
			end,
			order = 6
		},
		useSearchExact = {
			type = "toggle",
			name = "useSearchExact",
			desc = CraftBench.L["Use MultiSearchExact instead of MultSearch in Auction House shopping list"] or "Use MultiSearchExact instead of MultSearch in Auction House shopping list",
			get = function()
				return CraftBench.db.profile.plugins.ATR.useSearchExact
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.useSearchExact = value
			end,
			order = 7
		},
		extraBuyout = {
			type = "toggle",
			name = "extraBuyout",
			desc = CraftBench.L["Show buyout value"] or "Show buyout value",
			get = function()
				return CraftBench.db.profile.plugins.ATR.extraBuyout
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.extraBuyout = value
			end,
			order = 8
		},
		extraProfitValue = {
			type = "toggle",
			name = "extraProfitValue",
			desc = CraftBench.L["Show profit value"] or "Show profit value",
			get = function()
				return CraftBench.db.profile.plugins.ATR.extraProfitValue
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.extraProfitValue = value
			end,
			order = 9
		},
		extraProfitPercentage = {
			type = "toggle",
			name = "extraProfitPercentage",
			desc = CraftBench.L["Show profit as percentage"] or "Show profit as percentage",
			get = function()
				return CraftBench.db.profile.plugins.ATR.extraProfitPercentage
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.extraProfitPercentage = value
			end,
			order = 10
		},
		suffix = {
			type = "select",
			name = "Suffix",
			desc = CraftBench.L["Primary suffix text"] or "Primary suffix text",
			get = function() 
				return CraftBench.db.profile.plugins.ATR.suffix
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.ATR.suffix = value
				CraftBench.db.profile.plugins.ATR.suffixBuyout = (value == 1)
				CraftBench.db.profile.plugins.ATR.suffixCost = (value == 2)
				CraftBench.db.profile.plugins.ATR.suffixProfitValue = (value == 3)
				CraftBench.db.profile.plugins.ATR.suffixProfitPercentage = (value == 4)
			end,
			values = {
			[1] = L["Buyout"], 
			[2] = L["Cost"],
			[3] = L["Profit"],
			[4] = L["Percent"],
			},
			width = 0.5,
			style = "radio", -- "dropdown"
			order = 11
		},
		colorCode = {
			type = "toggle",
			name = "colorCode",
			desc = CraftBench.L["Add color to the results"] or "Add color to the results",
			get = function()
				return CraftBench.db.profile.plugins.ATR.colorCode
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.colorCode = value
			end,
--			width = "full",
			order = 20
		},
		calcProfitAhTax = {
			type = "toggle",
			name = "calcProfitAhTax",
			desc = CraftBench.L["Calc profit after AH Tax(5%)"] or "Calc profit after AH Tax(5%)",
			get = function()
				return CraftBench.db.profile.plugins.ATR.calcProfitAhTax
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.calcProfitAhTax = value
			end,
			order = 22
		},
		journalatorE = {
			type = "toggle",
			name = CraftBench.L["Journalator Extra"] or "Journalator Extra",
			desc = CraftBench.L["Show Journalator statistics"] or "Show Journalator statistics",
			hidden = function()
				return not Journalator
			end,
			get = function()
				return CraftBench.db.profile.plugins.ATR.journalatorE
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.journalatorE = value
			end,
			order = 23
		},
		journalatorC = {
			type = "toggle",
			name = CraftBench.L["Journalator Count"] or "Journalator Count",
			desc = CraftBench.L["Show Journalator success count suffix"] or "Show Journalator success count suffix",
			hidden = function()
				return not Journalator
			end,
			get = function()
				return CraftBench.db.profile.plugins.ATR.journalatorC
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.journalatorC = value
			end,
			order = 24
		},
		journalatorS = {
			type = "toggle",
			name = CraftBench.L["Journalator Sales Rate"] or "Journalator Sales Rate",
			desc = CraftBench.L["Show Journalator sales rate suffix"] or "Show Journalator sales rate suffix",
			hidden = function()
				return not Journalator
			end,
			get = function()
				return CraftBench.db.profile.plugins.ATR.journalatorS
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.journalatorS = value
			end,
			order = 25
		},
		qualityBuyout = {
			hidden = not CraftBench.isRetail,
			type = "toggle",
			name = "qualityBuyout",
			desc = CraftBench.L["Show all quality buyout values"] or "Show all quality buyout values",
			get = function()
				return CraftBench.db.profile.plugins.ATR.qualityBuyout
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.qualityBuyout = value
			end,
			order = 26
		},
		minmaxBuyout = {
			hidden = not CraftBench.isRetail,
			type = "toggle",
			name = "minmaxBuyout",
			desc = CraftBench.L["Show minimum and maximum buyout values"] or "Show minimum and maximum buyout values",
			get = function()
				return CraftBench.db.profile.plugins.ATR.minmaxBuyout
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.minmaxBuyout = value
			end,
			order = 27
		},
		customPrice = {
			type = "toggle",
			name = "customPrice",
			desc = CraftBench.L["Substitute customPrice table values for Auctionator price values"] or "Substitute customPrice table values for Auctionator price values",
			get = function()
				return CraftBench.db.profile.plugins.ATR.customPrice
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.customPrice = value
			end,
			order = 28
		},
		buyFactor = {
			type = "range",
			name = "buyFactor",
			desc = CraftBench.L["Multiply vendor sell price by this to get calculated buy price"] or "Multiply vendor sell price by this to get calculated buy price",
			min = 1, max = 10, step = .1, isPercent = false,
			get = function()
				return CraftBench.db.profile.plugins.ATR.buyFactor
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.buyFactor = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 30
		},
		markup = {
			type = "range",
			name = CraftBench.L["Markup %"] or "Markup %",
			min = 0, max = 2, step = 0.01, isPercent = true,
			get = function()
				return CraftBench.db.profile.plugins.ATR.markup
			end,
			set = function(self,value)
				CraftBench.db.profile.plugins.ATR.markup = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 31,
		},
	},
}

--
-- Until we can figure out how to get defaults into the "range" variables above
--
local buyFactorDef = 4
local markupDef = 1.05
local ahtaxDef = 0.95
local toConcatLabel = {}
local toConcatExtra = {}

local function NOSORT(tradeskill,a,b)
	return (a.skillIndex or 0) < (b.skillIndex or 0)
end

local function GetATRSort()
	local sortmethod = CraftBench:GetTradeSkillOption("sortmethod")
	--DA.DEBUG(0,"GetATRSort= "..tostring(sortmethod))
	return sortmethod
end

local function IsATRSort()
	local sortmethod = CraftBench:GetTradeSkillOption("sortmethod")
	local found = string.find(sortmethod,"ATR:")
	--DA.DEBUG(0,"IsATRSort= "..tostring(found))
	return found
end

local function IsJNLSort()
	local sortmethod = CraftBench:GetTradeSkillOption("sortmethod")
	local found = string.find(sortmethod,"JNL:") 
	--DA.DEBUG(0,"IsJNLSort= "..tostring(found))
	return found
end

local function SetATRsuffix(recipe)
	--DA.DEBUG(0,"SetATRsuffix: recipe= "..DA.DUMP1(recipe,1))
	if CraftBench.db.profile.plugins.ATR.suffixBuyout then
		--DA.DEBUG(0,"SetATRsuffix: buyout= "..tostring(recipe.buyout))
		return recipe.buyout
	elseif CraftBench.db.profile.plugins.ATR.suffixCost then
		--DA.DEBUG(0,"SetATRsuffix: cost= "..tostring(recipe.cost))
		return recipe.cost
	elseif CraftBench.db.profile.plugins.ATR.suffixProfitValue then
		--DA.DEBUG(0,"SetATRsuffix: profit= "..tostring(recipe.profit))
		return recipe.profit
	elseif CraftBench.db.profile.plugins.ATR.suffixProfitPercentage then
		--DA.DEBUG(0,"SetATRsuffix: percentage= "..tostring(recipe.percentage))
		return recipe.percentage
	end
end


local function GetMinMaxBuyout(recipe)
	local minBuyout = 999999999999
	local maxBuyout = 0
	local buyout, outputItemInfo, hasQ
	local itemID = recipe.itemID
	if recipe.supportsQualities and Auctionator and Auctionator.API.v1.GetAuctionPriceByItemLink and Auctionator.API.v1.GetAuctionPriceByItemID then
		for _, quality in pairs(recipe.qualityIDs) do
			outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipe.spellID, {}, nil, quality)
			if outputItemInfo and outputItemInfo.hyperlink then
				buyout = (Auctionator.API.v1.GetAuctionPriceByItemLink(addonName, outputItemInfo.hyperlink) or 0) * recipe.numMade
				hasQ = true
			else
				buyout = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0) * recipe.numMade
			end
			minBuyout = min(buyout,minBuyout)
			maxBuyout = max(buyout,maxBuyout)
		end
	elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
		minBuyout = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0) * recipe.numMade
		maxBuyout = minBuyout
	else
		return 0,0
	end
	return minBuyout, maxBuyout, hasQ
end

local function GetBuyout(recipe)
	local buyout, minBuyout, maxBuyout, outputItemInfo, sellout
	local itemID
	if recipe.scrollID then
		itemID = recipe.scrollID
	else
		itemID = recipe.itemID
	end
	sellout = ( select(11,C_Item.GetItemInfo(itemID)) or 0 )
	if CraftBench.isRetail and CraftBench.db.profile.plugins.ATR.minmaxBuyout then
		minBuyout, maxBuyout = GetMinMaxBuyout(recipe)
		if CraftBench.db.profile.best_quality then
			buyout = maxBuyout
		else
			buyout = minBuyout
		end
	else
		if Atr_GetAuctionBuyout then
			buyout = (Atr_GetAuctionBuyout(itemID) or 0) * recipe.numMade
		elseif Auctionator and Auctionator.API.v1 then
			if CraftBench.isRetail then
				if CraftBench.db.profile.best_quality then
					outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipe.spellID, {}, nil, 8)
				else
					outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipe.spellID, {}, nil, 4)
				end
			end
			if outputItemInfo and outputItemInfo.hyperlink then
				buyout = (Auctionator.API.v1.GetAuctionPriceByItemLink(addonName, outputItemInfo.hyperlink) or 0) * recipe.numMade
			else
				buyout = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID) or 0) * recipe.numMade
			end
		else
			return 0, sellout or 0
		end
	end
	return buyout or 0, sellout or 0
end

local function GetReagentData(reagent)
	--DA.DEBUG(0,"GetReagentData: reagent= "..DA.DUMP1(reagent))
	local value = 0
	local needed = 0
	local custom = ""
	local id, name
	if reagent then
		needed = reagent.numNeeded or 0
		if CraftBench.isRetail or CraftBench.isForever then
			id = reagent.reagentID
		else
			id = reagent.id
		end
		if not id then
			return 0,0,0,0,0
		end
		name = C_Item.GetItemInfo(id) or id
		if Atr_GetAuctionBuyout then
			value = (Atr_GetAuctionBuyout(id) or 0)
		elseif Auctionator and Auctionator.API.v1.GetAuctionPriceByItemID then
			value = (Auctionator.API.v1.GetAuctionPriceByItemID(addonName, id) or 0)
		else
			value = 0
		end
		if CraftBench:VendorSellsReagent(id) then
			if CraftBench.db.profile.plugins.ATR.buyablePrices then
				if CraftBench.db.profile.plugins.ATR.useVendorCalc then
					local buyFactor = CraftBench.db.profile.plugins.ATR.buyFactor or buyFactorDef
					value = ( select(11,C_Item.GetItemInfo(id)) or 0 ) * buyFactor
				end
			else
				value = 0
			end
		end
		if CraftBench.db.profile.plugins.ATR.customPrice then
			local server = CraftBench.data.server or 0
			local customPrice = CraftBench.db.global.customPrice[server]
			if customPrice and customPrice[id] then
				--DA.DEBUG(0,"GetReagentData: id= "..tostring(id)..", "..DA.DUMP1(customPrice[id]))
				if customPrice[id].name and customPrice[id].name ~= name then
					--DA.DEBUG(0,"GetReagentData: name mismatch: "..tostring(name)..", "..tostring(customPrice[id].name))
					customPrice[id].name = name
				end
				if customPrice[id].value and customPrice[id].value < value then
					--DA.DEBUG(0,"GetReagentData: substitute: "..tostring(customPrice[id].value).." for: "..tostring(value))
					value = customPrice[id].value
					custom = " |cffff8040*|r"
				end
			end
		end
		value = value * needed
	end
	return value, needed, id, name, custom
end

local function AddExtraText(value, needed, id, name, custom)
	--DA.DEBUG(0,"AddExtraText("..tostring(value)..", "..tostring(needed)..", "..tostring(id)..", "..tostring(name)..", "..tostring(custom)..")")
	if not CraftBench:VendorSellsReagent(id) then
--
-- Not sold by a vendor so use the default
--
		toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s%s", needed, name, custom)
		toConcatExtra[#toConcatExtra+1] = CraftBench:FormatMoneyFull(value, true)
	else
		toConcatLabel[#toConcatLabel+1] = string.format("   %d x %s  |cff808080(%s)|r", needed, name, L["buyable"])
		if CraftBench.db.profile.plugins.ATR.buyablePrices then
--
-- If this reagent is sold by a vendor, then use that (calculated) price instead
--
			local buyFactor = CraftBench.db.profile.plugins.ATR.buyFactor or buyFactorDef
			value = ( select(11,C_Item.GetItemInfo(id)) or 0 ) * needed * buyFactor
			toConcatExtra[#toConcatExtra+1] = CraftBench:FormatMoneyFull(value, true)
		else
--
-- If this reagent is sold by a vendor, don't use the Auctionator price
--
			value = 0
			toConcatExtra[#toConcatExtra+1] = ""
		end
	end
	return value
end

local function GetRecipeData(recipe)
	--DA.DEBUG(0,"GetRecipeData: recipe= "..DA.DUMP(recipe,1))
	if not recipe then return end
	local buyout, cost, profit, percentage, sellout, vprofit, vpercentage
	local itemID
	if recipe.scrollID then
		itemID = recipe.scrollID
	else
		itemID = recipe.itemID
	end
	if CraftBench.db.profile.plugins.ATR.enabled and itemID then
		buyout, sellout = GetBuyout(recipe)
		cost = 0
		for i=1,#recipe.reagentData do
			local value = GetReagentData(recipe.reagentData[i])
			cost = cost + value
		end
		if recipe.modifiedData then
			--DA.DEBUG(0,"GetRecipeData: modifiedData= "..DA.DUMP(recipe.modifiedData))
			for i=1,#recipe.modifiedData do
				local value = GetReagentData(recipe.modifiedData[i])
				cost = cost + value
			end
		end
		if CraftBench.db.profile.plugins.ATR.useVendorCalc then
			local markup = CraftBench.db.profile.plugins.ATR.markup or markupDef
			cost = cost * markup
		end
		local ah_tax = CraftBench.db.profile.plugins.ATR.calcProfitAhTax and ahtaxDef or 1
		profit = buyout * ah_tax - cost
		vprofit = sellout - cost
		if cost ~= 0 then
			percentage = profit * 100 / cost
			vpercentage = vprofit * 100 / cost
		end
		--DA.DEBUG(0,"GetRecipeData: buyout= "..tostring(buyout)..", profit= "..tostring(profit)..", percentage= "..tostring(percentage))
		--DA.DEBUG(0,"GetRecipeData: sellout= "..tostring(sellout)..", vprofit= "..tostring(vprofit)..", vpercentage= "..tostring(vpercentage))
		recipe.cost = cost or 0
		recipe.buyout = buyout or 0
		recipe.profit = profit or 0
		recipe.percentage = percentage or 0
		recipe.sellout = sellout or 0
		recipe.vprofit = vprofit or 0
		recipe.vpercentage = vpercentage or 0
		recipe.suffix = SetATRsuffix(recipe)
	end
end

--
-- Sort by Auctionator Buyout price
--
function plugin.SortByBuyout(skill,a,b)
	--DA.DEBUG(0,"SortByBuyout: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, buyoutA, buyoutB
	recipeA = CraftBench:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByBuyout: recipeA= "..DA.DUMP1(recipeA))
	recipeB = CraftBench:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByBuyout: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.buyout then
		GetRecipeData(recipeA)
	end
	buyoutA = recipeA.buyout or 0
	if not recipeB.buyout then
		GetRecipeData(recipeB)
	end
	buyoutB = recipeB.buyout or 0
	--DA.DEBUG(0,"SortByBuyout: buyoutA= "..tostring(buyoutA)..", buyoutB= "..tostring(buyoutB))
	return (buyoutA > buyoutB)
end

--
-- Sort by Auctionator Sell to Vendor price
--
function plugin.SortBySellout(skill,a,b)
	--DA.DEBUG(0,"SortBySellout: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, selloutA, selloutB
	recipeA = CraftBench:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortBySellout: recipeA= "..DA.DUMP1(recipeA))
	recipeB = CraftBench:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortBySellout: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.sellout then
		GetRecipeData(recipeA)
	end
	selloutA = recipeA.sellout or 0
	if not recipeB.sellout then
		GetRecipeData(recipeB)
	end
	selloutB = recipeB.sellout or 0
	--DA.DEBUG(0,"SortBySellout: selloutA= "..tostring(selloutA)..", selloutB= "..tostring(selloutB))
	return (selloutA > selloutB)
end

--
-- Sort by Auctionator Cost
--
function plugin.SortByCost(skill,a,b)
	--DA.DEBUG(0,"SortByCost: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, costA, costB
	recipeA = CraftBench:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByCost: recipeA= "..DA.DUMP1(recipeA))
	recipeB = CraftBench:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByCost: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.cost then
		GetRecipeData(recipeA)
	end
	costA = recipeA.cost or 0
	if not recipeB.cost then
		GetRecipeData(recipeB)
	end
	costB = recipeB.cost or 0
	--DA.DEBUG(0,"SortByCost: costA= "..tostring(costA)..", costB= "..tostring(costB))
	return (costA > costB)
end

--
-- Sort by calculated profit value
--
function plugin.SortByProfit(skill,a,b)
	--DA.DEBUG(0,"SortByProfit: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, profitA, profitB
	recipeA = CraftBench:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByProfit: recipeA= "..DA.DUMP1(recipeA))
	recipeB = CraftBench:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByProfit: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.profit then
		GetRecipeData(recipeA)
	end
	profitA = recipeA.profit or 0
	if not recipeB.profit then
		GetRecipeData(recipeB)
	end
	profitB = recipeB.profit or 0
	--DA.DEBUG(0,"SortByProfit: profitA= "..tostring(profitA)..", profitB= "..tostring(profitB))
	return (profitA > profitB)
end

--
-- Sort by sell to vendor profit value
--
function plugin.SortByVProfit(skill,a,b)
	--DA.DEBUG(0,"SortByVProfit: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, vprofitA, vprofitB
	recipeA = CraftBench:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortByProfit: recipeA= "..DA.DUMP1(recipeA))
	recipeB = CraftBench:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortByProfit: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.vprofit then
		GetRecipeData(recipeA)
	end
	vprofitA = recipeA.vprofit or 0
	if not recipeB.vprofit then
		GetRecipeData(recipeB)
	end
	vprofitB = recipeB.vprofit or 0
	--DA.DEBUG(0,"SortByProfit: vprofitA= "..tostring(vprofitA)..", vprofitB= "..tostring(vprofitB))
	return (vprofitA > vprofitB)
end

--
-- Sort by calculated profit percentage
--
function plugin.SortByPercent(skill,a,b)
	--DA.DEBUG(0,"SortByPercent: skill= "..tostring(skill)..", a="..tostring(a)..", b="..tostring(b))
	if a and b then
		--DA.DEBUG(1,"SortByPercent: a= "..DA.DUMP1(a,1))
		--DA.DEBUG(1,"SortByPercent: b= "..DA.DUMP1(b,1))
		if a.subGroup or b.subGroup then
--			return NOSORT(skill, a, b)
			return false
		end
	else
		return false
	end
	local recipeA, recipeB, idA, idB, percentA, percentB
	recipeA = CraftBench:GetRecipe(a.recipeID)
	--DA.DEBUG(1,"SortByPercent: recipeA= "..DA.DUMP1(recipeA))
	recipeB = CraftBench:GetRecipe(b.recipeID)
	--DA.DEBUG(1,"SortByPercent: recipeB= "..DA.DUMP1(recipeB))
	if not recipeA.percentage then
		GetRecipeData(recipeA)
	end
	percentA = recipeA.percentage or 0
	if not recipeB.percentage then
		GetRecipeData(recipeB)
	end
	percentB = recipeB.percentage or 0
	--DA.DEBUG(1,"SortByPercent: percentA= "..tostring(percentA)..", percentB= "..tostring(percentB))
	return (percentA > percentB)
end

--
-- Sort by the Journalator API function GetRealmSuccessCountByItemName
--
-- For enchanting, use the scrollID instead of the itemID
--
function plugin.SortMostSold(skill,a,b)
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return
	end
	local recipeA, recipeB, itemNameA, itemNameB, successCountA, successCountB
	recipeA = CraftBench:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortMostSold: recipeA= "..DA.DUMP1(recipeA))
	recipeB = CraftBench:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortMostSold: recipeB= "..DA.DUMP1(recipeB))
	if recipeA.scrollID then
		itemNameA = C_Item.GetItemInfo(recipeA.scrollID)
	elseif recipeA.itemID then
		itemNameA = C_Item.GetItemInfo(recipeA.itemID)
	end
	if recipeB.scrollID then
		itemNameB = C_Item.GetItemInfo(recipeB.scrollID)
	elseif recipeB.itemID then
		itemNameB = C_Item.GetItemInfo(recipeB.itemID)
	end
	--DA.DEBUG(0,"SortMostSold: itemNameA= "..tostring(itemNameA)..", itemNameB= "..tostring(itemNameB))
	successCountA = 0
	successCountB = 0
	if Journalator and Journalator.API and itemNameA and itemNameB then
		successCountA = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameA)
		successCountB = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameB)
	end
	if successCountA > 0 and successCountB > 0 then
		--DA.DEBUG(0,"SortMostSold: successCountA= "..tostring(successCountA)..", successCountB= "..tostring(successCountB))
	end
	return (successCountA > successCountB)
end

--
-- Sort by the Sales Rate using the Journalator API functions
--   GetRealmSuccessCountByItemName and GetRealmFailureCountByItemName
--
-- For enchanting, use the scrollID instead of the itemID
--
function plugin.SortSalesRate(skill,a,b)
	if a and b then
		if a.subGroup or b.subGroup then
			return NOSORT(skill, a, b)
		end
	else
		return
	end
	local recipeA, recipeB, itemNameA, itemNameB, successCountA, successCountB
	local failedCountA, failedCountB, salesRateA, salesRateB
	recipeA = CraftBench:GetRecipe(a.recipeID)
	--DA.DEBUG(0,"SortSalesRate: recipeA= "..DA.DUMP1(recipeA))
	recipeB = CraftBench:GetRecipe(b.recipeID)
	--DA.DEBUG(0,"SortSalesRate: recipeB= "..DA.DUMP1(recipeB))
	if recipeA.scrollID then
		itemNameA = C_Item.GetItemInfo(recipeA.scrollID)
	elseif recipeA.itemID then
		itemNameA = C_Item.GetItemInfo(recipeA.itemID)
	end
	if recipeB.scrollID then
		itemNameB = C_Item.GetItemInfo(recipeB.scrollID)
	elseif recipeB.itemID then
		itemNameB = C_Item.GetItemInfo(recipeB.itemID)
	end
	--DA.DEBUG(0,"SortSalesRate: itemNameA= "..tostring(itemNameA)..", itemNameB= "..tostring(itemNameB))
	salesRateA = 0
	salesRateB = 0
	if Journalator and Journalator.API and itemNameA and itemNameB then
		successCountA = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameA) or 0
		failedCountA = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemNameA) or 0
		successCountB = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemNameB) or 0
		failedCountB = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemNameB) or 0
		if successCountA > 0 then
			salesRateA = successCountA / (successCountA + failedCountA) * 100
		end
		if successCountB > 0 then
			salesRateB = successCountB / (successCountB + failedCountB) * 100
		end
	end
	if salesRateA > 0 and salesRateB > 0 then
		--DA.DEBUG(0,"SortSalesRate: salesRateA= "..tostring(salesRateA)..", salesRateB= "..tostring(salesRateB))
	end
	return (salesRateA > salesRateB)
end

function plugin.OnInitialize()
	--DA.DEBUG(0,"ATR:OnInitialize()")
	if not CraftBench.db.profile.plugins.ATR then
		CraftBench.db.profile.plugins.ATR = {}
		CraftBench.db.profile.plugins.ATR.enabled = true
		CraftBench.db.profile.plugins.ATR.buyFactor = buyFactorDef
		CraftBench.db.profile.plugins.ATR.markup = markupDef
	end
	if CraftBench.db.profile.plugins.ATR.showProfitValue == nil then
		CraftBench.db.profile.plugins.ATR.showProfitValue = true
	end
	CraftBench:AddPluginOptions(plugin.options)
	CraftBench:AddRecipeSorter("ATR: "..L["Buyout"], plugin.SortByBuyout)
	CraftBench:AddRecipeSorter("ATR: "..L["Cost"], plugin.SortByCost)
	CraftBench:AddRecipeSorter("ATR: "..L["Profit"], plugin.SortByProfit)
	CraftBench:AddRecipeSorter("ATR: "..L["Percent"], plugin.SortByPercent)
	CraftBench:AddRecipeSorter("ATR: "..L["Sellout"], plugin.SortBySellout)
	CraftBench:AddRecipeSorter("ATR: "..L["VProfit"], plugin.SortByVProfit)
	if Journalator and Journalator.API then
		CraftBench:AddRecipeSorter("JNL: "..L["Most Sold"], plugin.SortMostSold)
		CraftBench:AddRecipeSorter("JNL: "..L["Sales Rate"], plugin.SortSalesRate)
	end
end

local function profitPctText(profit,cost,limit)
	local profitPct, proPctTxt
	if cost and cost ~= 0 then
		profitPct = profit * 100 / cost
		if profitPct > limit then
			proPctTxt = ">"..tostring(limit)
		else
			proPctTxt = string.format("%.0d", profitPct)
			if proPctTxt == "" then
				proPctTxt = "0"
			end
		end
	else
		profitPct = 0.0
		proPctTxt = "0"
	end
	--DA.DEBUG(0,"profitPctText: profit= "..tostring(profit)..", cost= "..tostring(cost)..", limit= "..tostring(limit)..", proPctTxt= "..tostring(proPctTxt))
	return proPctTxt,profitPct
end

function plugin.GetExtraText(skill, recipe)
	local label = ""
	local extra_text = ""
	if not recipe then return end
	if not Auctionator then return end
	local itemID = recipe.itemID
--
-- Check for Enchanting. 
--   In Classic Era, Most recipes don't produce an item but we still should get reagent prices.
--   In Wrath, Enchants can be applied to vellum to produce scrolls so use the scroll price instead.
--
	if CraftBench.isCraft then
		--DA.DEBUG(0,"GetExtraText: itemID= "..tostring(itemID)..", type= "..type(itemID))
		--DA.DEBUG(0,"GetExtraText: recipe.name= "..tostring(recipe.name)..", recipe.spellID= "..tostring(recipe.spellID)..", recipe.scrollID= "..tostring(recipe.scrollID))
		if itemID then
			itemID = CraftBench.EnchantSpellToItem[itemID] or 0
			--DA.DEBUG(0,"GetExtraText: Change via EnchantSpellToItem, itemID= "..tostring(itemID))
		end
	elseif recipe.tradeID == 7411 and itemID == 0 then
		itemID = recipe.scrollID
		--DA.DEBUG(0,"GetExtraText: Change to scrollID, itemID= "..tostring(itemID))
	end
	if CraftBench.db.profile.plugins.ATR.enabled and itemID then
--
-- buyout is Auctionator's price (for one) times the number this recipe makes
--
		local buyout, minBuyout, maxBuyout, hasQ
		buyout = GetBuyout(recipe)
		if buyout and CraftBench.db.profile.plugins.ATR.extraBuyout then
			if CraftBench.db.profile.plugins.ATR.minmaxBuyout and recipe.supportsQualities then
				minBuyout, maxBuyout, hasQ = GetMinMaxBuyout(recipe)
			end
			if hasQ then
				label = "|r".."ATR "..L["Buyout"].." (min):"
				extra_text = CraftBench:FormatMoneyFull(minBuyout, true)
				label = label.."\n".."ATR "..L["Buyout"].." (max):"
				extra_text = extra_text.."\n"..CraftBench:FormatMoneyFull(maxBuyout, true)
			else
				label = "|r".."ATR "..L["Buyout"]..":"
				extra_text = CraftBench:FormatMoneyFull(buyout, true)
			end
			if CraftBench.db.profile.plugins.ATR.qualityBuyout and recipe.supportsQualities then
				label = label.."\n"
				extra_text = extra_text.."\n"
--
-- The hyperlink label can be taller than normal text so 
-- add a transparent icon of the same size to the extra_text
--
				local h = 18
				local price, age, buyout, outputItemInfo
				for _, quality in pairs(recipe.qualityIDs) do
					outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipe.spellID, {}, nil, quality)
					if outputItemInfo and outputItemInfo.hyperlink then
						age = Auctionator.API.v1.GetAuctionAgeByItemLink(addonName, outputItemInfo.hyperlink)
						if age and age < 2 then
							price = Auctionator.API.v1.GetAuctionPriceByItemLink(addonName, outputItemInfo.hyperlink)
							buyout = (price or 0) * recipe.numMade
							--DA.DEBUG(0,"GetExtraText: quality= "..tostring(quality)..", buyout= "..tostring(buyout)..", outputItemInfo= "..DA.DUMP1(outputItemInfo))
							local effectiveILvl, isPreview, baseILvl = C_Item.GetDetailedItemLevelInfo(outputItemInfo.hyperlink)
							--DA.DEBUG(0,"GetExtraText: effectiveILvl= "..tostring(effectiveILvl)..", itemType= "..tostring(recipe.itemType)..", classID= "..tostring(recipe.classID))
							if recipe.classID == 0 or recipe.classID == 7 then
								label = label.."\n"..outputItemInfo.hyperlink
								extra_text = extra_text.."\n".."|T982414:"..tostring(h)..":1|t"..CraftBench:FormatMoneyFull(buyout, true)
							else
--								label = label.."\n"..recipe.name.." ("..tostring(effectiveILvl)..")".." <"..tostring(age)..">"
								label = label.."\n"..recipe.name.." ("..tostring(effectiveILvl)..")"
								extra_text = extra_text.."\n"..CraftBench:FormatMoneyFull(buyout, true)
							end
						end
					end
				end
			end
		end
--
-- Collect the price of reagents
--
		toConcatLabel = {}
		toConcatExtra = {}
		local cost = 0
		for i=1,#recipe.reagentData do
			local reagent = recipe.reagentData[i]
			local value, needed, id, name, custom = GetReagentData(recipe.reagentData[i])
			value = AddExtraText(value, needed, id, name, custom)
			cost = cost + value
		end
		if recipe.modifiedData then
			--DA.DEBUG(0,"GetExtraText: modifiedData= "..DA.DUMP(recipe.modifiedData))
			for i=1,#recipe.modifiedData do
				local value, needed, id, name, custom = GetReagentData(recipe.modifiedData[i])
				value = AddExtraText(value, needed, id, name, custom)
				cost = cost + value
			end
		end
--
-- Show all the reagent information?
--
		if CraftBench.db.profile.plugins.ATR.reagentPrices then
			label = label.."\n\n"..table.concat(toConcatLabel,"\n").."\n"
			extra_text = extra_text.."\n\n"..table.concat(toConcatExtra,"\n").."\n"
		else
			label = label.."\n"
			extra_text = extra_text.."\n"
		end
--
-- If reagents were priced as bought from a vendor, should we markup the price? 
--
		if CraftBench.db.profile.plugins.ATR.useVendorCalc then
			local markup = CraftBench.db.profile.plugins.ATR.markup or markupDef
			label = label.."\n   "..L["Cost"].." * "..(markup * 100).."%:\n"
			cost = cost * markup
		else
			label = label.."\n   "..L["Cost"]..":\n"
		end
		extra_text = extra_text.."\n"..CraftBench:FormatMoneyFull(cost, true).."\n"
--
-- If we craft this item, will we make a profit?
--
		if buyout then
			local ah_tax = CraftBench.db.profile.plugins.ATR.calcProfitAhTax and ahtaxDef or 1
			local profit = buyout * ah_tax - cost
			if CraftBench.db.profile.plugins.ATR.extraProfitValue or CraftBench.db.profile.plugins.ATR.extraProfitPercentage then
				label = label.."\n"
				extra_text = extra_text.."\n"
			end
--
-- Show the profit absolute value and as a percentage of the cost
--
			if CraftBench.db.profile.plugins.ATR.extraProfitValue then
				label = label.."   Profit:\n"
				extra_text = extra_text..CraftBench:FormatMoneyFull(profit, true).."\n"
			end
			if CraftBench.db.profile.plugins.ATR.extraProfitPercentage then
				label = label.."   Profit percentage:\n"
				extra_text = extra_text..profitPctText(profit,cost,9999).."%\n"
			end
		end
--
-- Show Journalator sales info
--
		if addonName and Journalator and CraftBench.db.profile.plugins.ATR.journalatorE then
			label = label.."\n"
			extra_text = extra_text.."\n"
			local itemName = C_Item.GetItemInfo(itemID)
			local salesRate, successCount, failedCount, lastSold, lastBought
			if Journalator.API and itemName then
				successCount = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemName)
				failedCount = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemName)
				if successCount > 0 then
					salesRate = string.format("%.0d", successCount / (successCount + failedCount) * 100).."%"
				else
					salesRate = nil
				end
				lastSold = Journalator.API.v1.GetRealmLastSoldByItemName(addonName, itemName)
				lastBought = Journalator.API.v1.GetRealmLastBoughtByItemName(addonName, itemName)
				--DA.DEBUG(0,"GetExtraText(1): itemName= "..tostring(itemName)..", successCount= "..tostring(successCount)..", failedCount= "..tostring(failedCount)..", lastSold= "..tostring(lastSold)..", lastBought= "..tostring(lastBought))
			elseif itemName then
				salesRate, failedCount, lastSold, lastBought = Journalator.Tooltips.GetSalesInfo(itemName)
				--DA.DEBUG(0,"GetExtraText(2): itemName= "..tostring(itemName)..", salesRate= "..tostring(salesRate)..", failedCount= "..tostring(failedCount)..", lastSold= "..tostring(lastSold)..", lastBought= "..tostring(lastBought))
			end
			if salesRate and (string.find(salesRate,"%%") or DA.DebugShow) then
				label = label.."   salesRate:\n"
				extra_text = extra_text..tostring(salesRate).."\n"
			end
			if successCount and (successCount > 0 or DA.DebugShow) then
				label = label.."   successCount:\n"
				extra_text = extra_text..tostring(successCount).."\n"
			end
			if failedCount and (failedCount > 0 or DA.DebugShow) then
				label = label.."   failedCount:\n"
				extra_text = extra_text..tostring(failedCount).."\n"
			end
			if lastSold and (lastSold > 0 or DA.DebugShow) then
				label = label.."   lastSold:\n"
				extra_text = extra_text..CraftBench:FormatMoneyFull(lastSold, true).."\n"
			end
			if lastBought and (lastBought > 0 or DA.DebugShow) then
				label = label.."   lastBought:\n"
				extra_text = extra_text..CraftBench:FormatMoneyFull(lastBought, true).."\n"
			end
		end
	end
	return label, extra_text
end

--
-- Returns a text string suffix
--
function plugin.RecipeNameSuffix(skill, recipe)
	local text, buyout, cost, profit, percentage, sellout, vprofit
	local successCount = 0
	local failedCount = 0
	local salesRate = nil
	if not recipe then return end
	--DA.DEBUG(0,"RecipeNameSuffix: recipe= "..DA.DUMP1(recipe,1))
	local itemID = recipe.itemID
	--DA.DEBUG(0,"RecipeNameSuffix: itemID= "..tostring(itemID)..", type= "..type(itemID))
--
-- Check for Enchanting. Most recipes don't produce an item but
-- we still should get reagent prices.
--
	if CraftBench.isCraft then
		--DA.DEBUG(0,"RecipeNameSuffix: itemID= "..tostring(itemID)..", type= "..type(itemID))
		--DA.DEBUG(0,"RecipeNameSuffix: recipe.name= "..tostring(recipe.name)..", recipe.spellID= "..tostring(recipe.spellID)..", recipe.scrollID= "..tostring(recipe.scrollID))
		if itemID then
			itemID = CraftBench.EnchantSpellToItem[itemID] or 0
			--DA.DEBUG(0,"RecipeNameSuffix: Change via EnchantSpellToItem, itemID= "..tostring(itemID))
		end
	elseif recipe.tradeID == 7411 and itemID == 0 then
		itemID = recipe.scrollID
		--DA.DEBUG(0,"RecipeNameSuffix: Change to scrollID, itemID= "..tostring(itemID))
	end
	local itemName
	if itemID then itemName = C_Item.GetItemInfo(itemID) end
	--DA.DEBUG(0,"RecipeNameSuffix: itemName= "..tostring(itemName)..", type= "..type(itemName))
	if CraftBench.db.profile.plugins.ATR.enabled and itemID then
		buyout, sellout = GetBuyout(recipe)
		cost = 0
		for i=1,#recipe.reagentData do
			local value = GetReagentData(recipe.reagentData[i])
			cost = cost + value
		end
		if recipe.modifiedData then
			--DA.DEBUG(0,"GetRecipeData: modifiedData= "..DA.DUMP(recipe.modifiedData))
			for i=1,#recipe.modifiedData do
				local value = GetReagentData(recipe.modifiedData[i])
				cost = cost + value
			end
		end
		if CraftBench.db.profile.plugins.ATR.useVendorCalc then
			local markup = CraftBench.db.profile.plugins.ATR.markup or markupDef
			cost = cost * markup
		end
		local ah_tax = CraftBench.db.profile.plugins.ATR.calcProfitAhTax and ahtaxDef or 1
		profit = buyout * ah_tax - cost
		vprofit = sellout - cost
		if cost ~= 0 then
			percentage = profit * 100 / cost
		end

		if addonName and Journalator and Journalator.API then
			if itemName then
				successCount = Journalator.API.v1.GetRealmSuccessCountByItemName(addonName, itemName)
				failedCount = Journalator.API.v1.GetRealmFailureCountByItemName(addonName, itemName)
				if (successCount + failedCount) > 0 then
					salesRate = string.format("%2.0f", successCount / (successCount + failedCount) * 100).."%"
				else
					salesRate = string.format("%2.0f", 0).."%"
				end
			end
			--DA.DEBUG(0, "RecipeNameSuffix: itemName= "..tostring(itemName)..", successCount="..tostring(successCount)..", failedCount="..tostring(failedCount)..", salesRate="..tostring(salesRate))
		end

--
-- When one of our sorts is active, the suffix is the sort value
-- If none of our sorts is active, the suffix is determined by the option settings
--
		local getSort = GetATRSort()
		local isSortA = IsATRSort()
		local isSortJ = IsJNLSort()
		local isSort = isSortA or isSortJ
		--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort))
		if getSort == "ATR: "..L["Buyout"] or ((not isSortA or isSortJ) and CraftBench.db.profile.plugins.ATR.suffixBuyout) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixBuyout= "..tostring(CraftBench.db.profile.plugins.ATR.suffixBuyout))
			if CraftBench.db.profile.plugins.ATR.useShort then
				text = CraftBench:FormatMoneyShort(buyout, true, CraftBench.db.profile.plugins.ATR.colorCode)
			else
				text = CraftBench:FormatMoneyFull(buyout, true, CraftBench.db.profile.plugins.ATR.colorCode)
			end
		elseif getSort == "ATR: "..L["Cost"] or ((not isSortA or isSortJ) and CraftBench.db.profile.plugins.ATR.suffixCost) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixCost= "..tostring(CraftBench.db.profile.plugins.ATR.suffixCost))
			if CraftBench.db.profile.plugins.ATR.useShort then
				text = CraftBench:FormatMoneyShort(cost, true, CraftBench.db.profile.plugins.ATR.colorCode)
			else
				text = CraftBench:FormatMoneyFull(cost, true, CraftBench.db.profile.plugins.ATR.colorCode)
			end
		elseif getSort == "ATR: "..L["Profit"] or ((not isSortA or isSortJ) and CraftBench.db.profile.plugins.ATR.suffixProfitValue) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitValue= "..tostring(CraftBench.db.profile.plugins.ATR.suffixProfitValue))
			if CraftBench.db.profile.plugins.ATR.useShort then
				text = CraftBench:FormatMoneyShort(profit, true, CraftBench.db.profile.plugins.ATR.colorCode)
			else
				text = CraftBench:FormatMoneyFull(profit, true, CraftBench.db.profile.plugins.ATR.colorCode)
			end
			if not isSort and CraftBench.db.profile.plugins.ATR.onlyPositive and profit <= 0 then
				text = nil
			end
		elseif getSort == "ATR: "..L["Percent"] or ((not isSortA or isSortJ) and CraftBench.db.profile.plugins.ATR.suffixProfitPercentage) then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitPercentage= "..tostring(CraftBench.db.profile.plugins.ATR.suffixProfitPercentage))
			if text then
				text = text.." ("..profitPctText(profit,cost,999).."%)"
			else
				text = "("..profitPctText(profit,cost,999).."%)"
			end
		elseif getSort == "ATR: "..L["Sellout"] then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitPercentage= "..tostring(CraftBench.db.profile.plugins.ATR.suffixProfitPercentage))
			if CraftBench.db.profile.plugins.ATR.useShort then
				text = CraftBench:FormatMoneyShort(sellout, true, CraftBench.db.profile.plugins.ATR.colorCode)
			else
				text = CraftBench:FormatMoneyFull(sellout, true, CraftBench.db.profile.plugins.ATR.colorCode)
			end
		elseif getSort == "ATR: "..L["VProfit"] then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", suffixProfitPercentage= "..tostring(CraftBench.db.profile.plugins.ATR.suffixProfitPercentage))
			if CraftBench.db.profile.plugins.ATR.useShort then
				text = CraftBench:FormatMoneyShort(vprofit, true, CraftBench.db.profile.plugins.ATR.colorCode)
			else
				text = CraftBench:FormatMoneyFull(vprofit, true, CraftBench.db.profile.plugins.ATR.colorCode)
			end
			if CraftBench.db.profile.plugins.ATR.onlyPositive and vprofit <= 0 then
				text = nil
			end
		end
		if Journalator and CraftBench.db.profile.plugins.ATR.journalatorC then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", journalatorC= "..tostring(CraftBench.db.profile.plugins.ATR.journalatorC))
				if text then
					text = text.." ["..string.format("%3.0f", successCount).."]"
				else
					text = "["..string.format("%3.0f", successCount).."]"
				end
		end
		if Journalator and CraftBench.db.profile.plugins.ATR.journalatorS then
			--DA.DEBUG(1, "RecipeNameSuffix: GetATRSort="..tostring(getSort)..", IsATRSort= "..tostring(isSort)..", journalatorS= "..tostring(CraftBench.db.profile.plugins.ATR.journalatorS))
			if salesRate and string.find(salesRate,"%%") then
				if text then
					text = text.." ["..tostring(salesRate).."]"
				else
					text = "["..tostring(salesRate).."]"
				end
			end
		end
	end
	recipe.buyout = buyout
	recipe.cost = cost
	recipe.profit = profit
	recipe.percentage = percentage
	recipe.sellout = sellout
	recipe.vprofit = vprofit
	recipe.mostsold = successCount
	recipe.salesrate = salesRate
	recipe.suffix = SetATRsuffix(recipe)
	return text
end

CraftBench:RegisterRecipeNamePlugin("ATRPlugin")		-- we have a RecipeNamePrefix or a RecipeNameSuffix function

CraftBench:RegisterDisplayDetailPlugin("ATRPlugin")	-- we have a GetExtraText function

--
-- Auctionator button support
--  whichOne:
--    true will search for the items in the ShoppingList
--    false (or nil) will search for the item and reagents in the MainFrame
--
function CraftBench:AuctionatorSearch(whichOne)
	--DA.DEBUG(0, "AuctionatorSearch("..tostring(whichOne)..")")
	local shoppingListName
	local items = {}
	local recipe = CraftBench:GetRecipeDataByTradeIndex(CraftBench.currentTrade, CraftBench.selectedSkill)
	local useSearchExact = CraftBench.db.profile.plugins.ATR.useSearchExact
	--DA.DEBUG(1,"AuctionatorSearch: recipe= "..DA.DUMP1(recipe))
	if whichOne then
		shoppingListName = L["Shopping List"]
		local name = nil
		if not CraftBench.db.profile.include_alts then
			name = CraftBench.currentPlayer
		end
		local list = CraftBench:GetShoppingList(name, CraftBench.db.profile.same_faction, CraftBench.db.profile.include_guild)
		if not list or #list == 0 then
			--DA.DEBUG(0,"AuctionatorSearch: Shopping List is empty")
			return
		end
		for i=1,#list,1 do
			local id  = list[i].id
			local name = C_Item.GetItemInfo(id)
			if name and not CraftBench:VendorSellsReagent(id) then
				table.insert (items, name)
				--DA.DEBUG(1, "AuctionatorSearch: Item["..tostring(i).."] "..name.." ("..tostring(id)..") added")
			end
		end
	else
		if not recipe then
			return
		end
		local itemID = recipe.itemID
--
-- Check for Enchanting. For Wrath, Add the scroll for the enchant instead
--
		if CraftBench.isCraft and itemID then
			itemID = CraftBench.EnchantSpellToItem[itemID] or 0
		end
		if itemID ~= 0 then
			shoppingListName = C_Item.GetItemInfo(itemID)
		else
			shoppingListName = recipe.name
		end
		if (shoppingListName) then
			if recipe.tradeID == 7411 and not CraftBench.isCraft then
				if recipe.scrollID then
					local scrollName = C_Item.GetItemInfo(recipe.scrollID)
					if scrollName then
						table.insert(items, scrollName)
					end
				end
			elseif not recipe.salvage then
				table.insert(items, shoppingListName)
			end
		end
--
-- Add the reagent names
--
		local i
		for i=1, #recipe.reagentData do
			local reagent = recipe.reagentData[i]
			if not reagent then
				break
			end
			local needed = reagent.numNeeded or 0
			local id
			if CraftBench.isRetail or CraftBench.isForever then
				id = reagent.reagentID
			else
				id = reagent.id
			end
			if id then
				local reagentName = C_Item.GetItemInfo(id)
				if (reagentName) then
					if not CraftBench:VendorSellsReagent(id) then
						table.insert (items, reagentName)
						DA.DEBUG(1, "AuctionatorSearch:  Added  ["..i.."] ("..id..") "..reagentName)
					else
						DA.DEBUG(1, "AuctionatorSearch: Skipped ["..i.."] ("..id..") "..reagentName)
					end
				end
			end
		end
		if recipe.salvage then
			--DA.DEBUG(1,"AuctionatorSearch: recipe= "..DA.DUMP1(recipe))
			--DA.DEBUG(1, "AuctionatorSearch: numSalvage= "..tostring(#recipe.salvage)..", salvage= "..DA.DUMP(recipe.salvage))
			useSearchExact = true
			for i=1, #recipe.salvage do
				local id = recipe.salvage[i]
				local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(id)
				if quality == nil or quality == 1 then
					local name, bname = self:nameWithQuality(id)
					if (bname) then
						if not CraftBench:VendorSellsReagent(id) then
							table.insert (items, bname)
							--DA.DEBUG(1, "AuctionatorSearch:  Added  ["..i.."] ("..id..") "..bname)
						else
							--DA.DEBUG(1, "AuctionatorSearch: Skipped ["..i.."] ("..id..") "..bname)
						end
					end
				end
			end
		end
		if recipe.numModified then
			for i=1, recipe.numModified do
				local id = recipe.modifiedData[i].reagentID
				local name, bname = self:nameWithQuality(id)
				if (bname) then
					if not CraftBench:VendorSellsReagent(id) then
						table.insert (items, bname)
						--DA.DEBUG(1, "AuctionatorSearch:  Added  ["..i.."] ("..id..") "..bname)
					else
						--DA.DEBUG(1, "AuctionatorSearch: Skipped ["..i.."] ("..id..") "..bname)
					end
				end
			end
		end
	end
--
-- Make sure the Auction House is still open
--
--[[
	if (not AuctionHouseFrame or not AuctionHouseFrame:IsShown()) and
	   (not AuctionFrame      or not AuctionFrame:IsShown()) then
		return
	end
--]]
	if CraftBench.auctionOpen and #items > 0 and Auctionator and Auctionator.API and Auctionator.API.v1 then
		if useSearchExact and Auctionator.API.v1.MultiSearchExact then
			--DA.DEBUG(0, "AuctionatorSearch: (exact) addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
			Auctionator.API.v1.MultiSearchExact(addonName, items)
		elseif Auctionator.API.v1.MultiSearch then
			--DA.DEBUG(0, "AuctionatorSearch: addonName= "..tostring(addonName)..", items= "..DA.DUMP1(items))
			Auctionator.API.v1.MultiSearch(addonName, items)
		end
	end
end
