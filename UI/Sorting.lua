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
]]--

local L = LibStub("AceLocale-3.0"):GetLocale("CraftForge")

function CraftForge:GetItemMarketOrVendorPrice(itemID)
	if not itemID or itemID == 0 then return 0, false end
	local pref = self.db and self.db.profile and self.db.profile.plugins and self.db.profile.plugins.preferredAHAddon or "Auto"
	local function queryAuctionator()
		if _G.Auctionator and _G.Auctionator.API and _G.Auctionator.API.v1 and _G.Auctionator.API.v1.GetAuctionPriceByItemID then
			local ok, price = pcall(_G.Auctionator.API.v1.GetAuctionPriceByItemID, "CraftForge", itemID)
			if ok and type(price) == "number" and price > 0 then return price end
		end
	end
	local function queryTSM()
		if self.GetTSMPrice then
			local p = self:GetTSMPrice(itemID)
			if p and p > 0 then return p end
		end
	end
	local function queryOE()
		if _G.OEMarketInfo then
			local ok, info = pcall(_G.OEMarketInfo, itemID)
			if ok and type(info) == "table" and type(info.market) == "number" and info.market > 0 then
				return info.market
			end
		end
	end
	local order = { queryAuctionator, queryTSM, queryOE }
	if pref == "TSM" then
		order = { queryTSM, queryAuctionator, queryOE }
	elseif pref == "OribosExchange" then
		order = { queryOE, queryAuctionator, queryTSM }
	end
	for _, fn in ipairs(order) do
		local p = fn()
		if p and p > 0 then
			return p, true
		end
	end
	local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemID)
	if type(sellPrice) == "number" and sellPrice > 0 then
		return sellPrice, false
	end
	return 0, false
end

function CraftForge:GetRecipeCostAndProfit(recipe)
	if not recipe then return nil, nil, nil end
	local cost = 0
	if recipe.reagentData then
		for i = 1, #recipe.reagentData do
			local reagent = recipe.reagentData[i]
			if reagent and reagent.reagentID and reagent.numNeeded then
				local unitPrice = self:GetItemMarketOrVendorPrice(reagent.reagentID)
				if unitPrice <= 0 and self.VendorSellsReagent and self:VendorSellsReagent(reagent.reagentID) then
					local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(reagent.reagentID)
					unitPrice = (sellPrice and sellPrice > 0) and (sellPrice * 4) or 0
				end
				cost = cost + (unitPrice * reagent.numNeeded)
			end
		end
	end
	local value = 0
	if recipe.itemID and recipe.itemID ~= 0 then
		local unitVal = self:GetItemMarketOrVendorPrice(recipe.itemID)
		value = unitVal * (recipe.numMade or 1)
	end
	if cost == 0 and value == 0 then
		return nil, nil, nil
	end
	return cost, value, (value - cost)
end
--
-- Table of difficulty colors defined in CraftForgeData.lua
--
local skill_style_type = CraftForge.skill_style_type
--
-- List of possible sorting methods
--
local sorters = {}
local recipe_sort_method = nil

local function NOSORT(tradeskill, a, b)
	return (a.skillIndex or 0) < (b.skillIndex or 0)
end

local function sort_recipe_by_name(tradeskill, a, b)
	if a.name == b.name then
		return (a.skillIndex or 0) < (b.skillIndex or 0)
	else
		return a.name < b.name
	end
end

local function sort_recipe_by_skill_level(tradeskill, a, b)
	while a.subGroup and #a.subGroup.entries>0 do
		a = a.subGroup.entries[1]
	end
	while b.subGroup and #b.subGroup.entries>0 do
		b = b.subGroup.entries[1]
	end
	local leftDifficulty = 0
	local rightDifficulty = 0
	if a.skillData and a.skillData.difficulty and skill_style_type[a.skillData.difficulty] then
		leftDifficulty = skill_style_type[a.skillData.difficulty].level
	end
	if b.skillData and b.skillData.difficulty and skill_style_type[b.skillData.difficulty] then
		rightDifficulty = skill_style_type[b.skillData.difficulty].level
	end
	if leftDifficulty == rightDifficulty then
		local left = CraftForge:GetTradeSkillLevels(a.spellID)
		local right = CraftForge:GetTradeSkillLevels(b.spellID)
		if left == right then
			if a.subGroup and b.subGroup then
				return #a.subGroup.entries < #b.subGroup.entries
			else
				return (a.skillIndex or 0) < (b.skillIndex or 0)
			end
		else
			return left > right
		end
	else
		return leftDifficulty > rightDifficulty
	end
