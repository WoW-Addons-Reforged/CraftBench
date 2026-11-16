--[[

CraftBench: A tradeskill window replacement.

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

CraftBench.GathererReforgedPlugin = {}

local plugin = CraftBench.GathererReforgedPlugin
local L = CraftBench.L

plugin.options = {
	type = "group",
	name = "GathererReforged",
	order = 2,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.GathererReforged.enabled
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.GathererReforged.enabled = value
			end,
			width = "double",
			order = 1,
		},
	},
}

local KIND_TO_GATHERER = {
	herbalism = "HERB",
	mining = "MINE",
}

function plugin.OnInitialize()
	if not CraftBench.db.profile.plugins.GathererReforged then
		CraftBench.db.profile.plugins.GathererReforged = {}
		CraftBench.db.profile.plugins.GathererReforged.enabled = true
	end
	CraftBench:AddPluginOptions(plugin.options)
end

function plugin.FindBestZoneAndNode(searchName, gatherKind)
	if not CraftBench.db.profile.plugins.GathererReforged or not CraftBench.db.profile.plugins.GathererReforged.enabled then
		return nil
	end
	local g = _G.Gatherer
	local gType = KIND_TO_GATHERER[gatherKind]
	if not g or not g.Storage or not gType then
		return nil
	end

	local needle = string.lower(searchName or "")
	if needle == "" then return nil end

	local terms = {}
	for part in string.gmatch(needle, "[^/]+") do
		local trimmed = strtrim(part)
		if trimmed ~= "" then
			terms[#terms + 1] = trimmed
		end
	end

	local HBD = LibStub and LibStub("HereBeDragons-2.0", true)
	local px, py, pMap
	if HBD and HBD.GetPlayerZonePosition then
		px, py, pMap = HBD:GetPlayerZonePosition()
	end

	local totalCount = 0
	local bestZoneToken, bestMapID, bestCount, bestX, bestY, bestTitle, bestDist = nil, nil, 0, nil, nil, nil, nil
	local playerMap = pMap or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))

	if not g.Storage.GetAreaIndices or not g.Storage.ZoneGatherNames then
		return nil
	end

	for _, zoneToken in g.Storage.GetAreaIndices() do
		local matchedGatherIDs = {}
		for _, gatherID, gatherType in g.Storage.ZoneGatherNames(zoneToken) do
			if gatherType == gType then
				local nodeName = (g.Util and g.Util.GetNodeName and g.Util.GetNodeName(gatherID)) or tostring(gatherID)
				local lname = string.lower(nodeName)
				for _, term in ipairs(terms) do
					if string.find(lname, term, 1, true) or string.find(term, lname, 1, true) then
						matchedGatherIDs[gatherID] = nodeName
						break
					end
				end
			end
		end

		if next(matchedGatherIDs) and g.Storage.ZoneGatherNodes and g.Storage.GetNodeGatherNames then
			local mapID = g.ZoneTokens and g.ZoneTokens.GetZoneMapID and g.ZoneTokens.GetZoneMapID(zoneToken)
			local zoneMatches = 0
			local closestX, closestY, closestTitle, closestDist
			for index, xPos, yPos in g.Storage.ZoneGatherNodes(zoneToken, gType) do
				for _, gatherID in g.Storage.GetNodeGatherNames(zoneToken, gType, index) do
					if matchedGatherIDs[gatherID] then
						zoneMatches = zoneMatches + 1
						local d
						if HBD and HBD.GetZoneDistance and px and py and pMap and mapID and xPos and yPos then
							d = HBD:GetZoneDistance(pMap, px, py, mapID, xPos, yPos)
						end
						if not closestX or (d and (not closestDist or d < closestDist)) then
							closestX, closestY = xPos, yPos
							closestTitle = matchedGatherIDs[gatherID]
							closestDist = d
						end
						break
					end
				end
			end
			if zoneMatches > 0 then
				totalCount = totalCount + zoneMatches
				local betterByDist = closestDist and (not bestDist or closestDist < bestDist)
				local isCurrent = (playerMap and mapID == playerMap)
				if betterByDist or (not bestDist and (isCurrent or not bestZoneToken or (zoneMatches > bestCount and bestMapID ~= playerMap))) then
					bestZoneToken = zoneToken
					bestMapID = mapID
					bestCount = zoneMatches
					bestX, bestY = closestX, closestY
					bestTitle = closestTitle
					bestDist = closestDist
				end
			end
		end
	end

	if totalCount == 0 or not bestX or not bestY then
		return nil
	end

	local zoneInfo = bestMapID and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(bestMapID)
	return {
		addon = "GathererReforged",
		totalCount = totalCount,
		zoneCount = bestCount,
		mapID = bestMapID,
		zoneName = (zoneInfo and zoneInfo.name) or tostring(bestZoneToken),
		x = bestX,
		y = bestY,
		dist = bestDist,
		title = bestTitle or searchName,
	}
end
