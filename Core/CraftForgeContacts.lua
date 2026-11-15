----------------------------------------------------------
-- CraftForge - Trade Contacts (Vendors & Trainers DB) --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")

CraftForge.Contacts = CraftForge.Contacts or {}
local Contacts = CraftForge.Contacts

local RECIPE_CLASS_ID = (Enum and Enum.ItemClass and Enum.ItemClass.Recipe) or 9
local TRADEGOODS_CLASS_ID = (Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods) or 7

local function ensureDB()
	if not CraftForge.db then return nil end
	if not CraftForge.db.global.contactsDB then
		CraftForge.db.global.contactsDB = {
			vendors = {},
			trainers = {},
			itemVendors = {},
		}
	end
	local db = CraftForge.db.global.contactsDB
	db.vendors = db.vendors or {}
	db.trainers = db.trainers or {}
	db.itemVendors = db.itemVendors or {}
	return db
end

local function currentLocation()
	local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Unknown"
	local sub = (GetSubZoneText and GetSubZoneText()) or ""
	if sub == "" then sub = nil end
	local mapID, x, y
	if C_Map and C_Map.GetBestMapForUnit then
		mapID = C_Map.GetBestMapForUnit("player")
		if mapID and C_Map.GetPlayerMapPosition then
			local pos = C_Map.GetPlayerMapPosition(mapID, "player")
			if pos then
				local px, py = pos:GetXY()
				if px and py and (px > 0 or py > 0) then
					x = math.floor(px * 1000 + 0.5) / 10
					y = math.floor(py * 1000 + 0.5) / 10
				end
			end
		end
	end
	return zone, sub, mapID, x, y
end

local function getNpcID(unit)
	local guid = UnitGUID and UnitGUID(unit or "npc")
	if type(guid) ~= "string" then return nil end
	local _, _, _, _, _, npcID = strsplit("-", guid)
	return tonumber(npcID)
end

local function scanMerchant()
	local db = ensureDB()
	if not db or not GetMerchantNumItems then return end
	local npcName = UnitName and UnitName("npc")
	if not npcName or npcName == "" then return end
	local npcID = getNpcID("npc") or npcName
	local zone, sub, mapID, x, y = currentLocation()

	local relevantItems = {}
	local numItems = GetMerchantNumItems() or 0
	for i = 1, numItems do
		local link = GetMerchantItemLink and GetMerchantItemLink(i)
		local name, price, numAvailable
		if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
			local info = C_MerchantFrame.GetItemInfo(i)
			if info then
				name = info.name
				price = info.price
				numAvailable = info.numAvailable
			end
		elseif GetMerchantItemInfo then
			local _, _, p, _, na
			name, _, p, _, na = GetMerchantItemInfo(i)
			price = p
			numAvailable = na
		end
		if link then
			local itemID = tonumber(link:match("item:(%d+)"))
			if itemID then
				local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
				if getInstant then
					local _, _, _, _, _, classID = getInstant(itemID)
					if classID == RECIPE_CLASS_ID or classID == TRADEGOODS_CLASS_ID then
						relevantItems[itemID] = {
							id = itemID,
							name = name,
							price = price or 0,
							limited = (numAvailable and numAvailable >= 0) and numAvailable or nil,
						}
						db.itemVendors[itemID] = db.itemVendors[itemID] or {}
						db.itemVendors[itemID][npcID] = {
							npc = npcName,
							zone = zone,
							sub = sub,
							mapID = mapID,
							x = x,
							y = y,
							price = price or 0,
							limited = (numAvailable and numAvailable >= 0) and numAvailable or nil,
							seen = time(),
						}
					end
				end
			end
		end
	end

	if next(relevantItems) then
		db.vendors[npcID] = {
			name = npcName,
			zone = zone,
			sub = sub,
			mapID = mapID,
			x = x,
			y = y,
			items = relevantItems,
			seen = time(),
		}
	end
end

local function scanTrainer()
	local db = ensureDB()
	if not db or not GetNumTrainerServices then return end
	local npcName = UnitName and UnitName("npc")
	if not npcName or npcName == "" then return end
	local npcID = getNpcID("npc") or npcName
	local zone, sub, mapID, x, y = currentLocation()
	local profTitle = GetTrainerGreetingText and GetTrainerGreetingText()
	local num = GetNumTrainerServices() or 0
	if num <= 0 then return end

	db.trainers[npcID] = {
		name = npcName,
		zone = zone,
		sub = sub,
		mapID = mapID,
		x = x,
		y = y,
		greeting = profTitle,
		services = num,
		seen = time(),
	}
end

function Contacts:GetItemVendors(itemID)
	local db = ensureDB()
	if not db or not itemID then return nil end
	return db.itemVendors and db.itemVendors[itemID]
end

local function appendContactTooltip(tooltip, itemID)
	if not tooltip or not itemID then return end
	local vendors = Contacts:GetItemVendors(itemID)
	if not vendors or not next(vendors) then return end

	local shown = 0
	for _, v in pairs(vendors) do
		local coords = (v.x and v.y) and string.format(" (%.1f, %.1f)", v.x, v.y) or ""
		local priceStr = ""
		if v.price and v.price > 0 and CraftForge.FormatMoneyFull then
			priceStr = " - " .. CraftForge:FormatMoneyFull(v.price, true)
		end
		local limitStr = v.limited and (" |cffff9933[x" .. v.limited .. "]|r") or ""
		tooltip:AddLine(string.format("|cffd4a94eCraftForge Vendor:|r %s — %s%s%s%s",
			v.npc or "?", v.zone or "?", coords, priceStr, limitStr), 0.9, 0.9, 0.9, true)
		shown = shown + 1
		if shown >= 3 then break end
	end
end

function Contacts:Initialize()
	if self._initialized then return end
	self._initialized = true
	ensureDB()

	local f = CreateFrame("Frame")
	f:RegisterEvent("MERCHANT_SHOW")
	f:RegisterEvent("MERCHANT_UPDATE")
	f:RegisterEvent("TRAINER_SHOW")
	f:SetScript("OnEvent", function(_, event)
		if event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
			scanMerchant()
		elseif event == "TRAINER_SHOW" then
			scanTrainer()
		end
	end)

	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
			if tooltip ~= GameTooltip then return end
			local itemID = data and data.id
			if not itemID and tooltip.GetItem then
				local _, link = tooltip:GetItem()
				itemID = link and tonumber(link:match("item:(%d+)"))
			end
			if itemID then
				appendContactTooltip(tooltip, itemID)
			end
		end)
	elseif GameTooltip and GameTooltip.HookScript then
		GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
			local _, link = tooltip:GetItem()
			local itemID = link and tonumber(link:match("item:(%d+)"))
			if itemID then
				appendContactTooltip(tooltip, itemID)
			end
		end)
	end
end