end

local function sort_recipe_by_item_level(tradeskill, a, b)
	while a.subGroup and #a.subGroup.entries>0 do
		a = a.subGroup.entries[1]
	end
	while b.subGroup and #b.subGroup.entries>0 do
		b = b.subGroup.entries[1]
	end
	local left_r = CraftForge:GetRecipe(a.recipeID)
	local right_r = CraftForge:GetRecipe(b.recipeID)
	local left  = CraftForge:GetLevelRequiredToUse(left_r.itemID)
	local right = CraftForge:GetLevelRequiredToUse(right_r.itemID)
	if not left  then  left = 0 end
	if not right then right = 0 end
	if left == right then
--
-- Same level, try iLevel next
--
		local left = select(4,C_Item.GetItemInfo(left_r.itemID)) or 0
		local right = select(4,C_Item.GetItemInfo(right_r.itemID)) or 0
		if left == right then
--
-- Same level, sort by difficulty
--
			return sort_recipe_by_skill_level(tradeskill, a, b)
		else
			return left > right
		end
	else
		return left > right
	end
end

local function sort_recipe_by_item_quality(tradeskill, a, b)
	while a.subGroup and #a.subGroup.entries>0 do
		a = a.subGroup.entries[1]
	end
	while b.subGroup and #b.subGroup.entries>0 do
		b = b.subGroup.entries[1]
	end
	local left_r = CraftForge:GetRecipe(a.recipeID)
	local right_r = CraftForge:GetRecipe(b.recipeID)
	local _,_, left = C_Item.GetItemInfo(left_r.itemID)
	local _,_, right = C_Item.GetItemInfo(right_r.itemID)
	if not left  then  left = 0 end
	if not right then right = 0 end
	if left == right then
--
-- Same level, sort by level required to use
--
		return sort_recipe_by_item_level(tradeskill, a, b)
	else
		return left > right
	end
end

local function sort_recipe_by_index(tradeskill, a, b)
	if a and b then
		if a.subGroup and not b.subGroup then
			return true
		end
		if b.subGroup and not a.subGroup then
			return false
		end
		if (a.skillIndex or 0) == (b.skillIndex or 0) then
			return (a.name or "A") < (b.name or "B")
		else
			return (a.skillIndex or 0) < (b.skillIndex or 0)
		end
	else
		return false
	end
end

local function get_suffix(tradeskill, recipe, first)
	local ret = recipe.suffix
	if not ret and recipe.recipeData then
		ret = recipe.recipeData.suffix
	end
	if first and ret == nil and recipe.recipeID then
		local actualRecipe = CraftForge:GetRecipe(recipe.recipeID)
		CraftForge:RecipeNameSuffix(tradeskill, actualRecipe)
		ret = get_suffix(tradeskill, actualRecipe, false)
	end
	return ret
end

local function sort_recipe_by_suffix(tradeskill, a, b)
	if a.subGroup or b.subGroup then
		return NOSORT(tradeskill, a, b)
	end
	local as = get_suffix(tradeskill, a, true)
	local bs = get_suffix(tradeskill, b, true)
	if as == bs then
		return (a.skillIndex or 0) < (b.skillIndex or 0)
	else
		return (as or 0) > (bs or 0)
	end
end

local function SkillIsFilteredOut(skillIndex)
	--DA.DEBUG(0,"SkillIsFilteredOut("..tostring(skillIndex)..")")
	local skill = CraftForge:GetSkill(CraftForge.currentPlayer, CraftForge.currentTrade, skillIndex)
	--DA.DEBUG(1,"SkillIsFilteredOut: skill = "..DA.DUMP1(skill,1))
	local recipe = CraftForge:GetRecipe(skill.id)
	--DA.DEBUG(1,"SkillIsFilteredOut: recipe = "..DA.DUMP1(recipe,1))
	local recipeID = recipe.spellID or 0
	if recipeID == 0 then
