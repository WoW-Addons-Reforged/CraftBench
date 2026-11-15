local addonName,addonTable = ...
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

local L = CraftForge.L

local isRetail = CraftForge.isRetail
local isForever = CraftForge.isForever

--
-- Inspired by Kaliel's Tracker
--
StaticPopupDialogs["CRAFTFORGE_Version"] = {
	text = "CraftForge - Version",
	button2 = CLOSE,
	hasEditBox = true,
	editBoxWidth = 300,
	EditBoxOnEnterPressed = function(self)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	OnShow = function(self)
        local textFrame = self.Text or self.text
        local editBox = self.EditBox or self.editBox
		local version = textFrame.text_arg1
 		editBox:SetText(version)
        editBox:SetFocus()
        editBox:HighlightText()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true
}

--
-- Pop up a dialog with a Wowhead URL
--
function CraftForge:ShowVersion()
	DA.DEBUG(0,"ShowVersion()")
	local wowVersion,wowBuild = GetBuildInfo();
	local text = "CraftForge "..tostring(CraftForge.version).." on "..tostring(wowVersion).."."..tostring(wowBuild)..", "..tostring(GetLocale())
	StaticPopup_Show("CRAFTFORGE_Version", text)
end

--
-- All the options that we allow the user to control.
--
CraftForge.options =
{
	handler = CraftForge,
	type = 'group',
	args = {
		features = {
			type = 'group',
			name = L["Features"],
			desc = L["FEATURESDESC"],
			order = 1,
			args = {
				header = {
					type = "header",
					name = L["CraftForge Trade Skills"].." "..CraftForge.version,
					order = 2
				},
				use_first_name_only = {
					hidden = CraftForge.isRetail,
					type = "toggle",
					name = L["USEFIRSTONLYNAME"],
					desc = L["USEFIRSTONLYDESC"],
					get = function()
						return CraftForge.db.global.useFirstNameOnly
					end,
					set = function(self,value)
						CraftForge.db.global.useFirstNameOnly = value
					end,
					width = "full",
					order = 3
				},
				vendor_buy_button = {
					type = "toggle",
					name = L["VENDORBUYBUTTONNAME"],
					desc = L["VENDORBUYBUTTONDESC"],
					get = function()
						return CraftForge.db.profile.vendor_buy_button
					end,
					set = function(self,value)
						CraftForge.db.profile.vendor_buy_button = value
					end,
					width = "full",
					order = 12
				},
				vendor_auto_buy = {
					type = "toggle",
					name = L["VENDORAUTOBUYNAME"],
					desc = L["VENDORAUTOBUYDESC"],
					get = function()
						return CraftForge.db.profile.vendor_auto_buy
					end,
					set = function(self,value)
						CraftForge.db.profile.vendor_auto_buy = value
					end,
					width = "full",
					order = 13
				},
				show_item_notes_tooltip = {
					type = "toggle",
					name = L["SHOWITEMNOTESTOOLTIPNAME"],
					desc = L["SHOWITEMNOTESTOOLTIPDESC"],
					get = function()
						return CraftForge.db.profile.show_item_notes_tooltip
					end,
					set = function(self,value)
						CraftForge.db.profile.show_item_notes_tooltip = value
					end,
					width = "full",
					order = 14
				},
				show_crafters_tooltip = {
					type = "toggle",
					name = L["SHOWCRAFTERSTOOLTIPNAME"],
					desc = L["SHOWCRAFTERSTOOLTIPDESC"],
					get = function()
						return CraftForge.db.profile.show_crafters_tooltip
					end,
					set = function(self,value)
						CraftForge.db.profile.show_crafters_tooltip = value
					end,
					width = "full",
					order = 15
				},
				show_detailed_recipe_tooltip = {
					type = "toggle",
					name = L["SHOWDETAILEDRECIPETOOLTIPNAME"],
					desc = L["SHOWDETAILEDRECIPETOOLTIPDESC"],
					get = function()
						return CraftForge.db.profile.show_detailed_recipe_tooltip
					end,
					set = function(self,value)
						CraftForge.db.profile.show_detailed_recipe_tooltip = value
					end,
					width = "full",
					order = 16
				},
				display_full_tooltip = {
					type = "toggle",
					name = L["SHOWFULLTOOLTIPNAME"],
					desc = L["SHOWFULLTOOLTIPDESC"],
					get = function()
						return CraftForge.db.profile.display_full_tooltip
					end,
					set = function(self,value)
						CraftForge.db.profile.display_full_tooltip = value
					end,
					width = "full",
					order = 17
				},
				display_item_tooltip = {
					type = "toggle",
					name = L["SHOWITEMTOOLTIPNAME"],
					desc = L["SHOWITEMTOOLTIPDESC"],
					get = function()
						return CraftForge.db.profile.display_item_tooltip
					end,
					set = function(self,value)
						CraftForge.db.profile.display_item_tooltip = value
					end,
					width = "full",
					order = 18
				},
				link_craftable_reagents = {
					type = "toggle",
					name = L["LINKCRAFTABLEREAGENTSNAME"],
					desc = L["LINKCRAFTABLEREAGENTSDESC"],
					get = function()
						return CraftForge.db.profile.link_craftable_reagents
					end,
					set = function(self,value)
						CraftForge.db.profile.link_craftable_reagents = value
					end,
					width = "full",
					order = 19
				},
				queue_craftable_reagents = {
					type = "toggle",
					name = L["QUEUECRAFTABLEREAGENTSNAME"],
					desc = L["QUEUECRAFTABLEREAGENTSDESC"],
					get = function()
						return CraftForge.db.profile.queue_craftable_reagents
					end,
					set = function(self,value)
						CraftForge.db.profile.queue_craftable_reagents = value
					end,
					width = 1.5,
					order = 20
				},
				queue_tools = {
					type = "toggle",
					name = L["QUEUETOOLSNAME"],
					desc = L["QUEUETOOLSDESC"],
					get = function()
						return CraftForge.db.profile.queue_tools
					end,
					set = function(self,value)
						CraftForge.db.profile.queue_tools = value
					end,
					width = 1.5,
					order = 21
				},
				ignore_banked_reagents = {
					type = "toggle",
					name = L["IGNOREBANKEDREAGENTSNAME"],
					desc = L["IGNOREBANKEDREAGENTSDESC"],
					get = function()
						return CraftForge.db.profile.ignore_banked_reagents
					end,
					set = function(self,value)
						CraftForge.db.profile.ignore_banked_reagents = value
					end,
					width = 1.5,
					order = 21
				},
				ignore_queued_reagents = {
					type = "toggle",
					name = L["IGNOREQUEUEDREAGENTSNAME"],
					desc = L["IGNOREQUEUEDREAGENTSDESC"],
					get = function()
						return CraftForge.db.profile.ignore_queued_reagents
					end,
					set = function(self,value)
						CraftForge.db.profile.ignore_queued_reagents = value
					end,
					width = 1.5,
					order = 21
				},
				queue_craftable_reagents = {
					type = "toggle",
					name = L["QUEUECRAFTABLEREAGENTSNAME"],
					desc = L["QUEUECRAFTABLEREAGENTSDESC"],
					get = function()
						return CraftForge.db.profile.queue_craftable_reagents
					end,
					set = function(self,value)
						CraftForge.db.profile.queue_craftable_reagents = value
					end,
					width = "full",
					order = 22
				},
				queue_match_trade = {
					type = "toggle",
					name = L["QUEUEMATCHTRADENAME"],
					desc = L["QUEUEMARCHTRADEDESC"],
					get = function()
						return CraftForge.db.profile.queue_match_trade
					end,
					set = function(self,value)
						CraftForge.db.profile.queue_match_trade = value
					end,
					width = 1.5,
					order = 23
				},
				queue_insert_first = {
					type = "toggle",
					name = L["QUEUEINSERTFIRSTNAME"],
					desc = L["QUEUEINSERTFIRSTDESC"],
					get = function()
						return CraftForge.db.profile.queue_insert_first
					end,
					set = function(self,value)
						CraftForge.db.profile.queue_insert_first = value
					end,
					width = 1.5,
					order = 23
				},
--[[
				queue_to_front = {
					type = "toggle",
					name = L["QUEUETOFRONTNAME"],
					desc = L["QUEUETOFRONTDESC"],
					get = function()
						return CraftForge.db.profile.queue_to_front
					end,
					set = function(self,value)
						CraftForge.db.profile.queue_to_front = value
					end,
					width = "full",
					order = 23
				},
--]]
				queue_glyph_reagents = {
					hidden = not CraftForge.isRetail,
					type = "toggle",
					name = L["QUEUEGLYPHREAGENTSNAME"],
					desc = L["QUEUEGLYPHREAGENTSDESC"],
					get = function()
						return CraftForge.db.profile.queue_glyph_reagents
					end,
					set = function(self,value)
						CraftForge.db.profile.queue_glyph_reagents = value
					end,
					width = "full",
					order = 24
				},
				header = {
					type = "header",
					name = L["DISPLAYSHOPPINGLIST"],
					order = 25
				},
					display_shopping_list_at_bank = {
						type = "toggle",
						name = L["Bank"],
						desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
						get = function()
							return CraftForge.db.profile.display_shopping_list_at_bank
						end,
						set = function(self,value)
							CraftForge.db.profile.display_shopping_list_at_bank = value
						end,
							width = 0.75,
						order = 26
					},
					display_shopping_list_at_guildbank = {
						type = "toggle",
						name = L["Guild bank"],
						desc = L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"],
						get = function()
							return CraftForge.db.profile.display_shopping_list_at_guildbank
						end,
						set = function(self,value)
							CraftForge.db.profile.display_shopping_list_at_guildbank = value
						end,
							width = 0.75,
						order = 27
					},
					display_shopping_list_at_auction = {
						type = "toggle",
						name = L["Auction"],
						desc = L["DISPLAYSHOPPINGLISTATAUCTIONDESC"],
						get = function()
							return CraftForge.db.profile.display_shopping_list_at_auction
						end,
						set = function(self,value)
							CraftForge.db.profile.display_shopping_list_at_auction = value
						end,
							width = 0.75,
						order = 28
					},
					display_shopping_list_at_merchant = {
						type = "toggle",
						name = L["Merchant"],
						desc = L["DISPLAYSHOPPINGLISTATMERCHANTDESC"],
						get = function()
							return CraftForge.db.profile.display_shopping_list_at_merchant
						end,
						set = function(self,value)
							CraftForge.db.profile.display_shopping_list_at_merchant = value
						end,
							width = 0.75,
						order = 29
					},
				use_guildbank_as_alt = {
					type = "toggle",
					name = L["USEGUILDBANKASALTNAME"],
					desc = L["USEGUILDBANKASALTDESC"],
					get = function()
						return CraftForge.db.profile.use_guildbank_as_alt
					end,
					set = function(self,value)
						CraftForge.db.profile.use_guildbank_as_alt = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 30
				},
				use_altcurrency_vendor_items = {
					type = "toggle",
					name = L["USEALTCURRVENDITEMSNAME"],
					desc = L["USEALTCURRVENDITEMSDESC"],
					get = function()
						return CraftForge.db.profile.use_altcurrency_vendor_items
					end,
					set = function(self,value)
						CraftForge.db.profile.use_altcurrency_vendor_items = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 31
				},
			}
		},
		appearance = {
			type = 'group',
			name = L["Appearance"],
			desc = L["APPEARANCEDESC"],
			args = {
				display_required_level = {
					type = "toggle",
					name = L["DISPLAYREQUIREDLEVELNAME"],
					desc = L["DISPLAYREQUIREDLEVELDESC"],
					get = function()
						return CraftForge.db.profile.display_required_level
					end,
					set = function(self,value)
						CraftForge.db.profile.display_required_level = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 1
				},
				show_max_upgrade = {
					type = "toggle",
					name = L["SHOWMAXUPGRADENAME"],
					desc = L["SHOWMAXUPGRADEDESC"],
					get = function()
						return CraftForge.db.profile.show_max_upgrade
					end,
					set = function(self,value)
						CraftForge.db.profile.show_max_upgrade = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 2
				},
				show_craft_counts = {
					type = "toggle",
					name = L["SHOWCRAFTCOUNTSNAME"],
					desc = L["SHOWCRAFTCOUNTSDESC"],
					get = function()
						return CraftForge.db.profile.show_craft_counts
					end,
					set = function(self,value)
						CraftForge.db.profile.show_craft_counts = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 3
				},
				recipe_source_first = {
					type = "toggle",
					name = L["RECIPESOURCEFIRSTNAME"],
					desc = L["RECIPESOURCEFIRSTDESC"],
					get = function()
						return CraftForge.db.profile.recipe_source_first
					end,
					set = function(self,value)
						CraftForge.db.profile.recipe_source_first = value
					end,
					width = 1.5,
					order = 4
				},
				show_recipe_source_for_learned = {
					type = "toggle",
					name = L["SHOWRECIPESOURCEFORLEARNEDNAME"],
					desc = L["SHOWRECIPESOURCEFORLEARNEDDESC"],
					get = function()
						return CraftForge.db.profile.show_recipe_source_for_learned
					end,
					set = function(self,value)
						CraftForge.db.profile.show_recipe_source_for_learned = value
					end,
					width = 1.5,
					order = 5
				},
				use_blizzard_for_followers = {
					hidden = not CraftForge.isRetail,
					type = "toggle",
					name = L["USEBLIZZARDFORFOLLOWERSNAME"],
					desc = L["USEBLIZZARDFORFOLLOWERSDESC"],
					get = function()
						return CraftForge.db.profile.use_blizzard_for_followers
					end,
					set = function(self,value)
						CraftForge.db.profile.use_blizzard_for_followers = value
					end,
					width = "full",
					order = 6
				},
				always_show_progress_bar = {
					type = "toggle",
					name = L["SHOWPROGRESSBARNAME"],
					desc = L["SHOWPROGRESSBARDESC"],
					get = function()
						return CraftForge.db.profile.always_show_progress_bar
					end,
					set = function(self,value)
						CraftForge.db.profile.always_show_progress_bar = value
					end,
					width = "full",
					order = 7
				},
				hide_blizzard_frame = {
					hidden = CraftForge.isRetail,
					type = "toggle",
					name = L["HIDEBLIZZARDFRAMENAME"],
					desc = L["HIDEBLIZZARDFRAMEDESC"],
					get = function()
						return CraftForge.db.profile.hide_blizzard_frame
					end,
					set = function(self,value)
						CraftForge.db.profile.hide_blizzard_frame = value
						if not value and ProfessionsFrame then
							ProfessionsFrame:SetScale(1.0)
						end
						if value and CraftForge.db.profile.scale_blizzard_frame then
							CraftForge.db.profile.scale_blizzard_frame = false
						end
					end,
					width = 1.5,
					order = 7
				},
				scale_blizzard_frame = {
					hidden = CraftForge.isRetail,
					type = "toggle",
					name = L["SCALEBLIZZARDFRAMENAME"],
					desc = L["SCALEBLIZZARDFRAMEDESC"],
					get = function()
						return CraftForge.db.profile.scale_blizzard_frame
					end,
					set = function(self,value)
						CraftForge.db.profile.scale_blizzard_frame = value
						if not value and ProfessionsFrame then
							ProfessionsFrame:SetScale(1.0)
						end
						if value and CraftForge.db.profile.hide_blizzard_frame then
							CraftForge.db.profile.hide_blizzard_frame = false
						end
					end,
					width = 1.5,
					order = 8
				},
--[[
				select_top_recipe = {
					type = "toggle",
					name = L["SELECTTOPRECIPENAME"],
					desc = L["SELECTTOPRECIPEDESC"],
					get = function()
						return CraftForge.db.profile.select_top_recipe
					end,
					set = function(self,value)
						CraftForge.db.profile.select_top_recipe = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 8,
				},
--]]
				enhanced_recipe_display = {
					type = "toggle",
					name = L["ENHANCHEDRECIPEDISPLAYNAME"],
					desc = L["ENHANCHEDRECIPEDISPLAYDESC"],
					get = function()
						return CraftForge.db.profile.enhanced_recipe_display
					end,
					set = function(self,value)
						CraftForge.db.profile.enhanced_recipe_display = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = 1.5,
					order = 9
				},
				enhanced_chance_display = {
					type = "toggle",
					name = L["ENHANCHEDCHANCEDISPLAYNAME"],
					desc = L["ENHANCHEDCHANCEDISPLAYDESC"],
					get = function()
						return CraftForge.db.profile.enhanced_chance_display
					end,
					set = function(self,value)
						CraftForge.db.profile.enhanced_chance_display = value
						CraftForge:UpdateTradeSkillWindow()
					end,
--					width = "full",
					width = 1.5,
					order = 9,
				},
				confirm_queue_clear = {
					type = "toggle",
					name = L["CONFIRMQUEUECLEARNAME"],
					desc = L["CONFIRMQUEUECLEARDESC"],
					get = function()
						return CraftForge.db.profile.confirm_queue_clear
					end,
					set = function(self,value)
						CraftForge.db.profile.confirm_queue_clear = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 10
				},
				queue_only_view = {
					type = "toggle",
					name = L["QUEUEONLYVIEWNAME"],
					desc = L["QUEUEONLYVIEWDESC"],
					get = function()
						return CraftForge.db.profile.queue_only_view
					end,
					set = function(self,value)
						CraftForge.db.profile.queue_only_view = value
						CraftForge:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 11
				},
				dialog_switch = {
					type = "toggle",
					name = L["DIALOGSWITCHNAME"],
					desc = L["DIALOGSWITCHDESC"],
					get = function()
						return CraftForge.db.profile.dialog_switch
					end,
					set = function(self,value)
						CraftForge.db.profile.dialog_switch = value
					end,
					width = "full",
					order = 12
				},
				tsm_compat = {
					type = "toggle",
					name = L["TSMCOMPATNAME"],
					desc = L["TSMCOMPATDESC"],
					get = function()
						return CraftForge.db.profile.tsm_compat
					end,
					set = function(self,value)
						CraftForge.db.profile.tsm_compat = value
					end,
--					width = "full",
					width = 1.5,
					order = 13
				},
				tsm_prefer = {
					type = "toggle",
					name = L["TSMPREFERNAME"],
					desc = L["TSMPREFERDESC"],
					get = function()
						return CraftForge.db.profile.tsm_prefer
					end,
					set = function(self,value)
						CraftForge.db.profile.tsm_prefer = value
					end,
--					width = "full",
					width = 1.5,
					order = 13
				},
				scale_tooltip = {
					type = "toggle",
					name = L["SCALETOOLTIPNAME"],
					desc = L["SCALETOOLTIPDESC"],
					get = function()
						return CraftForge.db.profile.scale_tooltip
					end,
					set = function(self,value)
						CraftForge.db.profile.scale_tooltip = value
					end,
					width = "full",
					order = 14
				},
				sound_on_empty_queue = {
					type = "toggle",
					name = L["SOUNDONEMPTYQUEUENAME"],
					desc = L["SOUNDONEMPTYQUEUEDESC"],
					get = function()
						return CraftForge.db.profile.sound_on_empty_queue
					end,
					set = function(self,value)
						CraftForge.db.profile.sound_on_empty_queue = value
					end,
					width = 1.5,
					order = 15,
				},
				flash_on_empty_queue = {
					type = "toggle",
					name = L["FLASHONEMPTYQUEUENAME"],
					desc = L["FLASHONEMPTYQUEUEDESC"],
					get = function()
						return CraftForge.db.profile.flash_on_empty_queue
					end,
					set = function(self,value)
						CraftForge.db.profile.flash_on_empty_queue = value
					end,
					width = 1.5,
					order = 16,
				},
				sound_on_remove_queue = {
					type = "toggle",
					name = L["SOUNDONREMOVEQUEUENAME"],
					desc = L["SOUNDONREMOVEQUEUEDESC"],
					get = function()
						return CraftForge.db.profile.sound_on_remove_queue
					end,
					set = function(self,value)
						CraftForge.db.profile.sound_on_remove_queue = value
					end,
					width = 1.5,
					order = 17,
				},
				flash_on_remove_queue = {
					type = "toggle",
					name = L["FLASHONREMOVEQUEUENAME"],
					desc = L["FLASHONREMOVEQUEUEDESC"],
					get = function()
						return CraftForge.db.profile.flash_on_remove_queue
					end,
					set = function(self,value)
						CraftForge.db.profile.flash_on_remove_queue = value
					end,
					width = 1.5,
					order = 18,
				},
				transparency = {
					type = "range",
					name = L["Transparency"],
					desc = L["TRANSPARAENCYDESC"],
					min = 0.1, max = 1, step = 0.05, isPercent = true,
					get = function()
						return CraftForge.db.profile.transparency
					end,
					set = function(self,t)
						CraftForge.db.profile.transparency = t
						CraftForge:UpdateTradeSkillWindow()
						CraftForge:UpdateShoppingListWindow(false)
						CraftForge:UpdateStandaloneQueueWindow()
					end,
					width = "full",
					order = 20
				},
				scale = {
					type = "range",
					name = L["Scale"],
					desc = L["SCALEDESC"],
					min = 0.1, max = 1.25, step = 0.05, isPercent = true,
					get = function()
						return CraftForge.db.profile.scale
					end,
					set = function(self,t)
						CraftForge.db.profile.scale = t
						CraftForge:UpdateTradeSkillWindow()
						CraftForge:UpdateShoppingListWindow(false)
						CraftForge:UpdateStandaloneQueueWindow()
					end,
					width = "full",
					order = 21
				},
				ttscale = {
					type = "range",
					name = L["Tooltip Scale"],
					desc = L["TOOLTIPSCALEDESC"],
					min = 0.1, max = 1.25, step = 0.05, isPercent = true,
					get = function()
						return CraftForge.db.profile.ttscale
					end,
					set = function(self,t)
						CraftForge.db.profile.ttscale = t
						CraftForge:UpdateTradeSkillWindow()
						CraftForge:UpdateShoppingListWindow(false)
						CraftForge:UpdateStandaloneQueueWindow()
					end,
					width = "full",
					order = 22
				},
			},
		},
		config = {
			type = 'execute',
			name = L["Config"],
			desc = L["CONFIGDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:ShowOptions()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			guiHidden = true,
			order = 51
		},
		shoppinglist = {
			type = 'execute',
			name = L["Shopping List"],
			desc = L["SHOPPINGLISTDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					if CraftForge:IsShoppingListVisible() then
						CraftForge:HideShoppingList()
					else
						CraftForge:DisplayShoppingList(false)
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 52
		},
		shoppingclear = {
			type = 'execute',
			name = L["Shopping Clear"],
			desc = L["SHOPPINGCLEARDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:ClearShoppingList()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 53
		},
		flushalldata = {
			type = 'execute',
			name = L["Flush All Data"],
			desc = L["FLUSHALLDATADESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:FlushAllData()
					CraftForge.CleanDatabase = true
					CraftForge:InitializeDatabase(CraftForge:unitName("player"))
					CraftForge.CleanDatabase = false
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 54
		},
		flushrecipedata = {
			type = 'execute',
			name = L["Flush Recipe Data"],
			desc = L["FLUSHRECIPEDATADESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:FlushRecipeData()
					CraftForge:InitializeDatabase(CraftForge:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 55
		},
		flushcustomdata = {
			type = 'execute',
			name = "Flush Custom Data",
			desc = "Flush Custom Group Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:FlushCustomData()
					CraftForge:InitializeDatabase(CraftForge:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 56
		},
		flushqueuedata = {
			type = 'execute',
			name = "Flush Queue Data",
			desc = "Flush Queue Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:FlushQueueData()
					CraftForge:InitializeDatabase(CraftForge:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 57
		},
		flushplayerdata = {
			type = 'execute',
			name = L["Flush Player Data"],
			desc = L["Flush Player Data"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:FlushPlayerData()
					CraftForge:InitializeDatabase(CraftForge:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 58
		},
		flushdetaildata = {
			type = 'execute',
			name = "Flush Detail Data",
			desc = "Clear the collected bag, bank, guildbank details",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:FlushDetailData()
					CraftForge:InitializeDatabase(CraftForge:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 59
		},
		collectdetails = {
			type = "toggle",
			name = "Collect details",
			desc = "Disable/Enable collecting bag, bank, guildbank details",
			get = function()
				return CraftForge.db.profile.collect_details
			end,
			set = function(self,value)
				CraftForge.db.profile.collect_details = value
			end,
			order = 60
		},
		standby = {
			type = 'execute',
			name = L["STANDBYNAME"],
			desc = L["STANDBYDESC"],
			func = function()
				if CraftForge:IsEnabled() then
					CraftForge:Disable()
					CraftForge:Print(RED_FONT_COLOR_CODE..L["is now disabled"]..FONT_COLOR_CODE_CLOSE)
				else
					CraftForge:Enable()
					CraftForge:Print(GREEN_FONT_COLOR_CODE..L["is now enabled"]..FONT_COLOR_CODE_CLOSE)
				end
			end,
			guiHidden = true,
			order = 61
		},
		ignorelist = {
			type = 'execute',
			name = L["Ignored Materials List"],
			desc = L["IGNORELISTDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:DisplayIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 62
		},
		ignoreclear = {
			type = 'execute',
			name = L["Ignored Materials Clear"],
			desc = L["IGNORECLEARDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:ClearIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 63
		},
		ignoreadd = {
			type = "input",
			name = "IgnoreAdd",
			desc = "Add to userIgnoredMats",
			get = function()
				local value = tonumber(value)
				return CraftForge.db.realm.userIgnoredMats[CraftForge:unitName("player")][value]
			end,
			set = function(self,value)
				local value = tonumber(value)
				CraftForge.db.realm.userIgnoredMats[CraftForge:unitName("player")][value] = 1
			end,
			order = 64
		},
		ignoredel = {
			type = "input",
			name = "IgnoreDel",
			desc = "Delete from userIgnoredMats",
			get = function()
				local value = tonumber(value)
				return CraftForge.db.realm.userIgnoredMats[CraftForge:unitName("player")][value]
			end,
			set = function(self,value)
				local value = tonumber(value)
				CraftForge.db.realm.userIgnoredMats[CraftForge:unitName("player")][value] = nil
			end,
			order = 65
		},
		resetrecipefilter = {
			type = 'execute',
			name = L["Reset Recipe Filter"],
			desc = L["RESETRECIPEFILTERDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:ResetTradeSkillFilter()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 66
		},
		version = {
			type = 'execute',
			name = "Version",
			desc = "Print version information",
			func = function()
--				local wowVersion,wowBuild = GetBuildInfo();
--				print("CraftForge "..tostring(CraftForge.version).." on "..tostring(wowVersion).."."..tostring(wowBuild)..", "..tostring(GetLocale()))
			CraftForge:ShowVersion()
			end,
			order = 66
		},
		printsaved = {
			type = 'execute',
			name = "PrintSaved",
			desc = "Print list of SavedQueues",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:PrintSaved()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 67
		},
		printqueue = {
			type = 'execute',
			name = "PrintQueue",
			desc = "Print Current Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:PrintQueue()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 68
		},
		printallqueues = {
			type = 'execute',
			name = "PrintAllQueues",
			desc = "Print All Player Queues",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:PrintAllQueues()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 68
		},
		printsavedqueue = {
			type = 'input',
			name = "PrintSavedQueue",
			desc = "Print Named Saved Queue",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					CraftForge:PrintQueue(value)
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 69
		},
		clearqueue = {
			type = 'execute',
			name = "ClearQueue",
			desc = "Clear Current Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:ClearQueue()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 70
		},
		printauction = {
			type = 'execute',
			name = "PrintAuctionData",
			desc = "Print Auction Data",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:PrintAuctionData()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 71
		},
		printriq = {
			type = 'execute',
			name = "printriq",
			desc = "Print Reagents In Queue",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:PrintRIQ()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 72
		},
		printshop = {
			type = 'execute',
			name = "printshop",
			desc = "Print ShoppingList",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:PrintShoppingList()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 73
		},
--
-- commands to toggle Blizzard's frames (beats using "/run")
--
		btsui = {
			type = "toggle",
			name = "BTSUI",
			desc = "Show/Hide the Blizzard TradeSkill frame",
			get = function()
				return CraftForge.data.btsui
			end,
			set = function(self,value)
				CraftForge.data.btsui = value
				if value then
					ShowUIPanel(ProfessionsFrame)
					CraftForge.BlizzardUIshowing = true
				else
					HideUIPanel(ProfessionsFrame)
					CraftForge.BlizzardUIshowing = false
				end
			end,
			order = 74
		},
		bcui = {
			type = "toggle",
			name = "BCUI",
			desc = "Show/Hide the Blizzard Crafting frame",
			get = function()
				return CraftForge.data.bcui
			end,
			set = function(self,value)
				CraftForge.data.bcui = value
				if value then
					ShowUIPanel(CraftFrame)
				else
					HideUIPanel(CraftFrame)
				end
			end,
			order = 75
		},
		scalesmall = {
			type = "input",
			name = "scaleSmall",
			desc = "Scale Blizzard frame down",
			get = function()
				local value = tonumber(value)
				return CraftForge.db.profile.scale_blizzard_down
			end,
			set = function(self,value)
				local value = tonumber(value)
				if value then
					if value < 0.1 then
						value = 0.1
					elseif value > 1.0 then
						value = 1.0
					end
					CraftForge.db.profile.scale_blizzard_down = value
				else
					print("scalesmall= "..tostring(CraftForge.db.profile.scale_blizzard_down))
				end
			end,
			order = 75
		},
		scalelarge = {
			type = "input",
			name = "scaleLarge",
			desc = "Scale Blizzard frame up",
			get = function()
				local value = tonumber(value)
				return CraftForge.db.profile.scale_blizzard_up
			end,
			set = function(self,value)
				local value = tonumber(value)
				if value then
					if value < 0.1 then
						value = 0.1
					elseif value > 1.0 then
						value = 1.0
					end
					CraftForge.db.profile.scale_blizzard_up = value
				else
					print("scalelarge= "..tostring(CraftForge.db.profile.scale_blizzard_up))
				end
			end,
			order = 75
		},
--
-- commands to update CraftForge's main windows
--
		uslw = {
			type = 'execute',
			name = "UpdateShoppingListWindow",
			desc = "Update (CraftForge's) Shopping List Window",
			func = function()
				CraftForge:UpdateShoppingListWindow(false)
			end,
			order = 76
		},
		utsw = {
			type = 'execute',
			name = "UpdateTradeSkillWindow",
			desc = "Update (CraftForge's) TradeSkill Window",
			func = function()
				CraftForge:UpdateTradeSkillWindow()
			end,
			order = 77
		},
--
-- command to turn on/off custom groups 
-- (i.e. panic/debug button if they aren't working)
--
		customgroups = {
			type = "toggle",
			name = "CustomGroups",
			desc = "Enable / Disable Custom Groups button",
			get = function()
				return CraftForge.data.customgroups
			end,
			set = function(self,value)
				CraftForge.data.customgroups = value
				if value then
					CraftForgeRecipeGroupOperations:Enable()
				else
					CraftForgeRecipeGroupOperations:Disable()
				end
			end,
			order = 78
		},
		nomodkeys = {
			type = "toggle",
			name = "NoModKeys",
			desc = "Disable/Enable Mod Keys to open the Blizzard frames",
			get = function()
				return CraftForge.db.profile.nomodkeys
			end,
			set = function(self,value)
				CraftForge.db.profile.nomodkeys = value
			end,
			order = 79
		},
		swapshiftkey = {
			type = "toggle",
			name = "SwapShiftKey",
			desc = "Swap Shift Key to open the Blizzard frames",
			get = function()
				return CraftForge.db.profile.swapshiftkey
			end,
			set = function(self,value)
				CraftForge.db.profile.swapshiftkey = value
			end,
			order = 80
		},
		initskilllevels = {
			type = 'execute',
			name = "Init Skill Levels",
			desc = "Initialize Skill Levels",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge:InitializeSkillLevels()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 81
		},
		altskilllevels = {
			type = "toggle",
			name = "AltSkillLevels",
			desc = "Use Alternate Skill Levels",
			get = function()
				return CraftForge.db.profile.altskilllevels
			end,
			set = function(self,value)
				CraftForge.db.profile.altskilllevels = value
			end,
			order = 82
		},
		baseskilllevel = {
			type = "toggle",
			name = "BaseSkillLevel",
			desc = "Use Alternate Base Skill Level",
			get = function()
				return CraftForge.db.profile.baseskilllevel
			end,
			set = function(self,value)
				CraftForge.db.profile.baseskilllevel = value
			end,
			order = 83
		},
		news = {
			type = 'execute',
			name = "Display news",
			desc = "Display the news frame",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftForge.NewsGUI:Toggle()
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 84
		},

--
-- commands to manipulate the state of debugging code flags
-- (See DebugAids.lua)
--
		WarnShow = {
			type = "toggle",
			name = "WarnShow",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.WarnShow
			end,
			set = function(self,value)
				CraftForge.db.profile.WarnShow = value
				CraftForge.WarnShow = value
				if value then
					CraftForge.db.profile.WarnLog = value
					CraftForge.WarnLog = value
				end
			end,
			order = 81
		},
		WarnLog = {
			type = "toggle",
			name = "WarnLog",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.WarnLog
			end,
			set = function(self,value)
				CraftForge.db.profile.WarnLog = value
				CraftForge.WarnLog = value
			end,
			order = 82
		},
		DebugShow = {
			type = "toggle",
			name = "DebugShow",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.DebugShow
			end,
			set = function(self,value)
				CraftForge.db.profile.DebugShow = value
				CraftForge.DebugShow = value
				if value then
					CraftForge.db.profile.DebugLogging = value
					CraftForge.DebugLogging = value
				end
			end,
			order = 83
		},
		DebugLogging = {
			type = "toggle",
			name = "DebugLogging",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.DebugLogging
			end,
			set = function(self,value)
				CraftForge.db.profile.DebugLogging = value
				CraftForge.DebugLogging = value
			end,
			order = 84
		},
		DebugLevel = {
			type = "input",
			name = "DebugLevel",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.DebugLevel
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 1
				elseif value < 1 then value = 1
				elseif value > 9 then value = 10 end
				CraftForge.db.profile.DebugLevel = value
				CraftForge.DebugLevel = value
			end,
			order = 85
		},
		TableDump = {
			type = "toggle",
			name = "TableDump",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.TableDump
			end,
			set = function(self,value)
				CraftForge.db.profile.TableDump = value
				CraftForge.TableDump = value
			end,
			order = 86
		},
		TraceShow = {
			type = "toggle",
			name = "TraceShow",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.TraceShow
			end,
			set = function(self,value)
				CraftForge.db.profile.TraceShow = value
				CraftForge.TraceShow = value
				if value then
					CraftForge.db.profile.TraceLog = value
					CraftForge.TraceLog = value
				end
			end,
			order = 87
		},
		TraceLog = {
			type = "toggle",
			name = "TraceLog",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.TraceLog
			end,
			set = function(self,value)
				CraftForge.db.profile.TraceLog = value
				CraftForge.TraceLog = value
			end,
			order = 88
		},
		TraceLog2 = {
			type = "toggle",
			name = "TraceLog2",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.TraceLog2
			end,
			set = function(self,value)
				CraftForge.db.profile.TraceLog2 = value
				CraftForge.TraceLog2 = value
			end,
			order = 88
		},
		TraceLog3 = {
			type = "toggle",
			name = "TraceLog3",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.TraceLog3
			end,
			set = function(self,value)
				CraftForge.db.profile.TraceLog3 = value
				CraftForge.TraceLog3 = value
			end,
			order = 88
		},
		ProfileShow = {
			type = "toggle",
			name = "ProfileShow",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.ProfileShow
			end,
			set = function(self,value)
				CraftForge.db.profile.ProfileShow = value
				CraftForge.ProfileShow = value
			end,
			order = 89
		},
		ClearDebugLog = {
			type = "execute",
			name = "ClearDebugLog",
			desc = "Option for debugging",
			func = function()
				CraftForgeDBPC = {}
				DA.DebugLog = CraftForgeDBPC
			end,
			order = 90
		},
		ClearProfileLog = {
			type = "execute",
			name = "ClearProfileLog",
			desc = "Option for debugging",
			func = function()
				CraftForgeProfile = {}
				DA.DebugProfile = CraftForgeProfile
			end,
			order = 91
		},
		DebugStatus = {
			type = 'execute',
			name = "DebugStatus",
			desc = "Print Debug Status",
			func = function()
				DA.DebugAidsStatus()
			end,
			order = 92
		},
		DebugOn = {
			type = 'execute',
			name = "DebugOn",
			desc = "Turn Debug On",
			func = function()
--[[
				if CraftForge.db.profile.WarnShow then
					CraftForge.db.profile.WarnShow = true
					CraftForge.WarnShow = true
				end
				if CraftForge.db.profile.WarnLog then
					CraftForge.db.profile.WarnLog = true
					CraftForge.WarnLog = true
				end
				if CraftForge.db.profile.DebugShow then
					CraftForge.db.profile.DebugShow= true
					CraftForge.DebugShow = true
				end
				if CraftForge.db.profile.DebugLogging then
					CraftForge.db.profile.DebugLogging = true
					CraftForge.DebugLogging = true
				end
				if CraftForge.db.profile.DebugLevel then
					CraftForge.db.profile.DebugLevel = 4
				end
				if CraftForge.db.profile.TableDump then
					CraftForge.db.profile.TableDump = true
				end
--
-- LogLevel is left undefined or set to false as
-- the default should be log everything.
--
				if CraftForge.db.profile.LogLevel then
					CraftForge.db.profile.LogLevel = false
					CraftForge.LogLevel = false
				end
				if CraftForge.db.profile.TraceShow then
					CraftForge.db.profile.TraceShow = true
					CraftForge.TraceShow = true
				end
				if CraftForge.db.profile.TraceLog then
					CraftForge.db.profile.TraceLog = true
					CraftForge.TraceLog = true
				end
				if CraftForge.db.profile.TraceLog2 then
					CraftForge.db.profile.TraceLog2 = false
					CraftForge.TraceLog2 = false
				end
				if CraftForge.db.profile.TraceLog3 then
					CraftForge.db.profile.TraceLog3 = false
					CraftForge.TraceLog3 = false
				end
				if CraftForge.db.profile.ProfileShow then
					CraftForge.db.profile.ProfileShow = false
					CraftForge.ProfileShow = false
				end
--]]
				DA.DEBUGON()
				CraftForge:Print(GREEN_FONT_COLOR_CODE.."DebugOn:"..FONT_COLOR_CODE_CLOSE)
				DA.DebugAidsStatus()
			end,
			order = 93
		},
		DebugOff = {
			type = 'execute',
			name = "DebugOff",
			desc = "Turn Debug Off",
			func = function()
--[[
				if CraftForge.db.profile.WarnShow then
					CraftForge.db.profile.WarnShow = false
					CraftForge.WarnShow = false
				end
				if CraftForge.db.profile.WarnLog then
					CraftForge.db.profile.WarnLog = false
					CraftForge.WarnLog = false
				end
				if CraftForge.db.profile.DebugShow then
					CraftForge.db.profile.DebugShow= false
					CraftForge.DebugShow = false
				end
				if CraftForge.db.profile.DebugLogging then
					CraftForge.db.profile.DebugLogging = false
					CraftForge.DebugLogging = false
				end
--
-- DebugLevel is left alone but
-- LogLevel is left undefined or set to false as
-- the default should be log everything.
--
				if CraftForge.db.profile.LogLevel then
					CraftForge.db.profile.LogLevel = false
					CraftForge.LogLevel = false
				end
				if CraftForge.db.profile.TraceShow then
					CraftForge.db.profile.TraceShow = false
					CraftForge.TraceShow = false
				end
				if CraftForge.db.profile.TraceLog then
					CraftForge.db.profile.TraceLog = false
					CraftForge.TraceLog = false
				end
				if CraftForge.db.profile.TraceLog2 then
					CraftForge.db.profile.TraceLog2 = false
					CraftForge.TraceLog2 = false
				end
				if CraftForge.db.profile.TraceLog3 then
					CraftForge.db.profile.TraceLog3 = false
					CraftForge.TraceLog3 = false
				end
				if CraftForge.db.profile.ProfileShow then
					CraftForge.db.profile.ProfileShow = false
					CraftForge.ProfileShow = false
				end
--]]
				DA.DEBUGOFF()
				CraftForge:Print(RED_FONT_COLOR_CODE.."DebugOff:"..FONT_COLOR_CODE_CLOSE)
				DA.DebugAidsStatus()
			end,
			order = 93
		},
		LogLevel = {
			type = "toggle",
			name = "LogLevel",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.LogLevel
			end,
			set = function(self,value)
				CraftForge.db.profile.LogLevel = value
				CraftForge.LogLevel = value
			end,
			order = 94
		},
		MaxDebug = {
			type = "input",
			name = "MaxDebug",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.MAXDEBUG
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 4000 end
				CraftForge.db.profile.MAXDEBUG = value
				CraftForge.MAXDEBUG = value
			end,
			order = 95
		},
		MaxProfile = {
			type = "input",
			name = "MaxProfile",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.MAXPROFILE
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 2000 end
				CraftForge.db.profile.MAXPROFILE = value
				CraftForge.MAXPROFILE = value
			end,
			order = 96
		},
		FixBugs = {
			type = "toggle",
			name = "FixBugs",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.FixBugs
			end,
			set = function(self,value)
				CraftForge.db.profile.FixBugs = value
				CraftForge.FixBugs = value
				if value then
					CraftForge.db.profile.TraceLog = value
					CraftForge.TraceLog = value
				end
			end,
			order = 97
		},
		DebugMark = {
			type = 'input',
			name = "DebugMark",
			desc = "Adds a comment to logs",
			get = function()
			end,
			set = function(self,value)
				DA.MARK(value)
			end,
			order = 98
		},

--
-- command to reset the position of the major CraftForge frames
--
		reset = {
			type = 'execute',
			name = L["Reset"],
			desc = L["RESETDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					local windowManager = LibStub("LibWindow-1.1")
					if CraftForgeFrame and CraftForgeFrame:IsVisible() then
						CraftForgeFrame:SetWidth(750);
						CraftForgeFrame:SetHeight(580);
						CraftForgeFrame:SetPoint("TOPLEFT",200,-100);
						windowManager.SavePosition(CraftForgeFrame)
					end
					if CraftForgeStandaloneQueue and CraftForgeStandaloneQueue:IsVisible() then
						CraftForgeStandaloneQueue:SetWidth(385);
						CraftForgeStandaloneQueue:SetHeight(170);
						CraftForgeStandaloneQueue:SetPoint("TOPLEFT",950,-100);
						windowManager.SavePosition(CraftForgeStandaloneQueue)
					end
					if CraftForgeShoppingList and CraftForgeShoppingList:IsVisible() then
						CraftForgeShoppingList:SetWidth(385);
						CraftForgeShoppingList:SetHeight(240);
						CraftForgeShoppingList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftForgeShoppingList)
					end
					if CraftForgeIgnoreList and CraftForgeIgnoreList:IsVisible() then
						CraftForgeIgnoreList:SetWidth(320);
						CraftForgeIgnoreList:SetHeight(150);
						CraftForgeIgnoreList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftForgeIgnoreList)
					end
					if CraftForgeOptionalList and CraftForgeOptionalList:IsVisible() then
						CraftForgeOptionalList:SetWidth(420);
						CraftForgeOptionalList:SetHeight(230);
						CraftForgeOptionalList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftForgeOptionalList)
					end
					if CraftForgeModifiedList and CraftForgeModifiedList:IsVisible() then
						CraftForgeModifiedList:SetWidth(420);
						CraftForgeModifiedList:SetHeight(230);
						CraftForgeModifiedList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftForgeModifiedList)
					end
					if CraftForgeSalvageList and CraftForgeSalvageList:IsVisible() then
						CraftForgeSalvageList:SetWidth(420);
						CraftForgeSalvageList:SetHeight(230);
						CraftForgeSalvageList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftForgeSalvageList)
					end
					if CraftForgeFinishingList and CraftForgeFinishingList:IsVisible() then
						CraftForgeFinishingList:SetWidth(420);
						CraftForgeFinishingList:SetHeight(230);
						CraftForgeFinishingList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftForgeFinishingList)
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 99
		},
		BlizzOR = {
			type = "toggle",
			name = "BlizzOR",
			desc = "Option for debugging",
			get = function()
				return CraftForge.db.profile.BlizzOR
			end,
			set = function(self,value)
				CraftForge.db.profile.BlizzOR = value
				CraftForge.BlizzOR = value
			end,
			order = 100
		},
--
-- If set, FakeIt will not execute C_TradeSkillUI.CraftRecipe
-- FakeIt is not stored in the saved variables file.
--
		FakeIt = {
			type = "toggle",
			name = "FakeIt",
			desc = "Option for debugging",
			get = function()
				return CraftForge.FakeIt
			end,
			set = function(self,value)
				CraftForge.FakeIt = value
				if CraftForge.FakeIt then
					CraftForge:Print(RED_FONT_COLOR_CODE.."FakeIt is on"..FONT_COLOR_CODE_CLOSE)
				else
					CraftForge:Print(GREEN_FONT_COLOR_CODE.."FakeIt is off"..FONT_COLOR_CODE_CLOSE)
				end
			end,
			order = 101
		},
--
-- commands to manage the customPrice table
--
		customadd = {
			type = 'input',
			name = "customadd",
			desc = "Add a custom price for a reagent (customadd id|link,price)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local item, id, price, name, link
						local server = CraftForge.data.server or 0
						DA.DEBUG(0,"value= "..value)
						item, price = string.split(",",value)
						if string.find(item,"|H") then
							id = CraftForge:GetItemIDFromLink(item)
						else
							id = tonumber(item)
						end
						name, link = C_Item.GetItemInfo(id)
						price = tonumber(price)
						DA.DEBUG(0,"id= "..tostring(id)..", name= "..tostring(name)..", price= "..tostring(price)..", link= "..tostring(link))
						CraftForge.db.global.customPrice[server][id] = { ["name"] = name, ["value"] = price }
						end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 105
		},
		customdel = {
			type = 'input',
			name = "customdel",
			desc = "Delete a custom reagent (customdel id|link)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local id
						local server = CraftForge.data.server or 0
						DA.DEBUG(0,"value= "..value)
						if string.find(value,"|H") then
							id = CraftForge:GetItemIDFromLink(value)
						else
							id = tonumber(value)
						end
						CraftForge.db.global.customPrice[server][id] = nil
						end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 106
		},
		customshow = {
			type = 'execute',
			name = "customshow",
			desc = "Print the custom reagent price table",
			func = function()
				local server = CraftForge.data.server or 0
				for id,entry in pairs(CraftForge.db.global.customPrice[server]) do
					print(tostring(entry.name)..", "..CraftForge:FormatMoneyFull(entry.value,true))
				end
			end,
			order = 107
		},
		customdump = {
			type = 'execute',
			name = "customdump",
			desc = "Print the custom reagent price table",
			func = function()
				local server = CraftForge.data.server or 0
				for id,entry in pairs(CraftForge.db.global.customPrice[server]) do
					print("id= "..tostring(id)..", name= "..tostring(entry.name)..", value= "..tostring(entry.value))
				end
			end,
			order = 108
		},
		customclear = {
			type = 'execute',
			name = "customclear",
			desc = "Clear the custom reagent price table",
			func = function()
				local server = CraftForge.data.server or 0
				CraftForge.db.global.customPrice[server] = {}
			end,
			order = 109
		},
--
-- commands to manage the manual toolData list
--
		tooladd = {
			type = 'input',
			name = "tooladd",
			desc = "Add a tool (tooladd id|link,data)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local item, id, data, name, link
						local player = CraftForge.currentPlayer
						DA.DEBUG(0,"value= "..value)
						item, data = string.split(",",value)
						if string.find(item,"|H") then
							id = CraftForge:GetItemIDFromLink(item)
						else
							id = tonumber(item)
						end
						name, link = C_Item.GetItemInfo(id)
						data = tonumber(data)
						DA.DEBUG(0,"id= "..tostring(id)..", name= "..tostring(name)..", data= "..tostring(data)..", link= "..tostring(link))
						CraftForge.db.realm.toolData[player][id] = { ["name"] = name, ["value"] = data }
						end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 120
		},
		tooldel = {
			type = 'input',
			name = "tooldel",
			desc = "Delete a tool (tooldel id|link)",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						local id
						local player = CraftForge.currentPlayer
						DA.DEBUG(0,"value= "..value)
						if string.find(value,"|H") then
							id = CraftForge:GetItemIDFromLink(value)
						else
							id = tonumber(value)
						end
						CraftForge.db.realm.toolData[player][id] = nil
						end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 121
		},
		tooldump = {
			type = 'execute',
			name = "tooldump",
			desc = "Print the toolData table",
			func = function()
				local player = CraftForge.currentPlayer
				if next(CraftForge.db.realm.toolData[player]) == nil then
					print("toolData is empty")
				end
				for id,entry in pairs(CraftForge.db.realm.toolData[player]) do
					print("id= "..tostring(id)..", name= "..tostring(entry.name)..", value= "..tostring(entry.value))
				end
			end,
			order = 122
		},
		toolclear = {
			type = 'execute',
			name = "toolclear",
			desc = "Clear the custom reagent data table",
			func = function()
				local player = CraftForge.currentPlayer
				CraftForge.db.realm.toolData[player] = {}
			end,
			order = 123
		},

--
-- If set, MissAll will add all Merchant items to the MissingVendorItems table
-- MissAll is not stored in the saved variables file.
--
		MissAll = {
			type = "toggle",
			name = "MissAll",
			desc = "Option for debugging",
			get = function()
				return CraftForge.MissAll
			end,
			set = function(self,value)
				CraftForge.MissAll = value
				if CraftForge.MissAll then
					CraftForge:Print(RED_FONT_COLOR_CODE.."MissAll is on"..FONT_COLOR_CODE_CLOSE)
				else
					CraftForge:Print(GREEN_FONT_COLOR_CODE.."MissAll is off"..FONT_COLOR_CODE_CLOSE)
				end
			end,
			order = 111
		},
--
-- commands to manage the MissingVendorItems table
--
		missingshow = {
			type = 'input',
			name = "missingshow",
			desc = "Print the MissingVendorItems table",
			get = function()
				return value
			end,
			set = function(self,value)
				if not (UnitAffectingCombat("player")) then
					if value then
						DA.DEBUG(0,"value= "..value)
						local id
						for id,entry in pairs(CraftForge.db.global.MissingVendorItems) do
							if type(entry) == 'table' then	-- table entries are {name, quantity, currencyName, currencyID, currencyCount}
								if #entry ~= tonumber(value) then
									print("id= "..tostring(id)..", size= "..tostring(#entry)..", "..DA.DUMP(entry))
								end
							end
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 112
		},
		missingdel = {
			type = 'execute',
			name = "missingdel",
			desc = "Delete MissingVendorItems entries that are tables and not the correct size",
			func = function()
				if not (UnitAffectingCombat("player")) then
					if not CraftForge.db.global.RemovedVendorItems then
						CraftForge.db.global.RemovedVendorItems = {}
					end
					for id,entry in pairs(CraftForge.db.global.MissingVendorItems) do
						if type(entry) == 'table' then
							local size = #entry
							if not (size == 5 or size == 9) then
								print("id= "..tostring(id)..", size= "..tostring(size)..", "..DA.DUMP(entry))
								CraftForge.db.global.RemovedVendorItems[id] = entry
								CraftForge.db.global.MissingVendorItems[id] = nil
							end
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 113
		},
		missingclear = {
			type = 'execute',
			name = "missingclear",
			desc = "Clear the MissingVendorItems table",
			func = function()
				CraftForge.db.global.MissingVendorItems = {}
			end,
			order = 114
		},
--
-- commands to manage the RemovedVendorItems table
--
		removedshow = {
			type = 'execute',
			name = "removedshow",
			desc = "Print the RemovedVendorItems table",
			func = function()
				if not (UnitAffectingCombat("player")) then
					if CraftForge.db.global.RemovedVendorItems then
						for id,entry in pairs(CraftForge.db.global.RemovedVendorItems) do
							print("id= "..tostring(id)..", size= "..tostring(#entry)..", "..DA.DUMP(entry))
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftForge|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 116
		},
		removedclear = {
			type = 'execute',
			name = "removedclear",
			desc = "Clear the RemovedVendorItems table",
			func = function()
				CraftForge.db.global.RemovedVendorItems = {}
			end,
			order = 117
		},
--
-- Debug options to deal with bag update events slowing bag and bank sorting
--
		bagevents = {
			type = "toggle",
			name = "bagevents",
			desc = "Option for debugging",
			get = function()
				return CraftForge.BagEvents
			end,
			set = function(self,value)
				CraftForge.BagEvents = value
				if CraftForge.BagEvents then
					CraftForge:UnregisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
					CraftForge:UnregisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPDATE events for a specific action have been fired.
					CraftForge:UnregisterEvent("UNIT_INVENTORY_CHANGED")	-- BAG_UPDATE_DELAYED seems to have disappeared. Using this instead.
					CraftForge:Print(RED_FONT_COLOR_CODE.."BAG_UPDATE events are off"..FONT_COLOR_CODE_CLOSE)
				else
					CraftForge:RegisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
					CraftForge:RegisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPDATE events for a specific action have been fired.
					CraftForge:RegisterEvent("UNIT_INVENTORY_CHANGED")	-- BAG_UPDATE_DELAYED seems to have disappeared. Using this instead.
					CraftForge:Print(GREEN_FONT_COLOR_CODE.."BAG_UPDATE events are on"..FONT_COLOR_CODE_CLOSE)
				end
			end,
			order = 120
		},
		bagcounts = {
			type = 'execute',
			name = "bagcounts",
			desc = "Option for debugging",
			func = function()
				CraftForge:Print("bagUpdateCounts= "..DA.DUMP1(CraftForge.bagUpdateCounts))
				CraftForge:Print("bagUpdateDelayedCount= "..tostring(CraftForge.bagUpdateDelayedCount))
				CraftForge:Print("unitInventoryChangedCount= "..tostring(CraftForge.unitInventoryChangedCount))
				CraftForge:Print("bankUpdateCount= "..tostring(CraftForge.bankUpdateCount))
			end,
			order = 121
		},
		bagclear = {
			type = 'execute',
			name = "bagclear",
			desc = "Option for debugging",
			func = function()
				CraftForge.bagUpdateCounts = {}
				CraftForge.bagUpdateDelayedCount = 0
				CraftForge.unitInventoryChangedCount = 0
				CraftForge.bankUpdateCount = 0
			end,
			order = 122
		},
	}
}

function CraftForge:ConfigureOptions()
	local acecfg = LibStub("AceConfig-3.0")
	acecfg:RegisterOptionsTable("CraftForge", self.options, "craftforge")
	acecfg:RegisterOptionsTable("CraftForge Features", self.options.args.features)
	acecfg:RegisterOptionsTable("CraftForge Appearance", self.options.args.appearance)
	acecfg:RegisterOptionsTable("CraftForge Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	acecfg:RegisterOptionsTable("CraftForge Plugins", CraftForge.pluginsOptions)
	local acedia = LibStub("AceConfigDialog-3.0")
	CraftForge.optionsFrame, CraftForge.categoryID = acedia:AddToBlizOptions("CraftForge Features", "CraftForge")
	acedia:AddToBlizOptions("CraftForge Appearance", "Appearance", "CraftForge")
	acedia:AddToBlizOptions("CraftForge Profiles", "Profiles", "CraftForge")
	acedia:AddToBlizOptions("CraftForge Plugins", "Plugins", "CraftForge")
end

--
-- Show the options window
--
function CraftForge:ShowOptions()
--	Settings.OpenToCategory("CraftForge")
	Settings.OpenToCategory(CraftForge.categoryID)
end

