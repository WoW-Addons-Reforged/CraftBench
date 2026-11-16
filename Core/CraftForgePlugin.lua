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

CraftForge.registeredPlugins = {}		-- plugins that have registered a function
CraftForge.updatePlugins = {}			-- each plugin will register if it has an Update function
CraftForge.processQueuePlugins = {}	-- each plugin will register if it has a ProcessQueue function
CraftForge.displayDetailPlugins = {}	-- each plugin will register if it has a GetExtraText function
CraftForge.RecipeNamePrefixes = {}		-- each plugin will register, only one can be active
CraftForge.RecipeNameSuffixes = {}		-- each plugin will register, only one can be active

local PLUGIN_ADDON_MAP = {
	AckisRecipeList = { "AckisRecipeList", "AckisRecipeList_Classic" },
	AllTheThings = { "AllTheThings" },
	Auctionator = { "Auctionator" },
	AuctionDB = { "AuctionDB" },
	Baganator = { "Baganator" },
	BeanCounter = { "BeanCounter" },
	CanIMogIt = { "CanIMogIt" },
	DataStoreAuctions = { "DataStore_Auctions" },
	OribosExchange = { "OribosExchange" },
	Overachiever = { "Overachiever" },
	TSM = { "TradeSkillMaster" },
	ElvUI = { "ElvUI" },
	BetterBags = { "BetterBags" },
	TomTom = { "TomTom" },
}

local function isAddonInstalled(addon)
	local exists = false
	if C_AddOns and C_AddOns.DoesAddOnExist then
		exists = C_AddOns.DoesAddOnExist(addon)
	elseif C_AddOns and C_AddOns.GetAddOnInfo then
		exists = C_AddOns.GetAddOnInfo(addon) ~= nil
	elseif GetAddOnInfo then
		exists = GetAddOnInfo(addon) ~= nil
	end
	if not exists then
		return false
	end
	if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(addon) then
		return true
	elseif IsAddOnLoaded and IsAddOnLoaded(addon) then
		return true
	end
	if C_AddOns and C_AddOns.GetAddOnEnableState then
		local player = UnitName and UnitName("player") or nil
		return (C_AddOns.GetAddOnEnableState(addon, player) or 0) > 0
	elseif GetAddOnEnableState then
		local player = UnitName and UnitName("player") or nil
		return (GetAddOnEnableState(player, addon) or 0) > 0
	end
	return true
end

local function getAddonVersion(addon)
	local ver
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		ver = C_AddOns.GetAddOnMetadata(addon, "Version")
	elseif GetAddOnMetadata then
		ver = GetAddOnMetadata(addon, "Version")
	end
	if ver and ver ~= "" then
		return tostring(ver)
	end
	return nil
end

function CraftForge:IsPluginAddonInstalled(pluginName)
	local candidates = PLUGIN_ADDON_MAP[pluginName] or { pluginName }
	for _, addon in ipairs(candidates) do
		if isAddonInstalled(addon) then
			return true
		end
	end
	return false
end

function CraftForge:GetPluginAddonVersion(pluginName)
	local candidates = PLUGIN_ADDON_MAP[pluginName] or { pluginName }
	for _, addon in ipairs(candidates) do
		if isAddonInstalled(addon) then
			return getAddonVersion(addon)
		end
	end
	return nil
end

local AH_ADDONS = {
	{ key = "Auctionator", label = "Auctionator", addon = "Auctionator" },
	{ key = "TSM", label = "TradeSkillMaster (TSM)", addon = "TradeSkillMaster" },
	{ key = "OribosExchange", label = "OribosExchange", addon = "OribosExchange" },
	{ key = "AuctionDB", label = "AuctionDB", addon = "AuctionDB" },
	{ key = "BeanCounter", label = "BeanCounter", addon = "BeanCounter" },
	{ key = "DataStoreAuctions", label = "DataStore_Auctions", addon = "DataStore_Auctions" },
}

