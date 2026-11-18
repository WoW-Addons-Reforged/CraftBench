----------------------------------------------------------
-- CraftBench - Fishing Logger, Auto-Lure & Pole Swap   --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")

CraftBench.Fishing = CraftBench.Fishing or {}
local Fishing = CraftBench.Fishing

local LAST_BAG = NUM_TOTAL_EQUIPPED_BAG_SLOTS or 5
local LURE_MIN_LEFT = 5
local FISHING_SPELLS = {
	[7620] = true, [7731] = true, [7732] = true, [18248] = true, [33095] = true,
	[51294] = true, [88868] = true, [110410] = true, [131474] = true,
}

local KNOWN_LURES = {
	[6529] = { bonus = 25, req = 0 },     -- Shiny Bauble
	[6530] = { bonus = 50, req = 50 },    -- Nightcrawlers
	[6811] = { bonus = 50, req = 50 },    -- Aquadynamic Fish Lens
	[6532] = { bonus = 75, req = 100 },   -- Bright Baubles
	[7307] = { bonus = 75, req = 100 },   -- Flesh Eating Worm
	[6533] = { bonus = 100, req = 100 },  -- Aquadynamic Fish Attractor
	[34861] = { bonus = 100, req = 100 }, -- Sharpened Fish Hook
	[46006] = { bonus = 100, req = 100 }, -- Glow Worm
	[62673] = { bonus = 100, req = 100 }, -- Feathered Lure
	[68049] = { bonus = 150, req = 1 },   -- Heat-Treated Spinning Lure
	[118391] = { bonus = 200, req = 1 },  -- Worm Supreme
}

BINDING_HEADER_CRAFTBENCH_FISHING = "CraftBench: Fishing"
_G["BINDING_NAME_CLICK CraftBenchFishingCastButton:LeftButton"] = "CraftBench: Cast Fishing / Apply Lure"
_G["BINDING_NAME_CLICK CraftBenchFishingSwapButton:LeftButton"] = "CraftBench: Swap Fishing Pole / Weapons"

local function getSpellNameSafe(id)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(id)
		return info and info.name
	elseif GetSpellInfo then
		return (GetSpellInfo(id))
	end
end

local FISHING_SPELL_NAME = getSpellNameSafe(131474) or getSpellNameSafe(7620) or "Fishing"

local function getNumSlots(bag)
	if C_Container and C_Container.GetContainerNumSlots then
		return C_Container.GetContainerNumSlots(bag) or 0
	elseif GetContainerNumSlots then
		return GetContainerNumSlots(bag) or 0
	end
	return 0
end

local function getContainerItem(bag, slot)
	if C_Container and C_Container.GetContainerItemInfo then
		local info = C_Container.GetContainerItemInfo(bag, slot)
		if info then
			return info.itemID, info.hyperlink, info.stackCount or 1, info.iconFileID
		end
	elseif GetContainerItemInfo then
		local tex, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(bag, slot)
		if itemID or link then
			itemID = itemID or (link and tonumber(link:match("item:(%d+)")))
			return itemID, link, count or 1, tex
		end
	end
	return nil, nil, 0, nil
end

local function getItemInfoSafe(idOrLink)
	if C_Item and C_Item.GetItemInfo then
		return C_Item.GetItemInfo(idOrLink)
	elseif GetItemInfo then
		return GetItemInfo(idOrLink)
	end
end

local function getItemInstantSafe(idOrLink)
	if C_Item and C_Item.GetItemInfoInstant then
		return C_Item.GetItemInfoInstant(idOrLink)
	elseif GetItemInfoInstant then
		return GetItemInfoInstant(idOrLink)
	end
end

local function ensureDB()
	if not CraftBench.db then return nil end
	if not CraftBench.db.global.fishingDB then
		CraftBench.db.global.fishingDB = {
			zones = {},
			settings = { autoLure = true, easyCast = true, showBar = true, verbose = false, castKey = "", swapKey = "" },
		}
	end
	local gdb = CraftBench.db.global.fishingDB
	gdb.zones = gdb.zones or {}
	gdb.settings = gdb.settings or { autoLure = true, easyCast = true, showBar = true, verbose = false, castKey = "", swapKey = "" }
	if not CraftBench.db.char.fishingWeapons then
		CraftBench.db.char.fishingWeapons = {}
	end
	return gdb
end

local session = {
	started = nil,
	catches = 0,
	ups = 0,
	value = 0,
	lastLootAt = -100,
	lastEntry = nil,
	lastEntryAt = -100,
}

function Fishing:GetDB()
	return ensureDB()
end

function Fishing:GetSession()
	return session
end

