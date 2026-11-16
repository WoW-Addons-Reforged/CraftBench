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

local L = LibStub("AceLocale-3.0"):GetLocale("CraftBench")
local UIStyle = CraftBench.UIStyle

CRAFTBENCH_TRADE_SKILL_HEIGHT = 20

local COLORORANGE = "|cffff8040"
local COLORYELLOW = "|cffffff00"
local COLORGREEN =  "|cff40c040"
local COLORGRAY =   "|cff808080"
local COLORRED =    "|cffff0000"
local COLORWHITE =  "|cffffffff"
--
-- Colors used in the "0/0/0" strings and tooltips
--
local CGREY = "|cffb0b0b0"		-- Grey = "[", "/", "]"
local COWNED = "|cff95fcff"		-- Blue = How many you have in your inventory
local CBANK = "|cff95fcff"		-- Blue = How many you have in your bank
local CBAG = "|cff80ff80"		-- Green = How many you can make from materials you have
local CCRAFT =  "|cffffff80"	-- Yellow = How many you can make by crafting the reagents
local CVENDOR = "|cffffa050"	-- Orange = How many you can make if you purchase materials from a vendor
local CALTS = "|cffff80ff"		-- Purple = How many you can make using materials on your alts

-- min height for CraftBench window
local CRAFTBENCH_MIN_HEIGHT = 580
--
-- height of the header portion
--
-- this value reflects the offsets of 
-- CraftBenchSkillListParent and CraftBenchReagentParent
--   (Y offset is either 110 or 130)
--   (we really should compute this from those values)
--
local CRAFTBENCH_HEADER_HEIGHT = 145		-- 125 if Filter is removed under Search

-- min width for skill list window
local CRAFTBENCH_SKILLLIST_MIN_WIDTH = 440

-- min/max width for the reagent window
local CRAFTBENCH_REAGENT_MIN_WIDTH = 350
local CRAFTBENCH_REAGENT_MAX_WIDTH = 385
local CRAFTBENCH_REAGENT_MIN_HEIGHT = 300
local reagent_height

-- min width of count text
local CRAFTBENCH_COUNT_MIN_WIDTH = 100

--
-- Stack of previsouly selected skills for use by the
-- "click on reagent, go to recipe" code and for clicking on Queue'd recipes
-- stack is stack of tables: { "player", "tradeID", "skillIndex"}
--
CraftBench.skillStack = {}

--
-- Stolen from the Waterfall Ace2 addon.
--
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
local TSMBackdrop = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	tile = true, tileSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

--
-- List of functions that are called before a button is shown
--
local pre_show_callbacks = {}

--
-- List of functions that are called before a button is hidden
--
local pre_hide_callbacks = {}

function CraftBench:AddPreButtonShowCallback(method)
	assert(method and type(method) == "function",
		   "Usage: CraftBench:AddPreButtonShowCallback(method). method must be a non-nil function")
	table.insert(pre_show_callbacks, method)
end

function CraftBench:AddPreButtonHideCallback(method)
	assert(method and type(method) == "function",
		   "Usage: CraftBench:AddPreButtonHideCallback(method). method must be a non-nil function")
	table.insert(pre_hide_callbacks, method)
end

--
-- Figures out how to display the craftable counts for a recipe.
-- Returns: num, num_with_vendor, num_with_alts
--
local function get_craftable_counts(skill, numMade)
	--DA.DEBUG(2,"get_craftable_counts: name= "..tostring(skill.name)..", numMade= "..tostring(numMade))
	--DA.DEBUG(3,"get_craftable_counts: skill= "..DA.DUMP1(skill,1))
	local factor = 1
	if CraftBench.db.profile.show_craft_counts then
		factor = numMade or 1
	end
	local num          = math.floor((skill.numCraftable or 0) / factor)
	local numrecursive = math.floor((skill.numRecursive or 0) / factor)
	local numwvendor   = math.floor((skill.numCraftableVendor or 0) / factor)
	local numwalts     = math.floor((skill.numCraftableAlts or 0) / factor)
	local numbank      = math.floor((skill.numCraftableBank or 0) / factor)
	--DA.DEBUG(2,"get_craftable_counts = "..tostring(num)..", "..tostring(numrecursive)..", "..tostring(numwvendor)..", "..tostring(numwalts)..", "..tostring(numbank))
	return num, numrecursive, numwvendor, numwalts, numbank
end

function CraftBench:CreateTradeSkillWindow()
--
-- The CraftBenchFrame is defined in the file MainFrame.xml
--
	local frame = CraftBenchFrame
	if not frame then
		return frame
	end
	--DA.DEBUG(0,"CreateTradeSkillWindow: oldWidth= "..tostring(frame:GetWidth())..", oldHeight= "..tostring(frame:GetHeight()))
	if frame:GetWidth() < 710 then
		frame:SetWidth(710)		-- Reset the window size to the new minimum
	end
	if frame:GetHeight() < 545 then
		frame:SetHeight(545)
	end
	if not frame.SetBackdrop then
		Mixin(frame, BackdropTemplateMixin)
	end
	local UIStyle = CraftBench.UIStyle
	if TSM_API and CraftBench.db.profile.tsm_compat then
		frame:SetFrameStrata("HIGH")
		frame:SetBackdrop(TSMBackdrop)
		frame:SetBackdropColor(0.1, 0.1, 0.1)
	else
		UIStyle.SkinFrame(frame, false)
	end

	local titletext = frame:CreateFontString("CraftBenchTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -1)
	titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -1)
	titletext:SetHeight(26)
	titletext:SetJustifyH("CENTER")
	titletext:SetText(L["CraftBench Trade Skills"].." "..CraftBench.version)
	UIStyle.StyleHeaderBar(frame, titletext, 1)
	if CraftBenchFrameCloseButton then
		UIStyle.SkinCloseButton(CraftBenchFrameCloseButton)
	end
	if CraftBenchCloseButton then
		UIStyle.SkinCloseButton(CraftBenchCloseButton)
	end
	if CraftBenchShowOptionsButton then
		CraftBenchShowOptionsButton:SetSize(22, 22)
		CraftBenchShowOptionsButton:ClearAllPoints()
		if CraftBenchFrameCloseButton then
			CraftBenchShowOptionsButton:SetPoint("RIGHT", CraftBenchFrameCloseButton, "LEFT", -4, 0)
		end
		CraftBenchShowOptionsButton:SetText("")
		UIStyle.SkinButton(CraftBenchShowOptionsButton, "default")
		if not CraftBenchShowOptionsButton._cfGearIcon then
			local gear = CraftBenchShowOptionsButton:CreateTexture(nil, "OVERLAY")
			gear:SetSize(14, 14)
			gear:SetPoint("CENTER", CraftBenchShowOptionsButton, "CENTER", 0, 0)
			gear:SetTexture("Interface\\Icons\\Trade_Engineering")
			gear:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			CraftBenchShowOptionsButton._cfGearIcon = gear
		end
		CraftBenchShowOptionsButton:SetScript("OnClick", function()
			CraftBench:InventoryFilterButtons_Hide()
			if IsShiftKeyDown() and CraftBench.Share and CraftBench.Share.OpenOptions then
				CraftBench.Share:OpenOptions()
			else
				CraftBench:ShowOptions()
			end
		end)
		CraftBenchShowOptionsButton:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:ClearLines()
			GameTooltip:AddLine(L["Config"], 1, 0.85, 0.25)
			GameTooltip:AddLine(L["CONFIGDESC"], 0.9, 0.9, 0.9, true)
			GameTooltip:Show()
		end)
		CraftBenchShowOptionsButton:HookScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	local filterLabel = _G["CraftBenchFilterLabel"]
	if filterLabel then filterLabel:SetText(L["Filter"]) end
	local filterText = _G["CraftBenchFilterText"]
	if filterText then filterText:SetText("") end
	local searchLabel = _G["CraftBenchSearchLabel"]
	if searchLabel then searchLabel:SetText(L["Search"]) end
	CraftBenchPluginButton:SetText(L["Plugins"])
	CraftBenchPluginButton:Hide()
	CraftBenchCreateAllButton:SetText(L["Create All"])
	CraftBenchQueueAllButton:SetText(L["Queue All"])
	CraftBenchCreateButton:SetText(L["Create"])
	CraftBenchQueueButton:SetText(L["Queue"])
	CraftBenchStartQueueButton:SetText(L["Process"])
	CraftBenchEmptyQueueButton:SetText(L["Clear"])
	CraftBenchEnchantButton:SetText(L["Enchant"])
	CraftBenchRecipeNotesButton:SetText(L["Notes"])
	CraftBenchRecipeNotesFrameLabel:SetText(L["Notes"])
	CraftBenchShoppingListButton:SetText(L["Shopping List"])
	CraftBenchSortLabel:SetText(L["Sorting"])
	CraftBenchGroupLabel:SetText(L["Grouping"])
	CraftBenchIgnoredMatsButton:SetText(L["Ignored List"])
	CraftBenchQueueManagementButton:SetText(L["Queues"])
	CraftBenchQueueLoadButton:SetText(L["Load"])
	CraftBenchQueueDeleteButton:SetText(L["Delete"])
	CraftBenchQueueSaveButton:SetText(L["Save"])
	CraftBenchQueueOnlyButton:SetText(">")

	UIStyle.SkinButton(CraftBenchPluginButton, "default")
	UIStyle.SkinButton(CraftBenchCreateAllButton, "default")
	UIStyle.SkinButton(CraftBenchQueueAllButton, "default")
	UIStyle.SkinButton(CraftBenchCreateButton, "primary")
	UIStyle.SkinButton(CraftBenchQueueButton, "default")
	UIStyle.SkinButton(CraftBenchStartQueueButton, "primary")
	UIStyle.SkinButton(CraftBenchEmptyQueueButton, "danger")
	UIStyle.SkinButton(CraftBenchEnchantButton, "default")
	UIStyle.SkinButton(CraftBenchRecipeNotesButton, "default")
	UIStyle.SkinButton(CraftBenchShoppingListButton, "default")
	UIStyle.SkinButton(CraftBenchIgnoredMatsButton, "default")
	UIStyle.SkinButton(CraftBenchQueueManagementButton, "default")
	UIStyle.SkinButton(CraftBenchQueueLoadButton, "default")
	UIStyle.SkinButton(CraftBenchQueueDeleteButton, "danger")
	UIStyle.SkinButton(CraftBenchQueueSaveButton, "default")
	UIStyle.SkinButton(CraftBenchQueueOnlyButton, "default")
	if CraftBenchFilterButton then UIStyle.SkinButton(CraftBenchFilterButton, "default") end
	if CraftBenchFilterInputBox then UIStyle.SkinEditBox(CraftBenchFilterInputBox) end
	if CraftBenchSearchBox then
		UIStyle.SkinEditBox(CraftBenchSearchBox)
		CraftBenchSearchBox:SetTextInsets(4, 4, 0, 0)
	end
	if CraftBenchItemCountInputBox then
		UIStyle.SkinEditBox(CraftBenchItemCountInputBox)
		CraftBenchItemCountInputBox:SetJustifyH("CENTER")
		CraftBenchItemCountInputBox:SetTextInsets(2, 2, 0, 0)
	end
	if CraftBenchQueueNameInputBox then UIStyle.SkinEditBox(CraftBenchQueueNameInputBox) end
	if CraftBenchRecipeGroupDropdown then UIStyle.SkinDropDown(CraftBenchRecipeGroupDropdown) end
	if CraftBenchSortDropdown then UIStyle.SkinDropDown(CraftBenchSortDropdown) end
	if CraftBenchFilterDropdown then UIStyle.SkinDropDown(CraftBenchFilterDropdown) end
	if CraftBenchQueueLoadDropdown then UIStyle.SkinDropDown(CraftBenchQueueLoadDropdown) end
	for _, fs in ipairs({
		CraftBenchGroupLabel, CraftBenchSortLabel, CraftBenchFilterLabel, CraftBenchSearchLabel,
		CraftBenchReagentLabel, CraftBenchExtraTextLabel, CraftBenchExtraText,
		CraftBenchRequirementText, CraftBenchSkillCooldown, CraftBenchQueueLabel,
	}) do
		if fs then UIStyle.ApplyFont(fs, -1) end
	end
	if CraftBenchSkillName then UIStyle.ApplyFont(CraftBenchSkillName, 1) end
	for i = 1, 8 do
		local rText = _G["CraftBenchReagent" .. i .. "Text"]
		local rCount = _G["CraftBenchReagent" .. i .. "Count"]
		if rText then UIStyle.ApplyFont(rText, -1) end
		if rCount then UIStyle.ApplyFont(rCount, -1) end
	end
--
-- Always want these visible.
--
	CraftBenchItemCountInputBox:SetText("1");
--
-- Progression status bar
--
	CraftBenchRankFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	local rankTex = CraftBenchRankFrame:GetStatusBarTexture()
	if rankTex then
		rankTex:SetDrawLayer("ARTWORK", 1)
	end
	CraftBenchRankFrame:SetStatusBarColor(0.22, 0.45, 0.85, 0.95)
	if CraftBenchRankFrameBackground then
		CraftBenchRankFrameBackground:SetVertexColor(0.05, 0.06, 0.09, 0.95)
	end
	if CraftBenchRankFrameBorder then CraftBenchRankFrameBorder:Hide() end
	UIStyle.SkinInset(CraftBenchRankFrame)
	if CraftBenchRankFrameSkillRank then
		CraftBenchRankFrameSkillRank:SetDrawLayer("OVERLAY")
		UIStyle.ApplyFont(CraftBenchRankFrameSkillRank, -1)
	end
	if not CraftBenchRankFrame.subRanks then
		CraftBenchRankFrame.subRanks = {}
		CraftBenchRankFrame.subRanks.red = CreateFrame("StatusBar", "CraftBenchRankFrameRed", CraftBenchFrame, "CraftBenchRankFrameTemplate")
		CraftBenchRankFrame.subRanks.red:SetStatusBarColor(1.00, 0.00, 0.00, 1.00);
		CraftBenchRankFrame.subRanks.red:SetFrameLevel(CraftBenchFrame:GetFrameLevel()+8)
		CraftBenchRankFrame.subRanks.orange = CreateFrame("StatusBar", "CraftBenchRankFrameOrange", CraftBenchFrame, "CraftBenchRankFrameTemplate")
		CraftBenchRankFrame.subRanks.orange:SetStatusBarColor(1.00, 0.50, 0.25, 1.00);
		CraftBenchRankFrame.subRanks.orange:SetFrameLevel(CraftBenchFrame:GetFrameLevel()+7)
		CraftBenchRankFrame.subRanks.yellow = CreateFrame("StatusBar", "CraftBenchRankFrameYellow", CraftBenchFrame, "CraftBenchRankFrameTemplate")
		CraftBenchRankFrame.subRanks.yellow:SetStatusBarColor(1.00, 1.00, 0.00, 1.00);
		CraftBenchRankFrame.subRanks.yellow:SetFrameLevel(CraftBenchFrame:GetFrameLevel()+6)
		CraftBenchRankFrame.subRanks.green  = CreateFrame("StatusBar", "CraftBenchRankFrameGreen" , CraftBenchFrame, "CraftBenchRankFrameTemplate")
		CraftBenchRankFrame.subRanks.green:SetStatusBarColor(0.25, 0.75, 0.25, 1.00);
		CraftBenchRankFrame.subRanks.green:SetFrameLevel(CraftBenchFrame:GetFrameLevel()+5)
		CraftBenchRankFrame.subRanks.gray   = CreateFrame("StatusBar", "CraftBenchRankFrameGray"  , CraftBenchFrame, "CraftBenchRankFrameTemplate")
		CraftBenchRankFrame.subRanks.gray:SetStatusBarColor(0.50, 0.50, 0.50, 1.00);
		CraftBenchRankFrame.subRanks.gray:SetFrameLevel(CraftBenchFrame:GetFrameLevel()+4)
	end
	CraftBenchFrameEmptySpace = CreateFrame("Button", nil, CraftBenchSkillListParent, "CraftBenchEmptySpaceTemplate")
	CraftBenchFrameEmptySpace.skill = { ["mainGroup"] = true, }
	CraftBenchFrameEmptySpace:SetPoint("TOPLEFT",CraftBenchSkillListParent,"TOPLEFT")
	CraftBenchFrameEmptySpace:SetPoint("BOTTOMRIGHT",CraftBenchSkillListParent,"BOTTOMRIGHT")
	CraftBenchFrameEmptySpace:Show()
