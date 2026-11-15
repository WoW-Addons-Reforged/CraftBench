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

--
-- Called when the new filter drop down is displayed
--
function CraftForge:FilterDropDown_OnShow()
	--DA.DEBUG(0,"FilterDropDown_OnShow()")
	UIDropDownMenu_Initialize(CraftForgeFilterDropdown, CraftForge.FilterDropDown_Initialize)
	CraftForgeFilterDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	if CraftForge.unlearnedRecipes and CraftForge.learnedRecipes then
		UIDropDownMenu_SetSelectedID(CraftForgeFilterDropdown, 3)
	elseif CraftForge.unlearnedRecipes and not CraftForge.learnedRecipes then
		UIDropDownMenu_SetSelectedID(CraftForgeFilterDropdown, 2)
	elseif CraftForge.learnedRecipes and not CraftForge.unlearnedRecipes then
		UIDropDownMenu_SetSelectedID(CraftForgeFilterDropdown, 1)
	end
end

--
-- The method we use the initialize the new filter drop down.
--
function CraftForge:FilterDropDown_Initialize()
	--DA.DEBUG(0,"FilterDropDown_Initialize()")
	local selectedID = UIDropDownMenu_GetSelectedID(CraftForgeFilterDropdown)
	local info
	local i = 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Learned"]
	info.isNotRadio = true
	info.checked = (selectedID == i)
	info.func = CraftForge.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Unlearned"]
	info.isNotRadio = true
	info.checked = (selectedID == i)
	info.func = CraftForge.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1

	info = UIDropDownMenu_CreateInfo()
	info.text = L["Both"]
	info.isNotRadio = true
	info.checked = (selectedID == i)
	info.func = CraftForge.FilterDropDown_OnClick
	info.value = i
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	i = i + 1
end

--
-- Called when the user selects an item in the new filter drop down
--
function CraftForge:FilterDropDown_OnClick()
	--DA.DEBUG(0,"FilterDropDown_OnClick()")
	UIDropDownMenu_SetSelectedID(CraftForgeFilterDropdown, self:GetID())
	local index = self:GetID()
	if index == 1 then
		CraftForge:SetTradeSkillLearned()
	elseif index == 2 then
		CraftForge:SetTradeSkillUnlearned()
	elseif index == 3 then
		CraftForge:SetTradeSkillBoth()
	end
	CraftForge.dataScanned = false
	CraftForge:RescanTrade()
	CraftForge:UpdateTradeSkillWindow()
end

function CraftForge.InitializeFilterDropdown(self, level)
	local info = UIDropDownMenu_CreateInfo()
	if level == 1 then
		info.text = L["Reset"]
		info.notCheckable = true
		info.func = function()
			CraftForge:SetDefaultFilters()
			CraftForge:SetTradeSkillOption("onlyProfitable", false)
			CraftForge:SetTradeSkillOption("hasSourceOnly", false)
			CraftForge:ResetTradeSkillFilter() -- verify the search filter is blank (so we get all skills)
			UIDropDownMenu_RefreshAll(CraftForgeFilterDropMenu, 3)
			CraftForgeFilterText:SetText("")
			CraftForge.dataScanned = false
			CraftForge:UpdateTradeSkillWindow()
		end
		UIDropDownMenu_AddButton(info, level)
		info.notCheckable = false

		info.text = CRAFT_IS_MAKEABLE
		info.func = function()
			C_TradeSkillUI.SetOnlyShowMakeableRecipes(not C_TradeSkillUI.GetOnlyShowMakeableRecipes())
			CraftForge:SetTradeSkillOption("hideuncraftable", C_TradeSkillUI.GetOnlyShowMakeableRecipes())
			CraftForge.dataScanned = false
			CraftForge:UpdateTradeSkillWindow()
		end
		info.keepShownOnClick = true
		info.checked = C_TradeSkillUI.GetOnlyShowMakeableRecipes()
		info.isNotRadio = true
		UIDropDownMenu_AddButton(info, level)

		info.text = PROFESSION_RECIPES_IS_FIRST_CRAFT
		info.func = function()
			C_TradeSkillUI.SetOnlyShowFirstCraftRecipes(not C_TradeSkillUI.GetOnlyShowFirstCraftRecipes())
			CraftForge:SetTradeSkillOption("isfirstcraft", C_TradeSkillUI.GetOnlyShowFirstCraftRecipes())
			CraftForge.dataScanned = false
			CraftForge:UpdateTradeSkillWindow()
		end
		info.keepShownOnClick = true
		info.checked = C_TradeSkillUI.GetOnlyShowFirstCraftRecipes()
		info.isNotRadio = true
		UIDropDownMenu_AddButton(info, level)

		if not C_TradeSkillUI.IsTradeSkillGuild() and not C_TradeSkillUI.IsNPCCrafting() then
			info.text = TRADESKILL_FILTER_HAS_SKILL_UP
			info.func = function()
				C_TradeSkillUI.SetOnlyShowSkillUpRecipes(not C_TradeSkillUI.GetOnlyShowSkillUpRecipes())
				if C_TradeSkillUI.GetOnlyShowSkillUpRecipes() then
					CraftForge:SetTradeSkillOption("filterLevel", 2)
				else
					CraftForge:SetTradeSkillOption("filterLevel", 1)
				end
				CraftForge.dataScanned = false
				CraftForge:UpdateTradeSkillWindow()
			end
			info.keepShownOnClick = true
			info.checked = C_TradeSkillUI.GetOnlyShowSkillUpRecipes()
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, level)
		end

		info.text = L["Only Profitable"]
		info.func = function()
			CraftForge:SetTradeSkillOption("onlyProfitable", not CraftForge:GetTradeSkillOption("onlyProfitable"))
			CraftForge.dataScanned = false
			CraftForge:UpdateTradeSkillWindow()
		end
		info.keepShownOnClick = true
		info.checked = CraftForge:GetTradeSkillOption("onlyProfitable") and true or false
		info.isNotRadio = true
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Has Source Info"]
		info.func = function()
			CraftForge:SetTradeSkillOption("hasSourceOnly", not CraftForge:GetTradeSkillOption("hasSourceOnly"))
			CraftForge.dataScanned = false
			CraftForge:UpdateTradeSkillWindow()
		end
		info.keepShownOnClick = true
		info.checked = CraftForge:GetTradeSkillOption("hasSourceOnly") and true or false
		info.isNotRadio = true
		UIDropDownMenu_AddButton(info, level)

		info.checked = 	nil
		info.isNotRadio = true
		info.func =  nil
		info.notCheckable = true
		info.keepShownOnClick = false
		info.hasArrow = true

