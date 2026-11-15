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

local L = LibStub("AceLocale-3.0"):GetLocale("CraftForge")

function CraftForge:SalvageListToggleHaveItems()
	self.db.profile.hide_unowned = not self.db.profile.hide_unowned
	self:HideSalvageList()
end

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local num_buttons = 0
local function get_button(i)
	local button = _G["CraftForgeSalvageListButton"..i]
	if not button then
		button = CreateFrame("Button", "CraftForgeSalvageListButton"..i, CraftForgeSalvageListParent, "CraftForgeSalvageListItemTemplate")
		button:SetParent(CraftForgeSalvageListParent)
		button:SetPoint("TOPLEFT", "CraftForgeSalvageListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(CraftForgeSalvageListParent:GetFrameLevel() + 1)
	end
	return button
end

--
-- Stolen from the Waterfall Ace2 addon.  Used for the backdrop of the scrollframe
--
local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}-- Additional things to used to modify the XML created frame
local FrameBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 30, bottom = 3 }
}

CRAFTFORGE_SALVAGE_LIST_HEIGHT = 16
local function createSalvageListFrame(self)
	--DA.DEBUG(0,"createSalvageListFrame")
	local frame = CraftForgeSalvageList
	if not frame then
		return nil
	end
	local UIStyle = CraftForge.UIStyle
	if TSM_API and CraftForge.db.profile.tsm_compat then
		frame:SetFrameStrata("TOOLTIP")
	else
		frame:SetFrameStrata("HIGH")
	end
	UIStyle.SkinFrame(frame, false)
	local titletext = frame:CreateFontString("CraftForgeSalvageListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -1)
	titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -1)
	titletext:SetHeight(26)
	titletext:SetJustifyH("CENTER")
	titletext:SetText("CraftForge: Salvage Reagents")
	UIStyle.StyleHeaderBar(frame, titletext, 1)
	if CraftForgeSalvageListCloseButton then UIStyle.SkinCloseButton(CraftForgeSalvageListCloseButton) end
	frame.titletext = titletext
	CraftForgeSalvageHaveItemsText:SetText(OPTIONAL_REAGENT_LIST_HIDE_UNOWNED)
	CraftForgeSalvageHaveItems:SetChecked(CraftForge.db.profile.hide_unowned)
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = CraftForgeSalvageListParent
	if TSM_API and CraftForge.db.profile.tsm_compat then
		backdrop:SetFrameStrata("HIGH")
	end
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
	if CraftForgeSalvageList then UIStyle.StyleScrollBar(CraftForgeSalvageList) end
	local SalvageListLocation = {
		prefix = "SalvageListLocation_"
	}
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, SalvageListLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	CraftForge:EnableResize(frame, 420, 240, CraftForge.UpdateSalvageListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
--
-- Adjust the button height
--
	CRAFTFORGE_SALVAGE_LIST_HEIGHT = math.max(CraftForgeModifiedListButton1:GetHeight(), CRAFTFORGE_SALVAGE_LIST_HEIGHT)
	return frame
end

--
-- Called to update the salvage list window
--
function CraftForge:UpdateSalvageListWindow()
	DA.DEBUG(0,"UpdateSalvageListWindow()")
	self.InProgress.salvage = true
	local numItems
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, self.selectedSkill)
	if recipe.salvage then
		self.cachedSalvageList.reagents = recipe.salvage
	end
	if self.cachedSalvageList then
		--DA.DEBUG(1,"UpdateSalvageListWindow: cachedSalvageList= ",DA.DUMP1(self.cachedSalvageList))
		numItems = #self.cachedSalvageList
		--DA.DEBUG(1,"UpdateSalvageListWindow: numItems= "..tostring(numItems))
	else
		return
	end
	local height = CraftForgeSalvageListParent:GetHeight()	local buttonH = CraftForgeOptionalListButton1:GetHeight()
	local width = CraftForgeSalvageListParent:GetWidth() - 30 -- Allow for scrollbars
	--DA.DEBUG(1,"UpdateSalvageListWindow: height= "..tostring(height)..", CRAFTFORGE_SALVAGE_LIST_HEIGHT= "..tostring(CRAFTFORGE_SALVAGE_LIST_HEIGHT))
	--DA.DEBUG(1,"UpdateSalvageListWindow: CraftForgeSalvageListParent width= "..tostring(width))
	local button_count = height / CRAFTFORGE_SALVAGE_LIST_HEIGHT
	button_count = math.floor(button_count) - 1
	--DA.DEBUG(1,"UpdateSalvageListWindow: numItems= "..tostring(numItems)..", button_count= "..tostring(button_count)..", num_buttons= "..tostring(num_buttons))
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(CraftForgeSalvageListList,			-- frame
							numItems,						-- num items
							button_count,					-- num to display
							CRAFTFORGE_SALVAGE_LIST_HEIGHT)	-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(CraftForgeSalvageListList)
	--DA.DEBUG(1,"UpdateSalvageListWindow: itemOffset= "..tostring(itemOffset))
	for i=1, button_count, 1 do
		num_buttons = math.max(num_buttons, i)
		local itemIndex = i + itemOffset
		local  button = get_button(i)
		local    text = _G[button:GetName() .. "Text"]
		local    icon = _G[button:GetName() .. "Icon"]
		local   count = _G[button:GetName() .. "Count"]
		local  needed = _G[button:GetName() .. "Needed"]
		button:SetWidth(width)
		if itemIndex <= numItems then
			local sreagentID = self.cachedSalvageList[itemIndex].itemID
			button.sreagentID = sreagentID
			local sreagentName, sreagentLink = C_Item.GetItemInfo(sreagentID)
			local sreagentQuality
			if not sreagentName then
				CraftForge.salvageDataNeeded = true
				C_Item.RequestLoadItemDataByID(sreagentID)
				sreagentName = "item:"..tostring(sreagentID)
			end
			if sreagentLink then
				sreagentQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(sreagentLink)
			end
			needed:SetText("")
			needed:Show()
			local bags, num, craftable = self:GetInventory(self.currentPlayer, sreagentID)
			local count_text
			if craftable > 0 then
				count_text = string.format("[%d/%d]", num, craftable)
			else
				count_text = string.format("[%d]", num)
			end
			count:SetText(count_text)
			count:Show()
			if sreagentQuality then