function Fishing:GetFishingSkill()
	if GetProfessions and GetProfessionInfo then
		local ok, _, _, _, fishIdx = pcall(GetProfessions)
		if ok and fishIdx then
			local name, _, rank, maxRank, _, _, _, mod = GetProfessionInfo(fishIdx)
			if rank then
				return rank, mod or 0, maxRank or 0, name
			end
		end
	end
	if GetNumSkillLines and GetSkillLineInfo then
		for i = 1, GetNumSkillLines() do
			local name, isHeader, _, rank, _, mod, maxRank = GetSkillLineInfo(i)
			if not isHeader and name and (name == FISHING_SPELL_NAME or name == "Fishing" or name == "Angeln") then
				return rank or 0, mod or 0, maxRank or 0, name
			end
		end
	end
	return nil, 0, 0, FISHING_SPELL_NAME
end

function Fishing:IsPoleEquipped()
	local mh = GetInventoryItemID and GetInventoryItemID("player", 16)
	if not mh then return false, nil end
	local _, _, _, _, _, classID, subClassID = getItemInstantSafe(mh)
	local fishingPoleSub = Enum and Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole or 20
	if classID == 2 and (subClassID == fishingPoleSub or subClassID == 20) then
		return true, mh
	end
	return false, mh
end

function Fishing:FindPoleInBags()
	local fishingPoleSub = Enum and Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole or 20
	for bag = 0, LAST_BAG do
		for slot = 1, getNumSlots(bag) do
			local itemID = getContainerItem(bag, slot)
			if itemID then
				local _, _, _, _, _, classID, subClassID = getItemInstantSafe(itemID)
				if classID == 2 and (subClassID == fishingPoleSub or subClassID == 20) then
					return bag, slot, itemID
				end
			end
		end
	end
	return nil, nil, nil
end

function Fishing:GetActiveLureInfo()
	if not GetWeaponEnchantInfo then return false, 0 end
	local hasMain, mainExp = GetWeaponEnchantInfo()
	if hasMain and mainExp and mainExp > 0 then
		return true, math.floor(mainExp / 1000)
	end
	return false, 0
end

function Fishing:FindBestLure()
	local skill = self:GetFishingSkill() or 0
	local bestBag, bestSlot, bestBonus, bestID = nil, nil, -1, nil
	for bag = 0, LAST_BAG do
		for slot = 1, getNumSlots(bag) do
			local itemID = getContainerItem(bag, slot)
			local lure = itemID and KNOWN_LURES[itemID]
			if lure and skill >= (lure.req or 0) and lure.bonus > bestBonus then
				bestBag, bestSlot, bestBonus, bestID = bag, slot, lure.bonus, itemID
			end
		end
	end
	return bestBag, bestSlot, bestBonus, bestID
end

local castButton, swapButton

function Fishing:ApplyCastAttributes(btn)
	if not btn or InCombatLockdown() then return end
	local gdb = ensureDB()
	local autoLure = gdb and gdb.settings and gdb.settings.autoLure ~= false
	local hasLure, secsLeft = Fishing:GetActiveLureInfo()
	if autoLure and (not hasLure or secsLeft < LURE_MIN_LEFT) and Fishing:IsPoleEquipped() then
		local bag, slot = Fishing:FindBestLure()
		if bag and slot then
			btn:SetAttribute("type", "macro")
			btn:SetAttribute("macrotext", string.format("/use %d %d\n/use 16", bag, slot))
			return
		end
	end
	btn:SetAttribute("type", "spell")
	btn:SetAttribute("spell", FISHING_SPELL_NAME)
end

local function updateCastButton()
	if InCombatLockdown() then return end
	if castButton then
		Fishing:ApplyCastAttributes(castButton)
	end
	if CraftBench.FishingUI and CraftBench.FishingUI._barCastBtn then
		Fishing:ApplyCastAttributes(CraftBench.FishingUI._barCastBtn)
	end
	if CraftBench.FishingUI and CraftBench.FishingUI.RefreshBar then
		CraftBench.FishingUI:RefreshBar()
	end
end

local function swapPoleAndWeapons()
	if InCombatLockdown() then return end
	ensureDB()
	local charWeapons = CraftBench.db.char.fishingWeapons
	local poleEquipped, currentMH = Fishing:IsPoleEquipped()
	local equipByID = (C_Item and C_Item.EquipItemByName) or EquipItemByName

	if not poleEquipped then
		local _, _, poleID = Fishing:FindPoleInBags()
		if not poleID then
			CraftBench:Print("No fishing pole found in your bags.")
			return
		end
		charWeapons.mh = currentMH
		charWeapons.oh = GetInventoryItemID and GetInventoryItemID("player", 17) or nil
		charWeapons.pole = poleID
		if equipByID then
			equipByID(poleID, 16)
		end
	else
		if charWeapons.mh and equipByID then
			equipByID(charWeapons.mh, 16)
		end
		if charWeapons.oh and equipByID then
			equipByID(charWeapons.oh, 17)
		end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0.25, updateCastButton)
	end