--
-- The frame enclosing the scroll list needs a border and a background .....
--
	local backdrop = CraftBenchSkillListParent
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
	UIStyle.StyleScrollBar(CraftBenchSkillList)
--
-- Frame enclosing the reagent list
--
	backdrop = CraftBenchReagentParent
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
--
-- Frame enclosing the queue
--
	backdrop = CraftBenchQueueParent
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
	UIStyle.StyleScrollBar(CraftBenchQueueList)
--
-- Frame enclosing the pop out notes panel
--
	backdrop = CraftBenchRecipeNotesFrame
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
	backdrop:Hide() -- initially hidden
	backdrop = CraftBenchQueueManagementParent
	UIStyle.SkinInset(backdrop)
	backdrop:SetResizable(true)
	self.gearTexture = CraftBenchReagentParent:CreateTexture(nil, "OVERLAY")
	self.gearTexture:SetTexture("Interface\\Icons\\Trade_Engineering")
	self.gearTexture:SetHeight(16)
	self.gearTexture:SetWidth(16)
--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local tradeSkillLocation = {
		prefix = "tradeSkillLocation_"
	}
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, tradeSkillLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	if frame:GetNumPoints() == 0 then
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	windowManager.MakeDraggable(frame)
	frame:SetResizable(false)
	frame:SetSize(900, 620)
--
-- Set up the sorting methods here
--
	self:InitializeSorting()
	self:ConfigureRecipeControls(false)				-- initial setting
	self.craftbenchStandaloneQueue=CraftBench:CreateStandaloneQueueFrame()
	self.fullView = true
	self.saved_full_button_count = 0
	self.saved_SA_button_count = 0
	if self.CreateMainSideToolsDock then
		self:CreateMainSideToolsDock(frame)
	end
	return frame
end

function CraftBench:InitRecipeFilterButtons()
	local lastButton = CraftBenchRecipeDifficultyButton
	if self.recipeFilters then
		for name, filter in pairs(self.recipeFilters) do
			local newButton = filter.initMethod(filter.namespace)
			if newButton then
				newButton:SetParent(CraftBenchFrame)
				newButton:SetPoint("BOTTOMRIGHT", lastButton, "BOTTOMLEFT", -5, 0)
				lastButton = newButton
				newButton:Show()
			end
		end
	end
end

--
-- Resets all the sorting and filtering info for the window
-- This is called when the window has changed enough that
-- sorting or filtering may need to be updated.
--
function CraftBench:ResetTradeSkillWindow()
	--DA.DEBUG(0,"ResetTradeSkillWindow()")
	CraftBench:SortDropdown_OnShow()
	local buttons = CraftBenchFrame.added_buttons
	if buttons then
		local last_button = CraftBenchPluginButton
		for i=1, #buttons, 1 do
			local button = buttons[i]
			if button then
				button:ClearAllPoints()
				button:SetParent(CraftBenchFrame)
				button:SetPoint("TOPLEFT", last_button, "BOTTOMLEFT", 0, -1)
				button:Hide()
				button:SetAlpha(0)
				button:SetFrameLevel(0)
				last_button = button
			end
		end
	 end
end

--
-- Something has changed in the tradeskills, and the window needs to be updated
--
function CraftBench:TradeSkillRank_Updated()
	--DA.DEBUG(0,"TradeSkillRank_Updated()")
	local _, rank, maxRank = self:GetTradeSkillLine();
	if rank and maxRank then
		CraftBenchRankFrame:SetMinMaxValues(0, maxRank);
		CraftBenchRankFrame:SetValue(rank);
		CraftBenchRankFrameSkillRank:SetText(rank.."/"..maxRank);
		for c,s in pairs(CraftBenchRankFrame.subRanks) do
			s:SetMinMaxValues(0, maxRank)
		end
		CraftBenchRankFrame.subRanks.gray:SetValue(maxRank)
	end
	--DA.DEBUG(0,"TradeSkillRank_Updated over")
end

function CraftBench:ClickSkillButton(skillIndex)
	if skillIndex and self.button_count then
		for i=1, self.button_count, 1 do
			local button = _G["CraftBenchScrollButton"..i]
			if button and button.skill and button.skill.skillIndex and button.skill.skillIndex == skillIndex and button:IsVisible() and not button.skill.subGroup then
				button:Click("LeftButton", true);
			end
		end
	end
end

--
-- Called when the list of skills is scrolled
--
function CraftBench:SkillList_OnScroll()
	CraftBench:UpdateTradeSkillWindow()
end

local num_recipe_buttons = 1
local function get_recipe_button(i)
	local button = _G["CraftBenchScrollButton"..i]
	if not button then
		button = CreateFrame("Button", "CraftBenchScrollButton"..i, CraftBenchSkillListParent, "CraftBenchSkillButtonTemplate")
		button:SetParent(CraftBenchSkillListParent)
		button:SetPoint("TOPLEFT", "CraftBenchScrollButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(CraftBenchSkillListParent:GetFrameLevel() + 3)
		num_recipe_buttons = i
	end
	local buttonDrag = _G["CraftBenchScrollButtonDrag"..i]
	if not buttonDrag then
		buttonDrag = CreateFrame("Frame", "CraftBenchScrollButtonDrag"..i, CraftBenchSkillListParent, "CraftBenchSkillButtonDragTemplate")
		buttonDrag:SetParent(CraftBenchSkillListParent)
		buttonDrag:SetPoint("TOPLEFT", "CraftBenchScrollButton"..i, "TOPLEFT")
		buttonDrag:SetFrameLevel(CraftBenchSkillListParent:GetFrameLevel() + 2)
		buttonDrag:Hide()
	end
	if not button.highlight then
		button.index = i
		if UIStyle and UIStyle.ApplyFont then
			local bName = button:GetName()
			UIStyle.ApplyFont(_G[bName.."Level"], 0)
			UIStyle.ApplyFont(_G[bName.."Counts"], 0)
			UIStyle.ApplyFont(_G[bName.."Name"], 0)
			UIStyle.ApplyFont(_G[bName.."Suffix"], 0)
		end
		button.cfRowBg = button:CreateTexture(nil, "BACKGROUND")
		button.cfRowBg:SetAllPoints(button)
		button.cfRowBg:SetColorTexture(0.04, 0.038, 0.032, 0.4)
		button.cfHeaderTop = button:CreateTexture(nil, "BORDER")
		button.cfHeaderTop:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		button.cfHeaderTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
		button.cfHeaderTop:SetHeight(1)
		button.cfHeaderTop:SetColorTexture(0.96, 0.77, 0.43, 0.35)
		button.cfHeaderTop:Hide()
		button.cfHeaderBottom = button:CreateTexture(nil, "BORDER")
		button.cfHeaderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
		button.cfHeaderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
		button.cfHeaderBottom:SetHeight(1)
		button.cfHeaderBottom:SetColorTexture(0, 0, 0, 0.65)
		button.cfHeaderBottom:Hide()
		button.cfAccent = button:CreateTexture(nil, "ARTWORK")
		button.cfAccent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -1)
		button.cfAccent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 1)
		button.cfAccent:SetWidth(2)
		button.cfAccent:Hide()
		button.highlight = CreateFrame("Frame", "CraftBenchScrollHightlight"..i, button)
		button.highlight:SetParent(button)
		button.highlight:SetWidth(290)
		button.highlight:SetHeight(20)
		button.highlight:SetPoint("LEFT", button:GetName(), "LEFT")
		button.highlight:SetPoint("RIGHT", button:GetName(), "RIGHT")
		button:SetFrameLevel(CraftBenchSkillListParent:GetFrameLevel())
		local t = button.highlight:CreateTexture(nil, "ARTWORK")
		t:SetColorTexture(0.96, 0.77, 0.43, 0.22)
		t:SetAllPoints(button.highlight)
		button.highlight.texture = t
		button.highlight:SetAlpha(1)
		button.highlight:Hide()
	end
	if CraftBench.customSkillButtons then
		for n, b in pairs(CraftBench.customSkillButtons) do
			b.initMethod(b.namespace, button, i)
		end
	end
	return button, buttonDrag
end

--
-- Shows a recipe button (in the scrolling list) after doing the
-- required callbacks.
--
local function show_button(button, trade, skill, index, recipeID)
	for i=1, #pre_show_callbacks, 1 do
		local new_button = pre_show_callbacks[i](button, trade, skill, index, recipeID)
		if new_button and new_button ~= button then
			button:Hide() -- hide the old one just in case ....
			button = new_button
		end
	end
	button:Show()
end

--
-- Hides a recipe button (in the scrolling list) after doing the
-- required callbacks.
--
local function hide_button(button, trade, skill, index)
	for i=1, #pre_hide_callbacks, 1 do
		local new_button = pre_hide_callbacks[i](button, trade, skill, index)
		if new_button and new_button ~= button then
			button:Hide() -- hide the old one just in case ....
			button = new_button
		end
	end
	button:Hide()
end

--
-- Hide UI components that cannot be used for crafts and show that
-- that are only applicable to trade skills, as needed
--
function CraftBench:ConfigureRecipeControls(enchant)
	--DA.DEBUG(0,"ConfigureRecipeControls("..tostring(enchant)..")")
	if enchant then
		CraftBenchQueueAllButton:Hide()
		CraftBenchQueueButton:Hide()
		CraftBenchCreateAllButton:Hide()
		CraftBenchCreateButton:Hide()
		CraftBenchQueueParent:Hide()
		CraftBenchStartQueueButton:Hide()
		CraftBenchEmptyQueueButton:Hide()
		CraftBenchItemCountInputBox:Hide()
		CraftBenchSub10Button:Hide()
		CraftBenchSub1Button:Hide()
		CraftBenchAdd1Button:Hide()
		CraftBenchAdd10Button:Hide()
		CraftBenchClearNumButton:Hide()
		CraftBenchQueueOnlyButton:Hide()
		CraftBenchEnchantButton:Show();
	else
		CraftBenchQueueAllButton:Show()
		CraftBenchQueueButton:Show()
		CraftBenchCreateAllButton:Show()
		CraftBenchCreateButton:Show()
		CraftBenchQueueParent:Show()
		CraftBenchStartQueueButton:Show()
		CraftBenchEmptyQueueButton:Show()
		CraftBenchItemCountInputBox:Show()
		CraftBenchSub10Button:Show()
		CraftBenchSub1Button:Show()
		CraftBenchAdd1Button:Show()
		CraftBenchAdd10Button:Show()
		CraftBenchClearNumButton:Show()
		CraftBenchQueueOnlyButton:Show()
		CraftBenchEnchantButton:Hide()
	end
	self:InitRecipeFilterButtons()
	if self.currentPlayer ~= (CraftBench:unitName("player")) then
--
-- Disable processing because this is not the current player
--
		CraftBenchStartQueueButton:Disable()
		CraftBenchCreateAllButton:Disable()
		CraftBenchCreateButton:Disable()
	else
		CraftBenchStartQueueButton:Enable()
		CraftBenchCreateAllButton:Enable()
		CraftBenchCreateButton:Enable()
	end
end

function CraftBench:RecipeDifficultyButton_OnShow()
	local level = self:GetTradeSkillOption("filterLevel")
	local v = 1-level/4
	CraftBenchRecipeDifficultyButtonTexture:SetTexCoord(0,1,v,v+.25)
end

function CraftBench:ShowReagentDetails()
	--DA.DEBUG(0,"ShowReagentDetails()")
	CraftBenchQueueManagementParent:Hide();
	CraftBenchReagentParent:Show()
	CraftBenchReagentParent:SetHeight(reagent_height)
	CraftBench:ReAnchorButtons(CraftBenchReagentParent)
end

--
-- Updates the trade skill window whenever anything has changed,
-- number of skills, skill type, skill level, etc
--
local function getTransmogPrefix(recipe)
	if not recipe or not recipe.itemID or recipe.itemID == 0 then return nil end
	if CanIMogIt and CanIMogIt.GetIconText then
		local _, itemLink = C_Item.GetItemInfo(recipe.itemID)
		if itemLink then
			local icon = CanIMogIt:GetIconText(itemLink)
			if icon and icon ~= "" then
				return icon
			end
		end
	end
	if C_TransmogCollection and C_TransmogCollection.PlayerHasTransmogByItemInfo and C_Item and C_Item.GetItemInfoInstant then
		local _, _, _, equipLoc, _, classID = C_Item.GetItemInfoInstant(recipe.itemID)
		local isGear = (classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon)
			and equipLoc and equipLoc ~= ""
			and equipLoc ~= "INVTYPE_BAG" and equipLoc ~= "INVTYPE_QUIVER"
			and equipLoc ~= "INVTYPE_NECK" and equipLoc ~= "INVTYPE_FINGER" and equipLoc ~= "INVTYPE_TRINKET"
		if isGear or (C_Item.IsCosmeticItem and C_Item.IsCosmeticItem(recipe.itemID)) then
			local _, itemLink = C_Item.GetItemInfo(recipe.itemID)
			local hasTransmog = C_TransmogCollection.PlayerHasTransmogByItemInfo(itemLink or recipe.itemID)
			if hasTransmog then
				return "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12:0:0|t "
			else
				return "|TInterface\\RaidFrame\\ReadyCheck-NotReady:12:12:0:0|t "
			end
		end
	end
	return nil
