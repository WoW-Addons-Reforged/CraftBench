----------------------------------------------------------
-- CraftBench - Main Window All-in-One Side Dock        --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")
local L = CraftBench.L

local sideDock

function CraftBench:CreateMainSideToolsDock(parent)
	if sideDock or not parent then return sideDock end
	local UIStyle = CraftBench.UIStyle

	local dock = CreateFrame("Frame", "CraftBenchSideToolsDock", parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	dock:SetPoint("TOPLEFT", parent, "TOPRIGHT", 4, 0)
	dock:SetSize(168, 424)
	if UIStyle then
		UIStyle.SkinFrame(dock, false)
	end

	local hdr = dock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	hdr:SetPoint("TOPLEFT", dock, "TOPLEFT", 10, -8)
	hdr:SetText("|cffffd100" .. (L["TOOLS_TITLE"] or "All-in-One") .. "|r")
	dock._hdr = hdr

	local toggleBtn = CreateFrame("Button", nil, dock, BackdropTemplateMixin and "BackdropTemplate" or nil)
	toggleBtn:SetSize(20, 18)
	toggleBtn:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -6, -6)
	if UIStyle and UIStyle.ApplyBox then
		UIStyle.ApplyBox(toggleBtn, 0.14, 0.16, 0.22, 1, 0.79, 0.64, 0.15, 0.8)
	end
	local tfs = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tfs:SetAllPoints()
	tfs:SetText("«")
	toggleBtn._fs = tfs

	local tools = {
		{
			key = "level",
			icon = 136249,
			label = L["LVL_TITLE"] or "Leveling Planner",
			tip = "/cb level",
			onClick = function() if CraftBench.ShowLeveling then CraftBench:ShowLeveling() end end,
		},
		{
			key = "cd",
			icon = 136243,
			label = L["CD_TITLE"] or "Cooldowns",
			tip = "/cb cd",
			onClick = function() if CraftBench.ShowCooldowns then CraftBench:ShowCooldowns() end end,
		},
		{
			key = "watch",
			icon = 136033,
			label = L["WATCH_TITLE"] or "Recipe Watch",
			tip = L["SIDE_WATCH_TIP"] or "Click: Toggle HUD | Shift-Click: Pin selected",
			onClick = function()
				if IsShiftKeyDown() and CraftBench.Watch and CraftBench.Watch.PinCurrentOrByName then
					CraftBench.Watch:PinCurrentOrByName("")
				elseif CraftBench.ToggleWatchHUD then
					CraftBench:ToggleWatchHUD()
				end
			end,
		},
		{
			key = "gather",
			icon = 136065,
			label = L["GATHER_TITLE"] or "Gathering Guide",
			tip = "/cb gather",
			onClick = function() if CraftBench.ShowGathering then CraftBench:ShowGathering() end end,
		},
		{
			key = "contacts",
			icon = 133784,
			label = L["CONTACTS_TITLE"] or "Trade Contacts",
			tip = "/cb contacts",
			onClick = function() if CraftBench.ShowContacts then CraftBench:ShowContacts() end end,
		},
		{
			key = "fish",
			icon = 136245,
			label = L["Fishing"] or "Fishing",
			tip = "/cb fish",
			onClick = function() if CraftBench.ShowFishing then CraftBench:ShowFishing() end end,
		},
		{
			key = "camp",
			icon = 135805,
			label = L["CAMP_TITLE"] or "Camping",
			tip = "/cb camp",
			onClick = function() if CraftBench.ShowCamping then CraftBench:ShowCamping() end end,
		},
		{
			key = "find",
			icon = 134269,
			label = L["SIDE_ALT_FINDER"] or "Alt Finder",
			tip = "/cb find",
			onClick = function() if CraftBench.ShowAltFinder then CraftBench:ShowAltFinder() end end,
		},
		{
			key = "gear",
			icon = 132633,
			label = L["GEAR_TITLE"] or "Crafted Gear",
			tip = "/cb gear",
			onClick = function() if CraftBench.ShowGear then CraftBench:ShowGear() end end,
		},
		{
			key = "buffs",
			icon = 134830,
			label = L["BUFFS_ONLY"] or "Buffs only",
			tip = L["BUFFS_ONLY_TIP"] or "Filter list to consumables & enhancements usable at your level",
			onClick = function()
				if CraftBench.SetTradeSkillOption and CraftBench.GetTradeSkillOption then
					local cur = CraftBench:GetTradeSkillOption("buffsOnly")
					CraftBench:SetTradeSkillOption("buffsOnly", not cur)
					if CraftBench.SortAndFilterRecipes then CraftBench:SortAndFilterRecipes() end
					if CraftBench.UpdateTradeSkillWindow then CraftBench:UpdateTradeSkillWindow() end
				end
			end,
		},
		{
			key = "process",
			icon = 132853,
			label = L["SIDE_PROCESS"] or "Processing",
			tip = "/cb process",
			onClick = function() if CraftBench.ShowProcessPanel then CraftBench:ShowProcessPanel() end end,
		},
	}

	dock._buttons = {}
	local y = -30
	for _, info in ipairs(tools) do
		local btn = CreateFrame("Button", nil, dock, BackdropTemplateMixin and "BackdropTemplate" or nil)
		btn:SetPoint("TOPLEFT", dock, "TOPLEFT", 8, y)
		btn:SetSize(152, 28)
		if UIStyle and UIStyle.ApplyBox then
			UIStyle.ApplyBox(btn, 0.10, 0.12, 0.16, 0.92, 0.28, 0.31, 0.38, 0.9)
		end

		local ico = btn:CreateTexture(nil, "ARTWORK")
		ico:SetSize(20, 20)
		ico:SetPoint("LEFT", btn, "LEFT", 5, 0)
		ico:SetTexture(info.icon)
		ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		btn._ico = ico

		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		fs:SetPoint("LEFT", ico, "RIGHT", 6, 0)
		fs:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
		fs:SetJustifyH("LEFT")
		fs:SetText(info.label)
		btn._fs = fs
		btn._baseLabel = info.label
		btn._key = info.key

		btn:SetScript("OnClick", info.onClick)
		btn:SetScript("OnEnter", function(self)
			if self.SetBackdropBorderColor then
				self:SetBackdropBorderColor(0.95, 0.80, 0.25, 1)
			end
			if GameTooltip then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine("|cffffd100" .. info.label .. "|r")
				GameTooltip:AddLine(info.tip, 0.85, 0.85, 0.85, true)
				GameTooltip:Show()
			end
		end)
		btn:SetScript("OnLeave", function(self)
			if self.SetBackdropBorderColor then
				self:SetBackdropBorderColor(0.28, 0.31, 0.38, 0.9)
			end
			if GameTooltip then GameTooltip:Hide() end
		end)

		table.insert(dock._buttons, btn)
		y = y - 32
	end
	dock:SetHeight(-y + 10)

	local function applyCollapsedState(collapsed)
		if collapsed then
			dock:SetWidth(46)
			dock._hdr:Hide()
			toggleBtn._fs:SetText("»")
			for _, b in ipairs(dock._buttons) do
				b:SetWidth(30)
				b._fs:Hide()
			end
		else
			dock:SetWidth(168)
			dock._hdr:Show()
			toggleBtn._fs:SetText("«")
			for _, b in ipairs(dock._buttons) do
				b:SetWidth(152)
				b._fs:Show()
			end
		end
	end

	toggleBtn:SetScript("OnClick", function()
		local dbp = CraftBench.db and CraftBench.db.profile
		local nextState = not (dbp and dbp.sideDockCollapsed)
		if dbp then dbp.sideDockCollapsed = nextState end
		applyCollapsedState(nextState)
	end)

	dock:SetScript("OnShow", function()
		local readyCD = (CraftBench.Cooldowns and CraftBench.Cooldowns.GetReadyCount and CraftBench.Cooldowns:GetReadyCount()) or 0
		for _, b in ipairs(dock._buttons) do
			if b._key == "cd" then
				if readyCD > 0 then
					b._fs:SetText(b._baseLabel .. " |cff40ff40(" .. readyCD .. ")|r")
				else
					b._fs:SetText(b._baseLabel)
				end
			end
		end
	end)

	local initCollapsed = CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.sideDockCollapsed
	applyCollapsedState(initCollapsed and true or false)

	sideDock = dock
	return dock
end
