local addonName, addonTable = ...
local DA = _G[addonName] -- for DebugAids.lua
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

CraftBench.NewsName = "CraftBench News"
CraftBench.NewsData = {
	{
		version = "1.0.0",
		data = {
			{
				name = "Highlights",
				data = {
					{ header = "CraftBench 1.0.0", body = "Initial CraftBench release with full Retail, Classic, Forever, BCC, Wrath, Cata & Mists support." },
					{ header = "Modern Dark-Gold UI", body = "Unified Dark-Gold UI theme across main window, standalone queue, shopping list, notes and reagent panels." },
					{ header = "One-Click Material Processing", body = "Integrated one-click Disenchanting, Prospecting, Milling and Pick Lock via secure click overlay." },
				},
			},
			{
				name = "Ace3 & Plugins",
				data = {
					{ header = "Ace3 Modules", body = "Added AceBucket-3.0 event throttling, Queue Export/Import (AceSerializer-3.0 + LibDeflate), Guild/Party Sync (AceComm-3.0), Minimap/LDB launcher and AceTab-3.0 autocomplete." },
					{ header = "Plugin Compatibility", body = "Fixed and verified Auctionator, AuctionDB, OribosExchange, BeanCounter and AckisRecipeList integrations across Retail & Classic." },
				},
			},
		},
	},
}
