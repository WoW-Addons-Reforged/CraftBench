----------------------------------------------------------
-- CraftForge - Native Dark-Gold Options Window         --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")
local L = CraftForge.L

CraftForge.OptionsUI = CraftForge.OptionsUI or {}
local OptionsUI = CraftForge.OptionsUI

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local optionsFrame
local activeTabKey = "features"
local activeSubKey = nil
local dropdownMenu

local function resolveValue(val, info, ...)
	if type(val) == "function" then
		return val(info, ...)
	elseif type(val) == "string" and info and info.handler and type(info.handler[val]) == "function" then
		return info.handler[val](info.handler, info, ...)
	end
	return val
end

local function resolveMethod(opt, parentChain, key, info, ...)
	local fn = opt and opt[key]
	local owner = opt and opt.handler
	if not fn then
		for i = #parentChain, 1, -1 do
			local p = parentChain[i]
			if p and p[key] then
				fn = p[key]
				owner = p.handler or owner
				break
			end
		end
	end
	if not owner then
		for i = #parentChain, 1, -1 do
			if parentChain[i] and parentChain[i].handler then
				owner = parentChain[i].handler
				break
			end
		end
	end
	if type(fn) == "function" then
		return fn(info, ...)
	elseif type(fn) == "string" and owner and type(owner[fn]) == "function" then
		return owner[fn](owner, info, ...)
	end
	return nil
end

local function makeInfo(opt, parentChain, pathKeys)
	local info = {
		option = opt,
		options = parentChain[1],
		type = opt and opt.type,
		arg = opt and opt.arg,
		uiType = "dialog",
		uiName = "CraftForgeOptions-1.0",
	}
	for i = #parentChain, 1, -1 do
		if parentChain[i] and parentChain[i].handler then
			info.handler = parentChain[i].handler
			break
		end
	end
	if opt and opt.handler then
		info.handler = opt.handler
	end
	for i, k in ipairs(pathKeys) do
		info[i] = k
	end
	return info
end

local function isHidden(opt, parentChain, pathKeys)
	if not opt then return true end
	local h = opt.dialogHidden ~= nil and opt.dialogHidden or opt.hidden
	if h == nil then return false end
	local info = makeInfo(opt, parentChain, pathKeys)
	return resolveValue(h, info) and true or false
end

local function isDisabled(opt, parentChain, pathKeys)
	if not opt then return true end
	local d = opt.disabled
	if d == nil then return false end
	local info = makeInfo(opt, parentChain, pathKeys)
	return resolveValue(d, info) and true or false
end

local function getSortedArgs(argsTable, parentChain, basePath)
	local list = {}
	if type(argsTable) ~= "table" then return list end
	for key, opt in pairs(argsTable) do
		if type(opt) == "table" then
			local path = {}
			for _, pk in ipairs(basePath) do table.insert(path, pk) end
			table.insert(path, key)
			if not isHidden(opt, parentChain, path) then
				local info = makeInfo(opt, parentChain, path)
				local nameVal = resolveValue(opt.name, info) or key
				table.insert(list, {
					key = key,
					opt = opt,
					order = tonumber(opt.order) or 100,
					name = tostring(nameVal),
					path = path,
				})
			end
		end
	end
	table.sort(list, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end
		return a.name < b.name
	end)
	return list
end

local function attachTooltip(widget, titleText, descText)
	if not widget or (not titleText and not descText) then return end
	widget:SetScript("OnEnter", function(self)
		if not GameTooltip then return end
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		if titleText and titleText ~= "" then
			GameTooltip:AddLine(titleText, 1, 0.85, 0.25, true)
		end
		if descText and descText ~= "" then
			GameTooltip:AddLine(descText, 0.9, 0.9, 0.9, true)
		end
		GameTooltip:Show()
	end)
	widget:SetScript("OnLeave", function()
		if GameTooltip then GameTooltip:Hide() end
	end)
end

local function closeDropdownMenu()
	if dropdownMenu then
		dropdownMenu:Hide()
	end
end