local BAG_ADDONS = {
	{ key = "Baganator", label = "Baganator", addon = "Baganator" },
	{ key = "BetterBags", label = "BetterBags", addon = "BetterBags" },
	{ key = "Bagnon", label = "Bagnon", addon = "Bagnon" },
	{ key = "Combuctor", label = "Combuctor", addon = "Combuctor" },
	{ key = "ArkInventory", label = "ArkInventory", addon = "ArkInventory" },
	{ key = "ElvUI", label = "ElvUI Bags", addon = "ElvUI" },
	{ key = "AdiBags", label = "AdiBags", addon = "AdiBags" },
	{ key = "LiteBag", label = "LiteBag", addon = "LiteBag" },
}

local function buildAddonValues(list)
	local vals = { Auto = L["PLUGIN_AUTO"] }
	for _, entry in ipairs(list) do
		if isAddonInstalled(entry.addon) then
			local ver = getAddonVersion(entry.addon)
			vals[entry.key] = ver and (entry.label .. " (" .. ver .. ")") or entry.label
		end
	end
	return vals
end

local function buildInstalledSummary()
	local lines = {}
	local checkList = {
		{ "Auctionator", "Auctionator" },
		{ "TradeSkillMaster", "TradeSkillMaster" },
		{ "OribosExchange", "OribosExchange" },
		{ "AuctionDB", "AuctionDB" },
		{ "BeanCounter", "BeanCounter" },
		{ "DataStore_Auctions", "DataStore_Auctions" },
		{ "Baganator", "Baganator" },
		{ "BetterBags", "BetterBags" },
		{ "Bagnon", "Bagnon" },
		{ "Combuctor", "Combuctor" },
		{ "ArkInventory", "ArkInventory" },
		{ "ElvUI", "ElvUI" },
		{ "AdiBags", "AdiBags" },
		{ "LiteBag", "LiteBag" },
		{ "AllTheThings", "AllTheThings" },
		{ "AckisRecipeList", "AckisRecipeList" },
		{ "CanIMogIt", "CanIMogIt" },
		{ "Overachiever", "Overachiever" },
		{ "TomTom", "TomTom" },
		{ "Pawn", "Pawn" },
	}
	for _, pair in ipairs(checkList) do
		if isAddonInstalled(pair[1]) then
			local ver = getAddonVersion(pair[1]) or "?"
			table.insert(lines, "|cff00ff00•|r " .. pair[2] .. " |cffaaaaaa(v" .. ver .. ")|r")
		end
	end
	if #lines == 0 then
		return "|cff888888" .. L["None"] .. "|r"
	end
	return table.concat(lines, "\n")
end

local function hasDropdownEntries(values)
	for k in pairs(values) do
		if k ~= " " then
			return true
		end
	end
	return false
end

