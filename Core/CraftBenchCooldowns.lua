----------------------------------------------------------
-- CraftBench - Account-Wide Crafting Cooldown Tracker --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")
local L = CraftBench.L

CraftBench.Cooldowns = CraftBench.Cooldowns or {}
local Cooldowns = CraftBench.Cooldowns

local function ensureDB()
	if not CraftBench.db then return nil end
	if not CraftBench.db.global.cooldownsDB then
		CraftBench.db.global.cooldownsDB = {}
	end
	return CraftBench.db.global.cooldownsDB
end

local function playerKey()
	local name = UnitName and UnitName("player") or "Unknown"
	local realm = GetRealmName and GetRealmName() or "Realm"
	return name .. "-" .. realm
end

function Cooldowns:GetAllEntries(onlyReady)
	local db = ensureDB()
	if not db then return {} end
	local now = time and time() or 0
	local list = {}
	for pKey, recipes in pairs(db) do
		if type(recipes) == "table" then
			for recipeID, rec in pairs(recipes) do
				if type(rec) == "table" then
					local remaining = (rec.expiresAt or 0) - now
					if remaining < 0 then remaining = 0 end
					if (not onlyReady) or remaining == 0 then
						table.insert(list, {
							player = pKey,
							recipeID = recipeID,
							name = rec.name or ("Recipe #" .. tostring(recipeID)),
							tradeID = rec.tradeID,
							expiresAt = rec.expiresAt or 0,
							remaining = remaining,
							ready = remaining <= 0,
						})
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		if a.ready ~= b.ready then
			return a.ready
		end
		if a.remaining ~= b.remaining then
			return a.remaining < b.remaining
		end
		return (a.name or "") < (b.name or "")
	end)
	return list
end

function Cooldowns:GetReadyCount()
	local entries = self:GetAllEntries(true)
	return #entries
end

function Cooldowns:ScanCurrentProfession()
	local db = ensureDB()
	if not db then return end
	local pKey = playerKey()
	db[pKey] = db[pKey] or {}
	local tradeID = CraftBench.currentTrade
	local player = CraftBench.currentPlayer or (CraftBench.unitName and CraftBench:unitName("player"))
	if not tradeID or not player or not CraftBench.GetNumSkills then return end

	local n = CraftBench:GetNumSkills(player, tradeID) or 0
	local now = time and time() or 0
	for i = 1, n do
		local skill = CraftBench:GetSkill(player, tradeID, i)
		if skill and skill.id and skill.id ~= 0 then
			local cd
			if C_TradeSkillUI and C_TradeSkillUI.GetRecipeCooldown then
				local rem = C_TradeSkillUI.GetRecipeCooldown(skill.id)
				if rem and rem > 0 then
					cd = rem
				end
			elseif GetTradeSkillCooldown then
				local rem = GetTradeSkillCooldown(i)
				if rem and rem > 0 then
					cd = rem
				end
			end
			if cd and cd > 60 then
				db[pKey][skill.id] = {
					name = skill.name or ("Recipe #" .. tostring(skill.id)),
					tradeID = tradeID,
					expiresAt = now + math.floor(cd),
					updatedAt = now,
				}
			elseif db[pKey][skill.id] and (db[pKey][skill.id].expiresAt or 0) <= now then
				db[pKey][skill.id].expiresAt = now
			end
		end
	end
end

function Cooldowns:ClearExpired()
	local db = ensureDB()
	if not db then return end
	local now = time and time() or 0
	for _, recipes in pairs(db) do
		if type(recipes) == "table" then
			for recipeID, rec in pairs(recipes) do
				if type(rec) == "table" and (rec.expiresAt or 0) <= now then
					recipes[recipeID] = nil
				end
			end
		end
	end
end

function Cooldowns:NotifyReadyOnLogin()
	if CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.cooldownNotify == false then
		return
	end
	local ready = self:GetAllEntries(true)
	if #ready > 0 then
		CraftBench:Print(string.format(L["CD_READY_LOGIN_FMT"] or "%d crafting cooldown(s) are ready! (/cb cd)", #ready))
	end
end

local evtFrame = CreateFrame("Frame")
evtFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
local function tryRegisterEvent(ev)
	if C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(ev) then
		return
	end
	pcall(evtFrame.RegisterEvent, evtFrame, ev)
end
tryRegisterEvent("TRADE_SKILL_LIST_UPDATE")
tryRegisterEvent("TRADE_SKILL_DETAILS_UPDATE")
tryRegisterEvent("TRADE_SKILL_UPDATE")
local loginNotified = false
evtFrame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		if not loginNotified then
			loginNotified = true
			if C_Timer and C_Timer.After then
				C_Timer.After(4, function()
					Cooldowns:NotifyReadyOnLogin()
				end)
			end
		end
	else
		Cooldowns:ScanCurrentProfession()
	end
end)
