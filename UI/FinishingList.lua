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

function CraftForge:FinishingListToggleHaveItems()
	self.db.profile.hide_unowned = not self.db.profile.hide_unowned
	self:HideFinishingList()
end

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local num_buttons = 0
local function get_button(i)
	local button = _G["CraftForgeFinishingListButton"..i]
	if not button then
		button = CreateFrame("Button", "CraftForgeFinishingListButton"..i, CraftForgeFinishingListParent, "CraftForgeFinishingListItemTemplate")
		button:SetParent(CraftForgeFinishingListParent)
		button:SetPoint("TOPLEFT", "CraftForgeFinishingListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(CraftForgeFinishingListParent:GetFrameLevel() + 1)
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

CRAFTFORGE_FINISHING_LIST_HEIGHT = 16
local function createFinishingListFrame(self)
	--DA.DEBUG(0,"createFinishingListFrame")
	local frame = CraftForgeFinishingList
	if not frame then
		return nil
	end
	if TSM_API and CraftForge.db.profile.tsm_compat then
		frame:SetFrameStrata("TOOLTIP")
	else
		frame:SetFrameStrata("HIGH")
	end
	if not frame.SetBackdrop then
		Mixin(frame, BackdropTemplateMixin)
	end
	frame:SetBackdrop(FrameBackdrop)
	frame:SetBackdropColor(0.1, 0.1, 0.1)
--
-- A title bar stolen from the Ace2 Waterfall window.
--
	local r,g,b = 0, 0.7, 0; -- dark green
	local titlebar = frame:CreateTexture(nil,"BACKGROUND")
	local titlebar2 = frame:CreateTexture(nil,"BACKGROUND")
	titlebar:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-4)
	titlebar:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-4)
	titlebar:SetHeight(13)
	titlebar2:SetPoint("TOPLEFT",titlebar,"BOTTOMLEFT",0,0)
	titlebar2:SetPoint("TOPRIGHT",titlebar,"BOTTOMRIGHT",0,0)
	titlebar2:SetHeight(13)
	titlebar:SetColorTexture(r,g,b,1)
	titlebar2:SetColorTexture(r,g,b,1)
	local title = CreateFrame("Frame",nil,frame)
	title:SetPoint("TOPLEFT",titlebar,"TOPLEFT",0,0)
	title:SetPoint("BOTTOMRIGHT",titlebar2,"BOTTOMRIGHT",0,0)
	local titletext = title:CreateFontString("CraftForgeFinishingListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("CraftForge: Finishing Reagents")
	frame.titletext = titletext
	CraftForgeFinishingHaveItemsText:SetText(OPTIONAL_REAGENT_LIST_HIDE_UNOWNED)
	CraftForgeFinishingHaveItems:SetChecked(CraftForge.db.profile.hide_unowned)
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = CraftForgeFinishingListParent
	if not backdrop.SetBackdrop then
		Mixin(backdrop, BackdropTemplateMixin)
	end
	if TSM_API and CraftForge.db.profile.tsm_compat then
		backdrop:SetFrameStrata("HIGH")
	end
	backdrop:SetBackdrop(ControlBackdrop)
	backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6)
	backdrop:SetBackdropColor(0.05, 0.05, 0.05)
	backdrop:SetResizable(true)
	local FinishingListLocation = {
		prefix = "FinishingListLocation_"
	}
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, FinishingListLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	CraftForge:EnableResize(frame, 420, 240, CraftForge.UpdateFinishingListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
--
-- Adjust the button height
--
	CRAFTFORGE_FINISHING_LIST_HEIGHT = math.max(CraftForgeFinishingListButton1:GetHeight(), CRAFTFORGE_FINISHING_LIST_HEIGHT)
	return frame
end

--
-- Called to update the finishing list window
--
function CraftForge:UpdateFinishingListWindow()
	--DA.DEBUG(0,"UpdateFinishingListWindow()")
	self.InProgress.finishing = true
	local numItems
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, self.selectedSkill)
	if self.cachedFinishingList then
		--DA.DEBUG(1,"UpdateFinishingListWindow: cachedFinishingList= ",DA.DUMP1(self.cachedFinishingList))
		numItems = #self.cachedFinishingList.reagents
	else
		return
	end
	local height = CraftForgeFinishingListParent:GetHeight()
	local width = CraftForgeFinishingListParent:GetWidth() - 30 -- Allow for scrollbars
	--DA.DEBUG(1,"UpdateFinishingListWindow: height= "..tostring(height)..", CRAFTFORGE_FINISHING_LIST_HEIGHT= "..tostring(CRAFTFORGE_FINISHING_LIST_HEIGHT))
	--DA.DEBUG(1,"UpdateFinishingListWindow: CraftForgeFinishingListParent width= "..tostring(width))
	local button_count = height / CRAFTFORGE_FINISHING_LIST_HEIGHT
	button_count = math.floor(button_count) - 1
	--DA.DEBUG(1,"UpdateFinishingListWindow: numItems= "..tostring(numItems)..", button_count= "..tostring(button_count))
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(CraftForgeFinishingListList,		-- frame
							numItems,						-- num items
							button_count,					-- num to display
							CRAFTFORGE_FINISHING_LIST_HEIGHT)	-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(CraftForgeFinishingListList)
	--DA.DEBUG(1,"UpdateFinishingListWindow: itemOffset= "..tostring(itemOffset))
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
			local freagentID = self.cachedFinishingList.reagents[itemIndex].itemID
			button.freagentID = freagentID
			local freagentName, freagentLink = C_Item.GetItemInfo(freagentID)
			local freagentQuality
			if not freagentName then
				CraftForge.finishingDataNeeded = true
				C_Item.RequestLoadItemDataByID(freagentID)
				freagentName = "item:"..tostring(freagentID)
			end
			if freagentLink then
				freagentQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(freagentLink)
			end
			needed:SetText("")
			needed:Show()
			local bags, num, craftable = self:GetInventory(self.currentPlayer, freagentID)
			local count_text
			if craftable > 0 then
				count_text = string.format("[%d/%d]", num, craftable)
			else
				count_text = string.format("[%d]", num)
			end
			count:SetText(count_text)
			count:Show()
			if freagentQuality then