CraftForge.pluginsOrder = 10
CraftForge.pluginsOptions = {
		name = L["Plugins"],
		type = "group",
		childGroups = "tree",
		args = {
			ActiveSourcesSection = {
				type = "group",
				name = L["PLUGIN_ACTIVE_SOURCES"],
				order = 1,
				args = {
					ahAddon = {
						type = "select",
						name = L["PLUGIN_AH_ADDON"],
						desc = L["PLUGIN_AH_ADDON_DESC"],
						order = 1,
						width = 1.6,
						values = function()
							return buildAddonValues(AH_ADDONS)
						end,
						get = function()
							return CraftForge.db.profile.plugins.preferredAHAddon or "Auto"
						end,
						set = function(_, value)
							CraftForge.db.profile.plugins.preferredAHAddon = value
							CraftForge:UpdateTradeSkillWindow()
						end,
					},
					bagAddon = {
						type = "select",
						name = L["PLUGIN_BAG_ADDON"],
						desc = L["PLUGIN_BAG_ADDON_DESC"],
						order = 2,
						width = 1.6,
						values = function()
							return buildAddonValues(BAG_ADDONS)
						end,
						get = function()
							return CraftForge.db.profile.plugins.preferredBagAddon or "Auto"
						end,
						set = function(_, value)
							CraftForge.db.profile.plugins.preferredBagAddon = value
						end,
					},
					installedHeader = {
						type = "header",
						name = L["PLUGIN_INSTALLED_VERSIONS"],
						order = 3,
					},
					installedList = {
						type = "description",
						name = function()
							return buildInstalledSummary()
						end,
						fontSize = "medium",
						order = 4,
					},
				},
			},
			RecipeDisplaySection = {
				type = "group",
				name = L["PLUGIN_RECIPE_DISPLAY"],
				order = 2,
				hidden = function()
					local args = CraftForge.pluginsOptions.args.RecipeDisplaySection.args
					return not hasDropdownEntries(args.RecipeNamePrefix.values)
						and not hasDropdownEntries(args.RecipeNameSuffix.values)
				end,
				args = {
					RecipeNameHeader = {
						type = "description",
						name = L["PluginRecipeNameHelp"],
						fontSize = "medium",
						order = 0,
					},
					RecipeNamePrefix = {
						type = "select",
						name = L["RecipeNamePrefix"],
						desc = L["Only one plugin can supply prefix text"],
						order = 1,
						width = 1.4,
						hidden = function()
							local args = CraftForge.pluginsOptions.args.RecipeDisplaySection.args
							return not hasDropdownEntries(args.RecipeNamePrefix.values)
						end,
						get = function()
							local args = CraftForge.pluginsOptions.args.RecipeDisplaySection.args
							local val = CraftForge.db.profile.plugins.recipeNamePrefix
							if val and args.RecipeNamePrefix.values[val] then
								return val
							end
							return " "
						end,
						set = function(_, value)
							CraftForge.db.profile.plugins.recipeNamePrefix = value
							CraftForge:UpdateTradeSkillWindow()
						end,
						values = {
							[" "] = L["None"],
						},
					},
					RecipeNameSuffix = {
						type = "select",
						name = L["RecipeNameSuffix"],
						desc = L["Only one plugin can supply suffix text"],
						order = 2,
						width = 1.4,
						hidden = function()
							local args = CraftForge.pluginsOptions.args.RecipeDisplaySection.args
							return not hasDropdownEntries(args.RecipeNameSuffix.values)
						end,
						get = function()
							local args = CraftForge.pluginsOptions.args.RecipeDisplaySection.args
							local val = CraftForge.db.profile.plugins.recipeNameSuffix
							if val and args.RecipeNameSuffix.values[val] then
								return val
							end
							return " "
						end,
						set = function(_, value)
							CraftForge.db.profile.plugins.recipeNameSuffix = value
							CraftForge:UpdateTradeSkillWindow()
						end,
						values = {
							[" "] = L["None"],
						},
					},
				},
			},
		},
	}

local pluginBaseNames = {}

local PLUGIN_DESCRIPTIONS = {
	AckisRecipeList = "Uses AckisRecipeList (ARL) recipe source data for unlearned recipe filtering and acquisition details.",
	AchievementsUtils = "Uses AchievementsUtils (FindByCriteriaName, GetAchievement) "
		.. "to show achievement icons and uncompleted criteria details on matching recipes/items.",
	AllTheThings = "Uses AllTheThings (ATT) recipe acquisition sources in tooltips and collection status prefixes in the recipe list.",
	AtlasLoot = "Uses AtlasLootClassic (Data.Recipe, VendorPrice) to look up recipe scroll items and vendor prices in recipe details.",
	Auctionator = "Uses Auctionator live AH buyout prices for crafted items & reagents "
		.. "to compute craft cost, net profit, profit %, and trigger AH shopping searches.",
	AuctionDB = "Uses AuctionDB AH scan prices for item values, reagent costs, and profit calculation.",
	Baganator = "Uses Baganator / Syndicator bag & bank slot hooks for Material Processing and cross-character item counts.",
	BeanCounter = "Uses BeanCounter historical AH purchase & sale records to show personal paid/earned averages in recipe details.",
	BetterBags = "Uses BetterBags slot hooks for one-click modifier-key Material Processing (Disenchant, Prospect, Mill, Pick Lock).",
	CanIMogIt = "Uses CanIMogIt transmog collection status (Known / Unknown) prefixes on craftable gear.",
	DataStoreAuctions = "Uses DataStore_Auctions to show active alt auction counts in recipe prefixes and /cf find.",
	ElvUI = "Optional ElvUI skin integration (CraftForge's native Dark-Gold UI stays active unless explicitly enabled).",
	OribosExchange = "Uses OribosExchange realm & region market prices for craft cost, sell value, and profit suffixes.",
	Overachiever = "Uses Overachiever recipe achievement lookups (GetIconForRecipe) to mark recipes needed for achievements.",
	Questie = "Uses QuestieDB (vendors, npcDrops, relatedQuests) to show vendor NPCs/zones, drops, and quest sources in recipe details.",
	TomTom = "Uses TomTom (AddWaypoint) to create one-click map waypoints from visited Trade Contacts (/cf contacts).",
	TSM = "Uses TradeSkillMaster (TSM_API) price sources (DBMarket, DBMinBuyout, Crafting, etc.) for reagent costs, sell value, and profit calculation.",
}