--
-- It's a header, don't filter here
--
		return false
	end

	local recipeInfo = CraftForge.data.recipeInfo[CraftForge.currentTrade][recipeID]
	if recipeInfo then
		--DA.DEBUG(1,"SkillIsFilteredOut: unlearnedRecipes= "..tostring(CraftForge.unlearnedRecipes)..", recipeInfo = "..DA.DUMP1(recipeInfo,1))
		if CraftForge.unlearnedRecipes and recipeInfo.learned then
			return true
		end
		if CraftForge.learnedRecipes and not recipeInfo.learned then
			return true
		end
	end

	if CraftForge:IsUpgradeHidden(recipeID) then
		return true
	end

	if CraftForge:GetTradeSkillOption("favoritesOnly") and not CraftForge:IsFavorite(recipeID) then
		return true
	end

	if CraftForge:GetTradeSkillOption("buffsOnly") and CraftForge.IsBuffRecipe and not CraftForge:IsBuffRecipe(recipe) then
		return true
	end

	if CraftForge:GetTradeSkillOption("isfirstcraft") and not CraftForge:IsFirstCraft(recipeID) then
		return true
	end

	if CraftForge:GetTradeSkillOption("onlyProfitable") then
		local _, _, profit = CraftForge:GetRecipeCostAndProfit(recipe)
		if not profit or profit <= 0 then
			return true
		end
	end

	if CraftForge:GetTradeSkillOption("hasSourceOnly") then
		local src = C_TradeSkillUI and C_TradeSkillUI.GetRecipeSourceText and skill.id and C_TradeSkillUI.GetRecipeSourceText(skill.id)
		if (not src or src == "") and CraftForge.ATTPlugin and CraftForge.ATTPlugin.GetRecipeSource then
			src = CraftForge.ATTPlugin.GetRecipeSource(skill, recipe)
		end
		if not src or src == "" then
			return true
		end
	end

--
-- Are we hiding anything that is trivial (has no chance of giving a skill point)
--
	if skill_style_type[skill.difficulty] then
		if skill_style_type[skill.difficulty].level < (CraftForge:GetTradeSkillOption("filterLevel") or 4) then
			return true
		end
	end
--
-- Are we hiding anything that can't be created with the mats on this character?
--
	if CraftForge:GetTradeSkillOption("hideuncraftable") then
		if not (skill.numCraftable > 0 and CraftForge:GetTradeSkillOption("filterInventory-bag")) and
		   not (skill.numRecursive > 0 and CraftForge:GetTradeSkillOption("filterInventory-crafted")) and
		   not (skill.numCraftableVendor > 0 and CraftForge:GetTradeSkillOption("filterInventory-vendor")) and
		   not (skill.numCraftableAlts > 0 and CraftForge:GetTradeSkillOption("filterInventory-alts")) then
			return true
		end
	end
	if CraftForge.recipeFilters then
		for _,f in pairs(CraftForge.recipeFilters) do
			if f.filterMethod(f.namespace, skillIndex) then
				return true
			end
		end
	end
--
-- String search
--
	local searchtext = CraftForge:GetTradeSkillOption("searchtext")
	if searchtext and searchtext ~= "" then
		local filter = string.lower(searchtext)
		local nameOnly = false
		if string.sub(filter,1,1) == "!" then
			filter = string.sub(filter,2)
			nameOnly = true
		end
		local word
		local name = ""
		local tooltip = _G["CraftForgeParsingTooltip"]
		if tooltip == nil then
			tooltip = CreateFrame("GameTooltip", "CraftForgeParsingTooltip", _G["ANCHOR_NONE"], "GameTooltipTemplate")
			tooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
		end
		local searchText = ""
		if nameOnly then
			searchText = recipe.name
		else
			if not CraftForge.data.tooltipCache or CraftForge.data.tooltipCachedTrade ~= CraftForge.currentTrade then
				CraftForge.data.tooltipCachedTrade = CraftForge.currentTrade
				CraftForge.data.tooltipCache = {}
			end
			if not CraftForge.data.tooltipCache[recipeID] then
				tooltip:SetHyperlink("enchant:"..recipeID)
				local tiplines = tooltip:NumLines()
				for i=1, tiplines, 1 do
					searchText = searchText.. " " .. string.lower(_G["CraftForgeParsingTooltipTextLeft"..i]:GetText() or " ")
					searchText = searchText.. " " .. string.lower(_G["CraftForgeParsingTooltipTextRight"..i]:GetText() or " ")
				end
				CraftForge.data.tooltipCache[recipeID] = searchText
			else
				searchText = CraftForge.data.tooltipCache[recipeID]
			end
		end
		if searchText then
			searchText = string.lower(searchText)
			local wordList = { strsplit(" ",filter) }
			for v,word in pairs(wordList) do
				if string.find(searchText, word, 1, true) == nil then
					return true
				end
			end
		end
	end
	return false
