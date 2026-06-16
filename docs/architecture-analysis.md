# Architecture Analysis

## Overview

This document describes the current architecture of the CMaNGOS Achievements module, its event flow, core integration points, and areas of technical debt.

---

## Current Architecture

### Module Framework Dependency

The achievements module is built on top of the **cmangos-modules** framework
(`https://github.com/davidonete/cmangos-modules`).  Every feature is exposed
through a single class, `AchievementsModule`, which derives from `Module` (the
base class provided by that framework).

The framework injects hooks into the game core via a large patch file
(`classic.patch`).  The patch adds calls to a `ModuleMgr` singleton throughout
the CMaNGOS source tree so that registered modules receive callbacks for game
events.  Without the patch the module framework is not present in the core and
the module will not build.

### Source Files

| File | Purpose |
|------|---------|
| `src/AchievementsModule.h` | Main header — all data structures, enums, and `AchievementsModule` class declaration |
| `src/AchievementsModule.cpp` | ~6 400 lines — all achievement logic, criteria evaluation, DB I/O, packet handling |
| `src/AchievementsModuleConfig.h` | Configuration struct and enums shared between header and config loader |
| `src/AchievementsModuleConfig.cpp` | Reads `achievements.conf` via the module framework's `ModuleConfig` helper |
| `src/AchievementScriptMgr.h` | Internal scripting system (criteria scripts, player scripts, achievement scripts) |
| `src/AchievementScriptMgr.cpp` | Implementation of script registration and dispatch |
| `src/achievement_scripts.cpp` | Concrete script definitions wired to the `AchievementScriptMgr` |
| `CMakeLists.txt` | Build definition — links against `modules`, `shared`, and `RecastNavigation::Detour` |

### Key Classes

#### `AchievementsModule` (inherits `Module`)

The central singleton for server-wide achievement data and routing.  Responsibilities:

- Loading all achievement DBC data from world-database tables
  (`achievement_dbc`, `achievement_criteria_dbc`, `achievement_category_dbc`)
- Loading and caching realm-first completion data
- Routing every game event (see *Event Flow* section) to the appropriate
  `PlayerAchievementMgr` instance
- Providing GM/admin chat commands for managing achievements in-game

#### `PlayerAchievementMgr`

One instance is stored per online player inside
`AchievementsModule::m_playerMgrs` (keyed by player GUID).  Manages:

- Per-player criteria progress (`CriteriaProgressMap`)
- Per-player completed achievements (`CompletedAchievementMap`)
- Active timed achievements
- DB save/load (`SaveToDB`, `LoadFromDB`)
- Packet construction for the Achiever addon

#### `AchievementScriptMgr` / Script Registry

A mini-scripting layer on top of the main module, following the TrinityCore
scripting pattern.  Provides extension points:

- `AchievementCriteriaScript::OnCheck` — custom per-criteria validation
- `PlayerScript::OnAchiComplete`, `OnCriteriaProgress`, etc.
- `AchievementScript::IsCompletedCriteria`, `IsRealmCompleted`, etc.

### Data Structures

| Struct | Description |
|--------|-------------|
| `AchievementEntry` | Mirror of `achievement_dbc` — ID, faction, map, names/descriptions in 16 locales, flags, points |
| `AchievementCategoryEntry` | Mirror of `achievement_category_dbc` |
| `AchievementCriteriaEntry` | Mirror of `achievement_criteria_dbc` — large union covering all 125 criteria types |
| `CriteriaProgress` | Per-player counter, last-update timestamp, dirty flag |
| `CompletedAchievementData` | Completion timestamp, dirty flag |
| `AchievementCriteriaData` | Row from `achievement_criteria_data` — prerequisite conditions |
| `AchievementReward` | Row from `achievement_reward` — title ID, item ID, mail template |

### Database Tables

#### Character Database

| Table | Columns | Description |
|-------|---------|-------------|
| `character_achievement` | `guid`, `achievement`, `date` | Completed achievements per character |
| `character_achievement_progress` | `guid`, `criteria`, `counter`, `date` | In-progress criteria counters |

#### World Database

