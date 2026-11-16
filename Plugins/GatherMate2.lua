--[[

CraftForge: A tradeskill window replacement.

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

CraftForge.GatherMate2Plugin = {}

local plugin = CraftForge.GatherMate2Plugin
local L = CraftForge.L

plugin.options = {
	type = "group",
	name = "GatherMate2",
	order = 2,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftForge.db.profile.plugins.GatherMate2.enabled
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.GatherMate2.enabled = value
			end,
			width = "double",
			order = 1,
		},
	},
}

local KIND_TO_GM = {
	herbalism = "Herb Gathering",
	mining = "Mining",
}

local function GetGatherMate()
	if _G.GatherMate2 then return _G.GatherMate2 end
	if LibStub then
		local gm = LibStub("AceAddon-3.0", true)
		if gm then return gm:GetAddon("GatherMate2", true) end
	end
	return nil
end

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.GatherMate2 then
		CraftForge.db.profile.plugins.GatherMate2 = {}
		CraftForge.db.profile.plugins.GatherMate2.enabled = true
	end
	CraftForge:AddPluginOptions(plugin.options)
end

function plugin.FindBestZoneAndNode(searchName, gatherKind)
	if not CraftForge.db.profile.plugins.GatherMate2 or not CraftForge.db.profile.plugins.GatherMate2.enabled then
		return nil
	end
	local gm = GetGatherMate()
	local gmType = KIND_TO_GM[gatherKind]
	if not gm or not gmType or not gm.gmdbs or not gm.gmdbs[gmType] then
		return nil
	end

	local needle = string.lower(searchName or "")
	if needle == "" then return nil end

	-- Split combined entries like "Silverleaf / Peacebloom"
	local terms = {}
	for part in string.gmatch(needle, "[^/]+") do
		local trimmed = strtrim(part)
		if trimmed ~= "" then
			terms[#terms + 1] = trimmed
		end
	end

	local matchingNodeIDs = {}
	if gm.nodeIDs and gm.nodeIDs[gmType] then
		for nodeName, nodeID in pairs(gm.nodeIDs[gmType]) do
			local lname = string.lower(nodeName)
			for _, term in ipairs(terms) do
				if string.find(lname, term, 1, true) or string.find(term, lname, 1, true) then
					matchingNodeIDs[nodeID] = nodeName
					break
				end
			end
		end
	end

	local totalCount = 0
	local bestZone, bestCount, bestCoord, bestTitle = nil, 0, nil, nil
	local playerMap = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")

	for mapID, coords in pairs(gm.gmdbs[gmType]) do
		if type(coords) == "table" then
			local zoneMatches = 0
			local firstCoord, firstTitle
			for coord, nodeID in pairs(coords) do
				if matchingNodeIDs[nodeID] then
					zoneMatches = zoneMatches + 1
					if not firstCoord then
						firstCoord = coord
						firstTitle = matchingNodeIDs[nodeID]
					end
				end
			end
			if zoneMatches > 0 then
				totalCount = totalCount + zoneMatches
				local isCurrent = (playerMap and mapID == playerMap)
				if isCurrent or (not bestZone) or (zoneMatches > bestCount and bestZone ~= playerMap) then
					bestZone = mapID
					bestCount = zoneMatches
					bestCoord = firstCoord
					bestTitle = firstTitle
				end
			end
		end
	end

	if totalCount == 0 or not bestZone or not bestCoord or not gm.DecodeLoc then
		return nil
	end

	local x, y = gm:DecodeLoc(bestCoord)
	local zoneInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(bestZone)
	return {
		addon = "GatherMate2",
		totalCount = totalCount,
		zoneCount = bestCount,
		mapID = bestZone,
		zoneName = zoneInfo and zoneInfo.name or ("Map #" .. tostring(bestZone)),
		x = x,
		y = y,
		title = bestTitle or searchName,
	}
end
