local addonName, addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("CraftBench") -- for DebugAids.lua
--[[
CraftBench: All-in-One Profession, Crafting & Material-Processing Suite.

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

local L = LibStub("AceLocale-3.0"):GetLocale("CraftBench")

local SPELL_DISENCHANT = 13262
local SPELL_PROSPECT   = 31252
local SPELL_MILL       = 51005
local SPELL_PICKLOCK   = 1804

local MODIFIER_CHECKS = {
	ALT   = IsAltKeyDown,
	CTRL  = IsControlKeyDown,
	SHIFT = IsShiftKeyDown,
}

local processButton
local processInitialized = false
local tooltipProcessed = setmetatable({}, { __mode = "k" })

local PROSPECT_YIELDS = {
	[2770] = { { 774, 50, 1, 2 }, { 818, 50, 1, 2 }, { 1210, 10, 1, 1 } }, -- Copper Ore
	[2771] = { { 1206, 37, 1, 2 }, { 1705, 37, 1, 2 }, { 1529, 37, 1, 2 }, { 1210, 8, 1, 1 } }, -- Tin Ore
	[2772] = { { 1705, 35, 1, 2 }, { 1529, 35, 1, 2 }, { 3864, 35, 1, 2 }, { 7909, 5, 1, 1 }, { 7910, 5, 1, 1 } }, -- Iron Ore
	[3858] = { { 3864, 35, 1, 2 }, { 7909, 35, 1, 2 }, { 7910, 35, 1, 2 }, { 12361, 3, 1, 1 }, { 12799, 3, 1, 1 } }, -- Mithril Ore
	[10620] = { { 7910, 25, 1, 2 }, { 12361, 25, 1, 2 }, { 12799, 25, 1, 2 }, { 12800, 10, 1, 1 }, { 12364, 10, 1, 1 } }, -- Thorium Ore
	[23424] = { { 23077, 25, 1, 2 }, { 21929, 25, 1, 2 }, { 23112, 25, 1, 2 }, { 23079, 25, 1, 2 }, { 23107, 25, 1, 2 }, { 23117, 25, 1, 2 } }, -- Fel Iron Ore
	[23425] = { { 23436, 15, 1, 1 }, { 23439, 15, 1, 1 }, { 23440, 15, 1, 1 }, { 23437, 15, 1, 1 }, { 23438, 15, 1, 1 }, { 23441, 15, 1, 1 } }, -- Adamantite Ore
	[36909] = { { 36917, 25, 1, 2 }, { 36920, 25, 1, 2 }, { 36923, 25, 1, 2 }, { 36926, 25, 1, 2 }, { 36929, 25, 1, 2 }, { 36932, 25, 1, 2 } }, -- Cobalt Ore
	[36912] = { { 36918, 16, 1, 1 }, { 36921, 16, 1, 1 }, { 36924, 16, 1, 1 }, { 36927, 16, 1, 1 }, { 36930, 16, 1, 1 }, { 36933, 16, 1, 1 } }, -- Saronite Ore
	[36910] = { { 36919, 15, 1, 1 }, { 36922, 15, 1, 1 }, { 36925, 15, 1, 1 }, { 36928, 15, 1, 1 }, { 36931, 15, 1, 1 }, { 36934, 15, 1, 1 }, { 41334, 10, 1, 2 } }, -- Titanium Ore
	[53038] = { { 52177, 25, 1, 2 }, { 52178, 25, 1, 2 }, { 52179, 25, 1, 2 }, { 52180, 25, 1, 2 }, { 52181, 25, 1, 2 }, { 52182, 25, 1, 2 } }, -- Obsidium Ore
	[52185] = { { 52190, 16, 1, 1 }, { 52191, 16, 1, 1 }, { 52192, 16, 1, 1 }, { 52193, 16, 1, 1 }, { 52194, 16, 1, 1 }, { 52195, 16, 1, 1 } }, -- Elementium Ore
	[52183] = { { 52190, 25, 1, 2 }, { 52191, 25, 1, 2 }, { 52192, 25, 1, 2 }, { 52193, 25, 1, 2 }, { 52194, 25, 1, 2 }, { 52195, 25, 1, 2 } }, -- Pyrite Ore
	[72092] = { { 76131, 25, 1, 2 }, { 76132, 25, 1, 2 }, { 76133, 25, 1, 2 }, { 76134, 25, 1, 2 }, { 76135, 25, 1, 2 }, { 76136, 25, 1, 2 } }, -- Ghost Iron Ore
}

local MILL_YIELDS = {
	[765] = { { 39151, 100, 2, 3 } }, -- Silverleaf
	[2447] = { { 39151, 100, 2, 3 } }, -- Peacebloom
	[2449] = { { 39151, 100, 2, 3 } }, -- Earthroot
	[785] = { { 39334, 100, 2, 3 }, { 43103, 25, 1, 2 } }, -- Mageroyal
	[2450] = { { 39334, 100, 2, 3 }, { 43103, 25, 1, 2 } }, -- Briarthorn
	[2452] = { { 39334, 100, 2, 3 }, { 43103, 25, 1, 2 } }, -- Swiftthistle
	[2453] = { { 39334, 100, 2, 3 }, { 43103, 25, 1, 2 } }, -- Bruiseweed
	[3820] = { { 39334, 100, 2, 3 }, { 43103, 25, 1, 2 } }, -- Stranglekelp
	[3355] = { { 39338, 100, 2, 3 }, { 43104, 25, 1, 2 } }, -- Wild Steelbloom
	[3356] = { { 39338, 100, 2, 3 }, { 43104, 25, 1, 2 } }, -- Kingsblood
	[3357] = { { 39338, 100, 2, 3 }, { 43104, 25, 1, 2 } }, -- Liferoot
	[3369] = { { 39338, 100, 2, 3 }, { 43104, 25, 1, 2 } }, -- Grave Moss
	[3818] = { { 39339, 100, 2, 3 }, { 43105, 25, 1, 2 } }, -- Fadeleaf
	[3821] = { { 39339, 100, 2, 3 }, { 43105, 25, 1, 2 } }, -- Goldthorn
	[3358] = { { 39339, 100, 2, 3 }, { 43105, 25, 1, 2 } }, -- Khadgar's Whisker
	[3819] = { { 39339, 100, 2, 3 }, { 43105, 25, 1, 2 } }, -- Dragon's Teeth
	[4625] = { { 39340, 100, 2, 4 }, { 43106, 25, 1, 2 } }, -- Firebloom
	[8831] = { { 39340, 100, 2, 4 }, { 43106, 25, 1, 2 } }, -- Purple Lotus
	[8836] = { { 39340, 100, 2, 4 }, { 43106, 25, 1, 2 } }, -- Arthas' Tears
	[8838] = { { 39340, 100, 2, 4 }, { 43106, 25, 1, 2 } }, -- Sungrass
	[8839] = { { 39340, 100, 2, 4 }, { 43106, 25, 1, 2 } }, -- Blindweed
	[8845] = { { 39340, 100, 2, 4 }, { 43106, 25, 1, 2 } }, -- Ghost Mushroom
	[8846] = { { 39340, 100, 2, 4 }, { 43106, 25, 1, 2 } }, -- Gromsblood
	[13463] = { { 39341, 100, 2, 4 }, { 43107, 25, 1, 2 } }, -- Dreamfoil
	[13464] = { { 39341, 100, 2, 4 }, { 43107, 25, 1, 2 } }, -- Golden Sansam
	[13465] = { { 39341, 100, 2, 4 }, { 43107, 25, 1, 2 } }, -- Mountain Silversage
	[13466] = { { 39341, 100, 2, 4 }, { 43107, 25, 1, 2 } }, -- Sorrowmoss
	[13467] = { { 39341, 100, 2, 4 }, { 43107, 25, 1, 2 } }, -- Icecap
	[22785] = { { 39342, 100, 2, 4 }, { 43108, 25, 1, 2 } }, -- Felweed
	[22786] = { { 39342, 100, 2, 4 }, { 43108, 25, 1, 2 } }, -- Dreaming Glory
	[22787] = { { 39342, 100, 2, 4 }, { 43108, 25, 1, 2 } }, -- Ragveil
	[22789] = { { 39342, 100, 2, 4 }, { 43108, 25, 1, 2 } }, -- Terocone
	[22790] = { { 39342, 100, 2, 4 }, { 43108, 25, 1, 2 } }, -- Ancient Lichen
	[22791] = { { 39342, 100, 2, 4 }, { 43108, 25, 1, 2 } }, -- Netherbloom
	[22792] = { { 39342, 100, 2, 4 }, { 43108, 25, 1, 2 } }, -- Nightmare Vine
	[22793] = { { 39342, 100, 2, 4 }, { 43108, 25, 1, 2 } }, -- Mana Thistle
	[36901] = { { 39343, 100, 2, 4 }, { 43109, 25, 1, 2 } }, -- Goldclover
	[36903] = { { 39343, 100, 2, 4 }, { 43109, 50, 1, 3 } }, -- Adder's Tongue
	[36904] = { { 39343, 100, 2, 4 }, { 43109, 25, 1, 2 } }, -- Tiger Lily
	[36905] = { { 39343, 100, 2, 4 }, { 43109, 50, 1, 3 } }, -- Lichbloom
	[36906] = { { 39343, 100, 2, 4 }, { 43109, 50, 1, 3 } }, -- Icethorn
	[36907] = { { 39343, 100, 2, 4 }, { 43109, 25, 1, 2 } }, -- Talandra's Rose
	[37921] = { { 39343, 100, 2, 4 }, { 43109, 25, 1, 2 } }, -- Deadnettle
	[39970] = { { 39343, 100, 2, 4 }, { 43109, 25, 1, 2 } }, -- Fire Leaf
	[52983] = { { 61979, 100, 2, 4 }, { 61980, 25, 1, 2 } }, -- Cinderbloom
	[52984] = { { 61979, 100, 2, 4 }, { 61980, 25, 1, 2 } }, -- Stormvine
	[52985] = { { 61979, 100, 2, 4 }, { 61980, 25, 1, 2 } }, -- Azshara's Veil
	[52986] = { { 61979, 100, 2, 4 }, { 61980, 25, 1, 2 } }, -- Heartblossom
	[52987] = { { 61979, 100, 2, 4 }, { 61980, 50, 1, 3 } }, -- Twilight Jasmine
	[52988] = { { 61979, 100, 2, 4 }, { 61980, 50, 1, 3 } }, -- Whiptail
	[72234] = { { 79251, 100, 2, 4 }, { 79253, 25, 1, 2 } }, -- Green Tea Leaf
	[72235] = { { 79251, 100, 2, 4 }, { 79253, 25, 1, 2 } }, -- Silkweed
	[72237] = { { 79251, 100, 2, 4 }, { 79253, 25, 1, 2 } }, -- Rain Poppy
	[79010] = { { 79251, 100, 2, 4 }, { 79253, 25, 1, 2 } }, -- Snow Lily
	[79011] = { { 79251, 100, 2, 4 }, { 79253, 50, 1, 3 } }, -- Fool's Cap
}

local function getSpellNameSafe(spellID)
	if C_Spell and C_Spell.GetSpellName then
		return C_Spell.GetSpellName(spellID)
	elseif GetSpellInfo then
		return (GetSpellInfo(spellID))
	end
end

local function isSpellKnownSafe(spellID)
	if C_SpellBook and C_SpellBook.IsSpellInSpellBook and C_SpellBook.IsSpellInSpellBook(spellID) then
		return true
	end
	if IsPlayerSpell and IsPlayerSpell(spellID) then
		return true
	end
	if IsSpellKnown and IsSpellKnown(spellID) then
		return true
	end
	if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID) then
		return true
	end
	return false
end

local function getItemInfoSafe(item)
	if C_Item and C_Item.GetItemInfo then
		return C_Item.GetItemInfo(item)
	elseif GetItemInfo then
		return GetItemInfo(item)
	end
end

local function getContainerItemInfoSafe(bag, slot)
	if C_Container and C_Container.GetContainerItemInfo then
		local info = C_Container.GetContainerItemInfo(bag, slot)
		if info then
			return info.stackCount, info.hyperlink, info.isLocked
		end
	elseif GetContainerItemInfo then
		local _, count, locked, _, _, _, link = GetContainerItemInfo(bag, slot)
		return count, link, locked
	end
	return nil
end

local function isModifierActive()
	local mod = CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.process_modifier or "ALT"
	local fn = MODIFIER_CHECKS[mod] or IsAltKeyDown
	return fn()
end

local function tooltipHasPattern(tooltip, pattern)
	if not tooltip or not pattern then return false end
	local name = tooltip:GetName()
	if not name then return false end
	for i = 2, tooltip:NumLines() do
		local left = _G[name .. "TextLeft" .. i]
		if left then
			local text = left:GetText()
			if text and text:find(pattern, 1, true) then
				return true
			end
		end
	end
	return false
end

local function tooltipDataHasText(tooltipData, pattern)
	if not tooltipData or not tooltipData.lines or not pattern then return false end
	for _, line in ipairs(tooltipData.lines) do
		if line.leftText and line.leftText:find(pattern, 1, true) then
			return true
		end
	end
	return false
end

local function resolveActionForItem(itemLink, bag, slot, tooltip, tooltipData)
	if not itemLink or not bag or not slot then return nil end
	local profile = CraftBench.db and CraftBench.db.profile
	if not profile or not profile.process_enabled then return nil end

	local count, _, isLocked = getContainerItemInfoSafe(bag, slot)
	if not count or isLocked then return nil end

	local _, _, quality, _, _, _, _, _, equipLoc, _, _, classID, subClassID = getItemInfoSafe(itemLink)

	-- 1. Lockpicking (Rogue Pick Lock on locked boxes)
	if profile.process_lockpick and isSpellKnownSafe(SPELL_PICKLOCK) then
		local lockedText = LOCKED
		if (tooltipData and tooltipDataHasText(tooltipData, lockedText)) or (tooltip and tooltipHasPattern(tooltip, lockedText)) then
			return getSpellNameSafe(SPELL_PICKLOCK), 0.7, 0.7, 0.7
		end
	end

	-- 2. Disenchanting (Enchanting on Armor/Weapons/Professions gear)
	if profile.process_disenchant and isSpellKnownSafe(SPELL_DISENCHANT) then
		local maxQuality = profile.process_max_quality or 4
		if quality and quality >= 2 and quality <= maxQuality then
			local isGear = (classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Profession)
			if isGear and equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_BAG" then
				return getSpellNameSafe(SPELL_DISENCHANT), 0.55, 0.25, 0.95
			end
		end
	end

	-- 3. Prospecting (Jewelcrafting on stacks >= 5)
	if profile.process_prospect and isSpellKnownSafe(SPELL_PROSPECT) and count >= 5 then
		local prospectText = ITEM_PROSPECTABLE
		if (tooltipData and tooltipDataHasText(tooltipData, prospectText)) or (tooltip and tooltipHasPattern(tooltip, prospectText)) then
			return getSpellNameSafe(SPELL_PROSPECT), 1.0, 0.65, 0.15
		end
	end

	-- 4. Milling (Inscription on stacks >= 5)
	if profile.process_mill and isSpellKnownSafe(SPELL_MILL) and count >= 5 then
		local millText = ITEM_MILLABLE
		if (tooltipData and tooltipDataHasText(tooltipData, millText)) or (tooltip and tooltipHasPattern(tooltip, millText)) then
			return getSpellNameSafe(SPELL_MILL), 0.3, 0.85, 0.35
		end
	end

	-- Fallback for Tradegoods (if client doesn't expose ITEM_PROSPECTABLE / ITEM_MILLABLE on tooltip)
	if classID == Enum.ItemClass.Tradegoods and count >= 5 then
		if subClassID == 7 and profile.process_prospect and isSpellKnownSafe(SPELL_PROSPECT) then
			return getSpellNameSafe(SPELL_PROSPECT), 1.0, 0.65, 0.15
		elseif subClassID == 9 and profile.process_mill and isSpellKnownSafe(SPELL_MILL) then
			return getSpellNameSafe(SPELL_MILL), 0.3, 0.85, 0.35
		end
	end

	return nil
end

local function extractBagSlotFromOwner(owner)
	if not owner then return nil, nil end
	-- Baganator live item buttons expose owner.BGR.itemLocation = { bagID, slotIndex }
	-- Cached/offline Baganator buttons have owner.BGR without itemLocation and must not be treated as live bag slots.
	if owner.BGR then
		local loc = owner.BGR.itemLocation
		if type(loc) == "table" and type(loc.bagID) == "number" and type(loc.slotIndex) == "number" then
			if loc.bagID >= 0 and loc.slotIndex >= 1 then
				return loc.bagID, loc.slotIndex
			end
		end
		return nil, nil
	end
	-- ArkInventory item buttons expose owner.ARKINV_Data = { bag_id, slot_id }
	if type(owner.ARKINV_Data) == "table" then
		local bag = owner.ARKINV_Data.bag_id
		local slot = owner.ARKINV_Data.slot_id
		if type(bag) == "number" and type(slot) == "number" and bag >= 0 and slot >= 1 then
			return bag, slot
		end
	end
	-- BetterBags item buttons expose owner.data = { bagid, slotid } or owner.button
	if type(owner.data) == "table" and type(owner.data.bagid) == "number" and type(owner.data.slotid) == "number" then
		if owner.data.bagid >= 0 and owner.data.slotid >= 1 then
			return owner.data.bagid, owner.data.slotid
		end
	end
	-- Bagnon / Combuctor item buttons (owner.GetBag + owner.GetID, or owner.bag + owner.slot)
	if owner.GetBag and owner.GetID then
		local bag = owner:GetBag()
		local slot = owner:GetID()
		if type(bag) == "number" and type(slot) == "number" and bag >= 0 and slot >= 1 then
			return bag, slot
		end
	end
	if type(owner.bag) == "number" and type(owner.slot) == "number" and owner.bag >= 0 and owner.slot >= 1 then
		return owner.bag, owner.slot
	end
	-- Direct bagID / slotID fields (e.g. ElvUI Bags, AdiBags, LiteBag)
	if type(owner.bagID) == "number" and type(owner.slotID) == "number" and owner.bagID >= 0 and owner.slotID >= 1 then
		return owner.bagID, owner.slotID
	end
	-- Retail ContainerFrameItemButtonMixin
	if owner.GetBagID and owner.GetID then
		local bag = owner:GetBagID()
		local slot = owner:GetID()
		if type(bag) == "number" and type(slot) == "number" and bag >= 0 and slot >= 1 then
			return bag, slot
		end
	end
	-- Classic / Bag addons (parent = bag frame with GetID(), button = slot with GetID())
	local parent = owner.GetParent and owner:GetParent()
	if parent and parent.GetID and owner.GetID then
		local bag = parent:GetID()
		local slot = owner:GetID()
		if type(bag) == "number" and type(slot) == "number" and bag >= 0 and slot >= 1 then
			return bag, slot
		end
	end
	return nil, nil
end

local function hideProcessButton()
	if not processButton or InCombatLockdown() then return end
	if processButton.glowFrame then
		if processButton.glowAnim and processButton.glowAnim:IsPlaying() then
			processButton.glowAnim:Stop()
		end
		processButton.glowFrame:Hide()
	end
	processButton:Hide()
	processButton:ClearAllPoints()
	processButton:SetAttribute("type", nil)
	processButton:SetAttribute("macrotext", nil)
	processButton:SetAttribute("alt-type", nil)
	processButton:SetAttribute("alt-macrotext", nil)
	processButton:SetAttribute("ctrl-type", nil)
	processButton:SetAttribute("ctrl-macrotext", nil)
	processButton:SetAttribute("shift-type", nil)
	processButton:SetAttribute("shift-macrotext", nil)
end

local function showProcessButton(owner, bag, slot, spellName, r, g, b)
	if not processButton or InCombatLockdown() or not owner or not spellName then return end
	processButton:SetParent(owner)
	processButton:SetAllPoints(owner)
	processButton:SetFrameStrata(owner:GetFrameStrata() or "HIGH")
	processButton:SetFrameLevel((owner:GetFrameLevel() or 1) + 20)

	local macro = string.format("/cast %s\n/use %d %d", spellName, bag, slot)
	processButton:SetAttribute("type", "macro")
	processButton:SetAttribute("macrotext", macro)
	processButton:SetAttribute("alt-type", "macro")
	processButton:SetAttribute("alt-macrotext", macro)
	processButton:SetAttribute("ctrl-type", "macro")
	processButton:SetAttribute("ctrl-macrotext", macro)
	processButton:SetAttribute("shift-type", "macro")
	processButton:SetAttribute("shift-macrotext", macro)

	if processButton.glowFrame then
		if CraftBench.db.profile.process_glow then
			local cr, cg, cb = r or 1, g or 0.85, b or 0.25
			if processButton.glowOuter then
				processButton.glowOuter:SetVertexColor(cr, cg, cb, 0.95)
			end
			if processButton.glowInner then
				processButton.glowInner:SetColorTexture(cr, cg, cb, 0.18)
			end
			if processButton.glowEdges then
				for _, edge in ipairs(processButton.glowEdges) do
					edge:SetColorTexture(cr, cg, cb, 1.0)
				end
			end
			processButton.glowFrame:Show()
			if processButton.glowAnim and not processButton.glowAnim:IsPlaying() then
				processButton.glowAnim:Play()
			end
		else
			if processButton.glowAnim and processButton.glowAnim:IsPlaying() then
				processButton.glowAnim:Stop()
			end
			processButton.glowFrame:Hide()
		end
	end
	processButton:Show()
end

local function getBuiltInDisenchantYields(quality, itemLevel)
	if not quality or not itemLevel or itemLevel <= 0 then return nil end
	if quality == 2 then
		if itemLevel <= 20 then return { { 10940, 80, 1, 2 }, { 10938, 20, 1, 2 } }
		elseif itemLevel <= 25 then return { { 10940, 75, 2, 3 }, { 10939, 20, 1, 2 }, { 10978, 5, 1, 1 } }
		elseif itemLevel <= 30 then return { { 10940, 75, 2, 5 }, { 10998, 20, 1, 2 }, { 10978, 5, 1, 1 } }
		elseif itemLevel <= 35 then return { { 11083, 75, 1, 2 }, { 11082, 20, 1, 2 }, { 11084, 5, 1, 1 } }
		elseif itemLevel <= 40 then return { { 11083, 75, 2, 5 }, { 11134, 20, 1, 2 }, { 11138, 5, 1, 1 } }
		elseif itemLevel <= 45 then return { { 11137, 75, 1, 2 }, { 11135, 20, 1, 2 }, { 11139, 5, 1, 1 } }
		elseif itemLevel <= 50 then return { { 11137, 75, 2, 5 }, { 11174, 20, 1, 2 }, { 11177, 5, 1, 1 } }
		elseif itemLevel <= 55 then return { { 11176, 75, 1, 2 }, { 11175, 20, 1, 2 }, { 11178, 5, 1, 1 } }
		elseif itemLevel <= 60 then return { { 11176, 75, 2, 5 }, { 16202, 20, 1, 2 }, { 14343, 5, 1, 1 } }
		elseif itemLevel <= 65 then return { { 16204, 75, 1, 2 }, { 16203, 20, 1, 2 }, { 14344, 5, 1, 1 } }
		elseif itemLevel <= 99 then return { { 22445, 75, 1, 3 }, { 22447, 22, 1, 3 }, { 22448, 3, 1, 1 } }
		elseif itemLevel <= 120 then return { { 22445, 75, 2, 5 }, { 22446, 22, 1, 2 }, { 22449, 3, 1, 1 } }
		elseif itemLevel <= 151 then return { { 34054, 75, 1, 3 }, { 34056, 22, 1, 2 }, { 34053, 3, 1, 1 } }
		elseif itemLevel <= 200 then return { { 34054, 75, 2, 5 }, { 34055, 22, 1, 2 }, { 34052, 3, 1, 1 } }
		elseif itemLevel <= 305 then return { { 52555, 75, 1, 3 }, { 52718, 25, 1, 3 } }
		elseif itemLevel <= 333 then return { { 52555, 75, 2, 5 }, { 52719, 25, 1, 2 } }
		elseif itemLevel <= 415 then return { { 74249, 85, 1, 3 }, { 74250, 15, 1, 2 } }
		end
	elseif quality == 3 then
		if itemLevel <= 25 then return { { 10978, 100, 1, 1 } }
		elseif itemLevel <= 30 then return { { 11084, 100, 1, 1 } }
		elseif itemLevel <= 35 then return { { 11138, 100, 1, 1 } }
		elseif itemLevel <= 40 then return { { 11139, 100, 1, 1 } }
		elseif itemLevel <= 45 then return { { 11177, 100, 1, 1 } }
		elseif itemLevel <= 50 then return { { 11178, 100, 1, 1 } }
		elseif itemLevel <= 55 then return { { 14343, 100, 1, 1 } }
		elseif itemLevel <= 65 then return { { 14344, 100, 1, 1 } }
		elseif itemLevel <= 99 then return { { 22448, 100, 1, 1 } }
		elseif itemLevel <= 120 then return { { 22449, 100, 1, 1 } }
		elseif itemLevel <= 165 then return { { 34053, 100, 1, 1 } }
		elseif itemLevel <= 200 then return { { 34052, 100, 1, 1 } }
		elseif itemLevel <= 316 then return { { 52720, 100, 1, 1 } }
		elseif itemLevel <= 377 then return { { 52721, 100, 1, 1 } }
		elseif itemLevel <= 463 then return { { 74247, 100, 1, 1 } }
		end
	elseif quality == 4 then
		if itemLevel <= 60 then return { { 20725, 100, 1, 2 } }
		elseif itemLevel <= 164 then return { { 22450, 100, 1, 2 } }
		elseif itemLevel <= 284 then return { { 34057, 100, 1, 2 } }
		elseif itemLevel <= 416 then return { { 52722, 100, 1, 2 } }
		elseif itemLevel <= 572 then return { { 74248, 100, 1, 2 } }
		end
	end
	return nil
end

local function getMatUnitPrice(matID)
	if CraftBench.GetItemMarketOrVendorPrice then
		local price, isMarket = CraftBench:GetItemMarketOrVendorPrice(matID)
		if isMarket and type(price) == "number" and price > 0 then
			return price
		end
	end
	local _, _, _, _, _, _, _, _, _, _, sellPrice = getItemInfoSafe(matID)
	if type(sellPrice) == "number" and sellPrice > 0 then
		return sellPrice
	end
	return 0
end

local function appendYieldTooltip(tooltip, itemLink)
	if not tooltip or not itemLink or tooltipProcessed[tooltip] then return end
	local profile = CraftBench.db and CraftBench.db.profile
	if not profile then return end

	local itemID = tonumber(itemLink:match("item:(%d+)"))
	if not itemID then return end

	local _, _, quality, itemLevel, _, _, _, _, equipLoc, _, _, classID = getItemInfoSafe(itemLink)
	if C_Item and C_Item.GetDetailedItemLevelInfo then
		local detailed = C_Item.GetDetailedItemLevelInfo(itemLink)
		if detailed and detailed > 0 then
			itemLevel = detailed
		end
	end

	local yields, actionTitle = nil, nil

	-- 1. Disenchant yields
	if profile.process_tooltip_disenchant and quality and quality >= 2 and quality <= 4 then
		local isGear = (classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Profession)
		if isGear and equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_BAG" then
			yields = getBuiltInDisenchantYields(quality, itemLevel)
			actionTitle = getSpellNameSafe(SPELL_DISENCHANT) or L["PROCESSDISENCHANTNAME"]
		end
	end

	-- 2. Prospecting yields
	if not yields and profile.process_tooltip_prospect then
		yields = PROSPECT_YIELDS[itemID]
		if yields then
			actionTitle = (getSpellNameSafe(SPELL_PROSPECT) or L["PROCESSPROSPECTNAME"]) .. " (x5)"
		end
	end

	-- 3. Milling yields
	if not yields and profile.process_tooltip_mill then
		yields = MILL_YIELDS[itemID]
		if yields then
			actionTitle = (getSpellNameSafe(SPELL_MILL) or L["PROCESSMILLNAME"]) .. " (x5)"
		end
	end

	if not yields or #yields == 0 then return end

	local expectedValue = 0
	for _, entry in ipairs(yields) do
		local matID, pct, minC, maxC = entry[1], entry[2], entry[3], entry[4]
		if profile.process_tooltip_value then
			local unitPrice = getMatUnitPrice(matID)
			if unitPrice > 0 then
				expectedValue = expectedValue + (pct / 100) * ((minC + maxC) / 2) * unitPrice
			end
		end
	end

	local valueText = ""
	if profile.process_tooltip_value and expectedValue >= 1 then
		local copper = math.floor(expectedValue)
		if CraftBench.FormatMoneyFull then
			valueText = L["PROCESSYIELDVALUE"] .. ": " .. CraftBench:FormatMoneyFull(copper, true)
		elseif GetCoinTextureString then
			valueText = L["PROCESSYIELDVALUE"] .. ": " .. GetCoinTextureString(copper)
		end
	end

	tooltip:AddDoubleLine("|cff9966ffCraftBench:|r " .. (actionTitle or L["Material Processing"]), valueText, 0.9, 0.8, 1.0, 1.0, 0.85, 0.3)
	for _, entry in ipairs(yields) do
		local matID, pct, minC, maxC = entry[1], entry[2], entry[3], entry[4]
		local matName, _, matQuality = getItemInfoSafe(matID)
		local displayName = matName or ("Item #" .. matID)
		local colorHex = "ffffffff"
		if matQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[matQuality] then
			colorHex = ITEM_QUALITY_COLORS[matQuality].hex or colorHex
		end
		local countStr = (minC == maxC) and tostring(minC) or (minC .. "-" .. maxC)
		tooltip:AddDoubleLine(
			string.format("  |cffffd100%.0f%%|r |c%s%s|r", pct, colorHex, displayName),
			"x" .. countStr,
			0.85, 0.85, 0.85, 0.75, 0.85, 0.75
		)
	end

	tooltipProcessed[tooltip] = true
	tooltip:Show()
end

local function handleTooltipItem(tooltip, tooltipData)
	local _, itemLink = nil, nil
	if tooltip.GetItem then
		_, itemLink = tooltip:GetItem()
	end

	if itemLink then
		appendYieldTooltip(tooltip, itemLink)
	end

	if InCombatLockdown() then return end
	if not CraftBench.db or not CraftBench.db.profile or not CraftBench.db.profile.process_enabled then
		return
	end
	if not isModifierActive() then
		hideProcessButton()
		return
	end

	local owner = tooltip:GetOwner()
	local bag, slot = extractBagSlotFromOwner(owner)
	if not bag or not slot then return end

	if not itemLink then
		local _, link = getContainerItemInfoSafe(bag, slot)
		itemLink = link
	end
	if not itemLink then return end

	local spellName, r, g, b = resolveActionForItem(itemLink, bag, slot, tooltip, tooltipData)
	if spellName then
		showProcessButton(owner, bag, slot, spellName, r, g, b)
	else
		hideProcessButton()
	end
end

function CraftBench:InitializeProcessing()
	if processInitialized then return end
	processInitialized = true

	local function updateProcessClicks()
		if not processButton or InCombatLockdown() then return end
		local useDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
		processButton:RegisterForClicks(useDown and "LeftButtonDown" or "LeftButtonUp")
	end

	processButton = CreateFrame("Button", "CraftBenchProcessButton", UIParent, "SecureActionButtonTemplate")
	processButton:Hide()
	updateProcessClicks()

	local glowFrame = CreateFrame("Frame", nil, processButton)
	glowFrame:SetAllPoints(processButton)
	glowFrame:SetFrameLevel(processButton:GetFrameLevel() + 2)
	glowFrame:Hide()

	local glowOuter = glowFrame:CreateTexture(nil, "OVERLAY", nil, 6)
	glowOuter:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	glowOuter:SetBlendMode("ADD")
	glowOuter:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", -12, 12)
	glowOuter:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", 12, -12)

	local glowInner = glowFrame:CreateTexture(nil, "OVERLAY", nil, 5)
	glowInner:SetAllPoints(glowFrame)
	glowInner:SetBlendMode("ADD")

	local edgeThickness = 2
	local edgeTop = glowFrame:CreateTexture(nil, "OVERLAY", nil, 7)
	edgeTop:SetBlendMode("ADD")
	edgeTop:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", -1, 1)
	edgeTop:SetPoint("TOPRIGHT", glowFrame, "TOPRIGHT", 1, 1)
	edgeTop:SetHeight(edgeThickness)

	local edgeBottom = glowFrame:CreateTexture(nil, "OVERLAY", nil, 7)
	edgeBottom:SetBlendMode("ADD")
	edgeBottom:SetPoint("BOTTOMLEFT", glowFrame, "BOTTOMLEFT", -1, -1)
	edgeBottom:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", 1, -1)
	edgeBottom:SetHeight(edgeThickness)

	local edgeLeft = glowFrame:CreateTexture(nil, "OVERLAY", nil, 7)
	edgeLeft:SetBlendMode("ADD")
	edgeLeft:SetPoint("TOPLEFT", glowFrame, "TOPLEFT", -1, 1)
	edgeLeft:SetPoint("BOTTOMLEFT", glowFrame, "BOTTOMLEFT", -1, -1)
	edgeLeft:SetWidth(edgeThickness)

	local edgeRight = glowFrame:CreateTexture(nil, "OVERLAY", nil, 7)
	edgeRight:SetBlendMode("ADD")
	edgeRight:SetPoint("TOPRIGHT", glowFrame, "TOPRIGHT", 1, 1)
	edgeRight:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMRIGHT", 1, -1)
	edgeRight:SetWidth(edgeThickness)

	local glowAnim = glowFrame:CreateAnimationGroup()
	glowAnim:SetLooping("BOUNCE")
	local pulse = glowAnim:CreateAnimation("Alpha")
	pulse:SetFromAlpha(0.55)
	pulse:SetToAlpha(1.0)
	pulse:SetDuration(0.5)
	pulse:SetSmoothing("IN_OUT")

	processButton.glowFrame = glowFrame
	processButton.glowOuter = glowOuter
	processButton.glowInner = glowInner
	processButton.glowEdges = { edgeTop, edgeBottom, edgeLeft, edgeRight }
	processButton.glowAnim = glowAnim
	processButton:SetScript("OnLeave", function()
		hideProcessButton()
	end)

	local processEventFrame = CreateFrame("Frame")
	local pendingCheck = false
	local function scheduleAutoProcessCheck(delay)
		if pendingCheck then return end
		pendingCheck = true
		if C_Timer and C_Timer.After then
			C_Timer.After(delay or 0.3, function()
				pendingCheck = false
				if CraftBench.CheckAutoProcessPrompt then
					CraftBench:CheckAutoProcessPrompt()
				end
			end)
		else
			pendingCheck = false
			if CraftBench.CheckAutoProcessPrompt then
				CraftBench:CheckAutoProcessPrompt()
			end
		end
	end
	processEventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	processEventFrame:RegisterEvent("BAG_UPDATE")
	processEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	processEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	processEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	processEventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
	processEventFrame:RegisterEvent("CVAR_UPDATE")
	processEventFrame:SetScript("OnEvent", function(_, event, arg1)
		if event == "PLAYER_REGEN_DISABLED" then
			hideProcessButton()
			if CraftBench.HideAutoProcessPrompt then
				CraftBench:HideAutoProcessPrompt()
			end
		elseif event == "MODIFIER_STATE_CHANGED" then
			if not isModifierActive() then
				hideProcessButton()
			elseif GameTooltip and GameTooltip:IsShown() then
				local owner = GameTooltip:GetOwner()
				if owner then
					local bag, slot = extractBagSlotFromOwner(owner)
					if bag and slot then
						handleTooltipItem(GameTooltip, nil)
					end
				end
			end
		elseif event == "CVAR_UPDATE" and arg1 == "ActionButtonUseKeyDown" then
			updateProcessClicks()
		elseif event == "BAG_UPDATE_DELAYED" or event == "PLAYER_REGEN_ENABLED" then
			scheduleAutoProcessCheck(0.25)
		elseif event == "PLAYER_ENTERING_WORLD" then
			scheduleAutoProcessCheck(1.5)
		else
			scheduleAutoProcessCheck(0.5)
		end
	end)
	scheduleAutoProcessCheck(1.5)

	if GameTooltip and GameTooltip.HookScript then
		GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
			tooltipProcessed[tooltip] = nil
		end)
	end

	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
			if tooltip == GameTooltip then
				handleTooltipItem(tooltip, data)
			end
		end)
	elseif GameTooltip and GameTooltip.HookScript then
		GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
			handleTooltipItem(tooltip, nil)
		end)
	end

	DA.DEBUG(0, "InitializeProcessing: Material processing initialized")