local function openDropdownMenu(anchor, items, currentValue, onSelect)
	local UIStyle = CraftForge.UIStyle
	if not dropdownMenu then
		dropdownMenu = CreateFrame("Frame", "CraftForgeOptionsDropdownMenu", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		dropdownMenu:SetFrameStrata("FULLSCREEN_DIALOG")
		dropdownMenu:SetClampedToScreen(true)
		dropdownMenu:EnableMouse(true)
		if UIStyle then
			UIStyle.SkinFrame(dropdownMenu, false)
		end
		dropdownMenu._buttons = {}
	end

	for _, b in ipairs(dropdownMenu._buttons) do
		b:Hide()
	end

	local width = math.max(180, anchor:GetWidth() or 180)
	local y = -6
	for idx, entry in ipairs(items) do
		local btn = dropdownMenu._buttons[idx]
		if not btn then
			btn = CreateFrame("Button", nil, dropdownMenu, BackdropTemplateMixin and "BackdropTemplate" or nil)
			btn:SetHeight(22)
			local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			fs:SetPoint("LEFT", btn, "LEFT", 8, 0)
			fs:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
			fs:SetJustifyH("LEFT")
			btn._fs = fs
			btn:SetScript("OnEnter", function(self)
				if self.SetBackdropColor then
					self:SetBackdropColor(0.24, 0.20, 0.08, 1)
				end
			end)
			btn:SetScript("OnLeave", function(self)
				if self.SetBackdropColor then
					if self._isActive then
						self:SetBackdropColor(0.18, 0.16, 0.08, 1)
					else
						self:SetBackdropColor(0.08, 0.09, 0.12, 0)
					end
				end
			end)
			dropdownMenu._buttons[idx] = btn
		end
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 6, y)
		btn:SetWidth(width - 12)
		if UIStyle and UIStyle.ApplyBox then
			UIStyle.ApplyBox(btn, 0.08, 0.09, 0.12, 0, 0.2, 0.2, 0.25, 0)
		end
		btn._isActive = (entry.key == currentValue)
		btn._fs:SetText(entry.label)
		if btn._isActive then
			btn._fs:SetTextColor(1, 0.85, 0.25)
			if btn.SetBackdropColor then btn:SetBackdropColor(0.18, 0.16, 0.08, 1) end
		else
			btn._fs:SetTextColor(0.9, 0.92, 0.95)
		end
		btn:SetScript("OnClick", function()
			closeDropdownMenu()
			onSelect(entry.key)
		end)
		btn:Show()
		y = y - 23
	end

	dropdownMenu:SetSize(width, math.max(32, -y + 6))
	dropdownMenu:ClearAllPoints()
	dropdownMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	dropdownMenu:Show()
end

local function openColorPicker(r, g, b, a, hasAlpha, onChanged)
	if not ColorPickerFrame then return end
	if ColorPickerFrame.SetupColorPickerAndShow then
		local info = {
			r = r or 1,
			g = g or 1,
			b = b or 1,
			opacity = a or 1,
			hasOpacity = hasAlpha and true or false,
			swatchFunc = function()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB()
				local na = hasAlpha and ColorPickerFrame:GetColorAlpha() or 1
				onChanged(nr, ng, nb, na)
			end,
			opacityFunc = function()
				local nr, ng, nb = ColorPickerFrame:GetColorRGB()
				local na = hasAlpha and ColorPickerFrame:GetColorAlpha() or 1
				onChanged(nr, ng, nb, na)
			end,
			cancelFunc = function(prev)
				if prev then
					onChanged(prev.r, prev.g, prev.b, prev.a or 1)
				end
			end,
		}
		ColorPickerFrame:SetupColorPickerAndShow(info)
	else
		ColorPickerFrame.func = function()
			local nr, ng, nb = ColorPickerFrame:GetColorRGB()
			local na = hasAlpha and (1 - (OpacitySliderFrame and OpacitySliderFrame:GetValue() or 0)) or 1
			onChanged(nr, ng, nb, na)
		end
		ColorPickerFrame.hasOpacity = hasAlpha and true or false
		ColorPickerFrame.opacity = 1 - (a or 1)
		ColorPickerFrame:SetColorRGB(r or 1, g or 1, b or 1)
		ColorPickerFrame:Show()
	end
end

