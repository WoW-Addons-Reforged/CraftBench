local addonName, addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("CraftForge") -- for DebugAids.lua
--[[
CraftForge: A tradeskill window replacement.

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

local L = CraftForge.L

local SHOW_NEWS_MODES = {
	{ id = 1, label = L["NEWS_MODE_ALWAYS"] or "Always" },
	{ id = 2, label = L["NEWS_MODE_ACCOUNT"] or "Once per Account" },
	{ id = 3, label = L["NEWS_MODE_PLAYER"] or "Once per Player" },
	{ id = 4, label = L["NEWS_MODE_NEVER"] or "Never" },
}

local function capitalize(str)
	str = str or ""
	return string.upper(string.sub(str, 1, 1)) .. string.lower(string.sub(str, 2))
end

local function InitializeDB(self)
	if not CraftForge.db.global.NewsDB then
		CraftForge.db.global.NewsDB = {}
	end
	self.db = CraftForge.db.global.NewsDB
	if not self.db.show_news then
		self.db.show_news = 1
	end
	if not self.db.lastVersion then
		self.db.lastVersion = {}
	end
end

local function Create(self)
	local UIStyle = CraftForge.UIStyle
	local frame = CreateFrame("Frame", "CraftForgeNewsWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	frame:SetSize(720, 500)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
	frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "CraftForgeNewsWindow")

	if UIStyle then
		UIStyle.SkinFrame(frame, false)
	end

	local title = "CraftForge " .. tostring(CraftForge.version or "") .. " — " .. (L["News"] or "News")
	if UIStyle and UIStyle.CreateHeader then
		UIStyle.CreateHeader(frame, title, "Interface\\Icons\\Trade_BlackSmithing", function()
			frame:Hide()
		end)
	end

	-- Footer bar: "Show News" mode selector
	local footer = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
	footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
	footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
	footer:SetHeight(34)
	if UIStyle then
		UIStyle.SkinInset(footer)
	end

	local modeLabel = footer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	modeLabel:SetPoint("LEFT", footer, "LEFT", 10, 0)
	modeLabel:SetText((L["Show News"] or "Show News") .. ":")
	modeLabel:SetTextColor(0.95, 0.82, 0.25)
	if UIStyle then UIStyle.ApplyFont(modeLabel, -1) end

	local modeButtons = {}
	local function refreshModeButtons()
		for _, btn in ipairs(modeButtons) do
			local active = (self.db.show_news == btn._modeId)
			if btn.SetBackdropColor then
				if active then
					btn:SetBackdropColor(0.24, 0.20, 0.08, 1)
					btn:SetBackdropBorderColor(0.79, 0.64, 0.15, 1)
				else
					btn:SetBackdropColor(0.11, 0.13, 0.17, 1)
					btn:SetBackdropBorderColor(0.24, 0.27, 0.34, 1)
				end
			end
			if btn._fs then
				if active then
					btn._fs:SetTextColor(1, 0.85, 0.3)
				else
					btn._fs:SetTextColor(0.78, 0.82, 0.88)
				end
			end
		end
	end

	local prevBtn = modeLabel
	for idx, mode in ipairs(SHOW_NEWS_MODES) do
		local btn
		if UIStyle and UIStyle.CreateButton then
			btn = UIStyle.CreateButton(footer, 118, 22, mode.label, "secondary")
		else
			btn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
			btn:SetSize(118, 22)
			btn:SetText(mode.label)
		end
		btn._modeId = mode.id
		btn._fs = btn.GetFontString and btn:GetFontString()
		if idx == 1 then
			btn:SetPoint("LEFT", prevBtn, "RIGHT", 10, 0)
		else
			btn:SetPoint("LEFT", prevBtn, "RIGHT", 6, 0)
		end
		btn:SetScript("OnClick", function()
			self.db.show_news = mode.id
			refreshModeButtons()
		end)
		table.insert(modeButtons, btn)
		prevBtn = btn
	end
	refreshModeButtons()

	-- Left Sidebar: Version list
	local sidebar = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
	sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -52)
	sidebar:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 0, 8)
	sidebar:SetWidth(165)
	if UIStyle then
		UIStyle.SkinInset(sidebar)
	end

	-- Right Content Panel
	local contentBox = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
	contentBox:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
	contentBox:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 8)
	if UIStyle then
		UIStyle.SkinInset(contentBox)
	end

	local scroll = CreateFrame("ScrollFrame", "CraftForgeNewsScrollFrame", contentBox, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", contentBox, "TOPLEFT", 10, -10)
	scroll:SetPoint("BOTTOMRIGHT", contentBox, "BOTTOMRIGHT", -28, 10)
	if UIStyle and UIStyle.StyleScrollBar then
		UIStyle.StyleScrollBar(scroll)
	end

	local scrollChild = CreateFrame("Frame", nil, scroll)
	scrollChild:SetWidth(470)
	scrollChild:SetHeight(1)
	scroll:SetScrollChild(scrollChild)

	local textPool = {}
	local dividerPool = {}
	local function clearContent()
		for _, fs in ipairs(textPool) do fs:Hide() end
		for _, tx in ipairs(dividerPool) do tx:Hide() end
	end

	local function acquireFS(fontTemplate)
		local fs = table.remove(textPool)
		if not fs then
			fs = scrollChild:CreateFontString(nil, "OVERLAY", fontTemplate or "GameFontNormal")
		end
		fs:ClearAllPoints()
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(true)
		fs:Show()
		return fs
	end

	local usedFS = {}
	local usedDiv = {}
	local function renderVersion(versionData)
		for _, fs in ipairs(usedFS) do
			fs:Hide()
			table.insert(textPool, fs)
		end
		wipe(usedFS)
		for _, tx in ipairs(usedDiv) do
			tx:Hide()
			table.insert(dividerPool, tx)
		end
		wipe(usedDiv)

		if not versionData then return end
		local y = -4
		local width = math.max(300, (scroll:GetWidth() or 470) - 8)
		scrollChild:SetWidth(width)

		local verTitle = acquireFS("GameFontNormalLarge")
		verTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, y)
		verTitle:SetWidth(width)
		verTitle:SetText((L["Version"] or "Version") .. " " .. tostring(versionData.version or ""))
		verTitle:SetTextColor(0.95, 0.80, 0.25)
		if UIStyle then UIStyle.ApplyFont(verTitle, 3) end
		table.insert(usedFS, verTitle)
		y = y - (verTitle:GetStringHeight() or 20) - 10

		for _, group in ipairs(versionData.data or {}) do
			local groupName = capitalize(group.name or "")
			local gHeader = acquireFS("GameFontNormal")
			gHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, y)
			gHeader:SetWidth(width)
			gHeader:SetText(groupName)
			gHeader:SetTextColor(0.85, 0.72, 0.30)
			if UIStyle then UIStyle.ApplyFont(gHeader, 1) end
			table.insert(usedFS, gHeader)
			y = y - (gHeader:GetStringHeight() or 16) - 4

			local line = table.remove(dividerPool) or scrollChild:CreateTexture(nil, "ARTWORK")
			line:ClearAllPoints()
			line:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, y)
			line:SetSize(width, 1)
			line:SetColorTexture(0.79, 0.64, 0.15, 0.45)
			line:Show()
			table.insert(usedDiv, line)
			y = y - 8

			for _, entry in ipairs(group.data or {}) do
				local hFS = acquireFS("GameFontNormal")
				hFS:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 6, y)
				hFS:SetWidth(width - 12)
				hFS:SetText(entry.header or "")
				hFS:SetTextColor(0.45, 0.72, 1.0)
				if UIStyle then UIStyle.ApplyFont(hFS, 0) end
				table.insert(usedFS, hFS)
				y = y - (hFS:GetStringHeight() or 15) - 3

				local bFS = acquireFS("GameFontHighlightSmall")
				bFS:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 12, y)
				bFS:SetWidth(width - 18)
				bFS:SetText(entry.body or "")
				bFS:SetTextColor(0.88, 0.90, 0.94)
				if UIStyle then UIStyle.ApplyFont(bFS, -1) end
				table.insert(usedFS, bFS)
				y = y - (bFS:GetStringHeight() or 14) - 10
			end
			y = y - 6
		end

		scrollChild:SetHeight(math.max(100, -y + 10))
		scroll:SetVerticalScroll(0)
	end

	local versionButtons = {}
	local selectedIdx = 1
	local function refreshVersionButtons()
		for idx, btn in ipairs(versionButtons) do
			local active = (idx == selectedIdx)
			if btn.SetBackdropColor then
				if active then
					btn:SetBackdropColor(0.24, 0.20, 0.08, 1)
					btn:SetBackdropBorderColor(0.79, 0.64, 0.15, 1)
				else
					btn:SetBackdropColor(0.11, 0.13, 0.17, 1)
					btn:SetBackdropBorderColor(0.22, 0.25, 0.32, 1)
				end
			end
			if btn._fs then
				if active then
					btn._fs:SetTextColor(1, 0.85, 0.3)
				else
					btn._fs:SetTextColor(0.80, 0.84, 0.90)
				end
			end
		end
	end

	local newsList = CraftForge.NewsData or {}
	for idx, versionData in ipairs(newsList) do
		local btn
		if UIStyle and UIStyle.CreateButton then
			btn = UIStyle.CreateButton(sidebar, 145, 26, "v" .. tostring(versionData.version or ""), "secondary")
		else
			btn = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
			btn:SetSize(145, 26)
			btn:SetText("v" .. tostring(versionData.version or ""))
		end
		btn._fs = btn.GetFontString and btn:GetFontString()
		btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, -10 - (idx - 1) * 32)
		btn:SetScript("OnClick", function()
			selectedIdx = idx
			refreshVersionButtons()
			renderVersion(versionData)
		end)
		table.insert(versionButtons, btn)
	end

	clearContent()
	if newsList[1] then
		refreshVersionButtons()
		renderVersion(newsList[1])
	end

	CraftForge.NewsFrame = frame
	return frame
end

local NewsGUI = {}
function NewsGUI:Initialize()
	DA.DEBUG(0, "NewsGUI:Initialize()")
	InitializeDB(self)
	self:Create()
	self._initialized = true
end

function NewsGUI:Create()
	DA.DEBUG(0, "NewsGUI:Create()")
	local f = Create(self)
	self.top = f
	local player = CraftForge:unitName("player")
	local version = CraftForge.version
	if self.db.show_news == 4 or
	  (self.db.show_news == 3 and self.db.lastVersion[player] and self.db.lastVersion[player] == version) or
	  (self.db.show_news == 2 and self.db.lastVersionA and self.db.lastVersionA == version) then
		f:Hide()
	end
	self.db.lastVersionA = version
	self.db.lastVersion[player] = version
end

function NewsGUI:Toggle()
	DA.DEBUG(0, "NewsGUI:Toggle()")
	if not self._initialized then return end
	if self.top:IsVisible() then
		self.top:Hide()
	else
		self.top:Show()
	end
end

function NewsGUI:Reset()
	DA.DEBUG(0, "NewsGUI:Reset()")
	self.top:ClearAllPoints()
	self.top:SetPoint("CENTER", 0, 0)
end

CraftForge.NewsGUI = NewsGUI