end

local processPanelFrame
local processPanelRows = {}

local function getBagNumSlotsSafe(bag)
	if C_Container and C_Container.GetContainerNumSlots then
		return C_Container.GetContainerNumSlots(bag) or 0
	elseif GetContainerNumSlots then
		return GetContainerNumSlots(bag) or 0
	end
	return 0
end

local function refreshProcessPanel()
	if not processPanelFrame or InCombatLockdown() then return end
	local profile = CraftBench.db and CraftBench.db.profile
	if not profile then return end

	local items = {}
	local maxBags = NUM_BAG_SLOTS or 4
	for bag = 0, maxBags do
		local slots = getBagNumSlotsSafe(bag)
		for slot = 1, slots do
			local count, itemLink, isLocked = getContainerItemInfoSafe(bag, slot)
			if itemLink and count and not isLocked then
				local spellName = resolveActionForItem(itemLink, bag, slot, nil, nil)
				if not spellName and count >= 5 then
					local itemID = tonumber(itemLink:match("item:(%d+)"))
					if itemID then
						if profile.process_prospect and PROSPECT_YIELDS[itemID] and isSpellKnownSafe(SPELL_PROSPECT) then
							spellName = getSpellNameSafe(SPELL_PROSPECT)
						elseif profile.process_mill and MILL_YIELDS[itemID] and isSpellKnownSafe(SPELL_MILL) then
							spellName = getSpellNameSafe(SPELL_MILL)
						end
					end
				end
				if spellName then
					table.insert(items, {
						bag = bag,
						slot = slot,
						link = itemLink,
						count = count,
						spell = spellName,
					})
				end
			end
		end
	end

	processPanelFrame.emptyLabel:SetShown(#items == 0)
	for i = 1, 10 do
		local row = processPanelRows[i]
		local entry = items[i]
		if entry then
			row.label:SetText(string.format("%s x%d", entry.link, entry.count))
			row.btn:SetText(entry.spell)
			row.btn:SetAttribute("type", "macro")
			row.btn:SetAttribute("macrotext", string.format("/cast %s\n/use %d %d", entry.spell, entry.bag, entry.slot))
			row:Show()
		else
			row:Hide()
		end
	end
end

function CraftBench:ShowProcessPanel()
	if InCombatLockdown() then return end
	if not processPanelFrame then
		local UIStyle = CraftBench.UIStyle
		local f = CreateFrame("Frame", "CraftBenchProcessPanelFrame", UIParent, "BackdropTemplate")
		f:SetSize(400, 340)
		f:SetPoint("CENTER")
		f:SetFrameStrata("DIALOG")
		f:SetMovable(true)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)
		if UIStyle and UIStyle.SkinFrame then
			UIStyle.SkinFrame(f)
		end

		local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
		title:SetText("|cffffd100CraftBench|r — " .. L["Material Processing"])

		local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
		if UIStyle and UIStyle.SkinCloseButton then
			UIStyle.SkinCloseButton(closeBtn)
		end

		local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		refreshBtn:SetSize(80, 22)
		refreshBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -4, -3)
		refreshBtn:SetText(L["Refresh"])
		if UIStyle and UIStyle.SkinButton then
			UIStyle.SkinButton(refreshBtn)
		end
		refreshBtn:SetScript("OnClick", refreshProcessPanel)

		local emptyLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		emptyLbl:SetPoint("CENTER", f, "CENTER", 0, -10)
		emptyLbl:SetText("|cff888888" .. L["PROCESS_PANEL_EMPTY"] .. "|r")
		f.emptyLabel = emptyLbl

		for i = 1, 10 do
			local row = CreateFrame("Frame", nil, f)
			row:SetSize(372, 26)
			row:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -42 - (i - 1) * 28)

			local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
			lbl:SetWidth(250)
			lbl:SetJustifyH("LEFT")
			row.label = lbl

			local btn = CreateFrame("Button", "CraftBenchProcessPanelBtn" .. i, row, "SecureActionButtonTemplate,UIPanelButtonTemplate")
			btn:SetSize(110, 22)
			btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
			btn:RegisterForClicks("LeftButtonUp")
			if UIStyle and UIStyle.SkinButton then
				UIStyle.SkinButton(btn)
			end
			btn:HookScript("PostClick", function()
				C_Timer.After(0.4, refreshProcessPanel)
			end)
			row.btn = btn
			processPanelRows[i] = row
		end

		f:SetScript("OnShow", refreshProcessPanel)
		processPanelFrame = f
	end
	if processPanelFrame:IsShown() then
		processPanelFrame:Hide()
	else
		processPanelFrame:Show()
	end
