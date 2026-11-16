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

CraftBench.selectedQueueName = ""

function CraftBench:QueueLoadDropdown_OnShow()
	UIDropDownMenu_Initialize(CraftBenchQueueLoadDropdown, CraftBench.CraftBenchQueueLoadDropdown_Initialize)
	CraftBenchSortDropdown.displayMode = "MENU"  -- changes the pop-up borders to be rounded instead of square
	UIDropDownMenu_SetSelectedID(CraftBenchQueueLoadDropdown, 1)
	local i=2
	for k,v in pairs(CraftBench.db.profile.SavedQueues) do
		if CraftBench.selectedQueueName and CraftBench.selectedQueueName == k then
			UIDropDownMenu_SetSelectedID(CraftBenchQueueLoadDropdown, i)
		end
		i = i + 1
	end
end

function CraftBench:CraftBenchQueueLoadDropdown_Initialize()
	local info
	local i=1
	info = UIDropDownMenu_CreateInfo()
	info.text = ""
	info.isNotRadio = true
	info.func = CraftBench.QueueLoadDropdown_OnClick
	info.value = i
	i = i + 1
	if self then
		info.owner = self:GetParent()
	end
	UIDropDownMenu_AddButton(info)
	for k,v in pairs(CraftBench.db.profile.SavedQueues) do
		info = UIDropDownMenu_CreateInfo()
		info.text = k
		info.isNotRadio = true
		info.func = CraftBench.QueueLoadDropdown_OnClick
		info.value = i
		i = i + 1
		if self then
			info.owner = self:GetParent()
		end
		UIDropDownMenu_AddButton(info)
	end
end

-- Called when the user selects an item in the sorting drop down
function CraftBench:QueueLoadDropdown_OnClick()
	UIDropDownMenu_SetSelectedID(CraftBenchQueueLoadDropdown, self:GetID())
	CraftBench.selectedQueueName = self:GetText()
end