end

function CraftBench:UpdateTradeSkillWindow()
	--DA.DEBUG(0,"UpdateTradeSkillWindow()")
--[[
	if self.InProgress.main then 
		self.InProgress.mainDepth = self.InProgress.mainDepth + 1
		self.InProgress.mainMax = max(self.InProgress.mainMax,self.InProgress.mainDepth)
--		return
	else
		self.InProgress.mainDepth = 1
		self.InProgress.mainMax = 1
	end
--]]
	self.InProgress.main = true
	self:NameEditSave()
	if not self.currentPlayer or not self.currentTrade then 
		--DA.DEBUG(0,"UpdateTradeSkillWindow: leaving early, no player or no trade")
		return
	end
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
	local numTradeSkills = 0
	if not self.dataScanned then
		self.dataScanned = self:RescanTrade()
		self:SortAndFilterRecipes()
	end
	if not self.data.sortedSkillList[skillListKey] then
		numTradeSkills = self:SortAndFilterRecipes()
		if not numTradeSkills or numTradeSkills < 1 then
			numTradeSkills = 0
		end
	end
	self:ResetTradeSkillWindow()
	if self.data.sortedSkillList[skillListKey] then
		numTradeSkills = self.data.sortedSkillList[skillListKey].count
	else
		numTradeSkills = 0
	end
	self:UpdateDetailWindow(self.selectedSkill)
	self:UpdateTradeButtons(self.currentPlayer)
	self:UpdateIgnoredMatsButton()
	CraftBenchIgnoredMatsButton:Show()
--
-- Plugin button only shows if any plugins have registered
--
	if CraftBenchPluginButton and CraftBenchFrame.added_buttons and #CraftBenchFrame.added_buttons > 0 then
		CraftBenchPluginButton:Show()
	else
		CraftBenchPluginButton:Hide()
	end
--
-- If any plugins have registered an Update function, call it now
--
	self:UpdatePlugins()
--
-- shopping list button always shown
--
	CraftBenchShoppingListButton:Show()
	CraftBenchFrame:SetAlpha(self.db.profile.transparency)
	CraftBenchFrame:SetScale(self.db.profile.scale)
	local uiScale = CraftBenchFrame:GetEffectiveScale()
	local width = CraftBenchFrame:GetWidth() - 20 -- for padding.
	local height = CraftBenchFrame:GetHeight()
	local reagent_width = width / 2
	reagent_height = CRAFTBENCH_REAGENT_MIN_HEIGHT + ((height - CRAFTBENCH_MIN_HEIGHT) * 2) / 3
	--DA.DEBUG(0,"UpdateTradeSkillWindow: fullView="..tostring(self.fullView)..", reagent_height="..string.format("%.0d", reagent_height))
	if not self.fullView then
		reagent_height = CRAFTBENCH_REAGENT_MIN_HEIGHT + height - CRAFTBENCH_MIN_HEIGHT + 85
		--DA.DEBUG(0,"UpdateTradeSkillWindow: new_reagent_height="..string.format("%.0d", reagent_height))
	end
	if reagent_width < CRAFTBENCH_REAGENT_MIN_WIDTH then
		reagent_width = CRAFTBENCH_REAGENT_MIN_WIDTH
	elseif reagent_width > CRAFTBENCH_REAGENT_MAX_WIDTH then
		reagent_width = CRAFTBENCH_REAGENT_MAX_WIDTH
	end
	CraftBenchReagentParent:SetWidth(reagent_width)
	CraftBenchReagentParent:SetHeight(reagent_height)
	CraftBenchRankFrame:SetWidth(reagent_width)
	CraftBenchQueueManagementParent:SetWidth(reagent_width)
	width = CraftBenchFrame:GetWidth() - reagent_width - 20 -- padding
	CraftBenchSkillListParent:SetWidth(width)
	--DA.DEBUG(0,"UpdateTradeSkillWindow: width= "..string.format("%.0d", width)..", height= "..string.format("%.0d", height)..", reagent_width= "..string.format("%.0d", reagent_width)..", reagent_height= "..string.format("%.0d", reagent_height))
--
-- Set the state of any craft specific options
--
	self:RecipeDifficultyButton_OnShow()
	if CraftBench.isRetail then
		CraftBenchUseHighestQuality:SetChecked(self.db.profile.best_quality)
		CraftBenchUseHighestQuality:Show()
		CraftBenchUseConcentration:SetChecked(self.db.profile.use_concentration)
		CraftBenchUseConcentration:Show()
	else
		CraftBenchUseHighestQuality:Hide()
		CraftBenchUseConcentration:Hide()
	end
	CraftBenchHideUncraftableRecipes:SetChecked(self:GetTradeSkillOption("hideuncraftable"))
	C_TradeSkillUI.SetOnlyShowMakeableRecipes(self:GetTradeSkillOption("hideuncraftable"))
	self:UpdateQueueWindow()
	self:UpdateShoppingListWindow()
	self:FavoritesOnlyRefresh()
--
-- Window Title
--
	local tradeName = self:GetTradeName(self.currentTrade)
	if not tradeName then tradeName = "" end
	local title = _G["CraftBenchTitleText"];
	if title then
		title:SetText(L["CraftBench Trade Skills"] .. " "..self.version..": " .. self.currentPlayer .. "/" .. tradeName)
	end
	local sortedSkillList = self.data.sortedSkillList[skillListKey]
	local rank,maxRank = 0,0
	local skillRanks = self:GetSkillRanks(self.currentPlayer, self.currentTrade)
	if skillRanks then
		rank,maxRank = skillRanks.rank, skillRanks.maxRank
	end
--
-- Progression status bar
--
	CraftBenchRankFrame:SetMinMaxValues(0, maxRank)
	CraftBenchRankFrame:SetValue(rank)
	CraftBenchRankFrameSkillRank:SetText(tradeName.."    "..rank.."/"..maxRank)
	CraftBenchRankFrame.subRanks.gray:SetValue(maxRank)
	for c,s in pairs(CraftBenchRankFrame.subRanks) do
		s:SetMinMaxValues(0, maxRank)
	end
--
-- it seems the resize for the main craftbench window happens before the resize for the skill list box
--
	local button_count = (CraftBenchFrame:GetHeight() - CRAFTBENCH_HEADER_HEIGHT) / CRAFTBENCH_TRADE_SKILL_HEIGHT
	button_count = math.floor(button_count)
	self.button_count = button_count
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(CraftBenchSkillList,				-- frame
							numTradeSkills,					-- num items
							button_count,					-- num to display
							CRAFTBENCH_TRADE_SKILL_HEIGHT)		-- value step (item height)
--
-- Where in the list of skill to start counting.
--
	local skillOffset = FauxScrollFrame_GetOffset(CraftBenchSkillList);
--
-- Remove any selected highlight, it will be added back as needed
--
	CraftBenchHighlightFrame:Hide();
	local nilFound = false
	width = CraftBenchSkillListParent:GetWidth() - 10
	if CraftBenchSkillList:IsVisible() then
--
-- Adjust for the width of the scroll bar, if it is visible.
--
		width = width - 20
	end
	local text
	local pretext, preid, prelink
	local max_text_width = width
	local showOwned = self:GetTradeSkillOption("filterInventory-owned") -- count from Altoholic
	local showBag = self:GetTradeSkillOption("filterInventory-bag")
	local showCraft = self:GetTradeSkillOption("filterInventory-crafted")
	local showVendor = self:GetTradeSkillOption("filterInventory-vendor")
	local showAlts = self:GetTradeSkillOption("filterInventory-alts")
	local catstring = {}
	CraftBenchFrameEmptySpace.skill.subGroup = self:RecipeGroupFind(self.currentPlayer,self.currentTrade,self.currentGroupLabel,self.currentGroup)
	--DA.DEBUG(0,"UpdateTradeSkillWindow: GroupLabel= "..tostring(self.currentGroupLabel)..", Group= "..tostring(self.currentGroup))
	self.visibleSkillButtons = math.min(numTradeSkills - skillOffset, button_count)
--
-- Iterate through all the buttons that make up the scroll window
-- and fill them in with data or hide them, as necessary
--
	--DA.DEBUG(0,"UpdateTradeSkillWindow: Start for loop, button_count= "..tostring(button_count))
	for i=1, button_count, 1 do
		local rawSkillIndex = i + skillOffset
		local button, buttonDrag = get_recipe_button(i)
		button.rawIndex = rawSkillIndex
		button:SetWidth(width)
		if rawSkillIndex <= numTradeSkills then
			local skill = sortedSkillList[rawSkillIndex]
			--DA.DEBUG(2,"UpdateTradeSkillWindow: rawSkillIndex= "..tostring(rawSkillIndex)..", name= "..tostring(skill.name))
			--DA.DEBUG(3,"UpdateTradeSkillWindow: skill= "..DA.DUMP(skill,1))
			local skillIndex = skill.skillIndex
			local buttonText = _G[button:GetName() .. "Name"]
			local levelText = _G[button:GetName() .. "Level"]
			local countText = _G[button:GetName() .. "Counts"]
			local suffixText = _G[button:GetName() .. "Suffix"]
			local buttonExpand = _G[button:GetName() .. "Expand"]
			local buttonFavorite = _G[button:GetName() .. "Favorite"]
			local subSkillRankBar = _G[button:GetName() .. "SubSkillRankBar"]
--
-- Blizzard's Cooking database is FUBAR, fix it
--
			if self.FixBugs then
				if skill.name == "Food of Draenor - Header" then 
					DA.DEBUG(2,"UpdateTradeSkillWindow: FixBugs")
					--DA.DEBUG(3,"UpdateTradeSkillWindow: skill= "..DA.DUMP(skill,1))
					skill.name = "Food of Draenor"
				elseif skill.name == "Cucina di Draenor - Titolo" then 
					DA.DEBUG(2,"UpdateTradeSkillWindow: FixBugs")
					--DA.DEBUG(3,"UpdateTradeSkillWindow: skill= "..DA.DUMP(skill,1))
					skill.name = "Cucina di Draenor"
				end
			end
--
-- end of FUBAR fixes
--
			local hasProgressBar = CraftBench.hasProgressBar[skill.name]
			buttonText:SetText("")
			levelText:SetText("")
			countText:SetText("")
			countText:Hide()
			countText:SetWidth(10)
			suffixText:SetText("")
			suffixText:Hide()
			subSkillRankBar:Hide()
			if skill.subGroup then
				levelText:SetWidth(math.max(skill.depth * 6, 2))
			elseif self.db.profile.display_required_level then
				levelText:SetWidth(20 + math.max(skill.depth - 1, 0) * 4)
			else
				levelText:SetWidth(math.max(skill.depth * 6, 2))
			end
			buttonFavorite:Hide()
			local textAlpha = 1
			if self.dragEngaged then
				buttonDrag:SetWidth(width)
				button.highlight:Hide()
				if CraftBench.mouseOver then
					if CraftBench.mouseOver.skill.subGroup then
						if button == CraftBench.mouseOver then
							button.highlight:Show()
						end
					elseif skill.subGroup == CraftBench.mouseOver.skill.parent then
						button.highlight:Show()
					end
				end
				textAlpha = .75
				local dx = self.selectedTextOffsetXY[1] / uiScale
				local dy = self.selectedTextOffsetXY[2] / uiScale
				buttonDrag:SetPoint("TOPLEFT", button, "TOPLEFT", buttonDrag.skill.depth*8-8+dx, dy)
			else
				if skill.selected then
					button.highlight:Show()
				else
					button.highlight:Hide()
				end
			end
			if self.currentGroupLabel ~= "Blizzard" then 
				DA.DEBUG(0,"UpdateTradeSkillWindow: skill.subGroup = "..tostring(skill.subGroup))
			end
			UIStyle.ApplyFont(buttonText, -1)
			UIStyle.ApplyFont(countText, -1)
			UIStyle.ApplyFont(suffixText, -1)
			if skill.subGroup then
				UIStyle.ApplyFont(buttonText, 0)
				if button.cfRowBg then
					button.cfRowBg:SetColorTexture(0.17, 0.135, 0.075, 0.92)
				end
				if button.cfHeaderTop then
					button.cfHeaderTop:Show()
				end
				if button.cfHeaderBottom then
					button.cfHeaderBottom:Show()
				end
				if button.cfAccent then
					button.cfAccent:SetWidth(3)
					button.cfAccent:SetColorTexture(0.96, 0.77, 0.43, 0.95)
					button.cfAccent:Show()
				end
				if SkillButtonNameEdit.originalButton ~= buttonText then
					buttonText:SetTextColor(1.0, 0.85, 0.48, textAlpha)
					countText:SetTextColor(0.96, 0.77, 0.43, textAlpha)
					local expanded = skill.subGroup.expanded
					if expanded then
						buttonExpand:SetNormalTexture("Interface\\Addons\\CraftBench\\Icons\\expand_arrow_open.tga")
						buttonExpand:SetHighlightTexture("Interface\\Addons\\CraftBench\\Icons\\expand_arrow_open.tga")
					else
						buttonExpand:SetNormalTexture("Interface\\Addons\\CraftBench\\Icons\\expand_arrow_closed.tga")
						buttonExpand:SetHighlightTexture("Interface\\Addons\\CraftBench\\Icons\\expand_arrow_closed.tga")
					end
					local name = strsplit(":", skill.name).." ("..#skill.subGroup.entries..")"
					buttonText:SetText(name)
					button:SetID(skillIndex or 0)
					buttonExpand.group = skill.subGroup
					button.skill = skill
					button:UnlockHighlight() -- headers never get highlighted
					buttonExpand:Show()
					if hasProgressBar then
						local category = CraftBench.db.global.Categories[self.currentTrade][hasProgressBar]
						local currentRank = category.skillLineCurrentLevel
						local startingRank = category.skillLineStartingRank
						local maxRank = category.skillLineMaxLevel
						--DA.DEBUG(0,"UpdateTradeSkillWindow: "..tostring(skill.name).." ("..tostring(hasProgressBar)..")"..", category= "..DA.DUMP1(category))
						subSkillRankBar:Show();
						subSkillRankBar:SetMinMaxValues(startingRank,maxRank);
						subSkillRankBar:SetValue(currentRank);
						subSkillRankBar.currentRank = currentRank;
						subSkillRankBar.maxRank = maxRank;
						subSkillRankBar.Rank:SetText(currentRank.."/"..maxRank);
					end
					local button_width = button:GetTextWidth()
					show_button(button, self.currentTrade, skillIndex, i)
				end
			else
				if button.cfRowBg then
					if i % 2 == 0 then
						button.cfRowBg:SetColorTexture(0.055, 0.050, 0.042, 0.45)
					else
						button.cfRowBg:SetColorTexture(0.030, 0.028, 0.024, 0.25)
					end
				end
				if button.cfHeaderTop then
					button.cfHeaderTop:Hide()
				end
				if button.cfHeaderBottom then
					button.cfHeaderBottom:Hide()
				end
				if button.cfAccent then
					button.cfAccent:SetWidth(2)
					if skill.selected then
						button.cfAccent:SetColorTexture(0.96, 0.77, 0.43, 1)
						button.cfAccent:Show()
					else
						button.cfAccent:Hide()
					end
				end
				--DA.DEBUG(0,"UpdateTradeSkillWindow: currentTrade= "..tostring(self.currentTrade)..", Process '"..tostring(skill.name).."'("..tostring(skill.recipeID).."), skillIndex= "..tostring(skillIndex))
				local recipe = self:GetRecipe(skill.recipeID)
				buttonExpand.group = nil
				button.skill = skill
				local skill_color = CraftBench.skill_style_type[recipe.difficulty] or skill.color or skill.skillData.color or NORMAL_FONT_COLOR
				buttonText:SetTextColor(skill_color.r, skill_color.g, skill_color.b, textAlpha)
				countText:SetTextColor(skill_color.r, skill_color.g, skill_color.b, textAlpha)
				buttonExpand:Hide()
				buttonFavorite.skill = skill
				buttonFavorite.SetFavorite = function(self, state)
					if state then
						self:GetNormalTexture():SetAlpha(0.5)
					else
						self:GetNormalTexture():SetAlpha(0)
					end
				end
				buttonFavorite:SetFavorite(CraftBench:IsFavorite(skill.recipeID))
				buttonFavorite:Show()
