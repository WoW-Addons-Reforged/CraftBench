local addonName, addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("CraftBench") -- for DebugAids.lua
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

CraftBench.BetterBagsPlugin = {}

local plugin = CraftBench.BetterBagsPlugin
local L = CraftBench.L
local categoryRegistered = false

plugin.options = {
	type = "group",
	name = "BetterBags",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.BetterBags.enabled
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.BetterBags.enabled = value
			end,
			width = "double",
			order = 1,
		},
		queueCategory = {
			type = "toggle",
			name = L["BETTERBAGS_QUEUE_CAT"],
			get = function()
				return CraftBench.db.profile.plugins.BetterBags.queueCategory
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.BetterBags.queueCategory = value
			end,
			width = "double",
			order = 2,
		},
	},
}

local function registerBetterBagsCategory()
	if categoryRegistered then return end
	local AceAddon = LibStub and LibStub("AceAddon-3.0", true)
	local bb = AceAddon and AceAddon:GetAddon("BetterBags", true)
	if not bb or not bb.GetModule then return end
	local ok, categories = pcall(bb.GetModule, bb, "Categories", true)
	if not ok or not categories or not categories.RegisterCategoryFunction then return end

	categoryRegistered = true
	categories:RegisterCategoryFunction("CraftBenchQueueReagents", function(data)
		local cfg = CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.plugins and CraftBench.db.profile.plugins.BetterBags
		if not cfg or not cfg.enabled or not cfg.queueCategory then
			return nil
		end
		local itemID = data and data.itemInfo and data.itemInfo.itemID
		if itemID and CraftBench.db and CraftBench.db.realm and CraftBench.db.realm.reagentsInQueue then
			for _, reagents in pairs(CraftBench.db.realm.reagentsInQueue) do
				if reagents and reagents[itemID] and reagents[itemID] > 0 then
					return "CraftBench: " .. (L["Queue"] or "Queue")
				end
			end
		end
		return nil
	end)
end

function plugin.OnInitialize()
	if not CraftBench.db.profile.plugins.BetterBags then
		CraftBench.db.profile.plugins.BetterBags = {
			enabled = true,
			queueCategory = true,
		}
	end
	CraftBench:AddPluginOptions(plugin.options)
	registerBetterBagsCategory()
end

function plugin.Update()
	registerBetterBagsCategory()
end

CraftBench:RegisterUpdatePlugin("BetterBagsPlugin")
