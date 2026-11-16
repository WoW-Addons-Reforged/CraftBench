----------------------------------------------------------
-- CraftBench - Skill-Up Chances, Thresholds & Tooltips --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")
local L = CraftBench.L

local DIFF_CHANCE = {
	optimal = 1.0,
	medium = 0.5,
	easy = 0.25,
	trivial = 0.0,
}

local function FormatMoney(copper)
	if not copper or copper <= 0 then return nil end
	local absC = math.floor(math.abs(copper))
	if CraftBench.FormatMoneyFull then
		return CraftBench:FormatMoneyFull(absC, true)
	elseif GetCoinTextureString then
		return GetCoinTextureString(absC)
	end
	return tostring(absC)
end

local function GetCurrentProfessionRank()
	if CraftBench.GetTradeSkillLine then
		local _, rank = CraftBench:GetTradeSkillLine()
		if type(rank) == "number" and rank > 0 then
			return rank
		end
	end
	return nil
end

local function ParseThresholdString(str)
	if type(str) ~= "string" then return nil end
	local o, y, g, gr = string.match(str, "^(%d+)/(%d+)/(%d+)/(%d+)$")
	if o and y and g and gr then
		return {
			orange = tonumber(o),
			yellow = tonumber(y),
			green = tonumber(g),
			grey = tonumber(gr),
		}
	end
	return nil
end

function CraftBench:GetSkillUpThresholds(recipe)
	if not recipe or not recipe.spellID then return nil end
	-- Optional live integration if SkillUpForever is loaded
	if _G.SkillUpForever and _G.SkillUpForever.GetThresholds then
		local o, y, g, gr = _G.SkillUpForever:GetThresholds(recipe.spellID)
		if o and y and g and gr then
			return { orange = tonumber(o), yellow = tonumber(y), green = tonumber(g), grey = tonumber(gr) }
		end
	end
	if self.GetTradeSkillLevels then
		local o, y, g, gr = self:GetTradeSkillLevels(recipe.itemID, recipe.spellID)
		o, y, g, gr = tonumber(o), tonumber(y), tonumber(g), tonumber(gr)
		if o and y and g and gr and gr > 0 then
			return { orange = o, yellow = y, green = g, grey = gr }
		end
	end
	local globalDB = CraftBench.db and CraftBench.db.global
	if globalDB then
		local parsed = (globalDB.SkillLineAbility and ParseThresholdString(globalDB.SkillLineAbility[recipe.spellID]))
			or (recipe.itemID and globalDB.SkillLevels and ParseThresholdString(globalDB.SkillLevels[recipe.itemID]))
		if parsed then return parsed end
	end
	if CraftBench.SkillThresholds and CraftBench.SkillThresholds[recipe.spellID] then
		return CraftBench.SkillThresholds[recipe.spellID]
	end
	return nil
end

function CraftBench:GetSkillUpChance(recipe, currentSkill, difficultyOverride)
	if not recipe then return 0, nil end
	local diff = difficultyOverride or recipe.difficulty
	local thresholds = self:GetSkillUpThresholds(recipe)
	local skill = currentSkill or GetCurrentProfessionRank()

	if thresholds and skill then
		if skill < thresholds.yellow then
			return 1.0, thresholds
		elseif skill >= thresholds.grey then
			return 0.0, thresholds
		else
			local span = math.max(1, thresholds.grey - thresholds.yellow)
			local chance = math.max(0.05, math.min(1.0, (thresholds.grey - skill) / span))
			return chance, thresholds
		end
	end

	return DIFF_CHANCE[diff] or 0, thresholds
end

function CraftBench:EstimateRecipeMaterialCost(recipe)
	if not recipe or not recipe.reagentData or #recipe.reagentData == 0 then
		return nil
	end
	local total = 0
	local hasAnyPrice = false
	for i = 1, #recipe.reagentData do
		local r = recipe.reagentData[i]
		if r and r.reagentID and r.numNeeded then
			local unitPrice = self.GetItemMarketOrVendorPrice and (self:GetItemMarketOrVendorPrice(r.reagentID) or 0) or 0
			if unitPrice > 0 then
				hasAnyPrice = true
				total = total + unitPrice * r.numNeeded
			end
		end
	end
	if not hasAnyPrice then return nil end
	return total