--
-- If the item has a minimum level requirement, then print that here
--
				if self.db.profile.display_required_level then
					local level = self:GetLevelRequiredToUse(recipe.itemID)
					if level and level > 1 then
						local _, _, rarity = C_Item.GetItemInfo("item:"..recipe.itemID)
						local r, g, b = C_Item.GetItemQualityColor(rarity)
						if r and g and b then
							levelText:SetTextColor(r, g, b)
						end
						levelText:SetText(level)
					end
				end
--
-- Check for prefix information returned from a plugin. Most will return just text (which could be an icon)
-- Some may return additional information so store that in the button for later use.
--
				pretext, preid, prelink = self:RecipeNamePrefix(skill, recipe)
				if not pretext or pretext == "" then
					pretext = getTransmogPrefix(recipe)
				end
				if pretext then
					button.pretext = pretext
				end
				if preid then
					button.preid = preid
				end
				if prelink then
					button.prelink = prelink
				end
--
-- Set the prefix and name of the recipe
--
				text = (pretext and pretext ~= "" and (pretext .. " ") or "") .. (skill.name or "")
				local diff = skill.difficulty or (skill.skillData and skill.skillData.difficulty)
				if diff and diff ~= "trivial" and diff ~= "header" and self.GetSkillUpChance then
					local chance = self:GetSkillUpChance(recipe, nil, diff)
					if chance and chance > 0 then
						local pct = math.floor(chance * 100 + 0.5)
						local pctColor = (pct >= 80 and "|cffff8040") or (pct >= 40 and "|cffffff00") or "|cff40bf40"
						text = text .. " " .. pctColor .. pct .. "%|r"
					end
				end
--
-- Prepare the counts (displayed on the right)
--
				local num, numrecursive, numwvendor, numwalts, numbank = get_craftable_counts(skill.skillData, recipe.numMade)
				if (num > 0 and showBag) or (numrecursive > 0 and showCraft) or (numwvendor > 0 and showVendor) or (numwalts > 0 and showAlts) or (numbank > 0 and showBag) then
					local c = 1
					if showBag then
						local numColor = (num > 0) and CBAG or CGREY
						if num >= 1000 then
							num = "##"
						end
						catstring[c] = numColor..num
						c = c + 1
						if numbank > 0 then
							if numbank >= 1000 then
								numbank = "##"
							end
							catstring[c] = CBANK..numbank
							c = c + 1
						end
					end
					if showCraft then
						if numrecursive >= 1000 then
							numrecursive = "##"
						end
						catstring[c] = CCRAFT..numrecursive
						c = c + 1
					end
					if showVendor then
						if numwvendor >= 1000 then
							numwvendor = "##"
						end
						catstring[c] = CVENDOR..numwvendor
						c = c + 1
					end
					if showAlts then
						if numwalts >= 1000 then
							numwalts = "##"
						end
						catstring[c] = CALTS..numwalts
						c = c + 1
					end
					local count = ""
					if c > 1 then
						count = CGREY.."["
						for b=1,c-1 do
							count = count..catstring[b]
							if b+1 < c then
								count = count..CGREY.."/"
							end
						end
						count = count..CGREY.."]|r"
					end
					countText:SetText(count)
					countText:Show()
				else
					countText:Hide()
				end
--
-- Show the count of the item currently owned that the recipe will produce
--
				if showOwned and self.currentPlayer == CraftBench:unitName("player") then
					local numowned = (self.db.realm.auctionData[self.currentPlayer][recipe.itemID] or 0) + C_Item.GetItemCount(recipe.itemID,true)
					if numowned > 0 then
						if numowned >= 1000 then
							numowned = "##"
						end
						local count = COWNED.."("..numowned..") "..(countText:GetText() or "")
						countText:SetText(count)
						countText:Show()
					end
				end
				if skill_color.alttext == "+++" then
					local numSkillUps = recipe.numSkillUps
					if numSkillUps and numSkillUps > 1 then
						local count = "<+"..numSkillUps.."> "..(countText:GetText() or "")
						countText:SetText(count)
						countText:Show()
					end
				end
				countText:SetWidth(math.max(countText:GetStringWidth(),CRAFTBENCH_COUNT_MIN_WIDTH)) -- make end of buttonText have a fixed location
				button:SetID(skillIndex or 0)
--
-- If enhanced recipe display is enabled, show the difficulty as text,
-- rather than as a colour. This should help used that have problems
-- distinguishing between the difficulty colours we use.
--
				if self.db.profile.enhanced_recipe_display then
					text = text .. skill_color.alttext;
				end
--
-- If this recipe is upgradable, append the current and maximum upgrade levels
--
				--DA.DEBUG(0,"UpdateTradeSkillWindow: skill= "..DA.DUMP1(skill,1))
				local recipeInfo = CraftBench.data.recipeInfo[self.currentTrade][skill.recipeID]
				--DA.DEBUG(0,"UpdateTradeSkillWindow: recipeInfo= "..DA.DUMP1(recipeInfo))
				if recipeInfo and recipeInfo.upgradeable then
					if CraftBench.db.profile.show_max_upgrade then
						text = text .. " ("..tostring(recipeInfo.recipeUpgrade).."/"..tostring(recipeInfo.maxUpgrade)..")"
					else
						text = text .. " ("..tostring(recipeInfo.recipeUpgrade)..")"
					end
				end
--
-- Check for suffix information returned from a plugin
--
				suffixText:SetText(self:RecipeNameSuffix(skill, recipe) or "")
				suffixText:Show()
--
-- When displaying both learned and unlearned, add a "-" to the name of unlearned recipes
--
				if self.learnedRecipes and self.unlearnedRecipes then
					if recipeInfo and not recipeInfo.learned then
						text = "-"..text
					end
				end
				buttonText:SetText(text)
				buttonText:SetWordWrap(false)
--
-- Adjust the width of this line
--
				buttonText:SetWidth(max_text_width - countText:GetWidth())
--
-- Set this line's highlight and color
--
				if not self.dragEngaged and self.selectedSkill and self.selectedSkill == skillIndex then
					CraftBenchHighlightFrame:SetPoint("TOPLEFT", "CraftBenchScrollButton"..i, "TOPLEFT", 0, 0)
					CraftBenchHighlightFrame:SetWidth(button:GetWidth())
					CraftBenchHighlightFrame:SetFrameLevel(button:GetFrameLevel())
					if color then
						CraftBenchHighlight:SetColorTexture(color.r, color.g, color.b, 0.4)
					else
						CraftBenchHighlight:SetColorTexture(0.7, 0.7, 0.7, 0.4)
					end
--
-- Update the details for this skill, just in case something
-- has changed (mats consumed, etc)
--
					self:UpdateDetailWindow(self.selectedSkill)
					CraftBenchHighlightFrame:Show()
					button:LockHighlight()
				else
--
-- Not selected
--
					button:UnlockHighlight()
				end
				--DA.DEBUG(0,"UpdateTradeSkillWindow: show_button, skillIndex= "..tostring(skillIndex))
				show_button(button, self.currentTrade, skillIndex, i, skill.recipeID)
			end
		else -- rawSkillIndex > numTradeSkills 
			--DA.DEBUG(0,"UpdateTradeSkillWindow: hide_button, skillIndex= "..tostring(skillIndex))
			hide_button(button, self.currentTrade, skillIndex, i)
			button:UnlockHighlight()
		end
	end -- for
--
-- Hide any of the buttons that we created but don't need right now
--
	for i = button_count+1, num_recipe_buttons, 1 do
		local button, buttonDrag = get_recipe_button(i)
		hide_button(button, self.currentTrade, 0, i)
	end
	if self.visibleSkillButtons > 0 then
		local button = get_recipe_button(self.visibleSkillButtons)
		CraftBenchFrameEmptySpace:SetPoint("TOPLEFT",button,"BOTTOMLEFT")
	else
		CraftBenchFrameEmptySpace:SetPoint("TOPLEFT",CraftBenchSkillListParent,"TOPLEFT")
	end
	CraftBenchFrameEmptySpace:SetPoint("BOTTOMRIGHT",CraftBenchSkillListParent,"BOTTOMRIGHT")
	self.InProgress.main = false
--	self.InProgress.mainDepth = self.InProgress.mainDepth - 1
	--DA.DEBUG(3,"UpdateTradeSkillWindow Complete")
end

--
-- Display an action packed tooltip when we are over
-- a recipe in the list of skills
--
function CraftBench:SkillButton_OnEnter(button)
	--DA.DEBUG(0,"SkillButton_OnEnter("..tostring(button)..")")
	local id = button:GetID()
	if not id then
		return
	end
	if button.locked then return end	-- it's possible that multiple onEnters might stack ontop of each other if you scroll really quickly, this is to avoid that problem
	button.locked = true
	local b = button:GetName()
	if not b then
		button.locked = false
		return
	end
	local buttonName = _G[b.."Name"]
	if button.skill.subGroup then			-- header
		buttonName:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		button.locked = false
		return
	end
	if self.dragEngaged then		-- dragging a skill, don't highlight other buttons
		button.locked = false
		return
	end
	local skill = button.skill
	--DA.DEBUG(1,"SkillButton_OnEnter: skill= "..DA.DUMP1(skill,1))
	if not skill then
		button.locked = false
		return
	end
	if self.fencePickEngaged then
		self:SkillButton_ClearSelections()
		self:SkillButton_SetSelections(self.skillMainSelection, button.rawIndex)
		self:UpdateTradeSkillWindow()
		button.locked = false
		return
	end
	buttonName:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	local recipe = self:GetRecipe(skill.recipeID) or CraftBench.unknownRecipe
	if not self.db.profile.show_detailed_recipe_tooltip then
--
-- User does not want the tooltip displayed, it can get a bit big after all
--
		button.locked = false
		return
	end
	local tip = GameTooltip -- CraftBenchTradeskillTooltip
	tip:SetOwner(button, "ANCHOR_RIGHT", 8, 0)
	if not tip.SetBackdrop then
		Mixin(tip, BackdropTemplateMixin)
	end
	tip:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
	if tip.SetBackdropBorderColor then
		tip:SetBackdropBorderColor(0.75, 0.62, 0.30, 0.9)
	end
	tip:ClearLines()
	tip:SetClampedToScreen(true)
--
-- Set the tooltip's scale to match that of the default UI
--
	local uiScale = 1.0;
	if CraftBench.db.profile.scale_tooltip then
		if tip == GameTooltip and not CraftBench.gttScale then
			CraftBench.gttScale = GameTooltip:GetScale()
		end
		if ( GetCVar("useUiScale") == "1" ) then
			uiScale = tonumber(GetCVar("uiscale"))
		end
		if CraftBench.db.profile.ttscale then
			uiScale = uiScale * CraftBench.db.profile.ttscale
		end
		tip:SetScale(uiScale)
	end
--
-- Name of the recipe
--
		local color = CraftBench.skill_style_type[skill.difficulty]
		if (color) then
			tip:AddLine(skill.name, color.r, color.g, color.b, false)
		else
			tip:AddLine(skill.name, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, false)
		end
--
--	Add CraftBench specific information to the tooltip
--
	local num, numrecursive, numwvendor, numwalts, numbank = 0, 0, 0, 0, 0
	if skill.skillData then
		num, numrecursive, numwvendor, numwalts, numbank = get_craftable_counts(skill.skillData, recipe.numMade)
	end
	local numowned = C_Item.GetItemCount(recipe.itemID,true,false,true,true)
	local hasCounts = (numowned > 0) or (num > 0) or (numrecursive > 0)
		or (numbank and numbank > 0 and numbank ~= num)
		or (numwvendor and numwvendor > 0 and numwvendor ~= num)
		or (numwalts and numwalts > 0 and numwalts ~= num)
	if hasCounts then
		tip:AddLine(" ")
	end
	if numowned > 0 then
		tip:AddDoubleLine(L["in your inventory"], COWNED..numowned.."|r", 0.82, 0.82, 0.82, 1, 1, 1)
	end
	if num > 0 then
		tip:AddDoubleLine(L["can be created from reagents in your inventory"], CBAG..num.."|r", 0.82, 0.82, 0.82, 1, 1, 1)
	end
	if numbank and numbank > 0 and numbank ~= num then
		if numbank >= 1000 then
			numbank = "##"
		end
		tip:AddDoubleLine(L["can be created with reagents in your bank"], CBANK..numbank.."|r", 0.82, 0.82, 0.82, 1, 1, 1)
	end
	if numrecursive > 0 then
		tip:AddDoubleLine(L["can be created by crafting reagents"], CCRAFT..numrecursive.."|r", 0.82, 0.82, 0.82, 1, 1, 1)
	end
	if numwvendor and numwvendor > 0 and numwvendor ~= num then
		if numwvendor >= 1000 then
			numwvendor = "##"
		end
		tip:AddDoubleLine(L["can be created with reagents bought at vendor"], CVENDOR..numwvendor.."|r", 0.82, 0.82, 0.82, 1, 1, 1)
	end
	if numwalts and numwalts > 0 and numwalts ~= num then
		if numwalts >= 1000 then
			numwalts = "##"
		end
		tip:AddDoubleLine(L["can be created from reagents on all characters"], CALTS..numwalts.."|r", 0.82, 0.82, 0.82, 1, 1, 1)
	end
