# classic.patch Modernization Report

## Scope and evidence

This report was produced **before any code changes** and is based on:

- Local baseline configure/build attempt in this repository.
- GitHub Actions failure logs for recent `Build & Validate` runs.
- Dry-run and reject-based application of `classic.patch` from `flekz-games/cmangos-modules` against the current `cmangos/mangos-classic` `master` snapshot.

Reference artifacts used during analysis:

- `/tmp/cmangos-patch-audit/patch-dryrun.log`
- `/tmp/cmangos-patch-audit/git-apply.out`
- `/tmp/cmangos-patch-audit/gapply/src/game/Entities/Player.cpp.rej`
- `/tmp/cmangos-patch-audit/gapply/src/game/World/World.cpp.rej`

---

## 1) Every compile/build error observed

### A. CI compile error (repeated)

Observed in multiple failed workflow runs (e.g. `27647585357`, `27646530337`, `27645402834`, `27644924840`, `27644058662`):

```text
.../mangos-classic/src/game/vmap/TileAssembler.cpp:332:10: internal compiler error:
in compute_live_loop_exits, at tree-ssa-loop-manip.c:247
```

Interpretation: upstream core compiler ICE in GCC optimization pipeline (not module logic), historically mitigated by `-fno-tree-vrp` in workflow flags.

### B. CI configure error (earlier workflow revision)

Observed in failed runs (e.g. `27644923970`, `27644037082`):

```text
CMake Error at cmake/macros/FindMySQL.cmake:173 (message):
  Could not find the MySQL libraries!
```

Interpretation: CI dependency package mismatch (tooling/environment issue, not achievement logic).

### C. Local standalone configure error (this repository only)

From local run:

```text
CMake Error at CMakeLists.txt:90 (install):
  install FILES given no DESTINATION!
```

Interpretation: this module `CMakeLists.txt` expects parent-core variables (`CONF_INSTALL_DIR`/`CONF_DIR`) and is not intended to configure standalone.

---

## 2) Every failing patch hunk

Patch tested: `https://raw.githubusercontent.com/flekz-games/cmangos-modules/main/patches/classic.patch`
Target: current `cmangos/mangos-classic` `master` tarball snapshot.

### A. `patch --dry-run -p1`

- File: `src/game/Entities/Player.cpp`
  - Failed hunks: `#1, #18, #19, #20, #21, #22, #23, #24, #25, #26, #29, #31, #32, #33, #34, #35, #36, #37, #38, #39, #40, #41, #42, #43, #44`
- Summary: `25 out of 44 hunks FAILED` in `Player.cpp`.

### B. `git apply --reject` (stricter, captures true rejects)

Reject files:

- `src/game/Entities/Player.cpp.rej` (3 rejects)
- `src/game/World/World.cpp.rej` (1 reject)

#### Reject 1 — `Player.cpp` include block

```diff
@@ -73,6 +73,10 @@
+#ifdef ENABLE_MODULES
+#include "ModuleMgr.h"
+#endif
```

#### Reject 2 — `Player.cpp` skill update hook

```diff
@@ -5053,6 +5128,10 @@ bool Player::UpdateSkill(uint16 id, uint16 diff)
+#ifdef ENABLE_MODULES
+        sModuleMgr.OnUpdateSkill(this, id);
+#endif
```

#### Reject 3 — `Player.cpp` quest reward hook

```diff
@@ -12681,6 +12813,10 @@ void Player::RewardQuest(...)
+#ifdef ENABLE_MODULES
+    sModuleMgr.OnRewardQuest(this, pQuest);
+#endif
```

#### Reject 4 — `World.cpp` world initialized hook

```diff
@@ -1412,6 +1420,10 @@ void World::SetInitialWorldSettings()
+#ifdef ENABLE_MODULES
+    sModuleMgr.OnWorldInitialized();
+#endif
```

---

## 3) Every ModuleMgr dependency

### A. Build-time dependencies in this module

1. `src/AchievementsModule.h`
   - `#include "Module.h"`
   - `class AchievementsModule : public Module`
2. `src/AchievementsModuleConfig.h`
   - `#include "ModuleConfig.h"`
   - `class AchievementsModuleConfig : public ModuleConfig`
3. `src/AchievementsModuleConfig.cpp`
   - `ModuleConfig("achievements.conf")`
4. `CMakeLists.txt`
   - includes `${CMAKE_SOURCE_DIR}/src/modules/modules/src`
   - defines `ENABLE_MODULES`
   - links library target `modules`

### B. Runtime hook-surface dependencies in this module (`AchievementsModule`)

The module depends on ModuleMgr-driven hook dispatch for all of these handlers:

`OnInitialize`, `OnUpdate`, `OnPreCharacterCreated`, `OnPreLoadFromDB`, `OnLogOut`, `OnLoadFromDB`, `OnDeleteFromDB`, `OnSaveToDB`, `OnAddSpell`, `OnDuelComplete`, `OnKilledMonsterCredit`, `OnRewardPlayerAtKill`, `OnHandleFall`, `OnResetTalents`, `OnStoreItem`, `OnMoveItemToInventory`, `OnDeath` (both overloads), `OnHandlePageTextQuery`, `OnUpdateSkill`, `OnRewardHonor`, `OnEquipItem`, `OnUseItem`, `OnRewardQuest`, `OnTaxiFlightRouteStart`, `OnTaxiFlightRouteEnd`, `OnSetReputation`, `OnEmote`, `OnBuyBankSlot`, `OnSellItem` (player), `OnBuyBackItem`, `OnCreateItem`, `OnModifyMoney`, `OnSummoned`, `OnAreaExplored`, `OnUpdateHonor`, `OnGiveLevel`, `OnAbandonQuest`, `OnTradeAccepted`, `OnStartBattleGround`, `OnEndBattleGround`, `OnUpdatePlayerScore`, `OnLeaveBattleGround`, `OnJoinBattleGround`, `OnPickUpFlag`, `OnUse` (GameObject), `OnDealDamage`, `OnKill`, `OnDealHeal`, `OnHit`, `OnCast`, `OnHandleLootMasterGive`, `OnPlayerRoll`, `OnPlayerWinRoll`, `OnSendGold`, `OnAddMember`, `OnSellItem` (auction), `OnUpdateBid`, `OnActionBidWinning`, `OnSendMail`, `OnMailTakeItem`, `OnMailTakeMoney`, `OnWriteDump`.