function CraftForge:AddPluginOptions(options)
	if not options or not options.name then return end
	local baseName = pluginBaseNames[options] or options.name
	pluginBaseNames[options] = baseName
	if not self:IsPluginAddonInstalled(baseName) then
		return
	end
	local ver = self:GetPluginAddonVersion(baseName)
	if ver then
		options.name = baseName .. " |cff888888(" .. ver .. ")|r"
	end
	local desc = L["PLUGIN_DESC_" .. baseName] or PLUGIN_DESCRIPTIONS[baseName]
	if desc and options.args and not options.args._craftforge_desc then
		options.args._craftforge_desc = {
			type = "description",
			name = "|cffffd100" .. desc .. "|r",
			order = 0,
			fontSize = "medium",
		}
	end
	options.order = CraftForge.pluginsOrder
	CraftForge.pluginsOrder = CraftForge.pluginsOrder + 1
	CraftForge.pluginsOptions.args[baseName] = options
end

function CraftForge:RegisterRecipeNamePlugin(moduleName, priority)
	DA.DEBUG(0,"RegisterRecipeNamePlugin("..tostring(moduleName)..", "..tostring(priority))
	if not priority then priority = 100 end
	if type(moduleName) == "string" then
		local module = CraftForge[moduleName]
		if module and type(module) == "table" then
			local baseName = module.options and (pluginBaseNames[module.options] or module.options.name)
			local installed = baseName and self:IsPluginAddonInstalled(baseName)
			local displayArgs = CraftForge.pluginsOptions.args.RecipeDisplaySection.args
			if module.RecipeNamePrefix then
				CraftForge.RecipeNamePrefixes[moduleName] = module
				CraftForge.registeredPlugins[moduleName] = module
				if installed then
					displayArgs.RecipeNamePrefix.values[baseName] = baseName
				end
			end
			if module.RecipeNameSuffix then
				CraftForge.RecipeNameSuffixes[moduleName] = module
				CraftForge.registeredPlugins[moduleName] = module
				if installed then
					displayArgs.RecipeNameSuffix.values[baseName] = baseName
				end
			end
		end
	end
end

function CraftForge:IsRecipeNamePluginRegistered(moduleName)
	if type(moduleName) == "string" then
		return (CraftForge.RecipeNamePrefixes[moduleName] ~= nil) or (CraftForge.RecipeNameSuffixes[moduleName] ~= nil)
	end
end

function CraftForge:RegisterDisplayDetailPlugin(moduleName, priority)
	DA.DEBUG(0,"RegisterDisplayDetailPlugin("..tostring(moduleName)..", "..tostring(priority))
	if not priority then priority = 100 end
	if type(moduleName) == "string" then
		local module = CraftForge[moduleName]
		if module and type(module) == "table" and module.GetExtraText then
			CraftForge.displayDetailPlugins[moduleName] = module
			CraftForge.registeredPlugins[moduleName] = module
		end
	end
end

function CraftForge:IsDisplayDetailPluginRegistered(moduleName)
	if type(moduleName)	 == "string" then
		return CraftForge.displayDetailPlugins[moduleName] ~= nil
	end
end

function CraftForge:RegisterUpdatePlugin(moduleName, priority)
	DA.DEBUG(0,"RegisterUpdatePlugin("..tostring(moduleName)..", "..tostring(priority))
	if not priority then priority = 100 end
	if type(moduleName) == "string" then
		local module = CraftForge[moduleName]
		if module and type(module) == "table" and module.Update then
			CraftForge.updatePlugins[moduleName] = module
			CraftForge.registeredPlugins[moduleName] = module
		end
	end
end