--
-- Now the list of regents for this recipe and some info about them
--
	tip:AddLine(" ")
	local text
	if self.isRetail then
		text = string.format("|cff808080[%s/%s]|r", L["Inventory"], L["Craftable"])
	else
		text = string.format("|cff808080[%s||%s/%s]|r", L["Bags"], L["Inventory"], L["Craftable"])
	end
	tip:AddDoubleLine(SPELL_REAGENTS, text)
	for i=1,#recipe.reagentData do
		local reagent = recipe.reagentData[i]
		if not reagent then
			break
		end
		local numInBags, numInBoth, numCraftable = self:GetInventory(self.currentPlayer, reagent.reagentID)
		local itemName = C_Item.GetItemInfo(reagent.reagentID) or reagent.reagentID
		if self:VendorSellsReagent(reagent.reagentID) then
			text = string.format("  %d x %s  |cff808080(%s)|r", reagent.numNeeded, itemName, L["buyable"])
		else
			text = string.format("  %d x %s", reagent.numNeeded, itemName)
		end
		local counts
		if self.isRetail then
			counts = string.format("|cff808080[%d/%d]|r", numInBoth, numCraftable)
		else
			counts = string.format("|cff808080[%d||%d/%d]|r", numInBags, numInBoth, numCraftable)
		end
		tip:AddDoubleLine(text, counts, 1, 1, 1)
	end
	if recipe.modifiedData then
		for i=1,#recipe.modifiedData do
			local numInBags, numInBoth, numCraftable = self:GetInventory(self.currentPlayer, recipe.modifiedData[i].schematic.reagents)
			local itemName = C_Item.GetItemInfo(recipe.modifiedData[i].reagentID) or recipe.modifiedData[i].reagentID
			local text
			text = string.format("  %d x %s", recipe.modifiedData[i].numNeeded, itemName)
			local counts
			counts = string.format("|cff808080[%d/%d]|r", numInBoth, numCraftable)
			tip:AddDoubleLine(text, counts, 1, 1, 1)
		end
	end
--	local text = string.format("[%s/%s]", L["Inventory"], L["Craftable"])
--	tip:AddDoubleLine("\n", text)
	local showSource = CraftBench.db.profile.show_recipe_source_for_learned
	if not showSource then
		local rInfo = C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo and skill.id and C_TradeSkillUI.GetRecipeInfo(skill.id)
		if rInfo and not rInfo.learned then
			showSource = true
		elseif skill.learned == false or (recipe and recipe.learned == false) then
			showSource = true
		end
	end
	local sourceText = showSource and C_TradeSkillUI and C_TradeSkillUI.GetRecipeSourceText and skill.id and C_TradeSkillUI.GetRecipeSourceText(skill.id) or nil
	if showSource and (not sourceText or sourceText == "") and CraftBench.ATTPlugin and CraftBench.ATTPlugin.GetRecipeSource then
		sourceText = CraftBench.ATTPlugin.GetRecipeSource(skill, recipe)
	end
	if sourceText and sourceText ~= "" then
		tip:AddLine(" ")
		tip:AddLine(L["Source"] .. ":", 1.0, 0.82, 0.0, false)
		for line in sourceText:gsub("|n", "\n"):gmatch("[^\r\n]+") do
			tip:AddLine("  " .. line, 0.96, 0.77, 0.43, false)
		end
	end
	if self.AddSkillUpTooltipInfo then
		self:AddSkillUpTooltipInfo(tip, skill, recipe)
	end
	if self.GetRecipeCostAndProfit then
		local cost, value, profit = self:GetRecipeCostAndProfit(recipe)
		if cost and value then
			local fmt = function(c)
				local absC = math.floor(math.abs(c))
				if self.FormatMoneyFull then
					return self:FormatMoneyFull(absC, true)
				elseif GetCoinTextureString then
					return GetCoinTextureString(absC)
				end
				return tostring(absC)
			end
			tip:AddLine(" ")
			tip:AddDoubleLine(L["Craft Cost"] .. ":", fmt(cost), 0.82, 0.82, 0.82, 1, 1, 1)
			tip:AddDoubleLine(L["Sell Value"] .. ":", fmt(value), 0.82, 0.82, 0.82, 1, 1, 1)
			local sign = profit >= 0 and "+" or "-"
			local pr, pg, pb = 0.2, 1.0, 0.2
			if profit < 0 then
				pr, pg, pb = 1.0, 0.3, 0.3
			end
			tip:AddDoubleLine(L["Profit"] .. ":", sign .. fmt(profit), 1.0, 0.82, 0.0, pr, pg, pb)
		end
	end
	tip:AddLine(" ")
	local text1 = string.format("recipeID= %d",skill.recipeID)
	local item = string.format("itemID= %d",recipe.itemID)
	local scroll = string.format("scrollID= %d", CraftBench.scrollData[skill.recipeID])
	--DA.DEBUG(1,"SkillButton_OnEnter: recipeID= "..tostring(skill.recipeID)..", scrollData= "..tostring(CraftBench.scrollData[skill.recipeID]))
	if CraftBench.scrollData[skill.recipeID] then
		tip:AddDoubleLine(text1, scroll)
	elseif recipe.recipeType == Enum.TradeskillRecipeType.Enchant then
		tip:AddDoubleLine(text1, "Enchant")
	elseif recipe.itemID and recipe.itemID ~= 0 then
		tip:AddDoubleLine(text1, item)
	else 
		tip:AddDoubleLine(text1, "itemID= nil")
	end
	tip:Show()
	button.locked = false
end

--
-- Sets the game tooltip item to the selected skill
--
function CraftBench:SetTradeSkillToolTip(skillIndex)
	--DA.DEBUG(2,"SetTradeSkillToolTip("..tostring(skillIndex)..", "..tostring(onEvent)..")")
	GameTooltip:ClearLines()
	if CraftBench.db.profile.scale_tooltip then
		local uiScale = 1.0;
		if ( GetCVar("useUiScale") == "1" ) then
			uiScale = tonumber(GetCVar("uiscale"))
		end
		if CraftBench.db.profile.ttscale then
			uiScale = uiScale * CraftBench.db.profile.ttscale
		end
		GameTooltip:SetScale(uiScale)
	end
	local recipe, recipeID = self:GetRecipeDataByTradeIndex(self.currentTrade, skillIndex)
	if recipe then
		if recipe.itemID ~= 0 then
			if self.currentTrade == 7411 then		-- Enchanting
				GameTooltip:SetHyperlink("item:"..recipe.itemID)
			else
				GameTooltip:SetHyperlink(C_TradeSkillUI.GetRecipeItemLink(recipeID))
			end
			if IsShiftKeyDown() then
				GameTooltip_ShowCompareItem()
			end
		else
			--DA.DEBUG(2,"SetTradeSkillToolTip: Using SetHyperlink (spellID)")
			GameTooltip:SetHyperlink("enchant:"..recipe.spellID)				-- doesn't create an item, just tell us about the recipe
		end
	end
	GameTooltip:Show()
	CursorUpdate(self)
end

--
-- Clears any changes and hides the game tooltip
--
function CraftBench:ClearTradeSkillToolTip(skillIndex)
	if CraftBench.db.profile.scale_tooltip then
		GameTooltip:SetScale(CraftBench.gttScale)
	end
	GameTooltip:Hide()
	ResetCursor()
end

CraftBench.bopCache = {}
function CraftBench:bopCheck(item)
	--DA.DEBUG(0,"bopCheck("..tostring(item)..")")
	if not self.bopCache[item] then
		local _, link, _, _, _, _, _, _, _, _, _, _, _, bindType, _, _, _ = C_Item.GetItemInfo(item)
		--DA.DEBUG(0,"bopCheck: bindType= "..tostring(bindType))
		self.bopCache[item] = bindType or 0	-- Item binding type: 0 - none; 1 - on pickup; 2 - on equip; 3 - on use; 4 - quest
	end
	if self.bopCache[item] == 1 then
		return true
	end
	return false
end

function CraftBench:SkillButton_SetSelections(id1, id2)
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
	local sortedSkillList = self.data.sortedSkillList[skillListKey]
	if id1 > id2 then id1,id2 = id2,id1 end
	for i=1,sortedSkillList.count do
		if i>=id1 and i<=id2 then
			sortedSkillList[i].selected = true
		else
			sortedSkillList[i].selected = false
		end
	end
end

function CraftBench:SkillButton_SetAllSelections(toggle)
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
	local sortedSkillList = self.data.sortedSkillList[skillListKey]
	for i=1,sortedSkillList.count do
		sortedSkillList[i].selected = toggle
	end
end

function CraftBench:SkillButton_ClearSelections()
	self:SkillButton_SetAllSelections(false)
end

function CraftBench:NameEditSave()
	if SkillButtonNameEdit:IsVisible() and SkillButtonNameEdit.originalButton then
		SkillButtonNameEdit.originalButton:SetText(SkillButtonNameEdit:GetText())
		self:RecipeGroupRenameEntry(SkillButtonNameEdit.skill, SkillButtonNameEdit:GetText())
	end
	SkillButtonNameEdit:ClearFocus()
end

function CraftBench:SkillButton_OnMouseDown(button)
	self.dragStartXY = { GetCursorPosition() }
	self.selectedTextOffsetXY = { 0, 0 }
end

function CraftBench:SkillButton_OnMouseUp(button)
	--DA.DEBUG(0, "SkillButton_OnMouseUp")
end

function CraftBench:SkillButton_DragUpdate()
	if self.dragEngaged then
		local x,y = GetCursorPosition()
		self.selectedTextOffsetXY[1] = x - self.dragStartXY[1]
		self.selectedTextOffsetXY[2] = y - self.dragStartXY[2]
		self:UpdateTradeSkillWindow()
	end
end

function CraftBench:SkillButton_OnDragStop(button, mouse)
	CraftBench:SkillButton_OnReceiveDrag(CraftBench.mouseOver, mouse)
	for i=1,num_recipe_buttons do
		local button, buttonDrag = get_recipe_button(i)
		buttonDrag:Hide()
	end
	self.dragEngaged = false
	self.fencePickEngaged = false
	self:UpdateTradeSkillWindow()
end

function CraftBench:SkillButton_OnDragStart(button, mouse)
	local skill = button.skill
	if skill.selected and skill then
		if not self:RecipeGroupIsLocked() then
			for i=1,self.visibleSkillButtons do
				local button, buttonDrag = get_recipe_button(i)
				local buttonText = _G[button:GetName().."Name"]
				local buttonDragText = _G[buttonDrag:GetName().."Name"]
				buttonDrag.skill = button.skill
				local r,g,b = buttonText:GetTextColor()
				buttonDragText:SetText(buttonText:GetText())
				buttonDragText:SetTextColor(r,g,b,.4)
				if button.skill and button.skill.selected then
					buttonDrag:Show()
				else
					buttonDrag:Hide()
				end
			end
			self.dragEngaged = true
			self.fencePickEngaged = false
		end
	else
		self.skillMainSelection = button.rawIndex
		self:SetSelectedSkill(button:GetID())
		self.dragEngaged = false
		self.fencePickEngaged = true
		if skill then skill.selected = true end
	end
	self:UpdateTradeSkillWindow()
end

function CraftBench:SkillButton_OnReceiveDrag(button, mouse)
	if not self:RecipeGroupIsLocked() then
		local skill = nil
		local destinationGroup = nil
		if button then
			skill = button.skill
			if skill.subGroup then
				destinationGroup = button.skill.subGroup
			else
				if skill.parent ~= nil then
					destinationGroup = skill.parent
				else
					destinationGroup = skill
				end
			end
		else
			destinationGroup = self:RecipeGroupFind(self.currentPlayer, self.currentTrade, self.currentGroupLabel)
		end
		if self.dragEngaged and (skill == nil or not skill.selected) then
			local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
			local sortedSkillList = self.data.sortedSkillList[skillListKey]
			for i=1,sortedSkillList.count do
				if sortedSkillList[i].selected then
					self:RecipeGroupMoveEntry(sortedSkillList[i], destinationGroup)
				end
			end
			self.dragEngaged = false
			self:SortAndFilterRecipes()
			self:UpdateTradeSkillWindow()
		end
	end
end

function CraftBench:SkillButton_LinkRecipe()
	DA.DEBUG(0,"SkillButton_LinkRecipe()")
	local skill = CraftBench.menuButton.skill
	if skill and skill.recipeID then
		local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
		if spellLink then
			if not C_ChatInfo.InChatMessagingLockdown or not C_ChatInfo.InChatMessagingLockdown() then
--				ChatFrameUtil.GetActiveWindow() -- not sure what this does
				if not ChatFrameUtil.InsertLink(spellLink) then -- OpenChat
					if not ChatFrameUtil.OpenChat(spellLink) then -- InsertLink
						DA.DEBUG(0,"SkillButton_LinkRecipe: spellLink= "..DA.PLINK(spellLink))
					end
				end
			end
		end
	end
end

