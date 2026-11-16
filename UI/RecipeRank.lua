local addonName,addonTable = ...
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

local L = LibStub("AceLocale-3.0"):GetLocale("CraftBench")

--
-- Called when the grouping operators drop down is displayed
--
function CraftBench:RecipeRankSelector_OnClick(this)
	if not CraftBench.RecipeRankMenu then
		CraftBench.RecipeRankMenu = CreateFrame("Frame", "RecipeRankMenu", _G["UIParent"], "UIDropDownMenuTemplate")
	end
	UIDropDownMenu_Initialize(CraftBenchRecipeRankDropMenu, CraftBench.InitializeRecipeRankDropdown, "MENU")
	ToggleDropDownMenu(1, nil, CraftBenchRecipeRankDropMenu, this, this:GetWidth(), 0)
end

--
-- The method we use the initialize the group ops drop down.
--
function CraftBench.InitializeRecipeRankDropdown(menuFrame,level)
	if level == 1 then
		local entry = {}
		local null = {}
		null.text = ""
		null.disabled = true

		entry.isNotRadio = true
		entry.text = "Rank 1"
		entry.value = 1
		entry.func = CraftBench.RecipeRankChange
		entry.arg1 = 1
		entry.arg2 = "Rank 1"
		UIDropDownMenu_AddButton(entry)
		if CraftBench.recipeRankMax > 1 then
			entry.text = "Rank 2"
			entry.value = 2
			entry.func = CraftBench.RecipeRankChange
			entry.arg1 = 2
			entry.arg2 = "Rank 2"
			UIDropDownMenu_AddButton(entry)
		end
		if CraftBench.recipeRankMax > 2 then
			entry.text = "Rank 3"
			entry.value = 3
			entry.func = CraftBench.RecipeRankChange
			entry.arg1 = 3
			entry.arg2 = "Rank 3"
			UIDropDownMenu_AddButton(entry)
		end
		if CraftBench:RecipeRankIsMaxLevel() then  -- CraftBench.recipeRankMax > 3
			entry.text = "Rank 4"
			entry.value = 4
			entry.func = CraftBench.RecipeRankChange
			entry.arg1 = 4
			entry.arg2 = "Rank 4"
			UIDropDownMenu_AddButton(entry)
		end
	end
end

function CraftBench:RecipeRankChange(rank, text)
	DA.DEBUG(0,"RecipeRankChange("..tostring(rank)..", '"..tostring(text).."')")
	CraftBench.recipeRank = rank
	CraftBenchRecipeRankLabel:SetText(text)
	CraftBench:UpdateDetailWindow(CraftBench.currentSkillIndex)
end

function CraftBench:RecipeRankOnEnter(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	if ( self:RecipeRankIsMaxLevel() ) then
		GameTooltip_SetTitle(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_HIGHEST_RANK, NORMAL_FONT_COLOR)
		GameTooltip_AddColoredLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_HIGHEST_RANK_EXPLANATION, GREEN_FONT_COLOR)
	else
		local experiencePercent = math.floor((self.currentExperience / self.maxExperience) * 100)
		GameTooltip_SetTitle(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_RANK_FORMAT:format(self.recipeRank), NORMAL_FONT_COLOR)
		GameTooltip_AddHighlightLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_EXPERIENCE_FORMAT:format(self.currentExperience, self.maxExperience, experiencePercent))
		GameTooltip_AddColoredLine(GameTooltip, TRADESKILL_RECIPE_LEVEL_TOOLTIP_LEVELING_FORMAT:format(self.recipeRank + 1), GREEN_FONT_COLOR)
	end
	GameTooltip:Show()
end

function CraftBench:RecipeRankOnLeave()
	GameTooltip_Hide()
end

function CraftBench:RecipeRankSetExperience(currentExperience, maxExperience, currentLevel)
	self.currentExperience = currentExperience
	self.maxExperience = maxExperience

	if ( self:RecipeRankIsMaxLevel() ) then
		CraftBenchRecipeRankSkill:SetMinMaxValues(0, 1)
		CraftBenchRecipeRankSkill:SetValue(1)
		CraftBenchRecipeRankSkill.Rank:SetText(TRADESKILL_RECIPE_LEVEL_MAXIMUM)
	else
		CraftBenchRecipeRankSkill:SetMinMaxValues(0, maxExperience)
		CraftBenchRecipeRankSkill:SetValue(currentExperience)
		CraftBenchRecipeRankSkill.Rank:SetFormattedText(GENERIC_FRACTION_STRING, currentExperience, maxExperience)
	end
end

function CraftBench:RecipeRankIsMaxLevel()
	return self.currentExperience == nil
end

