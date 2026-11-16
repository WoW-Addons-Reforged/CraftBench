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

CraftBench.GatherRoutesPlugin = {}

local plugin = CraftBench.GatherRoutesPlugin
local L = CraftBench.L

plugin.options = {
	type = "group",
	name = "GatherRoutes",
	order = 2,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.GatherRoutes.enabled
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.GatherRoutes.enabled = value
			end,
			width = "double",
			order = 1,
		},
	},
}

function plugin.OnInitialize()
	if not CraftBench.db.profile.plugins.GatherRoutes then
		CraftBench.db.profile.plugins.GatherRoutes = {}
		CraftBench.db.profile.plugins.GatherRoutes.enabled = true
	end
	CraftBench:AddPluginOptions(plugin.options)
end

function plugin.OpenRouteUI()
	if not CraftBench.db.profile.plugins.GatherRoutes or not CraftBench.db.profile.plugins.GatherRoutes.enabled then
		return false
	end
	local gr = _G.GatherRoutes
	if not gr then return false end
	if gr.ToggleRoutesWindow then
		gr:ToggleRoutesWindow()
		return true
	elseif gr.ShowRoutesWindow then
		gr:ShowRoutesWindow()
		return true
	elseif _G.SlashCmdList and _G.SlashCmdList["GATHERROUTES"] then
		_G.SlashCmdList["GATHERROUTES"]("")
		return true
	end
	return false
end