end

local function currentZoneRecord()
	local gdb = ensureDB()
	if not gdb then return nil end
	local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Unknown"
	local sub = (GetSubZoneText and GetSubZoneText()) or ""
	if sub == "" then sub = zone end
	local key = zone .. " :: " .. sub
	local rec = gdb.zones[key]
	if not rec then
		rec = {
			key = key,
			zone = zone,
			subzone = sub,
			mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil,
			casts = 0,
			catches = 0,
			escaped = 0,
			items = {},
		}
		gdb.zones[key] = rec
	end
	return rec
end

local function isNightTime()
	if GetGameTime then
		local hour = GetGameTime()
		if type(hour) == "number" then
			return hour >= 18 or hour < 6
		end
	end
	return false
end

local function recordCaughtItem(rec, itemID, link, count, isNewCatch)
	if not rec or not itemID then return end
	local name, itemLink, quality, _, _, _, _, _, _, _, vendorPrice = getItemInfoSafe(link or itemID)
	local it = rec.items[itemID]
	if not it then
		it = {
			id = itemID,
			name = name or ("Item #" .. itemID),
			link = itemLink or link,
			quality = quality or 1,
			count = 0,
			hauls = 0,
			minSkill = nil,
			day = 0,
			night = 0,
		}
		rec.items[itemID] = it
	else
		if name then it.name = name end
		if itemLink or link then it.link = itemLink or link end
		if quality then it.quality = quality end
	end

	local qty = tonumber(count) or 1
	it.count = (it.count or 0) + qty
	it.hauls = (it.hauls or 0) + 1
	local skill = Fishing:GetFishingSkill()
	if skill and (not it.minSkill or skill < it.minSkill) then
		it.minSkill = skill
	end
	if isNightTime() then
		it.night = (it.night or 0) + qty
	else
		it.day = (it.day or 0) + qty
	end

	session.started = session.started or GetTime()
	if isNewCatch then
		session.catches = session.catches + 1
	end
	local unitVal = 0
	if CraftBench.GetItemMarketOrVendorPrice then
		unitVal = CraftBench:GetItemMarketOrVendorPrice(itemID) or 0
	elseif vendorPrice then
		unitVal = vendorPrice
	end
	session.value = session.value + (unitVal * qty)
	session.lastEntry = it
	session.lastEntryAt = GetTime()

	local gdb = ensureDB()
	if gdb and gdb.settings and gdb.settings.verbose == true then
		CraftBench:Print(string.format("%s x%d (%s)", it.link or it.name, qty, rec.subzone or rec.zone or "?"))
	end

	if CraftBench.FishingUI and CraftBench.FishingUI.Refresh then
		CraftBench.FishingUI:Refresh()
	end
end

local function logFishingLoot()
	local rec = currentZoneRecord()
	if not rec then return end
	session.lastLootAt = GetTime()
	rec.catches = (rec.catches or 0) + 1

	local num = GetNumLootItems and GetNumLootItems() or 0
	local first = true
	for slot = 1, num do
		local link = GetLootSlotLink and GetLootSlotLink(slot)
		local _, _, qty = GetLootSlotInfo(slot)
		if link then
			local itemID = tonumber(link:match("item:(%d+)"))
			if itemID then
				recordCaughtItem(rec, itemID, link, qty or 1, first)
				first = false
			end
		end
	end
end

function Fishing:GetDerbyStatus()
	local now = time()
	local d = date("*t", now)
	-- Sunday = 1 in Lua date("*t").wday, Stranglethorn Fishing Extravaganza = Sunday 14:00-16:00
	local daysUntilSun = (1 - (d.wday or 1)) % 7
	local todayStart = time({ year = d.year, month = d.month, day = d.day, hour = 14, min = 0, sec = 0 })
	local startTs = todayStart + daysUntilSun * 86400
	if startTs + 7200 <= now then
		startTs = startTs + 7 * 86400
	end
	local stopTs = startTs + 7200
	if now >= startTs and now < stopTs then
		return "live", stopTs - now
	end
	local left = startTs - now
	return (left <= 3600) and "soon" or "later", left
end

local castBindOwner, swapBindOwner, easyBindOwner