--				sreagentName = sreagentName..C_Texture.GetCraftingReagentQualityChatIcon(sreagentQuality)
				sreagentName = sreagentName.."|A:Professions-ChatIcon-Quality-Tier"..sreagentQuality..":17:17|a"
			end
			text:SetText(sreagentName)
			text:SetWordWrap(false)
			text:SetWidth(width - (needed:GetWidth() + count:GetWidth()))
			text:Show()
			local texture =C_Item.GetItemIconByID(sreagentID)
			icon:SetNormalTexture(texture)
			icon:Show()
			button:SetID(itemIndex)
			button:Show()
		else
			--DA.DEBUG(1,"UpdateSalvageListWindow: Hide unused button")
			text:SetText("")
			text:Hide()
			icon:Hide()
			count:SetText("")
			count:Hide()
			needed:SetText("")
			needed:Hide()
			button:SetID(itemIndex * 100)
			button:Hide()
		end
	end
--
-- Hide any of the buttons that we created, but don't need right now
--
	for i = button_count+1, num_buttons, 1 do
		local button = get_button(i)
		button:Hide()
	end
	self.InProgress.salvage = false
end

--
-- Updates the scrollbar when a scroll event happens
--
function CraftForge:SalvageList_OnScroll()
	CraftForge:UpdateSalvageListWindow()
end

--
-- Functions to show and hide the SalvageList
--
function CraftForge:DisplaySalvageList()
	--DA.DEBUG(0,"DisplaySalvageList()")
	if not self.SalvageList then
		self.SalvageList = createSalvageListFrame(self)
	end
	if not self.SalvageList:IsVisible() then
		self.SalvageList.titletext:SetText("CraftForge: Salvage Reagents")
		self.SalvageList:Show()
	end
end

function CraftForge:HideSalvageList(clear)
	--DA.DEBUG(0,"HideSalvageList()")
	if self.SalvageList then
		self.SalvageList:Hide()
	end
	if clear then
		self.cachedSalvageList = nil
	end
end

