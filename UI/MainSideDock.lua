----------------------------------------------------------
-- CraftForge - Main Window All-in-One Side Dock        --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")
local L = CraftForge.L

local sideDock

function CraftForge:CreateMainSideToolsDock(parent)
	if sideDock or not parent then return sideDock end
	local UIStyle = CraftForge.UIStyle

	local dock = CreateFrame("Frame", "CraftForgeSideToolsDock", parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
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
			tip = "/cf level",
			onClick = function() if CraftForge.ShowLeveling then CraftForge:ShowLeveling() end end,
		},
		{
			key = "cd",
			icon = 136243,
			label = L["CD_TITLE"] or "Cooldowns",
			tip = "/cf cd",
			onClick = function() if CraftForge.ShowCooldowns then CraftForge:ShowCooldowns() end end,
		},
		{
			key = "watch",
			icon = 136033,
			label = L["WATCH_TITLE"] or "Recipe Watch",
			tip = L["SIDE_WATCH_TIP"] or "Click: Toggle HUD | Shift-Click: Pin selected",
			onClick = function()
				if IsShiftKeyDown() and CraftForge.Watch and CraftForge.Watch.PinCurrentOrByName then
					CraftForge.Watch:PinCurrentOrByName("")
				elseif CraftForge.ToggleWatchHUD then
					CraftForge:ToggleWatchHUD()
				end
			end,
		},
		{
			key = "gather",
			icon = 136065,
			label = L["GATHER_TITLE"] or "Gathering Guide",
			tip = "/cf gather",
			onClick = function() if CraftForge.ShowGathering then CraftForge:ShowGathering() end end,
		},
		{
			key = "contacts",
			icon = 133784,
			label = L["CONTACTS_TITLE"] or "Trade Contacts",
			tip = "/cf contacts",
			onClick = function() if CraftForge.ShowContacts then CraftForge:ShowContacts() end end,
		},
		{
			key = "fish",
			icon = 136245,
			label = L["Fishing"] or "Fishing",
			tip = "/cf fish",
			onClick = function() if CraftForge.ShowFishing then CraftForge:ShowFishing() end end,
		},
		{
			key = "camp",
			icon = 135805,
			label = L["CAMP_TITLE"] or "Camping",
			tip = "/cf camp",
			onClick = function() if CraftForge.ShowCamping then CraftForge:ShowCamping() end end,
		},
		{
			key = "find",
			icon = 134269,
			label = L["SIDE_ALT_FINDER"] or "Alt Finder",
			tip = "/cf find",
			onClick = function() if CraftForge.ShowAltFinder then CraftForge:ShowAltFinder() end end,
		},
		{
			key = "gear",
			icon = 132633,
			label = L["GEAR_TITLE"] or "Crafted Gear",
			tip = "/cf gear",
			onClick = function() if CraftForge.ShowGear then CraftForge:ShowGear() end end,
		},
		{
			key = "buffs",
			icon = 134830,
			label = L["BUFFS_ONLY"] or "Buffs only",
			tip = L["BUFFS_ONLY_TIP"] or "Filter list to consumables & enhancements usable at your level",
			onClick = function()
				if CraftForge.SetTradeSkillOption and CraftForge.GetTradeSkillOption then
					local cur = CraftForge:GetTradeSkillOption("buffsOnly")
					CraftForge:SetTradeSkillOption("buffsOnly", not cur)
					if CraftForge.SortAndFilterRecipes then CraftForge:SortAndFilterRecipes() end
					if CraftForge.UpdateTradeSkillWindow then CraftForge:UpdateTradeSkillWindow() end
				end
			end,
		},
		{
			key = "process",
			icon = 132853,
			label = L["SIDE_PROCESS"] or "Processing",
			tip = "/cf process",
			onClick = function() if CraftForge.ShowProcessPanel then CraftForge:ShowProcessPanel() end end,
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
		local dbp = CraftForge.db and CraftForge.db.profile
		local nextState = not (dbp and dbp.sideDockCollapsed)
		if dbp then dbp.sideDockCollapsed = nextState end
		applyCollapsedState(nextState)
	end)

	dock:SetScript("OnShow", function()
		local readyCD = (CraftForge.Cooldowns and CraftForge.Cooldowns.GetReadyCount and CraftForge.Cooldowns:GetReadyCount()) or 0
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

	local initCollapsed = CraftForge.db and CraftForge.db.profile and CraftForge.db.profile.sideDockCollapsed
	applyCollapsedState(initCollapsed and true or false)

	sideDock = dock
	return dock
end
