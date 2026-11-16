local addonName,addonTable = ...
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

local L = CraftBench.L

local isRetail = CraftBench.isRetail
local isForever = CraftBench.isForever

--
-- Inspired by Kaliel's Tracker
--
StaticPopupDialogs["CRAFTBENCH_Version"] = {
	text = "CraftBench - Version",
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
function CraftBench:ShowVersion()
	DA.DEBUG(0,"ShowVersion()")
	local wowVersion,wowBuild = GetBuildInfo();
	local text = "CraftBench "..tostring(CraftBench.version).." on "..tostring(wowVersion).."."..tostring(wowBuild)..", "..tostring(GetLocale())
	StaticPopup_Show("CRAFTBENCH_Version", text)
end

--
-- All the options that we allow the user to control.
--
CraftBench.options =
{
	handler = CraftBench,
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
					name = L["CraftBench Trade Skills"].." "..CraftBench.version,
					order = 2
				},
				use_first_name_only = {
					hidden = CraftBench.isRetail,
					type = "toggle",
					name = L["USEFIRSTONLYNAME"],
					desc = L["USEFIRSTONLYDESC"],
					get = function()
						return CraftBench.db.global.useFirstNameOnly
					end,
					set = function(self,value)
						CraftBench.db.global.useFirstNameOnly = value
					end,
					width = "full",
					order = 3
				},
				vendor_buy_button = {
					type = "toggle",
					name = L["VENDORBUYBUTTONNAME"],
					desc = L["VENDORBUYBUTTONDESC"],
					get = function()
						return CraftBench.db.profile.vendor_buy_button
					end,
					set = function(self,value)
						CraftBench.db.profile.vendor_buy_button = value
					end,
					width = "full",
					order = 12
				},
				vendor_auto_buy = {
					type = "toggle",
					name = L["VENDORAUTOBUYNAME"],
					desc = L["VENDORAUTOBUYDESC"],
					get = function()
						return CraftBench.db.profile.vendor_auto_buy
					end,
					set = function(self,value)
						CraftBench.db.profile.vendor_auto_buy = value
					end,
					width = "full",
					order = 13
				},
				show_item_notes_tooltip = {
					type = "toggle",
					name = L["SHOWITEMNOTESTOOLTIPNAME"],
					desc = L["SHOWITEMNOTESTOOLTIPDESC"],
					get = function()
						return CraftBench.db.profile.show_item_notes_tooltip
					end,
					set = function(self,value)
						CraftBench.db.profile.show_item_notes_tooltip = value
					end,
					width = "full",
					order = 14
				},
				show_crafters_tooltip = {
					type = "toggle",
					name = L["SHOWCRAFTERSTOOLTIPNAME"],
					desc = L["SHOWCRAFTERSTOOLTIPDESC"],
					get = function()
						return CraftBench.db.profile.show_crafters_tooltip
					end,
					set = function(self,value)
						CraftBench.db.profile.show_crafters_tooltip = value
					end,
					width = "full",
					order = 15
				},
				show_detailed_recipe_tooltip = {
					type = "toggle",
					name = L["SHOWDETAILEDRECIPETOOLTIPNAME"],
					desc = L["SHOWDETAILEDRECIPETOOLTIPDESC"],
					get = function()
						return CraftBench.db.profile.show_detailed_recipe_tooltip
					end,
					set = function(self,value)
						CraftBench.db.profile.show_detailed_recipe_tooltip = value
					end,
					width = "full",
					order = 16
				},
				link_craftable_reagents = {
					type = "toggle",
					name = L["LINKCRAFTABLEREAGENTSNAME"],
					desc = L["LINKCRAFTABLEREAGENTSDESC"],
					get = function()
						return CraftBench.db.profile.link_craftable_reagents
					end,
					set = function(self,value)
						CraftBench.db.profile.link_craftable_reagents = value
					end,
					width = "full",
					order = 19
				},
				queue_tools = {
					type = "toggle",
					name = L["QUEUETOOLSNAME"],
					desc = L["QUEUETOOLSDESC"],
					get = function()
						return CraftBench.db.profile.queue_tools
					end,
					set = function(self,value)
						CraftBench.db.profile.queue_tools = value
					end,
					width = 1.5,
					order = 21
				},
				ignore_banked_reagents = {
					type = "toggle",
					name = L["IGNOREBANKEDREAGENTSNAME"],
					desc = L["IGNOREBANKEDREAGENTSDESC"],
					get = function()
						return CraftBench.db.profile.ignore_banked_reagents
					end,
					set = function(self,value)
						CraftBench.db.profile.ignore_banked_reagents = value
					end,
					width = 1.5,
					order = 21
				},
				ignore_queued_reagents = {
					type = "toggle",
					name = L["IGNOREQUEUEDREAGENTSNAME"],
					desc = L["IGNOREQUEUEDREAGENTSDESC"],
					get = function()
						return CraftBench.db.profile.ignore_queued_reagents
					end,
					set = function(self,value)
						CraftBench.db.profile.ignore_queued_reagents = value
					end,
					width = 1.5,
					order = 21
				},
				queue_craftable_reagents = {
					type = "toggle",
					name = L["QUEUECRAFTABLEREAGENTSNAME"],
					desc = L["QUEUECRAFTABLEREAGENTSDESC"],
					get = function()
						return CraftBench.db.profile.queue_craftable_reagents
					end,
					set = function(self,value)
						CraftBench.db.profile.queue_craftable_reagents = value
					end,
					width = "full",
					order = 22
				},
				queue_match_trade = {
					type = "toggle",
					name = L["QUEUEMATCHTRADENAME"],
					desc = L["QUEUEMARCHTRADEDESC"],
					get = function()
						return CraftBench.db.profile.queue_match_trade
					end,
					set = function(self,value)
						CraftBench.db.profile.queue_match_trade = value
					end,
					width = 1.5,
					order = 23
				},
				queue_insert_first = {
					type = "toggle",
					name = L["QUEUEINSERTFIRSTNAME"],
					desc = L["QUEUEINSERTFIRSTDESC"],
					get = function()
						return CraftBench.db.profile.queue_insert_first
					end,
					set = function(self,value)
						CraftBench.db.profile.queue_insert_first = value
					end,
					width = 1.5,
					order = 23
				},
				queue_glyph_reagents = {
					hidden = not CraftBench.isRetail,
					type = "toggle",
					name = L["QUEUEGLYPHREAGENTSNAME"],
					desc = L["QUEUEGLYPHREAGENTSDESC"],
					get = function()
						return CraftBench.db.profile.queue_glyph_reagents
					end,
					set = function(self,value)
						CraftBench.db.profile.queue_glyph_reagents = value
					end,
					width = "full",
					order = 24
				},
				shoppingHeader = {
					type = "header",
					name = L["DISPLAYSHOPPINGLIST"],
					order = 25
				},
					display_shopping_list_at_bank = {
						type = "toggle",
						name = L["Bank"],
						desc = L["DISPLAYSHOPPINGLISTATBANKDESC"],
						get = function()
							return CraftBench.db.profile.display_shopping_list_at_bank
						end,
						set = function(self,value)
							CraftBench.db.profile.display_shopping_list_at_bank = value
						end,
							width = 0.75,
						order = 26
					},
					display_shopping_list_at_guildbank = {
						type = "toggle",
						name = L["Guild bank"],
						desc = L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"],
						get = function()
							return CraftBench.db.profile.display_shopping_list_at_guildbank
						end,
						set = function(self,value)
							CraftBench.db.profile.display_shopping_list_at_guildbank = value
						end,
							width = 0.75,
						order = 27
					},
					display_shopping_list_at_auction = {
						type = "toggle",
						name = L["Auction"],
						desc = L["DISPLAYSHOPPINGLISTATAUCTIONDESC"],
						get = function()
							return CraftBench.db.profile.display_shopping_list_at_auction
						end,
						set = function(self,value)
							CraftBench.db.profile.display_shopping_list_at_auction = value
						end,
							width = 0.75,
						order = 28
					},
					display_shopping_list_at_merchant = {
						type = "toggle",
						name = L["Merchant"],
						desc = L["DISPLAYSHOPPINGLISTATMERCHANTDESC"],
						get = function()
							return CraftBench.db.profile.display_shopping_list_at_merchant
						end,
						set = function(self,value)
							CraftBench.db.profile.display_shopping_list_at_merchant = value
						end,
							width = 0.75,
						order = 29
					},
				use_guildbank_as_alt = {
					type = "toggle",
					name = L["USEGUILDBANKASALTNAME"],
					desc = L["USEGUILDBANKASALTDESC"],
					get = function()
						return CraftBench.db.profile.use_guildbank_as_alt
					end,
					set = function(self,value)
						CraftBench.db.profile.use_guildbank_as_alt = value
						CraftBench:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 30
				},
				use_altcurrency_vendor_items = {
					type = "toggle",
					name = L["USEALTCURRVENDITEMSNAME"],
					desc = L["USEALTCURRVENDITEMSDESC"],
					get = function()
						return CraftBench.db.profile.use_altcurrency_vendor_items
					end,
					set = function(self,value)
						CraftBench.db.profile.use_altcurrency_vendor_items = value
						CraftBench:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 31
				},
			}
		},
		processing = {
			type = 'group',
			name = L["Material Processing"],
			desc = L["PROCESSINGDESC"],
			order = 3,
			args = {
				process_enabled = {
					type = "toggle",
					name = L["PROCESSENABLEDNAME"],
					desc = L["PROCESSENABLEDDESC"],
					get = function()
						return CraftBench.db.profile.process_enabled
					end,
					set = function(_, value)
						CraftBench.db.profile.process_enabled = value
					end,
					width = "full",
					order = 1,
				},
				process_modifier = {
					type = "select",
					name = L["PROCESSMODIFIERNAME"],
					desc = L["PROCESSMODIFIERDESC"],
					values = {
						ALT = "Alt",
						CTRL = "Ctrl",
						SHIFT = "Shift",
					},
					get = function()
						return CraftBench.db.profile.process_modifier
					end,
					set = function(_, value)
						CraftBench.db.profile.process_modifier = value
					end,
					order = 2,
				},
				process_max_quality = {
					type = "select",
					name = L["PROCESSMAXQUALITYNAME"],
					desc = L["PROCESSMAXQUALITYDESC"],
					values = {
						[2] = ITEM_QUALITY2_DESC or "Uncommon",
						[3] = ITEM_QUALITY3_DESC or "Rare",
						[4] = ITEM_QUALITY4_DESC or "Epic",
					},
					get = function()
						return CraftBench.db.profile.process_max_quality
					end,
					set = function(_, value)
						CraftBench.db.profile.process_max_quality = value
					end,
					order = 3,
				},
				process_disenchant = {
					type = "toggle",
					name = L["PROCESSDISENCHANTNAME"],
					desc = L["PROCESSDISENCHANTDESC"],
					get = function()
						return CraftBench.db.profile.process_disenchant
					end,
					set = function(_, value)
						CraftBench.db.profile.process_disenchant = value
					end,
					width = "full",
					order = 4,
				},
				process_prospect = {
					type = "toggle",
					name = L["PROCESSPROSPECTNAME"],
					desc = L["PROCESSPROSPECTDESC"],
					get = function()
						return CraftBench.db.profile.process_prospect
					end,
					set = function(_, value)
						CraftBench.db.profile.process_prospect = value
					end,
					width = "full",
					order = 5,
				},
				process_mill = {
					type = "toggle",
					name = L["PROCESSMILLNAME"],
					desc = L["PROCESSMILLDESC"],
					get = function()
						return CraftBench.db.profile.process_mill
					end,
					set = function(_, value)
						CraftBench.db.profile.process_mill = value
					end,
					width = "full",
					order = 6,
				},
				process_lockpick = {
					type = "toggle",
					name = L["PROCESSLOCKPICKNAME"],
					desc = L["PROCESSLOCKPICKDESC"],
					get = function()
						return CraftBench.db.profile.process_lockpick
					end,
					set = function(_, value)
						CraftBench.db.profile.process_lockpick = value
					end,
					width = "full",
					order = 7,
				},
				process_glow = {
					type = "toggle",
					name = L["PROCESSGLOWNAME"],
					desc = L["PROCESSGLOWDESC"],
					get = function()
						return CraftBench.db.profile.process_glow
					end,
					set = function(_, value)
						CraftBench.db.profile.process_glow = value
					end,
					width = "full",
					order = 8,
				},
				yieldHeader = {
					type = "header",
					name = L["PROCESSYIELDHEADER"],
					order = 9,
				},
				process_tooltip_disenchant = {
					type = "toggle",
					name = L["PROCESSTOOLTIPDENAME"],
					desc = L["PROCESSTOOLTIPDEDESC"],
					get = function()
						return CraftBench.db.profile.process_tooltip_disenchant
					end,
					set = function(_, value)
						CraftBench.db.profile.process_tooltip_disenchant = value
					end,
					width = "full",
					order = 10,
				},
				process_tooltip_prospect = {
					type = "toggle",
					name = L["PROCESSTOOLTIPPROSPECTNAME"],
					desc = L["PROCESSTOOLTIPPROSPECTDESC"],
					get = function()
						return CraftBench.db.profile.process_tooltip_prospect
					end,
					set = function(_, value)
						CraftBench.db.profile.process_tooltip_prospect = value
					end,
					width = "full",
					order = 11,
				},
				process_tooltip_mill = {
					type = "toggle",
					name = L["PROCESSTOOLTIPMILLNAME"],
					desc = L["PROCESSTOOLTIPMILLDESC"],
					get = function()
						return CraftBench.db.profile.process_tooltip_mill
					end,
					set = function(_, value)
						CraftBench.db.profile.process_tooltip_mill = value
					end,
					width = "full",
					order = 12,
				},
				process_tooltip_value = {
					type = "toggle",
					name = L["PROCESSTOOLTIPVALUENAME"],
					desc = L["PROCESSTOOLTIPVALUEDESC"],
					get = function()
						return CraftBench.db.profile.process_tooltip_value
					end,
					set = function(_, value)
						CraftBench.db.profile.process_tooltip_value = value
					end,
					width = "full",
					order = 13,
				},
				open_process_panel = {
					type = "execute",
					name = L["PROCESS_PANEL_OPEN"],
					desc = L["PROCESS_PANEL_OPEN_DESC"],
					func = function()
						if CraftBench.ShowProcessPanel then
							CraftBench:ShowProcessPanel()
						end
					end,
					order = 14,
				},
				autopopupHeader = {
					type = "header",
					name = L["PROCESS_AUTOPOPUP_HEADER"],
					order = 15,
				},
				process_autopopup = {
					type = "toggle",
					name = L["PROCESS_AUTOPOPUP_NAME"],
					desc = L["PROCESS_AUTOPOPUP_DESC"],
					get = function()
						return CraftBench.db.profile.process_autopopup
					end,
					set = function(_, value)
						CraftBench.db.profile.process_autopopup = value
						if value and CraftBench.CheckAutoProcessPrompt then
							CraftBench:CheckAutoProcessPrompt()
						end
					end,
					width = "full",
					order = 16,
				},
				process_autopopup_clear_ignore = {
					type = "execute",
					name = L["PROCESS_AUTOPOPUP_CLEAR"],
					desc = L["PROCESS_AUTOPOPUP_CLEAR_DESC"],
					func = function()
						if CraftBench.ClearAutoProcessIgnores then
							CraftBench:ClearAutoProcessIgnores()
						end
					end,
					order = 17,
				},
			},
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
						return CraftBench.db.profile.display_required_level
					end,
					set = function(self,value)
						CraftBench.db.profile.display_required_level = value
						CraftBench:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 1
				},
				show_max_upgrade = {
					type = "toggle",
					name = L["SHOWMAXUPGRADENAME"],
					desc = L["SHOWMAXUPGRADEDESC"],
					get = function()
						return CraftBench.db.profile.show_max_upgrade
					end,
					set = function(self,value)
						CraftBench.db.profile.show_max_upgrade = value
						CraftBench:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 2
				},
				show_craft_counts = {
					type = "toggle",
					name = L["SHOWCRAFTCOUNTSNAME"],
					desc = L["SHOWCRAFTCOUNTSDESC"],
					get = function()
						return CraftBench.db.profile.show_craft_counts
					end,
					set = function(self,value)
						CraftBench.db.profile.show_craft_counts = value
						CraftBench:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 3
				},
				recipe_source_first = {
					type = "toggle",
					name = L["RECIPESOURCEFIRSTNAME"],
					desc = L["RECIPESOURCEFIRSTDESC"],
					get = function()
						return CraftBench.db.profile.recipe_source_first
					end,
					set = function(self,value)
						CraftBench.db.profile.recipe_source_first = value
					end,
					width = 1.5,
					order = 4
				},
				show_recipe_source_for_learned = {
					type = "toggle",
					name = L["SHOWRECIPESOURCEFORLEARNEDNAME"],
					desc = L["SHOWRECIPESOURCEFORLEARNEDDESC"],
					get = function()
						return CraftBench.db.profile.show_recipe_source_for_learned
					end,
					set = function(self,value)
						CraftBench.db.profile.show_recipe_source_for_learned = value
					end,
					width = 1.5,
					order = 5
				},
				use_blizzard_for_followers = {
					hidden = not CraftBench.isRetail,
					type = "toggle",
					name = L["USEBLIZZARDFORFOLLOWERSNAME"],
					desc = L["USEBLIZZARDFORFOLLOWERSDESC"],
					get = function()
						return CraftBench.db.profile.use_blizzard_for_followers
					end,
					set = function(self,value)
						CraftBench.db.profile.use_blizzard_for_followers = value
					end,
					width = "full",
					order = 6
				},
				always_show_progress_bar = {
					type = "toggle",
					name = L["SHOWPROGRESSBARNAME"],
					desc = L["SHOWPROGRESSBARDESC"],
					get = function()
						return CraftBench.db.profile.always_show_progress_bar
					end,
					set = function(self,value)
						CraftBench.db.profile.always_show_progress_bar = value
					end,
					width = "full",
					order = 7
				},
				hide_blizzard_frame = {
					hidden = CraftBench.isRetail,
					type = "toggle",
					name = L["HIDEBLIZZARDFRAMENAME"],
					desc = L["HIDEBLIZZARDFRAMEDESC"],
					get = function()
						return CraftBench.db.profile.hide_blizzard_frame
					end,
					set = function(self,value)
						CraftBench.db.profile.hide_blizzard_frame = value
						if not value and ProfessionsFrame then
							ProfessionsFrame:SetScale(1.0)
						end
						if value and CraftBench.db.profile.scale_blizzard_frame then
							CraftBench.db.profile.scale_blizzard_frame = false
						end
					end,
					width = 1.5,
					order = 7
				},
				scale_blizzard_frame = {
					hidden = CraftBench.isRetail,
					type = "toggle",
					name = L["SCALEBLIZZARDFRAMENAME"],
					desc = L["SCALEBLIZZARDFRAMEDESC"],
					get = function()
						return CraftBench.db.profile.scale_blizzard_frame
					end,
					set = function(self,value)
						CraftBench.db.profile.scale_blizzard_frame = value
						if not value and ProfessionsFrame then
							ProfessionsFrame:SetScale(1.0)
						end
						if value and CraftBench.db.profile.hide_blizzard_frame then
							CraftBench.db.profile.hide_blizzard_frame = false
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
						return CraftBench.db.profile.select_top_recipe
					end,
					set = function(self,value)
						CraftBench.db.profile.select_top_recipe = value
						CraftBench:UpdateTradeSkillWindow()
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
						return CraftBench.db.profile.enhanced_recipe_display
					end,
					set = function(self,value)
						CraftBench.db.profile.enhanced_recipe_display = value
						CraftBench:UpdateTradeSkillWindow()
					end,
					width = 1.5,
					order = 9
				},
				enhanced_chance_display = {
					type = "toggle",
					name = L["ENHANCHEDCHANCEDISPLAYNAME"],
					desc = L["ENHANCHEDCHANCEDISPLAYDESC"],
					get = function()
						return CraftBench.db.profile.enhanced_chance_display
					end,
					set = function(self,value)
						CraftBench.db.profile.enhanced_chance_display = value
						CraftBench:UpdateTradeSkillWindow()
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
						return CraftBench.db.profile.confirm_queue_clear
					end,
					set = function(self,value)
						CraftBench.db.profile.confirm_queue_clear = value
						CraftBench:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 10
				},
				queue_only_view = {
					type = "toggle",
					name = L["QUEUEONLYVIEWNAME"],
					desc = L["QUEUEONLYVIEWDESC"],
					get = function()
						return CraftBench.db.profile.queue_only_view
					end,
					set = function(self,value)
						CraftBench.db.profile.queue_only_view = value
						CraftBench:UpdateTradeSkillWindow()
					end,
					width = "full",
					order = 11
				},
				dialog_switch = {
					type = "toggle",
					name = L["DIALOGSWITCHNAME"],
					desc = L["DIALOGSWITCHDESC"],
					get = function()
						return CraftBench.db.profile.dialog_switch
					end,
					set = function(self,value)
						CraftBench.db.profile.dialog_switch = value
					end,
					width = "full",
					order = 12
				},
				tsm_compat = {
					type = "toggle",
					name = L["TSMCOMPATNAME"],
					desc = L["TSMCOMPATDESC"],
					get = function()
						return CraftBench.db.profile.tsm_compat
					end,
					set = function(self,value)
						CraftBench.db.profile.tsm_compat = value
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
						return CraftBench.db.profile.tsm_prefer
					end,
					set = function(self,value)
						CraftBench.db.profile.tsm_prefer = value
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
						return CraftBench.db.profile.scale_tooltip
					end,
					set = function(self,value)
						CraftBench.db.profile.scale_tooltip = value
					end,
					width = "full",
					order = 14
				},
				sound_on_empty_queue = {
					type = "toggle",
					name = L["SOUNDONEMPTYQUEUENAME"],
					desc = L["SOUNDONEMPTYQUEUEDESC"],
					get = function()
						return CraftBench.db.profile.sound_on_empty_queue
					end,
					set = function(self,value)
						CraftBench.db.profile.sound_on_empty_queue = value
					end,
					width = 1.5,
					order = 15,
				},
				flash_on_empty_queue = {
					type = "toggle",
					name = L["FLASHONEMPTYQUEUENAME"],
					desc = L["FLASHONEMPTYQUEUEDESC"],
					get = function()
						return CraftBench.db.profile.flash_on_empty_queue
					end,
					set = function(self,value)
						CraftBench.db.profile.flash_on_empty_queue = value
					end,
					width = 1.5,
					order = 16,
				},
				sound_on_remove_queue = {
					type = "toggle",
					name = L["SOUNDONREMOVEQUEUENAME"],
					desc = L["SOUNDONREMOVEQUEUEDESC"],
					get = function()
						return CraftBench.db.profile.sound_on_remove_queue
					end,
					set = function(self,value)
						CraftBench.db.profile.sound_on_remove_queue = value
					end,
					width = 1.5,
					order = 17,
				},
				flash_on_remove_queue = {
					type = "toggle",
					name = L["FLASHONREMOVEQUEUENAME"],
					desc = L["FLASHONREMOVEQUEUEDESC"],
					get = function()
						return CraftBench.db.profile.flash_on_remove_queue
					end,
					set = function(self,value)
						CraftBench.db.profile.flash_on_remove_queue = value
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
						return CraftBench.db.profile.transparency
					end,
					set = function(self,t)
						CraftBench.db.profile.transparency = t
						CraftBench:UpdateTradeSkillWindow()
						CraftBench:UpdateShoppingListWindow(false)
						CraftBench:UpdateStandaloneQueueWindow()
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
						return CraftBench.db.profile.scale
					end,
					set = function(self,t)
						CraftBench.db.profile.scale = t
						CraftBench:UpdateTradeSkillWindow()
						CraftBench:UpdateShoppingListWindow(false)
						CraftBench:UpdateStandaloneQueueWindow()
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
						return CraftBench.db.profile.ttscale
					end,
					set = function(self,t)
						CraftBench.db.profile.ttscale = t
						CraftBench:UpdateTradeSkillWindow()
						CraftBench:UpdateShoppingListWindow(false)
						CraftBench:UpdateStandaloneQueueWindow()
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
					CraftBench:ShowOptions()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					if CraftBench:IsShoppingListVisible() then
						CraftBench:HideShoppingList()
					else
						CraftBench:DisplayShoppingList(false)
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:ClearShoppingList()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction." .." Leave combat and try again.")
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
					CraftBench:FlushAllData()
					CraftBench.CleanDatabase = true
					CraftBench:InitializeDatabase(CraftBench:unitName("player"))
					CraftBench.CleanDatabase = false
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:FlushRecipeData()
					CraftBench:InitializeDatabase(CraftBench:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:FlushCustomData()
					CraftBench:InitializeDatabase(CraftBench:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:FlushQueueData()
					CraftBench:InitializeDatabase(CraftBench:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:FlushPlayerData()
					CraftBench:InitializeDatabase(CraftBench:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:FlushDetailData()
					CraftBench:InitializeDatabase(CraftBench:unitName("player"))
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 59
		},
		collectdetails = {
			type = "toggle",
			name = L["Collect details"],
			desc = L["Disable/Enable collecting bag, bank, guildbank details"],
			get = function()
				return CraftBench.db.profile.collect_details
			end,
			set = function(self,value)
				CraftBench.db.profile.collect_details = value
			end,
			order = 60
		},
		standby = {
			type = 'execute',
			name = L["STANDBYNAME"],
			desc = L["STANDBYDESC"],
			func = function()
				if CraftBench:IsEnabled() then
					CraftBench:Disable()
					CraftBench:Print(RED_FONT_COLOR_CODE..L["is now disabled"]..FONT_COLOR_CODE_CLOSE)
				else
					CraftBench:Enable()
					CraftBench:Print(GREEN_FONT_COLOR_CODE..L["is now enabled"]..FONT_COLOR_CODE_CLOSE)
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
					CraftBench:DisplayIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:ClearIgnoreList()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
				return CraftBench.db.realm.userIgnoredMats[CraftBench:unitName("player")][value]
			end,
			set = function(self,value)
				local value = tonumber(value)
				CraftBench.db.realm.userIgnoredMats[CraftBench:unitName("player")][value] = 1
			end,
			order = 64
		},
		ignoredel = {
			type = "input",
			name = "IgnoreDel",
			desc = "Delete from userIgnoredMats",
			get = function()
				local value = tonumber(value)
				return CraftBench.db.realm.userIgnoredMats[CraftBench:unitName("player")][value]
			end,
			set = function(self,value)
				local value = tonumber(value)
				CraftBench.db.realm.userIgnoredMats[CraftBench:unitName("player")][value] = nil
			end,
			order = 65
		},
		resetrecipefilter = {
			type = 'execute',
			name = L["Reset Recipe Filter"],
			desc = L["RESETRECIPEFILTERDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftBench:ResetTradeSkillFilter()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
--				print("CraftBench "..tostring(CraftBench.version).." on "..tostring(wowVersion).."."..tostring(wowBuild)..", "..tostring(GetLocale()))
			CraftBench:ShowVersion()
			end,
			order = 66
		},
		printsaved = {
			type = 'execute',
			name = "PrintSaved",
			desc = "Print list of SavedQueues",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftBench:PrintSaved()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:PrintQueue()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:PrintAllQueues()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:PrintQueue(value)
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:ClearQueue()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:PrintAuctionData()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:PrintRIQ()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
					CraftBench:PrintShoppingList()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
				return CraftBench.data.btsui
			end,
			set = function(self,value)
				CraftBench.data.btsui = value
				local blizzFrame = ProfessionsFrame or TradeSkillFrame
				if not blizzFrame then return end
				if value then
					ShowUIPanel(blizzFrame)
					CraftBench.BlizzardUIshowing = true
				else
					HideUIPanel(blizzFrame)
					CraftBench.BlizzardUIshowing = false
				end
			end,
			order = 74
		},
		bcui = {
			type = "toggle",
			name = "BCUI",
			desc = "Show/Hide the Blizzard Crafting frame",
			get = function()
				return CraftBench.data.bcui
			end,
			set = function(self,value)
				CraftBench.data.bcui = value
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
				return CraftBench.db.profile.scale_blizzard_down
			end,
			set = function(self,value)
				local value = tonumber(value)
				if value then
					if value < 0.1 then
						value = 0.1
					elseif value > 1.0 then
						value = 1.0
					end
					CraftBench.db.profile.scale_blizzard_down = value
				else
					print("scalesmall= "..tostring(CraftBench.db.profile.scale_blizzard_down))
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
				return CraftBench.db.profile.scale_blizzard_up
			end,
			set = function(self,value)
				local value = tonumber(value)
				if value then
					if value < 0.1 then
						value = 0.1
					elseif value > 1.0 then
						value = 1.0
					end
					CraftBench.db.profile.scale_blizzard_up = value
				else
					print("scalelarge= "..tostring(CraftBench.db.profile.scale_blizzard_up))
				end
			end,
			order = 75
		},
--
-- commands to update CraftBench's main windows
--
		uslw = {
			type = 'execute',
			name = "UpdateShoppingListWindow",
			desc = "Update (CraftBench's) Shopping List Window",
			func = function()
				CraftBench:UpdateShoppingListWindow(false)
			end,
			order = 76
		},
		utsw = {
			type = 'execute',
			name = "UpdateTradeSkillWindow",
			desc = "Update (CraftBench's) TradeSkill Window",
			func = function()
				CraftBench:UpdateTradeSkillWindow()
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
				return CraftBench.data.customgroups
			end,
			set = function(self,value)
				CraftBench.data.customgroups = value
				if value then
					CraftBenchRecipeGroupOperations:Enable()
				else
					CraftBenchRecipeGroupOperations:Disable()
				end
			end,
			order = 78
		},
		nomodkeys = {
			type = "toggle",
			name = "NoModKeys",
			desc = "Disable/Enable Mod Keys to open the Blizzard frames",
			get = function()
				return CraftBench.db.profile.nomodkeys
			end,
			set = function(self,value)
				CraftBench.db.profile.nomodkeys = value
			end,
			order = 79
		},
		swapshiftkey = {
			type = "toggle",
			name = "SwapShiftKey",
			desc = "Swap Shift Key to open the Blizzard frames",
			get = function()
				return CraftBench.db.profile.swapshiftkey
			end,
			set = function(self,value)
				CraftBench.db.profile.swapshiftkey = value
			end,
			order = 80
		},
		initskilllevels = {
			type = 'execute',
			name = "Init Skill Levels",
			desc = "Initialize Skill Levels",
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftBench:InitializeSkillLevels()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 81
		},
		news = {
			type = 'execute',
			name = L["Display news"],
			desc = L["Display the news frame"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					CraftBench.NewsGUI:Toggle()
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
				return CraftBench.db.profile.WarnShow
			end,
			set = function(self,value)
				CraftBench.db.profile.WarnShow = value
				CraftBench.WarnShow = value
				if value then
					CraftBench.db.profile.WarnLog = value
					CraftBench.WarnLog = value
				end
			end,
			order = 81
		},
		WarnLog = {
			type = "toggle",
			name = "WarnLog",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.WarnLog
			end,
			set = function(self,value)
				CraftBench.db.profile.WarnLog = value
				CraftBench.WarnLog = value
			end,
			order = 82
		},
		DebugShow = {
			type = "toggle",
			name = "DebugShow",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.DebugShow
			end,
			set = function(self,value)
				CraftBench.db.profile.DebugShow = value
				CraftBench.DebugShow = value
				if value then
					CraftBench.db.profile.DebugLogging = value
					CraftBench.DebugLogging = value
				end
			end,
			order = 83
		},
		DebugLogging = {
			type = "toggle",
			name = "DebugLogging",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.DebugLogging
			end,
			set = function(self,value)
				CraftBench.db.profile.DebugLogging = value
				CraftBench.DebugLogging = value
			end,
			order = 84
		},
		DebugLevel = {
			type = "input",
			name = "DebugLevel",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.DebugLevel
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 1
				elseif value < 1 then value = 1
				elseif value > 9 then value = 10 end
				CraftBench.db.profile.DebugLevel = value
				CraftBench.DebugLevel = value
			end,
			order = 85
		},
		TableDump = {
			type = "toggle",
			name = "TableDump",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.TableDump
			end,
			set = function(self,value)
				CraftBench.db.profile.TableDump = value
				CraftBench.TableDump = value
			end,
			order = 86
		},
		TraceShow = {
			type = "toggle",
			name = "TraceShow",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.TraceShow
			end,
			set = function(self,value)
				CraftBench.db.profile.TraceShow = value
				CraftBench.TraceShow = value
				if value then
					CraftBench.db.profile.TraceLog = value
					CraftBench.TraceLog = value
				end
			end,
			order = 87
		},
		TraceLog = {
			type = "toggle",
			name = "TraceLog",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.TraceLog
			end,
			set = function(self,value)
				CraftBench.db.profile.TraceLog = value
				CraftBench.TraceLog = value
			end,
			order = 88
		},
		TraceLog2 = {
			type = "toggle",
			name = "TraceLog2",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.TraceLog2
			end,
			set = function(self,value)
				CraftBench.db.profile.TraceLog2 = value
				CraftBench.TraceLog2 = value
			end,
			order = 88
		},
		TraceLog3 = {
			type = "toggle",
			name = "TraceLog3",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.TraceLog3
			end,
			set = function(self,value)
				CraftBench.db.profile.TraceLog3 = value
				CraftBench.TraceLog3 = value
			end,
			order = 88
		},
		ProfileShow = {
			type = "toggle",
			name = "ProfileShow",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.ProfileShow
			end,
			set = function(self,value)
				CraftBench.db.profile.ProfileShow = value
				CraftBench.ProfileShow = value
			end,
			order = 89
		},
		ClearDebugLog = {
			type = "execute",
			name = "ClearDebugLog",
			desc = "Option for debugging",
			func = function()
				CraftBenchDBPC = {}
				DA.DebugLog = CraftBenchDBPC
			end,
			order = 90
		},
		ClearProfileLog = {
			type = "execute",
			name = "ClearProfileLog",
			desc = "Option for debugging",
			func = function()
				CraftBenchProfile = {}
				DA.DebugProfile = CraftBenchProfile
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
				if CraftBench.db.profile.WarnShow then
					CraftBench.db.profile.WarnShow = true
					CraftBench.WarnShow = true
				end
				if CraftBench.db.profile.WarnLog then
					CraftBench.db.profile.WarnLog = true
					CraftBench.WarnLog = true
				end
				if CraftBench.db.profile.DebugShow then
					CraftBench.db.profile.DebugShow= true
					CraftBench.DebugShow = true
				end
				if CraftBench.db.profile.DebugLogging then
					CraftBench.db.profile.DebugLogging = true
					CraftBench.DebugLogging = true
				end
				if CraftBench.db.profile.DebugLevel then
					CraftBench.db.profile.DebugLevel = 4
				end
				if CraftBench.db.profile.TableDump then
					CraftBench.db.profile.TableDump = true
				end
--
-- LogLevel is left undefined or set to false as
-- the default should be log everything.
--
				if CraftBench.db.profile.LogLevel then
					CraftBench.db.profile.LogLevel = false
					CraftBench.LogLevel = false
				end
				if CraftBench.db.profile.TraceShow then
					CraftBench.db.profile.TraceShow = true
					CraftBench.TraceShow = true
				end
				if CraftBench.db.profile.TraceLog then
					CraftBench.db.profile.TraceLog = true
					CraftBench.TraceLog = true
				end
				if CraftBench.db.profile.TraceLog2 then
					CraftBench.db.profile.TraceLog2 = false
					CraftBench.TraceLog2 = false
				end
				if CraftBench.db.profile.TraceLog3 then
					CraftBench.db.profile.TraceLog3 = false
					CraftBench.TraceLog3 = false
				end
				if CraftBench.db.profile.ProfileShow then
					CraftBench.db.profile.ProfileShow = false
					CraftBench.ProfileShow = false
				end
--]]
				DA.DEBUGON()
				CraftBench:Print(GREEN_FONT_COLOR_CODE.."DebugOn:"..FONT_COLOR_CODE_CLOSE)
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
				if CraftBench.db.profile.WarnShow then
					CraftBench.db.profile.WarnShow = false
					CraftBench.WarnShow = false
				end
				if CraftBench.db.profile.WarnLog then
					CraftBench.db.profile.WarnLog = false
					CraftBench.WarnLog = false
				end
				if CraftBench.db.profile.DebugShow then
					CraftBench.db.profile.DebugShow= false
					CraftBench.DebugShow = false
				end
				if CraftBench.db.profile.DebugLogging then
					CraftBench.db.profile.DebugLogging = false
					CraftBench.DebugLogging = false
				end
--
-- DebugLevel is left alone but
-- LogLevel is left undefined or set to false as
-- the default should be log everything.
--
				if CraftBench.db.profile.LogLevel then
					CraftBench.db.profile.LogLevel = false
					CraftBench.LogLevel = false
				end
				if CraftBench.db.profile.TraceShow then
					CraftBench.db.profile.TraceShow = false
					CraftBench.TraceShow = false
				end
				if CraftBench.db.profile.TraceLog then
					CraftBench.db.profile.TraceLog = false
					CraftBench.TraceLog = false
				end
				if CraftBench.db.profile.TraceLog2 then
					CraftBench.db.profile.TraceLog2 = false
					CraftBench.TraceLog2 = false
				end
				if CraftBench.db.profile.TraceLog3 then
					CraftBench.db.profile.TraceLog3 = false
					CraftBench.TraceLog3 = false
				end
				if CraftBench.db.profile.ProfileShow then
					CraftBench.db.profile.ProfileShow = false
					CraftBench.ProfileShow = false
				end
--]]
				DA.DEBUGOFF()
				CraftBench:Print(RED_FONT_COLOR_CODE.."DebugOff:"..FONT_COLOR_CODE_CLOSE)
				DA.DebugAidsStatus()
			end,
			order = 93
		},
		LogLevel = {
			type = "toggle",
			name = "LogLevel",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.LogLevel
			end,
			set = function(self,value)
				CraftBench.db.profile.LogLevel = value
				CraftBench.LogLevel = value
			end,
			order = 94
		},
		MaxDebug = {
			type = "input",
			name = "MaxDebug",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.MAXDEBUG
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 4000 end
				CraftBench.db.profile.MAXDEBUG = value
				CraftBench.MAXDEBUG = value
			end,
			order = 95
		},
		MaxProfile = {
			type = "input",
			name = "MaxProfile",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.MAXPROFILE
			end,
			set = function(self,value)
				value = tonumber(value)
				if not value then value = 2000 end
				CraftBench.db.profile.MAXPROFILE = value
				CraftBench.MAXPROFILE = value
			end,
			order = 96
		},
		FixBugs = {
			type = "toggle",
			name = "FixBugs",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.FixBugs
			end,
			set = function(self,value)
				CraftBench.db.profile.FixBugs = value
				CraftBench.FixBugs = value
				if value then
					CraftBench.db.profile.TraceLog = value
					CraftBench.TraceLog = value
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
-- command to reset the position of the major CraftBench frames
--
		reset = {
			type = 'execute',
			name = L["Reset"],
			desc = L["RESETDESC"],
			func = function()
				if not (UnitAffectingCombat("player")) then
					local windowManager = LibStub("LibWindow-1.1")
					if CraftBenchFrame and CraftBenchFrame:IsVisible() then
						CraftBenchFrame:SetWidth(750);
						CraftBenchFrame:SetHeight(580);
						CraftBenchFrame:SetPoint("TOPLEFT",200,-100);
						windowManager.SavePosition(CraftBenchFrame)
					end
					if CraftBenchStandaloneQueue and CraftBenchStandaloneQueue:IsVisible() then
						CraftBenchStandaloneQueue:SetWidth(385);
						CraftBenchStandaloneQueue:SetHeight(170);
						CraftBenchStandaloneQueue:SetPoint("TOPLEFT",950,-100);
						windowManager.SavePosition(CraftBenchStandaloneQueue)
					end
					if CraftBenchShoppingList and CraftBenchShoppingList:IsVisible() then
						CraftBenchShoppingList:SetWidth(385);
						CraftBenchShoppingList:SetHeight(240);
						CraftBenchShoppingList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftBenchShoppingList)
					end
					if CraftBenchIgnoreList and CraftBenchIgnoreList:IsVisible() then
						CraftBenchIgnoreList:SetWidth(320);
						CraftBenchIgnoreList:SetHeight(150);
						CraftBenchIgnoreList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftBenchIgnoreList)
					end
					if CraftBenchOptionalList and CraftBenchOptionalList:IsVisible() then
						CraftBenchOptionalList:SetWidth(420);
						CraftBenchOptionalList:SetHeight(230);
						CraftBenchOptionalList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftBenchOptionalList)
					end
					if CraftBenchModifiedList and CraftBenchModifiedList:IsVisible() then
						CraftBenchModifiedList:SetWidth(420);
						CraftBenchModifiedList:SetHeight(230);
						CraftBenchModifiedList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftBenchModifiedList)
					end
					if CraftBenchSalvageList and CraftBenchSalvageList:IsVisible() then
						CraftBenchSalvageList:SetWidth(420);
						CraftBenchSalvageList:SetHeight(230);
						CraftBenchSalvageList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftBenchSalvageList)
					end
					if CraftBenchFinishingList and CraftBenchFinishingList:IsVisible() then
						CraftBenchFinishingList:SetWidth(420);
						CraftBenchFinishingList:SetHeight(230);
						CraftBenchFinishingList:SetPoint("TOPLEFT",950,-400);
						windowManager.SavePosition(CraftBenchFinishingList)
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 99
		},
		BlizzOR = {
			type = "toggle",
			name = "BlizzOR",
			desc = "Option for debugging",
			get = function()
				return CraftBench.db.profile.BlizzOR
			end,
			set = function(self,value)
				CraftBench.db.profile.BlizzOR = value
				CraftBench.BlizzOR = value
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
				return CraftBench.FakeIt
			end,
			set = function(self,value)
				CraftBench.FakeIt = value
				if CraftBench.FakeIt then
					CraftBench:Print(RED_FONT_COLOR_CODE.."FakeIt is on"..FONT_COLOR_CODE_CLOSE)
				else
					CraftBench:Print(GREEN_FONT_COLOR_CODE.."FakeIt is off"..FONT_COLOR_CODE_CLOSE)
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
						local server = CraftBench.data.server or 0
						DA.DEBUG(0,"value= "..value)
						item, price = strsplit(",",value)
						if string.find(item,"|H") then
							id = CraftBench:GetItemIDFromLink(item)
						else
							id = tonumber(item)
						end
						name, link = C_Item.GetItemInfo(id)
						price = tonumber(price)
						DA.DEBUG(0,"id= "..tostring(id)..", name= "..tostring(name)..", price= "..tostring(price)..", link= "..tostring(link))
						CraftBench.db.global.customPrice[server][id] = { ["name"] = name, ["value"] = price }
						end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction." .." Leave combat and try again.")
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
						local server = CraftBench.data.server or 0
						DA.DEBUG(0,"value= "..value)
						if string.find(value,"|H") then
							id = CraftBench:GetItemIDFromLink(value)
						else
							id = tonumber(value)
						end
						CraftBench.db.global.customPrice[server][id] = nil
						end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 106
		},
		customshow = {
			type = 'execute',
			name = "customshow",
			desc = "Print the custom reagent price table",
			func = function()
				local server = CraftBench.data.server or 0
				for id,entry in pairs(CraftBench.db.global.customPrice[server]) do
					print(tostring(entry.name)..", "..CraftBench:FormatMoneyFull(entry.value,true))
				end
			end,
			order = 107
		},
		customdump = {
			type = 'execute',
			name = "customdump",
			desc = "Print the custom reagent price table",
			func = function()
				local server = CraftBench.data.server or 0
				for id,entry in pairs(CraftBench.db.global.customPrice[server]) do
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
				local server = CraftBench.data.server or 0
				CraftBench.db.global.customPrice[server] = {}
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
						local player = CraftBench.currentPlayer
						DA.DEBUG(0,"value= "..value)
						item, data = strsplit(",",value)
						if string.find(item,"|H") then
							id = CraftBench:GetItemIDFromLink(item)
						else
							id = tonumber(item)
						end
						name, link = C_Item.GetItemInfo(id)
						data = tonumber(data)
						DA.DEBUG(0,"id= "..tostring(id)..", name= "..tostring(name)..", data= "..tostring(data)..", link= "..tostring(link))
						CraftBench.db.realm.toolData[player][id] = { ["name"] = name, ["value"] = data }
						end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
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
						local player = CraftBench.currentPlayer
						DA.DEBUG(0,"value= "..value)
						if string.find(value,"|H") then
							id = CraftBench:GetItemIDFromLink(value)
						else
							id = tonumber(value)
						end
						CraftBench.db.realm.toolData[player][id] = nil
						end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
			order = 121
		},
		tooldump = {
			type = 'execute',
			name = "tooldump",
			desc = "Print the toolData table",
			func = function()
				local player = CraftBench.currentPlayer
				if next(CraftBench.db.realm.toolData[player]) == nil then
					print("toolData is empty")
				end
				for id,entry in pairs(CraftBench.db.realm.toolData[player]) do
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
				local player = CraftBench.currentPlayer
				CraftBench.db.realm.toolData[player] = {}
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
				return CraftBench.MissAll
			end,
			set = function(self,value)
				CraftBench.MissAll = value
				if CraftBench.MissAll then
					CraftBench:Print(RED_FONT_COLOR_CODE.."MissAll is on"..FONT_COLOR_CODE_CLOSE)
				else
					CraftBench:Print(GREEN_FONT_COLOR_CODE.."MissAll is off"..FONT_COLOR_CODE_CLOSE)
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
						for id,entry in pairs(CraftBench.db.global.MissingVendorItems) do
							if type(entry) == 'table' then	-- table entries are {name, quantity, currencyName, currencyID, currencyCount}
								if #entry ~= tonumber(value) then
									print("id= "..tostring(id)..", size= "..tostring(#entry)..", "..DA.DUMP(entry))
								end
							end
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction." .." Leave combat and try again.")
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
					if not CraftBench.db.global.RemovedVendorItems then
						CraftBench.db.global.RemovedVendorItems = {}
					end
					for id,entry in pairs(CraftBench.db.global.MissingVendorItems) do
						if type(entry) == 'table' then
							local size = #entry
							if not (size == 5 or size == 9) then
								print("id= "..tostring(id)..", size= "..tostring(size)..", "..DA.DUMP(entry))
								CraftBench.db.global.RemovedVendorItems[id] = entry
								CraftBench.db.global.MissingVendorItems[id] = nil
							end
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 113
		},
		missingclear = {
			type = 'execute',
			name = "missingclear",
			desc = "Clear the MissingVendorItems table",
			func = function()
				CraftBench.db.global.MissingVendorItems = {}
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
					if CraftBench.db.global.RemovedVendorItems then
						for id,entry in pairs(CraftBench.db.global.RemovedVendorItems) do
							print("id= "..tostring(id)..", size= "..tostring(#entry)..", "..DA.DUMP(entry))
						end
					end
				else
					DA.DEBUG(0,"|cff8888ffCraftBench|r: Combat lockdown restriction." .." Leave combat and try again.")
				end
			end,
			order = 116
		},
		removedclear = {
			type = 'execute',
			name = "removedclear",
			desc = "Clear the RemovedVendorItems table",
			func = function()
				CraftBench.db.global.RemovedVendorItems = {}
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
				return CraftBench.BagEvents
			end,
			set = function(self,value)
				CraftBench.BagEvents = value
				if CraftBench.BagEvents then
					CraftBench:UnregisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
					CraftBench:UnregisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPDATE events for a specific action have been fired.
					CraftBench:UnregisterEvent("UNIT_INVENTORY_CHANGED")	-- BAG_UPDATE_DELAYED seems to have disappeared. Using this instead.
					CraftBench:Print(RED_FONT_COLOR_CODE.."BAG_UPDATE events are off"..FONT_COLOR_CODE_CLOSE)
				else
					CraftBench:RegisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
					CraftBench:RegisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPDATE events for a specific action have been fired.
					CraftBench:RegisterEvent("UNIT_INVENTORY_CHANGED")	-- BAG_UPDATE_DELAYED seems to have disappeared. Using this instead.
					CraftBench:Print(GREEN_FONT_COLOR_CODE.."BAG_UPDATE events are on"..FONT_COLOR_CODE_CLOSE)
				end
			end,
			order = 120
		},
		bagcounts = {
			type = 'execute',
			name = "bagcounts",
			desc = "Option for debugging",
			func = function()
				CraftBench:Print("bagUpdateCounts= "..DA.DUMP1(CraftBench.bagUpdateCounts))
				CraftBench:Print("bagUpdateDelayedCount= "..tostring(CraftBench.bagUpdateDelayedCount))
				CraftBench:Print("unitInventoryChangedCount= "..tostring(CraftBench.unitInventoryChangedCount))
				CraftBench:Print("bankUpdateCount= "..tostring(CraftBench.bankUpdateCount))
			end,
			order = 121
		},
		options = {
			type = 'execute',
			name = L["Options"],
			desc = L["Open standalone CraftBench options window"],
			func = function()
				if CraftBench.Share and CraftBench.Share.OpenOptions then
					CraftBench.Share:OpenOptions()
				else
					CraftBench:ShowOptions()
				end
			end,
			order = 115
		},
		export = {
			type = 'execute',
			name = L["Export Queue"],
			desc = L["Export current crafting queue as a shareable string"],
			func = function()
				if CraftBench.Share then
					CraftBench.Share:ShowExportDialog()
				end
			end,
			order = 116
		},
		import = {
			type = 'execute',
			name = L["Import Queue"],
			desc = L["Import a crafting queue from a shareable string"],
			func = function()
				if CraftBench.Share then
					CraftBench.Share:ShowImportDialog()
				end
			end,
			order = 117
		},
		sendqueue = {
			type = 'input',
			name = L["Send Queue"],
			desc = L["Send current queue via AceComm (e.g. GUILD, PARTY, or WHISPER <player>)"],
			set = function(_, val)
				if CraftBench.Share then
					local dist, target = strsplit(" ", val or "", 2)
					CraftBench.Share:SendQueue(dist, target)
				end
			end,
			order = 118
		},
		minimap = {
			type = 'toggle',
			name = L["Minimap Button"],
			desc = L["Show or hide the CraftBench minimap button"],
			get = function()
				return not (CraftBench.db and CraftBench.db.profile and CraftBench.db.profile.minimap and CraftBench.db.profile.minimap.hide)
			end,
			set = function(_, val)
				if CraftBench.Share then
					CraftBench.Share:ToggleMinimapIcon(val)
				end
			end,
			order = 119
		},
		find = {
			type = 'execute',
			name = L["ALT_FINDER_TITLE"],
			desc = L["ALT_FINDER_DESC"],
			func = function()
				if CraftBench.ShowAltFinder then
					CraftBench:ShowAltFinder()
				end
			end,
			order = 120
		},
		process = {
			type = 'execute',
			name = L["PROCESS_PANEL_OPEN"],
			desc = L["PROCESS_PANEL_OPEN_DESC"],
			func = function()
				if CraftBench.ShowProcessPanel then
					CraftBench:ShowProcessPanel()
				end
			end,
			order = 121
		},
		fishing = {
			type = 'group',
			name = L["Fishing"] or "Fishing",
			order = 3.5,
			args = {
				header = {
					type = 'header',
					name = L["Fishing"] or "Fishing",
					order = 1,
				},
				open_panel = {
					type = 'execute',
					name = L["FISH_OPEN_PANEL"] or "Open Fishing Window (/cb fish)",
					desc = L["FISH_OPEN_PANEL_DESC"],
					func = function()
						if CraftBench.ShowFishing then
							CraftBench:ShowFishing()
						end
					end,
					order = 2,
				},
				show_bar = {
					type = 'toggle',
					name = L["FISH_SHOW_BAR"] or "Show Floating Fishing Bar",
					desc = L["FISH_SHOW_BAR_DESC"],
					get = function()
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						return not gdb or not gdb.settings or gdb.settings.showBar ~= false
					end,
					set = function(_, val)
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						if gdb and gdb.settings then
							gdb.settings.showBar = val and true or false
						end
						if CraftBench.FishingUI and CraftBench.FishingUI.SetBarVisible then
							CraftBench.FishingUI:SetBarVisible(val and true or false)
						end
					end,
					order = 3,
				},
				auto_lure = {
					type = 'toggle',
					name = L["FISH_AUTO_LURE"] or "Auto-Apply Best Lure",
					desc = L["FISH_AUTO_LURE_DESC"],
					get = function()
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						return not gdb or not gdb.settings or gdb.settings.autoLure ~= false
					end,
					set = function(_, val)
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						if gdb and gdb.settings then
							gdb.settings.autoLure = val and true or false
						end
					end,
					order = 4,
				},
				easy_cast = {
					type = 'toggle',
					name = L["FISH_EASY_CAST"] or "Double-Right-Click to Cast (Easy-Cast)",
					desc = L["FISH_EASY_CAST_DESC"],
					get = function()
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						return not gdb or not gdb.settings or gdb.settings.easyCast ~= false
					end,
					set = function(_, val)
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						if gdb and gdb.settings then
							gdb.settings.easyCast = val and true or false
						end
					end,
					order = 5,
				},
				cast_key = {
					type = 'keybinding',
					name = L["FISH_CAST_KEY"] or "Cast / Apply Lure Keybind",
					desc = L["FISH_CAST_KEY_DESC"],
					get = function()
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						return (gdb and gdb.settings and gdb.settings.castKey) or ""
					end,
					set = function(_, val)
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						if gdb and gdb.settings then
							gdb.settings.castKey = val or ""
						end
						if CraftBench.Fishing and CraftBench.Fishing.ApplyKeyBindings then
							CraftBench.Fishing:ApplyKeyBindings()
						end
					end,
					order = 6,
				},
				swap_key = {
					type = 'keybinding',
					name = L["FISH_SWAP_KEY"] or "Swap Pole / Weapons Keybind",
					desc = L["FISH_SWAP_KEY_DESC"],
					get = function()
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						return (gdb and gdb.settings and gdb.settings.swapKey) or ""
					end,
					set = function(_, val)
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						if gdb and gdb.settings then
							gdb.settings.swapKey = val or ""
						end
						if CraftBench.Fishing and CraftBench.Fishing.ApplyKeyBindings then
							CraftBench.Fishing:ApplyKeyBindings()
						end
					end,
					order = 7,
				},
				verbose = {
					type = 'toggle',
					name = L["FISH_VERBOSE"] or "Log Catches in Chat",
					desc = L["FISH_VERBOSE_DESC"],
					get = function()
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						return gdb and gdb.settings and gdb.settings.verbose == true
					end,
					set = function(_, val)
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						if gdb and gdb.settings then
							gdb.settings.verbose = val and true or false
						end
					end,
					order = 8,
				},
				keybind_info = {
					type = 'description',
					name = L["FISH_KEYBIND_INFO"] or "Key Bindings: Esc -> Key Bindings -> AddOns -> CraftBench.",
					order = 9,
				},
				clear_db = {
					type = 'execute',
					name = L["FISH_RESET_DB"] or "Reset Fishing Catch Database",
					desc = L["FISH_RESET_DB_DESC"],
					func = function()
						local gdb = CraftBench.Fishing and CraftBench.Fishing:GetDB()
						if gdb then
							gdb.zones = {}
							if CraftBench.FishingUI and CraftBench.FishingUI.Refresh then
								CraftBench.FishingUI:Refresh()
							end
						end
					end,
					order = 10,
				},
			},
		},
		fish = {
			type = 'execute',
			name = L["Fishing"] or "Fishing",
			desc = "Open CraftBench Fishing tracker, catch log and auto-lure controls",
			func = function()
				if CraftBench.ShowFishing then
					CraftBench:ShowFishing()
				end
			end,
			order = 122
		},
		cd = {
			type = 'execute',
			name = L["CD_TITLE"] or "Crafting Cooldowns",
			desc = "Open account-wide Crafting Cooldowns window (/cb cd)",
			func = function()
				if CraftBench.ShowCooldowns then CraftBench:ShowCooldowns() end
			end,
			order = 123
		},
		watch = {
			type = 'input',
			name = L["WATCH_TITLE"] or "Recipe Watch",
			desc = "Pin/unpin a recipe or toggle the Watch HUD (/cb watch [name])",
			get = function() return "" end,
			set = function(_, val)
				if CraftBench.Watch and CraftBench.Watch.PinCurrentOrByName then
					CraftBench.Watch:PinCurrentOrByName(val)
				end
			end,
			order = 124
		},
		level = {
			type = 'execute',
			name = L["LVL_TITLE"] or "Leveling Planner",
			desc = "Open Smart Profession Leveling Planner (/cb level)",
			func = function()
				if CraftBench.ShowLeveling then CraftBench:ShowLeveling() end
			end,
			order = 125
		},
		gather = {
			type = 'execute',
			name = L["GATHER_TITLE"] or "Gathering Guide",
			desc = "Open Herbalism, Mining & Skinning Guide (/cb gather)",
			func = function()
				if CraftBench.ShowGathering then CraftBench:ShowGathering() end
			end,
			order = 126
		},
		gear = {
			type = 'execute',
			name = L["GEAR_TITLE"] or "Crafted Gear",
			desc = "Open Crafted Gear overview by slot (/cb gear)",
			func = function()
				if CraftBench.ShowGear then CraftBench:ShowGear() end
			end,
			order = 126.5
		},
		contacts = {
			type = 'execute',
			name = L["CONTACTS_TITLE"] or "Trade Contacts",
			desc = "Open visited Vendors & Trainers browser with TomTom waypoints (/cb contacts)",
			func = function()
				if CraftBench.ShowContacts then CraftBench:ShowContacts() end
			end,
			order = 127
		},
		camp = {
			type = 'execute',
			name = L["CAMP_TITLE"] or "Camping (WoW Forever)",
			desc = "Open WoW Forever Camping tracker (/cb camp)",
			func = function()
				if CraftBench.ShowCamping then CraftBench:ShowCamping() end
			end,
			order = 128
		},
		tools = {
			type = 'group',
			name = L["TOOLS_TITLE"] or "All-in-One Tools",
			order = 3.6,
			args = {
				header = { type = 'header', name = L["TOOLS_TITLE"] or "All-in-One Tools", order = 1 },
				open_level = {
					type = 'execute',
					name = L["LVL_TITLE"] or "Leveling Planner (/cb level)",
					func = function() if CraftBench.ShowLeveling then CraftBench:ShowLeveling() end end,
					order = 2,
				},
				open_cd = {
					type = 'execute',
					name = L["CD_TITLE"] or "Crafting Cooldowns (/cb cd)",
					func = function() if CraftBench.ShowCooldowns then CraftBench:ShowCooldowns() end end,
					order = 3,
				},
				open_watch = {
					type = 'execute',
					name = L["WATCH_TITLE"] or "Recipe Watch HUD (/cb watch)",
					func = function() if CraftBench.ToggleWatchHUD then CraftBench:ToggleWatchHUD() end end,
					order = 4,
				},
				open_gather = {
					type = 'execute',
					name = L["GATHER_TITLE"] or "Gathering Guide (/cb gather)",
					func = function() if CraftBench.ShowGathering then CraftBench:ShowGathering() end end,
					order = 5,
				},
				open_contacts = {
					type = 'execute',
					name = L["CONTACTS_TITLE"] or "Trade Contacts (/cb contacts)",
					func = function() if CraftBench.ShowContacts then CraftBench:ShowContacts() end end,
					order = 6,
				},
				open_camp = {
					type = 'execute',
					name = L["CAMP_TITLE"] or "Camping (WoW Forever) (/cb camp)",
					func = function() if CraftBench.ShowCamping then CraftBench:ShowCamping() end end,
					order = 7,
				},
			},
		},
		bagclear = {
			type = 'execute',
			name = "bagclear",
			desc = "Option for debugging",
			func = function()
				CraftBench.bagUpdateCounts = {}
				CraftBench.bagUpdateDelayedCount = 0
				CraftBench.unitInventoryChangedCount = 0
				CraftBench.bankUpdateCount = 0
			end,
			order = 122
		},
	}
}

function CraftBench:ConfigureOptions()
	if self.options.args.appearance and self.options.args.appearance.args then
		self.options.args.appearance.args.minimap = self.options.args.minimap
	end
	if self.options.args.features and self.options.args.features.args then
		self.options.args.features.args.export = self.options.args.export
		self.options.args.features.args.import = self.options.args.import
	end
	local acecfg = LibStub("AceConfig-3.0")
	acecfg:RegisterOptionsTable("CraftBench", self.options, { "craftbench", "cb" })
	acecfg:RegisterOptionsTable("CraftBench Features", self.options.args.features)
	acecfg:RegisterOptionsTable("CraftBench Appearance", self.options.args.appearance)
	acecfg:RegisterOptionsTable("CraftBench Processing", self.options.args.processing)
	acecfg:RegisterOptionsTable("CraftBench Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	acecfg:RegisterOptionsTable("CraftBench Plugins", CraftBench.pluginsOptions)
	acecfg:RegisterOptionsTable("CraftBenchGUI", {
		type = "group",
		name = "CraftBench",
		childGroups = "tab",
		args = {
			features = self.options.args.features,
			appearance = self.options.args.appearance,
			processing = self.options.args.processing,
			fishing = self.options.args.fishing,
			tools = self.options.args.tools,
			plugins = CraftBench.pluginsOptions,
			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db),
		},
	})
	local acedia = LibStub("AceConfigDialog-3.0")
	acedia:SetDefaultSize("CraftBenchGUI", 740, 560)
	CraftBench.optionsFrame, CraftBench.categoryID = acedia:AddToBlizOptions("CraftBench Features", "CraftBench")
	acedia:AddToBlizOptions("CraftBench Appearance", L["Appearance"], "CraftBench")
	acedia:AddToBlizOptions("CraftBench Processing", L["Material Processing"], "CraftBench")
	acedia:AddToBlizOptions("CraftBench Profiles", L["Profiles"], "CraftBench")
	acedia:AddToBlizOptions("CraftBench Plugins", L["Plugins"], "CraftBench")
end

--
-- Show the options window
--
function CraftBench:ShowOptions(tabKey, subKey)
	if CraftBench.OptionsUI and CraftBench.OptionsUI.Show then
		CraftBench.OptionsUI:Show(tabKey, subKey)
	elseif Settings and Settings.OpenToCategory and CraftBench.categoryID then
		Settings.OpenToCategory(CraftBench.categoryID)
	elseif InterfaceOptionsFrame_OpenToCategory and CraftBench.optionsFrame then
		InterfaceOptionsFrame_OpenToCategory(CraftBench.optionsFrame)
		InterfaceOptionsFrame_OpenToCategory(CraftBench.optionsFrame)
	elseif CraftBench.Share and CraftBench.Share.OpenOptions then
		CraftBench.Share:OpenOptions()
	end
end