end

function CraftBench:GetRecipeCostAndSkillUp(recipe, currentSkill, difficultyOverride)
	local chance, thresholds = self:GetSkillUpChance(recipe, currentSkill, difficultyOverride)
	local matCost = self:EstimateRecipeMaterialCost(recipe)
	local costPerSkillUp
	if matCost and chance and chance > 0 then
		costPerSkillUp = matCost / chance
	end
	return matCost, chance, costPerSkillUp, thresholds
end

function CraftBench:BuildThresholdBarText(thresholds, currentSkill)
	if not thresholds then return nil end
	local o = thresholds.orange or 1
	local y = thresholds.yellow or o
	local g = thresholds.green or y
	local gr = thresholds.grey or g
	local cur = currentSkill and string.format(" |cffffffff[%d]|r", currentSkill) or ""
	return string.format(
		"|cffff8040%d|r / |cffffff00%d|r / |cff40bf40%d|r / |cff808080%d|r%s",
		o, y, g, gr, cur
	)
end

function CraftBench:AddSkillUpTooltipInfo(tip, skill, recipe)
	if not tip or not recipe then return end
	local diff = (skill and skill.difficulty) or recipe.difficulty
	local curSkill = GetCurrentProfessionRank()
	local _, chance, costPerSkillUp, thresholds = self:GetRecipeCostAndSkillUp(recipe, curSkill, diff)
	if not diff and not thresholds then return end

	tip:AddLine(" ")
	local pct = math.floor((chance or 0) * 100 + 0.5)
	local cr, cg, cb = 0.5, 0.5, 0.5
	if pct >= 80 then
		cr, cg, cb = 1.0, 0.5, 0.25
	elseif pct >= 40 then
		cr, cg, cb = 1.0, 1.0, 0.0
	elseif pct > 0 then
		cr, cg, cb = 0.25, 0.85, 0.25
	end
	tip:AddDoubleLine(L["Skill-Up Chance"] or "Skill-Up Chance:", pct .. "%", 0.82, 0.82, 0.82, cr, cg, cb)

	local barText = self:BuildThresholdBarText(thresholds, curSkill, diff)
	if barText then
		tip:AddDoubleLine(L["Thresholds"] or "Thresholds:", barText, 0.82, 0.82, 0.82, 1, 1, 1)
	end

	if costPerSkillUp then
		local moneyStr = FormatMoney(costPerSkillUp)
		if moneyStr then
			tip:AddDoubleLine(L["Cost / Skill-Up"] or "Cost / Skill-Up:", moneyStr, 0.82, 0.82, 0.82, 1, 0.85, 0.25)
		end
	end
end

