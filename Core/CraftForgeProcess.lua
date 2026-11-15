local addonName, addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("CraftForge") -- for DebugAids.lua
--[[
CraftForge: All-in-One Profession, Crafting & Material-Processing Suite.

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

local L = LibStub("AceLocale-3.0"):GetLocale("CraftForge")

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

local function getSpellNameSafe(spellID)
	if C_Spell and C_Spell.GetSpellName then
		return C_Spell.GetSpellName(spellID)
	elseif GetSpellInfo then
		return (GetSpellInfo(spellID))
	end
end

local function isSpellKnownSafe(spellID)
	if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
		return C_SpellBook.IsSpellInSpellBook(spellID)
	elseif IsPlayerSpell then
		return IsPlayerSpell(spellID)
	elseif IsSpellKnown then
		return IsSpellKnown(spellID)
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
	local mod = CraftForge.db and CraftForge.db.profile and CraftForge.db.profile.process_modifier or "ALT"
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
	local profile = CraftForge.db and CraftForge.db.profile
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
	if AutoCastShine_AutoCastStop then
		AutoCastShine_AutoCastStop(processButton)
	end
	processButton:Hide()
	processButton:ClearAllPoints()
	processButton:SetAttribute("type", nil)
	processButton:SetAttribute("spell", nil)
	processButton:SetAttribute("target-bag", nil)
	processButton:SetAttribute("target-slot", nil)
end

local function showProcessButton(owner, bag, slot, spellName, r, g, b)
	if not processButton or InCombatLockdown() or not owner or not spellName then return end
	processButton:SetParent(owner)
	processButton:SetAllPoints(owner)
	processButton:SetFrameStrata(owner:GetFrameStrata() or "HIGH")
	processButton:SetFrameLevel((owner:GetFrameLevel() or 1) + 5)

	processButton:SetAttribute("type", "spell")
	processButton:SetAttribute("spell", spellName)
	processButton:SetAttribute("target-bag", bag)
	processButton:SetAttribute("target-slot", slot)

	if CraftForge.db.profile.process_glow and AutoCastShine_AutoCastStart then
		AutoCastShine_AutoCastStart(processButton, r, g, b)
	end
	processButton:Show()
end

local function handleTooltipItem(tooltip, tooltipData)
	if InCombatLockdown() then return end
	if not CraftForge.db or not CraftForge.db.profile or not CraftForge.db.profile.process_enabled then
		return
	end
	if not isModifierActive() then
		hideProcessButton()
		return
	end

	local owner = tooltip:GetOwner()
	local bag, slot = extractBagSlotFromOwner(owner)
	if not bag or not slot then return end

	local _, itemLink = nil, nil
	if tooltip.GetItem then
		_, itemLink = tooltip:GetItem()
	end
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

function CraftForge:InitializeProcessing()
	if processInitialized then return end
	processInitialized = true

	processButton = CreateFrame("Button", "CraftForgeProcessButton", UIParent, "SecureActionButtonTemplate, AutoCastShineTemplate")
	processButton:Hide()
	processButton:RegisterForClicks("AnyUp", "AnyDown")
	processButton:SetScript("OnLeave", function()
		hideProcessButton()
	end)

	self:RegisterEvent("PLAYER_REGEN_DISABLED", function()
		hideProcessButton()
	end)
	self:RegisterEvent("MODIFIER_STATE_CHANGED", function()
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
	end)

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
