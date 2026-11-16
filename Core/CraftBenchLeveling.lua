----------------------------------------------------------
-- CraftBench - Smart Profession Leveling Planner       --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")

CraftBench.Leveling = CraftBench.Leveling or {}
local Leveling = CraftBench.Leveling

local DIFF_GAIN = {
	optimal = 1.0,
	medium = 0.5,
	easy = 0.25,
}

local DIFF_PRIORITY = {
	optimal = 1,
	medium = 2,
	easy = 3,
}

local function ensureLevelingDB()
	local prof = CraftBench.db and CraftBench.db.profile
	if not prof then return nil end
	if not prof.leveling then
		prof.leveling = {
			ignoredRecipes = {},
			freeGatheredMats = false,
		}
	end
	if not prof.leveling.ignoredRecipes then
		prof.leveling.ignoredRecipes = {}
	end
	return prof.leveling
end

function Leveling:IsFreeGatheredMats()
	local db = ensureLevelingDB()
	return db and db.freeGatheredMats == true or false
end

function Leveling:SetFreeGatheredMats(val)
	local db = ensureLevelingDB()
	if db then db.freeGatheredMats = val and true or false end
end

function Leveling:IgnoreRecipe(recipeID)
	local db = ensureLevelingDB()
	if db and recipeID then
		db.ignoredRecipes[recipeID] = true
	end
end

function Leveling:ClearIgnored()
	local db = ensureLevelingDB()
	if db then
		db.ignoredRecipes = {}
	end
end

function Leveling:GetIgnoredCount()
	local db = ensureLevelingDB()
	if not db then return 0 end
	local n = 0
	for _ in pairs(db.ignoredRecipes) do n = n + 1 end
	return n
end

local function isGatheredReagent(itemID)
	local PT = LibStub and LibStub("LibPeriodicTable-3.1", true)
	if not PT or not itemID then return false end
	return PT:ItemInSet(itemID, "Tradeskill.Mat.ByProfession.Herbalism")
		or PT:ItemInSet(itemID, "Tradeskill.Mat.ByProfession.Mining")
		or PT:ItemInSet(itemID, "Tradeskill.Mat.ByProfession.Skinning")
		or false
end

local function estimateRecipeCost(recipe)
	if not recipe or not recipe.reagentData or #recipe.reagentData == 0 then
		return 99999999
	end
	local freeGathered = Leveling:IsFreeGatheredMats()
	local total = 0
	for i = 1, #recipe.reagentData do
		local r = recipe.reagentData[i]
		if r and r.reagentID and r.numNeeded then
			if freeGathered and isGatheredReagent(r.reagentID) then
				-- Treated as 0g when player gathers materials themselves
			else
				local unitPrice = 0
				if CraftBench.GetItemMarketOrVendorPrice then
					unitPrice = CraftBench:GetItemMarketOrVendorPrice(r.reagentID) or 0
				end
				if unitPrice <= 0 then
					unitPrice = 100
				end
				total = total + unitPrice * r.numNeeded
			end
		end
	end
	return total
end

function Leveling:BuildPlan(currentSkill, targetSkill)
	local player = CraftBench.currentPlayer or (CraftBench.unitName and CraftBench:unitName("player"))
	local tradeID = CraftBench.currentTrade
	if not player or not tradeID or not CraftBench.GetNumSkills then
		return nil, "NO_PROFESSION"
	end

	local n = CraftBench:GetNumSkills(player, tradeID) or 0
	if n == 0 then
		return nil, "NO_RECIPES"
	end

	local db = ensureLevelingDB()
	local ignored = db and db.ignoredRecipes or {}
	local candidates = {}
	for i = 1, n do
		local skill = CraftBench:GetSkill(player, tradeID, i)
		if skill and skill.id and skill.id ~= 0 and not ignored[skill.id] and DIFF_GAIN[skill.difficulty] then
			local recipe = CraftBench:GetRecipe(skill.id)
			if recipe and recipe.reagentData and #recipe.reagentData > 0 then
				local cost = estimateRecipeCost(recipe)
				local gain = DIFF_GAIN[skill.difficulty]
				if CraftBench.GetSkillUpChance then
					local chance = CraftBench:GetSkillUpChance(recipe, currentSkill, skill.difficulty)
					if chance and chance > 0 then
						gain = chance
					end
				end
				table.insert(candidates, {
					recipeID = skill.id,
					name = skill.name or ("Recipe #" .. tostring(skill.id)),
					difficulty = skill.difficulty,
					priority = DIFF_PRIORITY[skill.difficulty] or 9,
					gain = gain,
					cost = cost,
					costPerPoint = cost / gain,
					recipe = recipe,
				})
			end
		end
	end

	if #candidates == 0 then
		return nil, "NO_UPGRADE_RECIPES"
	end

	table.sort(candidates, function(a, b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		end
		if a.costPerPoint ~= b.costPerPoint then
			return a.costPerPoint < b.costPerPoint
		end
		return (a.name or "") < (b.name or "")
	end)

	local cur = math.max(1, tonumber(currentSkill) or 1)
	local tgt = math.max(cur, tonumber(targetSkill) or cur)
	local pointsNeeded = tgt - cur
	if pointsNeeded <= 0 then
		return { steps = {}, reagents = {}, totalCost = 0, currentSkill = cur, targetSkill = tgt }
	end

	-- Pick best recipe(s) in chunks of up to 10 points per step
	local steps = {}
	local reagentTotals = {}
	local totalCost = 0
	local sim = cur
	local best = candidates[1]
	local craftsNeeded = math.ceil((tgt - sim) / best.gain)
	if craftsNeeded > 0 then
		table.insert(steps, {
			recipeID = best.recipeID,
			name = best.name,
			difficulty = best.difficulty,
			fromSkill = sim,
			toSkill = tgt,
			crafts = craftsNeeded,
			estCost = best.cost * craftsNeeded,
		})
		totalCost = totalCost + best.cost * craftsNeeded
		for _, r in ipairs(best.recipe.reagentData) do
			if r.reagentID and r.numNeeded then
				reagentTotals[r.reagentID] = (reagentTotals[r.reagentID] or 0) + r.numNeeded * craftsNeeded
			end
		end
	end

	local reagents = {}
	for itemID, need in pairs(reagentTotals) do
		local inBags = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemID, false)) or 0
		local inBoth = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(itemID, true, false, true, true)) or inBags
		local itemName = (C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(itemID)) or ("Item #" .. tostring(itemID))
		table.insert(reagents, {
			itemID = itemID,
			name = itemName,
			need = need,
			inBags = inBags,
			inBoth = inBoth,
			missing = math.max(0, need - (CraftBench.isForever and inBags or inBoth)),
		})
	end
	table.sort(reagents, function(a, b) return (a.name or "") < (b.name or "") end)

	return {
		steps = steps,
		reagents = reagents,
		totalCost = totalCost,
		currentSkill = cur,
		targetSkill = tgt,
		tradeID = tradeID,
	}
end

function Leveling:QueuePlan(plan)
	if not plan or not plan.steps or #plan.steps == 0 then return 0 end
	local queued = 0
	for _, step in ipairs(plan.steps) do
		if CraftBench.QueueCommand and CraftBench.QueueAppend then
			local cmd = CraftBench:QueueCommand(step.recipeID, step.crafts)
			if cmd then
				CraftBench:QueueAppend(cmd, true, false)
				queued = queued + 1
			end
		end
	end
	if queued > 0 and CraftBench.UpdateTradeSkillWindow then
		CraftBench:UpdateTradeSkillWindow()
	end
	return queued
end
