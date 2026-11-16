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

	local recipes = {}
	for i = 1, num do
		local sName, sRank, sCat
		if GetTrainerServiceInfo then
			sName, sRank, sCat = GetTrainerServiceInfo(i)
		end
		if sName and sCat ~= "header" then
			local cost = GetTrainerServiceCost and GetTrainerServiceCost(i) or 0
			table.insert(recipes, {
				name = sName,
				rank = sRank,
				category = sCat,
				price = cost,
			})
		end
	end

	db.trainers[npcID] = {
		name = npcName,
		zone = zone,
		sub = sub,
		mapID = mapID,
		x = x,
		y = y,
		greeting = profTitle,
		services = num,
		recipes = recipes,
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

function Contacts:GetAllEntries(kindFilter, query)
	local db = ensureDB()
	if not db then return {} end
	local HBD = LibStub and LibStub("HereBeDragons-2.0", true)
	local px, py, pMap
	if HBD and HBD.GetPlayerZonePosition then
		px, py, pMap = HBD:GetPlayerZonePosition()
	end
	local list = {}
	local q = query and query ~= "" and string.lower(query) or nil
	local function addBucket(bucket, kind)
		for id, rec in pairs(bucket or {}) do
			if type(rec) == "table" then
				local match = true
				if q then
					local hay = string.lower((rec.name or "") .. " " .. (rec.zone or "") .. " " .. (rec.subzone or "") .. " " .. (rec.skill or ""))
					match = string.find(hay, q, 1, true) ~= nil
					if not match and rec.items then
						for _, it in pairs(rec.items) do
							if it.name and string.find(string.lower(it.name), q, 1, true) then
								match = true
								break
							end
						end
					end
					if not match and rec.recipes then
						for _, r in ipairs(rec.recipes) do
							if r.name and string.find(string.lower(r.name), q, 1, true) then
								match = true
								break
							end
						end
					end
				end
				if match then
					local dist
					if HBD and HBD.GetZoneDistance and px and py and pMap and rec.mapID and rec.x and rec.y then
						dist = HBD:GetZoneDistance(pMap, px, py, rec.mapID, rec.x / 100, rec.y / 100)
					end
					table.insert(list, {
						id = id,
						kind = kind,
						name = rec.name or "?",
						zone = rec.zone or "?",
						subzone = rec.subzone,
						mapID = rec.mapID,
						x = rec.x,
						y = rec.y,
						distance = dist,
						skill = rec.skill,
						items = rec.items,
						recipes = rec.recipes,
						seen = rec.seen or 0,
					})
				end
			end
		end
	end
	if not kindFilter or kindFilter == "all" or kindFilter == "vendors" then
		addBucket(db.vendors, "vendor")
	end
	if not kindFilter or kindFilter == "all" or kindFilter == "trainers" then
		addBucket(db.trainers, "trainer")
	end
	table.sort(list, function(a, b)
		if a.distance and b.distance and a.distance ~= b.distance then
			return a.distance < b.distance
		elseif (a.distance ~= nil) ~= (b.distance ~= nil) then
			return a.distance ~= nil
		end
		if (a.seen or 0) ~= (b.seen or 0) then
			return (a.seen or 0) > (b.seen or 0)
		end
		return (a.name or "") < (b.name or "")
	end)
	return list
end

function Contacts:SetWaypoint(rec)
	if not rec or not rec.mapID or not rec.x or not rec.y then
		CraftForge:Print(CraftForge.L["CONTACTS_NO_COORDS"] or "No coordinates recorded for this contact.")
		return
	end
	if _G.TomTom and _G.TomTom.AddWaypoint then
		_G.TomTom:AddWaypoint(rec.mapID, rec.x / 100, rec.y / 100, {
			title = rec.name .. " (" .. (rec.zone or "?") .. ")",
			persistent = false,
			minimap = true,
			world = true,
		})
		CraftForge:Print(string.format(CraftForge.L["CONTACTS_WAYPOINT_SET"] or "TomTom waypoint set: %s (%.1f, %.1f)", rec.name, rec.x, rec.y))
	elseif C_Map and C_Map.SetUserWaypoint and UiMapPoint then
		local point = UiMapPoint.CreateFromCoordinates(rec.mapID, rec.x / 100, rec.y / 100)
		C_Map.SetUserWaypoint(point)
		CraftForge:Print(string.format(CraftForge.L["CONTACTS_WAYPOINT_SET"] or "Waypoint set: %s (%.1f, %.1f)", rec.name, rec.x, rec.y))
	else
		CraftForge:Print(string.format("%s — %s (%.1f, %.1f)", rec.name, rec.zone or "?", rec.x, rec.y))
	end
end
