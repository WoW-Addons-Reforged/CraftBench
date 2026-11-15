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

CraftForge.BaganatorPlugin = {}

local plugin = CraftForge.BaganatorPlugin
local L = CraftForge.L

local cornerWidgetRegistered = false

plugin.options = {
	type = "group",
	name = "Baganator",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftForge.db.profile.plugins.Baganator.enabled
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.Baganator.enabled = value
				CraftForge:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1,
		},
		showQueueCorner = {
			type = "toggle",
			name = L["Highlight queued reagents in Baganator"],
			get = function()
				return CraftForge.db.profile.plugins.Baganator.showQueueCorner
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.Baganator.showQueueCorner = value
				if Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh then
					Baganator.API.RequestItemButtonsRefresh()
				end
			end,
			width = "double",
			order = 2,
		},
	},
}

local function isItemQueuedReagent(itemID)
	if not itemID or not CraftForge.db or not CraftForge.db.realm or not CraftForge.db.realm.reagentsInQueue then
		return false
	end
	local q = CraftForge.db.realm.reagentsInQueue[CraftForge.currentPlayer]
	return q and q[itemID] and q[itemID] > 0
end

local function registerCornerWidget()
	if cornerWidgetRegistered then return end
	if not Baganator or not Baganator.API or not Baganator.API.RegisterCornerWidget then return end
	cornerWidgetRegistered = true

	Baganator.API.RegisterCornerWidget("CraftForge Queue", "craftforge_queue",
		function(cornerFrame, details)
			if not CraftForge.db or not CraftForge.db.profile or not CraftForge.db.profile.plugins or not CraftForge.db.profile.plugins.Baganator then
				return false
			end
			local cfg = CraftForge.db.profile.plugins.Baganator
			if not cfg.enabled or not cfg.showQueueCorner then
				return false
			end
			return isItemQueuedReagent(details and details.itemID) and true or false
		end,
		function(itemButton)
			local tex = itemButton:CreateTexture(nil, "OVERLAY")
			tex:SetSize(14, 14)
			tex:SetTexture("Interface\\Icons\\Trade_Engineering")
			tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			return tex
		end,
		{ corner = "top_left", priority = 1 }
	)
end

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.Baganator then
		CraftForge.db.profile.plugins.Baganator = {
			enabled = true,
			showQueueCorner = true,
		}
	end
	if CraftForge.db.profile.plugins.Baganator.enabled == nil then
		CraftForge.db.profile.plugins.Baganator.enabled = true
	end
	if CraftForge.db.profile.plugins.Baganator.showQueueCorner == nil then
		CraftForge.db.profile.plugins.Baganator.showQueueCorner = true
	end

	CraftForge:AddPluginOptions(plugin.options)
	registerCornerWidget()
end

function plugin.GetExtraText(skill, recipe)
	local label, text = "", ""
	if not recipe or not CraftForge.db.profile.plugins.Baganator or not CraftForge.db.profile.plugins.Baganator.enabled then
		return label, text
	end
	if not Syndicator or not Syndicator.API or not Syndicator.API.GetInventoryInfoByItemID or not recipe.itemID then
		return label, text
	end
	local info = Syndicator.API.GetInventoryInfoByItemID(recipe.itemID, true, true)
	if not info then
		return label, text
	end
	local total = 0
	if type(info.characters) == "table" then
		for _, charData in ipairs(info.characters) do
			total = total + (charData.bags or 0) + (charData.bank or 0) + (charData.mail or 0) + (charData.equipped or 0)
		end
	end
	if type(info.guilds) == "table" then
		for _, guildData in ipairs(info.guilds) do
			total = total + (guildData.bank or 0)
		end
	end
	if total > 0 then
		label = "|cff88ccffSyndicator Total:|r"
		text = tostring(total)
	end
	return label, text
end

CraftForge:RegisterDisplayDetailPlugin("BaganatorPlugin")