end

local function set_sort_desc(toggle)
	for _,entry in pairs(sorters) do
		if entry.sorter == recipe_sort_method then
			CraftForge:SetTradeSkillOption("sortdesc-" .. entry.name, toggle)
			CraftForge:SortAndFilterRecipes()
		end
	end
end

local function is_sort_desc()
	for _,entry in pairs(sorters) do
		if entry.sorter == recipe_sort_method then
			return CraftForge:GetTradeSkillOption("sortdesc-" .. entry.name)
		end
	end
	return true
end

local function show_sort_toggle()
	CraftForgeSortDescButton:Hide()
	CraftForgeSortAscButton:Hide()
	if recipe_sort_method ~= NOSORT then
		if is_sort_desc() then
			CraftForgeSortDescButton:Show()
		else
			CraftForgeSortAscButton:Show()
		end
	end
end

function CraftForge:ExpandAll()
	local skillListKey = CraftForge.currentPlayer..":"..CraftForge.currentTrade..":"..CraftForge.currentGroupLabel
	if self.data.sortedSkillList[skillListKey] then
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		local numTradeSkills = sortedSkillList.count
		for i=1, numTradeSkills, 1 do
			local skill = sortedSkillList[i]
			if skill.subGroup then
				skill.subGroup.expanded = true
			end
		end
	end
	CraftForge:SortAndFilterRecipes()
	CraftForge:UpdateTradeSkillWindow()
end

function CraftForge:CollapseAll()
	local skillListKey = CraftForge.currentPlayer..":"..CraftForge.currentTrade..":"..CraftForge.currentGroupLabel
	if self.data.sortedSkillList[skillListKey] then
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		local numTradeSkills = sortedSkillList.count
		for i=1, numTradeSkills, 1 do
			local skill = sortedSkillList[i]
			if skill.subGroup then
				skill.subGroup.expanded = false
			end
		end
	end
	CraftForge:SortAndFilterRecipes()
	CraftForge:UpdateTradeSkillWindow()
end

--
-- Builds a sorted and filtered list of recipes for the
-- currently selected tradekskill and sorting method
-- if no sorting, then headers will be included
--
-- Adds the sorting routine to the list of sorting routines.
--
function CraftForge:AddRecipeSorter(text, sorter)
	assert(text and tostring(text),
		"Usage CraftForge:AddRecipeSorter(text, sorter), text must be a string")
	assert(sorter and type(sorter) == "function",
		"Usage CraftForge:AddRecipeSorter(text, sorter), sorter must be a function")
	for _,entry in pairs(sorters) do
		if entry.name == text then
			return
		end
	end
	table.insert(sorters, {["name"]=text, ["sorter"]=sorter})
end

function CraftForge:InitializeSorting()
--
-- Default sorting methods
-- We don't go through the public API for this as we want our methods
-- to appear first in the list, no matter what.
--
	table.insert(sorters, 1, {["name"]=L["None"], ["sorter"]=sort_recipe_by_index})
	table.insert(sorters, 2, {["name"]=L["By Name"], ["sorter"]=sort_recipe_by_name})
	table.insert(sorters, 3, {["name"]=L["By Difficulty"], ["sorter"]=sort_recipe_by_skill_level})
