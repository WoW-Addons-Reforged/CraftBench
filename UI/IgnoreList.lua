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

CRAFTBENCH_IGNORE_LIST_HEIGHT = 16

local L = LibStub("AceLocale-3.0"):GetLocale("CraftBench")

local num_buttons = 0

-- ===========================================================================================
--    Window creation and update methods
-- ===========================================================================================
local function get_button(i)
	local button = _G["CraftBenchIgnoreListButton"..i]
	if not button then
		button = CreateFrame("Button", "CraftBenchIgnoreListButton"..i, CraftBenchIgnoreListParent, "CraftBenchIgnoreListItemButtonTemplate")
		button:SetParent(CraftBenchIgnoreListParent)
		button:SetPoint("TOPLEFT", "CraftBenchIgnoreListButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(CraftBenchIgnoreListParent:GetFrameLevel() + 1)
	end
	return button
end

-- Stolen from the Waterfall Ace2 addon.  Used for the backdrop of the scrollframe
local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}
local FrameBackdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 30, bottom = 3 }
}

local function createIgnoreListFrame(self)
	--DA.DEBUG(0,"createIgnoreListFrame")
	local frame = CraftBenchIgnoreList
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
	local titletext = frame:CreateFontString("CraftBenchIgnoreListTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -1)
	titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -1)
	titletext:SetHeight(26)
	titletext:SetJustifyH("CENTER")
	titletext:SetText("CraftBench: Ignored Materials")
	UIStyle.StyleHeaderBar(frame, titletext, 1)
	if CraftBenchIgnoreListCloseButton then UIStyle.SkinCloseButton(CraftBenchIgnoreListCloseButton) end
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = CraftBenchIgnoreListParent
	if TSM_API and CraftBench.db.profile.tsm_compat then
		backdrop:SetFrameStrata("HIGH")
	end
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
	if CraftBenchIgnoreList then UIStyle.StyleScrollBar(CraftBenchIgnoreList) end
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local ignoreListLocation = {
		prefix = "ignoreListLocation_"
	}
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, ignoreListLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	CraftBench:EnableResize(frame, 320,150, CraftBench.UpdateIgnoreListWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
	return frame
end

function CraftBench:GetIgnoreList(player)
	--DA.DEBUG(0,"GetIgnoreList("..tostring(player)..")")
	local list = {}
	local playerList
	if player then
		playerList = { player }
	else
		playerList = {}
		for player,queue in pairs(self.db.realm.userIgnoredMats) do
			table.insert(playerList, player)
		end
	end
	--DA.DEBUG(0,"Ignored Mats list for: "..(player or "all players"))
	for i=1,#playerList,1 do
		local player = playerList[i]
		local userIgnoredMats = self.db.realm.userIgnoredMats[player]
		--DA.DEBUG(1,"player: "..player)
		if userIgnoredMats then
			for id,link in pairs(userIgnoredMats) do
				local entry = { ["player"] = player, ["id"] = id, ["link"] = link }
				table.insert(list, entry)
			end
		end
	end
	return list
end

function CraftBench:DeleteIgnoreEntry(index, player, id)
	--DA.DEBUG(0,"DeleteIgnoreEntry("..tostring(index)..", "..tostring(player)..", "..tostring(id)..")")
	table.remove(self.cachedIgnoreList,index)
	self.db.realm.userIgnoredMats[player][id] = nil
	self:UpdateIgnoreListWindow()
	self:UpdateTradeSkillWindow()
end

function CraftBench:ClearIgnoreList(player)
	--DA.DEBUG(0,"ClearIgnoreList("..tostring(player)..")")
	local playerList
	if player then
		playerList = { player }
	else
		playerList = {}
		for player,queue in pairs(self.db.realm.userIgnoredMats) do
			table.insert(playerList, player)
		end
	end
	--DA.DEBUG(0,"clear ignore list for: "..(player or "all players"))
	for i=1,#playerList,1 do
		local player = playerList[i]
		--DA.DEBUG(1,"player: "..player)
		self.db.realm.userIgnoredMats[player] = {}
	end
	self:UpdateIgnoreListWindow()
	self:UpdateTradeSkillWindow()
end

--
-- Called to add a count to the Ignored List button in the main frame
--
function CraftBench:UpdateIgnoredMatsButton()
	--DA.DEBUG(0,"UpdateIgnoredMatsButton()")
	self.cachedIgnoreList = self:GetIgnoreList()
	local numItems = #self.cachedIgnoreList
	if numItems > 0 then
		CraftBenchIgnoredMatsButton:SetText(L["Ignored List"].." ("..tostring(numItems)..")")
	else
		CraftBenchIgnoredMatsButton:SetText(L["Ignored List"])
	end
end

--
-- Called to update the ignore list window
--
function CraftBench:UpdateIgnoreListWindow()
	--DA.DEBUG(0,"UpdateIgnoreListWindow()")
	self.cachedIgnoreList = self:GetIgnoreList()
	local numItems = #self.cachedIgnoreList
	if not self.ignoreList or not self.ignoreList:IsVisible() then
		--DA.DEBUG(0,"No ignoreList visible so return")
		return
	end
	self:UpdateIgnoredMatsButton()
	local button_count = CraftBenchIgnoreListList:GetHeight() / CRAFTBENCH_IGNORE_LIST_HEIGHT
	button_count = math.floor(button_count)
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(CraftBenchIgnoreListList,			-- frame
							numItems,						-- num items
							button_count,					-- num to display
							CRAFTBENCH_IGNORE_LIST_HEIGHT)	-- value step (item height)
--
-- Where in the list of items to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(CraftBenchIgnoreListList)
	local width = CraftBenchIgnoreListParent:GetWidth()
	for i=1, button_count, 1 do
		num_buttons = math.max(num_buttons, i)
		local itemIndex = i + itemOffset
		local button = get_button(i)
		local player = _G[button:GetName() .. "Player"]
		local playerText = _G[button:GetName() .. "PlayerText"]
		local rlink = _G[button:GetName() .. "RecipeLink"]
		local rlinkText = _G[button:GetName() .. "RecipeLinkText"]
		local rid = _G[button:GetName() .. "RecipeID"]
		local ridText = _G[button:GetName() .. "RecipeIDText"]
		button:SetWidth(width)
		player:SetWidth(width * 0.2-10)
		playerText:SetWidth(width * 0.2-10)
		rlink:SetWidth(width * 0.6-10)
		rlinkText:SetWidth(width * 0.6-10)
		rlinkText:SetWordWrap(false)
		rid:SetWidth(width * 0.2-10)
		ridText:SetWidth(width * 0.2-10)
		if itemIndex <= numItems then
			playerText:SetText(self.cachedIgnoreList[itemIndex]["player"])
			rlinkText:SetText(self.cachedIgnoreList[itemIndex]["link"])
			ridText:SetText(self.cachedIgnoreList[itemIndex]["id"])
			button.index = itemIndex
			button.player = self.cachedIgnoreList[itemIndex]["player"]
			button.id = tonumber(self.cachedIgnoreList[itemIndex]["id"])
			button:Show()
			player:Show()
			rlink:Show()
			rid:Show()
		else
			button.id = nil
			button:Hide()
			player:Hide()
			rlink:Hide()
			rid:Hide()
		end
	end
--
-- Hide any of the buttons that we created, but don't need right now
--
	for i = button_count+1, num_buttons, 1 do
		local button = get_button(i)
		button:Hide()
	end
end

--
-- Updates the scrollbar when a scroll event happens
--
function CraftBench:IgnoreList_OnScroll()
	CraftBench:UpdateIgnoreListWindow()
end

--
-- Functions to show and hide the Ignorelist
--
function CraftBench:DisplayIgnoreList()
	--DA.DEBUG(0,"DisplayIgnoreList()")
	if not self.ignoreList then
		self.ignoreList = createIgnoreListFrame(self)
	end
	local frame = self.ignoreList
	if not frame:IsVisible() then
		frame:Show()
	else
		frame:Hide()
	end
	self:UpdateIgnoreListWindow()
end

function CraftBench:HideIgnoreList()
	--DA.DEBUG(0,"HideIgnoreList()")
	local closed
	if self.ignoreList and self.ignoreList:IsVisible() then
		self.ignoreList:Hide()
		closed = true
	end
	self.cachedIgnoreList = nil
	return closed
end
