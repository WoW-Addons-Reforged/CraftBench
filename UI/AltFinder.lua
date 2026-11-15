local addonName, addonTable = ...
local DA = LibStub("AceAddon-3.0"):GetAddon("CraftForge")
--[[
CraftForge: All-in-One Profession, Crafting & Material-Processing Suite.

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

local L = LibStub("AceLocale-3.0"):GetLocale("CraftForge")
local AceGUI = LibStub("AceGUI-3.0", true)

local altFinderFrame

local function parseRecipeID(entry)
	if type(entry) == "number" then
		return entry
	elseif type(entry) == "string" then
		local _, idStr = strsplit(" ", entry)
		return tonumber(idStr) or tonumber(entry:match("%d+"))
	elseif type(entry) == "table" then
		return tonumber(entry.spellID or entry.recipeID)
	end
end

local function populateAltResults(scroll, query)
	scroll:ReleaseChildren()
	local q = strtrim(query or ""):lower()
	if q == "" or #q < 2 then
		local hint = AceGUI:Create("Label")
		hint:SetFullWidth(true)
		hint:SetText("|cffbbbbbb" .. L["ALT_FINDER_HINT"] .. "|r")
		scroll:AddChild(hint)
		return
	end

	local realmDB = CraftForge.db and CraftForge.db.realm
	if not realmDB then return end

	local recipeHits = {}
	local skillDB = realmDB.skillDB or {}
	for player, trades in pairs(skillDB) do
		if type(trades) == "table" then
			for tradeID, list in pairs(trades) do
				if type(list) == "table" then
					local tradeName = (C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillDisplayName and C_TradeSkillUI.GetTradeSkillDisplayName(tradeID))
						or (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(tradeID))
						or tostring(tradeID)
					for _, raw in ipairs(list) do
						local recipeID = parseRecipeID(raw)
						local recipe = recipeID and CraftForge:GetRecipe(recipeID)
						if recipe and recipe.name and recipe.name:lower():find(q, 1, true) then
							table.insert(recipeHits, {
								name = recipe.name,
								player = player,
								trade = tradeName,
								recipeID = recipeID,
							})
						end
					end
				end
			end
		end
	end

	local invHits = {}
	local invDB = realmDB.inventoryData or {}
	for player, items in pairs(invDB) do
		if type(items) == "table" then
			for itemID, packed in pairs(items) do
				if type(itemID) == "number" and type(packed) == "string" then
					local itemName = C_Item.GetItemInfo(itemID)
					if itemName and itemName:lower():find(q, 1, true) then
						local bags, both = strsplit(" ", packed)
						local total = tonumber(both) or tonumber(bags) or 0
						if total > 0 then
							table.insert(invHits, {
								name = itemName,
								player = player,
								bags = tonumber(bags) or 0,
								total = total,
							})
						end
					end
				end
			end
		end
	end

	if _G.DataStore and _G.DataStore.GetCharacters and _G.DataStore.GetContainerItemCount and CraftForge.data and CraftForge.data.reagentToRecipe then
		for charName, charKey in pairs(_G.DataStore:GetCharacters()) do
			if not invDB[charName] then
				for itemID in pairs(CraftForge.data.reagentToRecipe) do
					if type(itemID) == "number" then
						local itemName = C_Item.GetItemInfo(itemID)
						if itemName and itemName:lower():find(q, 1, true) then
							local bags, bank = _G.DataStore:GetContainerItemCount(charKey, itemID)
							local total = (bags or 0) + (bank or 0)
							if total > 0 then
								table.insert(invHits, {
									name = itemName,
									player = charName,
									bags = bags or 0,
									total = total,
								})
							end
						end
					end
				end
			end
		end
	end

	local rHead = AceGUI:Create("Heading")
	rHead:SetFullWidth(true)
	rHead:SetText(L["ALT_FINDER_RECIPES"] .. " (" .. #recipeHits .. ")")
	scroll:AddChild(rHead)

	if #recipeHits == 0 then
		local empty = AceGUI:Create("Label")
		empty:SetFullWidth(true)
		empty:SetText("|cff888888" .. L["None"] .. "|r")
		scroll:AddChild(empty)
	else
		table.sort(recipeHits, function(a, b)
			if a.name == b.name then return a.player < b.player end
			return a.name < b.name
		end)
		for i = 1, math.min(#recipeHits, 60) do
			local hit = recipeHits[i]
			local lbl = AceGUI:Create("Label")
			lbl:SetFullWidth(true)
			lbl:SetText(string.format("|cffffd100%s|r  —  |cff66ccff%s|r (%s)", hit.name, hit.player, hit.trade))
			scroll:AddChild(lbl)
		end
	end

	local iHead = AceGUI:Create("Heading")
	iHead:SetFullWidth(true)
	iHead:SetText(L["ALT_FINDER_INVENTORY"] .. " (" .. #invHits .. ")")
	scroll:AddChild(iHead)

	if #invHits == 0 then
		local empty = AceGUI:Create("Label")
		empty:SetFullWidth(true)
		empty:SetText("|cff888888" .. L["None"] .. "|r")
		scroll:AddChild(empty)
	else
		table.sort(invHits, function(a, b)
			if a.name == b.name then return a.player < b.player end
			return a.name < b.name
		end)
		for i = 1, math.min(#invHits, 60) do
			local hit = invHits[i]
			local lbl = AceGUI:Create("Label")
			lbl:SetFullWidth(true)
			lbl:SetText(string.format("|cffffffff%s|r  —  |cff66ccff%s|r: %d (%s: %d)", hit.name, hit.player, hit.total, L["Bags"], hit.bags))
			scroll:AddChild(lbl)
		end
	end
end

function CraftForge:ShowAltFinder()
	if not AceGUI then return end
	if altFinderFrame then
		altFinderFrame:Show()
		return
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("CraftForge — " .. L["ALT_FINDER_TITLE"])
	frame:SetLayout("Flow")
	frame:SetWidth(540)
	frame:SetHeight(440)
	frame:EnableResize(false)
	frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		altFinderFrame = nil
	end)

	local searchBox = AceGUI:Create("EditBox")
	searchBox:SetLabel(L["Search"])
	searchBox:SetFullWidth(true)
	searchBox:DisableButton(true)
	frame:AddChild(searchBox)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	frame:AddChild(scroll)

	searchBox:SetCallback("OnTextChanged", function(_, _, text)
		populateAltResults(scroll, text)
	end)

	populateAltResults(scroll, "")
	altFinderFrame = frame
	DA.DEBUG(0, "ShowAltFinder: opened")
end
