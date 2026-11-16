----------------------------------------------------------
-- CraftBench - Native Dark-Gold Trade Contacts Window  --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")
local L = CraftBench.L

CraftBench.ContactsUI = CraftBench.ContactsUI or {}
local ContactsUI = CraftBench.ContactsUI

local contactsFrame
local kindFilter = "all"
local selectedContactKey

local function formatMoneyShort(copper)
	copper = math.floor(tonumber(copper) or 0)
	if copper <= 0 then return "|cff888888-|r" end
	if CraftBench.FormatMoneyFull then
		return CraftBench:FormatMoneyFull(copper, true)
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

local function ensureFrame()
	if contactsFrame then return contactsFrame end
	local UIStyle = CraftBench.UIStyle
	local f = CreateFrame("Frame", "CraftBenchContactsWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(800, 500)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "CraftBenchContactsWindow")

	if UIStyle then
		UIStyle.SkinFrame(f, false)
		UIStyle.CreateHeader(f, "CraftBench — " .. (L["CONTACTS_TITLE"] or "Trade Contacts"), 133784, function()
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
		{ id = "all", label = L["CONTACTS_ALL"] or "All" },
		{ id = "vendors", label = L["CONTACTS_VENDORS"] or "Vendors" },
		{ id = "trainers", label = L["CONTACTS_TRAINERS"] or "Trainers" },
	}
	local x = 8
	for _, t in ipairs(tabs) do
		local btn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(topBar, 100, 24, t.label, "secondary")
			or CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
		btn:SetPoint("LEFT", topBar, "LEFT", x, 0)
		btn:SetScript("OnClick", function()
			kindFilter = t.id
			selectedContactKey = nil
			ContactsUI:Refresh()
		end)
		f._tabs[t.id] = btn
		x = x + 106
	end

	local searchBox = CreateFrame("EditBox", nil, topBar, BackdropTemplateMixin and "BackdropTemplate" or nil)
	searchBox:SetSize(240, 22)
	searchBox:SetPoint("RIGHT", topBar, "RIGHT", -10, 0)
	searchBox:SetAutoFocus(false)
	searchBox:SetFontObject("GameFontHighlightSmall")
	searchBox:SetTextInsets(6, 6, 0, 0)
	if UIStyle and UIStyle.ApplyBox then UIStyle.ApplyBox(searchBox, 0.05, 0.06, 0.09, 1, 0.35, 0.38, 0.45, 1) end
	searchBox:SetScript("OnTextChanged", function() ContactsUI:Refresh() end)
	f._searchBox = searchBox

	-- Left List: Vendors & Trainers
	local leftBody = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	leftBody:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -8)
	leftBody:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
	leftBody:SetWidth(370)
	if UIStyle then UIStyle.SkinInset(leftBody) end

	local scroll = CreateFrame("ScrollFrame", "CraftBenchContactsScroll", leftBody, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", leftBody, "TOPLEFT", 8, -8)
	scroll:SetPoint("BOTTOMRIGHT", leftBody, "BOTTOMRIGHT", -26, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(scroll) end

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(330, 1)
	scroll:SetScrollChild(child)
	f._child = child
	f._rows = {}

	-- Right Panel: Recipes & Goods sold/taught by selected NPC
	local rightBody = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	rightBody:SetPoint("TOPLEFT", leftBody, "TOPRIGHT", 8, 0)
	rightBody:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	if UIStyle then UIStyle.SkinInset(rightBody) end

	local detailHdr = rightBody:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detailHdr:SetPoint("TOPLEFT", rightBody, "TOPLEFT", 10, -8)
	detailHdr:SetPoint("RIGHT", rightBody, "RIGHT", -10, 0)
	detailHdr:SetJustifyH("LEFT")
	detailHdr:SetTextColor(0.95, 0.80, 0.25)
	f._detailHdr = detailHdr

	local itemScroll = CreateFrame("ScrollFrame", "CraftBenchContactsItemScroll", rightBody, "UIPanelScrollFrameTemplate")
	itemScroll:SetPoint("TOPLEFT", rightBody, "TOPLEFT", 8, -30)
	itemScroll:SetPoint("BOTTOMRIGHT", rightBody, "BOTTOMRIGHT", -26, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(itemScroll) end

	local itemChild = CreateFrame("Frame", nil, itemScroll)
	itemChild:SetSize(365, 1)
	itemScroll:SetScrollChild(itemChild)
	f._itemChild = itemChild
	f._itemRows = {}

	contactsFrame = f
	return f
end

local function refreshDetailPanel(activeRec)
	local UIStyle = CraftBench.UIStyle
	for _, r in ipairs(contactsFrame._itemRows) do r:Hide() end
	if not activeRec then
		contactsFrame._detailHdr:SetText(L["CONTACTS_NO_ITEMS"] or "Select a vendor or trainer to view their recipes & goods.")
		contactsFrame._itemChild:SetHeight(60)
		return
	end

	local list = {}
	if activeRec.items then
		for _, it in pairs(activeRec.items) do
			if type(it) == "table" then
				table.insert(list, {
					id = it.id,
					name = it.name or ("Item #" .. tostring(it.id)),
					price = it.price or 0,
					limited = it.limited,
				})
			end
		end
	end
	if activeRec.recipes then
		for _, r in ipairs(activeRec.recipes) do
			table.insert(list, {
				name = r.rank and r.rank ~= "" and (r.name .. " (" .. r.rank .. ")") or r.name,
				price = r.price or 0,
				category = r.category,
			})
		end
	end
	table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)

	contactsFrame._detailHdr:SetText(string.format("%s — %s (%d)",
		activeRec.name or "?", L["CONTACTS_ITEMS_HDR"] or "Recipes & Goods", #list))

	local getIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
	local iy = -2
	for idx, it in ipairs(list) do
		local row = contactsFrame._itemRows[idx]
		if not row then
			row = CreateFrame("Button", nil, contactsFrame._itemChild, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(360, 26)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(row, 0.09, 0.10, 0.14, 0.85, 0.20, 0.23, 0.30, 0.8)
			end
			row._icon = row:CreateTexture(nil, "ARTWORK")
			row._icon:SetSize(20, 20)
			row._icon:SetPoint("LEFT", row, "LEFT", 4, 0)
			row._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

			row._name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._name:SetPoint("LEFT", row._icon, "RIGHT", 6, 0)
			row._name:SetWidth(225)
			row._name:SetJustifyH("LEFT")

			row._price = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._price:SetPoint("RIGHT", row, "RIGHT", -8, 0)
			row._price:SetJustifyH("RIGHT")

			row:SetScript("OnEnter", function(btn)
				if btn._itemID and GameTooltip then
					GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
					if GameTooltip.SetItemByID then
						GameTooltip:SetItemByID(btn._itemID)
					else
						GameTooltip:SetHyperlink("item:" .. tostring(btn._itemID))
					end
					GameTooltip:Show()
				end
			end)
			row:SetScript("OnLeave", function()
				if GameTooltip then GameTooltip:Hide() end
			end)
			contactsFrame._itemRows[idx] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", contactsFrame._itemChild, "TOPLEFT", 0, iy)
		row._itemID = it.id
		local tex = (it.id and getIcon and getIcon(it.id)) or 134939
		row._icon:SetTexture(tex)
		local limitStr = it.limited and (" |cffff9933[x" .. it.limited .. "]|r") or ""
		row._name:SetText((it.name or "?") .. limitStr)
		row._price:SetText(formatMoneyShort(it.price))
		row:Show()
		iy = iy - 28
	end
	contactsFrame._itemChild:SetHeight(math.max(80, -iy + 10))
end

function ContactsUI:Refresh()
	if not contactsFrame or not contactsFrame:IsShown() then return end
	local Contacts = CraftBench.Contacts
	if not Contacts or not Contacts.GetAllEntries then return end
	local UIStyle = CraftBench.UIStyle

	for id, btn in pairs(contactsFrame._tabs) do
		if btn.SetBackdropBorderColor then
			if id == kindFilter then
				btn:SetBackdropBorderColor(0.95, 0.80, 0.25, 1)
			else
				btn:SetBackdropBorderColor(0.25, 0.28, 0.35, 1)
			end
		end
	end

	local query = contactsFrame._searchBox and contactsFrame._searchBox:GetText() or ""
	local entries = Contacts:GetAllEntries(kindFilter, query)
	for _, r in ipairs(contactsFrame._rows) do r:Hide() end

	local activeRec
	if not selectedContactKey and entries[1] then
		selectedContactKey = entries[1].kind .. ":" .. tostring(entries[1].id or entries[1].name)
	end

	local y = -2
	for idx, rec in ipairs(entries) do
		local rowKey = rec.kind .. ":" .. tostring(rec.id or rec.name)
		if rowKey == selectedContactKey then
			activeRec = rec
		end
		local row = contactsFrame._rows[idx]
		if not row then
			row = CreateFrame("Button", nil, contactsFrame._child, BackdropTemplateMixin and "BackdropTemplate" or nil)
			row:SetSize(326, 40)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(row, 0.09, 0.10, 0.14, 0.85, 0.20, 0.23, 0.30, 0.8)
			end
			row._name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			row._name:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -5)
			row._name:SetWidth(220)
			row._name:SetJustifyH("LEFT")

			row._loc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row._loc:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 5)
			row._loc:SetWidth(220)
			row._loc:SetJustifyH("LEFT")
			row._loc:SetTextColor(0.72, 0.76, 0.82)

			local wpBtn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(row, 84, 22, L["CONTACTS_WAYPOINT"] or "Waypoint", "secondary")
				or CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
			wpBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
			row._wpBtn = wpBtn

			contactsFrame._rows[idx] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", contactsFrame._child, "TOPLEFT", 0, y)
		if row.SetBackdropBorderColor then
			if rowKey == selectedContactKey then
				row:SetBackdropBorderColor(0.95, 0.80, 0.25, 1)
			else
				row:SetBackdropBorderColor(0.20, 0.23, 0.30, 0.8)
			end
		end

		local itemCount = 0
		if rec.items then
			for _ in pairs(rec.items) do itemCount = itemCount + 1 end
		elseif rec.recipes then
			itemCount = #rec.recipes
		end
		local tag = (rec.kind == "trainer") and ("|cff40ff40[" .. (L["CONTACTS_TRAINER_TAG"] or "Trainer") .. "]|r ")
			or ("|cffffd100[" .. (L["CONTACTS_VENDOR_TAG"] or "Vendor") .. "]|r ")
		row._name:SetText(string.format("%s%s |cff95fcff(%d)|r", tag, rec.name, itemCount))
		local coords = (rec.x and rec.y) and string.format(" (%.1f, %.1f)", rec.x, rec.y) or ""
		local sub = rec.subzone and (" - " .. rec.subzone) or ""
		row._loc:SetText((rec.zone or "?") .. sub .. coords)

		row:SetScript("OnClick", function()
			selectedContactKey = rowKey
			ContactsUI:Refresh()
		end)
		row._wpBtn:SetScript("OnClick", function()
			Contacts:SetWaypoint(rec)
		end)
		if rec.mapID and rec.x and rec.y then
			row._wpBtn:Enable()
		else
			row._wpBtn:Disable()
		end
		row:Show()
		y = y - 42
	end
	contactsFrame._child:SetHeight(math.max(100, -y + 10))
	refreshDetailPanel(activeRec)
end

function CraftBench:ShowContacts()
	local f = ensureFrame()
	f:Show()
	ContactsUI:Refresh()
end