--				freagentName = freagentName..C_Texture.GetCraftingReagentQualityChatIcon(freagentQuality)
				freagentName = freagentName.."|A:Professions-ChatIcon-Quality-Tier"..freagentQuality..":17:17|a"
			end
			text:SetText(freagentName)
			text:SetWordWrap(false)
			text:SetWidth(width - (needed:GetWidth() + count:GetWidth()))
			text:Show()
			local texture =C_Item.GetItemIconByID(freagentID)
			icon:SetNormalTexture(texture)
			icon:Show()
			button:SetID(itemIndex)
			button:Show()
		else
			--DA.DEBUG(1,"UpdateFinishingListWindow: Hide unused button")
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
	self.InProgress.finishing = false
end

--
-- Updates the scrollbar when a scroll event happens
--
function CraftForge:FinishingList_OnScroll()
	CraftForge:UpdateFinishingListWindow()
end

--
-- Functions to show and hide the FinishingList
--
function CraftForge:DisplayFinishingList()
	--DA.DEBUG(0,"DisplayFinishingList()")
	if not self.FinishingList then
		self.FinishingList = createFinishingListFrame(self)
	end
	if not self.FinishingList:IsVisible() then
		self.FinishingList.titletext:SetText("CraftForge: Finishing Reagents")
		self.FinishingList:Show()
	end
end

function CraftForge:HideFinishingList(clear)
	--DA.DEBUG(0,"HideFinishingList()")
	if self.FinishingList then
		self.FinishingList:Hide()
	end
	if clear then
		self.cachedFinishingList = nil
	end
end

