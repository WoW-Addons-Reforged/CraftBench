----------------------------------------------------------
-- CraftBench - Recipe Watch (Pinned Material Goal HUD) --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")
local L = CraftBench.L

CraftBench.Watch = CraftBench.Watch or {}
local Watch = CraftBench.Watch

local function ensureDB()
	if not CraftBench.db then return nil end
	if not CraftBench.db.char.watchedRecipes then
		CraftBench.db.char.watchedRecipes = {}
	end
	return CraftBench.db.char.watchedRecipes
end

function Watch:IsWatched(recipeID)
	local db = ensureDB()
	return db and recipeID and db[recipeID] ~= nil
end

function Watch:ToggleRecipe(recipeID, targetCount)
	local db = ensureDB()
	if not db or not recipeID then return end
	if db[recipeID] then
		db[recipeID] = nil
	else
		local recipe = CraftBench.GetRecipe and CraftBench:GetRecipe(recipeID)
		local name = (recipe and recipe.name) or (CraftBench.GetRecipeName and CraftBench:GetRecipeName(recipeID)) or ("Recipe #" .. tostring(recipeID))
		local reagents = {}
		if recipe and recipe.reagentData then
			for i = 1, #recipe.reagentData do
				local r = recipe.reagentData[i]
				if r and r.reagentID and r.numNeeded then
					table.insert(reagents, {
						id = r.reagentID,
						need = r.numNeeded,
						name = (C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(r.reagentID)) or ("Item #" .. tostring(r.reagentID)),
					})
				end
			end
		end
		db[recipeID] = {
			recipeID = recipeID,
			name = name,
			tradeID = (recipe and recipe.tradeID) or CraftBench.currentTrade,
			count = math.max(1, tonumber(targetCount) or 1),
			reagents = reagents,
		}
	end
	if CraftBench.WatchUI and CraftBench.WatchUI.Refresh then
		CraftBench.WatchUI:Refresh(true)
	end
end

function Watch:AdjustCount(recipeID, delta)
	local db = ensureDB()
	if not db or not db[recipeID] then return end
	db[recipeID].count = math.max(1, (db[recipeID].count or 1) + delta)
	if CraftBench.WatchUI and CraftBench.WatchUI.Refresh then
		CraftBench.WatchUI:Refresh()
	end
end

function Watch:RemoveRecipe(recipeID)
	local db = ensureDB()
	if not db or not recipeID then return end
	db[recipeID] = nil
	if CraftBench.WatchUI and CraftBench.WatchUI.Refresh then
		CraftBench.WatchUI:Refresh()
	end
end

function Watch:GetWatchedList()
	local db = ensureDB()
	if not db then return {} end
	local list = {}
	for _, rec in pairs(db) do
		if type(rec) == "table" then
			local ready = true
			local lines = {}
			for _, r in ipairs(rec.reagents or {}) do
				local need = (r.need or 1) * (rec.count or 1)
				local have = 0
				if C_Item and C_Item.GetItemCount then
					if CraftBench.isRetail then
						have = C_Item.GetItemCount(r.id, true, false, true, true) or 0
					else
						have = C_Item.GetItemCount(r.id, false) or 0
					end
				end
				if have < need then ready = false end
				local itemName = (C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(r.id)) or r.name or ("Item #" .. tostring(r.id))
				table.insert(lines, {
					id = r.id,
					name = itemName,
					have = have,
					need = need,
					done = have >= need,
				})
			end
			table.insert(list, {
				recipeID = rec.recipeID,
				name = rec.name,
				count = rec.count or 1,
				ready = ready,
				reagents = lines,
			})
		end
	end
	table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
	return list
end

function Watch:PinCurrentOrByName(query)
	if query and query ~= "" then
		local q = string.lower(query)
		local player = CraftBench.currentPlayer or (CraftBench.unitName and CraftBench:unitName("player"))
		local trade = CraftBench.currentTrade
		if player and trade and CraftBench.GetNumSkills then
			local n = CraftBench:GetNumSkills(player, trade) or 0
			for i = 1, n do
				local skill = CraftBench:GetSkill(player, trade, i)
				if skill and skill.id and skill.id ~= 0 and skill.name and string.find(string.lower(skill.name), q, 1, true) then
					self:ToggleRecipe(skill.id, 1)
					return
				end
			end
		end
		CraftBench:Print(L["WATCH_NOT_FOUND"] or "No matching recipe found in current profession.")
	else
		if CraftBench.selectedSkill and CraftBench.GetSkill then
			local skill = CraftBench:GetSkill(CraftBench.currentPlayer, CraftBench.currentTrade, CraftBench.selectedSkill)
			if skill and skill.id and skill.id ~= 0 then
				self:ToggleRecipe(skill.id, 1)
				return
			end
		end
		if CraftBench.WatchUI and CraftBench.WatchUI.ToggleVisible then
			CraftBench.WatchUI:ToggleVisible()
		end
	end
end

local evt = CreateFrame("Frame")
evt:RegisterEvent("BAG_UPDATE_DELAYED")
evt:RegisterEvent("PLAYER_ENTERING_WORLD")
evt:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		if CraftBench.WatchUI and CraftBench.WatchUI.Initialize then
			CraftBench.WatchUI:Initialize()
		end
	elseif CraftBench.WatchUI and CraftBench.WatchUI.Refresh then
		CraftBench.WatchUI:Refresh()
	end
end)
