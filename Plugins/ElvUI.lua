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

CraftForge.ElvUIPlugin = {}

local plugin = CraftForge.ElvUIPlugin
local L = CraftForge.L
local skinned = false

plugin.options = {
	type = "group",
	name = "ElvUI",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftForge.db.profile.plugins.ElvUI.enabled
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.ElvUI.enabled = value
				if value and CraftForge.db.profile.plugins.ElvUI.skinEnabled then
					plugin:ApplySkin()
				elseif not value then
					DA.MARK3(L["ELVUI_SKIN_RELOAD"])
				end
			end,
			width = "double",
			order = 1,
		},
		skinEnabled = {
			type = "toggle",
			name = L["ELVUI_SKIN_ENABLED"],
			desc = L["ELVUI_SKIN_ENABLED_DESC"],
			get = function()
				return CraftForge.db.profile.plugins.ElvUI.skinEnabled
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.ElvUI.skinEnabled = value
				if value then
					plugin:ApplySkin()
				else
					DA.MARK3(L["ELVUI_SKIN_RELOAD"])
				end
			end,
			width = "double",
			order = 2,
		},
	},
}

function plugin:ApplySkin()
	if skinned then return end
	local profile = CraftForge.db and CraftForge.db.profile
	local cfg = profile and profile.plugins and profile.plugins.ElvUI
	if not cfg or not cfg.enabled or not cfg.skinEnabled then
		return
	end
	if not _G.ElvUI then return end
	local E = unpack(_G.ElvUI)
	if not E or not E.GetModule then return end
	local S = E:GetModule("Skins", true)
	if not S then return end
	if not CraftForgeFrame then return end

	skinned = true
	if S.HandleFrame then
		S:HandleFrame(CraftForgeFrame, true)
	end
	if S.HandleCloseButton and CraftForgeFrameCloseButton then
		S:HandleCloseButton(CraftForgeFrameCloseButton)
	end
	local buttons = {
		CraftForgeQueueButton,
		CraftForgeCreateButton,
		CraftForgeCreateAllButton,
		CraftForgeQueueAllButton,
		CraftForgeEmptyQueueButton,
		CraftForgeShoppingListButton,
		CraftForgeQueueLoadButton,
		CraftForgeQueueSaveButton,
		CraftForgeQueueDeleteButton,
		CraftForgeRecipeNotesButton,
		CraftForgeIgnoreListButton,
		CraftForgeQueueManagementButton,
	}
	for _, btn in ipairs(buttons) do
		if btn and S.HandleButton then
			S:HandleButton(btn)
		end
	end
	if S.HandleEditBox and CraftForgeSearchBox then
		S:HandleEditBox(CraftForgeSearchBox)
	end
	if S.HandleEditBox and CraftForgeItemCountInputBox then
		S:HandleEditBox(CraftForgeItemCountInputBox)
	end
	local dropdowns = {
		CraftForgeGroupDropdown,
		CraftForgeSortDropdown,
		CraftForgeFilterDropdown,
	}
	for _, dd in ipairs(dropdowns) do
		if dd and S.HandleDropDownBox then
			S:HandleDropDownBox(dd)
		end
	end
end

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.ElvUI then
		CraftForge.db.profile.plugins.ElvUI = {
			enabled = true,
			skinEnabled = false,
		}
	end
	CraftForge:AddPluginOptions(plugin.options)
end

function plugin.Update()
	plugin:ApplySkin()
end

CraftForge:RegisterUpdatePlugin("ElvUIPlugin")
