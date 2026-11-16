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

CraftBench.TSMPlugin = {}

local plugin = CraftBench.TSMPlugin
local L = CraftBench.L

plugin.options = {
	type = "group",
	name = "TSM",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftBench.db.profile.plugins.TSM.enabled
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.TSM.enabled = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1,
		},
		priceSource = {
			type = "select",
			name = L["TSM_PRICE_SOURCE"],
			values = {
				DBMarket = "DBMarket",
				DBMinBuyout = "DBMinBuyout",
				DBRegionMarketAvg = "DBRegionMarketAvg",
				DBHistorical = "DBHistorical",
			},
			get = function()
				return CraftBench.db.profile.plugins.TSM.priceSource or "DBMarket"
			end,
			set = function(_, value)
				CraftBench.db.profile.plugins.TSM.priceSource = value
				CraftBench:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 2,
		},
	},
}

function CraftBench:GetTSMPrice(itemID)
	if not itemID or not _G.TSM_API or not _G.TSM_API.GetCustomPriceValue then
		return nil
	end
	local cfg = self.db and self.db.profile and self.db.profile.plugins and self.db.profile.plugins.TSM
	if cfg and not cfg.enabled then
		return nil
	end
	local source = (cfg and cfg.priceSource) or "DBMarket"
	local ok, val = pcall(_G.TSM_API.GetCustomPriceValue, source, "i:" .. tostring(itemID))
	if ok and type(val) == "number" and val > 0 then
		return val
	end
	return nil
end

function plugin.GetExtraText(skill, recipe)
	local cfg = CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.plugins and CraftBench.db.profile.plugins.TSM
	if not cfg or not cfg.enabled or not _G.TSM_API then
		return
	end
	if not recipe or not recipe.itemID or recipe.itemID == 0 then
		return
	end
	local price = CraftBench:GetTSMPrice(recipe.itemID)
	if price and price > 0 and CraftBench.FormatMoneyFull then
		return "|cff66ccffTSM (" .. (cfg.priceSource or "DBMarket") .. "):|r", CraftBench:FormatMoneyFull(price, true)
	end
end

function plugin.OnInitialize()
	if not CraftBench.db.profile.plugins.TSM then
		CraftBench.db.profile.plugins.TSM = {
			enabled = true,
			priceSource = "DBMarket",
		}
	end
	CraftBench:AddPluginOptions(plugin.options)
end

CraftBench:RegisterDisplayDetailPlugin("TSMPlugin")
