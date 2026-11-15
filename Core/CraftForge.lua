local addonName,addonTable = ...
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

CraftForge = LibStub("AceAddon-3.0"):NewAddon("CraftForge", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local AceDB = LibStub("AceDB-3.0")

-- Pull it into the local namespace, it's faster to access that way
local CraftForge = CraftForge
local DA = CraftForge -- needed because LibStub changed the definition of CraftForge

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("CraftForge")
CraftForge.L = L

-- Get version info from the .toc file
CraftForge.version = C_AddOns.GetAddOnMetadata("CraftForge", "Version")
CraftForge.isTest = string.find(CraftForge.version,"-") or string.find(CraftForge.version,"+")
CraftForge.interface = select(4, GetBuildInfo())
CraftForge.build = (CraftForge.interface < 16000 and "Classic") or
  (CraftForge.interface < 20000 and "Forever") or 
  (CraftForge.interface < 30000 and "BCC") or
  (CraftForge.interface < 40000 and "Wrath") or 
  (CraftForge.interface < 50000 and "Cata") or
  (CraftForge.interface < 60000 and "Mists") or
  "Retail"
--
--	isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE -- 1
--	isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC -- 2
--	isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC -- 5
--	isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC -- 11
--	isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC -- 14
--	isForever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT -- 18
--	isMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC -- 19
--
CraftForge.project = WOW_PROJECT_ID
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
	CraftForge.isRetail = true
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	CraftForge.isClassic = true
elseif WOW_PROJECT_BURNING_CRUSADE_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
	CraftForge.isBCC = true
elseif WOW_PROJECT_WRATH_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
	CraftForge.isWrath = true
elseif WOW_PROJECT_CATACLYSM_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
	CraftForge.isCata = true
elseif WOW_PROJECT_MISTS_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC then
	CraftForge.isMists = true
elseif WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
	CraftForge.isForever = true
end
if GetGameType then
	CraftForge.gametype = GetGameType()
	CraftForge.isTalebound = CraftForge.gametype == "wowhack"
end

CraftForge.gttScale = GameTooltip:GetScale()

local defaults = {
	profile = {
--
-- user configurable options
--
		vendor_buy_button = true,
		vendor_auto_buy   = false,
		show_item_notes_tooltip = false,
		show_crafters_tooltip = false,
		show_detailed_recipe_tooltip = true,	-- show any tooltips?
		display_full_tooltip = true,			-- show full blizzards tooltip
		link_craftable_reagents = true,
		queue_craftable_reagents = true,
		queue_tools = false,
		queue_to_front = false,
		ignore_banked_reagents = false,
		ignore_queued_reagents = false,
		ignore_on_hand = false,
		queue_glyph_reagents = false,
		select_top_recipe = false,
		display_required_level = false,
		display_shopping_list_at_bank = true,
		display_shopping_list_at_guildbank = true,
		display_shopping_list_at_auction = true,
		display_shopping_list_at_merchant = false,
		use_blizzard_for_followers = false,
		show_recipe_source_for_learned = false,
		recipe_source_first = false,
		use_guildbank_as_alt = false,
		use_altcurrency_vendor_items = false,
		show_max_upgrade = true,
		queue_match_trade = false,
		queue_insert_first = false,
		enhanced_recipe_display = false,
		enhanced_chance_display = false,
		confirm_queue_clear = false,
		queue_only_view = true,
		dialog_switch = false,
		scale_tooltip = false,
		sound_on_empty_queue = false,
		sound_on_remove_queue = false,
		flash_on_empty_queue = false,
		flash_on_remove_queue = false,
		always_show_progress_bar = true,
		hide_blizzard_frame = true,
		scale_blizzard_frame = false,
		scale_blizzard_down = 0.4,
		scale_blizzard_up = 1.0,
		tsm_compat = false,
		tsm_prefer = false,
		transparency = 1.0,
		scale = 1.0,
		ttscale = 1.0,
		process_enabled = true,
		process_modifier = "ALT",
		process_disenchant = true,
		process_prospect = true,
		process_mill = true,
		process_lockpick = true,
		process_max_quality = 4,
		process_glow = true,
		plugins = {},
		SavedQueues = {},
	},
	realm = {
--
-- notes added to items crafted or used in crafting
--
		notes = {},
	},
}

--
-- default options for each player/tradeskill
--
CraftForge.defaultOptions = {
	["sortmethod"] = "None",
	["grouping"] = "Blizzard",
	["searchtext"] = "",
	["filterInventory-bag"] = true,
	["filterInventory-crafted"] = true,
	["filterInventory-vendor"] = true,
	["filterInventory-alts"] = false,
	["filterInventory-owned"] = true,
	["filterLevel"] = 1,
	["hideuncraftable"] = false,
	["favoritesOnly"] = false,
	["isfirstcraft"] = false,
}

CraftForge.unknownRecipe = {
	tradeID = 0,
	name = "unknown",
	tools = {},
	reagentData = {},
	numOptional = 0,
	cooldown = 0,
	itemID = 0,
	numMade = 0,
	spellID = 0,
	numCraftable = 0,
	numCraftableVendor = 0,
	numCraftableAlts = 0,
}

function CraftForge:DisableBlizzardFrame()
	DA.DEBUG(0,"DisableBlizzardFrame()")
	if not ProfessionsFrame then
		DA.WARN("DisableBlizzardFrame: ProfessionsFrame is nil")
	elseif CraftForge.isRetail or self.db.profile.hide_blizzard_frame then
		if self.BlizzardTradeSkillFrame == nil then
			self.BlizzardTradeSkillFrame = ProfessionsFrame
			self.tradeSkillHide = ProfessionsFrame:GetScript("OnHide")
			ProfessionsFrame:SetScript("OnHide", nil)
		end
		HideUIPanel(ProfessionsFrame)
		self.BlizzardUIshowing = false	
	elseif self.db.profile.scale_blizzard_frame then
		ProfessionsFrame:SetScale(self.db.profile.scale_blizzard_down or 0.4)
		self.BlizzardUIshowing = false	
	end
end

function CraftForge:EnableBlizzardFrame()
	DA.DEBUG(0,"EnableBlizzardFrame()")
	local blizzFrame = ProfessionsFrame or TradeSkillFrame
	if not blizzFrame then return end
	if self.BlizzardTradeSkillFrame ~= nil then
		self.BlizzardTradeSkillFrame = nil
		blizzFrame:SetScript("OnHide", self.tradeSkillHide)
		self.tradeSkillHide = nil
	end
	if CraftForge.isRetail or self.db.profile.hide_blizzard_frame then
		ShowUIPanel(blizzFrame)
	elseif self.db.profile.scale_blizzard_frame then
		blizzFrame:SetScale(self.db.profile.scale_blizzard_up or 1.0)
	end
	self.BlizzardUIshowing = true
end

--
-- Called when the addon is loaded
--
function CraftForge:OnInitialize()
	DA.DEBUG(0,"OnInitialize()");
--
--	Create the database
--
	self.db = AceDB:New("CraftForgeDB", defaults)
--
-- Information useful for debugging
--
	self.db.global.locale = GetLocale()
	self.db.global.version = self.version      -- from .toc
	self.db.global.project = self.project      -- WOW_PROJECT_ID
	self.db.global.interface = self.interface  -- from GetBuildInfo
	self.db.global.build = self.build          -- text derived from interface
	self.db.global.gametype = self.gametype    -- from GetGameType
	
	if not CraftForgeWho then
		CraftForgeWho = {}
	end
	if not CraftForgeDBPC then
		CraftForgeDBPC = {}
	end
	if not CraftForgeProfile then
		CraftForgeProfile = {}
	end
	if not CraftForgeMemory then
		CraftForgeMemory = {}
	end
	if DA.deepcopy then			-- For serious debugging, start with a clean slate
		CraftForgeMemory = {}
		CraftForgeDBPC = {}
	end
	DA.DebugLog = CraftForgeDBPC
	DA.DebugProfile = CraftForgeProfile
	if not self.InProgress then
		self.InProgress = {}
	end
--
-- Clean up obsolete data
--
	if self.db.realm.dataVersion then
		self.db.global.dataVersion = self.db.realm.dataVersion
		self.db.realm.dataVersion = nil
	end
	if self.db.realm.reagentBank then
		self.db.realm.reagentBank = nil
	end
	if self.db.global.AllRecipe then
		self.db.global.AllRecipe = nil
	end
	if self.db.realm.Filtered then
		self.db.realm.Filtered = nil
	end
	if self.db.realm.recipeInfo then
		self.db.realm.recipeInfo = nil
	end
	if self.db.realm.skillDB then
		self.db.realm.skillDB = nil
	end

--
-- Change the dataVersion when (major) code changes
-- obsolete the current saved variables database.
--
-- Change the customVersion when code changes obsolete 
-- the custom group specific saved variables data.
--
-- Change the queueVersion when code changes obsolete 
-- the queue specific saved variables data.
--
-- Change the recipeVersion when code changes obsolete 
-- the recipe specific saved variables data.
--
-- When Blizzard releases a new build, there's a chance that
-- recipes have changed (i.e. different reagent requirements) so
-- we clear the saved variables recipe data just to be safe.
--
	local dataVersion = 11
	if CraftForge.isForever then
		dataVersion = 12
	end
	local queueVersion = 1
	local customVersion = 1
	local recipeVersion = 1
	local detailsVersion = 1
	local _,wowBuild,_,wowVersion = GetBuildInfo();
	self.wowBuild = wowBuild
	self.wowVersion = wowVersion
	if not self.db.global.dataVersion or self.db.global.dataVersion ~= dataVersion then
		self.db.global.dataVersion = dataVersion
		self:FlushAllData()
	elseif not self.db.global.customVersion or self.db.global.customVersion ~= customVersion then
		self.db.global.customVersion = customVersion
		self:FlushCustomData()
	elseif not self.db.global.queueVersion or self.db.global.queueVersion ~= queueVersion then
		self.db.global.queueVersion = queueVersion
		self:FlushQueueData()
	elseif not self.db.global.recipeVersion or self.db.global.recipeVersion ~= recipeVersion then
		self.db.global.recipeVersion = recipeVersion
		self:FlushRecipeData()
	elseif not self.db.global.detailsVersion or self.db.global.detailsVersion ~= detailsVersion then
		self.db.global.detailsVersion = detailsVersion
		self:FlushDetailData()
	elseif not self.db.global.wowBuild or self.db.global.wowBuild ~= self.wowBuild then
		self.db.global.wowBuild = self.wowBuild
		self.db.global.wowVersion = self.wowVersion -- actually TOC version
		self:FlushRecipeData()
	end

--
-- Initialize global data
--
	if not self.db.global.recipeDB then
		self.db.global.recipeDB = {}
	end
	if not self.db.global.recipeNameDB then
		self.db.global.recipeNameDB = {}
	end
	if not self.db.global.itemRecipeSource then
		self.db.global.itemRecipeSource = {}
	end
	if not self.db.global.itemRecipeUsedIn then
		self.db.global.itemRecipeUsedIn = {}
	end
	if not self.db.global.Categories then
		self.db.global.Categories = {}
	end
	if not self.db.global.MissingVendorItems then
		self:InitializeMissingVendorItems()
	end
	if not self.db.global.AdjustNumMade then
		self.db.global.AdjustNumMade = {}
	end
	if not self.db.global.MissingSkillLevels then
		self.db.global.MissingSkillLevels = {}
	end
	if not self.db.global.SkillLevels then
		self:InitializeSkillLevels()
	end
	if not self.db.global.cachedGuildbank then
		self.db.global.cachedGuildbank = {}
	end
	if not self.db.global.customPrice then
		self.db.global.customPrice = {}
	end
	if not self.db.global.warbandData then
		self.db.global.warbandData = {}
	end
	if not self.db.global.warbandDetails then
		self.db.global.warbandDetails = {}
	end
--
-- Initialize the Skill Levels data if any of the tables are missing
--
	local initSkillLevels
	if not self.db.global.MissingSkillLevels then
		self.db.global.MissingSkillLevels = {}
		initSkillLevels = true
	end
	if not self.db.global.SkillLevels then
		self.db.global.SkillLevels = {}
		initSkillLevels = true
	end
	if not self.db.global.SkillLineAbility then
		self.db.global.SkillLineAbility = {}
		initSkillLevels = true
	end
	if not self.db.global.NameToSpellID then
		self.db.global.NameToSpellID = {}
		initSkillLevels = true
	end
	if initSkillLevels or not self.db.global.SkillLevelBuild or self.db.global.SkillLevelBuild ~= self.SkillLevelBuild then
		self.db.global.SkillLevelBuild = self.SkillLevelBuild
		if self.InitializeSkillLevels then
			self:InitializeSkillLevels()
		end
	end

--
-- configure the addon options and the slash command handler
-- (CraftForge.options is defined in CraftForgeOptions.lua)
--
	CraftForge:ConfigureOptions()
--
-- Copy the profile debugging variables to the global table 
-- where DebugAids.lua is looking for them.
--
-- Warning:	Setting TableDump can be a performance hog, use caution.
--			Setting DebugLogging (without DebugShow) is a minor performance hit.
--			WarnLog (with or without WarnShow) can remain on as warning messages are rare.
--			TraceLog2 controls event tracing of high frequency events like BAG_UPDATE
--
-- Note:	Undefined is the same as false so we only need to predefine true variables
--
	if CraftForge.db.profile.WarnLog == nil then
		CraftForge.db.profile.WarnLog = true
	end

	CraftForge.WarnLog = CraftForge.db.profile.WarnLog
	CraftForge.WarnShow = CraftForge.db.profile.WarnShow
	CraftForge.DebugShow = CraftForge.db.profile.DebugShow
	CraftForge.DebugLogging = CraftForge.db.profile.DebugLogging
	CraftForge.DebugLevel = CraftForge.db.profile.DebugLevel
	CraftForge.LogLevel = CraftForge.db.profile.LogLevel
	CraftForge.MAXDEBUG = CraftForge.db.profile.MAXDEBUG or 4000
	CraftForge.MAXPROFILE = CraftForge.db.profile.MAXPROFILE or 2000
	CraftForge.TableDump = CraftForge.db.profile.TableDump
	CraftForge.TraceShow = CraftForge.db.profile.TraceShow
	CraftForge.TraceLog = CraftForge.db.profile.TraceLog
	CraftForge.TraceLog2 = CraftForge.db.profile.TraceLog2
	CraftForge.ProfileShow = CraftForge.db.profile.ProfileShow
--
-- Profile variable to control CraftForge fixes for Blizzard bugs.
-- Can be toggled [or turned off] with "/craftforge fixbugs [off]"
--
	if CraftForge.db.profile.FixBugs == nil then
		CraftForge.db.profile.FixBugs = true
	end
	CraftForge.FixBugs = CraftForge.db.profile.FixBugs

--
-- Create static popups for changing professions
--
StaticPopupDialogs["CRAFTFORGE_CONTINUE_CHANGE"] = {
	text = "CraftForge-Classic\n"..L["Press Okay to continue changing professions"],
	button1 = OKAY,
	OnAccept = function( self )
		CraftForge:ContinueChange()
		return
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CRAFTFORGE_MANUAL_CHANGE"] = {
	text = "CraftForge\n"..L["Press your button which opens %s"],
--	button1 = OKAY,
--	OnAccept = function( self )
--		CraftForge:ContinueChange(true)
--		return
--	end,
	OnCancel = function( self )
		CraftForge:FinishChange()
		return
	end,
	OnHide = function( self )
		CraftForge:FinishChange()
		return
	end,
	timeout = 30,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

--
-- Create our frame
--
	if not CraftForge.tradeSkillFrame then
		CraftForge.tradeSkillFrame = CraftForge:CreateTradeSkillWindow()
		tinsert(UISpecialFrames, CraftForge.tradeSkillFrame:GetName())
	end

--
-- Now do the character initialization
--
	self:InitializeDatabase(CraftForge:unitName("player"))
	self:InitializePlugins()
	self.NewsGUI:Initialize()

--
--	Some counters for high frequency events
--
	if not CraftForge.bagUpdateCounts then
		CraftForge.bagUpdateCounts = {}
	end
	CraftForge.bagUpdateDelayedCount = 0
	CraftForge.unitInventoryChangedCount = 0
	CraftForge.bankUpdateCount = 0
end

--
-- These functions reset parts of the database primarily
-- when code changes obsolete the current database.
--
-- FlushAllData covers everything and (hopefully) is
-- rarely used. There is a dataVersion number to
-- increment to trigger a call.
--
function CraftForge:FlushAllData()
	DA.DEBUG(0,"FlushAllData()");
	CraftForge.data = {}
	CraftForge.db.realm.tradeSkills = {}
	CraftForge.db.realm.auctionData = {}
	CraftForge.db.realm.inventoryData = {}
	CraftForge.db.realm.userIgnoredMats = {}
	CraftForge.db.realm.options = {}
	CraftForge.db.realm.toolData = {}
	CraftForge.db.realm.faction = {}
	CraftForge.db.realm.race = {}
	CraftForge.db.realm.class = {}
	CraftForge.db.realm.guid = {}
	CraftForge.db.global.server = {}
	CraftForge:FlushCustomData()
	CraftForge:FlushQueueData()
	CraftForge:FlushRecipeData()
	CraftForge:FlushDetailData()
	CraftForge:FlushPlayerData()
	CraftForge:InitializeMissingVendorItems()
end

--
-- Flush all data for the current player
--
function CraftForge:FlushPlayerData()
	DA.DEBUG(0,"FlushPlayerData()");
	local player = CraftForge:unitName("player")
	CraftForge.db.realm.tradeSkills[player] = {}
	CraftForge.db.realm.auctionData[player] = {}
	CraftForge.db.realm.inventoryData[player] = {}
	CraftForge.db.realm.userIgnoredMats[player] = {}
	CraftForge.db.realm.bagData[player] = {}
	CraftForge.db.realm.bagDetails[player] = {}
	CraftForge.db.realm.bankData[player] = {}
	CraftForge.db.realm.bankDetails[player] = {}
	CraftForge.db.realm.queueData[player] = {}
	CraftForge.db.realm.reagentsInQueue[player] = {}
	CraftForge.db.realm.modifiedInQueue[player] = {}
	CraftForge.db.realm.groupDB[player] = {}
	CraftForge.db.realm.options[player] = {}
	CraftForge.db.realm.toolData[player] = {}
	CraftForge.db.realm.faction[player] = {}
	CraftForge.db.realm.race[player] = {}
	CraftForge.db.realm.class[player] = {}
	CraftForge.db.realm.guid[player]= {}
end

--
-- Custom Groups data could represent significant
-- effort by the player so don't clear it without
-- good cause.
--
function CraftForge:FlushCustomData()
	DA.DEBUG(0,"FlushCustomData()");
	CraftForge.db.realm.groupDB = {}
	CraftForge.db.profile.groupSN = {}
end

--
-- Saved queues are in the profile so
-- clearing these tables is just the current
-- queue and should have minimal impact.
--
function CraftForge:FlushQueueData()
	DA.DEBUG(0,"FlushQueueData()");
	CraftForge.db.realm.queueData = {}
	CraftForge.db.realm.reagentsInQueue = {}
	CraftForge.db.realm.modifiedInQueue = {}
end

--
-- Recipe data is constantly getting rebuilt so
-- clearing it should have minimal (if any) impact.
-- Blizzard's "stealth" changes to recipes are the
-- primary reason this function exists.
--
function CraftForge:FlushRecipeData()
	DA.DEBUG(0,"FlushRecipeData()");
	CraftForge.db.global.recipeDB = {}
	CraftForge.db.global.recipeNameDB = {}
	CraftForge.db.global.itemRecipeUsedIn = {}
	CraftForge.db.global.itemRecipeSource = {}
	CraftForge.db.global.Categories = {}
	if CraftForge.data and CraftForge.data.recipeInfo then
		CraftForge.data.recipeInfo = {}
	CraftForge:InitializeSkillLevels()
	end
end

--
-- Detailed contents of the bags, bank, and guildbank
-- can take a lot of space so clearing these tables
-- can free that up.
--
function CraftForge:FlushDetailData()
	DA.DEBUG(0,"FlushDetailData()");
	CraftForge.db.realm.bagData = {}
	CraftForge.db.realm.bagDetails = {}
	CraftForge.db.realm.bankData = {}
	CraftForge.db.realm.bankDetails = {}
	CraftForge.db.global.warbandData = {}
	CraftForge.db.global.warbandDetails = {}
	CraftForge.db.global.detailedGuildbank = {}
end

--
-- MissingVendorItem entries can be a string when bought with gold
-- or a table when bought with an alternate currency
-- table entries are {name, quantity, currencyName, currencyID, currencyCount}
--
function CraftForge:InitializeMissingVendorItems()
	self.db.global.MissingVendorItems = {
		[30817] = "Simple Flour",
		[4539]  = "Goldenbark Apple",
		[17035] = "Stranglethorn Seed",
		[17034] = "Maple Seed",
		[4399]	= "Wooden Stock",
		[3857]	= "Coal",
		[52188] = "Jeweler's Setting",
		[38682] = "Enchanting Vellum",
	}
end

function CraftForge:InitializeDatabase(player)
	if self.linkedSkill or self.isGuild then  -- Avoid adding unnecessary data to savedvariables
		return
	end
	local clean = CraftForge.CleanDatabase
	local action = clean and "Clean" or "Initialize"
	DA.DEBUG(0,action.." database for "..tostring(player))
--
-- Session data
--
	if not self.data then
		self.data = {}
	end
	if not self.data.recipeInfo then
		self.data.recipeInfo = {}
	end
	if not self.data.recipeList then
		self.data.recipeList = {}
	end
	if not self.data.skillList then
		self.data.skillList = {}
	end
	if player and (not self.data.skillList[player] or clean) then
		self.data.skillList[player] = {}
	end
	if not self.data.groupList then
		self.data.groupList = {}
	end
	if player and (not self.data.groupList[player] or clean) then
		self.data.groupList[player] = {}
	end
	if not self.data.skillIndexLookup then
		self.data.skillIndexLookup = {}
	end
	if player and (not self.data.skillIndexLookup[player] or clean) then
		self.data.skillIndexLookup[player] = {}
	end
--
-- Realm data
--
	if player then
		if not self.db.realm.groupDB then
			self.db.realm.groupDB = {}
		end
		if not self.db.realm.options then
			self.db.realm.options = {}
		end
		if not self.db.realm.options[player] or clean then
			self.db.realm.options[player] = {}
		end
		if not self.db.realm.queueData then
			self.db.realm.queueData = {}
		end
		if not self.db.realm.queueData[player] or clean then
			self.db.realm.queueData[player] = {}
		end
		if not self.db.realm.toolData then
			self.db.realm.toolData = {}
		end
		if not self.db.realm.toolData[player] or clean then
			self.db.realm.toolData[player] = {}
		end
		if not self.db.realm.auctionData then
			self.db.realm.auctionData = {}
		end
		if not self.db.realm.auctionData[player] or clean then
			self.db.realm.auctionData[player] = {}
		end
		if not self.db.realm.tradeSkills then
			self.db.realm.tradeSkills = {}
		end
		if not self.db.realm.tradeSkills[player] or clean then
			self.db.realm.tradeSkills[player] = {}
		end
		if not self.db.realm.faction then
			self.db.realm.faction = {}
		end
		if not self.db.realm.race then
			self.db.realm.race = {}
		end
		if not self.db.realm.class then
			self.db.realm.class = {}
		end
		if not self.db.realm.guid then
			self.db.realm.guid = {}
		end
		if not self.db.global.faction then
			self.db.global.faction = {}
		end
		if not self.db.global.server then
			self.db.global.server = {}
		end
		if not self.db.realm.inventoryData then
			self.db.realm.inventoryData = {}
		end
		if not self.db.realm.inventoryData[player] or clean then
			self.db.realm.inventoryData[player] = {}
		end
		if not self.db.realm.bagData then
			self.db.realm.bagData = {}
		end
		if not self.db.realm.bagData[player] or clean then
			self.db.realm.bagData[player] = {}
		end
		if not self.db.realm.bagDetails then
			self.db.realm.bagDetails = {}
		end
		if not self.db.realm.bagDetails[player] or clean then
			self.db.realm.bagDetails[player] = {}
		end
		if not self.db.realm.bankData then
			self.db.realm.bankData = {}
		end
		if not self.db.realm.bankData[player] or clean then
			self.db.realm.bankData[player] = {}
		end
		if not self.db.realm.bankDetails then
			self.db.realm.bankDetails = {}
		end
		if not self.db.realm.bankDetails[player] or clean then
			self.db.realm.bankDetails[player] = {}
		end

		if not self.db.realm.reagentsInQueue then
			self.db.realm.reagentsInQueue = {}
		end
		if not self.db.realm.reagentsInQueue[player] or clean then
			self.db.realm.reagentsInQueue[player] = {}
		end
		if not self.db.realm.modifiedInQueue then
			self.db.realm.modifiedInQueue = {}
		end
		if not self.db.realm.modifiedInQueue[player] or clean then
			self.db.realm.modifiedInQueue[player] = {}
		end
		if not self.db.realm.userIgnoredMats then
			self.db.realm.userIgnoredMats = {}
		end
		if not self.db.realm.userIgnoredMats[player] or clean then
			self.db.realm.userIgnoredMats[player] = {}
		end
		if not self.db.profile.SavedQueues then
			self.db.profile.SavedQueues = {}
		end
		if not self.db.profile.plugins then
			self.db.profile.plugins = {}
		end
		if self.db.profile.plugins.recipeNamePlugin then
			if not self.db.profile.plugins.recipeNameSuffix then
				self.db.profile.plugins.recipeNameSuffix = self.db.profile.plugins.recipeNamePlugin
			end
			self.db.profile.plugins.recipeNamePlugin = nil
		end
		CraftForge:InitializePlugins()
	end
end

function CraftForge:RegisterRecipeFilter(name, namespace, initMethod, filterMethod)
	if not self.recipeFilters then
		self.recipeFilters = {}
	end
	--DA.DEBUG(0,"add recipe filter "..name)
	self.recipeFilters[name] = { namespace = namespace, initMethod = initMethod, filterMethod = filterMethod }
end

--
-- Called when the addon is enabled
--
function CraftForge:OnEnable()
	DA.DEBUG(0,"OnEnable()");
--
-- Hook into the events that we care about
--
-- Trade skill window changes
--
	self:RegisterEvent("TRADE_SKILL_CLOSE")
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_NAME_UPDATE")
	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
--	self:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGING")
	self:RegisterEvent("TRADE_SKILL_DETAILS_UPDATE")
--	self:RegisterEvent("TRADE_SKILL_FILTER_UPDATE")
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
--	self:RegisterEvent("GUILD_RECIPE_KNOWN_BY_MEMBERS", "CraftForgeShowGuildCrafters")
	self:RegisterEvent("GARRISON_TRADESKILL_NPC_CLOSED")
	self:RegisterEvent("BAG_UPDATE") 				-- Fires for both bag and bank updates.
	self:RegisterEvent("BAG_UPDATE_DELAYED")		-- Fires after all applicable BAG_UPDATE events for a specific action have been fired.
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")	-- BAG_UPDATE_DELAYED seems to have disappeared. Using this instead.

--
-- Events that replace *_SHOW and *_CLOSED by adding a PlayerInteractionType parameter
--
	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
	self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
	if self.InitializeProcessing then
		self:InitializeProcessing()
	end
--
-- MERCHANT_SHOW, MERCHANT_HIDE, MERCHANT_UPDATE events needed for auto buying.
--
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_UPDATE")
	self:RegisterEvent("MERCHANT_CLOSED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("PLAYER_MONEY")
--
-- To show a shopping list when at the bank/guildbank/auction house
--
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
--	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANK_UPDATE_TEXT")
	self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
--
-- Events needed to process the queue and to update
-- the tradeskill window to update the number of items
-- that can be crafted as we consume reagents.
--
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
--	self:RegisterEvent("UPDATE_TRADESKILL_CAST_COMPLETE")
--	self:RegisterEvent("UPDATE_TRADESKILL_RECAST")
	self:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
--
-- Events needed to handle caching of item info
--
	self:RegisterEvent("ITEM_COUNT_CHANGED")
	self:RegisterEvent("ITEM_DATA_LOAD_RESULT")
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
--
-- Not sure these are needed for crafting but they
-- are useful for debugging.
--
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
--	self:RegisterEvent("CHAT_MSG_SKILL")
	self:RegisterEvent("SKILL_LINES_CHANGED") -- replacement for CHAT_MSG_SKILL
	self:RegisterEvent("NEW_RECIPE_LEARNED") -- arg1 = recipeID

	if CraftForge.db.profile.BlizzOR then
--
-- Dump the data passed to C_TradeSkillUI functions so we can learn how Blizzard handles the new stuff
--
-- C_TradeSkillUI.CraftRecipe(recipeSpellID [, numCasts [, craftingReagents [, recipeLevel [, orderID [, applyConcentration]]]]])
--
		hooksecurefunc(C_TradeSkillUI,"CraftRecipe",function(...)
			local recipeSpellID, numCasts, craftingReagents, recipeLevel, orderID = ...
			DA.DEBUG(0, "C_TradeSkillUI.CraftRecipe: recipeSpellID= "..tostring(recipeSpellID)..", numCasts= "..tostring(numCasts)..", craftingReagents= "..DA.DUMP(craftingReagents)..", recipeLevel= "..tostring(recipeLevel)..", orderID= "..tostring(orderID))
		end)

--
-- C_TradeSkillUI.CraftSalvage(recipeSpellID, [numCasts], itemTarget [, craftingReagents [, applyConcentration]])
--
		hooksecurefunc(C_TradeSkillUI,"CraftSalvage",function(...)
			local recipeSpellID, numCasts, itemTarget = ...
			DA.DEBUG(0, "C_TradeSkillUI.CraftSalvage: recipeSpellID= "..tostring(recipeSpellID)..", numCasts= "..tostring(numCasts)..", itemTarget= "..DA.DUMP(itemTarget))
		end)

--
-- C_TradeSkillUI.CraftEnchant(recipeSpellID [, numCasts [, craftingReagents [, itemTarget [, applyConcentration]]]])
--
		hooksecurefunc(C_TradeSkillUI,"CraftEnchant",function(...)
			local recipeSpellID, numCasts, craftingReagents, itemTarget = ...
			DA.DEBUG(0, "C_TradeSkillUI.CraftEnchant: recipeSpellID= "..tostring(recipeSpellID)..", numCasts= "..tostring(numCasts)..", craftingReagents= "..DA.DUMP(craftingReagents)..", itemTarget= "..DA.DUMP(itemTarget))
		end)

--
-- result = C_TradeSkillUI.RecraftRecipe(itemGUID [, craftingReagents [, removedModifications [, applyConcentration]]])
--
		hooksecurefunc(C_TradeSkillUI,"RecraftRecipe",function(...)
			local itemGUID, craftingReagents = ...
			DA.DEBUG(0, "C_TradeSkillUI.RecraftRecipe: itemGUID= "..tostring(itemGUID)..", craftingReagents= "..DA.DUMP(craftingReagents))
		end)
	end
--
-- Debugging cleanup if enabled
--
	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	self.bagsChanged = true
	self.hideUncraftableRecipes = false
	self.hideTrivialRecipes = false
	self.currentTrade = nil
	self.selectedSkill = nil
	self.currentPlayer = CraftForge:unitName("player")
	self.currentGroupLabel = "Blizzard"
	self.currentGroup = nil
	self.dataScanned = false
	self.recipeDump = {}

--
-- run the upgrade code to convert any old settings
--
	self:UpgradeDataAndOptions()
	self:CollectTradeSkillData()
	self:CollectCurrencyData()
	self:EnablePlugins()
end

--
-- Called when the addon is disabled
--
function CraftForge:OnDisable()
	DA.DEBUG(0,"CraftForge:OnDisable()");
	self:UnregisterAllEvents()
	self:EnableBlizzardFrame()
end

function CraftForge:PLAYER_LOGIN()
	DA.TRACE("PLAYER_LOGIN")
end

function CraftForge:PLAYER_MONEY()
	DA.TRACE("PLAYER_MONEY")
end

function CraftForge:UI_ERROR_MESSAGE(event,errtype,text)
	DA.TRACE("UI_ERROR_MESSAGE( "..tostring(errtype)..", "..tostring(text).." )")
end

function CraftForge:PLAYER_ENTERING_WORLD()
	DA.TRACE("PLAYER_ENTERING_WORLD")
	local player = CraftForge:unitName("player")
	local realm = GetRealmName()
	local faction = UnitFactionGroup("player")
	local raceName, raceFile, raceID = UnitRace("player")
	local className, classFile, classId = UnitClass("player")
	local locale = GetLocale()
	local _,wowBuild,_,wowVersion = GetBuildInfo();
	local guid = UnitGUID("player")		-- example: guid="Player-970-0002FD64" kind=="Player" server=="970" ID="0002FD64"
--
-- PLAYER_ENTERING_WORLD happens on login and when changing zones so
-- only save the time of the first one.
--
	if not CraftForge.loginTime then
		CraftForge.loginTime = GetTime()
	end
--
-- Store some identifying data in the per character saved variables file
--
	CraftForgeWho.player = player
	CraftForgeWho.realm = realm
	CraftForgeWho.faction = faction
	CraftForgeWho.raceFile = raceFile
	CraftForgeWho.classFile = classFile
	self.db.realm.faction[player] = faction
	self.db.realm.race[player] = raceFile
	self.db.realm.class[player] = classFile
	CraftForgeWho.locale = locale
	CraftForgeWho.wowBuild = wowBuild
	CraftForgeWho.wowVersion = wowVersion
	CraftForgeWho.guid = guid
	CraftForgeWho.version = CraftForge.version
	if guid then
		local kind, server, ID = strsplit("-", guid)
		DA.DEBUG(1,"player="..tostring(player)..", faction="..tostring(faction)..", guid="..tostring(guid)..", server="..tostring(server))
--
-- If we support data sharing across connected realms, then
-- CraftForge.db.realm.* data needs to move to 
-- CraftForge.db.global.* data indexed by server.
--
		self.db.realm.guid[player]= guid
		if (server) then
			if not self.data then
				self.data = {}
			end
			self.data.server = server
			self.data.realm = realm
			if not self.db.global.server[server] then
				self.db.global.server[server] = {}
			end
			self.db.global.server[server][realm] = player

			if not self.db.global.customPrice[server] then
				self.db.global.customPrice[server] = {}
			end
			if not self.db.global.faction[server] then
				self.db.global.faction[server] = {}
			end
			self.db.global.faction[server][player] = faction
		end
	end
end

function CraftForge:ADDON_ACTION_BLOCKED()
	DA.TRACE("ADDON_ACTION_BLOCKED")
--	print("|cf0f00000CraftForge-Classic|r: Combat lockdown restriction." ..
--								  " Leave combat and try again.")
--	self:HideAllWindows()
end

function CraftForge:PLAYER_LOGOUT()
	DA.TRACE("PLAYER_LOGOUT")
--
-- Make a copy of the in memory data for debugging. Note: DeepCopy.lua needs to be added to the .toc
--
	if DA.deepcopy then
		self.data.sortedSkillList = {"Removed"} -- This table is huge so don't save it unless needed.
--		CraftForgeMemory = DA.deepcopy(self.data)	-- Everything else
--
-- For RecipeGroups debugging:
--
		local tradeID, rest
		for tradeID in pairs(self.db.realm.tradeSkills[self.currentPlayer]) do
			DA.DEBUG(0,"tradeID= "..tostring(tradeID))
			if self.data.groupList[self.currentPlayer][tradeID] then
				self.data.groupList[self.currentPlayer][tradeID]["Blizzard"] = {"Removed"}
			end
		end
		CraftForgeMemory = DA.deepcopy(self.data.groupList) -- minus all the group "Blizzard" stuff
	end
end

function CraftForge:CHAT_MSG_SKILL(event,text)	-- Replaced by SKILL_LINES_CHANGED
	DA.TRACE("CHAT_MSG_SKILL")
	if CraftForge.tradeSkillOpen then
--		CraftForge:RescanTrade()
--		CraftForge:UpdateTradeSkillWindow()
--		CraftForge.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_LIST_UPDATE
	end
end

function CraftForge:SKILL_LINES_CHANGED()
	DA.TRACE("SKILL_LINES_CHANGED")
	if CraftForge.tradeSkillOpen then
--		CraftForge:RescanTrade()
--		CraftForge:UpdateTradeSkillWindow()
		CraftForge.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_LIST_UPDATE
	end
end

function CraftForge:NEW_RECIPE_LEARNED(event, recipeID)
	DA.TRACE("NEW_RECIPE_LEARNED")
	DA.TRACE("recipeID= ", recipeID)
	if CraftForge.tradeSkillOpen then
		CraftForge.dataSourceChanged = true	-- Process the change on the next TRADE_SKILL_LIST_UPDATE
	end
end

function CraftForge:TRADE_SKILL_SHOW()
	DA.TRACE("TRADE_SKILL_SHOW")
	CraftForge.dataSourceChanged = false
	CraftForge.detailsUpdate = false
	CraftForge.skillListUpdate = false
	CraftForge.adjustInventory = false
	CraftForge:CraftForgeShow()
end

function CraftForge:TRADE_SKILL_CLOSE()
	DA.TRACE("TRADE_SKILL_CLOSE")
	CraftForge:CraftForgeClose()
	CraftForge.dataSourceChanged = false
	CraftForge.detailsUpdate = false
	CraftForge.skillListUpdate = false
	CraftForge.adjustInventory = false
end

function CraftForge:TRADE_SKILL_DATA_SOURCE_CHANGED()
	DA.TRACE("TRADE_SKILL_DATA_SOURCE_CHANGED")
	DA.TRACE("tradeSkillOpen= "..tostring(CraftForge.tradeSkillOpen))
	if CraftForge.tradeSkillOpen then
		CraftForge.dataSourceChanged = true
		CraftForge:CraftForgeShowWindow("CHANGED")
		if CraftForge.delaySelectedSkill then
			self:SetSelectedSkill(CraftForge.delaySkillIndex)
			CraftForge.delaySelectedSkill = false
		end
	end
end

function CraftForge:TRADE_SKILL_DATA_SOURCE_CHANGING()
	DA.TRACE("TRADE_SKILL_DATA_SOURCE_CHANGING")
	DA.TRACE("tradeSkillOpen= "..tostring(CraftForge.tradeSkillOpen))
	if CraftForge.tradeSkillOpen then
		CraftForge:CraftForgeShow()
	end
end

function CraftForge:TRADE_SKILL_DETAILS_UPDATE()
	DA.TRACE("TRADE_SKILL_DETAILS_UPDATE")
	DA.TRACE("tradeSkillOpen= "..tostring(CraftForge.tradeSkillOpen))
	if CraftForge.tradeSkillOpen then
		CraftForge.detailsUpdate = true
		CraftForge:RescanTrade()
		CraftForge:UpdateTradeSkillWindow()
	end
end

function CraftForge:TRADE_SKILL_FILTER_UPDATE()
	DA.TRACE("TRADE_SKILL_FILTER_UPDATE")
end

function CraftForge:TRADE_SKILL_LIST_UPDATE()
	DA.TRACE("TRADE_SKILL_LIST_UPDATE")
	--DA.TRACE("tradeSkillOpen= "..tostring(CraftForge.tradeSkillOpen))
	--DA.TRACE("dataSourceChanged= "..tostring(CraftForge.dataSourceChanged))
	--DA.TRACE("adjustInventory= "..tostring(CraftForge.adjustInventory))
	if CraftForge.tradeSkillOpen and CraftForge.dataSourceChanged then
		CraftForge.dataSourceChanged = false
		CraftForge.adjustInventory = false
		CraftForge.skillListUpdate = true
		CraftForge:CraftForgeShowWindow("UPDATE")
	end
	if CraftForge.tradeSkillOpen and CraftForge.adjustInventory then
		CraftForge.skillListUpdate = true
		CraftForge:AdjustInventory()
	end
end

function CraftForge:TRADE_SKILL_NAME_UPDATE()
	DA.TRACE("TRADE_SKILL_NAME_UPDATE")
	DA.TRACE("linkedSkill= "..tostring(CraftForge.linkedSkill))
	if CraftForge.linkedSkill then
		CraftForge:CraftForgeShow()
	end
end

function CraftForge:GARRISON_TRADESKILL_NPC_CLOSED()
	DA.TRACE("GARRISON_TRADESKILL_NPC_CLOSED")
end

function CraftForge:ITEM_DATA_LOAD_RESULT(event, itemID, result)
	if itemID then
		local name = C_Item.GetItemInfo(itemID)
		DA.TRACE3("ITEM_DATA_LOAD_RESULT(", itemID, result, "), "..tostring(name))
	else
		DA.TRACE3("ITEM_DATA_LOAD_RESULT")
	end
	if CraftForge.salvageDataNeeded then
		CraftForge:UpdateSalvageListWindow()
		CraftForge.salvageDataNeeded = nil
	end
	if CraftForge.finishingDataNeeded then
		CraftForge:UpdateFinishingListWindow()
		CraftForge.finishingDataNeeded = nil
	end
	if CraftForge.optionalDataNeeded then
		CraftForge:UpdateOptionalListWindow()
		CraftForge.optionalDataNeeded = nil
	end
	if CraftForge.modifiedDataNeeded then
		CraftForge:UpdateModifiedListWindow()
		CraftForge.modifiedDataNeeded = nil
	end
	if CraftForge.detailDataNeeded then
		if not CraftForge.InProgress.detail then
			CraftForge:UpdateDetailWindow(self.selectedSkill)
		end
		CraftForge.detailDataNeeded = nil
	end
end

function CraftForge:GET_ITEM_INFO_RECEIVED(event, itemID, result)
	if itemID then
		local name = C_Item.GetItemInfo(itemID)
		DA.TRACE3("GET_ITEM_INFO_RECEIVED(", itemID, result, "), "..tostring(name))
	else
		DA.TRACE3("GET_ITEM_INFO_RECEIVED")
	end
end

--
-- Dragonflight replacement for *_SHOW events
--
function CraftForge:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(event,interactionType)
	DA.TRACE("PLAYER_INTERACTION_MANAGER_FRAME_SHOW(", interactionType, ")")
	if interactionType == Enum.PlayerInteractionType.Merchant then -- 5
--		CraftForge:CraftForge:MERCHANT_SHOW()
		CraftForge:MerchantShow()
	end
	if interactionType == Enum.PlayerInteractionType.Banker then -- 8
		CraftForge:BANKFRAME_OPENED()
	end
	if interactionType == Enum.PlayerInteractionType.GuildBanker then -- 10
		CraftForge:GUILDBANKFRAME_OPENED()
	end
	if interactionType == Enum.PlayerInteractionType.Auctioneer then -- 21
		CraftForge:AUCTION_HOUSE_SHOW()
	end
end

--
-- Dragonflight replacement for *_CLOSED events
--
function CraftForge:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(event,interactionType)
	DA.TRACE("PLAYER_INTERACTION_MANAGER_FRAME_HIDE(", interactionType, ")")
	if interactionType == Enum.PlayerInteractionType.Merchant then -- 5
--		CraftForge:MERCHANT_CLOSED()
	end
	if interactionType == Enum.PlayerInteractionType.Banker then -- 8
		CraftForge:BANKFRAME_CLOSED()
	end
	if interactionType == Enum.PlayerInteractionType.GuildBanker then -- 10
		CraftForge:GUILDBANKFRAME_CLOSED()
	end
	if interactionType == Enum.PlayerInteractionType.Auctioneer then -- 21
		CraftForge:AUCTION_HOUSE_CLOSED()
	end
end

function CraftForge:IsTradeSkillLinked()
	local isGuild = C_TradeSkillUI.IsTradeSkillGuild()
	local isLinked, linkedPlayer = C_TradeSkillUI.IsTradeSkillLinked()
	DA.DEBUG(0,"IsTradeSkillLinked: isGuild="..tostring(isGuild)..", isLinked="..tostring(isLinked)..", linkedPlayer="..tostring(linkedPlayer))
	if isLinked or isGuild then
		if not linkedPlayer then
			if isGuild then
				linkedPlayer = "Guild Recipes" -- This can be removed when InitializeDatabase gets smarter.
			end
		end
		return true, linkedPlayer, isGuild
	end
	return false, nil, false
end

--
-- Allow modifier keys that change initial frame behavior to be disabled.
-- Modifier keys within the CraftForge frame are not effected.
-- Type "/craftforge nomodkeys" to toggle.
--
-- Make modifier key to open Blizzard frame optional.
--
function CraftForge:IsModKey1Down()
	if not CraftForge.db.profile.nomodkeys and IsShiftKeyDown() then
		return true
	end
	return false
end

--
-- Make modifier key to alter some behaviors optional.
--
function CraftForge:IsModKey2Down()
	if not CraftForge.db.profile.nomodkeys and IsControlKeyDown() then
		return true
	end
	return false
end

--
-- Make modifier key to alter some behaviors optional.
--
function CraftForge:IsModKey3Down()
	if not CraftForge.db.profile.nomodkeys and IsAltKeyDown() then
		return true
	end
	return false
end

--
-- Checks to see if the current trade is one that we support.
-- Control key says we do (even if we don't, debugging)
-- Shift key says we don't support it (even if we do)
-- Shift key behavior can be swapped with "/craftforge swapshiftkey"
--
function CraftForge:IsSupportedTradeskill(tradeID)
	DA.DEBUG(0,"IsSupportedTradeskill("..tostring(tradeID)..")")
	if self:IsModKey2Down() then
		return true
	end
	if self:IsModKey1Down() then
		return CraftForge.db.profile.swapshiftkey
	end
	if not tradeID or self.BlizzardSkillList[tradeID] or self.currentPlayer ~= CraftForge:unitName("player") then
		DA.DEBUG(3,"IsSupportedTradeskill: BlizzardSkillList="..tostring(self.BlizzardSkillList[tradeID]))
		return false
	end
	local ranks = self:GetSkillRanks(self.currentPlayer, tradeID)
	if not ranks then
		DA.DEBUG(3,"IsSupportedTradeskill: not ranks")
		return false
	end
	return not CraftForge.db.profile.swapshiftkey
end

--
-- Checks to see if this trade follower can not use CraftForge frame.
--
function CraftForge:IsNotSupportedFollower(tradeID)
	--DA.DEBUG(0,"IsNotSupportedFollower("..tostring(tradeID)..")")
	CraftForge.wasNPCCrafting = false
	if self:IsModKey1Down() and self:IsModKey3Down() then
		CraftForge.wasNPCCrafting = true
		DA.DEBUG(3,"IsNotSupportedFollower: ShiftKey and AltKey down")
		return true -- Use Blizzard frame
	end
	if not tradeID then
		DA.DEBUG(3,"IsNotSupportedFollower: not tradeID")
		return true -- Unknown tradeskill, play it safe and use Blizzard frame
	end
	if C_TradeSkillUI.IsNPCCrafting() and CraftForge.FollowerSkillList[tradeID] then
		DA.DEBUG(3,"IsNotSupportedFollower: IsNPCCrafting and FollowerSkillList")
		CraftForge.wasNPCCrafting = true
		return true -- Any NPC for this tradeskill uses Blizzard Frame
	end
	local guid = UnitGUID("target")
	if guid and canaccessvalue(guid) then -- issecretvalue(foo) == not canaccessvalue(foo)
		local gtype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-",guid);
		DA.DEBUG(3,"IsNotSupportedFollower: IsNPCCrafting="..tostring(C_TradeSkillUI.IsNPCCrafting())..", gtype="..tostring(gtype)..", npc_id="..tostring(npc_id))
		if self:IsModKey2Down() and self:IsModKey3Down() then
			DA.DEBUG(3,"IsNotSupportedFollower: CtrlKey and AltKey down")
			CraftForge.wasNPCCrafting = true
			return false -- Use CraftForge frame (mostly for debugging)
		end
		if gtype and gtype == "Creature" and CraftForge.FollowerNPC[npc_id] then
			CraftForge.wasNPCCrafting = true
			return true -- This specific NPC crafts things CraftForge can't process, use Blizzard frame
		end
		if C_TradeSkillUI.IsNPCCrafting() and CraftForge.db.profile.use_blizzard_for_followers then
			CraftForge.wasNPCCrafting = true
			return true -- Option makes this easy, use Blizzard frame
		end
	end
	return false -- Use CraftForge frame
end

--
-- Internet documentation says:
--   prof1, prof2, archaeology, fishing, cooking, firstAid, prof7 = GetProfessions()
--
-- Forever returns something "dynamically" different
--
BINDING_NAME_CRAFTFORGEPROFESSION1 = L["Profession"].." 1"
BINDING_NAME_CRAFTFORGEPROFESSION2 = L["Profession"].." 2"
BINDING_NAME_CRAFTFORGEPROFESSION3 = L["Profession"].." 3"
BINDING_NAME_CRAFTFORGEPROFESSION4 = L["Profession"].." 4"
BINDING_NAME_CRAFTFORGEPROFESSION5 = L["Profession"].." 5"
BINDING_NAME_CRAFTFORGEPROFESSION6 = L["Profession"].." 6"
BINDING_NAME_CRAFTFORGEPROFESSION7 = L["Profession"].." 7"

local function ChangeBindings(i, name)
	DA.DEBUG(0,"ChangeBindings("..tostring(i)..", "..tostring(name)..")")
	if i == 1 then
		BINDING_NAME_CRAFTFORGEPROFESSION1 = name
	end
	if i == 2 then
		BINDING_NAME_CRAFTFORGEPROFESSION2 = name
	end
	if i == 3 then
		BINDING_NAME_CRAFTFORGEPROFESSION3 = name
	end
	if i == 4 then
		BINDING_NAME_CRAFTFORGEPROFESSION4 = name
	end
	if i == 5 then
		BINDING_NAME_CRAFTFORGEPROFESSION5 = name
	end
	if i == 6 then
		BINDING_NAME_CRAFTFORGEPROFESSION6 = name
	end
	if i == 7 then
		BINDING_NAME_CRAFTFORGEPROFESSION7 = name
	end
end

--
-- called from keybindings in Bindings.xml
--
function CraftForge:ShowProfession(whichone)
	local tradeName, tradeID
	DA.DEBUG(0,"ShowProfession("..tostring(whichone)..")")
	--DA.MARK3("ShowProfession("..tostring(whichone)..")")
	local prof1, prof2, prof3, prof4, prof5, prof6, prof7 = GetProfessions()
	for i, profIndex in ipairs({prof1, prof2, prof3, prof4, prof5, prof6, prof7}) do
		if profIndex then
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset,
			skillLine, skillModifier, specializationIndex,
			specializationOffset = GetProfessionInfo(profIndex)
			DA.DEBUG(1,"ShowProfession: i= "..tostring(i)..", index= "..tostring(profIndex)..", name= "..tostring(name))
			--DA.MARK3("ShowProfession: i= "..tostring(i)..", index= "..tostring(profIndex)..", name= "..tostring(name))
			ChangeBindings(i, name)
			if i == whichone then tradeName = name end
		end
	end
	if tradeName then
		DA.DEBUG(1,"ShowProfession: executing CastSpellByName("..tostring(tradeName)..")")
		--DA.MARK3("ShowProfession: executing CastSpellByName("..tostring(tradeName)..")")
		CastSpellByName(tradeName)
	end
end

--
-- Show the tradeskill window, called from TRADE_SKILL_SHOW event, clicking on links, or clicking on guild professions
--
function CraftForge:CraftForgeShow()
	DA.DEBUG(0,"CraftForgeShow: (was showing "..tostring(self.currentTrade)..")");
	local linkedPlayer
	self.linkedSkill, linkedPlayer, self.isGuild = self:IsTradeSkillLinked()
	StaticPopup_Hide("CRAFTFORGE_MANUAL_CHANGE")
	if self.linkedSkill or self.isGuild then
		return
	end
	self.currentPlayer = CraftForge:unitName("player")
	local frame = self.tradeSkillFrame
	if not frame then
		frame = self:CreateTradeSkillWindow()
		self.tradeSkillFrame = frame
		tinsert(UISpecialFrames, frame:GetName())
	end
	self:ScanPlayerTradeSkills(self.currentPlayer)
	local baseinfo = C_TradeSkillUI.GetBaseProfessionInfo()
	--DA.DEBUG(3,"CraftForgeShow: GetBaseProfessionInfo info= "..DA.DUMP1(baseinfo))
	local childinfo = C_TradeSkillUI.GetChildProfessionInfos()
	--DA.DEBUG(3,"CraftForgeShow: GetChildProfessionInfos info= "..DA.DUMP(childinfo))

	self.currentTrade = self.tradeSkillIDsByName[baseinfo.professionName]	-- names are localized so use a table to translate

	DA.DEBUG(0,"CraftForgeShow: trade= "..tostring(self.currentTrade))
	local link = C_TradeSkillUI.GetTradeSkillListLink()
	if not link then
		DA.DEBUG(0,"CraftForgeShow: "..tostring(skillLineName).." not linkable")
	end
	if TSM_API and TSM_API.IsUIVisible("CRAFTING") and CraftForge.db.profile.tsm_prefer then
--
-- Use the TradeSkillMaster UI 
--
		DA.DEBUG(3,"CraftForgeShow: "..tostring(self.currentTrade).." TSM Preferred")
		self:HideAllWindows()
--		self:EnableBlizzardFrame()
--		ShowUIPanel(ProfessionsFrame)
		CraftForge.BlizzardUIshowing = true
	elseif self:IsNotSupportedFollower(self.currentTrade) or CraftForge.db.profile.tsm_prefer then
--
-- Use the Blizzard UI for any garrison follower that can't use ours
--
		DA.DEBUG(3,"CraftForgeShow: "..tostring(self.currentTrade).." IsNotSupportedFollower")
		self:HideAllWindows()
		self:EnableBlizzardFrame()
	elseif self:IsSupportedTradeskill(self.currentTrade) then
		DA.DEBUG(3,"CraftForgeShow: "..tostring(self.currentTrade).." IsSupportedTradeskill")
		self:DisableBlizzardFrame()
		self.tradeSkillOpen = true
		self.selectedSkill = nil
		self.dataScanned = false
		self:SetTradeSkillLearned()
		DA.DEBUG(3,"CraftForgeShow: waiting for TRADE_SKILL_DATA_SOURCE_CHANGED")
--		self:CraftForgeShowWindow() -- Need to wait until TRADE_SKILL_DATA_SOURCE_CHANGED
	else
		DA.DEBUG(3,"CraftForgeShow: "..tostring(self.currentTrade).." not IsSupportedTradeskill")
		self:HideAllWindows()
		self:EnableBlizzardFrame()
	end
end

--
-- Called from events TRADE_SKILL_DATA_SOURCE_CHANGED and TRADE_SKILL_LIST_UPDATE
--
function CraftForge:CraftForgeShowWindow(where)
	DA.DEBUG(0,"CraftForgeShowWindow("..tostring(where).."), "..tostring(self.currentTrade))
	if not CraftForge.db.profile.tsm_compat then
		if TSM_API and where == "CHANGED" then
			if TSM_API.IsUIVisible("CRAFTING") then
				if not CraftForge.db.profile.tsm_prefer then
					DA.MARK3(L["TradeSkillMaster must be in 'WOW UI' mode to use CraftForge"])
				end
				return
			end
		end
	end
	if self.tradeSkillOpen then
		self:DisableBlizzardFrame()
	end
	if not self:RescanTrade() then
		if self.useBlizzard then
			self.useBlizzard = false
			return
		end
		DA.DEBUG(0,"No headers, reset filter")
		self.ResetTradeSkillFilter()
		if not self:RescanTrade() then
			if TSM_API then
				DA.MARK3(L["Conflict with the addon TradeSkillMaster"])
				self.db.profile.TSM_API = true
			else
				DA.MARK3(L["No headers, try again"])
			end
			return
		end
	end
	self.currentGroup = nil
	self.currentGroupLabel = self:GetTradeSkillOption("grouping")
	self:RecipeGroupDropdown_OnShow()
	self:ShowTradeSkillWindow()
	local searchbox = _G["CraftForgeSearchBox"]
	local oldtext = searchbox:GetText()
	local searchText = self:GetTradeSkillOption("searchtext")
--
-- if the text is changed, set the new text (which fires off an update) otherwise just do the update
--
	if searchText ~= oldtext then
		searchbox:SetText(searchText)
	end
end

function CraftForge:CraftForgeClose()
	DA.DEBUG(0,"CraftForgeClose()")
	self.tradeSkillOpen = false
	self:HideAllWindows()
	if self.isForever and self.db.profile.scale_blizzard_frame and ProfessionsFrame then
		ProfessionsFrame:SetScale(1.0)	-- Just to make sure
	end
	if CraftForge.wasNPCCrafting then
		DA.DEBUG(0,"wasNPCCrafting")
		CraftForge.wasNPCCrafting = false
		C_Garrison.CloseGarrisonTradeskillNPC()
		C_Garrison.CloseTradeskillCrafter()
	end
end

-- Rescans the trades (and thus bags). Can only be called if the tradeskill window is open and a trade selected.
function CraftForge:RescanBags()
	DA.DEBUG(0,"RescanBags()")
	local start = GetTime()
	CraftForge:InventoryScan()
	CraftForge:UpdateTradeSkillWindow()
	local elapsed = GetTime() - start
	if elapsed > 0.5 then
		DA.DEBUG(0,"WARNING: craftforge inventory scan took " .. math.floor(elapsed*100+.5)/100 .. " seconds to complete.")
	end
end

--
-- Trade window close, the counts may need to be updated.
-- This could be because an enchant has used up mats or the player
-- may have received more mats.
--
function CraftForge:TRADE_CLOSED()
	self:BAG_UPDATE("FAKE_BAG_UPDATE", 0)
end

--
-- Make sure profession changes are spaced out
--   delayChange is set when ChangeTradeSkill is called
--     and cleared here when the timer expires.
--
function CraftForge:DelayChange()
	DA.DEBUG(0,"DelayChange()")
	CraftForge.delayChange = false
	if CraftForge.delayNeeded then
		CraftForge.delayNeeded = false
		CraftForge:ChangeTradeSkill(CraftForge.delayTrade, CraftForge.changingName)
	end
end

--
-- Change to a different profession but
-- not more often than once every .5 seconds
-- If called too quickly, delayNeeded is set and
--   the change is deferred until DelayChange is called.
--
-- This triggers the whole rescan process via a TRADE_SKILL_SHOW event
--
function CraftForge:ChangeTradeSkill(tradeID, tradeName)
	DA.DEBUG(0,"ChangeTradeSkill("..tostring(tradeID)..", "..tostring(tradeName)..")")
	local byName = true
	if not self.delayChange then
		if self.db.profile.dialog_switch and not self.dialogSwitch then
			self:HideAllWindows()
			C_TradeSkillUI.CloseTradeSkill()
			self.changingTrade = tradeID
			self.changingName = self.tradeSkillNamesByID[tradeID]
			self.dialogSwitch = true
			if self.isRetail and tradeName == "Mining" then tradeName = "Mining Journal" end
			DA.DEBUG(0,"ChangeTradeSkill: changingTrade= "..tostring(self.changingTrade)..", changingName= "..tostring(self.changingName))
			StaticPopup_Show("CRAFTFORGE_MANUAL_CHANGE", self.changingName)
		else
			if self.isRetail and tradeName == "Mining" then tradeName = "Mining Journal" end
			if CraftForge.isForever then
				if tradeID == 2366 then
					tradeID = 1278062		-- herbalism skills (Gardening)
					byName = false
				elseif tradeID == 7620 then
					tradeID = 1278067		-- fishing skills (Bait and Tackle)
					byName = false
				elseif tradeID == 8613 then
					tradeID = 1278068		-- skinning skills (Tanning)
					byName = false
				end
			end
			if byName then
				DA.DEBUG(1,"ChangeTradeSkill: executing CastSpellByName("..tostring(tradeName)..")")
				CastSpellByName(tradeName)
			else
				DA.DEBUG(1,"ChangeTradeSkill: executing CastSpellByID("..tostring(tradeID)..")")
				CastSpellByID(tradeID)
			end
			self.delayTrade = tradeID
			self.delayName = tradeName
			self.delayChange = true
			self.dialogSwitch = false
			CraftForge:ScheduleTimer("DelayChange", 0.5)
		end
	else
		DA.DEBUG(1,"ChangeTradeSkill: waiting for callback")
		CraftForge.delayNeeded = true
	end
end

--
-- Called from the static popups to change professions
--   changingTrade and changingName should be set to
--   the target profession.
--
function CraftForge:ContinueChange(manual)
	DA.DEBUG(0,"ContinueChange("..tostring(manual)..")")
	DA.DEBUG(1,"ContinueChange: changingTrade= "..tostring(self.changingTrade)..", changingName= "..tostring(self.changingName))
	if not manual then
		self.currentTrade = CraftForge.changingTrade
		CraftForge:ChangeTradeSkill(CraftForge.changingTrade, CraftForge.changingName)
	end
end

--
-- Called from the static popup when hidden or canceled
--
function CraftForge:FinishChange()
	DA.DEBUG(0,"FinishChange()")
	self.changingTrade = nil
	self.changingName = nil
	self.dialogSwitch = nil
end

--
-- Either change to a different profession or change the currently selected recipe
--
function CraftForge:SetTradeSkill(player, tradeID, skillIndex)
	DA.DEBUG(0,"SetTradeSkill("..tostring(player)..", "..tostring(tradeID)..", "..tostring(skillIndex)..")")
	if not self.db.realm.queueData[player] then
		self.db.realm.queueData[player] = {}
	end
	if tradeID ~= self.currentTrade then
		local oldTradeID = self.currentTrade
		local tradeName = self:GetTradeName(tradeID)
		self.currentPlayer = player
		self.currentTrade = nil
		self.selectedSkill = nil
		self.currentGroup = nil
		self:ChangeTradeSkill(tradeID, tradeName)
		self.delaySelectedSkill = true
		self.delaySkillIndex = skillIndex
		self.dataScanned = false
	end
	if not self.delaySelectedSkill then
		self:SetSelectedSkill(skillIndex)
	end
end

--
-- Shows the trade skill frame.
--
function CraftForge:ShowTradeSkillWindow()
	DA.DEBUG(0,"ShowTradeSkillWindow()")
	if UnitAffectingCombat("player") then
		print("|cff8888ffCraftForge|r: Combat lockdown restriction." ..
		  " Leave combat and try again.")
		self.dataSourceChanged = false
		self.detailsUpdate = false
		self.skillListUpdate = false
		self.adjustInventory = false
		self:CraftForgeClose()
		return
	end
	local frame = self.tradeSkillFrame
	if not frame then
		frame = self:CreateTradeSkillWindow()
		self.tradeSkillFrame = frame
		tinsert(UISpecialFrames, frame:GetName())
	end
	self:ResetTradeSkillWindow()
	self:ShowFullView()
	if not frame:IsVisible() then
		frame:Show()
		self:UpdateTradeSkillWindow()
	else
		self:UpdateTradeSkillWindow()
	end
--[[
	if self.db.profile.select_top_recipe then
		if CraftForgeScrollButton1.skill.skillIndex then
			DA.DEBUG(1,"ShowTradeSkillWindow: Selecting First Recipe")
			self:SetSelectedSkill(CraftForgeScrollButton1.skill.skillIndex)
		else
			DA.DEBUG(1,"ShowTradeSkillWindow: Selecting Second Recipe")
			self:SetSelectedSkill(CraftForgeScrollButton2.skill.skillIndex)
		end
	end
--]]
	DA.DEBUG(0,"ShowTradeSkillWindow complete")
end

--
-- Hides the CraftForge trade skill window. Does nothing if the window is not visible
--
function CraftForge:HideTradeSkillWindow()
	--DA.DEBUG(0,"HideTradeSkillWindow()")
	local closed -- was anything closed by us?
	local frame = self.tradeSkillFrame
	if frame and frame:IsVisible() then
		frame:Hide()
		closed = true
	end
	return closed
end

--
-- Hides any and all CraftForge windows that are open
--
function CraftForge:HideAllWindows()
	DA.DEBUG(0,"HideAllWindows()")
	local closed -- was anything closed?
	if self:HideTradeSkillWindow() then
		closed = true
	end
	if self:HideNotesWindow() then
		closed = true
	end
	if self:HideShoppingList() then
		closed = true
	end
	if self:HideStandaloneQueue() then
		closed = true
	end
	if self:HideIgnoreList() then
		closed = true
	end
	if self:HideOptionalList() then
		closed = true
	end
	if self:HideModifiedList() then
		closed = true
	end
	if self:HideSalvageList() then
		closed = true
	end
	if self:HideFinishingList() then
		closed = true
	end
	self.currentTrade = nil
	self.selectedSkill = nil
	DA.DEBUG(0,"End of HideAllWindows()")
	return closed
end

--
-- Notes when a new trade has been selected
--
function CraftForge:SetSelectedTrade(newTrade)
	DA.DEBUG(0,"SetSelectedTrade("..tostring(newTrade)..")")
	self.currentTrade = newTrade;
	self:SetSelectedSkill(nil)
end

--
-- Sets the specific trade skill that the user wants to see details on.
--
function CraftForge:SetSelectedSkill(skillIndex)
	--DA.DEBUG(0,"SetSelectedSkill("..tostring(skillIndex)..")")
	if skillIndex then
		self:HideNotesWindow()
		self:ConfigureRecipeControls(false)
		if CraftForge.BlizzardUIshowing or CraftForge.isForever then
			local skill = self:GetSkill(self.currentPlayer, self.currentTrade, skillIndex)
			if skill and ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.RecipeList then
				local recipeInfo = C_TradeSkillUI.GetRecipeInfo(skill.id)
				if recipeInfo then
					EventRegistry:TriggerEvent("ProfessionsRecipeListMixin.Event.OnRecipeSelected", recipeInfo, ProfessionsFrame.CraftingPage.RecipeList)
					ProfessionsFrame.CraftingPage.RecipeList:SelectRecipe(recipeInfo, true)
				end
			end
		end
		self.selectedSkill = skillIndex
		self:ScrollToSkillIndex(skillIndex)
		self:UpdateDetailWindow(skillIndex)
		self:ClickSkillButton(skillIndex)
	end
end

--
-- Updates the text we filter the list of recipes against.
--
function CraftForge:UpdateSearch(text)
	DA.DEBUG(0,"UpdateSearch("..tostring(text)..")")
	self:SetTradeSkillOption("searchtext", text)
	self:SortAndFilterRecipes()
	self:UpdateTradeSkillWindow()
end

--
-- Gets the note associated with the item, if there is such a note.
-- If there is no user supplied note, then return nil
-- The item can be either a recipe or reagent name
--
function CraftForge:GetItemNote(key)
	--DA.DEBUG(0,"GetItemNote("..tostring(key)..")")
	local result
	if not self.db.realm.notes[self.currentPlayer] then
		return
	end
	local kind, id = string.split(":", key)
	id = tonumber(id) or 0
	if kind == "enchant" then 					-- get the note by the itemID, not the recipeID
		if self.data.recipeList[id] then
			id = self.data.recipeList[id].itemID or 0
		end
	end
	--DA.DEBUG(0,"GetItemNote itemID="..tostring(id))
	if id then
		result = self.db.realm.notes[self.currentPlayer][id]
	else
		DA.MARK2("Error: CraftForge:GetItemNote() could not determine item ID for " .. key);
	end
	if result and result == "" then
		result = nil
		self.db.realm.notes[self.currentPlayer][id] = nil
	end
	return result
end

--
-- Sets the note for the specified object, if there is already a note
-- then it is overwritten
--
function CraftForge:SetItemNote(key, note)
	--DA.DEBUG(0,"SetItemNote("..tostring(key)..", "..tostring(note)..")")
	local kind, id = string.split(":", key)
	id = tonumber(id) or 0
	if kind == "enchant" then 					-- store the note by the itemID, not the recipeID
		if self.data.recipeList[id] then
			id = self.data.recipeList[id].itemID or 0
		end
	end
	--DA.DEBUG(0,"SetItemNote itemID="..tostring(id))
	if not self.db.realm.notes[self.currentPlayer] then
		self.db.realm.notes[self.currentPlayer] = {}
	end
	if id then
		self.db.realm.notes[self.currentPlayer][id] = note
	else
		DA.MARK2("Error: CraftForge:SetItemNote() could not determine item ID for " .. key);
	end
end

--
-- Adds the craftforge notes text to the tooltip for a specified
-- item.
-- Returns true if tooltip modified.
--
function CraftForge:AddItemNotesToTooltip(tooltip)
	--DA.DEBUG(0,"AddItemNotesToTooltip()")
	if IsControlKeyDown() then
		return
	end
	local notes_enabled = self.db.profile.show_item_notes_tooltip or false
	local crafters_enabled = self.db.profile.show_crafters_tooltip or false
	if not notes_enabled and not crafters_enabled then
		return -- nothing to be added to the tooltip
	end
--
-- get item name
--
	local name,link = tooltip:GetItem();
	if not link then
		--DA.DEBUG(0,"Error: AddItemNotesToTooltip() could not determine link")
		return;
	end
	local id = self:GetItemIDFromLink(link)
	if not id then
		--DA.DEBUG(0,"Error: AddItemNotesToTooltip() could not determine id from "..DA.PLINK(link))
		return
	end
	--DA.DEBUG(0,"link= "..tostring(link)..", id= "..tostring(id)..", notes= "..tostring(notes_enabled)..", crafters= "..tostring(crafters_enabled))
	local header_added = false
	if notes_enabled then
		for player,notes_table in pairs(self.db.realm.notes) do
			local note = notes_table[id]
			--DA.DEBUG(1,"player= "..tostring(player)..", table= "..DA.DUMP1(notes_table)..", note= '"..tostring(note).."'")
			if note then
				if not header_added then
					tooltip:AddLine("CraftForge " .. L["Notes"] .. ":")
					header_added = true
				end
				if player ~= CraftForge:unitName("player") then
					note = GRAY_FONT_COLOR_CODE .. player .. ": " .. FONT_COLOR_CODE_CLOSE .. note
				end
				tooltip:AddLine(" " .. note, 1, 1, 1, true) -- r,g,b, wrap
			end
		end
		if self:VendorSellsReagent(id) then
			if not header_added then
				tooltip:AddLine("CraftForge " .. L["Notes"] .. ":")
				header_added = true
			end
			tooltip:AddLine(" Buyable")
		end
	end	-- notes_enabled
	if crafters_enabled then
		if self.db.global.itemRecipeSource[id] then
			if not header_added then
				tooltip:AddLine("CraftForge " .. L["Notes"] .. ":")
				header_added = true
			end
			tooltip:AddLine(" Craftable")
			for recipeID in pairs(self.db.global.itemRecipeSource[id]) do
				local recipe = self:GetRecipe(recipeID)
				tooltip:AddDoubleLine(" Source: ",(self:GetTradeName(recipe.tradeID) or recipe.tradeID)..":"..self:GetRecipeName(recipeID),0,1,0,1,1,1)
				local lookupTable = self.data.skillIndexLookup
				local player = self.currentPlayer
				if lookupTable[recipeID] then
					local rankData = self:GetSkillRanks(player, recipe.tradeID)
					if rankData then
						local rank, maxRank = rankData.rank, rankData.maxRank
						tooltip:AddDoubleLine("  "..player,"["..(rank or "?").."/"..(maxRank or "?").."]",1,1,1)
					else
						tooltip:AddDoubleLine("  "..player,"[???/???]",1,1,1)
					end
				end
			end
		end
		if self.db.realm.reagentsInQueue[self.currentPlayer] then
			local inQueue = self.db.realm.reagentsInQueue[self.currentPlayer][id]
			if inQueue then
				if not header_added then
					tooltip:AddLine("CraftForge " .. L["Notes"] .. ":")
					header_added = true
				end
				if inQueue < 0 then
					tooltip:AddDoubleLine(" Used in queued skills:",-inQueue,1,1,1)
				else
					tooltip:AddDoubleLine(" Created from queued skills:",inQueue,1,1,1)
				end
			end
		end
	end	-- crafters_enabled
	return header_added
end

function CraftForge:ToggleTradeSkillOption(option)
	--DA.DEBUG(0,"ToggleTradeSkillOption("..tostring(option)..")")
	local v = self:GetTradeSkillOption(option)
	self:SetTradeSkillOption(option, not v)
end

--
-- Returns the state of a craft specific option
--
function CraftForge:GetTradeSkillOption(option)
	local r
	local player = self.currentPlayer
	local trade = self.currentTrade
	local options = self.db.realm.options
	if not options or not player or not options[player] or not trade or not options[player][trade] then
		r = CraftForge.defaultOptions[option]
	elseif options[player][trade][option] == nil then
		r =  CraftForge.defaultOptions[option]
	else
		r = options[player][trade][option]
	end
	--DA.DEBUG(0,"GetTradeSkillOption("..tostring(option)..") value= "..tostring(r))
	return r
end

--
-- sets the state of a craft specific option
--
function CraftForge:SetTradeSkillOption(option, value)
	--DA.DEBUG(0,"SetTradeSkillOption("..tostring(option)..", "..tostring(value)..")")
	if not self.linkedSkill and not self.isGuild then
		local player = self.currentPlayer
		local trade = self.currentTrade
		if not self.db.realm.options then
			self.db.realm.options = {}
		end
		if player and trade then
			if not self.db.realm.options[player] then
				self.db.realm.options[player] = {}
			end
			if not self.db.realm.options[player][trade] then
				self.db.realm.options[player][trade] = {}
			end
			self.db.realm.options[player][trade][option] = value
		end
	end
end

function CraftForge:IsActive()
	return CraftForge:IsEnabled()
end

function CraftForge:XMLDebug(text)
	DA.DEBUG(0,text)
end

function CraftForge:XMLDebugLink(text, link)
	DA.DEBUG(0,text..DA.PLINK(link))
end

--[[
-- Player names ------------------------------------------------------------------
-- In Forever every character has a first name and a surname, unique across the
-- region: UnitName returns (first name, surname), and addon messages come from
-- "First Surname" with no realm. Elsewhere it's (name, realm) and "Name-Realm".

local function surnameSeparator()
    local consts = Constants and Constants.CharacterNameSeparatorConsts
    return consts and consts.CHARACTERNAME_SURNAME_SEPARATOR or " "
end

local function uniqueNames()
    return RegionalUniqueNamesEnabled ~= nil and RegionalUniqueNamesEnabled() == true
end

-- A unit's name as addon messages from them show it, or nil if unknown.
local function unitFullName(unit)
    local getName = unit == "player" and UnitNameUnmodified or UnitName
    local name, second = getName(unit)
    if not name or issecretvalue(name) or (second and issecretvalue(second)) then
		return nil 
	end
    if uniqueNames() then
        local separator = surnameSeparator()
        if second and second ~= "" and not name:find(separator, 1, true) then
			return name .. separator .. second
		end
        return name
    end
end
--]]

--
-- Note function name is intentionally different than the Blizzard function
--
function CraftForge:unitName(target)
	if CraftForge.isForever then
		if CraftForge.db.global.useFirstNameOnly then
			return UnitName(target)
		else
			return GetUnitName(target)
		end
	else
		return UnitName(target)
	end
end
