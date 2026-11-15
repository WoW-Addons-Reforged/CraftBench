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
- **Directory Structure & External Libraries (`Core/`, `Data/`, `Utils/`, `Scripts/`, `Skillet.toc`, `.pkgmeta`, `UI/DetailFrame.lua`)**:
  - Reorganized root Lua files into `Core/`, `Data/`, and `Utils/`, and moved developer scripts into `Scripts/` (excluded from packaging via `.pkgmeta` and `.gitattributes`).
  - Removed embedded `Libs/EasySkillet/` and replaced `EasySkillet(...)` in `UI/DetailFrame.lua` with `MenuUtil.CreateContextMenu` (with `EasyMenu` fallback).
  - Updated `.pkgmeta` externals for `LibStub`, `CallbackHandler-1.0`, and all `Ace3` libraries to pull directly from `https://github.com/WoWUIDev/Ace3`.
- **Release Workflow & Packaging (`.github/workflows/release.yml`, `.pkgmeta`, `Skillet.toc`)**: Updated GitHub Actions to `actions/checkout@v4` and `BigWigsMods/packager@v2` with `.github/CHANGELOG.md` support, excluded dev scripts in `.pkgmeta`, and fixed `## X-License: GPL-3.0` syntax in `Skillet.toc`.

### Fixed
- **Plugin Integration Fixes (`Core/CraftForgePlugin.lua`, `Plugins/AckisRecipeList.lua`, `CraftForge.toc`)**:
  - Fixed `CraftForge:IsRecipeNamePluginRegistered` referencing non-existent `CraftForge.RecipeNamePlugins` instead of `RecipeNamePrefixes` / `RecipeNameSuffixes`.
  - Initialized `local ARLProfessionInitialized = {}` in `Plugins/AckisRecipeList.lua` to prevent nil indexing and global leaks.
  - Added missing plugin addons (`AckisRecipeList`, `AuctionDB`, `CanIMogIt`, `DataStore_Auctions`, `Overachiever`) to `## OptionalDeps:` in `CraftForge.toc` and removed obsolete `Plugins/TheUndermineJournal.lua`.
- **BeanCounter Gold Sorting (`Plugins/BeanCounter.lua`)**: Removed `or 0` on multi-return `plugin.GetBCValues(...)` call in `SortGoldEarned` which discarded the 5th return value (`itemValueA`/`itemValueB`) and caused it to always evaluate to `0`.
- **Undefined `tradeskill` & Global Leak in `UI/Sorting.lua`**: Passed `tradeskill` properly into `get_suffix(tradeskill, recipe, first)` and localized `actualRecipe`.
- **Debug Stack Bug in `DeepCopy.lua`**: Added missing `stack` parameter to `DA.deepcopy_push(stack, ...)` and fixed `stack_top` typo to `stack._top`.
- **Global Variable Leaks & Redundant Assignments**: Localized leaked globals (`action`, `name`, `mitem`, `toolName`, `oreagentID`, `ocurrencyID`, `freagentID`, `mreagentID`, `sreagentID`, `_`) across `Skillet.lua`, `SkillLevelData.lua`, `SkilletQueue.lua`, `UI/DetailFrame.lua`, `UI/OptionalList.lua`, `UI/RequiredList.lua`, `UI/FinishingList.lua`, `UI/ModifiedList.lua`, `UI/SalvageList.lua`, and `UI/MainButtons.lua`; removed redundant `= 0` / `numowned` initializations in `Inventory.lua` and `UI/MainFrame.lua`.