| Table | Description |
|-------|-------------|
| `achievement_dbc` | Achievement definitions (ported from WotLK DBC) |
| `achievement_criteria_dbc` | Criteria definitions |
| `achievement_category_dbc` | Category definitions |
| `achievement_criteria_data` | Extra conditions/requirements per criteria |
| `achievement_reward` | Reward mapping (title, item, mail) |
| `achievement_reward_locale` | Localised reward strings |

---

## Event Flow

The module receives callbacks from the game core through the `ModuleMgr` hook
layer injected by `classic.patch`.  When an in-game event occurs the following
path is followed:

```
Game Core (e.g. Player::RewardQuest)
    └─> ModuleMgr::OnRewardQuest(player, quest)          [injected by patch]
            └─> AchievementsModule::OnRewardQuest(player, quest)
                    └─> mgr->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_COMPLETE_QUEST, ...)
                            └─> PlayerAchievementMgr::UpdateAchievementCriteria(type, ...)
                                    ├─> Iterates matching criteria entries
                                    ├─> Calls AchievementCriteriaData::Meets() for conditions
                                    ├─> Calls SetCriteriaProgress() to record progress
                                    ├─> Sends SMSG_CRITERIA_UPDATE packet to addon
                                    ├─> Calls CompletedCriteriaFor() to check achievement completion
                                    └─> Calls CompletedAchievement() to award the achievement
```

### Complete Hook Surface

The following hooks are currently consumed by `AchievementsModule`:

**Module lifecycle:**
- `OnInitialize` — loads all DBC data from world DB
- `OnUpdate(elapsed)` — ticks timed achievement timers

**Player lifecycle:**
- `OnPreCharacterCreated` — prepares mgr slot on character create
- `OnPreLoadFromDB` — creates mgr slot before DB load
- `OnLoadFromDB` — loads progress/completions from character DB
- `OnLogOut` — saves and removes mgr
- `OnDeleteFromDB` — purges character achievement data
- `OnSaveToDB` — flushes dirty progress and completions
- `OnWriteDump` / `IsModuleDumpTable` — character dump support

**Player gameplay:**
- `OnAddSpell` — `LEARN_SPELL` / `LEARN_SKILLLINE_SPELLS` criteria
- `OnDuelComplete` — `WIN_DUEL` / `LOSE_DUEL` criteria
- `OnKilledMonsterCredit` — `KILL_CREATURE` criteria
- `OnRewardPlayerAtKill` — `HK_CLASS` / `HK_RACE` / `HONORABLE_KILL` criteria
- `OnHandleFall` — `FALL_WITHOUT_DYING` criteria
- `OnResetTalents` — `NUMBER_OF_TALENT_RESETS` / `GOLD_SPENT_FOR_TALENTS` criteria
- `OnStoreItem` / `OnMoveItemToInventory` — `OWN_ITEM` / `RECEIVE_EPIC_ITEM` criteria
- `OnDeath(player, killer)` — `DEATH` / `DEATH_AT_MAP` / `KILLED_BY_CREATURE` / `KILLED_BY_PLAYER` criteria
- `OnDeath(player, envDamageType)` — `DEATHS_FROM` criteria
- `OnHandlePageTextQuery` — addon protocol handshake
- `OnUpdateSkill` — `REACH_SKILL_LEVEL` / `LEARN_SKILL_LEVEL` criteria
- `OnRewardHonor` — `HONORABLE_KILL_AT_AREA` criteria
- `OnEquipItem` — `EQUIP_EPIC_ITEM` / `EQUIP_ITEM` criteria
- `OnUseItem` — `USE_ITEM` criteria
- `OnRewardQuest` — `COMPLETE_QUEST` / `COMPLETE_QUEST_COUNT` / `COMPLETE_QUESTS_IN_ZONE` / `COMPLETE_DAILY_QUEST` / `MONEY_FROM_QUEST_REWARD` criteria
- `OnTaxiFlightRouteStart/End` — `FLIGHT_PATHS_TAKEN` criteria
- `OnSetReputation` — `GAIN_REPUTATION` / `GAIN_EXALTED_REPUTATION` criteria
- `OnEmote` — `DO_EMOTE` criteria
- `OnBuyBankSlot` — `BUY_BANK_SLOT` criteria
- `OnSellItem(player)` — `MONEY_FROM_VENDORS` criteria
- `OnBuyBackItem` — no active criteria (reserved)
- `OnCreateItem` — (crafted item tracking)
- `OnModifyMoney` — `HIGHEST_GOLD_VALUE_OWNED` criteria
- `OnSummoned` — `ACCEPTED_SUMMONINGS` criteria
- `OnAreaExplored` — `EXPLORE_AREA` criteria
- `OnUpdateHonor` — `OWN_RANK` criteria
- `OnGiveLevel` — `REACH_LEVEL` criteria
- `OnAbandonQuest` — `QUEST_ABANDONED` criteria
- `OnTradeAccepted` — `TRADES_DONE` criteria