--
-- Uncomment the block below to enable Inventory Slots, Recipe Sources, and Categories
-- Note that Categories may not be needed as CraftForge displays them all by default
--
--[[
		info.text = TRADESKILL_FILTER_SLOTS
		info.value = 1
		info.disabled = true					-- Not working in 5.55
		UIDropDownMenu_AddButton(info, level)

		info.text = SOURCES
		info.value = 2
		info.disabled = true					-- Not working in 5.55
		UIDropDownMenu_AddButton(info, level)

		info.text = TRADESKILL_FILTER_CATEGORY
		info.value = 3
		info.disabled = false					-- Working in 5.55 but probably not needed
		UIDropDownMenu_AddButton(info, level)
--]]

	elseif level == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == 1 then
			local inventorySlots = {C_TradeSkillUI.GetAllFilterableInventorySlots()}
			info.isNotRadio = true
			info.notCheckable = true
			info.text = CHECK_ALL
			info.func = function()
				Professions.SetAllInventorySlotsFiltered(true)
				UIDropDownMenu_Refresh(CraftForgeFilterDropMenu, 1, 2)
				CraftForge.dataScanned = false
				CraftForge:UpdateTradeSkillWindow()
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				Professions.SetAllInventorySlotsFiltered(false)
				CraftForge:SetDefaultFilters()
				UIDropDownMenu_Refresh(CraftForgeFilterDropMenu, 1, 2)
				CraftForge.dataScanned = false
				CraftForge:UpdateTradeSkillWindow()
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			for i, inventorySlot in ipairs(inventorySlots) do
				info.text = inventorySlot
				info.func = function()
					CraftForge.SetSlotFilter(i)
				end
				info.hasArrow = false
				UIDropDownMenu_AddButton(info, level)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
			info.hasArrow = false
			info.keepShownOnClick = true
			info.isNotRadio = true
			info.notCheckable = true
			info.text = CHECK_ALL
			info.func = function()
				C_TradeSkillUI.ClearRecipeSourceTypeFilter()
				UIDropDownMenu_Refresh(CraftForgeFilterDropMenu, 3, 2)
				CraftForge.dataScanned = false
				CraftForge:UpdateTradeSkillWindow()
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				CraftForge:SetDefaultFilters()
				UIDropDownMenu_Refresh(CraftForgeFilterDropMenu, 3, 2)
				CraftForge.dataScanned = false
				CraftForge:UpdateTradeSkillWindow()
			end
			UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			for i = 1, C_PetJournal.GetNumPetSources() do
				if C_TradeSkillUI.IsAnyRecipeFromSource(i) then
					info.text = _G["BATTLE_PET_SOURCE_" .. i]
					info.func = function(_, _, _, value)
						C_TradeSkillUI.SetRecipeSourceTypeFilter(i, not value)
						CraftForge.dataScanned = false
						CraftForge:UpdateTradeSkillWindow()
					end
					info.checked = function()
						return not C_TradeSkillUI.IsRecipeSourceTypeFiltered(i)
					end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 3 then
			local categories = {C_TradeSkillUI.GetCategories()}
			for i, categoryId in ipairs(categories) do
				local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryId)
				info.text = categoryData.name
				info.func = function()
					CraftForge.SetSlotFilter(nil, categoryId, nil)
				end