function CraftBench:GetSkillUpDetailText(skill, recipe)
	if not recipe then return nil end
	local diff = (skill and skill.difficulty) or (skill and skill.skillData and skill.skillData.difficulty) or recipe.difficulty
	local curSkill = GetCurrentProfessionRank()
	local _, chance, costPerSkillUp, thresholds = self:GetRecipeCostAndSkillUp(recipe, curSkill, diff)
	if not diff and not thresholds then return nil end

	local parts = {}
	local pct = math.floor((chance or 0) * 100 + 0.5)
	local pctColor = (pct >= 80 and "|cffff8040") or (pct >= 40 and "|cffffff00") or (pct > 0 and "|cff40bf40") or "|cff808080"
	parts[#parts + 1] = "|cffffd100" .. (L["Skill-Up Chance"] or "Skill-Up Chance:") .. "|r  " .. pctColor .. pct .. "%|r"

	local barText = self:BuildThresholdBarText(thresholds, curSkill)
	if barText then
		parts[#parts + 1] = "|cffffd100" .. (L["Thresholds"] or "Thresholds:") .. "|r  " .. barText
	end

	if costPerSkillUp then
		local moneyStr = FormatMoney(costPerSkillUp)
		if moneyStr then
			parts[#parts + 1] = "|cffffd100" .. (L["Cost / Skill-Up"] or "Cost / Skill-Up:") .. "|r  " .. moneyStr
		end
	end

	return table.concat(parts, "\n")
end

-- =========================================================
-- Feature 4: "Buffs only" Recipe Filter
-- =========================================================
local BUFF_NAME_PATTERNS = {
	"elixir", "flask", "potion", "well fed", "whetstone", "weightstone",
	"mana oil", "wizard oil", "armor kit", "scope", "food", "feast",
	"elixier", "fläschchen", "trank", "wetzstein", "gewichtsstein",
	"zauberöl", "manaöl", "rüstungsset", "zielfernrohr", "festmahl", "buff",
}

function CraftBench:IsBuffRecipe(recipe)
	if not recipe then return false end
	local itemID = recipe.itemID
	if not itemID or itemID <= 0 then
		local lname = string.lower(recipe.name or "")
		for _, pat in ipairs(BUFF_NAME_PATTERNS) do
			if string.find(lname, pat, 1, true) then
				return true
			end
		end
		return false
	end

	local _, _, _, _, reqLevel, itemType, itemSubType, _, _, _, _, classID, subClassID =
		(C_Item and C_Item.GetItemInfo or GetItemInfo)(itemID)

	local playerLevel = UnitLevel and UnitLevel("player") or 80
	if reqLevel and reqLevel > playerLevel then
		return false
	end

	-- Consumables (classID == 0): Potions (1), Elixirs (2), Flasks (3), Food & Drink (5), Item Enhancements (6)
	if classID == 0 then
		if subClassID == 1 or subClassID == 2 or subClassID == 3 or subClassID == 5 or subClassID == 6 then
			return true
		end
	end

	-- Item Enhancement / Permanent / Temporary (classID == 8)
	if classID == 8 then
		return true
	end

	local combined = string.lower((recipe.name or "") .. " " .. (itemType or "") .. " " .. (itemSubType or ""))
	for _, pat in ipairs(BUFF_NAME_PATTERNS) do
		if string.find(combined, pat, 1, true) then
			return true
		end
	end
	return false
end

-- =========================================================
-- Feature 3a: Trainer Tooltip Annotations
-- =========================================================
local function FindRecipeByName(serviceName)
	if not serviceName or serviceName == "" or not CraftBench.data or not CraftBench.data.recipeDB then
		return nil
	end
	local lower = string.lower(serviceName)
	for _, recipe in pairs(CraftBench.data.recipeDB) do
		if type(recipe) == "table" and recipe.name and string.lower(recipe.name) == lower then
			return recipe
		end
	end
	return nil
end

local function AnnotateTrainerTooltip(tooltip, index)
	if not tooltip or not index or not GetTrainerServiceInfo then return end
	local serviceName, _, category = GetTrainerServiceInfo(index)
	if not serviceName or category == "header" then return end

	local recipe = FindRecipeByName(serviceName)
	if not recipe then return end

	local reqSkill = GetTrainerServiceSkillReq and select(2, GetTrainerServiceSkillReq(index))
	local curSkill = GetCurrentProfessionRank()
	local matCost, chance, costPerSkillUp = CraftBench:GetRecipeCostAndSkillUp(recipe, curSkill, "optimal")

	tooltip:AddLine(" ")
	tooltip:AddLine("|cffffd100CraftBench|r", 1, 0.82, 0)
	if chance then
		tooltip:AddDoubleLine(L["Skill-Up Chance"] or "Skill-Up Chance:", math.floor(chance * 100 + 0.5) .. "%", 0.8, 0.8, 0.8, 0.25, 0.9, 0.25)
	end
	if matCost then
		local money = FormatMoney(matCost)
		if money then
			tooltip:AddDoubleLine(L["Craft Cost"] or "Craft Cost:", money, 0.8, 0.8, 0.8, 1, 1, 1)
		end
	end
	if costPerSkillUp then
		local money = FormatMoney(costPerSkillUp)
		if money then
			tooltip:AddDoubleLine(L["Cost / Skill-Up"] or "Cost / Skill-Up:", money, 0.8, 0.8, 0.8, 1, 0.85, 0.25)
		end
	end
	if curSkill and reqSkill and reqSkill <= curSkill and category == "available" then
		tooltip:AddLine("|cff40ff40" .. (L["TRAINER_RECOMMENDED"] or "Available for current skill") .. "|r")
	end
	tooltip:Show()
end

if GameTooltip and GameTooltip.SetTrainerService then
	hooksecurefunc(GameTooltip, "SetTrainerService", AnnotateTrainerTooltip)
end

-- =========================================================
-- Feature 3b: Reagent Item Tooltips (Plan/Watch + Shift)
-- =========================================================
local function GetItemIDFromTooltip(tooltip)
	if not tooltip then return nil end
	if tooltip.GetItem then
		local _, link = tooltip:GetItem()
		if link then
			local id = tonumber(string.match(link, "item:(%d+)"))
			if id then return id end
		end
	end
	if tooltip.GetTooltipData then
		local data = tooltip:GetTooltipData()
		if data and data.id then return data.id end
	end
	return nil
end

local function CollectWatchNeedForItem(itemID)
	local totalNeed = 0
	local watch = CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.watch
	if watch and watch.pinned and CraftBench.GetRecipe then
		for recipeID, count in pairs(watch.pinned) do
			local recipe = CraftBench:GetRecipe(recipeID)
			if recipe and recipe.reagentData then
				for _, r in ipairs(recipe.reagentData) do
					if r.reagentID == itemID and r.numNeeded then
						totalNeed = totalNeed + r.numNeeded * (count or 1)
					end
				end
			end
		end
	end
	return totalNeed
end

local function CollectSkillUpRecipesUsingItem(itemID, maxResults)
	local matches = {}
	local player = CraftBench.currentPlayer or (CraftBench.unitName and CraftBench:unitName("player"))
	local tradeID = CraftBench.currentTrade
	if not player or not tradeID or not CraftBench.GetNumSkills then
		return matches
	end
	local n = CraftBench:GetNumSkills(player, tradeID) or 0
	for i = 1, n do
		local skill = CraftBench:GetSkill(player, tradeID, i)
		if skill and skill.id and skill.id ~= 0 and skill.difficulty and skill.difficulty ~= "trivial" then
			local recipe = CraftBench:GetRecipe(skill.id)
			if recipe and recipe.reagentData then
				for _, r in ipairs(recipe.reagentData) do
					if r.reagentID == itemID then
						table.insert(matches, {
							name = skill.name or recipe.name or ("Recipe #" .. tostring(skill.id)),
							difficulty = skill.difficulty,
							needed = r.numNeeded or 1,
						})
						if #matches >= (maxResults or 6) then
							return matches
						end
						break
					end
				end
			end
		end
	end
	return matches
end

local function AddReagentTooltipLines(tooltip)
	if not tooltip or tooltip ~= GameTooltip then return end
	local itemID = GetItemIDFromTooltip(tooltip)
	if not itemID then return end

	local watchNeed = CollectWatchNeedForItem(itemID)
	if watchNeed > 0 then
		local have = 0
		if CraftBench.GetItemCount then
			have = CraftBench:GetItemCount(itemID, false, false, false) or 0
		elseif C_Item and C_Item.GetItemCount then
			have = C_Item.GetItemCount(itemID, false) or 0
		elseif GetItemCount then
			have = GetItemCount(itemID, false) or 0
		end
		tooltip:AddLine(" ")
		local doneColor = (have >= watchNeed) and "|cff40ff40" or "|cffffd100"
		tooltip:AddDoubleLine(
			"|cffffd100CraftBench Watch:|r",
			doneColor .. have .. " / " .. watchNeed .. "|r",
			1, 0.82, 0, 1, 1, 1
		)
	end

	if IsShiftKeyDown and IsShiftKeyDown() then
		local recipes = CollectSkillUpRecipesUsingItem(itemID, 6)
		if #recipes > 0 then
			if watchNeed == 0 then tooltip:AddLine(" ") end
			tooltip:AddLine("|cffffd100" .. (L["REAGENT_SKILLUP_RECIPES"] or "CraftBench Skill-Up Recipes:") .. "|r")
			for _, m in ipairs(recipes) do
				local c = "|cff40bf40"
				if m.difficulty == "optimal" then c = "|cffff8040"
				elseif m.difficulty == "medium" then c = "|cffffff00" end
				tooltip:AddLine(string.format("  %s%s|r (x%d)", c, m.name, m.needed), 0.9, 0.9, 0.9)
			end
		end
	end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddReagentTooltipLines)
elseif GameTooltip and GameTooltip.HookScript then
	GameTooltip:HookScript("OnTooltipSetItem", AddReagentTooltipLines)
end