**Mail:**
- `OnSendMail` — `GOLD_SPENT_FOR_MAIL` / `MAIL_GOLD` / `MAIL_ITEMS` criteria
- `OnMailTakeItem` — `RECEIVE_EPIC_ITEM` criteria
- `OnMailTakeMoney` — reserved

**Battleground:**
- `OnStartBattleGround` — sets initial BG state for timed criteria
- `OnEndBattleGround` — `WIN_BG` / `COMPLETE_BATTLEGROUND` / `COMPLETE_RAID` criteria
- `OnUpdatePlayerScore` — BG-specific criteria (damage, healing, kills, objectives)
- `OnLeaveBattleGround` — condition resets (`ACHIEVEMENT_CRITERIA_CONDITION_BG_MAP`)
- `OnJoinBattleGround` — condition resets
- `OnPickUpFlag(BattleGroundWS)` — `BG_OBJECTIVE_CAPTURE` criteria

**Game Object:**
- `OnUse(GameObject, Unit)` — `USE_GAMEOBJECT` / `FISH_IN_GAMEOBJECT` criteria

**Unit:**
- `OnDealDamage` — `DAMAGE_DONE` / `HIGHEST_HIT_DEALT` / `TOTAL_DAMAGE_RECEIVED` criteria
- `OnKill` — `KILL_CREATURE_TYPE` / `SPECIAL_PVP_KILL` / `GET_KILLING_BLOWS` criteria
- `OnDealHeal` — `HEALING_DONE` / `HIGHEST_HEAL_CASTED` / `TOTAL_HEALING_RECEIVED` criteria

**Spell:**
- `OnHit(Spell, caster, target)` — `BE_SPELL_TARGET` / `BE_SPELL_TARGET2` criteria
- `OnCast(Spell, caster, target)` — `CAST_SPELL` / `CAST_SPELL2` criteria

**Loot:**
- `OnHandleLootMasterGive` — `LOOT_ITEM` / `LOOT_EPIC_ITEM` criteria
- `OnPlayerRoll` — `ROLL_NEED_ON_LOOT` / `ROLL_GREED_ON_LOOT` criteria
- `OnPlayerWinRoll` — `ROLL_NEED` / `ROLL_GREED` criteria
- `OnSendGold` — `LOOT_MONEY` / `LOOT_TYPE` criteria

**Group:**
- `OnAddMember` — `JOINED_GROUP` criteria

**Auction House:**
- `OnSellItem(AuctionEntry)` — `CREATE_AUCTION` / `HIGHEST_AUCTION_SOLD` criteria
- `OnUpdateBid` — `HIGHEST_AUCTION_BID` criteria
- `OnActionBidWinning` — `GOLD_EARNED_BY_AUCTIONS` / `WON_AUCTIONS` criteria

---

## Core Integration Points

### ModuleMgr Hook Layer

All integration with the game core passes through `ModuleMgr`, a singleton
class injected into the CMaNGOS source by `classic.patch`.  The patch adds
`ModuleMgr::CallHook<HookName>(args...)` calls at roughly **70+ sites** across
the game-server codebase.

Because this patch must be kept in sync with upstream CMaNGOS, it is the
single largest maintenance burden.  Any CMaNGOS commit that modifies a hooked
function signature requires an update to both the patch and the module.

### CMaNGOS APIs Used

