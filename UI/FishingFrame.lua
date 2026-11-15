----------------------------------------------------------
-- CraftForge - Native Dark-Gold Fishing Window        --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")
local L = CraftForge.L

CraftForge.FishingUI = CraftForge.FishingUI or {}
local FishingUI = CraftForge.FishingUI

local fishingFrame
local selectedZoneKey = nil

local function formatMoneyShort(copper)
	copper = math.floor(tonumber(copper) or 0)
	if copper <= 0 then return "|cff888888-|r" end
	if CraftForge.FormatMoneyFull then
		return CraftForge:FormatMoneyFull(copper, true)
	end
	local g = math.floor(copper / 10000)
	local s = math.floor((copper % 10000) / 100)
	local c = copper % 100
	if g > 0 then
		return string.format("|cffffd100%dg|r |cffc7c7cf%ds|r", g, s)
	elseif s > 0 then
		return string.format("|cffc7c7cf%ds|r |cffeda55f%dc|r", s, c)
	end
	return string.format("|cffeda55f%dc|r", c)
end

local function formatClock(sec)
	sec = math.max(0, math.floor(sec or 0))
	local d = math.floor(sec / 86400)
	local h = math.floor((sec % 86400) / 3600)
	local m = math.floor((sec % 3600) / 60)
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %dm", h, m)
	end
	return string.format("%dm %ds", m, sec % 60)
end

