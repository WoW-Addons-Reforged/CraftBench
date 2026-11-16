----------------------------------------------------------
-- CraftBench - Gathering Professions (Herb/Mine/Skin)  --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftBench = _G.CraftBench or LibStub("AceAddon-3.0"):GetAddon("CraftBench")

CraftBench.Gathering = CraftBench.Gathering or {}
local Gathering = CraftBench.Gathering

Gathering.DATA = {
	herbalism = {
		{ name = "Silverleaf / Peacebloom", req = 1, yellow = 50, green = 75, grey = 100, zones = "Starter Zones (Elwynn, Durotar, Tirisfal, Teldrassil, Dun Morogh, Mulgore)" },
		{ name = "Earthroot", req = 15, yellow = 65, green = 90, grey = 115, zones = "Starter Zones, Westfall, Loch Modan, Barrens, Silverpine" },
		{ name = "Mageroyal / Briarthorn", req = 50, yellow = 100, green = 125, grey = 150, zones = "Westfall, Redridge, Darkshore, Barrens, Silverpine, Loch Modan" },
		{ name = "Stranglekelp", req = 85, yellow = 135, green = 160, grey = 185, zones = "Coasts: Westfall, Darkshore, Barrens, Wetlands, Hillsbrad" },
		{ name = "Bruiseweed", req = 100, yellow = 150, green = 175, grey = 200, zones = "Ashenvale, Stonetalon, Wetlands, Duskwood, Hillsbrad" },
		{ name = "Wild Steelbloom", req = 115, yellow = 165, green = 190, grey = 215, zones = "Stonetalon, Stranglethorn, Arathi, Badlands, Thousand Needles" },
		{ name = "Kingsblood", req = 125, yellow = 175, green = 200, grey = 225, zones = "Ashenvale, Duskwood, Wetlands, Hillsbrad, Stranglethorn, Swamp of Sorrows" },
		{ name = "Liferoot", req = 150, yellow = 200, green = 225, grey = 250, zones = "Stranglethorn, Wetlands, Dustwallow, Arathi, Alterac, Hinterlands" },
		{ name = "Fadeleaf / Goldthorn", req = 160, yellow = 210, green = 235, grey = 260, zones = "Stranglethorn, Swamp of Sorrows, Arathi, Dustwallow, Badlands" },
		{ name = "Khadgar's Whisker", req = 185, yellow = 235, green = 260, grey = 285, zones = "Stranglethorn, Swamp of Sorrows, Hinterlands, Feralas, Dustwallow" },
		{ name = "Firebloom / Purple Lotus", req = 205, yellow = 255, green = 280, grey = 305, zones = "Tanaris, Searing Gorge, Blasted Lands, Badlands, Azshara" },
		{ name = "Sungrass / Blindweed", req = 230, yellow = 280, green = 305, grey = 330, zones = "Feralas, Hinterlands, Azshara, Un'Goro, Felwood, Swamp of Sorrows" },
		{ name = "Gromsblood / Golden Sansam", req = 250, yellow = 300, green = 325, grey = 350, zones = "Felwood, Blasted Lands, Ashenvale, Un'Goro, Azshara, Burning Steppes" },
		{ name = "Dreamfoil / Mountain Silversage", req = 270, yellow = 320, green = 345, grey = 375, zones = "Un'Goro, Felwood, Winterspring, Eastern/Western Plaguelands, Silithus" },
		{ name = "Plaguebloom / Icecap", req = 285, yellow = 335, green = 360, grey = 375, zones = "Eastern & Western Plaguelands, Winterspring" },
	},
	mining = {
		{ name = "Copper Vein", req = 1, yellow = 50, green = 75, grey = 100, zones = "Starter Zones, Westfall, Barrens, Darkshore, Loch Modan" },
		{ name = "Tin Vein", req = 65, yellow = 115, green = 140, grey = 165, zones = "Redridge, Duskwood, Wetlands, Hillsbrad, Barrens, Ashenvale" },
		{ name = "Silver Vein", req = 75, yellow = 125, green = 150, grey = 175, zones = "Redridge, Wetlands, Ashenvale, Stranglethorn, Thousand Needles" },
		{ name = "Iron Deposit", req = 125, yellow = 175, green = 200, grey = 225, zones = "Thousand Needles, Arathi, Stranglethorn, Badlands, Desolace, Swamp of Sorrows" },
		{ name = "Gold Vein", req = 155, yellow = 205, green = 230, grey = 255, zones = "Arathi, Badlands, Stranglethorn, Desolace, Feralas, Hinterlands" },
		{ name = "Mithril Deposit", req = 175, yellow = 225, green = 250, grey = 275, zones = "Badlands, Tanaris, Hinterlands, Searing Gorge, Felwood, Feralas" },
		{ name = "Truesilver Deposit", req = 230, yellow = 280, green = 305, grey = 330, zones = "Hinterlands, Un'Goro, Felwood, Burning Steppes, Winterspring, Azshara" },
		{ name = "Small Thorium Vein", req = 245, yellow = 295, green = 320, grey = 345, zones = "Un'Goro Crater, Felwood, Azshara, Burning Steppes, Western Plaguelands" },
		{ name = "Rich Thorium Vein", req = 275, yellow = 325, green = 350, grey = 375, zones = "Winterspring, Eastern Plaguelands, Silithus, Burning Steppes, Un'Goro" },
	},
	skinning = {
		{ name = "Beasts Lv 1-10 (Ruined / Light Leather)", req = 1, yellow = 50, green = 75, grey = 100, zones = "All Starter Zones" },
		{ name = "Beasts Lv 11-20 (Light / Medium Leather)", req = 50, yellow = 100, green = 125, grey = 150, zones = "Westfall, Loch Modan, Barrens, Darkshore, Silverpine" },
		{ name = "Beasts Lv 21-30 (Medium / Heavy Leather)", req = 100, yellow = 150, green = 175, grey = 200, zones = "Ashenvale, Duskwood, Wetlands, Hillsbrad, Thousand Needles" },
		{ name = "Beasts Lv 31-40 (Heavy Leather)", req = 150, yellow = 200, green = 225, grey = 250, zones = "Stranglethorn, Desolace, Dustwallow, Arathi, Badlands" },
		{ name = "Beasts Lv 41-50 (Thick Leather)", req = 205, yellow = 255, green = 280, grey = 305, zones = "Tanaris, Feralas, Hinterlands, Searing Gorge, Azshara" },
		{ name = "Beasts Lv 51-60 (Rugged Leather)", req = 255, yellow = 300, green = 325, grey = 350, zones = "Un'Goro Crater, Felwood, Winterspring, Silithus, Plaguelands" },
	},
}