end

local autoPromptFrame
local autoSessionIgnore = {}

local function formatPromptMoney(copper)
	local absC = math.floor(math.max(0, copper or 0))
	if absC == 0 then return "|cff888888-|r" end
	if CraftBench.FormatMoneyFull then
		return CraftBench:FormatMoneyFull(absC, true)
	elseif GetCoinTextureString then
		return GetCoinTextureString(absC)
	end
	return tostring(absC)
end

local function computeExpectedYieldValue(itemLink, itemID)
	local _, _, quality, itemLevel, _, _, _, _, equipLoc, _, _, classID = getItemInfoSafe(itemLink)
	if C_Item and C_Item.GetDetailedItemLevelInfo then
		local detailed = C_Item.GetDetailedItemLevelInfo(itemLink)
		if detailed and detailed > 0 then
			itemLevel = detailed
		end
	end
	local yields
	if quality and quality >= 2 and quality <= 4 then
		local isGear = (classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon or classID == Enum.ItemClass.Profession)
		if isGear and equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_BAG" then
			yields = getBuiltInDisenchantYields(quality, itemLevel)
		end
	end
	if not yields and itemID then
		yields = PROSPECT_YIELDS[itemID] or MILL_YIELDS[itemID]
	end
	if not yields then return 0 end
	local expected = 0
	for _, entry in ipairs(yields) do
		local matID, pct, minC, maxC = entry[1], entry[2], entry[3], entry[4]
		local unitPrice = getMatUnitPrice(matID)
		if unitPrice > 0 then
			expected = expected + (pct / 100) * ((minC + maxC) / 2) * unitPrice
		end
	end
	return expected