--
-- Inspired by Kaliel's Tracker
--
StaticPopupDialogs["CRAFTBENCH_WowheadURL"] = {
	text = "CraftBench - Wowhead URL",
	button2 = CLOSE,
	hasEditBox = true,
	editBoxWidth = 300,
	EditBoxOnEnterPressed = function(self)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	OnShow = function(self)
		local textFrame = self.Text or self.text
		local editBox = self.EditBox or self.editBox
		local url = "https://www.wowhead.com/"
		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			url = url.."classic/"
		elseif WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
			url = url.."cata/"
		elseif WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC then
			url = url.."mop-classic/"
		elseif WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
			url = url.."forever/"
		elseif WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
			url = url.."retail/"
		end
		local param = "item="..textFrame.text_arg1
		textFrame:SetText(textFrame:GetText().."\n\n"..textFrame.text_arg2)
		editBox.text = url..param
		editBox:SetText(editBox.text)
		editBox:SetFocus()
		editBox:HighlightText()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

--
-- Pop up a dialog with a Wowhead URL
--
function CraftBench:SkillButton_WowheadURL()
	DA.DEBUG(0,"SkillButton_WowheadURL()")
	local skill = CraftBench.menuButton.skill
	--DA.DEBUG(1,"SkillButton_WowheadURL: skill= "..DA.DUMP1(skill,1))
	if skill and skill.recipeID then
		--DA.DEBUG(1,"SkillButton_WowheadURL: recipeID= "..tostring(skill.recipeID)..", name= "..tostring(skill.name))
		local recipe = self:GetRecipe(skill.recipeID)
		--DA.DEBUG(2,"SkillButton_WowheadURL: recipe= "..DA.DUMP1(recipe,1))
		if recipe and recipe.itemID then
			--DA.DEBUG(2,"SkillButton_WowheadURL: itemID= "..tostring(recipe.itemID)..", name= "..tostring(recipe.name))
			StaticPopup_Show("CRAFTBENCH_WowheadURL", recipe.itemID, recipe.name)
		end
	end
end

function CraftBench:SkillButton_CopySelected()
	DA.DEBUG(0,"SkillButton_CopySelected()")
	local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
	local sortedSkillList = self.data.sortedSkillList[skillListKey]
	if not self.skillListCopyBuffer then
		self.skillListCopyBuffer = {}
	end
	self.skillListCopyBuffer[self.currentTrade] = {}
	local d = 1
	for i=1,sortedSkillList.count do
		if sortedSkillList[i].selected and not (sortedSkillList[i].parentIndex and sortedSkillList[sortedSkillList[i].parentIndex].selected) then
			self.skillListCopyBuffer[self.currentTrade][d] = sortedSkillList[i]
			--DA.DEBUG(1,"SkillButton_CopySelected: "..(sortedSkillList[i].name or "nil"))
			d = d + 1
		end
	end
end

function CraftBench:SkillButton_PasteSelected(button)
	DA.DEBUG(0,"SkillButton_PasteSelected("..tostring(button)..")")
	if not self:RecipeGroupIsLocked() then
		local parentGroup
		if button then
			parentGroup = button.skill.subGroup or button.skill.parent
		else
			parentGroup = self:RecipeGroupFind(self.currentPlayer, self.currentTrade, self.currentGroupLabel, self.currentGroup)
		end
		if self.skillListCopyBuffer and self.skillListCopyBuffer[self.currentTrade] then
			for d=1,#self.skillListCopyBuffer[self.currentTrade] do
				--DA.DEBUG(1,"SkillButton_PasteSelected: "..(self.skillListCopyBuffer[self.currentTrade][d].name or "nil").." to "..parentGroup.name)
				self:RecipeGroupPasteEntry(self.skillListCopyBuffer[self.currentTrade][d], parentGroup)
			end
		end
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function CraftBench:SkillButton_DeleteSelected()
	DA.DEBUG(0,"SkillButton_DeleteSelected()")
	if not self:RecipeGroupIsLocked() then
		local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		for i=1,sortedSkillList.count do
			if sortedSkillList[i].selected and not (sortedSkillList[i].parent and sortedSkillList[i].parent.selected) then
				self:RecipeGroupDeleteEntry(sortedSkillList[i])
			end
		end
		self.selectedSkill = nil
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function CraftBench:SkillButton_CutSelected()
	DA.DEBUG(0,"SkillButton_CutSelected()")
	CraftBench:SkillButton_CopySelected()
	CraftBench:SkillButton_DeleteSelected()
end

function CraftBench:SkillButton_NewGroup()
	DA.DEBUG(0,"SkillButton_NewGroup()")
	if not self:RecipeGroupIsLocked() then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel
		local name, index = self:RecipeGroupNewName(player..":"..tradeID..":"..label, "New Group")
		local newGroup = self:RecipeGroupNew(player, tradeID, label, name)
		local parentGroup = self:RecipeGroupFind(player, tradeID, label, self.currentGroup)
		self:RecipeGroupAddSubGroup(parentGroup, newGroup, index)
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function CraftBench:SkillButton_MakeGroup()
	DA.DEBUG(0,"SkillButton_MakeGroup()")
	if not self:RecipeGroupIsLocked() then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel
		local name, index = self:RecipeGroupNewName(player..":"..tradeID..":"..label, "New Group")
		local newGroup = self:RecipeGroupNew(player, tradeID, label, name)
		local parentGroup = self:RecipeGroupFind(player, tradeID, label, self.currentGroup)
		local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		for i=1,sortedSkillList.count do
			if sortedSkillList[i].selected and not (sortedSkillList[i].parent and sortedSkillList[i].parent.selected) then
				self:RecipeGroupMoveEntry(sortedSkillList[i], newGroup)
			end
		end
		self:RecipeGroupAddSubGroup(parentGroup, newGroup, index)
		self:SortAndFilterRecipes()
		self:UpdateTradeSkillWindow()
	end
end

function CraftBench:SkillButton_OnKeyDown(button, key)
	DA.DEBUG(3,"SkillButton_OnKeyDown("..tostring(button)..", "..tostring(key)..")")
	if key == "D" then
		self:SkillButton_SetAllSelections(false)
	elseif key == "A" then
		self:SkillButton_SetAllSelections(true)
	elseif key == "C" then
		self:SkillButton_CopySelected()
	elseif key == "X" then
		self:SkillButton_CutSelected()
	elseif key == "V" then
		self:SkillButton_PasteSelected(self.mouseOver)
	elseif key == "DELETE" or key == "BACKSPACE" then
		self:SkillButton_DeleteSelected()
	elseif key == "N" then
		self:SkillButton_NewGroup()
	elseif key == "G" then
		self:SkillButton_MakeGroup()
	else
		return
	end
	self:UpdateTradeSkillWindow()
end

function CraftBench:SkillButton_NameEditEnable(button)
	DA.DEBUG(3,"SkillButton_NameEditEnable("..tostring(button)..")")
	if not self:RecipeGroupIsLocked() then
		SkillButtonNameEdit:SetText(button.skill.name)
		SkillButtonNameEdit:SetParent(button:GetParent())
		local buttonText = _G[button:GetName().."Name"]
		local numPoints = button:GetNumPoints()
		for p=1,numPoints do
			SkillButtonNameEdit:SetPoint(buttonText:GetPoint(p))
		end
		SkillButtonNameEdit.originalButton = buttonText
		SkillButtonNameEdit.skill = button.skill
		SkillButtonNameEdit:Show()
		buttonText:Hide()
		button:UnregisterEvent("MODIFIER_STATE_CHANGED")
	end
end

function CraftBench:FavoriteButton_OnClick(button, mouse)
	if (mouse=="LeftButton") then
	  if button.skill then
			CraftBench:ToggleFavorite(button.skill.recipeID)
			button:SetFavorite(CraftBench:IsFavorite(button.skill.recipeID))
		end
	end
end

function CraftBench:FavoritesOnlyRefresh()
	if CraftBench:GetTradeSkillOption("favoritesOnly") then
		CraftBenchFavoritesOnlyButton:LockHighlight()
	else
		CraftBenchFavoritesOnlyButton:UnlockHighlight()
	end
end

function CraftBench:SetGroupSelection(skillName)
	self.currentGroup = skillName
	CraftBench:SetTradeSkillOption("group", skillName)
end

--
-- When one of the skill buttons in the left scroll pane is clicked
--
local lastClick = 0
function CraftBench:SkillButton_OnClick(button, mouse)
	if (mouse == "LeftButton") then
		CraftBench:QueueManagementToggle(true)
		local doubleClicked = false
		local thisClick = GetTime()
		local delay = thisClick - lastClick
		lastClick = thisClick
		if delay < .25 then
			doubleClicked = true
			DA.DEBUG(1,"SkillButton_OnClick: double click")
		end
		if doubleClicked then
			if button.skill.subGroup then
				if button.skill.mainGroup or self.currentGroup == button.skill.name then
					CraftBench:SetGroupSelection(nil)
					button.skill.subGroup.expanded = true
				else
					CraftBench:SetGroupSelection(button.skill.name)
					button.skill.subGroup.expanded = true
				end
				self:SortAndFilterRecipes()
			else
				local skill = button.skill
				if skill and skill.recipeID then
					local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
					if not ChatEdit_InsertLink(spellLink) then
						DA.DEBUG(0,"SkillButton_OnClick: spellLink= "..DA.PLINK(spellLink))
					end
				end
			end
		elseif not button.skill.mainGroup then
			if IsShiftKeyDown() and self.skillMainSelection then
				self:SkillButton_ClearSelections()
				self:SkillButton_SetSelections(self.skillMainSelection, button.rawIndex)
			elseif IsControlKeyDown() then
				button.skill.selected = not button.skill.selected
			elseif IsAltKeyDown() then
--
-- Some plugins may return extra information from RecipeNamePrefix so deal with it here
-- Currently, only the Overachiever plugin returns the achievement id and a link
--
				if button.prelink then
					DA.MARK3(button.prelink)
				end
			else
				if not button.skill.subGroup then
					if not button.skill.selected then
						self:SkillButton_ClearSelections()
					end
					self:SetSelectedSkill(button:GetID())
					button.skill.selected = true
				else
					if button.skill.selected and not self:RecipeGroupIsLocked() then
						self:SkillButton_NameEditEnable(button)
						return			-- avoid window update
					else
						self:SkillButton_ClearSelections()
						self.selectedSkill = nil
						button.skill.selected = true
					end
				end
				self.skillMainSelection = button.rawIndex
			end
		end
		self:UpdateTradeSkillWindow()
	elseif (mouse == "RightButton") then
--
-- The following options are primarily for debugging.
--
		if IsShiftKeyDown() then
			DA.DEBUG(1,"SkillButton_OnClick: Shift is down")
		elseif IsControlKeyDown() then
			DA.DEBUG(1,"SkillButton_OnClick: Ctrl is down")
		elseif IsAltKeyDown() then
			DA.DEBUG(1,"SkillButton_OnClick: Alt is down")
			local skill = self:GetSkill(self.currentPlayer, self.currentTrade, self.selectedSkill)
			local recipe = self:GetRecipe(skill.id)
			local requirements = C_TradeSkillUI.GetRecipeRequirements(recipe.spellID)
			local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipe.spellID)
			local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipe.spellID, false)
			DA.DEBUG(1,"SkillButton_OnClick: name= "..tostring(recipe.name)..", skill.id= "..tostring(skill.id)..", recipe.spellID= "..tostring(recipe.spellID))
			DA.DEBUG(1,"SkillButton_OnClick: skill= "..DA.DUMP1(skill))
			DA.DEBUG(1,"SkillButton_OnClick: recipe= "..DA.DUMP(recipe))
			DA.DEBUG(1,"SkillButton_OnClick: requirements= "..DA.DUMP(requirements))
			DA.DEBUG(1,"SkillButton_OnClick: GetRecipeInfo= "..DA.DUMP(recipeInfo))
			DA.DEBUG(1,"SkillButton_OnClick: GetRecipeSchematic= "..DA.DUMP(recipeSchematic))
		else
--
-- Currently the only "useful" option.
--
			self:CraftBenchSkillMenu_Show(button)
		end
	end
end

--
-- When one of the skill buttons in the left scroll pane is clicked
--
function CraftBench:SkillExpandButton_OnClick(button, mouse, doubleClicked)
	--DA.DEBUG(3,"SkillExpandButton_OnClick("..tostring(button)..", "..tostring(mouse)..", "..tostring(doubleClicked))
	if (mouse=="LeftButton") then
		if button.group then
			button.group.expanded = not button.group.expanded
			self:SortAndFilterRecipes()
			self:UpdateTradeSkillWindow()
		end
	end
end

--
-- This function assures that a recipe that is indirectly selected (via reagent clicks, for example)
-- will be visible in the skill list (ie, not scrolled off the top/bottom)
--
function CraftBench:ScrollToSkillIndex(skillIndex)
	--DA.DEBUG(0,"ScrollToSkillIndex("..tostring(skillIndex)..")")
	if skillIndex == nil then
		return
	end
--
-- Scroll the skill list to make sure the new skill is revealed
--
	if CraftBenchSkillList:IsVisible() then
		local skillListKey = self.currentPlayer..":"..self.currentTrade..":"..self.currentGroupLabel
		local sortedSkillList = self.data.sortedSkillList[skillListKey]
		if sortedSkillList then
			local sortedIndex
			for i=1,#sortedSkillList,1 do
				if sortedSkillList[i].skillIndex == skillIndex then
					sortedIndex = i
					break
				end
			end
			sortedIndex = sortedIndex or 1
			local scrollbar = _G["CraftBenchSkillListScrollBar"]
			local button_count = CraftBenchSkillList:GetHeight() / CRAFTBENCH_TRADE_SKILL_HEIGHT
			button_count = math.floor(button_count)
			local skillOffset = FauxScrollFrame_GetOffset(CraftBenchSkillList)
			--DA.DEBUG(0,"ScrollToSkillIndex: "..(skillOffset or "nil").." > "..(sortedIndex or "nil"))
			if skillOffset > sortedIndex then
				sortedIndex = sortedIndex - 1
				FauxScrollFrame_SetOffset(CraftBenchSkillList, sortedIndex)
				scrollbar:SetValue(sortedIndex * CRAFTBENCH_TRADE_SKILL_HEIGHT)
			elseif (skillOffset + button_count) < sortedIndex then
				sortedIndex = sortedIndex - button_count
				FauxScrollFrame_SetOffset(CraftBenchSkillList, sortedIndex)
				scrollbar:SetValue(sortedIndex * CRAFTBENCH_TRADE_SKILL_HEIGHT)
			end
		end
	end
	self:UpdateTradeSkillWindow()
end

--
-- Go to the previous recipe in the history list.
--
function CraftBench:GoToPreviousSkill()
	local entry = table.remove(self.skillStack)
	if entry then
		self:SetTradeSkill(entry.player,entry.tradeID,entry.skillIndex)
	end
end

function CraftBench:PushSkill(player, tradeID, skillIndex)
	local entry = { ["player"] = player, ["tradeID"] = tradeID, ["skillIndex"] = skillIndex }
	table.insert(self.skillStack, entry)
end

