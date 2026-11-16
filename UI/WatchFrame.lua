----------------------------------------------------------
-- CraftBench - On-Screen Recipe Watch HUD              --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")
local L = CraftBench.L

CraftBench.WatchUI = CraftBench.WatchUI or {}
local WatchUI = CraftBench.WatchUI

local hudFrame

local function ensureHUD()
	if hudFrame then return hudFrame end
	local UIStyle = CraftBench.UIStyle
	local f = CreateFrame("Frame", "CraftBenchWatchHUD", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(250, 120)
	f:SetFrameStrata("MEDIUM")
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if CraftBench.db and CraftBench.db.profile then
			local p, _, rp, x, y = self:GetPoint()
			CraftBench.db.profile.watchHudPos = { point = p, relPoint = rp, x = x, y = y }
		end
	end)

	local pos = CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.watchHudPos
	if pos and pos.point then
		f:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
	else
		f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -240)
	end

	if UIStyle and UIStyle.ApplyBox then
		UIStyle.ApplyBox(f, 0.08, 0.09, 0.12, 0.92, 0.79, 0.64, 0.15, 0.85)
	end

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	title:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
	title:SetText("|cffffd100" .. (L["WATCH_TITLE"] or "CraftBench Watch") .. "|r")
	f._title = title

	local closeBtn = CreateFrame("Button", nil, f)
	closeBtn:SetSize(16, 16)
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
	closeBtn:SetNormalFontObject("GameFontNormalSmall")
	closeBtn:SetText("x")
	closeBtn:SetScript("OnClick", function() f:Hide() end)

	f._lines = {}
	hudFrame = f
	return f
end

local function acquireLine(parent, idx)
	if parent._lines[idx] then return parent._lines[idx] end
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(234, 16)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	fs:SetAllPoints()
	fs:SetJustifyH("LEFT")
	btn._fs = fs
	parent._lines[idx] = btn
	return btn
end

function WatchUI:Initialize()
	local list = CraftBench.Watch and CraftBench.Watch:GetWatchedList() or {}
	if #list > 0 then
		self:Refresh(true)
	end
end

function WatchUI:ToggleVisible()
	local f = ensureHUD()
	if f:IsShown() then
		f:Hide()
	else
		f:Show()
		self:Refresh(true)
	end
end

function WatchUI:Refresh(forceShow)
	local Watch = CraftBench.Watch
	if not Watch then return end
	local list = Watch:GetWatchedList()
	if not hudFrame and not forceShow and #list == 0 then return end
	local f = ensureHUD()
	if forceShow then f:Show() end
	if not f:IsShown() then return end

	for _, b in ipairs(f._lines) do b:Hide() end
	local lineIdx = 0
	local y = -24

	if #list == 0 then
		lineIdx = 1
		local ln = acquireLine(f, 1)
		ln:ClearAllPoints()
		ln:SetPoint("TOPLEFT", f, "TOPLEFT", 8, y)
		ln._fs:SetText("|cff9d9d9d" .. (L["WATCH_EMPTY"] or "No recipes pinned (/cb watch)") .. "|r")
		ln:SetScript("OnClick", nil)
		ln:Show()
		y = y - 20
	else
		for _, rec in ipairs(list) do
			lineIdx = lineIdx + 1
			local hdr = acquireLine(f, lineIdx)
			hdr:ClearAllPoints()
			hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 8, y)
			local status = rec.ready and ("|cff40ff40[" .. (L["WATCH_READY"] or "Ready") .. "]|r") or ""
			hdr._fs:SetText(string.format("|cffffd100%s x%d|r %s", rec.name, rec.count, status))
			local rid = rec.recipeID
			hdr:SetScript("OnClick", function(_, button)
				if button == "RightButton" then
					Watch:RemoveRecipe(rid)
				elseif IsShiftKeyDown() then
					Watch:AdjustCount(rid, -1)
				else
					Watch:AdjustCount(rid, 1)
				end
			end)
			hdr:SetScript("OnEnter", function(btn)
				if GameTooltip then
					GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
					GameTooltip:AddLine(rec.name)
					GameTooltip:AddLine(L["WATCH_HINT_CLICK"] or "Click: +1 | Shift-Click: -1 | Right-Click: Remove", 0.8, 0.8, 0.8)
					GameTooltip:Show()
				end
			end)
			hdr:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
			hdr:Show()
			y = y - 16

			for _, r in ipairs(rec.reagents) do
				lineIdx = lineIdx + 1
				local ln = acquireLine(f, lineIdx)
				ln:ClearAllPoints()
				ln:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y)
				local color = r.done and "|cff40ff40" or "|cffff6666"
				ln._fs:SetText(string.format("  %s%d/%d|r %s", color, r.have, r.need, r.name))
				ln:SetScript("OnClick", nil)
				ln:SetScript("OnEnter", nil)
				ln:Show()
				y = y - 14
			end
			y = y - 4
		end
	end
	f:SetHeight(math.max(54, -y + 6))
end

function CraftBench:ToggleWatchHUD()
	WatchUI:ToggleVisible()
end
