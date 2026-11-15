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

CraftForge.selectedQueueName = ""

function CraftForge:QueueLoadDropdown_OnShow()
	UIDropDownMenu_Initialize(CraftForgeQueueLoadDropdown, CraftForge.CraftForgeQueueLoadDropdown_Initialize)
	CraftForgeSortDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	UIDropDownMenu_SetSelectedID(CraftForgeQueueLoadDropdown, 1)
	local i=2
	for k,v in pairs(CraftForge.db.profile.SavedQueues) do
		if CraftForge.selectedQueueName and CraftForge.selectedQueueName == k then
			UIDropDownMenu_SetSelectedID(CraftForgeQueueLoadDropdown, i)
		end
		i = i + 1
	end
end

function CraftForge:CraftForgeQueueLoadDropdown_Initialize()
	local info
	local i=1
	info = UIDropDownMenu_CreateInfo()
	info.text = ""
	info.func = CraftForge.QueueLoadDropdown_OnClick
	info.value = i
	i = i + 1
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	for k,v in pairs(CraftForge.db.profile.SavedQueues) do
		info = UIDropDownMenu_CreateInfo()
		info.text = k
		info.func = CraftForge.QueueLoadDropdown_OnClick
		info.value = i
		i = i + 1
		if self then
			info.owner = self:GetParent()
		end
		UIDropDownMenu_AddButton(info)
	end
end

-- Called when the user selects an item in the sorting drop down
function CraftForge:QueueLoadDropdown_OnClick()
	UIDropDownMenu_SetSelectedID(CraftForgeQueueLoadDropdown, self:GetID())
	CraftForge.selectedQueueName = self:GetText()
end