local SKILL_NAMES = {
	herbalism = { "Herbalism", "Kräuterkunde" },
	mining = { "Mining", "Bergbau" },
	skinning = { "Skinning", "Kürschnerei" },
}

function Gathering:GetSkillRank(kind)
	local targets = SKILL_NAMES[kind]
	if not targets then return 0, 0 end
	if GetNumSkillLines and GetSkillLineInfo then
		local n = GetNumSkillLines() or 0
		for i = 1, n do
			local name, isHeader, _, rank, _, modifier, maxRank = GetSkillLineInfo(i)
			if not isHeader and name then
				for _, t in ipairs(targets) do
					if name == t then
						return (rank or 0) + (modifier or 0), maxRank or 300
					end
				end
			end
		end
	end
	if GetProfessions and GetProfessionInfo then
		local p1, p2 = GetProfessions()
		for _, idx in ipairs({ p1, p2 }) do
			if idx then
				local name, _, rank, maxRank = GetProfessionInfo(idx)
				if name then
					for _, t in ipairs(targets) do
						if name == t then
							return rank or 0, maxRank or 300
						end
					end
				end
			end
		end
	end
	return 0, 0
end

function Gathering:GetDifficultyColor(node, rank)
	if rank < node.req then
		return "|cffff3333", "locked"
	elseif rank < node.yellow then
		return "|cffff8040", "orange"
	elseif rank < node.green then
		return "|cffffff00", "yellow"
	elseif rank < node.grey then
		return "|cff40bf40", "green"
	end
	return "|cff808080", "grey"
end

local function isSafeString(val)
	if type(val) ~= "string" then return false end
	if _G.issecretvalue and _G.issecretvalue(val) then return false end
	if _G.canaccessvalue and not _G.canaccessvalue(val) then return false end
	local ok, nonEmpty = pcall(function() return val ~= "" end)
	return ok and nonEmpty
end

local function ColorGatheringNodeTooltip(tooltip)
	if not tooltip or tooltip ~= GameTooltip then return end
	local owner = tooltip.GetOwner and tooltip:GetOwner()
	if owner and owner ~= UIParent and owner ~= WorldFrame then return end
	if (tooltip.GetItem and tooltip:GetItem()) or (tooltip.GetUnit and tooltip:GetUnit()) then return end

	for i = 2, math.min(4, tooltip:NumLines() or 0) do
		local lineObj = _G["GameTooltipTextLeft" .. i]
		local okText, text = pcall(function() return lineObj and lineObj:GetText() end)
		if okText and isSafeString(text) then
			local req = tonumber(string.match(text, "%((%d+)%)"))
			local kind
			if string.find(text, "Herbalism", 1, true) or string.find(text, "Kräuterkunde", 1, true) then
				kind = "herbalism"
			elseif string.find(text, "Mining", 1, true) or string.find(text, "Bergbau", 1, true) then
				kind = "mining"
			end
			if kind and req then
				local rank = Gathering:GetSkillRank(kind)
				local r, g, b
				if rank < req then
					r, g, b = 1.0, 0.2, 0.2
				elseif rank < req + 25 then
					r, g, b = 1.0, 0.5, 0.25
				elseif rank < req + 50 then
					r, g, b = 1.0, 1.0, 0.0
				elseif rank < req + 100 then
					r, g, b = 0.25, 0.75, 0.25
				else
					r, g, b = 0.5, 0.5, 0.5
				end
				lineObj:SetTextColor(r, g, b)
				return
			end
		end
	end
end

if GameTooltip and GameTooltip.HookScript then
	GameTooltip:HookScript("OnShow", ColorGatheringNodeTooltip)
end
