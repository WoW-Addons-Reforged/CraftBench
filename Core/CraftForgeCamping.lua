----------------------------------------------------------
-- CraftForge - WoW Forever Camping System              --
----------------------------------------------------------

local addonName, addonTable = ...
local CraftForge = _G.CraftForge or LibStub("AceAddon-3.0"):GetAddon("CraftForge")

CraftForge.Camping = CraftForge.Camping or {}
local Camping = CraftForge.Camping

local SKILL_NAMES = { "Camping", "Lagerbau" }

Camping.MILESTONES = {
	{ req = 1, name = "Basic Campfire / Kindling", desc = "Starter camp warmth & cooking fire" },
	{ req = 50, name = "Sturdy Bedroll / Traveler's Tent", desc = "Rested bonus & camp comfort" },
	{ req = 100, name = "Iron Cooking Spit / Field Lantern", desc = "Improved camp utility & lighting" },
	{ req = 150, name = "Reinforced Pavilion / Supply Crate", desc = "Group camp shelter & storage" },
	{ req = 225, name = "Expedition Camp / Hearthstone Brazier", desc = "Advanced field camp perks" },
	{ req = 300, name = "Masterwork Basecamp", desc = "Full Forever Camping mastery" },
}

function Camping:GetSkillRank()
	if GetNumSkillLines and GetSkillLineInfo then
		local n = GetNumSkillLines() or 0
		for i = 1, n do
			local name, isHeader, _, rank, _, modifier, maxRank = GetSkillLineInfo(i)
			if not isHeader and name then
				for _, t in ipairs(SKILL_NAMES) do
					if name == t then
						return (rank or 0) + (modifier or 0), maxRank or 300
					end
				end
			end
		end
	end
	return 0, 0
end

function Camping:GetStatusList()
	local rank, maxRank = self:GetSkillRank()
	local list = {}
	for _, m in ipairs(self.MILESTONES) do
		table.insert(list, {
			req = m.req,
			name = m.name,
			desc = m.desc,
			unlocked = rank >= m.req,
		})
	end
	return rank, maxRank, list
end
