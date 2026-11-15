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

CraftForge.ATTPlugin = {}

local plugin = CraftForge.ATTPlugin
local L = CraftForge.L

plugin.options = {
	type = "group",
	name = "AllTheThings",
	order = 1,
	args = {
		enabled = {
			type = "toggle",
			name = L["Enabled"],
			get = function()
				return CraftForge.db.profile.plugins.ATT.enabled
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.ATT.enabled = value
				CraftForge:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 1,
		},
		showItemStatus = {
			type = "toggle",
			name = L["Show item collection status"],
			get = function()
				return CraftForge.db.profile.plugins.ATT.showItemStatus
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.ATT.showItemStatus = value
				CraftForge:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 2,
		},
		showRecipeStatus = {
			type = "toggle",
			name = L["Show recipe collection status"],
			get = function()
				return CraftForge.db.profile.plugins.ATT.showRecipeStatus
			end,
			set = function(_, value)
				CraftForge.db.profile.plugins.ATT.showRecipeStatus = value
				CraftForge:UpdateTradeSkillWindow()
			end,
			width = "double",
			order = 3,
		},
	},
}

function plugin.OnInitialize()
	if not CraftForge.db.profile.plugins.ATT then
		CraftForge.db.profile.plugins.ATT = {
			enabled = true,
			showItemStatus = true,
			showRecipeStatus = true,
		}
	end
	CraftForge:AddPluginOptions(plugin.options)
end

local function queryATTIcon(att, field, id, fallbackCreate)
	if not id then return nil end
	local obj
	if att.SearchForObject then
		local ok, res = pcall(att.SearchForObject, field, id, "field")
		if ok and res then obj = res end
	end
	if not obj and att.SearchForField then
		local ok, res = pcall(att.SearchForField, field, id)
		if ok and type(res) == "table" and res[1] then obj = res[1] end
	end
	if not obj and fallbackCreate then
		local ok, res = pcall(fallbackCreate, id)
		if ok and res then obj = res end
	end
	if not obj then return nil end
	if att.GetProgressTextForRow then
		local ok, iconText = pcall(att.GetProgressTextForRow, obj, true)
		if ok and type(iconText) == "string" and iconText ~= "" then
			return iconText
		end
	end
	if obj.collected == 1 or obj.saved then
		return "|cff00ff00" .. L["Collected"] .. "|r"
	elseif obj.collectible then
		return "|cffff4444" .. L["Not collected"] .. "|r"
	end
	return nil
end

function plugin.RecipeNamePrefix(skill, recipe)
	if not skill or not recipe then return end
	local att = _G.AllTheThings
	local cfg = CraftForge.db and CraftForge.db.profile and CraftForge.db.profile.plugins and CraftForge.db.profile.plugins.ATT
	if not att or not cfg or not cfg.enabled then return end
	if cfg.showItemStatus and recipe.itemID then
		local icon = queryATTIcon(att, "itemID", recipe.itemID, att.CreateItem)
		if icon then return icon end
	end
	if cfg.showRecipeStatus and recipe.spellID then
		local icon = queryATTIcon(att, "recipeID", recipe.spellID, att.CreateRecipe) or queryATTIcon(att, "spellID", recipe.spellID)
		if icon then return icon end
	end
end

local function buildATTSourcePath(obj)
	if not obj then return nil end
	local parts = {}
	local cur = obj.sourceParent or obj.parent
	local depth = 0
	while cur and depth < 6 do
		local seg = cur.sourceText or cur.text
		if type(seg) == "string" and seg ~= "" and seg ~= RETRIEVING_DATA then
			table.insert(parts, 1, seg)
		end
		cur = cur.sourceParent or cur.parent
		depth = depth + 1
	end
	if #parts > 0 then
		return table.concat(parts, " > ")
	end
	return nil
end

function plugin.GetRecipeSource(skill, recipe)
	if not skill and not recipe then return nil end
	local att = _G.AllTheThings
	local cfg = CraftForge.db and CraftForge.db.profile and CraftForge.db.profile.plugins and CraftForge.db.profile.plugins.ATT
	if not att or not cfg or not cfg.enabled or not att.SearchForField then return nil end

	local candidates
	local recipeID = (skill and skill.recipeID) or (recipe and recipe.spellID)
	local spellID = recipe and recipe.spellID
	local itemID = recipe and recipe.itemID

	local function searchFirst(field, id)
		if not id or id == 0 then return nil end
		local ok, res = pcall(att.SearchForField, field, id)
		if ok and type(res) == "table" and #res > 0 then
			return res
		end
		return nil
	end

	candidates = searchFirst("recipeID", recipeID)
		or searchFirst("spellID", recipeID)
		or (spellID and spellID ~= recipeID and (searchFirst("recipeID", spellID) or searchFirst("spellID", spellID)))
		or searchFirst("itemID", itemID)

	if not candidates then return nil end

	local seen = {}
	local paths = {}
	for _, entry in ipairs(candidates) do
		local path = buildATTSourcePath(entry)
		if path and not seen[path] then
			seen[path] = true
			table.insert(paths, path)
			if #paths >= 2 then break end
		end
	end
	if #paths > 0 then
		return table.concat(paths, "\n")
	end
	return nil
end

function plugin.GetExtraText(skill, recipe)
	if not skill or not recipe then return end
	local att = _G.AllTheThings
	local cfg = CraftForge.db and CraftForge.db.profile and CraftForge.db.profile.plugins and CraftForge.db.profile.plugins.ATT
	if not att or not cfg or not cfg.enabled then return end
	local parts = {}
	if cfg.showItemStatus and recipe.itemID then
		local icon = queryATTIcon(att, "itemID", recipe.itemID, att.CreateItem)
		if icon then
			table.insert(parts, L["Item"] .. ": " .. icon)
		end
	end
	if cfg.showRecipeStatus and recipe.spellID then
		local icon = queryATTIcon(att, "recipeID", recipe.spellID, att.CreateRecipe) or queryATTIcon(att, "spellID", recipe.spellID)
		if icon then
			table.insert(parts, L["Recipe"] .. ": " .. icon)
		end
	end
	local showSource = CraftForge.db.profile.show_recipe_source_for_learned
	if not showSource then
		local rInfo = C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo and (recipe.spellID or skill.id) and C_TradeSkillUI.GetRecipeInfo(recipe.spellID or skill.id)
		if rInfo and rInfo.learned then
			showSource = false
		elseif rInfo and not rInfo.learned then
			showSource = true
		elseif skill.learned == false or recipe.learned == false then
			showSource = true
		end
	end
	local src = showSource and plugin.GetRecipeSource(skill, recipe) or nil
	if src then
		table.insert(parts, "\n|cffffd100" .. L["Source"] .. ":|r\n  " .. src:gsub("\n", "\n  "))
	end
	if #parts > 0 then
		return "AllTheThings:", table.concat(parts, "  ")
	end
end

CraftForge:RegisterRecipeNamePlugin("ATTPlugin")
CraftForge:RegisterDisplayDetailPlugin("ATTPlugin")