--
-- Uncomment the line below (and the level 3 code block) to enable subcategories
--
--				info.hasArrow = select("#", C_TradeSkillUI.GetSubCategories(categoryId)) > 0
				info.keepShownOnClick = true;
				info.value = categoryId
				UIDropDownMenu_AddButton(info, level)
			end
		end

	elseif level == 3 then
--[[
--
-- Blizzard doesn't implement subcategories in 12.0.5
--
		local categoryID = UIDROPDOWNMENU_MENU_VALUE
		local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryID)
		local subCategories = { C_TradeSkillUI.GetSubCategories(categoryID) }
		for i, subCategoryID in ipairs(subCategories) do
			local subCategoryData = C_TradeSkillUI.GetCategoryInfo(subCategoryID)
			info.text = subCategoryData.name
			info.func = function()
				CraftForge.SetSlotFilter(nil, categoryID, subCategoryId)
			end
			info.notCheckable = false
			info.keepShownOnClick = true
			info.value = subCategoryId
			UIDropDownMenu_AddButton(info, level)
		end
--]]
	end
end

function CraftForge.SetSlotFilter(inventorySlotIndex, categoryId, subCategoryId)
	--DA.DEBUG(0,"SetSlotFilter("..tostring(inventorySlotIndex)..", "..tostring(categoryId)..", "..tostring(subCategoryId)..")")
	C_TradeSkillUI.ClearInventorySlotFilter()
	C_TradeSkillUI.ClearRecipeCategoryFilter()

	if inventorySlotIndex then
		C_TradeSkillUI.SetInventorySlotFilter(inventorySlotIndex, true, true)
	end

	if categoryId or subCategoryId then
		C_TradeSkillUI.SetRecipeCategoryFilter(categoryId, subCategoryId)
	end
	CraftForge.dataScanned = false
	CraftForge:UpdateTradeSkillWindow()
end

function CraftForge:SetDefaultFilters()
	--DA.DEBUG(0,"SetDefaultFilters()")
	C_TradeSkillUI.SetShowLearned(true)
	C_TradeSkillUI.SetShowUnlearned(true)
	C_TradeSkillUI.SetOnlyShowMakeableRecipes(false)
	C_TradeSkillUI.SetOnlyShowSkillUpRecipes(false)
	C_TradeSkillUI.SetOnlyShowFirstCraftRecipes(false)
	C_TradeSkillUI.ClearInventorySlotFilter()
	Professions.SetAllSourcesFiltered(false)
	C_TradeSkillUI.ClearRecipeSourceTypeFilter()
	C_TradeSkillUI.ClearRecipeCategoryFilter()
end

--
-- Currently unused
--
function CraftForge:GetCurrentFilterSet()
	DA.DEBUG(0,"GetCurrentFilterSet()")
	local filterSet =
	{
		textFilter = C_TradeSkillUI.GetRecipeItemNameFilter(),
		showOnlyMakeable = C_TradeSkillUI.GetOnlyShowMakeableRecipes(),
		showOnlySkillUps = C_TradeSkillUI.GetOnlyShowSkillUpRecipes(),
		showOnlyFirstCraft = C_TradeSkillUI.GetOnlyShowFirstCraftRecipes(),
		professionInfo = C_TradeSkillUI.GetChildProfessionInfo(),
		showUnlearned = C_TradeSkillUI.GetShowUnlearned(),
		showLearned = C_TradeSkillUI.GetShowLearned(),
		sourceTypeFilter = C_TradeSkillUI.GetSourceTypeFilter(),
	}
	filterSet.invTypeFilters = {}
	for idx = 1, C_TradeSkillUI.GetAllFilterableInventorySlotsCount() do
		filterSet.invTypeFilters[idx] = C_TradeSkillUI.IsInventorySlotFiltered(idx)
	end
	return filterSet
end

--
-- Currently unused
--
function CraftForge:ApplyfilterSet(filterSet)
	DA.DEBUG(0,"ApplyfilterSet("..DA.DUMP1(filterSet)..")")
	if filterSet then
		C_TradeSkillUI.SetShowLearned(filterSet.showLearned)
		C_TradeSkillUI.SetShowUnlearned(filterSet.showUnlearned)
		C_TradeSkillUI.SetOnlyShowMakeableRecipes(filterSet.showOnlyMakeable)
		C_TradeSkillUI.SetOnlyShowSkillUpRecipes(filterSet.showOnlySkillUps)
		C_TradeSkillUI.SetOnlyShowFirstCraftRecipes(filterSet.showOnlyFirstCraft)
		C_TradeSkillUI.SetSourceTypeFilter(filterSet.sourceTypeFilter)
		for idx, filtered in ipairs(filterSet.invTypeFilters) do
			C_TradeSkillUI.SetInventorySlotFilter(idx, not filtered)
		end
	else
		Professions.OnRecipeListSearchTextChanged("")
		Professions.SetDefaultFilters();
	end
end
