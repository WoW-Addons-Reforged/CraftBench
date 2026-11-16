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

local OVERALL_PARENT_GROUP_NAME = "*ALL*"

local skillLevel = {
	["optimal"]	        = 4,
	["medium"]          = 3,
	["easy"]            = 2,
	["trivial"]	        = 1,
}

function CraftForge:RecipeGroupRename(oldName, newName)
	--DA.DEBUG(0,"RecipeGroupRename("..tostring(oldName)..", "..tostring(newName)..")")
	if self.data.groupList[self.currentTrade][oldName] then
		self.data.groupList[self.currentTrade][newName] = self.data.groupList[self.currentTrade][oldName]
		self.data.groupList[self.currentTrade][oldName] = nil
		local list = self.data.groupList[self.currentTrade][newName]
		local oldKey =  self.currentPlayer..":"..self.currentTrade..":"..oldName
		local key = self.currentPlayer..":"..self.currentTrade..":"..newName
		self.db.realm.groupDB[key] = self.db.realm.groupDB[oldKey]
		self.db.realm.groupDB[oldKey] = nil
		for groupName, groupData in pairs(list) do
			groupData.key = key
		end
	end
end

function CraftForge:RecipeGroupFind(player, tradeID, label, name)
	--DA.DEBUG(0,"RecipeGroupFind("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..", "..tostring(name)..")")
	if player and tradeID and label then
		local groupList = self.data.groupList
		if groupList and groupList[tradeID] and groupList[tradeID][label] then
			return self.data.groupList[tradeID][label][name or OVERALL_PARENT_GROUP_NAME]
		end
	end
end

function CraftForge:RecipeGroupFindRecipe(group, recipeID)
	--DA.DEBUG(0,"RecipeGroupFindRecipe("..DA.DUMP1(group,1)..", "..tostring(recipeID)..")")
	if group then
		local entries = group.entries
		if entries then
			for i=1,#entries do
				if entries[i].recipeID then
					return entries[i]
				end
			end
		end
	end
end

--
-- Creates a new recipe group
-- player = for whom the group is being created
-- tradeID = tradeID of the group
-- label = meta-group of groups.  for example, "Blizzard" is defined for the standard blizzard groups.  this allows multiple group settings
-- name = new group name (optional -- not specified means the overall parent group)
--
-- returns the newly created group record
--
local serial = 0
function CraftForge:RecipeGroupNew(player, tradeID, label, name)
	--DA.DEBUG(0,"RecipeGroupNew("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..", "..tostring(name)..")")
	local existingGroup = self:RecipeGroupFind(player, tradeID, label, name)
	if existingGroup then
		--DA.DEBUG(0,"group "..existingGroup.key.."/"..existingGroup.name.." exists")
		return existingGroup
	else
		--DA.DEBUG(0,"new group "..(name or OVERALL_PARENT_GROUP_NAME))
		local newGroup = {}
		local key = player..":"..tradeID..":"..label
		newGroup.expanded = true
		newGroup.key = key
		newGroup.name = name or OVERALL_PARENT_GROUP_NAME
		newGroup.entries = {}
		newGroup.skillIndex = serial
		newGroup.locked = nil
		serial = serial + 1
		if not self.data.groupList[tradeID] then
			self.data.groupList[tradeID] = {}
		end
		if not self.data.groupList[tradeID][label] then
			self.data.groupList[tradeID][label] = {}
		end
		self.data.groupList[tradeID][label][newGroup.name] = newGroup
		return newGroup
	end
end