### C. Direct ModuleMgr call dependencies in `classic.patch`

`classic.patch` injects `sModuleMgr.*` calls across the core; currently it contains **86 distinct hook call names** (framework-wide), including all achievement-relevant events and additional non-achievement framework hooks.

---

## 4) Every place where `classic.patch` modifies the core

`classic.patch` modifies **35 files** in `mangos-classic`:

1. `CMakeLists.txt`
2. `cmake/options.cmake`
3. `cmake/showoptions.cmake`
4. `src/CMakeLists.txt`
5. `src/game/AuctionHouse/AuctionHouseHandler.cpp`
6. `src/game/AuctionHouse/AuctionHouseMgr.cpp`
7. `src/game/BattleGround/BattleGround.cpp`
8. `src/game/BattleGround/BattleGroundAB.cpp`
9. `src/game/BattleGround/BattleGroundAV.cpp`
10. `src/game/BattleGround/BattleGroundHandler.cpp`
11. `src/game/BattleGround/BattleGroundWS.cpp`
12. `src/game/CMakeLists.txt`
13. `src/game/Chat/Chat.cpp`
14. `src/game/Chat/ChatHandler.cpp`
15. `src/game/Entities/Creature.cpp`
16. `src/game/Entities/GameObject.cpp`
17. `src/game/Entities/ItemHandler.cpp`
18. `src/game/Entities/NPCHandler.cpp`
19. `src/game/Entities/Player.cpp`
20. `src/game/Entities/Player.h`
21. `src/game/Entities/QueryHandler.cpp`
22. `src/game/Entities/Unit.cpp`
23. `src/game/Groups/Group.cpp`
24. `src/game/Loot/LootHandler.cpp`
25. `src/game/Loot/LootMgr.cpp`
26. `src/game/Mails/MailHandler.cpp`
27. `src/game/Quests/QuestHandler.cpp`
28. `src/game/Reputation/ReputationMgr.cpp`
29. `src/game/Server/DBCStores.cpp`
30. `src/game/Server/DBCStores.h`
31. `src/game/Server/DBCfmt.h`
32. `src/game/Spells/Spell.cpp`
33. `src/game/Spells/SpellHandler.cpp`
34. `src/game/Tools/PlayerDump.cpp`
35. `src/game/World/World.cpp`

Patch footprint characteristics:

- Repeated insertion pattern: `#ifdef ENABLE_MODULES ... sModuleMgr.OnXxx(...) ... #endif`
- Core build wiring edits (`CMakeLists`, options) plus broad gameplay subsystem touch points.

---

## 5) Recommendations: replace modifications with modern extension points

### Decision 1 — Prioritize ScriptMgr-native events first

For all events that already have ScriptMgr equivalents, migrate off ModuleMgr and delete corresponding patch lines.

- Rationale: zero-core-change path for many hooks, immediate footprint reduction.
- Expected impact: remove a large share of call-site injections without feature loss.

### Decision 2 — Keep a thin residual shim only for genuinely missing hooks

For events with no ScriptMgr equivalent (e.g., fall handling, certain mail/loot/AH events), use a minimal, explicit `AchievementHooks` shim with narrowly scoped call sites.

- Rationale: contain unavoidable core deltas to a small audited surface.
- Expected impact: replace broad ModuleMgr framework coupling with narrowly defined achievement extension points.

### Decision 3 — Remove obsolete hooks instead of preserving compatibility paths

Drop hooks with no active criteria path (`OnBuyBackItem`, `OnMailTakeMoney`, dump-table plumbing) rather than carrying legacy patch debt.

- Rationale: patch footprint reduction over legacy compatibility, per issue preference.

### Decision 4 — Remove module-framework hard dependency after migration

Post migration:

- stop inheriting `AchievementsModule` from `Module`
- remove `ENABLE_MODULES` compile definition from this module
- remove include/link dependency on `src/modules/modules/src` and `modules` target

- Rationale: decouple feature module from global framework patch lifecycle.

### Decision 5 — Treat currently failing hunks as migration checkpoints

The 4 reject hunks identify exact drift points where patch-maintenance cost is already material. These should be converted first to ScriptMgr/shim integration points and then removed from classic.patch entirely.

---

## Architectural replacement map (high level)

- `OnRewardQuest` → existing `ScriptMgr::OnQuestComplete` pipeline
- `OnUpdateSkill` → add minimal typed achievement shim if no ScriptMgr equivalent exists
- `OnWorldInitialized` → startup registration point (`ScriptMgr` startup hook / one-time bootstrap)
- Include-only `ModuleMgr.h` dependency in `Player.cpp` should disappear when direct `sModuleMgr` calls are removed

---

## Final notes

- This report intentionally separates **observed failures** from **design recommendations**.
- Recommendations favor architectural modernization and patch reduction over backward-compatibility hacks, as requested.