local function ensureFishingFrame()
	if fishingFrame then return fishingFrame end
	local UIStyle = CraftForge.UIStyle
	local f = CreateFrame("Frame", "CraftForgeFishingWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(760, 520)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "CraftForgeFishingWindow")

	if UIStyle then
		UIStyle.SkinFrame(f, false)
		UIStyle.CreateHeader(f, "CraftForge — " .. (L["Fishing"] or "Fishing"), 136245, function()
			f:Hide()
		end)
	end

	-- Top Status & Action Bar
	local topBar = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	topBar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -52)
	topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -52)
	topBar:SetHeight(58)
	if UIStyle then UIStyle.SkinInset(topBar) end

	local skillFS = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	skillFS:SetPoint("TOPLEFT", topBar, "TOPLEFT", 12, -8)
	skillFS:SetJustifyH("LEFT")
	if UIStyle then UIStyle.ApplyFont(skillFS, 0) end
	f._skillFS = skillFS

	local sessionFS = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sessionFS:SetPoint("TOPLEFT", skillFS, "BOTTOMLEFT", 0, -4)
	sessionFS:SetJustifyH("LEFT")
	if UIStyle then UIStyle.ApplyFont(sessionFS, -1) end
	f._sessionFS = sessionFS

	local derbyFS = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	derbyFS:SetPoint("BOTTOMLEFT", topBar, "BOTTOMLEFT", 12, 6)
	derbyFS:SetJustifyH("LEFT")
	if UIStyle then UIStyle.ApplyFont(derbyFS, -1) end
	f._derbyFS = derbyFS

	local swapBtn
	if UIStyle and UIStyle.CreateButton then
		swapBtn = UIStyle.CreateButton(topBar, 118, 24, L["FISH_SWAP_POLE"] or "Swap Pole", "secondary")
	else
		swapBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
		swapBtn:SetSize(118, 24)
		swapBtn:SetText(L["FISH_SWAP_POLE"] or "Swap Pole")
	end
	swapBtn:SetPoint("TOPRIGHT", topBar, "TOPRIGHT", -10, -8)
	swapBtn:SetScript("OnClick", function()
		if CraftForge.Fishing and CraftForge.Fishing.TriggerSwap then
			CraftForge.Fishing:TriggerSwap()
		end
	end)

	local lureBtn
	if UIStyle and UIStyle.CreateButton then
		lureBtn = UIStyle.CreateButton(topBar, 126, 24, L["FISH_AUTOLURE_ON"] or "Auto-Lure: ON", "secondary")
	else
		lureBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
		lureBtn:SetSize(126, 24)
		lureBtn:SetText(L["FISH_AUTOLURE_ON"] or "Auto-Lure: ON")
	end
	lureBtn:SetPoint("RIGHT", swapBtn, "LEFT", -6, 0)
	lureBtn:SetScript("OnClick", function()
		local gdb = CraftForge.Fishing and CraftForge.Fishing:GetDB()
		if gdb and gdb.settings then
			gdb.settings.autoLure = (gdb.settings.autoLure == false) and true or false
			FishingUI:Refresh()
		end
	end)
	f._lureBtn = lureBtn

	-- Left Sidebar: Zones
	local zoneBox = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	zoneBox:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -8)
	zoneBox:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
	zoneBox:SetWidth(210)
	if UIStyle then UIStyle.SkinInset(zoneBox) end

	local zoneScroll = CreateFrame("ScrollFrame", "CraftForgeFishingZoneScroll", zoneBox, "UIPanelScrollFrameTemplate")
	zoneScroll:SetPoint("TOPLEFT", zoneBox, "TOPLEFT", 6, -8)
	zoneScroll:SetPoint("BOTTOMRIGHT", zoneBox, "BOTTOMRIGHT", -24, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(zoneScroll) end

	local zoneChild = CreateFrame("Frame", nil, zoneScroll)
	zoneChild:SetSize(176, 1)
	zoneScroll:SetScrollChild(zoneChild)
	f._zoneChild = zoneChild
	f._zoneButtons = {}

	-- Right Panel: Caught Items
	local itemBox = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	itemBox:SetPoint("TOPLEFT", zoneBox, "TOPRIGHT", 8, 0)
	itemBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	if UIStyle then UIStyle.SkinInset(itemBox) end

	local zoneHeader = itemBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	zoneHeader:SetPoint("TOPLEFT", itemBox, "TOPLEFT", 10, -8)
	zoneHeader:SetTextColor(0.95, 0.80, 0.25)
	if UIStyle then UIStyle.ApplyFont(zoneHeader, 0) end
	f._zoneHeader = zoneHeader

	local itemScroll = CreateFrame("ScrollFrame", "CraftForgeFishingItemScroll", itemBox, "UIPanelScrollFrameTemplate")
	itemScroll:SetPoint("TOPLEFT", itemBox, "TOPLEFT", 8, -30)
	itemScroll:SetPoint("BOTTOMRIGHT", itemBox, "BOTTOMRIGHT", -26, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(itemScroll) end

	local itemChild = CreateFrame("Frame", nil, itemScroll)
	itemChild:SetSize(486, 1)
	itemScroll:SetScrollChild(itemChild)
	f._itemChild = itemChild
	f._itemRows = {}

	fishingFrame = f
	return f
end

function FishingUI:Refresh()
	if not fishingFrame or not fishingFrame:IsShown() then return end
	local Fishing = CraftForge.Fishing
	if not Fishing then return end
	local UIStyle = CraftForge.UIStyle
	local gdb = Fishing:GetDB()
	if not gdb then return end

	local rank, mod, maxRank = Fishing:GetFishingSkill()
	local hasLure, lureSecs = Fishing:GetActiveLureInfo()
	local lureText = hasLure and string.format("|cff40ff40" .. (L["FISH_LURE_ACTIVE"] or "Lure active (%dm %ds)") .. "|r", math.floor(lureSecs / 60), lureSecs % 60) or ("|cff9d9d9d" .. (L["FISH_NO_LURE"] or "No lure") .. "|r")
	if rank then
		local modStr = (mod and mod > 0) and ("|cff40ff40+" .. mod .. "|r") or ""
		fishingFrame._skillFS:SetText(string.format("|cffffd100%s:|r %d%s / %d   •   %s", L["Fishing"] or "Fishing", rank, modStr, maxRank or 300, lureText))
	else
		fishingFrame._skillFS:SetText("|cffff6666" .. (L["FISH_NOT_LEARNED"] or "Fishing not learned") .. "|r   •   " .. lureText)
	end

	local ses = Fishing:GetSession()
	local mins = ses.started and math.max(0.1, (GetTime() - ses.started) / 60) or 0
	local perHr = (mins >= 1) and math.floor((ses.catches / mins) * 60 + 0.5) or 0
	fishingFrame._sessionFS:SetText(string.format(L["FISH_SESSION_FMT"] or "Session: |cffffffff%d|r catches (%d/hr), |cffffffff%d|r skill-ups, value ~%s",
		ses.catches or 0, perHr, ses.ups or 0, formatMoneyShort(ses.value or 0)))

	local derbyState, derbyLeft = Fishing:GetDerbyStatus()
	if derbyState == "live" then
		fishingFrame._derbyFS:SetText((L["FISH_DERBY_LIVE"] or "|cff40ff40Stranglethorn Derby LIVE!|r Ends in ") .. formatClock(derbyLeft))
	else
		fishingFrame._derbyFS:SetText((L["FISH_DERBY_NEXT"] or "|cff9d9d9dStranglethorn Derby:|r in ") .. formatClock(derbyLeft)
			.. "   |cff777777(" .. (L["FISH_DERBY_HINT"] or "Keybind: Esc -> Key Bindings -> AddOns -> CraftForge") .. ")|r")
	end

	local autoOn = gdb.settings and gdb.settings.autoLure ~= false
	fishingFrame._lureBtn:SetText(autoOn and (L["FISH_AUTOLURE_ON"] or "Auto-Lure: ON") or (L["FISH_AUTOLURE_OFF"] or "Auto-Lure: OFF"))

	-- Build sorted zone list
	local zones = {}
	for _, rec in pairs(gdb.zones or {}) do
		table.insert(zones, rec)
	end
	table.sort(zones, function(a, b)
		if (a.catches or 0) ~= (b.catches or 0) then
			return (a.catches or 0) > (b.catches or 0)
		end
		return (a.key or "") < (b.key or "")
	end)

	if not selectedZoneKey and zones[1] then
		selectedZoneKey = zones[1].key
	end

	for _, btn in ipairs(fishingFrame._zoneButtons) do btn:Hide() end
	local zy = -2
	for idx, rec in ipairs(zones) do
		local btn = fishingFrame._zoneButtons[idx]
		if not btn then
			if UIStyle and UIStyle.CreateButton then
				btn = UIStyle.CreateButton(fishingFrame._zoneChild, 170, 26, "", "secondary")
			else
				btn = CreateFrame("Button", nil, fishingFrame._zoneChild, "UIPanelButtonTemplate")
				btn:SetSize(170, 26)
			end
			btn._fs = btn.GetFontString and btn:GetFontString()
			if btn._fs then btn._fs:SetJustifyH("LEFT") end
			fishingFrame._zoneButtons[idx] = btn
		end
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", fishingFrame._zoneChild, "TOPLEFT", 2, zy)
		local label = (rec.subzone ~= rec.zone) and (rec.subzone or rec.zone) or rec.zone
		btn:SetText(string.format("%s (%d)", label, rec.catches or 0))
		local isSel = (rec.key == selectedZoneKey)
		if btn.SetBackdropColor then
			if isSel then
				btn:SetBackdropColor(0.24, 0.20, 0.08, 1)
				btn:SetBackdropBorderColor(0.79, 0.64, 0.15, 1)
			else
				btn:SetBackdropColor(0.11, 0.13, 0.17, 1)
				btn:SetBackdropBorderColor(0.22, 0.25, 0.32, 1)
			end
		end
		btn:SetScript("OnClick", function()
			selectedZoneKey = rec.key
			FishingUI:Refresh()
		end)
		btn:Show()
		zy = zy - 30
	end
	fishingFrame._zoneChild:SetHeight(math.max(100, -zy + 10))

	-- Populate right table
	for _, row in ipairs(fishingFrame._itemRows) do row:Hide() end
	local activeZone = selectedZoneKey and gdb.zones and gdb.zones[selectedZoneKey]
	if not activeZone then
		fishingFrame._zoneHeader:SetText(L["FISH_NO_CATCHES"] or "No catches logged yet — cast a line!")
		fishingFrame._itemChild:SetHeight(100)
		return
	end

	fishingFrame._zoneHeader:SetText(string.format(L["FISH_ZONE_HEADER_FMT"] or "%s — %s  |cffc7c7cf(%d catches, %d casts)|r",
		activeZone.zone or "?", activeZone.subzone or "?", activeZone.catches or 0, activeZone.casts or 0))

	local items = {}
	for _, it in pairs(activeZone.items or {}) do
		table.insert(items, it)
	end
	table.sort(items, function(a, b)
		if (a.count or 0) ~= (b.count or 0) then
			return (a.count or 0) > (b.count or 0)
		end
		return (a.name or "") < (b.name or "")
	end)

	local totalCatches = math.max(1, activeZone.catches or 1)
	local iy = -2
	for idx, it in ipairs(items) do
		local row = fishingFrame._itemRows[idx]
		if not row then
			row = CreateFrame("Button", nil, fishingFrame._itemChild, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(480, 26)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(row, 0.09, 0.10, 0.14, 0.85, 0.20, 0.23, 0.30, 0.8)
			end
			row._icon = row:CreateTexture(nil, "ARTWORK")
			row._icon:SetSize(20, 20)
			row._icon:SetPoint("LEFT", row, "LEFT", 4, 0)
			row._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

			row._name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._name:SetPoint("LEFT", row._icon, "RIGHT", 6, 0)
			row._name:SetWidth(205)
			row._name:SetJustifyH("LEFT")

			row._stats = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._stats:SetPoint("RIGHT", row, "RIGHT", -8, 0)
			row._stats:SetJustifyH("RIGHT")

			row:SetScript("OnEnter", function(btn)
				if btn._link and GameTooltip then
					GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
					GameTooltip:SetHyperlink(btn._link)
					GameTooltip:Show()
				end
			end)
			row:SetScript("OnLeave", function()
				if GameTooltip then GameTooltip:Hide() end
			end)
			fishingFrame._itemRows[idx] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", fishingFrame._itemChild, "TOPLEFT", 0, iy)
		row._link = it.link or ("item:" .. tostring(it.id))
		local tex = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(it.id)) or (GetItemIcon and GetItemIcon(it.id)) or 134400
		row._icon:SetTexture(tex)

		local qColor = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[it.quality or 1]
		local hex = qColor and qColor.hex or "|cffffffff"
		row._name:SetText(hex .. (it.name or ("Item #" .. it.id)) .. "|r")

		local pct = math.floor(((it.hauls or 1) / totalCatches) * 100 + 0.5)
		local val = CraftForge.GetItemMarketOrVendorPrice and CraftForge:GetItemMarketOrVendorPrice(it.id) or 0
		row._stats:SetText(string.format(L["FISH_ITEM_STATS_FMT"] or "x%d  |cff9d9d9d(%d%%)|r  •  Skill %s  •  D:%d/N:%d  •  %s",
			it.count or 1, pct, tostring(it.minSkill or "?"), it.day or 0, it.night or 0, formatMoneyShort(val)))
		row:Show()
		iy = iy - 28
	end
	fishingFrame._itemChild:SetHeight(math.max(100, -iy + 10))
end

function CraftForge:ShowFishing()
	local f = ensureFishingFrame()
	f:Show()
	FishingUI:Refresh()
end

local fishingBar
function FishingUI:InitializeBar()
	if fishingBar then
		self:RefreshBar()
		return
	end
	local UIStyle = CraftForge.UIStyle
	local Fishing = CraftForge.Fishing
	if not Fishing then return end

	local bar = CreateFrame("Frame", "CraftForgeFishingBar", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	bar:SetSize(230, 40)
	bar:SetFrameStrata("MEDIUM")
	bar:SetClampedToScreen(true)
	bar:EnableMouse(true)
	bar:SetMovable(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", function(f) f:StartMoving() end)
	bar:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
		if CraftForge.db and CraftForge.db.profile then
			local point, _, relPoint, x, y = f:GetPoint()
			CraftForge.db.profile.fishingBarPos = { point = point, relPoint = relPoint, x = x, y = y }
		end
	end)

	local pos = CraftForge.db and CraftForge.db.profile and CraftForge.db.profile.fishingBarPos
	if pos and pos.point then
		bar:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
	else
		bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 140)
	end

	if UIStyle and UIStyle.ApplyBox then
		UIStyle.ApplyBox(bar, 0.08, 0.09, 0.12, 0.94, 0.79, 0.64, 0.15, 0.9)
	end

	-- 1. Secure Cast / Auto-Lure Button
	local useDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
	local castBtn = CreateFrame("Button", "CraftForgeFishingBarCastButton", bar, "SecureActionButtonTemplate,BackdropTemplate")
	castBtn:SetSize(28, 28)
	castBtn:SetPoint("LEFT", bar, "LEFT", 6, 0)
	castBtn:RegisterForClicks(useDown and "LeftButtonDown" or "LeftButtonUp")
	if UIStyle and UIStyle.ApplyBox then
		UIStyle.ApplyBox(castBtn, 0.12, 0.14, 0.19, 1, 0.45, 0.38, 0.16, 1)
	end
	local castIcon = castBtn:CreateTexture(nil, "ARTWORK")
	castIcon:SetPoint("TOPLEFT", 2, -2)
	castIcon:SetPoint("BOTTOMRIGHT", -2, 2)
	castIcon:SetTexture(136245)
	castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	Fishing:ApplyCastAttributes(castBtn)
	castBtn:HookScript("PostClick", function()
		if C_Timer and C_Timer.After then
			C_Timer.After(0.2, function()
				Fishing:ApplyCastAttributes(castBtn)
				FishingUI:RefreshBar()
			end)
		end
	end)
	castBtn:SetScript("OnEnter", function(btn)
		if GameTooltip then
			GameTooltip:SetOwner(btn, "ANCHOR_TOP")
			GameTooltip:AddLine(L["FISH_BAR_CAST_TITLE"] or "|cffffd100CraftForge: Cast Fishing|r")
			GameTooltip:AddLine(L["FISH_BAR_CAST_TIP"] or "Left-Click: Apply best lure (if needed) & cast Fishing", 0.9, 0.9, 0.9, true)
			GameTooltip:Show()
		end
	end)
	castBtn:SetScript("OnLeave", function()
		if GameTooltip then GameTooltip:Hide() end
	end)
	FishingUI._barCastBtn = castBtn

	-- 2. Swap Pole / Weapons Button
	local swapBtn = CreateFrame("Button", "CraftForgeFishingBarSwapButton", bar, BackdropTemplateMixin and "BackdropTemplate" or nil)
	swapBtn:SetSize(28, 28)
	swapBtn:SetPoint("LEFT", castBtn, "RIGHT", 4, 0)
	if UIStyle and UIStyle.ApplyBox then
		UIStyle.ApplyBox(swapBtn, 0.12, 0.14, 0.19, 1, 0.35, 0.38, 0.45, 1)
	end
	local swapIcon = swapBtn:CreateTexture(nil, "ARTWORK")
	swapIcon:SetPoint("TOPLEFT", 2, -2)
	swapIcon:SetPoint("BOTTOMRIGHT", -2, 2)
	swapIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	swapBtn._icon = swapIcon
	swapBtn:SetScript("OnClick", function()
		Fishing:TriggerSwap()
		if C_Timer and C_Timer.After then
			C_Timer.After(0.25, function() FishingUI:RefreshBar() end)
		end
	end)
	swapBtn:SetScript("OnEnter", function(btn)
		if GameTooltip then
			GameTooltip:SetOwner(btn, "ANCHOR_TOP")
			local equipped = Fishing:IsPoleEquipped()
			GameTooltip:AddLine(equipped and (L["FISH_BAR_POLE_EQUIPPED"] or "|cff40ff40Pole Equipped|r") or (L["FISH_BAR_WEAPONS_EQUIPPED"] or "|cffffd100Weapons Equipped|r"))
			GameTooltip:AddLine(L["FISH_BAR_SWAP_TIP"] or "Left-Click: Swap between Fishing Pole and combat weapons", 0.9, 0.9, 0.9, true)
			GameTooltip:Show()
		end
	end)
	swapBtn:SetScript("OnLeave", function()
		if GameTooltip then GameTooltip:Hide() end
	end)
	bar._swapBtn = swapBtn

	-- 3. Info / Open Window Area
	local infoBtn = CreateFrame("Button", nil, bar)
	infoBtn:SetPoint("LEFT", swapBtn, "RIGHT", 6, 0)
	infoBtn:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
	infoBtn:SetHeight(30)
	infoBtn:RegisterForDrag("LeftButton")
	infoBtn:SetScript("OnDragStart", function() bar:StartMoving() end)
	infoBtn:SetScript("OnDragStop", function()
		bar:StopMovingOrSizing()
		if CraftForge.db and CraftForge.db.profile then
			local point, _, relPoint, x, y = bar:GetPoint()
			CraftForge.db.profile.fishingBarPos = { point = point, relPoint = relPoint, x = x, y = y }
		end
	end)
	infoBtn:SetScript("OnClick", function()
		if CraftForge.ShowFishing then CraftForge:ShowFishing() end
	end)
	infoBtn:SetScript("OnEnter", function(btn)
		if GameTooltip then
			GameTooltip:SetOwner(btn, "ANCHOR_TOP")
			GameTooltip:AddLine(L["FISH_BAR_TITLE"] or "|cffffd100CraftForge Fishing|r")
			GameTooltip:AddLine(L["FISH_BAR_OPEN_TIP"] or "Click: Open Fishing Window (/cf fish)", 0.9, 0.9, 0.9)
			GameTooltip:AddLine(L["FISH_BAR_DRAG_TIP"] or "Drag: Move Bar", 0.75, 0.75, 0.75)
			GameTooltip:Show()
		end
	end)
	infoBtn:SetScript("OnLeave", function()
		if GameTooltip then GameTooltip:Hide() end
	end)

	local topFS = infoBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	topFS:SetPoint("TOPLEFT", infoBtn, "TOPLEFT", 0, -2)
	topFS:SetPoint("RIGHT", infoBtn, "RIGHT", 0, 0)
	topFS:SetJustifyH("LEFT")
	bar._topFS = topFS

	local botFS = infoBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	botFS:SetPoint("BOTTOMLEFT", infoBtn, "BOTTOMLEFT", 0, 2)
	botFS:SetPoint("RIGHT", infoBtn, "RIGHT", 0, 0)
	botFS:SetJustifyH("LEFT")
	bar._botFS = botFS

	local elapsedAcc = 0
	bar:SetScript("OnUpdate", function(_, elapsed)
		elapsedAcc = elapsedAcc + elapsed
		if elapsedAcc >= 1.0 then
			elapsedAcc = 0
			FishingUI:RefreshBar()
		end
	end)

	fishingBar = bar
	local gdb = Fishing:GetDB()
	local show = not gdb or not gdb.settings or gdb.settings.showBar ~= false
	self:SetBarVisible(show)
	self:RefreshBar()
end

function FishingUI:SetBarVisible(show)
	if not fishingBar then return end
	if show then
		fishingBar:Show()
		self:RefreshBar()
	else
		fishingBar:Hide()
	end
end

function FishingUI:RefreshBar()
	if not fishingBar or not fishingBar:IsShown() then return end
	local Fishing = CraftForge.Fishing
	if not Fishing then return end

	local poleEquipped = Fishing:IsPoleEquipped()
	if fishingBar._swapBtn then
		local getIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
		local charWeapons = CraftForge.db and CraftForge.db.char and CraftForge.db.char.fishingWeapons
		if poleEquipped then
			local mhID = charWeapons and charWeapons.mh
			local mhTex = mhID and getIcon and getIcon(mhID)
			fishingBar._swapBtn._icon:SetTexture(mhTex or 135328)
			if fishingBar._swapBtn.SetBackdropBorderColor then
				fishingBar._swapBtn:SetBackdropBorderColor(0.25, 0.95, 0.35, 1)
			end
		else
			local _, _, poleID = Fishing:FindPoleInBags()
			local poleTex = poleID and getIcon and getIcon(poleID)
			fishingBar._swapBtn._icon:SetTexture(poleTex or 132932)
			if fishingBar._swapBtn.SetBackdropBorderColor then
				fishingBar._swapBtn:SetBackdropBorderColor(0.79, 0.64, 0.15, 0.9)
			end
		end
	end

	local rank, mod = Fishing:GetFishingSkill()
	if rank then
		local modStr = (mod and mod > 0) and ("|cff40ff40+" .. mod .. "|r") or ""
		local tag = poleEquipped and ("|cff40ff40" .. (L["FISH_BAR_POLE_TAG"] or "[Pole]") .. "|r") or ("|cff9d9d9d" .. (L["FISH_BAR_WEAPON_TAG"] or "[Weapon]") .. "|r")
		fishingBar._topFS:SetText(string.format("|cffffd100%s|r %d%s  %s", L["FISH_BAR_SHORT"] or "Fish:", rank, modStr, tag))
	else
		fishingBar._topFS:SetText("|cff9d9d9d" .. (L["FISH_NOT_LEARNED"] or "Fishing not learned") .. "|r")
	end

	local hasLure, secsLeft = Fishing:GetActiveLureInfo()
	if hasLure then
		fishingBar._botFS:SetText(string.format(L["FISH_BAR_LURE_FMT"] or "|cff40ff40Lure: %dm %02ds|r", math.floor(secsLeft / 60), secsLeft % 60))
	else
		fishingBar._botFS:SetText(L["FISH_BAR_NOLURE_LOG"] or "|cff9d9d9dNo Lure  •  Click for Log|r")
	end
end
