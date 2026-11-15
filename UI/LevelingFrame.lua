----------------------------------------------------------
-- CraftForge - Native Dark-Gold Leveling Planner UI    --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")
local L = CraftForge.L

CraftForge.LevelingUI = CraftForge.LevelingUI or {}
local LevelingUI = CraftForge.LevelingUI

local levelFrame
local currentPlan

local DIFF_COLORS = {
	optimal = "|cffff8040",
	medium = "|cffffff00",
	easy = "|cff40bf40",
}

local function formatMoney(copper)
	copper = math.floor(tonumber(copper) or 0)
	if copper <= 0 then return "|cff888888-|r" end
	if CraftForge.FormatMoneyFull then
		return CraftForge:FormatMoneyFull(copper, true)
	end
	local g = math.floor(copper / 10000)
	local s = math.floor((copper % 10000) / 100)
	return string.format("|cffffd100%dg|r |cffc7c7cf%ds|r", g, s)
end

local function ensureFrame()
	if levelFrame then return levelFrame end
	local UIStyle = CraftForge.UIStyle
	local f = CreateFrame("Frame", "CraftForgeLevelingWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(680, 480)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "CraftForgeLevelingWindow")

	if UIStyle then
		UIStyle.SkinFrame(f, false)
		UIStyle.CreateHeader(f, "CraftForge — " .. (L["LVL_TITLE"] or "Leveling Planner"), 136249, function()
			f:Hide()
		end)
	end

	local topBar = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	topBar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -52)
	topBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -52)
	topBar:SetHeight(42)
	if UIStyle then UIStyle.SkinInset(topBar) end

	local curLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	curLabel:SetPoint("LEFT", topBar, "LEFT", 10, 0)
	curLabel:SetText(L["LVL_CURRENT"] or "Current:")

	local curBox = CreateFrame("EditBox", nil, topBar, BackdropTemplateMixin and "BackdropTemplate" or nil)
	curBox:SetSize(48, 22)
	curBox:SetPoint("LEFT", curLabel, "RIGHT", 6, 0)
	curBox:SetAutoFocus(false)
	curBox:SetNumeric(true)
	curBox:SetFontObject("GameFontHighlightSmall")
	curBox:SetJustifyH("CENTER")
	if UIStyle and UIStyle.ApplyBox then UIStyle.ApplyBox(curBox, 0.05, 0.06, 0.09, 1, 0.35, 0.38, 0.45, 1) end
	f._curBox = curBox

	local tgtLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	tgtLabel:SetPoint("LEFT", curBox, "RIGHT", 14, 0)
	tgtLabel:SetText(L["LVL_TARGET"] or "Target:")

	local tgtBox = CreateFrame("EditBox", nil, topBar, BackdropTemplateMixin and "BackdropTemplate" or nil)
	tgtBox:SetSize(48, 22)
	tgtBox:SetPoint("LEFT", tgtLabel, "RIGHT", 6, 0)
	tgtBox:SetAutoFocus(false)
	tgtBox:SetNumeric(true)
	tgtBox:SetFontObject("GameFontHighlightSmall")
	tgtBox:SetJustifyH("CENTER")
	if UIStyle and UIStyle.ApplyBox then UIStyle.ApplyBox(tgtBox, 0.05, 0.06, 0.09, 1, 0.35, 0.38, 0.45, 1) end
	f._tgtBox = tgtBox

	local calcBtn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(topBar, 120, 24, L["LVL_CALC"] or "Calculate", "primary")
		or CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	calcBtn:SetPoint("LEFT", tgtBox, "RIGHT", 14, 0)
	calcBtn:SetScript("OnClick", function()
		LevelingUI:Calculate()
	end)

	local queueBtn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(topBar, 160, 24, L["LVL_ADD_QUEUE"] or "Add Path to Queue", "secondary")
		or CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	queueBtn:SetPoint("RIGHT", topBar, "RIGHT", -10, 0)
	queueBtn:SetScript("OnClick", function()
		if currentPlan and CraftForge.Leveling then
			local n = CraftForge.Leveling:QueuePlan(currentPlan)
			if n > 0 then
				CraftForge:Print(string.format(L["LVL_QUEUED_FMT"] or "Added %d leveling step(s) to queue.", n))
			end
		end
	end)

	local body = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	body:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -8)
	body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	if UIStyle then UIStyle.SkinInset(body) end

	local statusFS = body:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	statusFS:SetPoint("TOPLEFT", body, "TOPLEFT", 10, -8)
	statusFS:SetTextColor(0.95, 0.82, 0.25)
	f._statusFS = statusFS

	local scroll = CreateFrame("ScrollFrame", "CraftForgeLevelingScroll", body, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -28)
	scroll:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -26, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(scroll) end

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(620, 1)
	scroll:SetScrollChild(child)
	f._child = child
	f._rows = {}

	levelFrame = f
	return f
