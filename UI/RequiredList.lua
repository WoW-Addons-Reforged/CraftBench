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

function CraftBench:RequiredListToggleHaveItems()
	self.db.profile.hide_unowned = not self.db.profile.hide_unowned
	self:HideRequiredList()
end

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local num_buttons = 0
local function get_button(i)
	local button = _G["CraftBenchRequiredListButton"..i]
	if not button then
		button = CreateFrame("Button", "CraftBenchRequiredListButton"..i, CraftBenchRequiredListParent, "CraftBenchRequiredListItemTemplate")
		button:SetParent(CraftBenchRequiredListParent)
		button:SetPoint("TOPLEFT", "CraftBenchRequiredListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(CraftBenchRequiredListParent:GetFrameLevel() + 1)
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

CRAFTBENCH_REQUIRED_LIST_HEIGHT = 16
local function createRequiredListFrame(self)
	--DA.DEBUG(0,"createRequiredListFrame")
	local frame = CraftBenchRequiredList
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
	local titletext = frame:CreateFontString("CraftBenchRequiredListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -1)
	titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -1)
	titletext:SetHeight(26)
	titletext:SetJustifyH("CENTER")
	titletext:SetText("CraftBench: Required Reagents")
	UIStyle.StyleHeaderBar(frame, titletext, 1)
	if CraftBenchRequiredListCloseButton then UIStyle.SkinCloseButton(CraftBenchRequiredListCloseButton) end
	frame.titletext = titletext
	CraftBenchRequiredHaveItemsText:SetText(OPTIONAL_REAGENT_LIST_HIDE_UNOWNED)
	CraftBenchRequiredHaveItems:SetChecked(CraftBench.db.profile.hide_unowned)
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = CraftBenchRequiredListParent
	if TSM_API and CraftBench.db.profile.tsm_compat then
		backdrop:SetFrameStrata("HIGH")
	end
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
	if CraftBenchRequiredList then UIStyle.StyleScrollBar(CraftBenchRequiredList) end
	local RequiredListLocation = {
		prefix = "RequiredListLocation_"
	}
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, RequiredListLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	CraftBench:EnableResize(frame, 420, 240, CraftBench.UpdateRequiredListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
--
-- Adjust the button height
--
	CRAFTBENCH_REQUIRED_LIST_HEIGHT = math.max(CraftBenchRequiredListButton1:GetHeight(), CRAFTBENCH_REQUIRED_LIST_HEIGHT)
	return frame
end

--
-- Called to update the optional list window
--
function CraftBench:UpdateRequiredListWindow()
	--DA.DEBUG(0,"UpdateRequiredListWindow()")
	self.InProgress.optional = true
	local numItems
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, self.selectedSkill)
	if self.cachedRequiredList then
		numItems = #self.cachedRequiredList.reagents
		--DA.DEBUG(1,"UpdateRequiredListWindow: cachedRequiredList= ",DA.DUMP1(self.cachedRequiredList))
	else
		return
	end
	local height = CraftBenchRequiredListParent:GetHeight() - 30 -- Allow for frame border
	local width = CraftBenchRequiredListParent:GetWidth() - 30 -- Allow for scrollbars
	--DA.DEBUG(1,"UpdateRequiredListWindow: CraftBenchRequiredListParent height= "..tostring(height)..", CRAFTBENCH_REQUIRED_LIST_HEIGHT= "..tostring(CRAFTBENCH_REQUIRED_LIST_HEIGHT))
	--DA.DEBUG(1,"UpdateRequiredListWindow: CraftBenchRequiredListParent width= "..tostring(width))
	local button_count = height / CRAFTBENCH_REQUIRED_LIST_HEIGHT
	button_count = math.floor(button_count) - 1
	--DA.DEBUG(1,"UpdateRequiredListWindow: numItems= "..tostring(numItems)..", button_count= "..tostring(button_count))
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(CraftBenchRequiredListList,			-- frame
							numItems,						-- num items
							button_count,					-- num to display
							CRAFTBENCH_REQUIRED_LIST_HEIGHT)	-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(CraftBenchRequiredListList)
	--DA.DEBUG(1,"UpdateRequiredListWindow: itemOffset= "..tostring(itemOffset))
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
			local oreagentID = self.cachedRequiredList.reagents[itemIndex].itemID
			button.oreagentID = oreagentID
			local oreagentName, oreagentLink = C_Item.GetItemInfo(oreagentID)
			local oreagentQuality
			if not oreagentName then
				CraftBench.optionalDataNeeded = true
				C_Item.RequestLoadItemDataByID(oreagentID)
				oreagentName = "item:"..tostring(oreagentID)
			end
			if oreagentLink then
				oreagentQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(oreagentLink)
			end
			needed:SetText("")
			needed:Show()
			local bags, num, craftable = self:GetInventory(self.currentPlayer, oreagentID)
			local count_text
			if craftable > 0 then
				count_text = string.format("[%d/%d]", num, craftable)
			else
				count_text = string.format("[%d]", num)
			end
			count:SetText(count_text)
			count:Show()
			if oreagentQuality then
--				oreagentName = oreagentName..C_Texture.GetCraftingReagentQualityChatIcon(oreagentQuality)
				oreagentName = oreagentName.."|A:Professions-ChatIcon-Quality-Tier"..oreagentQuality..":17:17|a"
			end
			text:SetText(oreagentName)
			text:SetWordWrap(false)
			text:SetWidth(width - (needed:GetWidth() + count:GetWidth()))
			text:Show()
			local texture =C_Item.GetItemIconByID(oreagentID)
			icon:SetNormalTexture(texture)
			icon:Show()
			button:SetID(itemIndex)
			button:Show()
		else
			--DA.DEBUG(1,"UpdateRequiredListWindow: Hide unused button")
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
	self.InProgress.optional = false
end

--
-- Updates the scrollbar when a scroll event happens
--
function CraftBench:RequiredList_OnScroll()
	CraftBench:UpdateRequiredListWindow()
end

--
-- Functions to show and hide the RequiredList
--
function CraftBench:DisplayRequiredList()
	--DA.DEBUG(0,"DisplayRequiredList()")
	if not self.RequiredList then
		self.RequiredList = createRequiredListFrame(self)
	end
	if not self.RequiredList:IsVisible() then
		self.RequiredList.titletext:SetText("CraftBench: Required Reagents")
		self.RequiredList:Show()
	end
end

function CraftBench:HideRequiredList(clear)
	--DA.DEBUG(0,"HideRequiredList()")
	if self.RequiredList then
		self.RequiredList:Hide()
	end
	if clear then
		self.cachedRequiredList = nil
	end
end

--
-- Called when an required reagent button in the CraftBench detail frame is clicked.
-- This required list is used for selecting Required reagents.
-- This has the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function CraftBench:RequiredReagentOnClick(button, mouse, skillIndex, reagentIndex)
	DA.DEBUG(0,"RequiredReagentOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	CraftBenchRequiredHaveItems:Hide()
	local thisRequired, index
--
-- Required reagents are identified with a negative index < -100.
-- Finishing reagents are identified with a +200 offset.
-- Note that this index is not the dataSlotIndex needed by C_TradeSkillUI.CraftRecipe
--
	index = (reagentIndex + 100) * -1
	thisRequired = recipe.requiredData[index]
	self.cachedRequiredIndex = index
	DA.DEBUG(1,"RequiredReagentOnClick: thisRequired= "..DA.DUMP(thisRequired))
	self.cachedRequiredList = thisRequired.schematic
	DA.DEBUG(1,"RequiredReagentOnClick: cachedRequiredIndex= "..tostring(self.cachedRequiredIndex)..", cachedRequiredList= "..DA.DUMP1(self.cachedRequiredList))
--
-- Left-click selects and right-click deselects.
--
	if mouse == "LeftButton" then
		self:UpdateRequiredListWindow()
	elseif mouse == "RightButton" then
		if self.requiredSelected then
			self.requiredSelected[self.cachedRequiredIndex] = nil
		end
		self:UpdateDetailWindow(skillIndex)
	end
end

--
-- Returns a link for the required reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function CraftBench:GetRequiredItemLink(skillIndex, index)
	--DA.DEBUG(0,"GetRequiredItemLink("..tostring(skillIndex)..", "..tostring(index)..")")
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and self.cachedRequiredList then
			local oreagentID = self.cachedRequiredList.reagents[index].itemID
			local name, link = C_Item.GetItemInfo(oreagentID)
			return link
		end
	end
end

--
-- Called when then mouse enters a required button
--
function CraftBench:RequiredButtonOnEnter(button, skillIndex, optionalIndex)
	--DA.DEBUG(0,"RequiredButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(optionalIndex)..")")
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
	--DA.DEBUG(1,"RequiredButtonOnEnter: "..tostring(button.oreagentID))
	tip:SetHyperlink("item:"..button.oreagentID)
	tip:Show()
	CursorUpdate(button)
end

--
-- called then the mouse leaves an optional button
--
function CraftBench:RequiredButtonOnLeave(button, skillIndex, optionalIndex)
	--DA.DEBUG(0,"RequiredButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(optionalIndex)..")")
	local tip = GameTooltip -- CraftBenchTradeskillTooltip
	if CraftBench.db.profile.scale_tooltip then
		tip:SetScale(CraftBench.gttScale)
	end
	tip:Hide()
	ResetCursor()
end

--
-- Called when an required reagent in the RequiredList is clicked.
-- This required list is used for selecting Required reagents.
-- These all have the property that only one item is selected and 
-- the quantity (per craft) is one.
--
function CraftBench:RequiredButtonOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"RequiredButtonOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	--DA.DEBUG(1,"RequiredButtonOnClick: cachedRequiredIndex= "..tostring(self.cachedRequiredIndex)..", cachedRequiredList= "..DA.DUMP(self.cachedRequiredList))
	local oreagentID = self.cachedRequiredList.reagents[reagentIndex].itemID
	local oreagentSlot = self.cachedRequiredList.dataSlotIndex
	if not self.requiredSelected then
		self.requiredSelected = {}
	end
	if mouse == "LeftButton" then
		self.requiredSelected[self.cachedRequiredIndex] = { itemID = oreagentID, quantity = 1, dataSlotIndex = oreagentSlot, }
	elseif mouse == "RightButton" then
		self.requiredSelected[self.cachedRequiredIndex] = nil
	end
	--DA.DEBUG(1,"RequiredButtonOnClick: cachedRequiredIndex= "..tostring(self.cachedRequiredIndex)..", oreagentID= "..tostring(oreagentID)..", requiredSelected= "..DA.DUMP(self.requiredSelected))
	self:UpdateDetailWindow(skillIndex)
end
