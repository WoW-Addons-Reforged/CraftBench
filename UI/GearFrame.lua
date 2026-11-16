----------------------------------------------------------
-- CraftForge - Native Dark-Gold Crafted Gear Window    --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")
local L = CraftForge.L

CraftForge.GearUI = CraftForge.GearUI or {}
local GearUI = CraftForge.GearUI

local gearFrame
local activeCategory = "all"

local function ensureFrame()
	if gearFrame then return gearFrame end
	local UIStyle = CraftForge.UIStyle

	local f = CreateFrame("Frame", "CraftForgeGearWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(740, 500)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "CraftForgeGearWindow")

	if UIStyle then
		UIStyle.SkinFrame(f, false)
		UIStyle.CreateHeader(f, "CraftForge — " .. (L["GEAR_TITLE"] or "Crafted Gear"), 132633, function()
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
		{ key = "all", label = L["ALL"] or "All" },
		{ key = "armor", label = L["GEAR_ARMOR"] or "Armor" },
		{ key = "weapons", label = L["GEAR_WEAPONS"] or "Weapons" },
		{ key = "jewelry", label = L["GEAR_JEWELRY"] or "Back & Jewelry" },
	}
	local prevTab
	for _, t in ipairs(tabs) do
		local btn = CreateFrame("Button", nil, topBar, BackdropTemplateMixin and "BackdropTemplate" or nil)
		btn:SetSize(130, 26)
		if prevTab then
			btn:SetPoint("LEFT", prevTab, "RIGHT", 6, 0)
		else
			btn:SetPoint("LEFT", topBar, "LEFT", 8, 0)
		end
		if UIStyle then UIStyle.SkinButton(btn, "default") end
		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		fs:SetAllPoints()
		fs:SetText(t.label)
		btn._fs = fs
		btn:SetScript("OnClick", function()
			activeCategory = t.key
			GearUI:Refresh()
		end)
		f._tabs[t.key] = btn
		prevTab = btn
	end

	local infoText = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	infoText:SetPoint("RIGHT", topBar, "RIGHT", -10, 0)
	infoText:SetTextColor(0.75, 0.75, 0.75)
	f._infoText = infoText

	local sf = CreateFrame("ScrollFrame", "CraftForgeGearScroll", f, "UIPanelScrollFrameTemplate")
	sf:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -6)
	sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 12)
	if UIStyle and UIStyle.SkinScrollBar and sf.ScrollBar then
		UIStyle.SkinScrollBar(sf.ScrollBar)
	end

	local content = CreateFrame("Frame", nil, sf)
	content:SetSize(690, 400)
	sf:SetScrollChild(content)
	f._content = content
	f._rows = {}

	gearFrame = f
	return f
end

function GearUI:Refresh()
	local f = ensureFrame()
	local UIStyle = CraftForge.UIStyle
	for k, btn in pairs(f._tabs) do
		if k == activeCategory then
			if UIStyle then UIStyle.ApplyBox(btn, 0.25, 0.21, 0.08, 1, 0.79, 0.64, 0.15, 1) end
		else
			if UIStyle then UIStyle.SkinButton(btn, "default") end
		end
	end

	for _, r in ipairs(f._rows) do r:Hide() end

	local items = CraftForge.Gear and CraftForge.Gear:CollectCraftableGear(activeCategory) or {}
	f._infoText:SetText(string.format("%d %s", #items, L["Items"] or "Items"))

	local y = -4
	local rowH = 30
	if #items == 0 then
		local row = f._rows[1]
		if not row then
			row = CreateFrame("Button", nil, f._content, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(690, rowH)
			local txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			txt:SetPoint("LEFT", 10, 0)
			row._txt = txt
			f._rows[1] = row
		end
		row:SetPoint("TOPLEFT", f._content, "TOPLEFT", 0, y)
		row._txt:SetText(L["GEAR_EMPTY"] or "Open a crafting profession window to scan craftable equipment.")
		row:Show()
		f._content:SetHeight(40)
		return
	end

	for idx, entry in ipairs(items) do
		local row = f._rows[idx]
		if not row then
			row = CreateFrame("Button", nil, f._content, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(690, rowH)
			if UIStyle then UIStyle.SkinInset(row) end

			local ico = row:CreateTexture(nil, "ARTWORK")
			ico:SetSize(22, 22)
			ico:SetPoint("LEFT", row, "LEFT", 6, 0)
			row._ico = ico

			local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			nameFs:SetPoint("LEFT", ico, "RIGHT", 8, 0)
			nameFs:SetWidth(280)
			nameFs:SetJustifyH("LEFT")
			row._name = nameFs

			local slotFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			slotFs:SetPoint("LEFT", nameFs, "RIGHT", 8, 0)
			slotFs:SetWidth(120)
			slotFs:SetJustifyH("LEFT")
			row._slot = slotFs

			local ilvlFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			ilvlFs:SetPoint("LEFT", slotFs, "RIGHT", 8, 0)
			ilvlFs:SetWidth(110)
			ilvlFs:SetJustifyH("LEFT")
			row._ilvl = ilvlFs

			local craftFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			craftFs:SetPoint("RIGHT", row, "RIGHT", -10, 0)
			row._craft = craftFs

			f._rows[idx] = row
		end

		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", f._content, "TOPLEFT", 0, y)
		row._ico:SetTexture(entry.icon or 134400)
		row._name:SetText(entry.link or entry.name)
		row._slot:SetText("|cffbbbbbb" .. (entry.slotName or "") .. "|r")
		row._ilvl:SetText(string.format("iLvl %d  (Lv %d)", entry.itemLevel or 0, entry.reqLevel or 0))
		if entry.numCraftable > 0 then
			row._craft:SetText("|cff40ff40[" .. entry.numCraftable .. "]|r")
		else
			row._craft:SetText("|cff888888[0]|r")
		end

		row:SetScript("OnEnter", function(selfBtn)
			GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
			if GameTooltip.SetItemByID and entry.itemID then
				GameTooltip:SetItemByID(entry.itemID)
			elseif entry.link then
				GameTooltip:SetHyperlink(entry.link)
			end
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		row:SetScript("OnClick", function()
			if CraftForge.SetSelectedSkill and entry.skillIndex then
				CraftForge:SetSelectedSkill(entry.skillIndex, true)
			end
		end)

		row:Show()
		y = y - (rowH + 3)
	end

	f._content:SetHeight(math.max(100, -y + 10))
end

function CraftForge:ShowGear()
	local f = ensureFrame()
	if f:IsShown() then
		f:Hide()
	else
		GearUI:Refresh()
		f:Show()
	end
end
