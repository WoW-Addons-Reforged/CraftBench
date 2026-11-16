----------------------------------------------------------
-- CraftBench - Native Dark-Gold Forever Camping UI     --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")
local L = CraftBench.L

CraftBench.CampingUI = CraftBench.CampingUI or {}
local CampingUI = CraftBench.CampingUI

local campFrame

local function ensureFrame()
	if campFrame then return campFrame end
	local UIStyle = CraftBench.UIStyle
	local f = CreateFrame("Frame", "CraftBenchCampingWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(620, 420)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "CraftBenchCampingWindow")

	if UIStyle then
		UIStyle.SkinFrame(f, false)
		UIStyle.CreateHeader(f, "CraftBench — " .. (L["CAMP_TITLE"] or "Camping (WoW Forever)"), 135805, function()
			f:Hide()
		end)
	end

	local topBar = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	topBar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -52)
	topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -52)
	topBar:SetHeight(36)
	if UIStyle then UIStyle.SkinInset(topBar) end

	local rankFS = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	rankFS:SetPoint("LEFT", topBar, "LEFT", 12, 0)
	rankFS:SetTextColor(0.95, 0.82, 0.25)
	f._rankFS = rankFS

	local body = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	body:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -8)
	body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	if UIStyle then UIStyle.SkinInset(body) end

	local scroll = CreateFrame("ScrollFrame", "CraftBenchCampingScroll", body, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -26, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(scroll) end

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(560, 1)
	scroll:SetScrollChild(child)
	f._child = child
	f._rows = {}

	campFrame = f
	return f
end

function CampingUI:Refresh()
	if not campFrame or not campFrame:IsShown() then return end
	local Camping = CraftBench.Camping
	if not Camping then return end
	local UIStyle = CraftBench.UIStyle

	local rank, maxRank, list = Camping:GetStatusList()
	if rank > 0 then
		campFrame._rankFS:SetText(string.format("%s: %d / %d", L["CAMP_SKILL"] or "Camping Skill", rank, maxRank))
	else
		campFrame._rankFS:SetText("|cff9d9d9d" .. (L["CAMP_NOT_LEARNED"] or "Camping not learned (WoW Forever)") .. "|r")
	end

	for _, r in ipairs(campFrame._rows) do r:Hide() end
	local y = -2
	for idx, m in ipairs(list) do
		local row = campFrame._rows[idx]
		if not row then
			row = CreateFrame("Frame", nil, campFrame._child, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(550, 38)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(row, 0.09, 0.10, 0.14, 0.85, 0.20, 0.23, 0.30, 0.8)
			end
			row._name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row._name:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -4)
			row._name:SetJustifyH("LEFT")

			row._status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._status:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -4)
			row._status:SetJustifyH("RIGHT")

			row._desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._desc:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 4)
			row._desc:SetJustifyH("LEFT")
			row._desc:SetTextColor(0.72, 0.76, 0.82)
			campFrame._rows[idx] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", campFrame._child, "TOPLEFT", 0, y)
		row._name:SetText((m.unlocked and "|cff40ff40" or "|cffffd100") .. m.name .. "|r")
		row._status:SetText(m.unlocked and ("|cff40ff40" .. (L["CAMP_UNLOCKED"] or "Unlocked") .. "|r")
			or string.format("|cff9d9d9d%s %d|r", L["GATHER_REQ"] or "Req", m.req))
		row._desc:SetText(m.desc)
		row:Show()
		y = y - 40
	end
	campFrame._child:SetHeight(math.max(100, -y + 10))
end

function CraftBench:ShowCamping()
	local f = ensureFrame()
	f:Show()
	CampingUI:Refresh()
end