end

function LevelingUI:Calculate()
	if not levelFrame or not CraftForge.Leveling then return end
	local UIStyle = CraftForge.UIStyle
	local cur = tonumber(levelFrame._curBox:GetText()) or 1
	local tgt = tonumber(levelFrame._tgtBox:GetText()) or (cur + 25)
	local plan, err = CraftForge.Leveling:BuildPlan(cur, tgt)
	currentPlan = plan

	for _, r in ipairs(levelFrame._rows) do r:Hide() end
	if not plan then
		local msg = (err == "NO_PROFESSION" or err == "NO_RECIPES")
			and (L["LVL_OPEN_PROF"] or "Open a crafting profession first so CraftForge can scan your recipes.")
			or (L["LVL_NO_UPGRADES"] or "No orange, yellow, or green recipes found for leveling.")
		levelFrame._statusFS:SetText("|cffff6666" .. msg .. "|r")
		levelFrame._child:SetHeight(60)
		return
	end

	levelFrame._statusFS:SetText(string.format(L["LVL_SUMMARY_FMT"] or "Path %d -> %d  |  Est. Cost: %s",
		plan.currentSkill, plan.targetSkill, formatMoney(plan.totalCost)))

	local y = -2
	local rowIdx = 0
	local function addRow(leftText, rightText)
		rowIdx = rowIdx + 1
		local row = levelFrame._rows[rowIdx]
		if not row then
			row = CreateFrame("Frame", nil, levelFrame._child, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(610, 24)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(row, 0.09, 0.10, 0.14, 0.85, 0.20, 0.23, 0.30, 0.8)
			end
			row._left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._left:SetPoint("LEFT", row, "LEFT", 8, 0)
			row._left:SetJustifyH("LEFT")
			row._right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._right:SetPoint("RIGHT", row, "RIGHT", -8, 0)
			row._right:SetJustifyH("RIGHT")
			levelFrame._rows[rowIdx] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", levelFrame._child, "TOPLEFT", 0, y)
		row._left:SetText(leftText)
		row._right:SetText(rightText or "")
		row:Show()
		y = y - 26
	end

	addRow("|cffffd100" .. (L["LVL_STEPS_HDR"] or "Crafting Steps") .. "|r", "")
	for _, s in ipairs(plan.steps) do
		local c = DIFF_COLORS[s.difficulty] or "|cffffffff"
		addRow(string.format("%s%s|r  x%d  (%d -> %d)", c, s.name, s.crafts, s.fromSkill, s.toSkill), formatMoney(s.estCost))
	end

	addRow("|cffffd100" .. (L["LVL_SHOPPING_HDR"] or "Required Materials (Shopping List)") .. "|r", "")
	for _, r in ipairs(plan.reagents) do
		local missCol = (r.missing == 0) and "|cff40ff40" or "|cffff6666"
		addRow(string.format("%s  (x%d)", r.name, r.need),
			string.format("%s%s: %d|r  |cff9d9d9d(%s: %d)|r", missCol, L["LVL_MISSING"] or "Missing", r.missing, L["Bags"] or "Bags", r.inBags))
	end

	levelFrame._child:SetHeight(math.max(100, -y + 10))
end

function CraftForge:ShowLeveling()
	local f = ensureFrame()
	local rank, maxRank = 1, 300
	if self.currentPlayer and self.currentTrade and self.GetSkillRanks then
		local data = self:GetSkillRanks(self.currentPlayer, self.currentTrade)
		if data then
			rank = data.rank or 1
			maxRank = data.maxRank or 300
		end
	end
	f._curBox:SetText(tostring(rank))
	f._tgtBox:SetText(tostring(math.min(maxRank, rank + 25)))
	f:Show()
	LevelingUI:Calculate()
end