function Fishing:ApplyKeyBindings()
	if InCombatLockdown() then return end
	local gdb = ensureDB()
	local s = gdb and gdb.settings or {}
	if ClearOverrideBindings then
		if castBindOwner then ClearOverrideBindings(castBindOwner) end
		if swapBindOwner then ClearOverrideBindings(swapBindOwner) end
	end
	if SetOverrideBindingClick then
		local ck = s.castKey and s.castKey:match("^%s*(.-)%s*$") or ""
		if ck ~= "" and castBindOwner then
			SetOverrideBindingClick(castBindOwner, true, ck:upper(), "CraftBenchFishingCastButton", "LeftButton")
		end
		local sk = s.swapKey and s.swapKey:match("^%s*(.-)%s*$") or ""
		if sk ~= "" and swapBindOwner then
			SetOverrideBindingClick(swapBindOwner, true, sk:upper(), "CraftBenchFishingSwapButton", "LeftButton")
		end
	end
end

function Fishing:Initialize()
	if self._initialized then return end
	self._initialized = true
	ensureDB()

	castBindOwner = CreateFrame("Frame")
	swapBindOwner = CreateFrame("Frame")
	easyBindOwner = CreateFrame("Frame")

	local useDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
	castButton = CreateFrame("Button", "CraftBenchFishingCastButton", UIParent, "SecureActionButtonTemplate")
	castButton:RegisterForClicks(useDown and "LeftButtonDown" or "LeftButtonUp")
	castButton:HookScript("PostClick", function()
		if ClearOverrideBindings and easyBindOwner and not InCombatLockdown() then
			ClearOverrideBindings(easyBindOwner)
		end
		if C_Timer and C_Timer.After then
			C_Timer.After(0.2, updateCastButton)
		end
	end)

	swapButton = CreateFrame("Button", "CraftBenchFishingSwapButton", UIParent)
	swapButton:SetScript("OnClick", swapPoleAndWeapons)

	-- Double-right-click on WorldFrame when holding a Fishing Pole -> Easy-Cast
	local lastRightClick = 0
	if WorldFrame and WorldFrame.HookScript then
		WorldFrame:HookScript("OnMouseDown", function(_, button)
			if button ~= "RightButton" then return end
			if InCombatLockdown() then return end
			local gdb = ensureDB()
			if gdb and gdb.settings and gdb.settings.easyCast == false then return end
			if not Fishing:IsPoleEquipped() then return end
			if LootFrame and LootFrame:IsShown() then return end
			if UnitExists and UnitExists("mouseover") then return end

			local now = GetTime()
			if (now - lastRightClick) <= 0.45 then
				lastRightClick = 0
				if SetOverrideBindingClick then
					SetOverrideBindingClick(easyBindOwner, true, "BUTTON2", "CraftBenchFishingCastButton", "LeftButton")
					if C_Timer and C_Timer.After then
						C_Timer.After(0.25, function()
							if ClearOverrideBindings and not InCombatLockdown() then
								ClearOverrideBindings(easyBindOwner)
							end
						end)
					end
				end
			else
				lastRightClick = now
			end
		end)
	end

	updateCastButton()
	self:ApplyKeyBindings()
	if CraftBench.FishingUI and CraftBench.FishingUI.InitializeBar then
		CraftBench.FishingUI:InitializeBar()
	end

	local f = CreateFrame("Frame")
	f:RegisterEvent("LOOT_OPENED")
	f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	f:RegisterEvent("CHAT_MSG_SKILL")
	f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	f:RegisterEvent("BAG_UPDATE_DELAYED")
	f:RegisterEvent("PLAYER_REGEN_ENABLED")
	f:SetScript("OnEvent", function(_, event, arg1, _, arg3)
		if event == "LOOT_OPENED" then
			if IsFishingLoot and IsFishingLoot() then
				logFishingLoot()
			end
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" and not (issecretvalue and issecretvalue(arg1)) and arg1 == "player" then
			if not (issecretvalue and issecretvalue(arg3)) and (FISHING_SPELLS[arg3] or getSpellNameSafe(arg3) == FISHING_SPELL_NAME) then
				local rec = currentZoneRecord()
				if rec then rec.casts = (rec.casts or 0) + 1 end
				updateCastButton()
			end
		elseif event == "CHAT_MSG_SKILL" then
			local isFishingUp = false
			if type(arg1) == "string" and not (issecretvalue and issecretvalue(arg1)) then
				isFishingUp = arg1:find(FISHING_SPELL_NAME, 1, true) ~= nil
					or arg1:find("Fishing", 1, true) ~= nil
					or arg1:find("Angeln", 1, true) ~= nil
			elseif (GetTime() - (session.lastLootAt or -100)) < 5 then
				isFishingUp = true
			end
			if isFishingUp then
				session.ups = session.ups + 1
				if CraftBench.FishingUI and CraftBench.FishingUI.Refresh then
					CraftBench.FishingUI:Refresh()
				end
			end
		else
			updateCastButton()
		end
	end)
end

function Fishing:TriggerSwap()
	swapPoleAndWeapons()
end