function CraftBench:getLvlUpChance()
--
-- % to level up with this receipt is calculated by: (greySkill - yourSkill) / (greySkill - yellowSkill
--
	local skilRanks = CraftBench:GetSkillRanks(CraftBench.currentPlayer, CraftBench.currentTrade)
	local currentLevel, maxLevel = 0, 0
	if skilRanks then
		currentLevel, maxLevel = skilRanks.rank, skilRanks.maxRank
	end
	local gray = tonumber(CraftBenchRankFrame.subRanks.green:GetValue())
	local yellow = tonumber(CraftBenchRankFrame.subRanks.orange:GetValue())
	--DA.DEBUG(0,"getLvlUpChance: currentLevel= "..tostring(currentLevel)..", gray= "..tostring(gray)..", yellow= "..tostring(yellow))
	if (currentLevel > gray) then
		return 0
	elseif (gray - yellow) == 0 then
		return 100
	else
		local percent = ((gray - currentLevel) / ( gray - yellow )) * 100
		if percent > 100 then
			percent = 100
		end
		return percent
	end
end

local function RankFrameMenuList(CraftBenchRankFrameMenu, rootDescription)
	if CraftBench.isTest then 
		local title = "RankFrameMenuList"
		rootDescription:CreateTitle(title);
	end
	rootDescription:CreateButton(L["Button 1"], function() CraftBench:RankFrame_Button1() end);
	rootDescription:CreateDivider(); -- CreateSpacer, CreateDivider
	rootDescription:CreateButton(L["Button 2"], function() CraftBench:RankFrame_Button2() end);
end

--
-- Called when then mouse enters the rank status bar
--
function CraftBench:RankFrame_OnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_BOTTOMLEFT")
	local r,g,b = CraftBenchSkillName:GetTextColor()
	GameTooltip:AddLine(CraftBenchSkillName:GetText(),r,g,b)
	local gray = CraftBenchRankFrame.subRanks.green:GetValue()
	local green = CraftBenchRankFrame.subRanks.yellow:GetValue()
	local yellow = CraftBenchRankFrame.subRanks.orange:GetValue()
	local orange = CraftBenchRankFrame.subRanks.red:GetValue()
	-- lets add the chance to level up that skill with that receipt
	local chance = self:getLvlUpChance()
	chance = math.floor(chance*10)/10		-- one decimal is enough
	GameTooltip:AddLine(COLORORANGE..orange.."|r/"..COLORYELLOW..yellow.."|r/"..COLORGREEN..green.."|r/"..COLORGRAY..gray.."|r/ Chance:"..chance.."|r%")
	GameTooltip:Show()
end

--
-- Called when then mouse leaves the rank status bar
--
function CraftBench:RankFrame_OnLeave(button)
	CraftBench.RankFrameExtra = false
	GameTooltip:Hide()
end

function CraftBench:RankFrame_OnMouseDown(button)
	local mouse = GetMouseButtonClicked()
	DA.DEBUG(3,"RankFrame_OnMouseDown("..tostring(button).."), "..tostring(mouse))
	if (mouse == "LeftButton") then
		if not CraftBench.RankFrameExtra then
			GameTooltip:AddLine("RankFrame_OnMouseDown")
			CraftBench.RankFrameExtra = true
		end
		GameTooltip:Show()
	elseif (mouse == "RightButton") then
		self:CraftBenchRankFrame_Show(button)
	end
end

function CraftBench:RankFrame_OnMouseUp(button)
	local mouse = GetMouseButtonClicked()
	DA.DEBUG(3,"RankFrame_OnMouseUp("..tostring(button).."), "..tostring(mouse))
	if (mouse == "LeftButton") then
		GameTooltip:AddLine("RankFrame_OnMouseUp")
		GameTooltip:Show()
	elseif (mouse == "RightButton") then
		self:CraftBenchRankFrame_Show(button)
	end
end

function CraftBench:CraftBenchRankFrame_Show(button)
	--DA.DEBUG(0,"CraftBenchRankFrame_Show("..tostring(button)..")")
	local x, y = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	if not CraftBenchRankFrameMenu then
		CraftBenchRankFrameMenu = CreateFrame("Frame", "CraftBenchRankFrameMenu", _G["UIParent"], "UIDropDownMenuTemplate")
		CraftBenchRankFrameMenu:SetScale(uiScale)
	end
	self.menuButton = button
--	GameTooltip:Hide() --hide tooltip, because it may be over the menu, sometimes it still fails
	MenuUtil.CreateContextMenu(CraftBenchRankFrameMenu, RankFrameMenuList);
end

function CraftBench:RankFrame_Button1()
	DA.DEBUG(0,"RankFrame_Button1()")
end

function CraftBench:RankFrame_Button2()
	DA.DEBUG(0,"RankFrame_Button2()")
end

function CraftBench:CraftBenchFrameForceClose()
	--DA.DEBUG(0,"CraftBenchFrameForceClose()")
--
-- CraftBench's Close (X) button just hides our frames to avoid crashing TSM
--
	if TSM_API and CraftBench.db.profile.tsm_compat then
		if TSM_API.IsUIVisible("CRAFTING") then
			return self:HideAllWindows()
		end
	end
	C_TradeSkillUI.CloseTradeSkill()
	return self:HideAllWindows()
end

function CraftBench:InventoryFilterButton_OnClick(button)
	local slot = button.slot or ""
	local option = "filterInventory-"..slot
	self:ToggleTradeSkillOption(option)
	self:InventoryFilterButton_OnEnter(button)
	self:InventoryFilterButton_OnShow(button)
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

function CraftBench:InventoryFilterButton_OnEnter(button)
	local slot = button.slot or ""
	local option = "filterInventory-"..slot
	local value = self:GetTradeSkillOption(option)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	if value then
		GameTooltip:SetText(slot.." on")
	else
		GameTooltip:SetText(slot.." off")
	end
	GameTooltip:Show()
end

function CraftBench:InventoryFilterButton_OnLeave(button)
	GameTooltip:Hide()
end

function CraftBench:InventoryFilterButton_OnShow(button)
	local slot = button.slot or ""
	local option = "filterInventory-"..slot
	local value = self:GetTradeSkillOption(option)
	if value then
		button:SetChecked(true)
	else
		button:SetChecked(false)
	end
end

function CraftBench:InventoryFilterButtons_Show()
	CraftBenchInventoryFilterBag:Show()
	CraftBenchInventoryFilterCraft:Show()
	CraftBenchInventoryFilterVendor:Show()
	CraftBenchInventoryFilterAlts:Show()
	CraftBenchInventoryFilterOwned:Show()
end

function CraftBench:InventoryFilterButtons_Hide()
	CraftBenchInventoryFilterBag:Hide()
	CraftBenchInventoryFilterCraft:Hide()
	CraftBenchInventoryFilterVendor:Hide()
	CraftBenchInventoryFilterAlts:Hide()
	CraftBenchInventoryFilterOwned:Hide()
end

local function SkillMenuList(CraftBenchSkillMenu, rootDescription)
	if CraftBench.isTest then 
		local title = "skillMenuList"
		if CraftBench.isLocked then
			title = title .. "(locked)"
		end
		rootDescription:CreateTitle(title);
	end
	rootDescription:CreateButton(L["Link Recipe"], function() CraftBench:SkillButton_LinkRecipe() end);
	rootDescription:CreateButton(L["Wowhead URL"], function() CraftBench:SkillButton_WowheadURL() end);
	if CraftBench.isLocked then
		rootDescription:CreateButton(L["Add to Ignore Materials"], function()
			local skill = CraftBench.menuButton.skill
			if skill and skill.recipeID then
				local recipeID = skill.recipeID
				local spellLink = C_TradeSkillUI.GetRecipeLink(skill.recipeID)
				CraftBench.db.realm.userIgnoredMats[CraftBench.currentPlayer][recipeID] = spellLink
				if CraftBench.ignoreList and CraftBench.ignoreList:IsVisible() then
					CraftBench:UpdateIgnoreListWindow()
				end
			end
		end);
	end
	rootDescription:CreateButton(CraftBench.favoriteMenuText, function()
		local recipeID = CraftBench.menuButton.skill.recipeID
		local favoriteButton = _G[CraftBench.menuButton:GetName() .. "Favorite"]
		CraftBench:ToggleFavorite(recipeID)
		favoriteButton:SetFavorite(CraftBench:IsFavorite(recipeID))
	end);
	if not CraftBench.isLocked then
		local submenu1 = rootDescription:CreateButton(L["Ignore"]);
			submenu1:CreateButton(L["Add Recipe to Ignored List"], function()
				local index = CraftBench.menuButton:GetID()
				local skillDB = CraftBench.db.realm.skillDB[CraftBench.currentPlayer][CraftBench.currentTrade][index]
				local recipeID = string.sub(skillDB,2)
				local print=(tostring(index)..", "..tostring(skillDB)..", "..tostring(recipeID))
				CraftBench.db.realm.userIgnoredMats[CraftBench.currentPlayer][recipeID] = CraftBench.currentTrade
				if CraftBench.ignoreList and CraftBench.ignoreList:IsVisible() then
					CraftBench:UpdateIgnoreListWindow()
				end
			end);
			submenu1:CreateButton(L["Remove Recipe from Ignored List"], function()
				local index = CraftBench.menuButton:GetID()
				local skillDB = CraftBench.db.realm.skillDB[CraftBench.currentPlayer][CraftBench.currentTrade][index]
				local recipeID = string.sub(skillDB,2)
				local print=(tostring(index)..", "..tostring(skillDB)..", "..tostring(recipeID))
				CraftBench.db.realm.userIgnoredMats[CraftBench.currentPlayer][recipeID] = nil
				if CraftBench.ignoreList and CraftBench.ignoreList:IsVisible() then
					CraftBench:UpdateIgnoreListWindow()
				end
			end);
		local submenu2 = rootDescription:CreateButton(L["New Group"]);
			submenu2:CreateButton(L["Empty Group"], function() CraftBench:SkillButton_NewGroup() end);
			submenu2:CreateButton(L["From Selection"], function() CraftBench:SkillButton_MakeGroup() end);
	end
	rootDescription:CreateDivider(); -- CreateSpacer, CreateDivider
	rootDescription:CreateButton(L["Copy"], function() CraftBench:SkillButton_CopySelected() end);
	if not CraftBench.isLocked then
		rootDescription:CreateButton(L["Cut"], function() CraftBench:SkillButton_CutSelected() end);
		rootDescription:CreateButton(L["Paste"], function() CraftBench:SkillButton_PasteSelected(CraftBench.menuButton) end);
	end
end;

local function HeaderMenuList(CraftBenchSkillMenu, rootDescription)
	if CraftBench.isTest then 
		local title = "headerMenuList"
		if CraftBench.isLocked then
			title = title .. "(locked)"
		end
		rootDescription:CreateTitle(title);
	end
	if not CraftBench.isLocked then
		rootDescription:CreateButton(L["Rename Group"], function() CraftBench:SkillButton_NameEditEnable(CraftBench.menuButton) end);
		local submenu1 = rootDescription:CreateButton(L["New Group"]);
			submenu1:CreateButton(L["Empty Group"], function() CraftBench:SkillButton_NewGroup() end);
			submenu1:CreateButton(L["From Selection"], function() CraftBench:SkillButton_MakeGroup() end);
		rootDescription:CreateDivider(); -- CreateSpacer, CreateDivider
	end
	local submenu2 = rootDescription:CreateButton(L["Selection"]);
		submenu2:CreateButton(L["Select All"], function() CraftBench:SkillButton_SetAllSelections(true) CraftBench:UpdateTradeSkillWindow() end);
		submenu2:CreateButton(L["Select None"], function() CraftBench:SkillButton_SetAllSelections(false) CraftBench:UpdateTradeSkillWindow() end);
	rootDescription:CreateDivider(); -- CreateSpacer, CreateDivider
	rootDescription:CreateButton(L["Copy"], function() CraftBench:SkillButton_CopySelected() end);
	if not CraftBench.isLocked then
		rootDescription:CreateButton(L["Cut"], function() CraftBench:SkillButton_CutSelected() end);
		rootDescription:CreateButton(L["Paste"], function() CraftBench:SkillButton_PasteSelected(CraftBench.menuButton) end);
	end
end;

local function HeaderMenuListMainGroup(CraftBenchSkillMenu, rootDescription)
	if CraftBench.isTest then 
		local title = "headerMenuListMainGroup"
		if CraftBench.isLocked then
			title = title .. "(locked)"
		end
		rootDescription:CreateTitle(title);
	end
	if not CraftBench.isLocked then
		local submenu1 = rootDescription:CreateButton(L["New Group"]);
			submenu1:CreateButton(L["Empty Group"], function() CraftBench:SkillButton_NewGroup() end);
			submenu1:CreateButton(L["From Selection"], function() CraftBench:SkillButton_MakeGroup() end);
		rootDescription:CreateDivider(); -- CreateSpacer, CreateDivider
		local submenu2 = rootDescription:CreateButton(L["Selection"]);
			submenu2:CreateButton(L["Select All"], function() CraftBench:SkillButton_SetAllSelections(true) CraftBench:UpdateTradeSkillWindow() end);
			submenu2:CreateButton(L["Select None"], function() CraftBench:SkillButton_SetAllSelections(false) CraftBench:UpdateTradeSkillWindow() end);
		rootDescription:CreateDivider(); -- CreateSpacer, CreateDivider
	end
	rootDescription:CreateButton(L["Copy"], function() CraftBench:SkillButton_CopySelected() end);
	if not CraftBench.isLocked then
		rootDescription:CreateButton(L["Cut"], function() CraftBench:SkillButton_CutSelected() end);
		rootDescription:CreateButton(L["Paste"], function() CraftBench:SkillButton_PasteSelected(CraftBench.menuButton) end);
	end
end;

--
-- Called when the skill operators drop down is displayed
--
function CraftBench:CraftBenchSkillMenu_Show(button)
	--DA.DEBUG(0,"CraftBenchSkillMenu_Show("..tostring(button)..")")
	local x, y = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	local locked = self:RecipeGroupIsLocked()
	self.isLocked = locked
	if not CraftBenchSkillMenu then
		CraftBenchSkillMenu = CreateFrame("Frame", "CraftBenchSkillMenu", _G["UIParent"], "UIDropDownMenuTemplate") -- WowStyle1DropdownTemplate
		CraftBenchSkillMenu:SetScale(uiScale)
	end
	self.menuButton = button
	if button.skill.subGroup then
		if button.skill.mainGroup then
			MenuUtil.CreateContextMenu(CraftBenchSkillMenu, HeaderMenuListMainGroup);
		else
			MenuUtil.CreateContextMenu(CraftBenchSkillMenu, HeaderMenuList);
		end
	else
		GameTooltip:Hide() --hide tooltip, because it may be over the menu, sometimes it still fails
		if C_TradeSkillUI.GetShowLearned() then
			CraftBench.favoriteMenuText = L["Set Favorite"]
		else
			CraftBench.favoriteMenuText = L["Cannot Set Favorite"]
		end
		if CraftBench:IsFavorite(button.skill.recipeID) then
			CraftBench.favoriteMenuText = L["Remove Favorite"]
		end
		MenuUtil.CreateContextMenu(CraftBenchSkillMenu, SkillMenuList);
	end
end

function CraftBench:ReAnchorButtons(newFrame)
	--DA.DEBUG(0,"ReAnchorButtons("..tostring(newFrame)..")")
	CraftBenchRecipeNotesButton:SetPoint("BOTTOMRIGHT",newFrame,"TOPRIGHT",0,2)
	CraftBenchQueueAllButton:SetPoint("TOPLEFT",newFrame,"BOTTOMLEFT",0,-2)
	CraftBenchEnchantButton:SetPoint("TOPLEFT",newFrame,"BOTTOMLEFT",0,-2)
--	CraftBenchQueueButton:SetPoint("TOPRIGHT",newFrame,"BOTTOMRIGHT",0,-2)
end

--
-- The CraftBenchQueue and StandaloneQueue functions start here
--
function CraftBench:CraftBenchQueueMenu_Show(button)
	--DA.DEBUG(0,"CraftBenchQueueMenu_Show("..tostring(button)..")")
	local x, y = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	if not CraftBenchQueueMenu then
		CraftBenchQueueMenu = CreateFrame("Frame", "CraftBenchQueueMenu", _G["UIParent"], "UIDropDownMenuTemplate")
		--DA.DEBUG(0,"CraftBenchQueueMenu_Show: uiScale= "..tostring(uiScale))
		CraftBenchQueueMenu:SetScale(uiScale)
	end
	self.queueMenuButton = button
	MenuUtil.CreateButtonContextMenu(CraftBenchQueueMenu,
	{L["Move to Top"], function() CraftBench:QueueMoveToTop(CraftBench.queueMenuButton:GetID()) end},
	{L["Move Up"], function() CraftBench:QueueMoveUp(CraftBench.queueMenuButton:GetID()) end},
	{L["Move Down"], function() CraftBench:QueueMoveDown(CraftBench.queueMenuButton:GetID()) end},
	{L["Move to Bottom"], function() CraftBench:QueueMoveToBottom(CraftBench.queueMenuButton:GetID()) end}
	);
end

--
-- The start/pause queue button.
--
function CraftBench:StartQueue_OnClick(button, mouse)
	if self.queuecasting then
		DA.MARK3(L["Cancel incomplete processing"])
		self:CancelCast()
		self.queuecasting = false
	else
		button:SetText(L["Pause"])
		self:ProcessQueue(mouse == "RightButton" or IsAltKeyDown())
	end
	self:UpdateQueueWindow()
end

function CraftBench:QueueManagementToggle(showDetails)
	--DA.DEBUG(0,"QueueManagementToggle("..tostring(showDetails)..")")
	if CraftBenchQueueManagementParent:IsVisible() or showDetails then
		CraftBench:ShowReagentDetails()
	else
		CraftBenchQueueManagementParent:Show();
		CraftBenchQueueManagementParent:SetHeight(100)
		CraftBenchReagentParent:Hide()
		CraftBench:ReAnchorButtons(CraftBenchQueueManagementParent)
	end
end

function CraftBench:QueueItemButton_OnClick(this, button)
	local queue = self.db.realm.queueData[self.currentPlayer]
	local index = this:GetID()
	if button == "LeftButton" then
		CraftBench:QueueManagementToggle(true)
		local recipeID = queue[index].recipeID
		local recipe = self:GetRecipe(recipeID)
		local tradeID = recipe.tradeID
		local newSkillIndex = self.data.skillIndexLookup[recipeID]
		--DA.DEBUG(0,"QueueItemButton_OnClick: selecting new skill "..tradeID..":"..(newSkillIndex or "nil"))
		self:SetTradeSkill(self.currentPlayer, tradeID, newSkillIndex)
		--DA.DEBUG(0,"QueueItemButton_OnClick: done selecting new skill")
	elseif button == "RightButton" then
		CraftBench:CraftBenchQueueMenu_Show(this)
	end
end

--
-- Called when the list of queued items is scrolled
--
function CraftBench:QueueList_OnScroll()
	CraftBench:UpdateQueueWindow()
end

local num_queue_buttons = 0
local function get_queue_button(i)
	local button = _G["CraftBenchQueueButton"..i]
	if not button then
		button = CreateFrame("Button", "CraftBenchQueueButton"..i, CraftBenchQueueParent, "CraftBenchQueueItemButtonTemplate")
		button:SetParent(CraftBenchQueueParent)
		button:SetPoint("TOPLEFT", "CraftBenchQueueButton"..(i-1), "BOTTOMLEFT")
		button:SetFrameLevel(CraftBenchQueueParent:GetFrameLevel() + 1)
	end
	return button
end

--
-- Updates the window/scroll list displaying queue of items
-- that are waiting to be crafted.
--
function CraftBench:UpdateQueueWindow()
	--DA.DEBUG(0,"UpdateQueueWindow()")
	local queue = self.db.realm.queueData[self.currentPlayer]
	if not queue then
		CraftBenchStartQueueButton:SetText(L["Process"])
		CraftBenchEmptyQueueButton:Disable()
		CraftBenchStartQueueButton:Disable()
		return
	end
	local numItems = #queue
	if numItems > 0 then
		CraftBenchStartQueueButton:Enable()
		CraftBenchEmptyQueueButton:Enable()
	else
		CraftBenchStartQueueButton:Disable()
		CraftBenchEmptyQueueButton:Disable()
	end
	if self.queuecasting and UnitCastingInfo("player") then
		CraftBenchStartQueueButton:SetText(L["Pause"])
	else
		CraftBenchStartQueueButton:SetText(L["Process"])
	end
	local button_count = CraftBenchQueueParentBase:GetHeight() / CRAFTBENCH_TRADE_SKILL_HEIGHT
	button_count = math.max(0, (math.floor(button_count) - 1))
	--DA.DEBUG(0,"UpdateQueueWindow: button_count="..button_count)
	if button_count == 0 then
		if self.fullView then
			button_count = self.saved_full_button_count
		else
			button_count = self.saved_SA_button_count
		end
	else
		if self.fullView then
			self.saved_full_button_count = button_count
		else
			self.saved_SA_button_count = button_count
		end
	end
--
-- Update the scroll frame
--
	FauxScrollFrame_Update(CraftBenchQueueList,				-- frame
						   numItems,                        -- num items
						   button_count,                    -- num to display
						   CRAFTBENCH_TRADE_SKILL_HEIGHT)      -- value step (item height)
--
-- Where in the list of skill to start counting.
--
	local itemOffset = FauxScrollFrame_GetOffset(CraftBenchQueueList)
	--DA.DEBUG(0,"UpdateQueueWindow: itemOffset="..itemOffset)
	local width = CraftBenchQueueList:GetWidth()
--
-- Iterate through all the buttons that make up the scroll window
-- and fill then in with data or hide them, as necessary
--
	for i=1, button_count, 1 do
		local itemIndex = i + itemOffset
		num_queue_buttons = math.max(num_queue_buttons, i)
		local button       = get_queue_button(i)
		local countFrame   = _G[button:GetName() .. "Count"]
		local queueCount   = _G[button:GetName() .. "CountText"]
		local nameButton   = _G[button:GetName() .. "Name"]
		local queueName    = _G[button:GetName() .. "NameText"]
		local deleteButton = _G[button:GetName() .. "DeleteButton"]
		button:SetWidth(width)
--
-- Stick this on top of the button we use for displaying queue contents.
--
		deleteButton:SetFrameLevel(button:GetFrameLevel() + 1)
		local fixed_width = countFrame:GetWidth() + deleteButton:GetWidth()
		fixed_width = width - fixed_width - 10 -- 10 for the padding between items
		queueName:SetWidth(fixed_width);
		nameButton:SetWidth(fixed_width);
		if itemIndex <= numItems then
			deleteButton:SetID(itemIndex)
			nameButton:SetID(itemIndex)
			local queueCommand = queue[itemIndex]
			if queueCommand then
				--DA.DEBUG(0,"UpdateQueueWindow: queueCommand= "..DA.DUMP1(queueCommand))
				local recipe = self:GetRecipe(queueCommand.recipeID)
				local optionals = ""
				local c = 0
				if queueCommand.optionalReagents then
					for i,r in pairs(queueCommand.optionalReagents) do
						c = c + 1
					end
					if c > 0 then
						optionals = " +"..tostring(c)
					end
				end
				local tname = queueCommand.tradeName or self:GetTradeName(recipe.tradeID) or queueCommand.tradeID or recipe.tradeID
				local rname = queueCommand.recipeName or recipe.name or queueCommand.recipeID or recipe.recipeID
				local count = queueCommand.count
				queueName:SetText(tname..":"..rname..optionals)
				queueCount:SetText(count)
			end
			nameButton:Show()
			queueName:Show()
			countFrame:Show()
			queueCount:Show()
			button:Show()
		else
			button:Hide()
			queueName:Hide()
			queueCount:Hide()
		end
	end
--
-- Hide any of the buttons that we created, but don't need right now
--
	for i = button_count + 1, num_queue_buttons, 1 do
	   local button = get_queue_button(i)
	   button:Hide()
	end
end

function CraftBench:ShowFullView()
	CraftBench.fullView = true
	CraftBenchQueueParentBase:SetParent(CraftBenchFrame)
	CraftBenchQueueParentBase:ClearAllPoints()
	CraftBenchQueueParentBase:SetPoint("TOPLEFT",CraftBenchCreateAllButton,"BOTTOMLEFT",0,-3)
	CraftBenchQueueParentBase:SetPoint("BOTTOMRIGHT",CraftBenchFrame,"BOTTOMRIGHT",-10,32)
	CraftBenchStandaloneQueue:Hide()
	CraftBenchQueueOnlyButton:SetText(">")
	CraftBench:UpdateQueueWindow()
end

function CraftBench:ShowQueueView()
	--DA.DEBUG(0,"ShowQueueView()")
	CraftBench.fullView = false
	CraftBenchQueueParentBase:SetParent(CraftBenchStandaloneQueue)
	CraftBenchQueueParentBase:ClearAllPoints()
	CraftBenchQueueParentBase:SetPoint("TOPLEFT",CraftBenchStandaloneQueue,"TOPLEFT",5,-32)
	CraftBenchQueueParentBase:SetPoint("BOTTOMRIGHT",CraftBenchStandaloneQueue,"BOTTOMRIGHT",-5,30)
	CraftBenchStandaloneQueue:Show()
	CraftBenchQueueOnlyButton:SetText("<")
	CraftBench:UpdateQueueWindow()
end

function CraftBench:QueueOnlyViewToggle()
	--DA.DEBUG(0,"QueueOnlyViewToggle()")
	FauxScrollFrame_SetOffset(CraftBenchQueueList, 0)
	self.fullView = not self.fullView
	if self.fullView then
		self:ShowFullView()
		if self.db.profile.queue_only_view then
			CraftBenchFrame:Show()
		end
		self:UpdateTradeSkillWindow()
	else
		self:ShowQueueView()
		if self.db.profile.queue_only_view then
			CraftBenchFrame:Hide()
		end
	end
end

function CraftBench:StandaloneQueueClose()
	--DA.DEBUG(0,"StandaloneQueueClose()")
	self:ShowFullView()
	if self.db.profile.queue_only_view then
		self:CraftBenchFrameForceClose()
	end
end

function CraftBench:HideStandaloneQueue()
	--DA.DEBUG(0,"HideStandaloneQueue()")
	local closed
	if self.craftbenchStandaloneQueue and self.craftbenchStandaloneQueue:IsVisible() then
		CraftBenchStandaloneQueue:Hide()
		closed = true
	end
	return closed
end

--
-- Creates and sets up the Standalone Queue Frame
--
function CraftBench:CreateStandaloneQueueFrame()
	--DA.DEBUG(0,"CreateStandaloneQueueFrame()")
	local frame = CraftBenchStandaloneQueue
	if not frame then
		return nil
	end
	local UIStyle = CraftBench.UIStyle
	if TSM_API and CraftBench.db.profile.tsm_compat then
		frame:SetFrameStrata("HIGH")
	end
	UIStyle.SkinFrame(frame, false)
	local titletext = frame:CreateFontString("CraftBenchStandaloneQueueTitleText", "OVERLAY", "GameFontNormalLarge")
	titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -1)
	titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -1)
	titletext:SetHeight(26)
	titletext:SetJustifyH("CENTER")
	titletext:SetText("CraftBench: " .. L["Queue"])
	UIStyle.StyleHeaderBar(frame, titletext, 1)
	if CraftBenchStandaloneQueueCloseButton then
		UIStyle.SkinCloseButton(CraftBenchStandaloneQueueCloseButton)
	end

