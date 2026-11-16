local addonName,addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
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

local L = LibStub("AceLocale-3.0"):GetLocale("CraftBench")

function CraftBench:FinishingListToggleHaveItems()
	self.db.profile.hide_unowned = not self.db.profile.hide_unowned
	self:HideFinishingList()
end

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local num_buttons = 0
local function get_button(i)
	local button = _G["CraftBenchFinishingListButton"..i]
	if not button then
		button = CreateFrame("Button", "CraftBenchFinishingListButton"..i, CraftBenchFinishingListParent, "CraftBenchFinishingListItemTemplate")
		button:SetParent(CraftBenchFinishingListParent)
		button:SetPoint("TOPLEFT", "CraftBenchFinishingListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(CraftBenchFinishingListParent:GetFrameLevel() + 1)
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

CRAFTBENCH_FINISHING_LIST_HEIGHT = 16
local function createFinishingListFrame(self)
	--DA.DEBUG(0,"createFinishingListFrame")
	local frame = CraftBenchFinishingList
	if not frame then
		return nil
	end
	local UIStyle = CraftBench.UIStyle
	if TSM_API and CraftBench.db.profile.tsm_compat then
		frame:SetFrameStrata("TOOLTIP")
	else
		frame:SetFrameStrata("HIGH")
	end
	UIStyle.SkinFrame(frame, false)
	local titletext = frame:CreateFontString("CraftBenchFinishingListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -1)
	titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -1)
	titletext:SetHeight(26)
	titletext:SetJustifyH("CENTER")
	titletext:SetText("CraftBench: Finishing Reagents")
	UIStyle.StyleHeaderBar(frame, titletext, 1)
	if CraftBenchFinishingListCloseButton then UIStyle.SkinCloseButton(CraftBenchFinishingListCloseButton) end
	frame.titletext = titletext
	CraftBenchFinishingHaveItemsText:SetText(OPTIONAL_REAGENT_LIST_HIDE_UNOWNED)
	CraftBenchFinishingHaveItems:SetChecked(CraftBench.db.profile.hide_unowned)
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = CraftBenchFinishingListParent
	if TSM_API and CraftBench.db.profile.tsm_compat then
		backdrop:SetFrameStrata("HIGH")
	end
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
	if CraftBenchFinishingList then UIStyle.StyleScrollBar(CraftBenchFinishingList) end
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
	CraftBench:EnableResize(frame, 420, 240, CraftBench.UpdateFinishingListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
--
-- Adjust the button height
--
	CRAFTBENCH_FINISHING_LIST_HEIGHT = math.max(CraftBenchFinishingListButton1:GetHeight(), CRAFTBENCH_FINISHING_LIST_HEIGHT)
	return frame
end

--
-- Called to update the finishing list window
--
function CraftBench:UpdateFinishingListWindow()
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
	local height = CraftBenchFinishingListParent:GetHeight()
	local width = CraftBenchFinishingListParent:GetWidth() - 30 -- Allow for scrollbars
	--DA.DEBUG(1,"UpdateFinishingListWindow: height= "..tostring(height)..", CRAFTBENCH_FINISHING_LIST_HEIGHT= "..tostring(CRAFTBENCH_FINISHING_LIST_HEIGHT))
	--DA.DEBUG(1,"UpdateFinishingListWindow: CraftBenchFinishingListParent width= "..tostring(width))
	local button_count = height / CRAFTBENCH_FINISHING_LIST_HEIGHT
	button_count = math.floor(button_count) - 1
	--DA.DEBUG(1,"UpdateFinishingListWindow: numItems= "..tostring(numItems)..", button_count= "..tostring(button_count))
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(CraftBenchFinishingListList,		-- frame
							numItems,						-- num items
							button_count,					-- num to display
							CRAFTBENCH_FINISHING_LIST_HEIGHT)	-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(CraftBenchFinishingListList)
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
				CraftBench.finishingDataNeeded = true
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
function CraftBench:FinishingList_OnScroll()
	CraftBench:UpdateFinishingListWindow()
end

--
-- Functions to show and hide the FinishingList
--
function CraftBench:DisplayFinishingList()
	--DA.DEBUG(0,"DisplayFinishingList()")
	if not self.FinishingList then
		self.FinishingList = createFinishingListFrame(self)
	end
	if not self.FinishingList:IsVisible() then
		self.FinishingList.titletext:SetText("CraftBench: Finishing Reagents")
		self.FinishingList:Show()
	end
end

function CraftBench:HideFinishingList(clear)
	--DA.DEBUG(0,"HideFinishingList()")
	if self.FinishingList then
		self.FinishingList:Hide()
	end
	if clear then
		self.cachedFinishingList = nil
	end
end

--
-- Called when an finishing reagent button in the CraftBench detail frame is clicked.
-- This finishing list is used for selecting Finishing reagents.
-- This has the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function CraftBench:FinishingReagentOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"FinishingReagentOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	CraftBenchFinishingHaveItems:Hide()
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
function CraftBench:GetFinishingItemLink(skillIndex, index)
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
function CraftBench:FinishingButtonOnEnter(button, skillIndex, finishingIndex)
	--DA.DEBUG(0,"FinishingButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(finishingIndex)..")")
	local tip = GameTooltip -- CraftBenchTradeskillTooltip
	tip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
	if CraftBench.db.profile.scale_tooltip then
		local uiScale = 1.0;
		if ( GetCVar("useUiScale") == "1" ) then
			uiScale = tonumber(GetCVar("uiscale"))
		end
		if CraftBench.db.profile.ttscale then
			uiScale = uiScale * CraftBench.db.profile.ttscale
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
function CraftBench:FinishingButtonOnLeave(button, skillIndex, finishingIndex)
	--DA.DEBUG(0,"FinishingButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(finishingIndex)..")")
	local tip = GameTooltip -- CraftBenchTradeskillTooltip
	if CraftBench.db.profile.scale_tooltip then
		tip:SetScale(CraftBench.gttScale)
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
function CraftBench:FinishingButtonOnClick(button, mouse, skillIndex, reagentIndex)
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
