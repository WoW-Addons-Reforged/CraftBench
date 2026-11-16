----------------------------------------------------------
-- CraftBench - Ace3 Modules (Share, Minimap, Tab, GUI) --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = LibStub("AceAddon-3.0"):GetAddon("CraftBench")
local L = LibStub("AceLocale-3.0"):GetLocale("CraftBench")

local Share = CraftBench:NewModule("Share", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0")
CraftBench.Share = Share

local COMM_PREFIX = "CraftBenchQ"
local EXPORT_PREFIX = "!CFQ1!"

local pendingCommQueue = nil
local pendingCommSender = nil

StaticPopupDialogs["CRAFTBENCH_ACCEPT_QUEUE"] = {
	text = L["SHARE_ACCEPT_QUEUE_FMT"] or "CraftBench: %s sent you a crafting queue (%d items). Import into your queue?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		if pendingCommQueue then
			Share:ApplyQueueTable(pendingCommQueue)
			CraftBench:Print(string.format(L["SHARE_IMPORTED_FMT"] or "Imported queue from %s.", tostring(pendingCommSender or "player")))
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
		acedia:SetDefaultSize("CraftBenchGUI", 740, 560)
	end
end

function Share:OpenOptions()
	if CraftBench.ShowOptions then
		CraftBench:ShowOptions()
		return
	end
	local acedia = LibStub("AceConfigDialog-3.0", true)
	if acedia then
		acedia:Open("CraftBenchGUI")
	end
end

function Share:SetupMinimapIcon()
	local LDB = LibStub("LibDataBroker-1.1", true)
	local LDBIcon = LibStub("LibDBIcon-1.0", true)
	if not LDB or not LDBIcon then return end

	if not CraftBench.db.profile.minimap then
		CraftBench.db.profile.minimap = { hide = false }
	end

	local dataObj = LDB:NewDataObject("CraftBench", {
		type = "data source",
		label = "CraftBench",
		text = "CraftBench",
		icon = "Interface\\Icons\\Trade_Engineering",
		OnClick = function(_, button)
			if button == "RightButton" then
				Share:OpenOptions()
			elseif button == "MiddleButton" then
				if CraftBench.ShowFishing then
					CraftBench:ShowFishing()
				end
			elseif IsShiftKeyDown() then
				if CraftBench.DisplayShoppingList then
					CraftBench:DisplayShoppingList(true)
				end
			else
				if not CraftBench.craftbenchStandaloneQueue and CraftBench.CreateTradeSkillWindow then
					CraftBench:CreateTradeSkillWindow()
				end
				if CraftBench.craftbenchStandaloneQueue and CraftBench.craftbenchStandaloneQueue:IsVisible() then
					CraftBench.craftbenchStandaloneQueue:Hide()
				elseif CraftBench.ShowQueueView and _G.CraftBenchStandaloneQueue then
					CraftBench:ShowQueueView()
				end
			end
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine("|cffffd100CraftBench|r " .. tostring(CraftBench.version or ""))
			local queue = CraftBench.db and CraftBench.db.realm and CraftBench.db.realm.queueData and CraftBench.db.realm.queueData[CraftBench.currentPlayer]
			local count = queue and #queue or 0
			tooltip:AddLine(string.format("%s: %d", L["Queue"], count), 0.85, 0.90, 0.96)
			if CraftBench.Cooldowns and CraftBench.Cooldowns.GetReadyCount then
				local readyCD = CraftBench.Cooldowns:GetReadyCount()
				if readyCD > 0 then
					tooltip:AddLine(string.format("|cff40ff40%s: %d|r", L["CD_READY_COUNT"] or "Ready Cooldowns", readyCD))
				end
			end
			tooltip:AddLine(" ")
			tooltip:AddLine(L["|cff00ff00Left-Click:|r Toggle Queue Window"], 0.9, 0.9, 0.9)
			tooltip:AddLine(L["|cff00ff00Shift-Left-Click:|r Toggle Shopping List"], 0.9, 0.9, 0.9)
			tooltip:AddLine(L["|cff00ff00Middle-Click:|r Open Fishing Tracker"] or "|cff00ff00Middle-Click:|r Open Fishing Tracker", 0.9, 0.9, 0.9)
			tooltip:AddLine(L["|cff00ff00Right-Click:|r Open Options"], 0.9, 0.9, 0.9)
		end,
	})

	self.ldb = dataObj
	LDBIcon:Register("CraftBench", dataObj, CraftBench.db.profile.minimap)
	self:UpdateLDBText()
end

function Share:UpdateLDBText()
	if not self.ldb then return end
	local queue = CraftBench.db and CraftBench.db.realm and CraftBench.db.realm.queueData and CraftBench.db.realm.queueData[CraftBench.currentPlayer]
	local count = queue and #queue or 0
	if count > 0 then
		self.ldb.text = string.format("CraftBench (%d)", count)
	else
		self.ldb.text = "CraftBench"
	end
end

function Share:ToggleMinimapIcon(show)
	local LDBIcon = LibStub("LibDBIcon-1.0", true)
	if not LDBIcon then return end
	if not CraftBench.db.profile.minimap then
		CraftBench.db.profile.minimap = { hide = false }
	end
	if show == nil then
		CraftBench.db.profile.minimap.hide = not CraftBench.db.profile.minimap.hide
	else
		CraftBench.db.profile.minimap.hide = not show
	end
	if CraftBench.db.profile.minimap.hide then
		LDBIcon:Hide("CraftBench")
	else
		LDBIcon:Show("CraftBench")
	end
end

function Share:SetupTabCompletion()
	local AceTab = LibStub("AceTab-3.0", true)
	if not AceTab or AceTab:IsTabCompletionRegistered("CraftBenchSlash") then return end

	local baseCmds = {
		"config", "options", "standby", "shopping", "queue", "export", "import", "sendqueue", "minimap", "prof", "version", "find", "process", "fish", "cd", "watch", "level", "gather", "contacts", "camp",
	}

	AceTab:RegisterTabCompletion("CraftBenchSlash", { "/craftbench ", "/cb " }, function(t, text, pos)
		for _, cmd in ipairs(baseCmds) do
			table.insert(t, cmd)
		end
		local savedQueues = CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.SavedQueues
		if type(savedQueues) == "table" then
			for qName in pairs(savedQueues) do
				table.insert(t, qName)
			end
		end
	end)
end

function Share:ExportQueueString()
	local queue = CraftBench.db and CraftBench.db.realm and CraftBench.db.realm.queueData and CraftBench.db.realm.queueData[CraftBench.currentPlayer]
	if not queue or #queue == 0 then
		return nil, "Queue is empty."
	end
	local payload = {
		v = 1,
		p = CraftBench.currentPlayer,
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
	if not CraftBench.db.realm.queueData then
		CraftBench.db.realm.queueData = {}
	end
	local dest = CraftBench.db.realm.queueData[CraftBench.currentPlayer]
	if type(dest) ~= "table" then
		dest = {}
		CraftBench.db.realm.queueData[CraftBench.currentPlayer] = dest
	end
	for _, entry in ipairs(queue) do
		if type(entry) == "table" and entry.op and entry.numcasts then
			table.insert(dest, entry)
		end
	end
	if CraftBench.UpdateQueueWindow then
		CraftBench:UpdateQueueWindow()
	end
	if CraftBench.UpdateTradeSkillWindow then
		CraftBench:UpdateTradeSkillWindow()
	end
	return true
end

function Share:ImportQueueString(encoded)
	if type(encoded) ~= "string" or encoded == "" then
		return false, "Empty import string."
	end
	encoded = encoded:match("^%s*(.-)%s*$")
	if encoded:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
		return false, "Invalid CraftBench queue string."
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
		return false, "Failed to decode CraftBench queue."
	end
	self:ApplyQueueTable(payload.q)
	return true, #payload.q
end

function Share:SendQueue(distribution, target)
	local encoded, err = self:ExportQueueString()
	if not encoded then
		CraftBench:Print(err or "Nothing to send.")
		return false
	end
	local dist = (distribution and distribution ~= "" and string.upper(distribution)) or (IsInGroup() and "PARTY" or (IsInGuild() and "GUILD" or nil))
	if not dist then
		CraftBench:Print("Not in a guild or group. Specify WHISPER <player>.")
		return false
	end
	self:SendCommMessage(COMM_PREFIX, encoded, dist, target)
	CraftBench:Print(string.format("Sent queue via %s%s.", dist, target and (" to " .. target) or ""))
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
	StaticPopup_Show("CRAFTBENCH_ACCEPT_QUEUE", sender or "Unknown", #payload.q)
end

function Share:ShowExportDialog()
	local AceGUI = LibStub("AceGUI-3.0", true)
	if not AceGUI then return end
	local encoded, err = self:ExportQueueString()
	if not encoded then
		CraftBench:Print(err or "Queue is empty.")
		return
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("CraftBench - " .. L["Export Queue"])
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
	frame:SetTitle("CraftBench - " .. L["Import Queue"])
	frame:SetStatusText(L["Paste a CraftBench queue string"])
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
			CraftBench:Print(string.format("Imported %d queue entries.", tonumber(res) or 0))
			frame:Hide()
		else
			frame:SetStatusText("|cffff4040" .. tostring(res) .. "|r")
		end
	end)
	frame:AddChild(btn)
end