--
-- Ace Window manager library, allows the window position (and size)
-- to be automatically saved
--
	local standaloneQueueLocation = {
		prefix = "standaloneQueueLocation_"
	}
	local windowManager = LibStub("LibWindow-1.1")
	windowManager.RegisterConfig(frame, self.db.profile, standaloneQueueLocation)
	windowManager.RestorePosition(frame)  -- restores scale also
	if frame:GetNumPoints() == 0 then
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	windowManager.MakeDraggable(frame)
--
-- lets play the resize me game!
--
	CraftBench:EnableResize(frame, 385, 170, CraftBench.UpdateStandaloneQueueWindow)
--
-- so hitting [ESC] will close the window
--
	tinsert(UISpecialFrames, frame:GetName())
	return frame
end

function CraftBench:UpdateStandaloneQueueWindow()
	--DA.DEBUG(0,"UpdateStandaloneQueueWindow()")
	if not self.craftbenchStandaloneQueue or not self.craftbenchStandaloneQueue:IsVisible() then
		return
	end
	CraftBenchStandaloneQueue:SetAlpha(self.db.profile.transparency)
	CraftBenchStandaloneQueue:SetScale(self.db.profile.scale)
	self:UpdateQueueWindow()
end

--
-- Adds a button to the tradeskill window. The button will be
-- reparented and placed appropriately in the window.
--
-- The frame representing the main tradeskill window will be
-- returned in case you need to pop up a frame attached to it.
--
function CraftBench:AddButtonToTradeskillWindow(button)
	--DA.DEBUG(0,"AddButtonToTradeskillWindow("..tostring(button)..")")
	if not CraftBenchFrame.added_buttons then
		CraftBenchFrame.added_buttons = {}
	end
	button:Hide()
--
-- See if this button has already been added ...
--
	for i=1, #CraftBenchFrame.added_buttons, 1 do
		if CraftBenchFrame.added_buttons[i] == button then
			return	-- ... yup
		end
	end
	table.insert(CraftBenchFrame.added_buttons, button)	-- ... nope
	if CraftBenchPluginButton then
		CraftBenchPluginButton:Show()
	end
	return CraftBenchFrame
end

function CraftBench:ToggleUseConcentration()
	self.db.profile.use_concentration = not self.db.profile.use_concentration
	--DA.DEBUG(0,"ToggleUseConcentration: use_concentration= "..tostring(self.db.profile.use_concentration))
	CraftBenchUseConcentration:SetChecked(self.db.profile.use_concentration)
	self:UpdateDetailWindow(self.selectedSkill)
end