--
-- Called when an finishing reagent button in the CraftForge detail frame is clicked.
-- This finishing list is used for selecting Finishing reagents.
-- This has the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function CraftForge:FinishingReagentOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"FinishingReagentOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	CraftForgeFinishingHaveItems:Hide()
	local thisFinishing
--
-- Optional reagents are identified with a negative index.
-- Finishing reagents are identified with a +200 offset.
-- Note that this index is not the dataSlotIndex needed by C_TradeSkillUI.CraftRecipe
--
	thisFinishing = recipe.finishingData[reagentIndex - 200]
	self.cachedFinishingIndex = reagentIndex - 200
	--DA.DEBUG(1,"FinishingReagentOnClick: thisFinishing= "..DA.DUMP(thisFinishing))
	self.cachedFinishingList = thisFinishing.schematic
	--DA.DEBUG(1,"FinishingReagentOnClick: cachedFinishingIndex= "..tostring(self.cachedFinishingIndex)..", cachedFinishingList= "..DA.DUMP1(self.cachedFinishingList))
--
-- Left-click selects and right-click deselects.
--
	if mouse == "LeftButton" then
		self:UpdateFinishingListWindow()
	elseif mouse == "RightButton" then
		if self.finishingSelected then
			self.finishingSelected[self.cachedFinishingIndex] = nil
		end
		self:UpdateDetailWindow(skillIndex)
	end
end

--
-- Returns a link for the finishing reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function CraftForge:GetFinishingItemLink(skillIndex, index)
	--DA.DEBUG(0,"GetFinishingItemLink("..tostring(skillIndex)..", "..tostring(index)..")")
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and self.cachedFinishingList then
			local freagentID = self.cachedFinishingList.reagents[index].itemID
			local name, link = C_Item.GetItemInfo(freagentID)
			return link
		end
	end
end

--
-- Called when then mouse enters a finishing button
--
function CraftForge:FinishingButtonOnEnter(button, skillIndex, finishingIndex)
	--DA.DEBUG(0,"FinishingButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(finishingIndex)..")")
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
	--DA.DEBUG(1,"FinishingButtonOnEnter: "..tostring(button.freagentID))
	tip:SetHyperlink("item:"..button.freagentID)
	tip:Show()
	CursorUpdate(button)
end

--
-- called then the mouse leaves an finishing button
--
function CraftForge:FinishingButtonOnLeave(button, skillIndex, finishingIndex)
	--DA.DEBUG(0,"FinishingButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(finishingIndex)..")")
	local tip = GameTooltip -- CraftForgeTradeskillTooltip
	if CraftForge.db.profile.scale_tooltip then
		tip:SetScale(CraftForge.gttScale)
	end
	tip:Hide()
	ResetCursor()
end

--
-- Called when an finishing reagent in the FinishingList is clicked.
-- This finishing list is used for selecting Finishing and Finishing reagents.
-- These all have the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function CraftForge:FinishingButtonOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"FinishingButtonOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	--DA.DEBUG(1,"FinishingButtonOnClick: cachedFinishingIndex= "..tostring(self.cachedFinishingIndex)..", cachedFinishingList= "..DA.DUMP(self.cachedFinishingList))
	local freagentID = self.cachedFinishingList.reagents[reagentIndex].itemID
	local freagentSlot = self.cachedFinishingList.dataSlotIndex
	if not self.finishingSelected then
		self.finishingSelected = {}
	end
	if mouse == "LeftButton" then
		self.finishingSelected[self.cachedFinishingIndex] = { itemID = freagentID, quantity = 1, dataSlotIndex = freagentSlot, }
	elseif mouse == "RightButton" then
		self.finishingSelected[self.cachedFinishingIndex] = nil
	end
	--DA.DEBUG(1,"FinishingButtonOnClick: cachedFinishingIndex= "..tostring(self.cachedFinishingIndex)..", freagentID= "..tostring(freagentID)..", finishingSelected= "..DA.DUMP(self.finishingSelected))
	self:UpdateDetailWindow(skillIndex)
end