--	table.insert(sorters, 4, {["name"]=L["By Skill Level"], ["sorter"]=sort_recipe_by_skill_level})
	table.insert(sorters, 4, {["name"]=L["By Item Level"], ["sorter"]=sort_recipe_by_item_level})
	table.insert(sorters, 5, {["name"]=L["By Quality"], ["sorter"]=sort_recipe_by_item_quality})
	table.insert(sorters, 6, {["name"]=L["By Suffix"], ["sorter"]=sort_recipe_by_suffix})
	table.insert(sorters, 7, {["name"]=L["By Profit"], ["sorter"]=function(tradeskill, a, b)
		while a.subGroup and #a.subGroup.entries > 0 do
			a = a.subGroup.entries[1]
		end
		while b.subGroup and #b.subGroup.entries > 0 do
			b = b.subGroup.entries[1]
		end
		local ra = a.recipeID and CraftForge:GetRecipe(a.recipeID)
		local rb = b.recipeID and CraftForge:GetRecipe(b.recipeID)
		local _, _, pa = CraftForge:GetRecipeCostAndProfit(ra)
		local _, _, pb = CraftForge:GetRecipeCostAndProfit(rb)
		pa = pa or -999999999
		pb = pb or -999999999
		if pa == pb then
			return (a.skillIndex or 0) < (b.skillIndex or 0)
		end
		return pa > pb
	end})

	recipe_sort_method = sort_recipe_by_index
	CraftForgeSortAscButton:SetScript("OnClick", function()
		-- clicked the button will toggle sort ascending off
		set_sort_desc(true)
		CraftForgeSortAscButton:Hide()
		CraftForgeSortDescButton:Show()
		self:UpdateTradeSkillWindow()
	end)
	CraftForgeSortAscButton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(CraftForgeSortAscButton, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["SORTASC"])
	end)
	CraftForgeSortAscButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	CraftForgeSortDescButton:SetScript("OnClick", function()
		-- clicked the button will toggle sort descending off
		set_sort_desc(false)
		CraftForgeSortDescButton:Hide()
		CraftForgeSortAscButton:Show()
		self:UpdateTradeSkillWindow()
	end)
	CraftForgeSortDescButton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(CraftForgeSortDescButton, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["SORTDESC"])
	end)
	CraftForgeSortDescButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

--
-- Causes the list of recipes to be resorted
--
function CraftForge:SortAndFilterRecipes()
	DA.DEBUG(0,"SortAndFilterRecipes()")
	local skillListKey = CraftForge.currentPlayer..":"..CraftForge.currentTrade..":"..CraftForge.currentGroupLabel
	local numSkills = CraftForge:GetNumSkills(CraftForge.currentPlayer, CraftForge.currentTrade)
	if not CraftForge.data.sortedSkillList then
		--DA.DEBUG(1,"SortAndFilterRecipes: CraftForge.data.sortedSkillList = {}")
		CraftForge.data.sortedSkillList = {}
	end
	if not CraftForge.data.sortedSkillList[skillListKey] then
		--DA.DEBUG(1,"SortAndFilterRecipes: CraftForge.data.sortedSkillList[skillListKey] = {}")
		CraftForge.data.sortedSkillList[skillListKey] = {}
	end
	local sortedSkillList = CraftForge.data.sortedSkillList[skillListKey]
	local oldLength = #sortedSkillList
	--DA.DEBUG(1,"SortAndFilterRecipes: numSkills= "..tostring(numSkills)..", oldLength= ",tostring(oldLength))
	local button_index = 0
	local searchtext = CraftForge:GetTradeSkillOption("searchtext")
	local groupLabel = CraftForge.currentGroupLabel
	--DA.DEBUG(1,"SortAndFilterRecipes: searchtext="..tostring(searchtext)..", groupLabel="..tostring(groupLabel))
	if searchtext and searchtext ~= "" or groupLabel == "Flat" then
		--DA.DEBUG(1,"SortAndFilterRecipes: Flat")
		for i=1, numSkills, 1 do
			local skill = CraftForge:GetSkill(CraftForge.currentPlayer, CraftForge.currentTrade, i)
			if skill then
				local recipe = CraftForge:GetRecipe(skill.id)
				if skill.id ~= 0 then							-- not a header
					local filtered = SkillIsFilteredOut(i)
					--DA.DEBUG(1,"SortAndFilterRecipes: SkillIsFilteredOut("..tostring(i)..")= "..tostring(filtered))
					if not filtered then
--
-- skill is not filtered out
--
						button_index = button_index + 1
						sortedSkillList[button_index] = {["recipeID"] = skill.id, ["spellID"] = recipe.spellID, ["name"] = recipe.name, ["skillIndex"] = i, ["recipeData"] = recipe, ["skillData"] = skill, ["depth"] = 0}
					elseif i == CraftForge.selectedSkill then
