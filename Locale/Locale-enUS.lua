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

local L = LibStub("AceLocale-3.0"):NewLocale("CraftForge", "enUS", true, true)
if not L then return end

--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true, handle-subnamespaces="concat")@

L["Material Processing"] = "Material Processing"
L["PROCESSINGDESC"] = "Configure one-click Disenchanting, Prospecting, Milling, and Lockpicking (Molinari-style)"
L["PROCESSENABLEDNAME"] = "Enable one-click material processing"
L["PROCESSENABLEDDESC"] = "Allows Disenchanting, Prospecting, Milling, and Lockpicking by holding the modifier key and clicking items in your bags"
L["PROCESSMODIFIERNAME"] = "Modifier Key"
L["PROCESSMODIFIERDESC"] = "Modifier key to hold while hovering and clicking bag items"
L["PROCESSMAXQUALITYNAME"] = "Max Disenchant Quality"
L["PROCESSMAXQUALITYDESC"] = "Highest item quality eligible for one-click disenchanting"
L["PROCESSDISENCHANTNAME"] = "Enable Disenchanting"
L["PROCESSDISENCHANTDESC"] = "Allow one-click disenchanting on eligible gear"
L["PROCESSPROSPECTNAME"] = "Enable Prospecting"
L["PROCESSPROSPECTDESC"] = "Allow one-click prospecting on ore stacks of 5 or more"
L["PROCESSMILLNAME"] = "Enable Milling"
L["PROCESSMILLDESC"] = "Allow one-click milling on herb stacks of 5 or more"
L["PROCESSLOCKPICKNAME"] = "Enable Pick Lock"
L["PROCESSLOCKPICKDESC"] = "Allow one-click lockpicking on locked containers (Rogue)"
L["PROCESSGLOWNAME"] = "Show Glow Highlight"
L["PROCESSGLOWDESC"] = "Display an animated glow highlight around eligible items while holding the modifier key"
