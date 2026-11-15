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

CraftForge.pluginsOrder = 2
CraftForge.pluginsOptions = {
		name = "Plugins",
		type = "group",
		childGroups = "tree",
		args = {
			RecipeNamePrefix = {
				type = "select",
				name = "RecipeNamePrefix",
				desc = "Only one plugin can supply prefix text",
				order = 1,
				get = function() 
					return CraftForge.db.profile.plugins.recipeNamePrefix
				end,
				set = function(_, value)
					CraftForge.db.profile.plugins.recipeNamePrefix = value
					CraftForge:UpdateTradeSkillWindow()
				end,
				values = {
					[" "] = " ",
--					Additional entries filled in dynamically by RegisterRecipeNamePlugin
				},
			},
			RecipeNameSuffix = {
				type = "select",
				name = "RecipeNameSuffix",
				desc = "Only one plugin can supply suffix text",
				order = 1,
				get = function() 
					return CraftForge.db.profile.plugins.recipeNameSuffix
				end,
				set = function(_, value)
					CraftForge.db.profile.plugins.recipeNameSuffix = value
					CraftForge:UpdateTradeSkillWindow()
				end,
				values = {
					[" "] = " ",
--					Additional entries filled in dynamically by RegisterRecipeNamePlugin
				},
			},
-- 			Filled in dynamically by AddPluginOptions
		},
	}

function CraftForge:AddPluginOptions(options)
	options.order = CraftForge.pluginsOrder
	CraftForge.pluginsOrder = CraftForge.pluginsOrder + 1
	CraftForge.pluginsOptions.args[options.name] = options
end

function CraftForge:RegisterRecipeNamePlugin(moduleName, priority)
	DA.DEBUG(0,"RegisterRecipeNamePlugin("..tostring(moduleName)..", "..tostring(priority))
	if not priority then priority = 100 end
	if type(moduleName) == "string" then
		local module = CraftForge[moduleName]
		if module and type(module) == "table" then
			if module.RecipeNamePrefix then
				CraftForge.RecipeNamePrefixes[moduleName] = module
				CraftForge.registeredPlugins[moduleName] = module
				CraftForge.pluginsOptions.args.RecipeNamePrefix.values[module.options.name] = module.options.name
			end
			if module.RecipeNameSuffix then
				CraftForge.RecipeNameSuffixes[moduleName] = module
				CraftForge.registeredPlugins[moduleName] = module
				CraftForge.pluginsOptions.args.RecipeNameSuffix.values[module.options.name] = module.options.name
			end
		end
	end
end

function CraftForge:IsRecipeNamePluginRegistered(moduleName)
	if type(moduleName)	 == "string" then
		return CraftForge.RecipeNamePlugins[moduleName] ~= nil
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
	local output_label, output_text
	for k,v in pairs(CraftForge.displayDetailPlugins) do
		local label,text = v.GetExtraText(skill, recipe)
		if label and label ~= "" then
			if output_label then
				output_label = output_label.."\n\n"
			else
				output_label = ""
			end
			output_label = output_label..label
		end
		if text and text ~= "" then
			if output_text then
				output_text = output_text.."\n\n"
			else
				output_text = ""
			end
			output_text = output_text..text
		end
	end
	return output_label, output_text
end

function CraftForge:RecipeNamePrefix(skill, recipe)
	local text
	local recipeNamePrefix = self.db.profile.plugins.recipeNamePrefix
	if recipeNamePrefix and recipeNamePrefix ~= " " then
		for k,v in pairs(CraftForge.RecipeNamePrefixes) do
			--DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
			if v.RecipeNamePrefix and v.options.name == recipeNamePrefix then
				text = v.RecipeNamePrefix(skill, recipe)
				--DA.DEBUG(1,"text= "..tostring(text))
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
		for k,v in pairs(CraftForge.RecipeNameSuffixes) do
			--DA.DEBUG(1,"k= "..tostring(k)..", v= "..tostring(v))
			if v.RecipeNameSuffix and v.options.name == recipeNameSuffix then
				text = v.RecipeNameSuffix(skill, recipe)
				--DA.DEBUG(1,"text= "..tostring(text))
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

