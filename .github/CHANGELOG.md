# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **One-Click Material Processing (`Core/CraftForgeProcess.lua`, `Core/CraftForge.lua`, `Core/CraftForgeOptions.lua`, `Locale/Locale-enUS.lua`, `Locale/Locale-deDE.lua`, `CraftForge.toc`)**: Integrated Molinari-style one-click **Disenchanting**, **Prospecting**, **Milling**, and **Pick Lock** via a combat-safe `SecureActionButtonTemplate` overlay (`CraftForgeProcessButton`), supporting both Retail (`TooltipDataProcessor`) and Classic (`OnTooltipSetItem`) with full AceConfig options (modifier key, per-action toggles, max disenchant quality, glow highlight).
- **CraftForge Rebranding & Brand Assets (`CraftForge.toc`, `.github/assets/logo.jpg`, `.github/assets/social-banner.jpg`, `README.md`)**: Rebranded the entire addon from `Skillet` to `CraftForge` (identifiers, SavedVariables, frames, locales, slash commands, `.toc`, `.pkgmeta`, `.luacheckrc`), added custom CraftForge logo and social preview banner, and updated `README.md` with standard badges and documentation.
- **Code Quality & Packaging Infrastructure (`.luacheckrc`, `.gitignore`, `.gitattributes`, `.github/workflows/quality.yml`)**: Added `luacheck` configuration, `Code Quality` GitHub Actions workflow (`luacheck` + `.toc` validation), and export/packaging ignores for dev scripts (`*.js`, `*.py`).

### Changed
- **Multi-Flavor TOC & Project Flags (`CraftForge.toc`, `Core/CraftForge.lua`)**: Added full multi-flavor `## Interface` and per-flavor `## Interface-*` headers (`Retail`, `Classic`, `Forever`, `BCC`, `Wrath`, `Titan`, `Cata`, `Mists`), extended `Data\SkillLevelData1.lua` `AllowLoadGameType` to all non-standard flavors, and populated `isClassic`/`isBCC`/`isWrath`/`isCata`/`isMists` project flags in `Core/CraftForge.lua`.
- **Directory Structure & External Libraries (`Core/`, `Data/`, `Utils/`, `Scripts/`, `Skillet.toc`, `.pkgmeta`, `UI/DetailFrame.lua`)**:
  - Reorganized root Lua files into `Core/`, `Data/`, and `Utils/`, and moved developer scripts into `Scripts/` (excluded from packaging via `.pkgmeta` and `.gitattributes`).
  - Removed embedded `Libs/EasySkillet/` and replaced `EasySkillet(...)` in `UI/DetailFrame.lua` with `MenuUtil.CreateContextMenu` (with `EasyMenu` fallback).
  - Updated `.pkgmeta` externals for `LibStub`, `CallbackHandler-1.0`, and all `Ace3` libraries to pull directly from `https://github.com/WoWUIDev/Ace3`.
- **Release Workflow & Packaging (`.github/workflows/release.yml`, `.pkgmeta`, `Skillet.toc`)**: Updated GitHub Actions to `actions/checkout@v4` and `BigWigsMods/packager@v2` with `.github/CHANGELOG.md` support, excluded dev scripts in `.pkgmeta`, and fixed `## X-License: GPL-3.0` syntax in `Skillet.toc`.

### Fixed
- **Blizzard Frame Compatibility & Duplicate Hook Guards (`Core/CraftForge.lua`, `Core/CraftForgeOptions.lua`, `UI/MainButtons.lua`, `UI/MainFrame.lua`)**:
  - Added nil-safe `ProfessionsFrame or TradeSkillFrame` guards in `EnableBlizzardFrame`, `SetSelectedSkill`, `CraftForgeOptions` (`btsui`), and `UI/MainButtons.lua` to prevent crashes on clients without `ProfessionsFrame`.
  - Prevented duplicate `HookScript("OnClick", ...)` registrations on `CloseButton` in `UI/MainButtons.lua`.
  - Removed unused `color`/`skillIndex` declarations in `UI/MainFrame.lua`.
- **Auctionator, AuctionDB, OribosExchange & BeanCounter Plugin Fixes (`Plugins/Auctionator.lua`, `UI/DetailFrame.lua`, `Plugins/AuctionDB.lua`, `Plugins/OribosExchange.lua`, `Plugins/BeanCounter.lua`)**:
  - Enabled the Auctionator search button in `UI/DetailFrame.lua` on Classic clients (`AuctionFrame` in addition to `AuctionHouseFrame`), added API/empty-list/scrollName guards in `AuctionatorSearch`, fixed duplicate `order` key in options, and guarded Journalator `failedCount` with `or 0`.
  - Fixed `Plugins/OribosExchange.lua` `RecipeNameSuffix` returning `nil` due to out-of-scope `local value` and fixed Classic reagent ID lookup (`v.id` vs `v.reagentID`).
  - Fixed `Plugins/AuctionDB.lua` multiplying reagent cost by `recipe.numMade` instead of `needed`, guarded `nil` `itemID` in `AHDB_Price`, and guarded `nil` `reagentName` in `string.format`.
  - Fixed `Plugins/BeanCounter.lua` `SortSoldAmount` comparing `a.recipeData.itemID` against itself instead of `b.recipeData.itemID`.
- **Plugin Integration Fixes (`Core/CraftForgePlugin.lua`, `Plugins/AckisRecipeList.lua`, `CraftForge.toc`)**:
  - Fixed `CraftForge:IsRecipeNamePluginRegistered` referencing non-existent `CraftForge.RecipeNamePlugins` instead of `RecipeNamePrefixes` / `RecipeNameSuffixes`.
  - Initialized `local ARLProfessionInitialized = {}` in `Plugins/AckisRecipeList.lua` to prevent nil indexing and global leaks.
  - Added missing plugin addons (`AckisRecipeList`, `AuctionDB`, `CanIMogIt`, `DataStore_Auctions`, `Overachiever`) to `## OptionalDeps:` in `CraftForge.toc` and removed obsolete `Plugins/TheUndermineJournal.lua`.
- **BeanCounter Gold Sorting (`Plugins/BeanCounter.lua`)**: Removed `or 0` on multi-return `plugin.GetBCValues(...)` call in `SortGoldEarned` which discarded the 5th return value (`itemValueA`/`itemValueB`) and caused it to always evaluate to `0`.
- **Undefined `tradeskill` & Global Leak in `UI/Sorting.lua`**: Passed `tradeskill` properly into `get_suffix(tradeskill, recipe, first)` and localized `actualRecipe`.
- **Debug Stack Bug in `DeepCopy.lua`**: Added missing `stack` parameter to `DA.deepcopy_push(stack, ...)` and fixed `stack_top` typo to `stack._top`.
- **Global Variable Leaks & Redundant Assignments**: Localized leaked globals (`action`, `name`, `mitem`, `toolName`, `oreagentID`, `ocurrencyID`, `freagentID`, `mreagentID`, `sreagentID`, `_`) across `Skillet.lua`, `SkillLevelData.lua`, `SkilletQueue.lua`, `UI/DetailFrame.lua`, `UI/OptionalList.lua`, `UI/RequiredList.lua`, `UI/FinishingList.lua`, `UI/ModifiedList.lua`, `UI/SalvageList.lua`, and `UI/MainButtons.lua`; removed redundant `= 0` / `numowned` initializations in `Inventory.lua` and `UI/MainFrame.lua`.
