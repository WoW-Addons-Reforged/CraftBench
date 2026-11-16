----------------------------------------------------------
-- CraftBench - Crafted Gear Scanner & Slot Index       --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")

CraftBench.Gear = CraftBench.Gear or {}
local Gear = CraftBench.Gear

local ARMOR_SLOTS = {
	INVTYPE_HEAD = true,
	INVTYPE_SHOULDER = true,
	INVTYPE_CHEST = true,
	INVTYPE_ROBE = true,
	INVTYPE_WRIST = true,
	INVTYPE_HAND = true,
	INVTYPE_WAIST = true,
	INVTYPE_LEGS = true,
	INVTYPE_FEET = true,
}

local WEAPON_SLOTS = {
	INVTYPE_WEAPON = true,
	INVTYPE_WEAPONMAINHAND = true,
	INVTYPE_WEAPONOFFHAND = true,
	INVTYPE_2HWEAPON = true,
	INVTYPE_SHIELD = true,
	INVTYPE_HOLDABLE = true,
	INVTYPE_RANGED = true,
	INVTYPE_RANGEDRIGHT = true,
	INVTYPE_THROWN = true,
}

local JEWELRY_SLOTS = {
	INVTYPE_CLOAK = true,
	INVTYPE_NECK = true,
	INVTYPE_FINGER = true,
	INVTYPE_TRINKET = true,
}

local function GetItemDetails(itemID)
	if not itemID or itemID <= 0 then return nil end
	if C_Item and C_Item.GetItemInfo then
		return C_Item.GetItemInfo(itemID)
	elseif GetItemInfo then
		return GetItemInfo(itemID)
	end
	return nil
end

local function MatchesCategory(equipLoc, category)
	if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" or equipLoc == "INVTYPE_BAG" then
		return false
	end
	if category == "all" or not category then return true end
	if category == "armor" then return ARMOR_SLOTS[equipLoc] == true end
	if category == "weapons" then return WEAPON_SLOTS[equipLoc] == true end
	if category == "jewelry" then return JEWELRY_SLOTS[equipLoc] == true end
	return equipLoc == category
end

function Gear:CollectCraftableGear(category)
	local results = {}
	local player = CraftBench.currentPlayer or (CraftBench.unitName and CraftBench:unitName("player"))
	local tradeID = CraftBench.currentTrade
	if not player or not tradeID or not CraftBench.GetNumSkills then
		return results
	end

	local n = CraftBench:GetNumSkills(player, tradeID) or 0
	for i = 1, n do
		local skill = CraftBench:GetSkill(player, tradeID, i)
		if skill and skill.id and skill.id ~= 0 then
			local recipe = CraftBench:GetRecipe(skill.id)
			if recipe and recipe.itemID and recipe.itemID > 0 then
				local itemName, itemLink, quality, itemLevel, reqLevel, _, _, _, equipLoc, icon = GetItemDetails(recipe.itemID)
				if MatchesCategory(equipLoc, category) then
					local slotName = _G[equipLoc] or equipLoc
					table.insert(results, {
						skillIndex = i,
						recipeID = skill.id,
						itemID = recipe.itemID,
						name = itemName or skill.name or ("Item #" .. tostring(recipe.itemID)),
						link = itemLink,
						quality = quality or 1,
						itemLevel = itemLevel or 0,
						reqLevel = reqLevel or 0,
						equipLoc = equipLoc,
						slotName = slotName,
						icon = icon or 134400,
						difficulty = skill.difficulty,
						numCraftable = skill.numCraftable or 0,
					})
				end
			end
		end
	end

	table.sort(results, function(a, b)
		if a.itemLevel ~= b.itemLevel then return a.itemLevel > b.itemLevel end
		if a.reqLevel ~= b.reqLevel then return a.reqLevel > b.reqLevel end
		return (a.name or "") < (b.name or "")
	end)
	return results
end
