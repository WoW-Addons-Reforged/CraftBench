local addonName, addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("CraftForge") -- for DebugAids.lua
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

CraftForge.TomTomPlugin = {}

local plugin = CraftForge.TomTomPlugin
local L = CraftForge.L

plugin.options = {
	type = "group",
	name = "TomTom",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftForge.db.profile.plugins.TomTom.enabled
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.TomTom.enabled = value
			end,
			width = "double",
			order = 1,
		},
	},
}

function CraftForge:AddTomTomWaypointFromText(title, text)
	if not _G.TomTom or not _G.TomTom.AddWaypoint or not text then return false end
	local cfg = self.db and self.db.profile and self.db.profile.plugins and self.db.profile.plugins.TomTom
	if cfg and not cfg.enabled then return false end
	local x, y = text:match("(%d+%.?%d*)%s*,%s*(%d+%.?%d*)")
	x, y = tonumber(x), tonumber(y)
	if not x or not y or x <= 0 or x > 100 or y <= 0 or y > 100 then
		return false
	end
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not mapID then return false end
	_G.TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = title or "CraftForge", persistent = false, minimap = true, world = true })
	return true
end

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.TomTom then
		CraftForge.db.profile.plugins.TomTom = {
			enabled = true,
		}
	end
	CraftForge:AddPluginOptions(plugin.options)
end

function plugin.Update()
end

CraftForge:RegisterUpdatePlugin("TomTomPlugin")
