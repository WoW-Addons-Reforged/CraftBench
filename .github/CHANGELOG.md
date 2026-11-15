# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Code Quality & Packaging Infrastructure (`.luacheckrc`, `.gitignore`, `.gitattributes`, `.github/workflows/quality.yml`)**: Added `luacheck` configuration, `Code Quality` GitHub Actions workflow (`luacheck` + `.toc` validation), and export/packaging ignores for dev scripts (`*.js`, `*.py`).

### Changed
- **Release Workflow & Packaging (`.github/workflows/release.yml`, `.pkgmeta`, `Skillet.toc`)**: Updated GitHub Actions to `actions/checkout@v4` and `BigWigsMods/packager@v2` with `.github/CHANGELOG.md` support, excluded dev scripts in `.pkgmeta`, and fixed `## X-License: GPL-3.0` syntax in `Skillet.toc`.

### Fixed
- **BeanCounter Gold Sorting (`Plugins/BeanCounter.lua`)**: Removed `or 0` on multi-return `plugin.GetBCValues(...)` call in `SortGoldEarned` which discarded the 5th return value (`itemValueA`/`itemValueB`) and caused it to always evaluate to `0`.
- **Undefined `tradeskill` & Global Leak in `UI/Sorting.lua`**: Passed `tradeskill` properly into `get_suffix(tradeskill, recipe, first)` and localized `actualRecipe`.
- **Debug Stack Bug in `DeepCopy.lua`**: Added missing `stack` parameter to `DA.deepcopy_push(stack, ...)` and fixed `stack_top` typo to `stack._top`.
- **Global Variable Leaks & Redundant Assignments**: Localized leaked globals (`action`, `name`, `mitem`, `toolName`, `oreagentID`, `ocurrencyID`, `freagentID`, `mreagentID`, `sreagentID`, `_`) across `Skillet.lua`, `SkillLevelData.lua`, `SkilletQueue.lua`, `UI/DetailFrame.lua`, `UI/OptionalList.lua`, `UI/RequiredList.lua`, `UI/FinishingList.lua`, `UI/ModifiedList.lua`, `UI/SalvageList.lua`, and `UI/MainButtons.lua`; removed redundant `= 0` / `numowned` initializations in `Inventory.lua` and `UI/MainFrame.lua`.