--
-- Called when an salvage reagent button in the CraftForge detail frame is clicked.
-- This salvage list is used for selecting Salvage, Salvage, and Finishing reagents.
-- These all have the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function CraftForge:SalvageReagentOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"SalvageReagentOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	CraftForgeSalvageHaveItems:Show()
	self.cachedSalvageList = {}
	--DA.DEBUG(1,"SalvageReagentOnClick: salvage= "..DA.DUMP1(recipe.salvage))
	local j = 1
	for i=1, #recipe.salvage,1 do
		if self.db.profile.hide_unowned then
			local bags, num, craftable = self:GetInventory(self.currentPlayer, recipe.salvage[i])
			if num > 0 or craftable > 0 then
				self.cachedSalvageList[j] = {}
				self.cachedSalvageList[j].itemID = recipe.salvage[i]
				j = j + 1
			end
		else
			self.cachedSalvageList[i] = {}
			self.cachedSalvageList[i].itemID = recipe.salvage[i]
		end
	end
	self.cachedSalvageIndex = reagentIndex * -1
	--DA.DEBUG(1,"SalvageReagentOnClick: cachedSalvageIndex= "..tostring(self.cachedSalvageIndex)..", cachedSalvageList= "..DA.DUMP1(self.cachedSalvageList))
--
-- Left-click selects and right-click deselects.
--
	if mouse == "LeftButton" then
		self:UpdateSalvageListWindow()
	elseif mouse == "RightButton" then
		if self.salvageSelected then
			self.salvageSelected[self.cachedSalvageIndex] = nil
		end
		self:UpdateDetailWindow(skillIndex)
	end
end

--
-- Returns a link for the salvage reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function CraftForge:GetSalvageItemLink(skillIndex, index)
	--DA.DEBUG(0,"GetSalvageItemLink("..tostring(skillIndex)..", "..tostring(index)..")")
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and self.cachedSalvageList then
			local sreagentID = self.cachedSalvageList[index].itemID
			local name, link = C_Item.GetItemInfo(sreagentID)
			return link
		end
	end
end

--
-- Called when then mouse enters a salvage button
--
function CraftForge:SalvageButtonOnEnter(button, skillIndex, salvageIndex)
	--DA.DEBUG(0,"SalvageButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(salvageIndex)..")")
	local tip = GameTooltip -- CraftForgeTradeskillTooltip
	tip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
	if CraftForge.db.profile.scale_tooltip then
		local uiScale = 1.0;
		if ( GetCVar("useUiScale") == "1" ) then
			uiScale = tonumber(GetCVar("uiscale"))
		end
		if CraftForge.db.profile.ttscale then
			uiScale = uiScale * CraftForge.db.profile.ttscale
		end
		tip:SetScale(uiScale)
	end
	--DA.DEBUG(1,"SalvageButtonOnEnter: "..tostring(button.sreagentID))
	tip:SetHyperlink("item:"..button.sreagentID)
	tip:Show()
	CursorUpdate(button)
end

--
-- called then the mouse leaves an salvage button
--
function CraftForge:SalvageButtonOnLeave(button, skillIndex, salvageIndex)
	--DA.DEBUG(0,"SalvageButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(salvageIndex)..")")
	local tip = GameTooltip -- CraftForgeTradeskillTooltip
	if CraftForge.db.profile.scale_tooltip then
		tip:SetScale(CraftForge.gttScale)
	end
	tip:Hide()
	ResetCursor()
end

--
-- Called when an salvage reagent in the SalvageList is clicked.
-- This salvage list is used for selecting Salvage, Salvage, and Finishing reagents.
-- These all have the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function CraftForge:SalvageButtonOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"SalvageButtonOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	--DA.DEBUG(1,"SalvageButtonOnClick: cachedSalvageIndex= "..tostring(self.cachedSalvageIndex)..", cachedSalvageList= "..DA.DUMP(self.cachedSalvageList))
	local sreagentID = self.cachedSalvageList[reagentIndex].itemID
	if not self.salvageSelected then
		self.salvageSelected = {}
	end
	if mouse == "LeftButton" then
		self.salvageSelected[self.cachedSalvageIndex] = sreagentID
--		self:HideSalvageList()
	elseif mouse == "RightButton" then
		self.salvageSelected[self.cachedSalvageIndex] = nil
	end
	--DA.DEBUG(1,"SalvageButtonOnClick: cachedSalvageIndex= "..tostring(self.cachedSalvageIndex)..", sreagentID= "..tostring(sreagentID)..", salvageSelected= "..DA.DUMP(self.salvageSelected))
	self:UpdateDetailWindow(skillIndex)
end
