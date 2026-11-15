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

CraftForge.BetterBagsPlugin = {}

local plugin = CraftForge.BetterBagsPlugin
local L = CraftForge.L
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
				return CraftForge.db.profile.plugins.BetterBags.enabled
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.BetterBags.enabled = value
			end,
			width = "double",
			order = 1,
		},
		queueCategory = {
			type = "toggle",
			name = L["BETTERBAGS_QUEUE_CAT"],
			get = function()
				return CraftForge.db.profile.plugins.BetterBags.queueCategory
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.BetterBags.queueCategory = value
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
	categories:RegisterCategoryFunction("CraftForgeQueueReagents", function(data)
		local cfg = CraftForge.db and CraftForge.db.profile and CraftForge.db.profile.plugins and CraftForge.db.profile.plugins.BetterBags
		if not cfg or not cfg.enabled or not cfg.queueCategory then
			return nil
		end
		local itemID = data and data.itemInfo and data.itemInfo.itemID
		if itemID and CraftForge.db and CraftForge.db.realm and CraftForge.db.realm.reagentsInQueue then
			for _, reagents in pairs(CraftForge.db.realm.reagentsInQueue) do
				if reagents and reagents[itemID] and reagents[itemID] > 0 then
					return "CraftForge: " .. (L["Queue"] or "Queue")
				end
			end
		end
		return nil
	end)
end

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.BetterBags then
		CraftForge.db.profile.plugins.BetterBags = {
			enabled = true,
			queueCategory = true,
		}
	end
	CraftForge:AddPluginOptions(plugin.options)
	registerBetterBagsCategory()
end

function plugin.Update()
	registerBetterBagsCategory()
end

CraftForge:RegisterUpdatePlugin("BetterBagsPlugin")