function CraftForge:RecipeGroupClearEntries(group, n)
	--DA.DEBUG(0,"RecipeGroupClearEntries("..DA.DUMP1(group,1))
	if not n then 
		n = 0 
		--DA.DEBUG(0,"RecipeGroupClearEntries("..DA.DUMP1(group,1))
	end
	if group then
		--DA.DEBUG(1,"RecipeGroupClearEntries: n="..tostring(n)..", name= "..tostring(group.name)..", #group.entries= "..tostring(#group.entries))
		for i=1,#group.entries do
			if group.entries[i] then
				if group.entries[i].subGroup then
					self:RecipeGroupClearEntries(group.entries[i].subGroup, n+1)
				end
			else
				--DA.DEBUG(2,"RecipeGroupClearEntries: i="..tostring(i)..", entry= "..DA.DUMP1(group.entries[i],1))
			end
		end
		group.entries = {}
	end
end

function CraftForge:RecipeGroupCopy(s, d, noDB)
	--DA.DEBUG(0,"RecipeGroupCopy("..DA.DUMP1(s,1)..", "..DA.DUMP1(d,1)..", "..tostring(noDB)..")")
	if s and d then
		local player, tradeID, label = strsplit(":", d.key)
		d.skillIndex = s.skillIndex
		d.expanded = s.expanded
		d.entries = {}
			for i=1,#s.entries do
			if s.entries[i].subGroup then
				local newGroup = self:RecipeGroupNew(player, tradeID, label, s.entries[i].name)
				self:RecipeGroupCopy(s.entries[i].subGroup, newGroup, noDB)
				self:RecipeGroupAddSubGroup(d, newGroup, s.entries[i].skillIndex, noDB)
			else
				self:RecipeGroupAddRecipe(d, s.entries[i].recipeID, s.entries[i].skillIndex, noDB)
			end
		end
	end
end

function CraftForge:RecipeGroupAddRecipe(group, recipeID, skillIndex, noDB)
	--DA.DEBUG(0,"RecipeGroupAddRecipe("..DA.DUMP1(group,1)..", "..tostring(recipeID)..", "..tostring(skillIndex)..", "..tostring(noDB)..")")
	recipeID = tonumber(recipeID)
	if group and recipeID then
		local currentEntry
		for i=1,#group.entries do
			if group.entries[i].recipeID == recipeID then
				currentEntry = group.entries[i]
				break
			end
		end
		if not currentEntry then
			local newEntry = {}
			newEntry.recipeID = recipeID
			newEntry.name, newEntry.spellID = self:GetRecipeName(recipeID)
			newEntry.skillIndex = skillIndex
			newEntry.parent = group
			table.insert(group.entries, newEntry)
			currentEntry = newEntry
		else
			currentEntry.subGroup = subGroup
			currentEntry.skillIndex = skillIndex
			currentEntry.name, currentEntry.spellID = self:GetRecipeName(recipeID)
			currentEntry.parent = group
		end
		if not noDB then
			self:RecipeGroupConstructDBString(group)
		end
		return currentEntry
	end
end

function CraftForge:RecipeGroupAddSubGroup(group, subGroup, skillIndex, noDB)
	--DA.DEBUG(0,"RecipeGroupAddSubGroup("..DA.DUMP1(group,1)..", "..DA.DUMP1(subGroup,1)..", "..tostring(skillIndex)..", "..tostring(noDB)..")")
	if group and subGroup then
		local currentEntry
		for i=1,#group.entries do
			if group.entries[i].subGroup == subGroup then
				currentEntry = group.entries[i]
				break
			end
		end
		if not currentEntry then
			local newEntry = {}
			subGroup.parent = group
			subGroup.skillIndex = skillIndex
			newEntry.subGroup = subGroup
			newEntry.skillIndex = skillIndex
			newEntry.name = subGroup.name
			newEntry.parent = group
			table.insert(group.entries, newEntry)
		else
			subGroup.parent = group
			subGroup.skillIndex = skillIndex
			currentEntry.subGroup = subGroup
			currentEntry.skillIndex = skillIndex
			currentEntry.name = subGroup.name
			currentEntry.parent = group
		end
		if not noDB then
			self:RecipeGroupConstructDBString(group)
		end
	end
end

function CraftForge:RecipeGroupPasteEntry(entry, group)
	--DA.DEBUG(0,"RecipeGroupPasteEntry("..DA.DUMP1(entry,1)..", "..DA.DUMP1(group,1)..")")
	if entry and group and entry.parent ~= group then
		local player = self.currentPlayer
		local tradeID = self.currentTrade
		local label = self.currentGroupLabel
		--DA.DEBUG(0,"paste "..entry.name.." into "..group.name)
--		local parentGroup = self:RecipeGroupFind(player, tradeID, label, self.currentGroup)
		local parentGroup = group
		if entry.subGroup then
			 if entry.subGroup == group then
			 	return
			end
			local newName, newIndex = self:RecipeGroupNewName(group.key, entry.name)
			local newGroup = self:RecipeGroupNew(player, tradeID, label, newName)
			self:RecipeGroupAddSubGroup(parentGroup, newGroup, newIndex)
			if entry.subGroup.entries then
				--DA.DEBUG(0,(entry.subGroup.name or "nil") .. " " .. #entry.subGroup.entries)
				for i=1,#entry.subGroup.entries do
					--DA.DEBUG(1,(entry.subGroup.entries[i].name or "nil") .. " " .. newGroup.name)
					self:RecipeGroupPasteEntry(entry.subGroup.entries[i], newGroup)
				end
			end
		else
			local newIndex = self.data.skillIndexLookup[entry.recipeID]
			if not newIndex then
				newIndex = #self.data.skillDB[tradeID]+1
				self.data.skillDB[tradeID][newIndex] = "x"..entry.recipeID
			end
			self:RecipeGroupAddRecipe(parentGroup, entry.recipeID, newIndex)
		end
	end
end

function CraftForge:RecipeGroupMoveEntry(entry, group)
	--DA.DEBUG(0,"RecipeGroupMoveEntry("..DA.DUMP1(entry,1)..", "..DA.DUMP1(group,1)..")")
	if entry and group and entry.parent ~= group then
		if entry.subGroup then
			if entry.subGroup == group then
				return
			end
		end
		local entryGroup = entry.parent
		if entryGroup then
			local loc
			for i=1,#entryGroup.entries do
				if entryGroup.entries[i] == entry then
					loc = i
					break
				end
			end
			table.remove(entryGroup.entries, loc)
			table.insert(group.entries, entry)
			entry.parent = group
			CraftForge:RecipeGroupConstructDBString(group)
			CraftForge:RecipeGroupConstructDBString(entryGroup)
		end
	end
end

function CraftForge:RecipeGroupDeleteGroup(group)
	--DA.DEBUG(0,"RecipeGroupDeleteGroup("..DA.DUMP1(group,1)..")")
	if group then
		for i=1,#group.entries do
			if group.entries[i].subGroup then
				self.RecipeGroupDeleteGroup(group.entries[i].subGroup)
			end
		end
		group.entries = nil
		self.db.realm.groupDB[group.key][group.name] = nil
	end
end

function CraftForge:RecipeGroupDeleteEntry(entry)
	--DA.DEBUG(0,"RecipeGroupDeleteEntry("..DA.DUMP1(entry,1)..")")
	if entry then
		local entryGroup = entry.parent
		local loc
		if not entryGroup.entries then return end
		for i=1,#entryGroup.entries do
			if entryGroup.entries[i] == entry then
				loc = i
				break
			end
		end
		table.remove(entryGroup.entries, loc)
		if entry.subGroup then
			self:RecipeGroupDeleteGroup(entry.subGroup)
		end
		CraftForge:RecipeGroupConstructDBString(entryGroup)
	end
end

function CraftForge:RecipeGroupNewName(key, name)
	--DA.DEBUG(0,"RecipeGroupNewName("..tostring(key)..", "..tostring(name)..")")
	local index = 1
	if key and name then
		local player, tradeID, label = strsplit(":", key)
		tradeID = tonumber(tradeID)
		local groupList = self.data.groupList[tradeID][label]
		for v in pairs(groupList) do
			index = index + 1
		end
		if groupList[name] then
			local tempName = name..":"
			local suffix = 2
			while groupList[tempName..suffix] do
				suffix = suffix + 1
			end
			name = tempName..suffix
		end
	end
	--DA.DEBUG(0,"RecipeGroupNewName: name= "..tostring(name)..", index= "..tostring(index))
	return name, index
end

function CraftForge:RecipeGroupRenameEntry(entry, name)
	--DA.DEBUG(0,"RecipeGroupRenameEntry("..DA.DUMP1(entry,1)..", "..tostring(name)..")")
	if entry and name then
		local key = entry.parent.key
		local player, tradeID, label = strsplit(":", key)
		local gkey = tradeID..":"..label
		tradeID = tonumber(tradeID)
		if entry.subGroup then
			local oldName = entry.subGroup.name
			local groupList = self.data.groupList[tradeID][label]
			if oldName ~= name then
				name = self:RecipeGroupNewName(key, name)
				entry.subGroup.name = name
				entry.name = name
				groupList[name] = groupList[oldName]
				groupList[oldName] = nil
				self.db.profile.groupDB[gkey][oldName] = nil
			end
		end
		self:RecipeGroupConstructDBString(entry.parent)
	end
end

function CraftForge:RecipeGroupSort(group, sortMethod, reverse, n)
	--DA.DEBUG(0,"RecipeGroupSort("..tostring(group.skillIndex)..", "..tostring(sortMethod)..","..tostring(reverse)..")")
	if not n then 
		n = 0 
		--DA.DEBUG(0,"RecipeGroupSort("..DA.DUMP1(group,1))
	end
	--DA.DEBUG(0,"RecipeGroupSort: skillIndex="..tostring(group.skillIndex)..", name="..tostring(group.name)..", reverse="..tostring(reverse)..", n="..tostring(n))
	if group then
		for v, entry in pairs(group.entries) do
			if entry.subGroup and entry.subGroup ~= group then
				self:RecipeGroupSort(entry.subGroup, sortMethod, reverse, n+1)
			end
		end
		if group.entries and #group.entries > 1 then
			if reverse then
				table.sort(group.entries, function(a,b)
					return sortMethod(CraftForge.currentTrade, b, a)
				end)
			else
				table.sort(group.entries, function(a,b)
					return sortMethod(CraftForge.currentTrade, a, b)
				end)
			end
		end
	end
end

function CraftForge:RecipeGroupInitFlatten(group, list)
	--DA.DEBUG(0,"RecipeGroupInitFlatten("..tostring(group.skillIndex)..", "..tostring(list)..")")
	--DA.DEBUG(1,"RecipeGroupInitFlatten("..DA.DUMP1(group,1)..", "..DA.DUMP1(list,1)..")")
	if group and list then
		local newSkill = {}
		newSkill.name = group.name
		newSkill.skillIndex = group.skillIndex
		newSkill.subGroup = group
		newSkill.expanded = true
		newSkill.depth = 0
		newSkill.parent = group.parent
		DA.DEBUG(1,"RecipeGroupInitFlatten: newSkill= "..DA.DUMP1(newSkill,1))
		list[1] = newSkill
	end
end

function CraftForge:RecipeGroupFlatten(group, depth, list, index)
	--DA.DEBUG(0,"RecipeGroupFlatten("..tostring(group.skillIndex)..", "..tostring(depth)..", "..tostring(list)..", "..tostring(index)..")")
	--DA.DEBUG(1,"RecipeGroupFlatten("..DA.DUMP1(entry,1)..", "..tostring(depth)..", "..DA.DUMP1(list,1)..", "..tostring(index)..")")
	--DA.DEBUG(1,"RecipeGroupFlatten: group= "..DA.DUMP1(group,2))
	--DA.DEBUG(1,"RecipeGroupFlatten: list= "..DA.DUMP1(list,2))
	local num = 0
	if group and list then
		for v, entry in pairs(group.entries) do
			if entry.subGroup then
				local newSkill = entry
				local inSub = 0
				newSkill.depth = depth
				if (index>0) then
					newSkill.parentIndex = index
				else
					newSkill.parentIndex = nil
				end
				num = num + 1
				list[num + index] = newSkill
				if entry.subGroup.expanded then
					inSub = self:RecipeGroupFlatten(entry.subGroup, depth+1, list, num+index)
				end
				if inSub == 0 and entry.subGroup.expanded then
--
-- Group is empty so remove the header unless
-- it has a progress bar and the option to keep them is set.
--
					if CraftForge.hasProgressBar[entry.subGroup.name] then
						--DA.DEBUG(0,"RecipeGroupFlatten: empty hasProgressBar group= "..tostring(entry.subGroup.name))
						if not CraftForge.db.profile.always_show_progress_bar then
							table.remove(list, num + index)
							num = num - 1
						end
					else
						--DA.DEBUG(0,"RecipeGroupFlatten: empty group= "..tostring(entry.subGroup.name))
						table.remove(list, num + index)
						num = num - 1
					end
				else
					num = num + inSub
				end
			else
				local skillData = self:GetSkill(self.currentPlayer, self.currentTrade, entry.skillIndex)
				local recipe = self:GetRecipe(entry.recipeID)
				if skillData then
					local filterLevel = ((skillLevel[entry.difficulty] or skillLevel[skillData.difficulty] or 0) < (self:GetTradeSkillOption("filterLevel")))
					local filterCraftable = false
					local filterFavoritesOnly = self:GetTradeSkillOption("favoritesOnly") and not CraftForge:IsFavorite(entry.recipeID)
					local filterBuffsOnly = self:GetTradeSkillOption("buffsOnly") and CraftForge.IsBuffRecipe and not CraftForge:IsBuffRecipe(recipe)
					local filterFirstCraftOnly = self:GetTradeSkillOption("isfirstcraft") and not CraftForge:IsFirstCraft(entry.recipeID)
					if CraftForge:GetTradeSkillOption("hideuncraftable") then
						--DA.DEBUG(1,"RecipeGroupFlatten: name="..tostring(skillData.name)..", numCraftable="..tostring(skillData.numCraftable)..", numRecursive="..tostring(skillData.numRecursive)..", numCraftableVendor="..tostring(skillData.numCraftableVendor)..", numCraftableAlts="..tostring(skillData.numCraftableAlts))
						if not (skillData.numCraftable and skillData.numCraftable > 0 and CraftForge:GetTradeSkillOption("filterInventory-bag")) and
						   not (skillData.numRecursive and skillData.numRecursive > 0 and CraftForge:GetTradeSkillOption("filterInventory-crafted")) and
						   not (skillData.numCraftableVendor and skillData.numCraftableVendor > 0 and CraftForge:GetTradeSkillOption("filterInventory-vendor")) and
						   not (skillData.numCraftableAlts and skillData.numCraftableAlts > 0 and CraftForge:GetTradeSkillOption("filterInventory-alts")) then
							filterCraftable = true
						end
					end
					if CraftForge.recipeFilters then
						for _,f in pairs(CraftForge.recipeFilters) do
							if f.filterMethod(f.namespace, entry.skillIndex) then
								filterCraftable = true
							end
						end
					end
					local newSkill = entry
					newSkill.depth = depth
					newSkill.skillData = skillData
					newSkill.spellID = recipe.spellID
					if (index>0) then
						newSkill.parentIndex = index
					else
						newSkill.parentIndex = nil
					end
					if not (filterLevel or filterCraftable or filterFavoritesOnly or filterBuffsOnly or filterFirstCraftOnly or CraftForge:IsUpgradeHidden(newSkill.spellID)) then
						num = num + 1
						list[num + index] = newSkill
					end
				end
			end
		end
	end
	return num
end

function CraftForge:RecipeGroupDump(group)
	if group then
		local groupString = group.key.."/"..group.name.."="..group.skillIndex
		for v,entry in pairs(group.entries) do
			if not entry.subGroup then
				groupString = groupString..":"..entry.recipeID
			else
				groupString = groupString..":"..entry.subGroup.name
				self:RecipeGroupDump(entry.subGroup)
			end
		end
		DA.DEBUG(0,"RecipeGroupDump: "..groupString)
	else
		DA.DEBUG(0,"RecipeGroupDump: no match")
	end
end

--
-- Make a db string for saving groups
--
function CraftForge:RecipeGroupConstructDBString(group)
	--DA.DEBUG(0,"RecipeGroupConstructDBString("..DA.DUMP1(group,1)..")")
	if group and not group.autoGroup then
		local key = group.key
		local player, tradeID, label = strsplit(":",key)
		tradeID = tonumber(tradeID)
		if not self.data.groupList[tradeID][label].autoGroup then
			local groupString = group.skillIndex
			for v,entry in pairs(group.entries) do
				if not entry.subGroup then
					groupString = groupString..":"..entry.recipeID
				else
					groupString = groupString..":g"..entry.skillIndex	-- entry.subGroup.name
					self:RecipeGroupConstructDBString(entry.subGroup)
				end
			end
			if not self.db.realm.groupDB[key] then
				self.db.realm.groupDB[key] = {}
			end
			self.db.realm.groupDB[key][group.name] = groupString
		end
	end
end

function CraftForge:RecipeGroupPruneList(player)
	--DA.DEBUG(0,"RecipeGroupPruneList("..tostring(player)..")")
	if self.data.groupList then
		for trade, perTradeList in pairs(self.data.groupList) do
			for label, perLabelList in pairs(perTradeList) do
				for name, group in pairs(perLabelList) do
					if type(group)=="table" and name ~= OVERALL_PARENT_GROUP_NAME and group.parent == nil then
						perLabelList[name] = nil
						if self.db.realm.groupDB and self.db.realm.groupDB[player..":"..trade..":"..label] then
							self.db.realm.groupDB[player..":"..trade..":"..label][name] = nil
						end
					end
				end
			end
		end
	end
end

function CraftForge:InitGroupList(player, tradeID, label, autoGroup)
	--DA.DEBUG(0,"InitGroupList("..tostring(player)..", "..tostring(tradeID)..", "..tostring(label)..", "..tostring(autoGroup)..")")
	if not self.data.groupList[tradeID] then
		self.data.groupList[tradeID] = {}
	end
	if not self.data.groupList[tradeID][label] then
		self.data.groupList[tradeID][label] = {}
	end
	self.data.groupList[tradeID][label].autoGroup = autoGroup
end

function CraftForge:RecipeGroupDeconstructDBStrings()
	--DA.DEBUG(0,"RecipeGroupDeconstructDBStrings()")
	local groupNames = {}
	local serial = 1
	for key, groupList in pairs(self.db.realm.groupDB) do
		local player, tradeID, label = strsplit(":", key)
		tradeID = tonumber(tradeID)
		if player == self.currentPlayer and tradeID == self.currentTrade and self.data.skillIndexLookup then
			self:InitGroupList(player, tradeID, label)
			for name,list in pairs(groupList) do
				local group = self:RecipeGroupNew(player, tradeID, label, name)
				local groupContents = { strsplit(":",list) }
				local groupIndex = tonumber(groupContents[1]) or serial
				serial = serial + 1
				group.skillIndex = groupIndex
				groupNames[groupIndex] = name
			end
		end
	end
	for key, groupList in pairs(self.db.realm.groupDB) do
		local player, tradeID, label = strsplit(":", key)
		tradeID = tonumber(tradeID)
		if player == self.currentPlayer and tradeID == self.currentTrade and self.data.skillIndexLookup then
			for name,list in pairs(groupList) do
				local group = self:RecipeGroupFind(player, tradeID, label, name)
				local groupIndex = group.skillIndex
				if not group.initialized then
					group.initialized = true
					local groupContents = { strsplit(":",list) }
					--DA.DEBUG(0,"RecipeGroupDeconstructDBStrings: "..groupContents)
					for j=2,#groupContents do
						local recipeID = groupContents[j]
						if not tonumber(recipeID) then
							local id = tonumber(string.sub(recipeID,2))
							local subGroup = self:RecipeGroupFind(player, tradeID, label, groupNames[id])
							if subGroup then
								self:RecipeGroupAddSubGroup(group, subGroup, subGroup.skillIndex, true)
							end
						else
							recipeID = tonumber(recipeID)
							--DA.DEBUG(0,"RecipeGroupDeconstructDBStrings: "..recipeID)
							local skillIndex = self.data.skillIndexLookup[recipeID]
							if skillIndex then
								--DA.DEBUG(0,"RecipeGroupDeconstructDBStrings: adding recipe "..recipeID.." to "..group.name.."/"..player..":"..skillIndex)
								self:RecipeGroupAddRecipe(group, recipeID, skillIndex, true)
							end
						end
					end
				end
			end
			self:RecipeGroupPruneList(player)
		end
	end
end

function CraftForge:RecipeGroupGenerateAutoGroups()
	--DA.DEBUG(0,"RecipeGroupGenerateAutoGroups()")
end

--
-- Called when the grouping drop down is displayed
--
function CraftForge:RecipeGroupDropdown_OnShow()
	--DA.DEBUG(0,"RecipeGroupDropdown_OnShow()")
	UIDropDownMenu_Initialize(CraftForgeRecipeGroupDropdown, CraftForge.RecipeGroupDropdown_Initialize)
	CraftForgeRecipeGroupDropdown.displayMode = "MENU"
	CraftForge:RecipeGroupDeconstructDBStrings()
	local groupLabel = self:GetTradeSkillOption("grouping") or self.currentGroupLabel
	UIDropDownMenu_SetSelectedName(CraftForgeRecipeGroupDropdown, groupLabel, true)
	UIDropDownMenu_SetText(CraftForgeRecipeGroupDropdown, groupLabel)
end

--
-- The method we use the initialize the grouping drop down.
--
function CraftForge.RecipeGroupDropdown_Initialize(menuFrame,level)
	--DA.DEBUG(0,"RecipeGroupDropdown_Initialize("..tostring(menuFrame)..", "..tostring(level)..")")
	if level == 1 then  -- group labels
		local entry = {}
		entry.isNotRadio = true
		entry.text = "Flat"
		entry.value = "Flat"
		entry.func = CraftForge.RecipeGroupSelect
		entry.arg1 = CraftForge
		entry.arg2 = "Flat"
		entry.icon = "Interface\\Addons\\CraftForge\\Icons\\locked.tga"
		if CraftForge.currentGroupLabel == "Flat" then
			entry.checked = true
		else
			entry.checked = false
		end
		UIDropDownMenu_AddButton(entry)
		if CraftForge.data.groupList then
			local numGroupsAdded = 0
			if CraftForge.data.groupList[CraftForge.currentTrade] then
				for labelName, groupData in pairs(CraftForge.data.groupList[CraftForge.currentTrade]) do
					entry.text = labelName
					entry.value = labelName
					entry.func = CraftForge.RecipeGroupSelect
					entry.arg1 = CraftForge
					entry.arg2 = labelName
					if labelName == "Blizzard" or CraftForge:GetTradeSkillOption(labelName.."-locked") then
						entry.icon = "Interface\\Addons\\CraftForge\\Icons\\locked.tga"
					else
						entry.icon = nil -- "Interface\\Addons\\CraftForge\\Icons\\unlocked.tga"
					end
					if CraftForge.currentGroupLabel == labelName then
						entry.checked = true
					else
						entry.checked = false
					end
					UIDropDownMenu_AddButton(entry)
					numGroupsAdded = numGroupsAdded + 1
				end
			end
		end
	end
end

--
-- Called when the user selects an item in the sorting drop down
--
function CraftForge:RecipeGroupSelect(menuFrame,label)
	--DA.DEBUG(0,"RecipeGroupSelect("..tostring(menuFrame)..", "..tostring(label)..")")
	CraftForge:SetTradeSkillOption("grouping", label)
	CraftForge.currentGroupLabel = label
	CraftForge.currentGroup = nil
	CraftForge:RecipeGroupDropdown_OnShow()
	CraftForge:RecipeGroupGenerateAutoGroups()
	CraftForge:SortAndFilterRecipes()
	CraftForge:UpdateTradeSkillWindow()
end

function CraftForge:RecipeGroupIsLocked()
	if self.currentGroupLabel == "Flat" or self.currentGroupLabel == "Blizzard" then
		return true
	end
	return CraftForge:GetTradeSkillOption(self.currentGroupLabel.."-locked")
end

function CraftForge:ToggleTradeSkillOptionDropDown(option)
	self:ToggleTradeSkillOption(option)
	self:RecipeGroupDropdown_OnShow()
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

--
-- Called when the grouping operators drop down is displayed
--
function CraftForge:RecipeGroupOperations_OnClick(this)
	if not CraftForge.RecipeGroupOpsMenu then
		CraftForge.RecipeGroupOpsMenu = CreateFrame("Frame", "RecipeGroupOpsMenu", _G["UIParent"], "UIDropDownMenuTemplate")
	end
	UIDropDownMenu_Initialize(CraftForge.RecipeGroupOpsMenu, CraftForge.RecipeGroupOpsMenu_Init, "MENU")
	ToggleDropDownMenu(1, nil, CraftForge.RecipeGroupOpsMenu, this, this:GetWidth(), 0)
end

--
-- The method we use the initialize the group ops drop down.
--
function CraftForge.RecipeGroupOpsMenu_Init(menuFrame,level)
	if level == 1 then
		local entry = {}
		entry.notCheckable = true
		entry.isNotRadio = true
		local null = {}
		null.text = ""
		null.disabled = true
		entry.text = "New"
		entry.value = "New"
		entry.func = CraftForge.RecipeGroupOpNew
		UIDropDownMenu_AddButton(entry)
		entry.text = "Copy"
		entry.value = "Copy"
		entry.func = CraftForge.RecipeGroupOpCopy
		UIDropDownMenu_AddButton(entry)
		entry.text = "Rename"
		entry.value = "Rename"
		entry.func = CraftForge.RecipeGroupOpRename
		UIDropDownMenu_AddButton(entry)
		entry.text = "Lock/Unlock"
		entry.value = "Lock/Unlock"
		entry.func = CraftForge.RecipeGroupOpLock
		UIDropDownMenu_AddButton(entry)
		entry.text = "Delete"
		entry.value = "Delete"
		entry.func = CraftForge.RecipeGroupOpDelete
		UIDropDownMenu_AddButton(entry)
	end
end

function CraftForge:RecipeGroupOpNew()
	--DA.DEBUG(0,"RecipeGroupOpNew()")
	local label = "Custom"
	local serial = 1
	local player = CraftForge.currentPlayer
	local tradeID = CraftForge.currentTrade
	local groupList = CraftForge.data.groupList
	while groupList[tradeID][label] do
		serial = serial + 1
		label = "Custom "..serial
	end
	local newMain = CraftForge:RecipeGroupNew(player, tradeID, label)
	CraftForge:RecipeGroupConstructDBString(newMain)
	CraftForge:SetTradeSkillOption("grouping", label)
	CraftForge.currentGroupLabel = label
	UIDropDownMenu_SetSelectedName(CraftForgeRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(CraftForgeRecipeGroupDropdown, label)
	CraftForge:SortAndFilterRecipes()
	CraftForge:UpdateTradeSkillWindow()
end

function CraftForge:RecipeGroupOpCopy()
	--DA.DEBUG(0,"RecipeGroupOpCopy()")
	local label = "Custom"
	local serial = 1
	local player = CraftForge.currentPlayer
	local tradeID = CraftForge.currentTrade
	local groupList = CraftForge.data.groupList
	while sk[tradeID][label] do
		serial = serial + 1
		label = "Custom "..serial
	end
	local newMain = CraftForge:RecipeGroupNew(player, tradeID, label)
	local oldMain = CraftForge:RecipeGroupFind(player, tradeID, CraftForge.currentGroupLabel)
	CraftForge:RecipeGroupCopy(oldMain, newMain, false)
	CraftForge:RecipeGroupConstructDBString(newMain)
	CraftForge:SetTradeSkillOption("grouping", label)
	CraftForge.currentGroupLabel = label
	UIDropDownMenu_SetSelectedName(CraftForgeRecipeGroupDropdown, label, true)
	UIDropDownMenu_SetText(CraftForgeRecipeGroupDropdown, label)
	CraftForge:SortAndFilterRecipes()
	CraftForge:UpdateTradeSkillWindow()
end

function CraftForge:GroupNameEditSave()
	--DA.DEBUG(0,"GroupNameEditSave()")
	local newName = GroupButtonNameEdit:GetText()
	CraftForge:RecipeGroupRename(CraftForge.currentGroupLabel, newName)
	GroupButtonNameEdit:Hide()
	CraftForgeRecipeGroupDropdownText:Show()
	CraftForgeRecipeGroupDropdownText:SetText(newName)
	CraftForge.currentGroupLabel = newName
end

function CraftForge:RecipeGroupOpRename()
	--DA.DEBUG(0,"RecipeGroupOpRename()")
	if not CraftForge:RecipeGroupIsLocked() then
		GroupButtonNameEdit:SetText(CraftForge.currentGroupLabel)
		GroupButtonNameEdit:SetParent(CraftForgeRecipeGroupDropdownText:GetParent())
		local numPoints = CraftForgeRecipeGroupDropdownText:GetNumPoints()
		for p=1,numPoints do
			GroupButtonNameEdit:SetPoint(CraftForgeRecipeGroupDropdownText:GetPoint(p))
		end
		GroupButtonNameEdit:Show()
		CraftForgeRecipeGroupDropdownText:Hide()
	end
end

function CraftForge:RecipeGroupOpLock()
	--DA.DEBUG(0,"RecipeGroupOpLock()")
	local label = CraftForge.currentGroupLabel
	if label ~= "Blizzard" and label ~= "Flat" then
		CraftForge:ToggleTradeSkillOption(label.."-locked")
	end
end

function CraftForge:RecipeGroupOpDelete()
	--DA.DEBUG(0,"RecipeGroupOpDelete()")
	if not CraftForge:RecipeGroupIsLocked() then
		local player = CraftForge.currentPlayer
		local tradeID = CraftForge.currentTrade
		local label = CraftForge.currentGroupLabel
		CraftForge.data.groupList[tradeID][label] = nil
		CraftForge.db.realm.groupDB[player..":"..tradeID..":"..label] = nil
		label = "Blizzard"
		CraftForge:SetTradeSkillOption("grouping", label)
		CraftForge.currentGroupLabel = label
		UIDropDownMenu_SetSelectedName(CraftForgeRecipeGroupDropdown, label, true)
		UIDropDownMenu_SetText(CraftForgeRecipeGroupDropdown, label)
		CraftForge:SortAndFilterRecipes()
		CraftForge:UpdateTradeSkillWindow()
	end
end
