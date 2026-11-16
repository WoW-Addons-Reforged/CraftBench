<div align="center">
  <img src=".github/assets/social-banner.jpg" alt="CraftBench Banner" width="100%" />

  # CraftBench

  **All-in-One World of Warcraft Profession, Crafting Queue, Shopping List & Material-Processing Suite.**

  [![Code Quality](https://github.com/gOOvER/CraftBench/actions/workflows/quality.yml/badge.svg)](https://github.com/gOOvER/CraftBench/actions/workflows/quality.yml)
  [![Release](https://github.com/gOOvER/CraftBench/actions/workflows/release.yml/badge.svg)](https://github.com/gOOvER/CraftBench/actions/workflows/release.yml)
  [![GitHub Release](https://img.shields.io/github/v/release/gOOvER/CraftBench?include_prereleases&label=Version&color=brightgreen&logo=github)](https://github.com/gOOvER/CraftBench/releases/latest)
  [![CurseForge](https://img.shields.io/badge/CurseForge-CraftBench-f16436?logo=curseforge&logoColor=white)](https://www.curseforge.com/wow/addons/craftbench)
  [![Wago.io](https://img.shields.io/badge/Wago.io-CraftBench-c1272d?logo=wagtail&logoColor=white)](https://addons.wago.io/addons/craftbench)
  [![WoW Versions](https://img.shields.io/badge/WoW-Retail%20%7C%20Classic%20%7C%20BCC%20%7C%20Wrath%20%7C%20Cata%20%7C%20MoP%20%7C%20Forever-f8b700?logo=battle.net&logoColor=white)](#-supported-wow-versions)
  [![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE.txt)
  [![Support](https://img.shields.io/badge/Support-donate.goover.dev-ff69b4?logo=ko-fi&logoColor=white)](https://donate.goover.dev)
</div>

---

## Features
- **Complete Profession Replacement (Native Dark-Gold UI)**: Enhanced crafting UI with multi-item crafting queues, persistent cross-session queues, custom recipe grouping, source/profit filtering, sorting (name, difficulty, level, quality, profit), and native Dark-Gold **Options** and **News** windows.
- **Smart Reagent & Alt Finder**: Tracks materials and learned recipes across bags, bank, warband/reagent bank, and alts (`/craftbench find`), with recursive craftability counts and automatic vendor reagent purchasing.
- **Shopping List & Cost/Profit Calculator**: Displays required materials at banks, guild banks, and auction houses with one-click item retrieval plus live crafting cost, sell value, and profit calculation.
- **Fishing Tracker, Catch Database & Auto-Lure**: Dedicated Dark-Gold Fishing window (`/craftbench fish`) that logs every catch per zone/subzone (count, drop %, min skill, day/night split, estimated value), tracks session stats & Stranglethorn Derby countdown, and provides secure one-key Fishing cast with automatic best-lure application and Fishing Pole / combat weapon swap keybinds.
- **Trade Contacts (Vendor & Trainer Memory)**: Automatically records visited recipe/tradegood vendors and profession trainers (with zone, coordinates, prices, and limited stock) and displays known vendor locations on item tooltips.
- **Recipe Notes, Sources & Ignored Materials**: Attach custom notes to recipes and reagents, inspect recipe acquisition sources in hover tooltips, and exclude materials you do not want tracked or purchased.
- **Addon Integrations**: Supports **Auctionator**, **TradeSkillMaster (TSM)**, **OribosExchange**, **AuctionDB**, **Baganator / Syndicator**, **BetterBags**, **Bagnon / Combuctor / ArkInventory / ElvUI Bags / AdiBags / LiteBag**, **ElvUI** (toggleable skin), **AllTheThings**, **AckisRecipeList**, **CanIMogIt**, **Overachiever**, **AchievementsUtils**, **Questie**, **AtlasLootClassic**, **BeanCounter**, **DataStore**, **TomTom**, and **Pawn**.
- **One-Click Material Processing, Batch Panel & Auto-Popup**: Hold a configurable modifier key (`Alt` / `Ctrl` / `Shift`) to highlight eligible items with an animated glowing border and click directly in your bags to **Disenchant**, **Prospect**, **Mill**, or **Pick Lock**, use the compact batch processing panel (`/craftbench process`), enable the optional Auto-Process Popup for newly acquired items, and view disenchant/prospect/mill yield tooltips.

## Supported WoW Versions
- **Retail** (`12.01.05`, `12.01.07`)
- **Classic / Era / Anniversary / MoP** (`1.16.x` / multi-flavor support via `CraftBench.toc`)

## Slash Commands
- `/craftbench` / `/cb` — Open options / manage CraftBench
- `/craftbench find` — Open the account-wide Alt Recipe & Inventory Finder
- `/craftbench process` — Open the Material Processing batch panel
- `/craftbench fish` — Open the Fishing tracker, catch log & auto-lure window
- `/craftbench level` — Open the Smart Profession Leveling Planner
- `/craftbench cd` — Open the account-wide Crafting Cooldowns tracker
- `/craftbench watch` — Pin/unpin a recipe or toggle the on-screen Recipe Watch HUD
- `/craftbench gather` — Open the Herbalism, Mining & Skinning Gathering Guide
- `/craftbench contacts` — Open the Trade Contacts browser with TomTom waypoints
- `/craftbench camp` — Open the WoW Forever Camping tracker
- `/craftbench options` — Open standalone options window
- `/craftbench minimap` — Toggle the minimap button
- `/craftbench export` / `/craftbench import` / `/craftbench sendqueue` — Share crafting queues

## Supported Addons & Integrations
All integrations are **optional** and automatically activate only when the respective addon is installed:

| Addon | What CraftBench Takes / Uses From It |
| :--- | :--- |
| **Auctionator** | Reads live AH buyout prices (`GetAuctionPriceByItemID`) for crafted items & reagents to compute craft cost, net profit, profit %, recipe sort order, and triggers AH shopping list searches (`StartSearch`) |
| **TradeSkillMaster (TSM)** | Reads TSM price sources (`DBMarket`, `DBMinBuyout`, `DBHistorical`, `Crafting`, etc.) via `TSM_API.GetCustomPriceValue` for reagent costs, sell value, and profit calculation |
| **OribosExchange** | Reads realm/region market & buyout prices (`OEMarketInfo`) for craft cost, sell value, and profit suffixes |
| **AuctionDB** | Reads AuctionDB AH scan prices (`AuctionDB:GetItemInfo` / `AHGetAuctionInfo`) for item values, reagent costs, and profit calculation |
| **Altoholic / DataStore** | Reads alt learned professions & recipes (`DataStore_Crafts`), bag/bank item counts (`DataStore_Containers`), mailbox item counts (`DataStore_Mails`), and active alt auctions (`DataStore_Auctions`) for `/cb find` and recipe counts |
| **AllTheThings (ATT)** | Reads recipe acquisition sources (`GetRecipeSource`) for tooltips and collection/completion status icons (`RecipeNamePrefix`) in the recipe list |
| **AckisRecipeList (ARL)** | Reads unlearned recipe acquisition sources (`GetRecipeSource`) and trainer/vendor/drop metadata for filtering and details |
| **CanIMogIt** | Reads transmog collection status (`GetIconText` / `PlayerKnowsTransmog`) to show known/unknown appearance prefixes on craftable gear |
| **Overachiever** | Reads recipe achievement links & icons (`Overachiever.GetIconForRecipe`) to mark recipes needed for achievements |
| **AchievementsUtils** | Reads indexed uncompleted achievement criteria (`FindByCriteriaName`, `GetAchievement`) for matching recipe/crafted item names and displays achievement icons & criteria details |
| **Questie** | Reads vendor NPCs + zones (`QueryItemSingle("vendors")`), mob drops (`npcDrops`), and quest sources (`relatedQuests`) from `QuestieDB` for recipe details |
| **AtlasLootClassic** | Reads recipe scroll item IDs (`Data.Recipe.GetRecipeForSpell`) and vendor prices (`Data.VendorPrice.GetVendorPriceForItem`) for recipe details |
| **GatherMate2** | Reads Mining & Herbalism node databases (`gmdbs`, `nodeIDs`, `DecodeLoc`) for `/cb gather` node counts and 1-click waypoints (selectable in **Plugins → Active Sources**) |
| **GathererReforged** | Reads Mining & Herbalism node storage (`Gatherer.Storage`) for `/cb gather` node counts and 1-click waypoints (selectable in **Plugins → Active Sources**) |
| **GatherRoutes** | Launches zone farm routes directly from `/cb gather` (also integrates with Gatherer Reforged's `/gather route`) |
| **SkillUp Forever** | Reads exact `orange / yellow / green / grey` skill-up thresholds (`GetThresholds`) when installed to refine skill-up chance % and `/cb level` planning |
| **BeanCounter** | Reads personal historical AH purchase & sale prices (`BeanCounter.API.search`) to show actual paid/earned averages in recipe details |
| **TomTom** | Creates map waypoints (`TomTom:AddWaypoint`) with a single click from visited Trade Contacts (`/cb contacts`) |
| **ElvUI** | Optional ElvUI skin toggle (`Plugins/ElvUI.lua`); CraftBench's native Dark-Gold UI stays active unless ElvUI skinning is explicitly enabled |
| **Baganator / Syndicator, BetterBags, Bagnon, Combuctor, ArkInventory, AdiBags, LiteBag** | Hooks bag & bank item slot frames to enable one-click modifier-key Material Processing (Disenchant, Prospect, Mill, Pick Lock) and reads `Syndicator` cross-character counts when available |
| **Pawn** | Reads Pawn equipment upgrade scores/scales (`PawnGetItemData`) to display upgrade value info in craftable item tooltips |

## Attribution & License
**CraftBench** is based on **Skillet** (by *yossa*, *bsmorgan*, *lilsparky*, *nogudnik*, and *Slartie*) and licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See [LICENSE.txt](LICENSE.txt) for details.

Special thanks for the inspiration and ideas behind key features go to **Molinari** (one-click modifier-key material processing) and **[ForeverArtisan](https://www.curseforge.com/wow/addons/foreverartisan)** (fishing tracker, catch log, auto-lure, and pole/weapon swap).