end

function CraftBench:HideAutoProcessPrompt()
	if autoPromptFrame and not InCombatLockdown() then
		autoPromptFrame:Hide()
	end
end

function CraftBench:ClearAutoProcessIgnores()
	wipe(autoSessionIgnore)
	if CraftBench.db and CraftBench.db.profile then
		CraftBench.db.profile.process_autopopup_ignore = {}
	end
	DA.MARK2(L["PROCESS_AUTOPOPUP_CLEARED"])
	if self.CheckAutoProcessPrompt then
		self:CheckAutoProcessPrompt()
	end
end

function CraftBench:CheckAutoProcessPrompt()
	if InCombatLockdown() then return end
	local profile = CraftBench.db and CraftBench.db.profile
	if not profile or not profile.process_enabled or not profile.process_autopopup then
		self:HideAutoProcessPrompt()
		return
	end
	if (MerchantFrame and MerchantFrame:IsShown()) or (MailFrame and MailFrame:IsShown()) or (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then
		return
	end

	local permIgnore = profile.process_autopopup_ignore or {}
	local found
	local maxBags = NUM_BAG_SLOTS or 4
	for bag = 0, maxBags do
		local slots = getBagNumSlotsSafe(bag)
		for slot = 1, slots do
			local count, itemLink, isLocked = getContainerItemInfoSafe(bag, slot)
			if itemLink and count and not isLocked then
				local itemID = tonumber(itemLink:match("item:(%d+)"))
				if itemID and not autoSessionIgnore[itemID] and not permIgnore[itemID] then
					local spellName = resolveActionForItem(itemLink, bag, slot, nil, nil)
					if not spellName and count >= 5 then
						if profile.process_prospect and PROSPECT_YIELDS[itemID] and isSpellKnownSafe(SPELL_PROSPECT) then
							spellName = getSpellNameSafe(SPELL_PROSPECT)
						elseif profile.process_mill and MILL_YIELDS[itemID] and isSpellKnownSafe(SPELL_MILL) then
							spellName = getSpellNameSafe(SPELL_MILL)
						end
					end
					if spellName then
						local isUpgrade = false
						if _G.PawnIsItemAnUpgrade and _G.PawnGetItemData then
							local okP, itemData = pcall(_G.PawnGetItemData, itemLink)
							if okP and itemData then
								local okU, upg = pcall(_G.PawnIsItemAnUpgrade, itemData)
								if okU and upg then
									isUpgrade = true
								end
							end
						end
						if not isUpgrade then
							found = {
								bag = bag,
								slot = slot,
								itemID = itemID,
								link = itemLink,
								count = count,
								spell = spellName,
							}
							break
						end
					end
				end
			end
		end
		if found then break end
	end

	if not found then
		self:HideAutoProcessPrompt()
		return
	end

	if not autoPromptFrame then
		local UIStyle = CraftBench.UIStyle
		local f = CreateFrame("Frame", "CraftBenchAutoProcessPrompt", UIParent, "BackdropTemplate")
		f:SetSize(340, 148)
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
		f:SetFrameStrata("DIALOG")
		f:SetMovable(true)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)
		if UIStyle and UIStyle.SkinFrame then
			UIStyle.SkinFrame(f)
		end

		local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
		title:SetText("|cffffd100CraftBench|r — " .. L["PROCESS_AUTOPOPUP_TITLE"])

		local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
		if UIStyle and UIStyle.SkinCloseButton then
			UIStyle.SkinCloseButton(closeBtn)
		end

		local icon = f:CreateTexture(nil, "ARTWORK")
		icon:SetSize(36, 36)
		icon:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -36)
		f.icon = icon

		local itemLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		itemLbl:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
		itemLbl:SetPoint("RIGHT", f, "RIGHT", -14, 0)
		itemLbl:SetJustifyH("LEFT")
		f.itemLabel = itemLbl

		local itemHover = CreateFrame("Frame", nil, f)
		itemHover:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
		itemHover:SetPoint("BOTTOMRIGHT", itemLbl, "BOTTOMRIGHT", 0, -14)
		itemHover:EnableMouse(true)
		itemHover:SetScript("OnEnter", function(btn)
			if not GameTooltip then return end
			GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
			if f.currentBag ~= nil and f.currentSlot ~= nil and GameTooltip.SetBagItem then
				GameTooltip:SetBagItem(f.currentBag, f.currentSlot)
			elseif f.currentLink then
				GameTooltip:SetHyperlink(f.currentLink)
			end
			GameTooltip:Show()
		end)
		itemHover:SetScript("OnLeave", function()
			if GameTooltip then GameTooltip:Hide() end
		end)

		local valLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		valLbl:SetPoint("TOPLEFT", itemLbl, "BOTTOMLEFT", 0, -4)
		valLbl:SetPoint("RIGHT", f, "RIGHT", -14, 0)
		valLbl:SetJustifyH("LEFT")
		f.valLabel = valLbl

		local actBtn = CreateFrame("Button", "CraftBenchAutoProcessActionBtn", f, "SecureActionButtonTemplate,UIPanelButtonTemplate")
		actBtn:SetSize(112, 24)
		actBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 12)
		local useDown = GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")
		actBtn:RegisterForClicks(useDown and "LeftButtonDown" or "LeftButtonUp")
		if UIStyle and UIStyle.SkinButton then
			UIStyle.SkinButton(actBtn)
		end
		actBtn:HookScript("PostClick", function()
			C_Timer.After(0.5, function()
				CraftBench:CheckAutoProcessPrompt()
			end)
		end)
		f.actBtn = actBtn

		local skipBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		skipBtn:SetSize(96, 24)
		skipBtn:SetPoint("LEFT", actBtn, "RIGHT", 6, 0)
		skipBtn:SetText(L["PROCESS_AUTOPOPUP_SKIP"])
		if UIStyle and UIStyle.SkinButton then
			UIStyle.SkinButton(skipBtn)
		end
		skipBtn:SetScript("OnClick", function()
			if f.currentItemID then
				autoSessionIgnore[f.currentItemID] = true
			end
			CraftBench:CheckAutoProcessPrompt()
		end)

		local ignBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		ignBtn:SetSize(96, 24)
		ignBtn:SetPoint("LEFT", skipBtn, "RIGHT", 6, 0)
		ignBtn:SetText(L["PROCESS_AUTOPOPUP_IGNORE"])
		if UIStyle and UIStyle.SkinButton then
			UIStyle.SkinButton(ignBtn)
		end
		ignBtn:SetScript("OnClick", function()
			if f.currentItemID and CraftBench.db and CraftBench.db.profile then
				if not CraftBench.db.profile.process_autopopup_ignore then
					CraftBench.db.profile.process_autopopup_ignore = {}
				end
				CraftBench.db.profile.process_autopopup_ignore[f.currentItemID] = true
			end
			CraftBench:CheckAutoProcessPrompt()
		end)

		autoPromptFrame = f
	end

	local _, _, _, _, _, _, _, _, _, itemTexture = getItemInfoSafe(found.link)
	local marketPrice = getMatUnitPrice(found.itemID)
	local yieldVal = computeExpectedYieldValue(found.link, found.itemID)

	autoPromptFrame.currentItemID = found.itemID
	autoPromptFrame.currentLink = found.link
	autoPromptFrame.currentBag = found.bag
	autoPromptFrame.currentSlot = found.slot
	autoPromptFrame.icon:SetTexture(itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
	autoPromptFrame.itemLabel:SetText(string.format("%s |cffbbbbbb(x%d)|r", found.link, found.count))
	autoPromptFrame.valLabel:SetText(string.format("%s: %s  |  %s: %s",
		L["PROCESS_AUTOPOPUP_ITEMVAL"], formatPromptMoney(marketPrice),
		L["PROCESSYIELDVALUE"], formatPromptMoney(yieldVal)))

	local macro = string.format("/cast %s\n/use %d %d", found.spell, found.bag, found.slot)
	autoPromptFrame.actBtn:SetText(found.spell)
	autoPromptFrame.actBtn:SetAttribute("type", "macro")
	autoPromptFrame.actBtn:SetAttribute("macrotext", macro)
	autoPromptFrame:Show()
end
