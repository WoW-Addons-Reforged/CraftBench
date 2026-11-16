----------------------------------------------------------
-- CraftForge - Native Dark-Gold Gathering Window       --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")
local L = CraftForge.L

CraftForge.GatheringUI = CraftForge.GatheringUI or {}
local GatheringUI = CraftForge.GatheringUI

local gatherFrame
local activeTab = "herbalism"

local function ensureFrame()
	if gatherFrame then return gatherFrame end
	local UIStyle = CraftForge.UIStyle
	local f = CreateFrame("Frame", "CraftForgeGatheringWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(720, 480)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "CraftForgeGatheringWindow")

	if UIStyle then
		UIStyle.SkinFrame(f, false)
		UIStyle.CreateHeader(f, "CraftForge — " .. (L["GATHER_TITLE"] or "Gathering Guide"), 136065, function()
			f:Hide()
		end)
	end

	local topBar = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	topBar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -52)
	topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -52)
	topBar:SetHeight(40)
	if UIStyle then UIStyle.SkinInset(topBar) end

	f._tabs = {}
	local tabs = {
		{ id = "herbalism", label = L["GATHER_HERB"] or "Herbalism" },
		{ id = "mining", label = L["GATHER_MINE"] or "Mining" },
		{ id = "skinning", label = L["GATHER_SKIN"] or "Skinning" },
	}
	local x = 8
	for _, t in ipairs(tabs) do
		local btn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(topBar, 130, 26, t.label, "secondary")
			or CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
		btn:SetPoint("LEFT", topBar, "LEFT", x, 0)
		btn:SetScript("OnClick", function()
			activeTab = t.id
			GatheringUI:Refresh()
		end)
		f._tabs[t.id] = btn
		x = x + 138
	end

	local rankFS = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	rankFS:SetPoint("RIGHT", topBar, "RIGHT", -12, 0)
	rankFS:SetTextColor(0.95, 0.82, 0.25)
	f._rankFS = rankFS

	local body = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	body:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -8)
	body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	if UIStyle then UIStyle.SkinInset(body) end

	local scroll = CreateFrame("ScrollFrame", "CraftForgeGatheringScroll", body, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -26, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(scroll) end

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(660, 1)
	scroll:SetScrollChild(child)
	f._child = child
	f._rows = {}

	gatherFrame = f
	return f
end

function GatheringUI:Refresh()
	if not gatherFrame or not gatherFrame:IsShown() then return end
	local Gathering = CraftForge.Gathering
	if not Gathering then return end
	local UIStyle = CraftForge.UIStyle

	for id, btn in pairs(gatherFrame._tabs) do
		if btn.SetBackdropBorderColor then
			if id == activeTab then
				btn:SetBackdropBorderColor(0.95, 0.80, 0.25, 1)
			else
				btn:SetBackdropBorderColor(0.25, 0.28, 0.35, 1)
			end
		end
	end

	local rank, maxRank = Gathering:GetSkillRank(activeTab)
	if rank > 0 then
		gatherFrame._rankFS:SetText(string.format("%s: %d / %d", L["GATHER_SKILL"] or "Skill", rank, maxRank))
	else
		gatherFrame._rankFS:SetText("|cff9d9d9d" .. (L["GATHER_NOT_LEARNED"] or "Not learned") .. "|r")
	end

	local list = Gathering.DATA[activeTab] or {}
	for _, r in ipairs(gatherFrame._rows) do r:Hide() end

	local y = -2
	for idx, node in ipairs(list) do
		local row = gatherFrame._rows[idx]
		if not row then
			row = CreateFrame("Frame", nil, gatherFrame._child, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(650, 36)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(row, 0.09, 0.10, 0.14, 0.85, 0.20, 0.23, 0.30, 0.8)
			end
			row._name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			row._name:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -4)
			row._name:SetJustifyH("LEFT")

			row._req = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._req:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -4)
			row._req:SetJustifyH("RIGHT")

			row._zones = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._zones:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 4)
			row._zones:SetPoint("RIGHT", row, "RIGHT", -96, 0)
			row._zones:SetJustifyH("LEFT")
			row._zones:SetTextColor(0.72, 0.76, 0.82)

			local wpBtn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(row, 82, 20, L["Waypoint"] or "Waypoint", "secondary")
				or CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
			wpBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 3)
			row._wpBtn = wpBtn

			gatherFrame._rows[idx] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", gatherFrame._child, "TOPLEFT", 0, y)
		local col = Gathering:GetDifficultyColor(node, rank)
		local nodeInfo = CraftForge.FindGatherNodeLocation and CraftForge:FindGatherNodeLocation(node.name, activeTab)
		if nodeInfo then
			local distText = ""
			if nodeInfo.dist then
				if nodeInfo.dist >= 1000 then
					distText = string.format(" • %.1fk yd", nodeInfo.dist / 1000)
				else
					distText = string.format(" • %d yd", math.floor(nodeInfo.dist + 0.5))
				end
			end
			row._name:SetText(col .. node.name .. "|r  |cff66ccff[" .. nodeInfo.addon .. ": " .. nodeInfo.totalCount .. distText .. "]|r")
			row._wpBtn:SetScript("OnClick", function()
				if CraftForge.SetGatherWaypoint then
					CraftForge:SetGatherWaypoint(nodeInfo)
				end
			end)
			row._wpBtn:Show()
		else
			row._name:SetText(col .. node.name .. "|r")
			row._wpBtn:Hide()
		end
		row._req:SetText(string.format("%s %d  |cff9d9d9d(%d / %d / %d)|r", L["GATHER_REQ"] or "Req", node.req, node.yellow, node.green, node.grey))
		row._zones:SetText(node.zones)
		row:Show()
		y = y - 38
	end
	gatherFrame._child:SetHeight(math.max(100, -y + 10))
end

function CraftForge:ShowGathering(tab)
	if tab and CraftForge.Gathering and CraftForge.Gathering.DATA[tab] then
		activeTab = tab
	end
	local f = ensureFrame()
	f:Show()
	GatheringUI:Refresh()
end