local function ensureOptionsFrame()
	if optionsFrame then return optionsFrame end

	local UIStyle = CraftForge.UIStyle
	local f = CreateFrame("Frame", "CraftForgeOptionsWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(780, 560)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		closeDropdownMenu()
		self:StartMoving()
	end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	f:SetScript("OnHide", function() closeDropdownMenu() end)
	tinsert(UISpecialFrames, "CraftForgeOptionsWindow")

	if UIStyle then
		UIStyle.SkinFrame(f, false)
		local title = "CraftForge " .. tostring(CraftForge.version or "") .. " — " .. (L["Options"] or "Options")
		UIStyle.CreateHeader(f, title, "Interface\\Icons\\Trade_BlackSmithing", function()
			f:Hide()
		end)
	end

	-- Left sidebar
	local sidebar = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	sidebar:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -52)
	sidebar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
	sidebar:SetWidth(190)
	if UIStyle then UIStyle.SkinInset(sidebar) end

	local sideScroll = CreateFrame("ScrollFrame", "CraftForgeOptionsSideScroll", sidebar, "UIPanelScrollFrameTemplate")
	sideScroll:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, -8)
	sideScroll:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -24, 8)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(sideScroll) end

	local sideChild = CreateFrame("Frame", nil, sideScroll)
	sideChild:SetSize(156, 1)
	sideScroll:SetScrollChild(sideChild)
	f._sideChild = sideChild

	-- Right content area
	local contentBox = CreateFrame("Frame", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	contentBox:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
	contentBox:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	if UIStyle then UIStyle.SkinInset(contentBox) end

	local subTabBar = CreateFrame("Frame", nil, contentBox)
	subTabBar:SetPoint("TOPLEFT", contentBox, "TOPLEFT", 10, -8)
	subTabBar:SetPoint("TOPRIGHT", contentBox, "TOPRIGHT", -10, -8)
	subTabBar:SetHeight(28)
	subTabBar:Hide()
	f._subTabBar = subTabBar

	local scroll = CreateFrame("ScrollFrame", "CraftForgeOptionsContentScroll", contentBox, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", contentBox, "TOPLEFT", 12, -12)
	scroll:SetPoint("BOTTOMRIGHT", contentBox, "BOTTOMRIGHT", -28, 12)
	if UIStyle and UIStyle.StyleScrollBar then UIStyle.StyleScrollBar(scroll) end
	f._scroll = scroll

	local scrollChild = CreateFrame("Frame", nil, scroll)
	scrollChild:SetSize(510, 1)
	scroll:SetScrollChild(scrollChild)
	f._scrollChild = scrollChild

	f._sideButtons = {}
	f._subTabButtons = {}
	f._pool = {}

	optionsFrame = f
	return f
end

local function renderOptionGroup(parent, optTable, parentChain, basePath, startY, contentWidth, onRefresh)
	local UIStyle = CraftForge.UIStyle
	local y = startY
	local sorted = getSortedArgs(optTable.args, parentChain, basePath)

	for _, item in ipairs(sorted) do
		local opt = item.opt
		local info = makeInfo(opt, parentChain, item.path)
		local disabled = isDisabled(opt, parentChain, item.path)
		local label = resolveValue(opt.name, info) or item.key
		local desc = resolveValue(opt.desc, info)
		local oType = opt.type

		if oType == "header" then
			y = y - 6
			local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			fs:SetWidth(contentWidth)
			fs:SetJustifyH("LEFT")
			fs:SetText(label)
			fs:SetTextColor(0.95, 0.80, 0.25)
			if UIStyle then UIStyle.ApplyFont(fs, 1) end
			y = y - (fs:GetStringHeight() or 16) - 4

			local div = parent:CreateTexture(nil, "ARTWORK")
			div:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			div:SetSize(contentWidth, 1)
			div:SetColorTexture(0.79, 0.64, 0.15, 0.45)
			y = y - 10
		elseif oType == "description" then
			local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			fs:SetWidth(contentWidth)
			fs:SetJustifyH("LEFT")
			fs:SetWordWrap(true)
			fs:SetText(label)
			fs:SetTextColor(0.86, 0.89, 0.93)
			if UIStyle then
				local delta = (opt.fontSize == "large" and 2) or (opt.fontSize == "medium" and 0) or -1
				UIStyle.ApplyFont(fs, delta)
			end
			y = y - (fs:GetStringHeight() or 14) - 8
		elseif oType == "toggle" then
			local cb
			if UIStyle and UIStyle.CreateCheckBox then
				cb = UIStyle.CreateCheckBox(parent, label)
			else
				cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
			end
			cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			local checked = resolveMethod(opt, parentChain, "get", info) and true or false
			cb:SetChecked(checked)
			if disabled then
				cb:Disable()
				cb:SetAlpha(0.45)
			else
				cb:Enable()
				cb:SetAlpha(1)
			end
			cb:SetScript("OnClick", function(self)
				local val = self:GetChecked() and true or false
				resolveMethod(opt, parentChain, "set", info, val)
				onRefresh()
			end)
			attachTooltip(cb, label, desc)
			y = y - 26
		elseif oType == "execute" then
			local btnWidth = math.min(contentWidth, math.max(150, (string.len(label) * 7) + 34))
			local btn
			if UIStyle and UIStyle.CreateButton then
				btn = UIStyle.CreateButton(parent, btnWidth, 24, label, "secondary")
			else
				btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
				btn:SetSize(btnWidth, 24)
				btn:SetText(label)
			end
			btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			if disabled then
				btn:Disable()
				btn:SetAlpha(0.45)
			else
				btn:Enable()
				btn:SetAlpha(1)
			end
			btn:SetScript("OnClick", function()
				resolveMethod(opt, parentChain, "func", info)
				onRefresh()
			end)
			attachTooltip(btn, label, desc)
			y = y - 30
		elseif oType == "select" then
			local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			lbl:SetWidth(contentWidth)
			lbl:SetJustifyH("LEFT")
			lbl:SetText(label)
			lbl:SetTextColor(0.92, 0.85, 0.55)
			if UIStyle then UIStyle.ApplyFont(lbl, -1) end
			y = y - (lbl:GetStringHeight() or 14) - 4

			local valuesTbl = resolveValue(opt.values, info) or {}
			local curKey = resolveMethod(opt, parentChain, "get", info)
			local curText = valuesTbl[curKey] or tostring(curKey or "")

			local ddBtn
			if UIStyle and UIStyle.CreateButton then
				ddBtn = UIStyle.CreateButton(parent, 250, 24, curText, "secondary")
			else
				ddBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
				ddBtn:SetSize(250, 24)
				ddBtn:SetText(curText)
			end
			local arrow = ddBtn:CreateTexture(nil, "OVERLAY")
			arrow:SetSize(14, 14)
			arrow:SetPoint("RIGHT", ddBtn, "RIGHT", -6, 0)
			arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
			ddBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			if disabled then
				ddBtn:Disable()
				ddBtn:SetAlpha(0.45)
			end
			ddBtn:SetScript("OnClick", function(self)
				if dropdownMenu and dropdownMenu:IsShown() then
					closeDropdownMenu()
					return
				end
				local entries = {}
				if type(opt.sorting) == "table" then
					for _, k in ipairs(opt.sorting) do
						if valuesTbl[k] ~= nil then
							table.insert(entries, { key = k, label = tostring(valuesTbl[k]) })
						end
					end
				else
					for k, v in pairs(valuesTbl) do
						table.insert(entries, { key = k, label = tostring(v) })
					end
					table.sort(entries, function(a, b) return a.label < b.label end)
				end
				openDropdownMenu(self, entries, curKey, function(chosenKey)
					resolveMethod(opt, parentChain, "set", info, chosenKey)
					onRefresh()
				end)
			end)
			attachTooltip(ddBtn, label, desc)
			y = y - 32
		elseif oType == "range" then
			local minVal = opt.min or 0
			local maxVal = opt.max or 100
			local stepVal = opt.step or 1
			local curVal = tonumber(resolveMethod(opt, parentChain, "get", info)) or minVal

			local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			lbl:SetJustifyH("LEFT")
			lbl:SetText(string.format("%s: |cffffffff%s|r", label, opt.isPercent and (math.floor(curVal * 100 + 0.5) .. "%") or tostring(curVal)))
			lbl:SetTextColor(0.92, 0.85, 0.55)
			if UIStyle then UIStyle.ApplyFont(lbl, -1) end
			y = y - (lbl:GetStringHeight() or 14) - 4

			local slider = CreateFrame("Slider", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
			slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, y)
			slider:SetSize(240, 14)
			slider:SetOrientation("HORIZONTAL")
			slider:SetMinMaxValues(minVal, maxVal)
			slider:SetValueStep(stepVal)
			slider:SetObeyStepOnDrag(true)
			slider:SetValue(curVal)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(slider, 0.05, 0.06, 0.08, 1, 0.25, 0.28, 0.35, 1)
			end
			local thumb = slider:CreateTexture(nil, "ARTWORK")
			thumb:SetSize(12, 16)
			thumb:SetColorTexture(0.85, 0.68, 0.20, 1)
			slider:SetThumbTexture(thumb)

			if disabled then
				slider:Disable()
				slider:SetAlpha(0.45)
			end
			slider:SetScript("OnValueChanged", function(_, value)
				local rounded = math.floor(value / stepVal + 0.5) * stepVal
				lbl:SetText(string.format("%s: |cffffffff%s|r", label, opt.isPercent and (math.floor(rounded * 100 + 0.5) .. "%") or tostring(rounded)))
			end)
			slider:SetScript("OnMouseUp", function(self)
				local value = math.floor(self:GetValue() / stepVal + 0.5) * stepVal
				resolveMethod(opt, parentChain, "set", info, value)
				onRefresh()
			end)
			attachTooltip(slider, label, desc)
			y = y - 24
		elseif oType == "input" then
			local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			lbl:SetJustifyH("LEFT")
			lbl:SetText(label)
			lbl:SetTextColor(0.92, 0.85, 0.55)
			if UIStyle then UIStyle.ApplyFont(lbl, -1) end
			y = y - (lbl:GetStringHeight() or 14) - 4

			local eb
			if UIStyle and UIStyle.CreateEditBox then
				eb = UIStyle.CreateEditBox(parent, 250, 22, "")
			else
				eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
				eb:SetSize(250, 22)
				eb:SetAutoFocus(false)
			end
			eb:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			local curVal = resolveMethod(opt, parentChain, "get", info) or ""
			eb:SetText(tostring(curVal))
			if disabled then
				eb:Disable()
				eb:SetAlpha(0.45)
			end
			eb:SetScript("OnEnterPressed", function(self)
				resolveMethod(opt, parentChain, "set", info, self:GetText())
				self:ClearFocus()
				onRefresh()
			end)
			eb:SetScript("OnEditFocusLost", function(self)
				local newText = self:GetText()
				if newText ~= tostring(curVal) then
					resolveMethod(opt, parentChain, "set", info, newText)
					onRefresh()
				end
			end)
			attachTooltip(eb, label, desc)
			y = y - 30
		elseif oType == "keybinding" then
			local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			lbl:SetJustifyH("LEFT")
			lbl:SetText(label)
			lbl:SetTextColor(0.92, 0.85, 0.55)
			if UIStyle then UIStyle.ApplyFont(lbl, -1) end
			y = y - (lbl:GetStringHeight() or 14) - 4

			local curVal = resolveMethod(opt, parentChain, "get", info) or ""
			local bindBtn = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
			bindBtn:SetSize(222, 24)
			bindBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(bindBtn, 0.08, 0.09, 0.13, 1, 0.35, 0.38, 0.45, 1)
			end
			local bfs = bindBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			bfs:SetAllPoints()
			bfs:SetJustifyH("CENTER")
			bindBtn._fs = bfs
			bindBtn._listening = false

			local function updateBindText()
				if bindBtn._listening then
					bfs:SetText("|cffffd100" .. (L["KEYBIND_PRESS"] or "Press key / mouse button...") .. "|r")
					if bindBtn.SetBackdropBorderColor then bindBtn:SetBackdropBorderColor(0.95, 0.80, 0.25, 1) end
				elseif curVal ~= "" then
					bfs:SetText("|cff40ff40" .. tostring(curVal) .. "|r")
					if bindBtn.SetBackdropBorderColor then bindBtn:SetBackdropBorderColor(0.35, 0.38, 0.45, 1) end
				else
					bfs:SetText("|cff888888" .. (L["KEYBIND_NONE"] or "Not Bound (Click to set)") .. "|r")
					if bindBtn.SetBackdropBorderColor then bindBtn:SetBackdropBorderColor(0.35, 0.38, 0.45, 1) end
				end
			end
			updateBindText()

			local function stopListening(saveKey)
				bindBtn._listening = false
				bindBtn:EnableKeyboard(false)
				bindBtn:EnableMouseWheel(false)
				if saveKey ~= nil then
					curVal = saveKey
					resolveMethod(opt, parentChain, "set", info, saveKey)
					onRefresh()
					return
				end
				updateBindText()
			end

			local function modPrefix()
				local p = ""
				if IsAltKeyDown and IsAltKeyDown() then p = p .. "ALT-" end
				if IsControlKeyDown and IsControlKeyDown() then p = p .. "CTRL-" end
				if IsShiftKeyDown and IsShiftKeyDown() then p = p .. "SHIFT-" end
				return p
			end

			bindBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			bindBtn:SetScript("OnClick", function(_, button)
				if disabled then return end
				if button == "RightButton" and not bindBtn._listening then
					stopListening("")
					return
				end
				bindBtn._listening = true
				bindBtn:EnableKeyboard(true)
				bindBtn:EnableMouseWheel(true)
				updateBindText()
			end)
			bindBtn:SetScript("OnMouseDown", function(_, button)
				if not bindBtn._listening then return end
				if button == "LeftButton" then return end
				if button == "RightButton" then
					stopListening(nil)
					return
				end
				local mapped = (button == "MiddleButton") and "BUTTON3" or string.upper(tostring(button))
				stopListening(modPrefix() .. mapped)
			end)
			bindBtn:SetScript("OnMouseWheel", function(_, delta)
				if not bindBtn._listening then return end
				stopListening(modPrefix() .. (delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"))
			end)
			bindBtn:SetScript("OnKeyDown", function(_, key)
				if not bindBtn._listening then return end
				if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
					return
				end
				if key == "ESCAPE" then
					stopListening(nil)
					return
				end
				stopListening(modPrefix() .. tostring(key))
			end)

			local clearBtn = UIStyle and UIStyle.CreateButton and UIStyle.CreateButton(parent, 24, 24, "x", "secondary")
				or CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
			clearBtn:SetPoint("LEFT", bindBtn, "RIGHT", 4, 0)
			clearBtn:SetScript("OnClick", function()
				if not disabled then
					stopListening("")
				end
			end)

			if disabled then
				bindBtn:Disable()
				bindBtn:SetAlpha(0.45)
				clearBtn:Disable()
			end
			attachTooltip(bindBtn, label, desc)
			y = y - 30
		elseif oType == "color" then
			local cr, cg, cb, ca = resolveMethod(opt, parentChain, "get", info)
			local row = CreateFrame("Button", nil, parent)
			row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			row:SetSize(contentWidth, 24)
			local swatch = CreateFrame("Frame", nil, row, BackdropTemplateMixin and "BackdropTemplate" or nil)
			swatch:SetSize(20, 20)
			swatch:SetPoint("LEFT", row, "LEFT", 0, 0)
			if UIStyle and UIStyle.ApplyBox then
				UIStyle.ApplyBox(swatch, cr or 1, cg or 1, cb or 1, ca or 1, 0.79, 0.64, 0.15, 1)
			end
			local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			lbl:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
			lbl:SetText(label)
			if UIStyle then UIStyle.ApplyFont(lbl, 0) end
			if disabled then
				row:Disable()
				row:SetAlpha(0.45)
			else
				row:SetScript("OnClick", function()
					openColorPicker(cr, cg, cb, ca, opt.hasAlpha, function(nr, ng, nb, na)
						resolveMethod(opt, parentChain, "set", info, nr, ng, nb, na)
						if swatch.SetBackdropColor then swatch:SetBackdropColor(nr, ng, nb, na) end
					end)
				end)
			end
			attachTooltip(row, label, desc)
			y = y - 28
		elseif oType == "group" then
			local childBox = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
			childBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
			childBox:SetWidth(contentWidth)
			if UIStyle then UIStyle.SkinInset(childBox) end

			local gTitle = childBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			gTitle:SetPoint("TOPLEFT", childBox, "TOPLEFT", 10, -8)
			gTitle:SetText(label)
			gTitle:SetTextColor(0.95, 0.80, 0.25)
			if UIStyle then UIStyle.ApplyFont(gTitle, 0) end

			local nextChain = {}
			for _, p in ipairs(parentChain) do table.insert(nextChain, p) end
			table.insert(nextChain, opt)

			local innerContainer = CreateFrame("Frame", nil, childBox)
			innerContainer:SetPoint("TOPLEFT", childBox, "TOPLEFT", 10, -28)
			innerContainer:SetWidth(contentWidth - 20)
			local endY = renderOptionGroup(innerContainer, opt, nextChain, item.path, 0, contentWidth - 20, onRefresh)
			local boxHeight = math.max(36, -endY + 38)
			innerContainer:SetHeight(math.max(1, -endY + 4))
			childBox:SetHeight(boxHeight)
			y = y - boxHeight - 10
		end
	end
	return y
end

function OptionsUI:Refresh()
	if not optionsFrame or not optionsFrame:IsShown() then return end
	local UIStyle = CraftForge.UIStyle
	local rootOpt = AceConfigRegistry:GetOptionsTable("CraftForgeGUI", "dialog", "CraftForgeOptions-1.0")
	if not rootOpt or not rootOpt.args then return end

	closeDropdownMenu()

	local topTabs = getSortedArgs(rootOpt.args, { rootOpt }, {})
	local activeEntry = nil
	for _, t in ipairs(topTabs) do
		if t.key == activeTabKey then
			activeEntry = t
			break
		end
	end
	if not activeEntry and topTabs[1] then
		activeEntry = topTabs[1]
		activeTabKey = activeEntry.key
	end

	-- Rebuild sidebar buttons
	for _, btn in ipairs(optionsFrame._sideButtons) do
		btn:Hide()
	end

	local sideY = -4
	local btnIdx = 0
	for _, tab in ipairs(topTabs) do
		btnIdx = btnIdx + 1
		local btn = optionsFrame._sideButtons[btnIdx]
		if not btn then
			if UIStyle and UIStyle.CreateButton then
				btn = UIStyle.CreateButton(optionsFrame._sideChild, 152, 26, tab.name, "secondary")
			else
				btn = CreateFrame("Button", nil, optionsFrame._sideChild, "UIPanelButtonTemplate")
				btn:SetSize(152, 26)
			end
			btn._fs = btn.GetFontString and btn:GetFontString()
			optionsFrame._sideButtons[btnIdx] = btn
		end
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", optionsFrame._sideChild, "TOPLEFT", 2, sideY)
		btn:SetText(tab.name)
		local isSelected = (tab.key == activeTabKey)
		if btn.SetBackdropColor then
			if isSelected then
				btn:SetBackdropColor(0.24, 0.20, 0.08, 1)
				btn:SetBackdropBorderColor(0.79, 0.64, 0.15, 1)
			else
				btn:SetBackdropColor(0.11, 0.13, 0.17, 1)
				btn:SetBackdropBorderColor(0.22, 0.25, 0.32, 1)
			end
		end
		if btn._fs then
			if isSelected then
				btn._fs:SetTextColor(1, 0.85, 0.3)
			else
				btn._fs:SetTextColor(0.82, 0.86, 0.92)
			end
		end
		btn:SetScript("OnClick", function()
			activeTabKey = tab.key
			activeSubKey = nil
			OptionsUI:Refresh()
		end)
		btn:Show()
		sideY = sideY - 30
	end
	optionsFrame._sideChild:SetHeight(math.max(100, -sideY + 10))

	-- Clear previous content children
	local oldChild = optionsFrame._scrollChild
	if oldChild then
		for _, child in ipairs({ oldChild:GetChildren() }) do child:Hide() end
		for _, region in ipairs({ oldChild:GetRegions() }) do region:Hide() end
	end
	local newChild = CreateFrame("Frame", nil, optionsFrame._scroll)
	newChild:SetSize(510, 1)
	optionsFrame._scroll:SetScrollChild(newChild)
	optionsFrame._scrollChild = newChild

	for _, sb in ipairs(optionsFrame._subTabButtons) do sb:Hide() end
	optionsFrame._subTabBar:Hide()
	optionsFrame._scroll:ClearAllPoints()
	optionsFrame._scroll:SetPoint("TOPLEFT", optionsFrame._subTabBar:GetParent(), "TOPLEFT", 12, -12)
	optionsFrame._scroll:SetPoint("BOTTOMRIGHT", optionsFrame._subTabBar:GetParent(), "BOTTOMRIGHT", -28, 12)

	if not activeEntry then return end

	local targetOpt = activeEntry.opt
	local parentChain = { rootOpt, targetOpt }
	local basePath = { activeEntry.key }

	-- Check if this tab has sub-groups (e.g. Plugins tab)
	local subGroups = {}
	if targetOpt.childGroups == "tab" or targetOpt.childGroups == "tree" then
		for _, sub in ipairs(getSortedArgs(targetOpt.args, parentChain, basePath)) do
			if sub.opt.type == "group" then
				table.insert(subGroups, sub)
			end
		end
	end

	if #subGroups > 0 then
		local activeSub = nil
		for _, sub in ipairs(subGroups) do
			if sub.key == activeSubKey then
				activeSub = sub
				break
			end
		end
		if not activeSub then
			activeSub = subGroups[1]
			activeSubKey = activeSub.key
		end

		optionsFrame._subTabBar:Show()
		optionsFrame._scroll:ClearAllPoints()
		optionsFrame._scroll:SetPoint("TOPLEFT", optionsFrame._subTabBar, "BOTTOMLEFT", 2, -8)
		optionsFrame._scroll:SetPoint("BOTTOMRIGHT", optionsFrame._subTabBar:GetParent(), "BOTTOMRIGHT", -28, 12)

		local maxBarW = optionsFrame._subTabBar:GetWidth()
		if not maxBarW or maxBarW < 100 then maxBarW = 540 end
		local sx, sy = 0, 0
		local rowStep = 26
		for idx, sub in ipairs(subGroups) do
			local sb = optionsFrame._subTabButtons[idx]
			local visName = sub.name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			local w = math.max(72, math.min(210, (string.len(visName) * 6.5) + 18))
			if sx > 0 and (sx + w) > maxBarW then
				sx = 0
				sy = sy - rowStep
			end
			if not sb then
				if UIStyle and UIStyle.CreateButton then
					sb = UIStyle.CreateButton(optionsFrame._subTabBar, w, 24, sub.name, "secondary")
				else
					sb = CreateFrame("Button", nil, optionsFrame._subTabBar, "UIPanelButtonTemplate")
					sb:SetSize(w, 24)
				end
				sb._fs = sb.GetFontString and sb:GetFontString()
				optionsFrame._subTabButtons[idx] = sb
			end
			sb:SetSize(w, 24)
			sb:ClearAllPoints()
			sb:SetPoint("TOPLEFT", optionsFrame._subTabBar, "TOPLEFT", sx, sy)
			sb:SetText(sub.name)
			local isSel = (sub.key == activeSubKey)
			if sb.SetBackdropColor then
				if isSel then
					sb:SetBackdropColor(0.24, 0.20, 0.08, 1)
					sb:SetBackdropBorderColor(0.79, 0.64, 0.15, 1)
				else
					sb:SetBackdropColor(0.11, 0.13, 0.17, 1)
					sb:SetBackdropBorderColor(0.22, 0.25, 0.32, 1)
				end
			end
			if sb._fs then
				sb._fs:SetTextColor(isSel and 1 or 0.80, isSel and 0.85 or 0.84, isSel and 0.30 or 0.90)
			end
			sb:SetScript("OnClick", function()
				activeSubKey = sub.key
				OptionsUI:Refresh()
			end)
			sb:Show()
			sx = sx + w + 4
		end
		optionsFrame._subTabBar:SetHeight(math.abs(sy) + 26)

		targetOpt = activeSub.opt
		table.insert(parentChain, targetOpt)
		table.insert(basePath, activeSub.key)
	end

	local width = math.max(460, (optionsFrame._scroll:GetWidth() or 510) - 8)
	newChild:SetWidth(width)
	local endY = renderOptionGroup(newChild, targetOpt, parentChain, basePath, -2, width, function()
		OptionsUI:Refresh()
	end)
	newChild:SetHeight(math.max(100, -endY + 16))
	optionsFrame._scroll:SetVerticalScroll(0)
end

function OptionsUI:Show(tabKey, subKey)
	local f = ensureOptionsFrame()
	if tabKey then activeTabKey = tabKey end
	if subKey then activeSubKey = subKey end
	f:Show()
	self:Refresh()
end