| Component | API used |
|-----------|---------|
| Logging | `sLog.outError`, `sLog.outDetail`, `sLog.outString` |
| Object Manager | `sObjectMgr.GetCreatureTemplate`, `sObjectMgr.GetItemPrototype`, etc. |
| Spell Manager | `sSpellMgr.GetSpellEntry` |
| World | `sWorld.getConfig`, `sWorld.GetSessionCount` |
| Game Events | `sGameEventMgr.IsActiveHoliday` |
| Guild Manager | `sGuildMgr.GetGuildById` |
| Character DB | `CharacterDatabase.PQuery`, `CharacterDatabase.PExecute`, `BeginTransaction`, `CommitTransaction` |
| World DB | `WorldDatabase.Query` |
| Battleground | `BattleGround::GetBgMap()->GetVariableManager().GetVariable(...)` |
| Packets | `WorldPacket`, `SMSG_ACHIEVEMENT_EARNED`, custom addon messages |
| Player | `Player::GetGUIDLow`, `GetSession`, `GetTeam`, `GetHonorPoints`, etc. |

### PlayerBots Dependency

The module has optional integration with the PlayerBots module (`ENABLE_PLAYERBOTS`).
Approximately 15 `#ifdef ENABLE_PLAYERBOTS` blocks gate bot-specific behaviour
such as suppressing addon packets for bots and handling bot deaths differently.
This dependency is entirely optional; the module builds and functions correctly
without it.

---

## Areas of Technical Debt

### 1. Large Monolithic Source File

`AchievementsModule.cpp` is ~6 400 lines, containing data loading, criteria
evaluation, packet construction, GM commands, and BG scoring in a single
translation unit.  This increases compile times and makes targeted changes
risky.

### 2. Tight Coupling to ModuleMgr

Every event callback flows through the `Module` base class and `ModuleMgr`.
There is no way to receive events without the module framework patch being
applied to the core.  This makes independent builds or alternative integration
strategies impossible without significant refactoring.

### 3. Outdated Database API Patterns

The code uses the legacy `PQuery`/`PExecute` style with raw `printf`-style
format strings.  Modern CMaNGOS prefers prepared statements via
`CharacterDatabase.GetPreparedStatement(...)` and `CharacterDatabase.Execute(stmt)`.

### 4. Achievement Data Stored in World DB

Achievement DBC data is stored as custom world-database tables
(`achievement_dbc`, `achievement_criteria_dbc`, etc.).  Modern CMaNGOS loads
DBC data directly from files using `DBCStorage<>` templates.  However, since
Classic WoW does not ship WotLK DBC files, storing this data in the DB is
intentional and must be preserved.

### 5. Non-Idempotent SQL Scripts

The install scripts use `DROP TABLE IF EXISTS` followed by `CREATE TABLE IF NOT
EXISTS`.  The world install scripts also contain raw `INSERT` statements without
`INSERT IGNORE` or `ON DUPLICATE KEY UPDATE`, making re-runs destructive.

### 6. Missing Indexes

The character tables lack secondary indexes.  Performance with large character
counts would benefit from:
- Index on `character_achievement(achievement)` for realm-first queries
- Index on `character_achievement_progress(criteria)` for bulk resets

### 7. PlayerBots Ifdef Sprawl

Fifteen `#ifdef ENABLE_PLAYERBOTS` guards are scattered throughout the file.
These should be consolidated into a thin adapter layer or virtual overrides.

### 8. No CMake Version Requirement

`CMakeLists.txt` does not set `cmake_minimum_required`, which can cause silent
compatibility problems on newer CMake versions.

### 9. Hooks Not Present in Module Base Class

Several methods (`OnEquipItem`, `OnUseItem`, `OnRewardQuest`, `OnSetReputation`,
`OnSendMail`, `OnMailTakeItem`, `OnMailTakeMoney`) are declared in
`AchievementsModule` but are **not** virtual overrides of the `Module` base
class.  They are called directly or via patch-inserted code, which means they
bypass the module dispatch mechanism and are fragile across core updates.

### 10. No Automated Tests or CI

There is no build verification workflow, no unit tests, and no SQL validation
CI pipeline.  Regressions after upstream CMaNGOS changes go undetected until a
developer attempts a build.
