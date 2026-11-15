----------------------------------------------------------
-- CraftForge - Native Dark-Gold Cooldowns Window       --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")
local L = CraftForge.L

CraftForge.CooldownsUI = CraftForge.CooldownsUI or {}
local CooldownsUI = CraftForge.CooldownsUI

local cdFrame
local onlyReady = false

local function formatDuration(sec)
	sec = math.max(0, math.floor(sec or 0))
	if sec == 0 then
		return "|cff40ff40" .. (L["CD_READY"] or "Ready!") .. "|r"
	end
	local d = math.floor(sec / 86400)
	local h = math.floor((sec % 86400) / 3600)
	local m = math.floor((sec % 3600) / 60)
	if d > 0 then
		return string.format("|cffffd100%dd %dh %dm|r", d, h, m)
	elseif h > 0 then
		return string.format("|cffffd100%dh %dm|r", h, m)
	end
	return string.format("|cffffff80%dm %ds|r", m, sec % 60)
end

local function ensureFrame()
	if cdFrame then return cdFrame end
	local UIStyle = CraftForge.UIStyle
	local f = CreateFrame("Frame", "CraftForgeCooldownsWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(640, 440)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "CraftForgeCooldownsWindow")

	if UIStyle then
		UIStyle.SkinFrame(f, false)
		UIStyle.CreateHeader(f, "CraftForge — " .. (L["CD_TITLE"] or "Crafting Cooldowns"), 136243, function()
			f:Hide()
		end)
	end

	local topBar = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	topBar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -52)
	topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -52)
	topBar:SetHeight(36)
	if UIStyle then UIStyle.SkinInset(topBar) end

	local filterBtn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(topBar, 150, 24, L["CD_FILTER_ALL"] or "Show: All", "secondary")
		or CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	filterBtn:SetPoint("LEFT", topBar, "LEFT", 8, 0)
	filterBtn:SetScript("OnClick", function()
		onlyReady = not onlyReady
		filterBtn:SetText(onlyReady and (L["CD_FILTER_READY"] or "Show: Ready Only") or (L["CD_FILTER_ALL"] or "Show: All"))
		CooldownsUI:Refresh()
	end)
	f._filterBtn = filterBtn

	local clearBtn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(topBar, 140, 24, L["CD_CLEAR_READY"] or "Clear Ready", "secondary")
		or CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	clearBtn:SetPoint("RIGHT", topBar, "RIGHT", -8, 0)
	clearBtn:SetScript("OnClick", function()
		if CraftForge.Cooldowns then
			CraftForge.Cooldowns:ClearExpired()
		end
		CooldownsUI:Refresh()
	end)

	local body = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	body:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -8)
	body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	if UIStyle then UIStyle.SkinInset(body) end

	local scroll = CreateFrame("ScrollFrame", "CraftForgeCooldownsScroll", body, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -26, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(scroll) end

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(580, 1)
	scroll:SetScrollChild(child)
	f._child = child
	f._rows = {}

	local emptyFS = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	emptyFS:SetPoint("CENTER", body, "CENTER", 0, 0)
	emptyFS:SetText(L["CD_EMPTY"] or "No tracked crafting cooldowns yet. Open a profession with cooldown recipes to scan.")
	emptyFS:SetTextColor(0.65, 0.65, 0.70)
	f._emptyFS = emptyFS

	cdFrame = f
	return f
end

function CooldownsUI:Refresh()
	if not cdFrame or not cdFrame:IsShown() then return end
	local Cooldowns = CraftForge.Cooldowns
	if not Cooldowns then return end
	local UIStyle = CraftForge.UIStyle
	local entries = Cooldowns:GetAllEntries(onlyReady)

	for _, row in ipairs(cdFrame._rows) do row:Hide() end
	if #entries == 0 then
		cdFrame._emptyFS:Show()
		cdFrame._child:SetHeight(100)
		return
	end
	cdFrame._emptyFS:Hide()

	local y = -2
	for idx, rec in ipairs(entries) do
		local row = cdFrame._rows[idx]
		if not row then
			row = CreateFrame("Frame", nil, cdFrame._child, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(572, 28)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(row, 0.09, 0.10, 0.14, 0.85, 0.20, 0.23, 0.30, 0.8)
			end
			row._name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row._name:SetPoint("LEFT", row, "LEFT", 8, 0)
			row._name:SetWidth(240)
			row._name:SetJustifyH("LEFT")

			row._player = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._player:SetPoint("LEFT", row._name, "RIGHT", 8, 0)
			row._player:SetWidth(180)
			row._player:SetJustifyH("LEFT")

			row._time = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._time:SetPoint("RIGHT", row, "RIGHT", -8, 0)
			row._time:SetJustifyH("RIGHT")

			cdFrame._rows[idx] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", cdFrame._child, "TOPLEFT", 0, y)
		row._name:SetText(rec.name)
		row._player:SetText("|cff95fcff" .. tostring(rec.player) .. "|r")
		row._time:SetText(formatDuration(rec.remaining))
		row:Show()
		y = y - 30
	end
	cdFrame._child:SetHeight(math.max(100, -y + 10))
end

function CraftForge:ShowCooldowns()
	local f = ensureFrame()
	if CraftForge.Cooldowns and CraftForge.Cooldowns.ScanCurrentProfession then
		CraftForge.Cooldowns:ScanCurrentProfession()
	end
	f:Show()
	CooldownsUI:Refresh()
end