--
-- if filtered out and selected - deselect
--
						CraftForge.selectedSkill = nil
					end
				end
			end
		end
		if oldLength > button_index then
			while oldLength > button_index do
				sortedSkillList[oldLength] = nil
				oldLength = oldLength - 1
			end
		end
		if not is_sort_desc() then
			table.sort(sortedSkillList, function(a,b)
				return recipe_sort_method(CraftForge.currentTrade, a, b)
			end)
		else
			table.sort(sortedSkillList, function(a,b)
				return recipe_sort_method(CraftForge.currentTrade, b, a)
			end)
		end
	else
--
-- No search string and not Flat (i.e. Blizzard)
--
		local group = CraftForge:RecipeGroupFind(CraftForge.currentPlayer, CraftForge.currentTrade, CraftForge.currentGroupLabel, CraftForge.currentGroup)
		--DA.DEBUG(1,"SortAndFilterRecipes: current grouping "..CraftForge.currentGroupLabel.." "..(CraftForge.currentGroup or "nil"))
		if recipe_sort_method ~= NOSORT then
			CraftForge:RecipeGroupSort(group, recipe_sort_method, is_sort_desc())
		end
		if CraftForge.currentGroup then
			CraftForge:RecipeGroupInitFlatten(group, sortedSkillList)
			button_index = CraftForge:RecipeGroupFlatten(group, 1, sortedSkillList, 1) + 1
		else
			button_index = CraftForge:RecipeGroupFlatten(group, 0, sortedSkillList, 0)
		end
	end
	DA.DEBUG(1,"SortAndFilterRecipes: sorted "..button_index.." skills")
	sortedSkillList.count = button_index
	return button_index
end

--
-- called when the sort drop down is first loaded
--
function CraftForge:SortDropdown_OnLoad()
	UIDropDownMenu_Initialize(CraftForgeSortDropdown, CraftForge.SortDropdown_Initialize)
	CraftForgeSortDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	-- Find out which sort method is selected
	for i=1, #sorters, 1 do
		if recipe_sort_method == sorters[i].sorter then
			UIDropDownMenu_SetSelectedID(CraftForgeSortDropdown, i)
			break
		end
	end
--
-- Can't call show_sort_toggle() here as the sort
-- buttons have not been created yet
--
end

--
-- Called when the sort drop down is displayed
--
function CraftForge:SortDropdown_OnShow()
	UIDropDownMenu_Initialize(CraftForgeSortDropdown, CraftForge.SortDropdown_Initialize)
	CraftForgeSortDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	for i=1, #sorters, 1 do
		if recipe_sort_method == sorters[i].sorter then
			UIDropDownMenu_SetSelectedID(CraftForgeSortDropdown, i)
			break
		end
	end
	show_sort_toggle()
end

--
-- The method we use the initialize the sorting drop down.
--
function CraftForge:SortDropdown_Initialize()
	recipe_sort_method = NOSORT
	local currentSort = CraftForge:GetTradeSkillOption("sortmethod")
	local matched = false
	local info
	for i=1, #sorters, 1 do
		local entry = sorters[i]
		info = UIDropDownMenu_CreateInfo()
		info.text = entry.name
		info.isNotRadio = true
		if entry.name == currentSort or (i == 1 and currentSort == "None") then
			recipe_sort_method = entry.sorter
			info.checked = true
			matched = true
		else
			info.checked = false
		end
		info.func = CraftForge.SortDropdown_OnClick
		info.value = i
		if self then
			info.owner = self:GetParent()
		end
		UIDropDownMenu_AddButton(info)
	end
	if not matched and sorters[1] then
		recipe_sort_method = sorters[1].sorter
	end
--
-- Can't call show_sort_toggle() here as the sort
-- buttons have not been created yet
--
end

--
-- Called when the user selects an item in the sorting drop down
--
function CraftForge:SortDropdown_OnClick()
	UIDropDownMenu_SetSelectedID(CraftForgeSortDropdown, self:GetID())
	local entry = sorters[self:GetID()]
	CraftForge:SetTradeSkillOption("sortmethod", entry.name)
	recipe_sort_method = entry.sorter
	show_sort_toggle()
	CraftForge:SortAndFilterRecipes()
	CraftForge:UpdateTradeSkillWindow()
end
