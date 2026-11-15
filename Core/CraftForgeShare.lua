----------------------------------------------------------
-- CraftForge - Ace3 Modules (Share, Minimap, Tab, GUI) --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = LibStub("AceAddon-3.0"):GetAddon("CraftForge")
local L = LibStub("AceLocale-3.0"):GetLocale("CraftForge")

local Share = CraftForge:NewModule("Share", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0")
CraftForge.Share = Share

local COMM_PREFIX = "CraftForgeQ"
local EXPORT_PREFIX = "!CFQ1!"

local pendingCommQueue = nil
local pendingCommSender = nil

StaticPopupDialogs["CRAFTFORGE_ACCEPT_QUEUE"] = {
	text = L["SHARE_ACCEPT_QUEUE_FMT"] or "CraftForge: %s sent you a crafting queue (%d items). Import into your queue?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		if pendingCommQueue then
			Share:ApplyQueueTable(pendingCommQueue)
			CraftForge:Print(string.format(L["SHARE_IMPORTED_FMT"] or "Imported queue from %s.", tostring(pendingCommSender or "player")))
		end
		pendingCommQueue = nil
		pendingCommSender = nil
	end,
	OnCancel = function()
		pendingCommQueue = nil
		pendingCommSender = nil
	end,
	timeout = 30,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function Share:OnInitialize()
	self:RegisterComm(COMM_PREFIX, "OnCommReceived")
	self:SetupStandaloneOptions()
	self:SetupMinimapIcon()
	self:SetupTabCompletion()
end

function Share:SetupStandaloneOptions()
	local acedia = LibStub("AceConfigDialog-3.0", true)
	if acedia and acedia.SetDefaultSize then
		acedia:SetDefaultSize("CraftForgeGUI", 740, 560)
	end
end

function Share:OpenOptions()
	if CraftForge.ShowOptions then
		CraftForge:ShowOptions()
		return
	end
	local acedia = LibStub("AceConfigDialog-3.0", true)
	if acedia then
		acedia:Open("CraftForgeGUI")
	end
end

function Share:SetupMinimapIcon()
	local LDB = LibStub("LibDataBroker-1.1", true)
	local LDBIcon = LibStub("LibDBIcon-1.0", true)
	if not LDB or not LDBIcon then return end

	if not CraftForge.db.profile.minimap then
		CraftForge.db.profile.minimap = { hide = false }
	end

	local dataObj = LDB:NewDataObject("CraftForge", {
		type = "data source",
		label = "CraftForge",
		text = "CraftForge",
		icon = "Interface\\Icons\\Trade_Engineering",
		OnClick = function(_, button)
			if button == "RightButton" then
				Share:OpenOptions()
			elseif button == "MiddleButton" then
				if CraftForge.ShowFishing then
					CraftForge:ShowFishing()
				end
			elseif IsShiftKeyDown() then
				if CraftForge.DisplayShoppingList then
					CraftForge:DisplayShoppingList(true)
				end
			else
				if CraftForge.ShowStandaloneQueue then
					if CraftForge.craftforgeStandaloneQueue and CraftForge.craftforgeStandaloneQueue:IsVisible() then
						CraftForge.craftforgeStandaloneQueue:Hide()
					else
						CraftForge:ShowStandaloneQueue()
					end
				end
			end
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine("|cffffd100CraftForge|r " .. tostring(CraftForge.version or ""))
			local queue = CraftForge.db and CraftForge.db.realm and CraftForge.db.realm.queueData and CraftForge.db.realm.queueData[CraftForge.currentPlayer]
			local count = queue and #queue or 0
			tooltip:AddLine(string.format("%s: %d", L["Queue"], count), 0.85, 0.90, 0.96)
			tooltip:AddLine(" ")
			tooltip:AddLine(L["|cff00ff00Left-Click:|r Toggle Queue Window"], 0.9, 0.9, 0.9)
			tooltip:AddLine(L["|cff00ff00Shift-Left-Click:|r Toggle Shopping List"], 0.9, 0.9, 0.9)
			tooltip:AddLine(L["|cff00ff00Middle-Click:|r Open Fishing Tracker"] or "|cff00ff00Middle-Click:|r Open Fishing Tracker", 0.9, 0.9, 0.9)
			tooltip:AddLine(L["|cff00ff00Right-Click:|r Open Options"], 0.9, 0.9, 0.9)
		end,
	})

	self.ldb = dataObj
	LDBIcon:Register("CraftForge", dataObj, CraftForge.db.profile.minimap)
	self:UpdateLDBText()
end

function Share:UpdateLDBText()
	if not self.ldb then return end
	local queue = CraftForge.db and CraftForge.db.realm and CraftForge.db.realm.queueData and CraftForge.db.realm.queueData[CraftForge.currentPlayer]
	local count = queue and #queue or 0
	if count > 0 then
		self.ldb.text = string.format("CraftForge (%d)", count)
	else
		self.ldb.text = "CraftForge"
	end
end

function Share:ToggleMinimapIcon(show)
	local LDBIcon = LibStub("LibDBIcon-1.0", true)
	if not LDBIcon then return end
	if not CraftForge.db.profile.minimap then
		CraftForge.db.profile.minimap = { hide = false }
	end
	if show == nil then
		CraftForge.db.profile.minimap.hide = not CraftForge.db.profile.minimap.hide
	else
		CraftForge.db.profile.minimap.hide = not show
	end
	if CraftForge.db.profile.minimap.hide then
		LDBIcon:Hide("CraftForge")
	else
		LDBIcon:Show("CraftForge")
	end
end

function Share:SetupTabCompletion()
	local AceTab = LibStub("AceTab-3.0", true)
	if not AceTab or AceTab:IsTabCompletionRegistered("CraftForgeSlash") then return end

	local baseCmds = {
		"config", "options", "standby", "shopping", "queue", "export", "import", "sendqueue", "minimap", "prof", "version", "find", "process", "fish",
	}

	AceTab:RegisterTabCompletion("CraftForgeSlash", { "/craftforge ", "/cf " }, function(t, text, pos)
		for _, cmd in ipairs(baseCmds) do
			table.insert(t, cmd)
		end
		local savedQueues = CraftForge.db and CraftForge.db.profile and CraftForge.db.profile.SavedQueues
		if type(savedQueues) == "table" then
			for qName in pairs(savedQueues) do
				table.insert(t, qName)
			end
		end
	end)
end

function Share:ExportQueueString()
	local queue = CraftForge.db and CraftForge.db.realm and CraftForge.db.realm.queueData and CraftForge.db.realm.queueData[CraftForge.currentPlayer]
	if not queue or #queue == 0 then
		return nil, "Queue is empty."
	end
	local payload = {
		v = 1,
		p = CraftForge.currentPlayer,
		q = queue,
	}
	local serialized = self:Serialize(payload)
	local LibDeflate = LibStub("LibDeflate", true)
	if LibDeflate then
		local compressed = LibDeflate:CompressDeflate(serialized)
		return EXPORT_PREFIX .. LibDeflate:EncodeForPrint(compressed)
	end
	return EXPORT_PREFIX .. serialized
end

function Share:ApplyQueueTable(queue)
	if type(queue) ~= "table" then return false end
	if not CraftForge.db.realm.queueData then
		CraftForge.db.realm.queueData = {}
	end
	local dest = CraftForge.db.realm.queueData[CraftForge.currentPlayer]
	if type(dest) ~= "table" then
		dest = {}
		CraftForge.db.realm.queueData[CraftForge.currentPlayer] = dest
	end
	for _, entry in ipairs(queue) do
		if type(entry) == "table" and entry.op and entry.numcasts then
			table.insert(dest, entry)
		end
	end
	if CraftForge.UpdateQueueWindow then
		CraftForge:UpdateQueueWindow()
	end
	if CraftForge.UpdateTradeSkillWindow then
		CraftForge:UpdateTradeSkillWindow()
	end
	return true
end

function Share:ImportQueueString(encoded)
	if type(encoded) ~= "string" or encoded == "" then
		return false, "Empty import string."
	end
	encoded = encoded:match("^%s*(.-)%s*$")
	if encoded:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
		return false, "Invalid CraftForge queue string."
	end
	local body = encoded:sub(#EXPORT_PREFIX + 1)
	local serialized = body
	local LibDeflate = LibStub("LibDeflate", true)
	if LibDeflate then
		local decoded = LibDeflate:DecodeForPrint(body)
		if decoded then
			local decompressed = LibDeflate:DecompressDeflate(decoded)
			if decompressed then
				serialized = decompressed
			end
		end
	end
	local ok, payload = self:Deserialize(serialized)
	if not ok or type(payload) ~= "table" or type(payload.q) ~= "table" then
		return false, "Failed to decode CraftForge queue."
	end
	self:ApplyQueueTable(payload.q)
	return true, #payload.q
end

function Share:SendQueue(distribution, target)
	local encoded, err = self:ExportQueueString()
	if not encoded then
		CraftForge:Print(err or "Nothing to send.")
		return false
	end
	local dist = (distribution and distribution ~= "" and string.upper(distribution)) or (IsInGroup() and "PARTY" or (IsInGuild() and "GUILD" or nil))
	if not dist then
		CraftForge:Print("Not in a guild or group. Specify WHISPER <player>.")
		return false
	end
	self:SendCommMessage(COMM_PREFIX, encoded, dist, target)
	CraftForge:Print(string.format("Sent queue via %s%s.", dist, target and (" to " .. target) or ""))
	return true
end

function Share:OnCommReceived(prefix, message, distribution, sender)
	if prefix ~= COMM_PREFIX then return end
	local myName = UnitName("player")
	if sender and myName and (sender == myName or sender:match("^" .. myName .. "%-")) then
		return
	end
	if type(message) ~= "string" or message:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
		return
	end
	local body = message:sub(#EXPORT_PREFIX + 1)
	local serialized = body
	local LibDeflate = LibStub("LibDeflate", true)
	if LibDeflate then
		local decoded = LibDeflate:DecodeForPrint(body)
		if decoded then
			local decompressed = LibDeflate:DecompressDeflate(decoded)
			if decompressed then
				serialized = decompressed
			end
		end
	end
	local ok, payload = self:Deserialize(serialized)
	if not ok or type(payload) ~= "table" or type(payload.q) ~= "table" or #payload.q == 0 then
		return
	end
	pendingCommQueue = payload.q
	pendingCommSender = sender
	StaticPopup_Show("CRAFTFORGE_ACCEPT_QUEUE", sender or "Unknown", #payload.q)
end

function Share:ShowExportDialog()
	local AceGUI = LibStub("AceGUI-3.0", true)
	if not AceGUI then return end
	local encoded, err = self:ExportQueueString()
	if not encoded then
		CraftForge:Print(err or "Queue is empty.")
		return
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("CraftForge - " .. L["Export Queue"])
	frame:SetStatusText(L["Copy this string (Ctrl+C)"])
	frame:SetLayout("Fill")
	frame:SetWidth(520)
	frame:SetHeight(280)
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

	local editbox = AceGUI:Create("MultiLineEditBox")
	editbox:SetLabel(L["Queue String"])
	editbox:SetText(encoded)
	editbox:DisableButton(true)
	editbox:SetFocus()
	editbox:HighlightText()
	frame:AddChild(editbox)
end

function Share:ShowImportDialog()
	local AceGUI = LibStub("AceGUI-3.0", true)
	if not AceGUI then return end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("CraftForge - " .. L["Import Queue"])
	frame:SetStatusText(L["Paste a CraftForge queue string"])
	frame:SetLayout("Flow")
	frame:SetWidth(520)
	frame:SetHeight(300)
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

	local editbox = AceGUI:Create("MultiLineEditBox")
	editbox:SetLabel(L["Queue String"])
	editbox:SetFullWidth(true)
	editbox:SetNumLines(10)
	editbox:DisableButton(true)
	frame:AddChild(editbox)

	local btn = AceGUI:Create("Button")
	btn:SetText("Import")
	btn:SetWidth(140)
	btn:SetCallback("OnClick", function()
		local ok, res = Share:ImportQueueString(editbox:GetText())
		if ok then
			CraftForge:Print(string.format("Imported %d queue entries.", tonumber(res) or 0))
			frame:Hide()
		else
			frame:SetStatusText("|cffff4040" .. tostring(res) .. "|r")
		end
	end)
	frame:AddChild(btn)
end
