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

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local num_buttons = 0
local function get_button(i)
	local button = _G["CraftForgeModifiedListButton"..i]
	if not button then
		button = CreateFrame("Button", "CraftForgeModifiedListButton"..i, CraftForgeModifiedListParent, "CraftForgeModifiedListItemTemplate")
		button:SetParent(CraftForgeModifiedListParent)
		button:SetPoint("TOPLEFT", "CraftForgeModifiedListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(CraftForgeModifiedListParent:GetFrameLevel() + 1)
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

CRAFTFORGE_MODIFIED_LIST_HEIGHT = 24
local function createModifiedListFrame(self)
	--DA.DEBUG(0,"createModifiedListFrame")
	local frame = CraftForgeModifiedList
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
	local titletext = title:CreateFontString("CraftForgeShoppingListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT",title,"TOPLEFT",0,0)
	titletext:SetPoint("TOPRIGHT",title,"TOPRIGHT",0,0)
	titletext:SetHeight(26)
	titletext:SetShadowColor(0,0,0)
	titletext:SetShadowOffset(1,-1)
	titletext:SetTextColor(1,1,1)
	titletext:SetText("CraftForge: Modified Reagents")
	frame.titletext = titletext
	CraftForgeModifiedBestQualityText:SetText(PROFESSIONS_USE_BEST_QUALITY_REAGENTS)
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = CraftForgeModifiedListParent
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
	local ModifiedListLocation = {
		prefix = "ModifiedListLocation_"
	}
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, ModifiedListLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	CraftForge:EnableResize(frame, 420, 240, CraftForge.UpdateModifiedListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
--
-- Adjust the button height
--
	CRAFTFORGE_MODIFIED_LIST_HEIGHT = math.max(CraftForgeModifiedListButton1:GetHeight(), CRAFTFORGE_MODIFIED_LIST_HEIGHT)
	return frame
end

--
-- Called to update the modified list window
--
function CraftForge:UpdateModifiedListWindow()
	--DA.DEBUG(0,"UpdateModifiedListWindow()")
	self.InProgress.modified = true
	local numItems
	if self.cachedModifiedList then
		numItems = #self.cachedModifiedList
		--DA.DEBUG(1,"UpdateModifiedListWindow: numItems= "..tostring(numItems)..", cachedModifiedIndex= "..tostring(self.cachedModifiedIndex)..", cachedModifiedNeeded= "..tostring(self.cachedModifiedNeeded))
		--DA.DEBUG(1,"UpdateModifiedListWindow: cachedModifiedList= "..DA.DUMP1(self.cachedModifiedList))
	else
		return
	end
	CraftForgeModifiedNeeded:SetText(self.cachedModifiedNeeded)
	CraftForgeModifiedNeeded:SetTextColor(1,1,1)
	local height = CraftForgeModifiedListParent:GetHeight()
	local width = CraftForgeModifiedListParent:GetWidth() - 30 -- Allow for scrollbars
	--DA.DEBUG(1,"UpdateModifiedListWindow: height= "..tostring(height)..", CRAFTFORGE_MODIFIED_LIST_HEIGHT= "..tostring(CRAFTFORGE_MODIFIED_LIST_HEIGHT))
	--DA.DEBUG(1,"UpdateModifiedListWindow: width= "..tostring(width))
	local button_count = height / CRAFTFORGE_MODIFIED_LIST_HEIGHT
	button_count = math.floor(button_count) - 1
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(CraftForgeModifiedListList,			-- frame
							numItems,						-- num items
							button_count,					-- num to display
							CRAFTFORGE_MODIFIED_LIST_HEIGHT)	-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(CraftForgeModifiedListList)
	--DA.DEBUG(1,"UpdateModifiedListWindow: itemOffset= "..tostring(itemOffset))
	for i=1, button_count, 1 do
		num_buttons = math.max(num_buttons, i)
		local itemIndex = i + itemOffset
		local  button = get_button(i)
		local    text = _G[button:GetName() .. "Text"]
		local    icon = _G[button:GetName() .. "Icon"]
		local   count = _G[button:GetName() .. "Count"]
		local  needed = _G[button:GetName() .. "Needed"]
		local   input = _G[button:GetName() .. "Input"]
		button:SetWidth(width)
		if itemIndex <= numItems then
			local mreagentID = self.cachedModifiedList[itemIndex].itemID
			button.itemIndex = itemIndex
			button:SetID(itemIndex)
			button.mreagentID = mreagentID
			needed:SetText("")
			needed:Show()
			local bags, num, craftable = self:GetInventory(self.currentPlayer, mreagentID)
			button.have = num
			local count_text
			if craftable > 0 then
				count_text = string.format("[%d/%d]", num, craftable)
			else
				count_text = string.format("[%d]", num)
			end
			count:SetText(count_text)
			count:Show()
			local modifiedSelected = self.modifiedSelected[self.cachedModifiedIndex]
			--DA.DEBUG(1,"UpdateModifiedListWindow: modifiedSelected= "..DA.DUMP1(modifiedSelected))
			local use = 0
			if modifiedSelected then
				for j,reagent in pairs(modifiedSelected) do
					if reagent.itemID == mreagentID then
						use = reagent.quantity
					end
				end
			end
			button.use = use
			input:SetText(use)
			input:Show()
			local mreagentName = self:nameWithQuality(mreagentID, true)
			text:SetText(mreagentName)
			text:SetWordWrap(false)
			text:SetWidth(width - (needed:GetWidth() + count:GetWidth()))
			text:Show()
			local texture =C_Item.GetItemIconByID(mreagentID)
			icon:SetNormalTexture(texture)
			icon:Show()
			button:Show()
		else
			--DA.DEBUG(1,"UpdateModifiedListWindow: Hide unused button")
			text:SetText("")
			text:Hide()
			icon:Hide()
			count:SetText("")
			count:Hide()
			needed:SetText("")
			needed:Hide()
			button:SetID(0)
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
	self.InProgress.modified = false
end

--
-- Updates the scrollbar when a scroll event happens
--
function CraftForge:ModifiedList_OnScroll()
	CraftForge:UpdateModifiedListWindow()
end

--
-- Functions to show and hide the ModifiedList
--
function CraftForge:DisplayModifiedList()
	--DA.DEBUG(0,"DisplayModifiedList()")
	if not self.ModifiedList then
		self.ModifiedList = createModifiedListFrame(self)
	end
	if not self.ModifiedList:IsVisible() then
		CraftForgeModifiedListCloseButton:Enable()
		self.ModifiedList:Show()
	end
end

function CraftForge:HideModifiedList(clear)
	--DA.DEBUG(0,"HideModifiedList()")
	if self.ModifiedList then
		self.ModifiedList:Hide()
	end
	if clear then
		self.cachedModifiedList = nil
	end
end

--
-- Called when an modified reagent button in the CraftForge detail frame is clicked
--

function CraftForge:ModifiedReagentOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"ModifiedReagentOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	local thisModified = recipe.modifiedData[reagentIndex - 100]
	--DA.DEBUG(1,"ModifiedReagentOnClick: thisModified= "..DA.DUMP(thisModified))
	self.cachedModifiedList = thisModified.schematic.reagents
	self.cachedModifiedIndex = reagentIndex - 100
	self.cachedModifiedNeeded = thisModified.numNeeded
	--DA.DEBUG(1,"ModifiedReagentOnClick: cachedModifiedIndex= "..tostring(self.cachedModifiedIndex)..", cachedModifiedList= "..DA.DUMP1(self.cachedModifiedList))
	local modifiedSelected = self.modifiedSelected[self.cachedModifiedIndex]
	--DA.DEBUG(1,"ModifiedReagentOnClick: modifiedSelected= "..DA.DUMP1(modifiedSelected))
	if mouse == "LeftButton" then
		self:UpdateModifiedListWindow()
	elseif mouse == "RightButton" then
		self:UpdateDetailWindow(skillIndex)
	end
end

--
-- Returns a link for the modified reagent required to create the specified
-- item, the index'th reagent required for the item is returned
--
function CraftForge:GetModifiedItemLink(skillIndex, index)
	--DA.DEBUG(0,"GetModifiedItemLink("..tostring(skillIndex)..", "..tostring(index)..")")
	if skillIndex and index then
		local recipe = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
		if recipe and self.cachedModifiedList then
			local mreagentID = self.cachedModifiedList[index].itemID
			local name, link = C_Item.GetItemInfo(mreagentID)
			return link
		end
	end
end

--
-- Called when then mouse enters a modified button in the ModifiedList frame
--
function CraftForge:ModifiedButtonOnEnter(button, skillIndex, modifiedIndex)
	--DA.DEBUG(0,"ModifiedButtonOnEnter("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(modifiedIndex)..")")
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
	--DA.DEBUG(1,"ModifiedButtonOnEnter: "..tostring(button.mreagentID))
	tip:SetHyperlink("item:"..button.mreagentID)
	tip:Show()
	CursorUpdate(button)
end

--
-- Called when the mouse leaves a modified button in the ModifiedList frame
--
function CraftForge:ModifiedButtonOnLeave(button, skillIndex, modifiedIndex)
	--DA.DEBUG(0,"ModifiedButtonOnLeave("..tostring(button)..", "..tostring(skillIndex)..", "..tostring(modifiedIndex)..")")
	local tip = GameTooltip -- CraftForgeTradeskillTooltip
	if CraftForge.db.profile.scale_tooltip then
		tip:SetScale(CraftForge.gttScale)
	end
	tip:Hide()
	ResetCursor()
end

--
-- Called when the mouse is clicked on a modified button in the ModifiedList frame
--
function CraftForge:ModifiedButtonOnClick(button, mouse, skillIndex, reagentIndex)
	--DA.DEBUG(0,"ModifiedButtonOnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(skillIndex)..", "..tostring(reagentIndex)..")")
	local mreagentID = self.cachedModifiedList[reagentIndex].itemID
	if not self.modifiedSelected then
		self.modifiedSelected = {}
	end
	if mouse == "LeftButton" then
		self.modifiedSelected[self.cachedModifiedIndex] = mreagentID
--		self:HideModifiedList()
	elseif mouse == "RightButton" then
		self.modifiedSelected[self.cachedModifiedIndex] = nil
	end
	--DA.DEBUG(1,"ModifiedButtonOnClick: cachedModifiedIndex= "..tostring(self.cachedModifiedIndex)..", mreagentID= "..tostring(mreagentID)..", modifiedSelected= "..DA.DUMP1(self.modifiedSelected))
	self:UpdateDetailWindow(skillIndex)
end

function CraftForge:ModifiedListToggleBestQuality()
	self.db.profile.best_quality = not self.db.profile.best_quality
	--DA.DEBUG(0,"ModifiedListToggleBestQuality: best_quality= "..tostring(self.db.profile.best_quality))
	CraftForgeUseHighestQuality:SetChecked(self.db.profile.best_quality)
	self:UpdateDetailWindow(self.selectedSkill)
end

function CraftForge:ModifyItemCount(this,button)
	--DA.DEBUG(0,"ModifyItemCount("..tostring(this)..", "..tostring(button))
end

function CraftForge:ResetItemCount(this,button)
	--DA.DEBUG(0,"ResetItemCount("..tostring(this)..", "..tostring(button))
end

function CraftForge:ModifiedItemCount(this, button, count)
	--DA.DEBUG(0,"ModifiedItemCount("..tostring(this)..", "..tostring(button)..", "..tostring(count))
	local parent = this:GetParent()
	local itemID = parent.mreagentID
	local have = parent.have
	local use = parent.use
	local itemIndex = parent.itemIndex
	--DA.DEBUG(1,"ModifiedItemCount: itemID= "..tostring(itemID)..", have= "..tostring(have)..", use= "..tostring(use)..", itemIndex= "..tostring(itemIndex))
	local mreagents = self.modifiedSelected[self.cachedModifiedIndex]
	--DA.DEBUG(1,"ModifiedItemCount: (before) mreagents= "..DA.DUMP1(mreagents))
	local name = parent:GetName()
	local input = _G[name.."Input"]
	local val = input:GetNumber()
	--DA.DEBUG(1,"ModifiedItemCount: val= "..tostring(val))
	val = val + count
--
-- first (outer) limit checks
--
	if val < 0 then
		val = 0
	end
	if val > have then
		val = have
	end
--
-- now check if this change will exceeded the needed value
--
	local total = 0
	local thisReagent
	if mreagents then
		for i,reagent in pairs(mreagents) do
			--DA.DEBUG(2,"ModifiedItemCount: i= "..tostring(i)..", reagent= "..DA.DUMP1(reagent))
			if reagent.itemID == itemID then
				total = total + val
				thisReagent = reagent
			else
				total = total + reagent.quantity
			end
		end
	end
	--DA.DEBUG(1,"ModifiedItemCount: total= "..tostring(total)..", needed= "..tostring(self.cachedModifiedNeeded)..", val= "..tostring(val)..", thisReagent= "..DA.DUMP1(thisReagent))
	if total <= self.cachedModifiedNeeded then
		input:SetText(tostring(val))
		if thisReagent then
			thisReagent.quantity = val
		end
		if total == self.cachedModifiedNeeded then
			CraftForgeModifiedNeeded:SetTextColor(1,1,1)
			CraftForgeModifiedListCloseButton:Enable()
		else
			CraftForgeModifiedNeeded:SetTextColor(1,0,0)
			if mreagents then
				CraftForgeModifiedListCloseButton:Disable()
			end
		end
	else
		input:SetText(tostring(val))
		CraftForgeModifiedNeeded:SetTextColor(1,0,0)
		CraftForgeModifiedListCloseButton:Disable()
	end
	--DA.DEBUG(1,"ModifiedItemCount: (after) mreagents= "..DA.DUMP1(mreagents))
end

--
-- Called when there are enough reagents for this slot.
-- Builds a table in the format needed by C_TradeSkillUI.CraftRecipe
-- using self.db.profile.best_quality to determine the order.
--
function CraftForge:InitializeModifiedSelected(mreagent)
	--DA.DEBUG(0,"InitializeModifiedSelected("..DA.DUMP(mreagent)..")")
	local modifiedSelected = {}
	local total = 0
	local this = 0
	local used = 0
	local need = mreagent.numNeeded
	local bags, num
	if self.db.profile.best_quality then
		for k=#mreagent.schematic.reagents, 1 , -1 do
			if used < need then
				bags, num = self:GetInventory(self.currentPlayer, mreagent.schematic.reagents[k].itemID)
				this = math.min(num,(need-total))
				total = total + this
				if this > 0 then
					table.insert(modifiedSelected, { itemID = mreagent.schematic.reagents[k].itemID, quantity = this, dataSlotIndex = mreagent.slot, })
				end
			else
				table.insert(modifiedSelected, { itemID = mreagent.schematic.reagents[k].itemID, quantity = 0, dataSlotIndex = mreagent.slot, })
			end
		end
	else
		for k=1, #mreagent.schematic.reagents, 1 do
			if used < need then
				bags, num = self:GetInventory(self.currentPlayer, mreagent.schematic.reagents[k].itemID)
				this = math.min(num,(need-total))
				total = total + this
				table.insert(modifiedSelected, { itemID = mreagent.schematic.reagents[k].itemID, quantity = this, dataSlotIndex = mreagent.slot, })
			else
				table.insert(modifiedSelected, { itemID = mreagent.schematic.reagents[k].itemID, quantity = 0, dataSlotIndex = mreagent.slot, })
			end
		end
	end
	--DA.DEBUG(0,"InitializeModifiedSelected: modifiedSelected = "..DA.DUMP1(modifiedSelected))
	return modifiedSelected, used < need
end

--
-- Called to check if there still are enough reagents.
--
function CraftForge:CheckModifiedSelected(mreagent)
	--DA.DEBUG(0,"CheckModifiedSelected("..DA.DUMP(mreagent)..")")
	if mreagent then
		for j,reagent in pairs(mreagent) do
			--DA.DEBUG(1,"CheckModifiedSelected: j= "..tostring(j)..", reagent= "..DA.DUMP1(reagent))
			local have = C_Item.GetItemCount(reagent.itemID,true,false,true,true)
			if have < reagent.quantity then
				return false
			end
		end
	else
		return false
	end
	return true
end