function CraftForge:IsUpdatePluginRegistered(moduleName)
	if type(moduleName)	 == "string" then
		return CraftForge.updatePlugins[moduleName] ~= nil
	end
end

function CraftForge:UpdatePlugins()
	--DA.DEBUG(0,"UpdatePlugins()")
	for k,v in pairs(CraftForge.updatePlugins) do
		v.Update()
	end
end

function CraftForge:RegisterProcessQueuePlugin(moduleName, priority)
	DA.DEBUG(0,"RegisterProcessQueuePlugin("..tostring(moduleName)..", "..tostring(priority))
	if not priority then priority = 100 end
	if type(moduleName) == "string" then
		local module = CraftForge[moduleName]
		if module and type(module) == "table" and module.ProcessQueue then
			CraftForge.processQueuePlugins[moduleName] = module
			CraftForge.registeredPlugins[moduleName] = module
		end
	end
end

function CraftForge:IsProcessQueuePluginRegistered(moduleName)
	if type(moduleName)	 == "string" then
		return CraftForge.processQueuePlugins[moduleName] ~= nil
	end
end

function CraftForge:ProcessQueuePlugins()
	--DA.DEBUG(0,"ProcessQueuePlugins()")
	for k,v in pairs(CraftForge.processQueuePlugins) do
		v.ProcessQueue()
	end
end

function CraftForge:GetExtraText(skill, recipe)
	local lines = {}
	for _, v in pairs(CraftForge.displayDetailPlugins) do
		local label, text = v.GetExtraText(skill, recipe)
		local hasLabel = label and label ~= ""
		local hasText = text and text ~= ""
		if hasLabel and hasText then
			local cleanLabel = label:gsub("^|r", "")
			table.insert(lines, "|cffffd100" .. cleanLabel .. "|r  " .. text)
		elseif hasLabel then
			table.insert(lines, label)
		elseif hasText then
			table.insert(lines, text)
		end
	end
	if #lines > 0 then
		return table.concat(lines, "\n"), nil
	end
	return nil, nil
end

function CraftForge:RecipeNamePrefix(skill, recipe)
	local text
	local recipeNamePrefix = self.db.profile.plugins.recipeNamePrefix
	if recipeNamePrefix and recipeNamePrefix ~= " " then
		for _, v in pairs(CraftForge.RecipeNamePrefixes) do
			local baseName = v.options and (pluginBaseNames[v.options] or v.options.name)
			if v.RecipeNamePrefix and baseName == recipeNamePrefix then
				text = v.RecipeNamePrefix(skill, recipe)
				break
			end
		end
	end
	return text
end

function CraftForge:RecipeNameSuffix(skill, recipe)
	local text
	local recipeNameSuffix = self.db.profile.plugins.recipeNameSuffix
	if recipeNameSuffix and recipeNameSuffix ~= " " then
		for _, v in pairs(CraftForge.RecipeNameSuffixes) do
			local baseName = v.options and (pluginBaseNames[v.options] or v.options.name)
			if v.RecipeNameSuffix and baseName == recipeNameSuffix then
				text = v.RecipeNameSuffix(skill, recipe)
				break
			end
		end
	end
	return text
end

function CraftForge:InitializePlugins()
	DA.DEBUG(0,"InitializePlugins()")
	for k,v in pairs(CraftForge.registeredPlugins) do
		if v and v.OnInitialize then
			DA.DEBUG(1,"InitializePlugins: k= "..tostring(k)..", v= "..tostring(v))
			v.OnInitialize()
		end
	end
end

function CraftForge:EnablePlugins()
	DA.DEBUG(0,"EnablePlugins()")
	for k,v in pairs(CraftForge.registeredPlugins) do
		if v and v.OnEnable then
			DA.DEBUG(1,"EnablePlugins: k= "..tostring(k)..", v= "..tostring(v))
			v.OnEnable()
		end
	end
end

function CraftForge:DisablePlugins()
	DA.DEBUG(0,"DisablePlugins()")
	for k,v in pairs(CraftForge.registeredPlugins) do
		if v and v.OnDisable then
			DA.DEBUG(1,"DisablePlugins: k= "..tostring(k)..", v= "..tostring(v))
			v.OnDisable()
		end
	end
end

