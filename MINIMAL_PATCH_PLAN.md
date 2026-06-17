# Minimal Patch Plan

## Design: `AchievementHooks` Interface

Rather than reviving the generic `Module` / `sModuleMgr` dispatcher, we introduce a
single, achievement-specific observer class.  The CMaNGOS core only needs to know one
header; the achievement module provides the sole implementation.

### Proposed `AchievementHooks` API

```cpp
// src/AchievementHooks.h  (lives inside the achievements module, not in the core)
#pragma once

// Forward-declare only the types that appear in hook signatures.
class Player; class Unit; class Spell; class Item; class Quest;
class BattleGround; class BattleGroundWS; class GameObject;
class Group; class AuctionEntry; class MailDraft; struct Mail;
struct LootItem; class Loot; struct TradeData;
class ObjectGuid; struct MovementInfo; struct FactionEntry;
namespace Taxi { class Tracker; }

class AchievementHooks
{
public:
    static AchievementHooks& Instance();   // returns the one registered impl

    // --- World lifecycle ---
    virtual void OnWorldInitialized() {}
    virtual void OnWorldUpdated(uint32 elapsed) {}

    // --- Player lifecycle ---
    virtual void OnPlayerCreate(Player* player) {}
    virtual void OnPlayerPreLoadFromDB(Player* player) {}
    virtual void OnPlayerLoadFromDB(Player* player) {}
    virtual void OnPlayerLogOut(Player* player) {}
    virtual void OnPlayerSaveToDB(Player* player) {}
    virtual void OnPlayerDeleteFromDB(uint32 playerId) {}

    // --- Player gameplay ---
    virtual void OnGiveLevel(Player* player, uint32 level) {}
    virtual void OnUpdateSkill(Player* player, uint16 skillId) {}
    virtual void OnAddSpell(Player* player, uint32 spellId) {}
    virtual void OnResetTalents(Player* player, uint32 cost) {}
    virtual void OnDuelComplete(Player* player, Player* opponent, uint8 type) {}
    virtual void OnKilledMonsterCredit(Player* player, uint32 entry, ObjectGuid& guid) {}
    virtual void OnRewardPlayerAtKill(Player* player, Unit* victim) {}
    virtual void OnHandleFall(Player* player, const MovementInfo& movementInfo,
                              float lastFallZ, uint32 damage) {}
    virtual bool OnHandlePageTextQuery(Player* player, const WorldPacket& packet)
                              { return false; }
    virtual void OnDeath(Player* player, Unit* killer) {}
    virtual void OnDeath(Player* player, uint8 environmentalDamageType) {}
    virtual void OnModifyMoney(Player* player, int32 diff) {}
    virtual void OnRewardHonor(Player* player, Unit* victim) {}
    virtual void OnUpdateHonor(Player* player) {}
    virtual void OnAreaExplored(Player* player, uint32 areaId) {}
    virtual void OnSummoned(Player* player, const ObjectGuid& summoner) {}
    virtual void OnStoreItem(Player* player, Item* item) {}
    virtual void OnEquipItem(Player* player, Item* item) {}
    virtual bool OnUseItem(Player* player, Item* item) { return false; }
    virtual void OnMoveItemToInventory(Player* player, Item* item) {}
    virtual void OnCreateItem(Player* player, Item* item, uint32 amount) {}
    virtual void OnRewardQuest(Player* player, const Quest* quest) {}
    virtual void OnAbandonQuest(Player* player, uint32 questId) {}
    virtual void OnTaxiFlightRouteStart(Player* player,
                              const Taxi::Tracker& taxiTracker, bool initial) {}
    virtual void OnTaxiFlightRouteEnd(Player* player,
                              const Taxi::Tracker& taxiTracker, bool final) {}
    virtual void OnSetReputation(Player* player, const FactionEntry* factionEntry,
                              int32 standing, bool incremental) {}
    virtual void OnEmote(Player* player, Unit* target, uint32 emote) {}
    virtual void OnBuyBankSlot(Player* player, uint32 slot, uint32 price) {}
    virtual void OnSellItem(Player* player, Item* item, uint32 money) {}
    virtual void OnTradeAccepted(Player* player, Player* trader,
                              TradeData* playerTrade, TradeData* traderTrade) {}

    // --- Battleground ---
    virtual void OnStartBattleGround(BattleGround* bg) {}
    virtual void OnEndBattleGround(BattleGround* bg, uint32 winnerTeam) {}
    virtual void OnLeaveBattleGround(BattleGround* bg, Player* player) {}
    virtual void OnJoinBattleGround(BattleGround* bg, Player* player) {}
    virtual void OnUpdatePlayerScore(BattleGround* bg, Player* player,
                              uint8 scoreType, uint32 value) {}
    virtual void OnPickUpFlag(BattleGroundWS* bg, Player* player, uint32 team) {}

    // --- GameObject ---
    virtual bool OnGameObjectUse(GameObject* go, Unit* user) { return false; }

    // --- Unit ---
    virtual void OnDealDamage(Unit* dealer, Unit* victim,
                              uint32 health, uint32 damage) {}
    virtual void OnKill(Unit* killer, Unit* victim) {}
    virtual void OnDealHeal(Unit* dealer, Unit* victim,
                              int32 gain, uint32 addHealth) {}

    // --- Spell ---
    virtual void OnSpellHit(Spell* spell, Unit* caster, Unit* target) {}
    virtual void OnSpellCast(Spell* spell, Unit* caster, Unit* target) {}

    // --- Loot ---
    virtual void OnHandleLootMasterGive(Loot* loot, Player* target,
                              LootItem* lootItem) {}
    virtual void OnPlayerRoll(Loot* loot, Player* player,
                              uint32 itemSlot, uint8 rollType) {}
    virtual void OnPlayerWinRoll(Loot* loot, Player* player, uint8 rollType,
                              uint8 rollAmount, uint32 itemSlot,
                              uint8 inventoryResult) {}
    virtual void OnSendGold(Loot* loot, Player* player,
                              uint32 gold, uint8 lootMethod) {}

    // --- Group ---
    virtual void OnAddMember(Group* group, Player* player, uint8 method) {}

    // --- Auction ---
    virtual void OnAuctionSellItem(AuctionEntry* entry, Player* player) {}
    virtual void OnAuctionUpdateBid(AuctionEntry* entry,
                              Player* player, uint32 newBid) {}
    virtual void OnAuctionBidWinning(AuctionEntry* entry,
                              const ObjectGuid& owner,
                              const ObjectGuid& bidder) {}

    // --- Mail ---
    virtual void OnSendMail(const MailDraft& mail, Player* player,
                              const ObjectGuid& receiver, uint32 cost) {}
    virtual void OnMailTakeItem(Mail* mail, Player* player,
                              Item* item, const ObjectGuid& sender) {}

protected:
    AchievementHooks() = default;
    virtual ~AchievementHooks() = default;
};

#define sAchievementHooks AchievementHooks::Instance()
```

`AchievementsModule` inherits `AchievementHooks` and overrides every method.
`AchievementHooks::Instance()` returns a pointer set at module startup, defaulting to
a no-op base implementation so the core never hard-crashes if the module is disabled.

---

## CMaNGOS Source Locations to Patch

The table below lists every file that needs a call site, with one row per
insertion point.  The **Action** column uses three codes:

- **KEEP** – call site exists in `classic.patch`; update to call `sAchievementHooks` instead of `sModuleMgr`
- **ADD**  – call site does not exist in `classic.patch`; must be added
- **DROP** – call site exists in `classic.patch` but has no achievement consumer; omit entirely from new patch

### `CMakeLists.txt` (root)

| Hunk area | Action | Notes |
|-----------|--------|-------|
| Module registry / FetchContent block | DROP | Entire `BUILD_MODULES` infrastructure |
| Per-module option loop | DROP | |
| `add_subdirectory(src/modules/achievements)` | KEEP | Simplified one-liner; no FetchContent |

### `cmake/options.cmake`

| Hunk area | Action | Notes |
|-----------|--------|-------|
| `BUILD_MODULES` option | DROP | |
| `BUILD_MODULE_ACHIEVEMENTS` option | KEEP | Rename to `BUILD_ACHIEVEMENTS` |

### `cmake/showoptions.cmake`

| Hunk area | Action | Notes |
|-----------|--------|-------|
| `BUILD_MODULES` status line | DROP | |
| Per-module status loop | DROP | |
| `BUILD_ACHIEVEMENTS` status line | KEEP | Simple one-liner |

### `src/CMakeLists.txt`

| Hunk area | Action | Notes |
|-----------|--------|-------|
| Module subdirectory loop | DROP | |
| `add_subdirectory(modules/achievements …)` | KEEP | Guarded by `if(BUILD_ACHIEVEMENTS)` |

### `src/game/CMakeLists.txt`

| Hunk area | Action | Notes |
|-----------|--------|-------|
| `target_link_libraries(game … achievements …)` | KEEP | Link `achievements` static lib into `game` |

### `src/game/World/World.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnWorldPreInitialized()` | DROP | Unused |
| `sModuleMgr.OnWorldInitialized()` | KEEP → `sAchievementHooks.OnWorldInitialized()` | |
| `sModuleMgr.OnWorldUpdated(diff)` | KEEP → `sAchievementHooks.OnWorldUpdated(diff)` | |

### `src/game/Entities/Player.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnCharacterCreated(player)` | DROP | Unused |
| `sModuleMgr.OnPreCharacterCreated(player)` | KEEP | |
| `sModuleMgr.OnGiveXP(…)` | DROP | Unused |
| `sModuleMgr.OnGiveLevel(player, level)` | KEEP | |
| `sModuleMgr.OnDeleteFromDB(playerId)` | KEEP | |
| `sModuleMgr.OnPreResurrect(player)` | DROP | Unused |
| `sModuleMgr.OnResurrect(player)` | DROP | Unused |
| `sModuleMgr.OnReleaseSpirit(player)` | DROP | Unused |
| `sModuleMgr.OnUpdateHonor(player)` | KEEP | |
| `sModuleMgr.OnRewardHonor(player, victim)` | KEEP | |
| `sModuleMgr.OnDuelComplete(player, opponent, type)` | KEEP | |
| `sModuleMgr.OnStoreItem(player, item)` | KEEP | |
| `sModuleMgr.OnEquipItem(player, item)` | KEEP | |
| `sModuleMgr.OnSetVisibleItemSlot(…)` | DROP | Unused |
| `sModuleMgr.OnMoveItemFromInventory(…)` | DROP | Unused |
| `sModuleMgr.OnMoveItemToInventory(player, item)` | KEEP | |
| `sModuleMgr.OnRewardQuest(player, quest)` | KEEP | |
| `sModuleMgr.OnKilledMonsterCredit(player, entry, guid)` | KEEP | |
| `sModuleMgr.OnPreLoadFromDB(player)` | KEEP | |
| `sModuleMgr.OnLoadFromDB(player)` | KEEP | |
| `sModuleMgr.OnSaveToDB(player)` | KEEP | |
| `sModuleMgr.OnLogOut(player)` | KEEP | |
| `sModuleMgr.OnTaxiFlightRouteStart(player, tracker, initial)` | KEEP | |
| `sModuleMgr.OnTaxiFlightRouteEnd(player, tracker, final)` | KEEP | |
| `sModuleMgr.OnSummoned(player, summoner)` | KEEP | |
| `sModuleMgr.OnPreRewardPlayerAtKill(player, victim)` | DROP | Unused |
| `sModuleMgr.OnRewardPlayerAtKill(player, victim)` | KEEP | |
| `sModuleMgr.OnHandleFall(player, movInfo, lastZ, dmg)` | KEEP | |
| `sModuleMgr.OnPreHandleFall(…)` | DROP | Unused |
| `sModuleMgr.OnLearnTalent(…)` | DROP | Unused |
| `sModuleMgr.OnResetTalents(player, cost)` | KEEP | |
| `sModuleMgr.OnAddSpell(player, spellId)` | KEEP | |
| `sModuleMgr.OnUpdateSkill(player, skillId)` | KEEP | *(≥ 3 insertion points for different UpdateSkill paths)* |
| `sModuleMgr.OnAreaExplored(player, areaId)` | KEEP | |
| `sModuleMgr.OnModifyMoney(player, diff)` | KEEP | |
| `sModuleMgr.OnLoadActionButtons(…)` | DROP | Unused |
| `sModuleMgr.OnSaveActionButtons(…)` | DROP | Unused |
| `sModuleMgr.OnDeath(player, killer)` | KEEP | |
| `sModuleMgr.OnDeath(player, envType)` | KEEP | |
| `sModuleMgr.OnGetPlayerLevelInfo(…)` | DROP | Unused |
| `sModuleMgr.OnCreateItem(player, item, amount)` | KEEP | |
| `sModuleMgr.OnAbandonQuest(player, questId)` | KEEP | |
| **`sAchievementHooks.OnTradeAccepted(p, t, pT, tT)`** | **ADD** | In `Player::TradeCancel` or `AcceptTrade` path |

### `src/game/Entities/Player.h`

| Change | Action | Notes |
|--------|--------|-------|
| Remove `friend class Module` (if present) | DROP | |

### `src/game/Entities/Unit.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnDealDamage(…)` | KEEP | |
| `sModuleMgr.OnKill(killer, victim)` | KEEP | |
| `sModuleMgr.OnDealHeal(…)` | KEEP | |
| `sModuleMgr.OnCalculateEffectiveDodgeChance(…)` | DROP | Unused |
| `sModuleMgr.OnCalculateEffectiveParryChance(…)` | DROP | Unused |
| `sModuleMgr.OnCalculateEffectiveBlockChance(…)` | DROP | Unused |
| `sModuleMgr.OnCalculateEffectiveCritChance(…)` | DROP | Unused |
| `sModuleMgr.OnCalculateEffectiveMissChance(…)` | DROP | Unused |
| `sModuleMgr.OnCalculateSpellMissChance(…)` | DROP | Unused |
| `sModuleMgr.OnGetAttackDistance(…)` | DROP | Unused |

### `src/game/BattleGround/BattleGround.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnStartBattleGround(bg)` | KEEP | |
| `sModuleMgr.OnEndBattleGround(bg, winner)` | KEEP | |
| `sModuleMgr.OnLeaveBattleGround(bg, player)` | KEEP | |
| `sModuleMgr.OnJoinBattleGround(bg, player)` | KEEP | |

### `src/game/BattleGround/BattleGroundAB.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnStartBattleGround(bg)` | KEEP | *(AB start doors open)* |
| `sModuleMgr.OnUpdatePlayerScore(bg, player, type, value)` | KEEP | |

### `src/game/BattleGround/BattleGroundAV.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnStartBattleGround(bg)` | KEEP | *(AV start)* |
| `sModuleMgr.OnUpdatePlayerScore(bg, player, type, value)` | KEEP | |

### `src/game/BattleGround/BattleGroundHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnJoinBattleGround(bg, player)` *(area spirit healer path)* | KEEP | |

### `src/game/BattleGround/BattleGroundWS.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnStartBattleGround(bg)` | KEEP | |
| `sModuleMgr.OnPickUpFlag(bg, player, team)` | KEEP | |
| `sModuleMgr.OnUpdatePlayerScore(bg, player, type, value)` | KEEP | |

### `src/game/Entities/GameObject.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnUse(go, user)` | KEEP → `sAchievementHooks.OnGameObjectUse(go, user)` | |
| `sModuleMgr.OnAddToWorld(go)` | DROP | Unused |
| `sModuleMgr.OnRespawn(go)` | DROP | Unused |

### `src/game/Entities/Creature.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnAddToWorld(creature)` | DROP | Unused |
| `sModuleMgr.OnRespawn(creature)` | DROP | Unused |
| `sModuleMgr.OnRespawnRequest(creature)` | DROP | Unused |

### `src/game/Entities/ItemHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnSellItem(player, item, money)` | KEEP | |
| `sModuleMgr.OnBuyBackItem(…)` | DROP | Unused |
| `sModuleMgr.OnUseItem(player, item)` | KEEP | |
| `sModuleMgr.OnBuyBankSlot(player, slot, price)` | KEEP | |
| `sModuleMgr.OnAddItem(…)` | DROP | Unused |

### `src/game/Entities/NPCHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnPreGossipHello(…)` | DROP | Unused |
| `sModuleMgr.OnGossipHello(…)` | DROP | Unused |
| `sModuleMgr.OnGossipSelect(…)` | DROP | Unused |

### `src/game/Chat/Chat.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnExecuteCommand(…)` | DROP | Unused |

### `src/game/Chat/ChatHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnEmote(player, target, emote)` | KEEP | |

### `src/game/Entities/QueryHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnHandlePageTextQuery(player, packet)` | KEEP | |

### `src/game/Spells/Spell.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnHit(spell, caster, target)` | KEEP → `sAchievementHooks.OnSpellHit(…)` | |

### `src/game/Spells/SpellHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnCast(spell, caster, target)` | KEEP → `sAchievementHooks.OnSpellCast(…)` | |

### `src/game/Loot/LootHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnHandleLootMasterGive(loot, target, item)` | KEEP | |
| `sModuleMgr.OnPlayerRoll(loot, player, slot, rollType)` | KEEP | |
| `sModuleMgr.OnPlayerWinRoll(…)` | KEEP | |

### `src/game/Loot/LootMgr.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnFillLoot(…)` | DROP | Unused |
| `sModuleMgr.OnGenerateMoneyLoot(…)` | DROP | Unused |
| `sModuleMgr.OnSendGold(loot, player, gold, method)` | KEEP | |

### `src/game/Groups/Group.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnAddMember(group, player, method)` | KEEP | |

### `src/game/AuctionHouse/AuctionHouseHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnSellItem(auctionEntry, player)` | KEEP → `sAchievementHooks.OnAuctionSellItem(…)` | |

### `src/game/AuctionHouse/AuctionHouseMgr.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnUpdateBid(entry, player, newBid)` | KEEP → `sAchievementHooks.OnAuctionUpdateBid(…)` | |
| **`sAchievementHooks.OnAuctionBidWinning(entry, owner, bidder)`** | **ADD** | In `AuctionEntry::UpdateBid` or `AuctionHouseMgr::Update` when bid wins |

### `src/game/Mails/MailHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnSendMail(mail, player, receiver, cost)` | KEEP | |
| **`sAchievementHooks.OnMailTakeItem(mail, player, item, sender)`** | **ADD** | In `HandleMailTakeItem` after item transfer succeeds |

### `src/game/Quests/QuestHandler.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| *(no surviving hooks from old patch)* | – | All quest hooks now route through `Player::RewardQuest` in `Player.cpp` |

### `src/game/Reputation/ReputationMgr.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnSetReputation(player, faction, standing, incr)` | KEEP | |

### `src/game/Server/DBCStores.cpp` / `.h` / `DBCfmt.h`

| Change | Action | Notes |
|--------|--------|-------|
| DBC store declarations for achievement tables | KEEP | These are genuine data additions, not module-framework boilerplate |

### `src/game/Tools/PlayerDump.cpp`

| Call site | Action | Hook |
|-----------|--------|------|
| `sModuleMgr.OnWriteDump(…)` | DROP | Unused |
| `sModuleMgr.IsModuleDumpTable(…)` | DROP | Unused |

### `src/game/Entities/TradeHandler.cpp` *(new file in patch)*

| Call site | Action | Hook |
|-----------|--------|------|
| **`sAchievementHooks.OnTradeAccepted(player, trader, pTrade, tTrade)`** | **ADD** | In `WorldSession::HandleAcceptTradeOpcode` after trade succeeds |

---

## Summary of Changes vs. Old Patch

| Metric | Old `classic.patch` | New `classic-minimal.patch` |
|--------|--------------------|-----------------------------|
| Total files touched | 35 | ~22 |
| Total hunks | 143 | ~75 |
| Hunks adding unused module calls (DROP) | ~68 | 0 |
| Hunks keeping / updating achievement call sites | ~75 | ~72 |
| New call sites not in old patch (ADD) | 0 | 3 |
| CMake infrastructure hunks | ~13 | ~3 |
| `#include "ModuleManager.h"` additions | 35 | 0 |

---

## Patch Skeleton for the Three New Call Sites

### 1. `src/game/Mails/MailHandler.cpp` – `OnMailTakeItem`

Insert after the item is successfully moved to the player's inventory in
`WorldSession::HandleMailTakeItem`:

```cpp
sAchievementHooks.OnMailTakeItem(m, GetPlayer(), it, ObjectGuid(m->sender));
```

### 2. `src/game/AuctionHouse/AuctionHouseMgr.cpp` – `OnAuctionBidWinning`

Insert in the section that processes a winning bid (inside `AuctionHouseMgr::Update`
or the helper that sends the item to the winner):

```cpp
sAchievementHooks.OnAuctionBidWinning(auctionEntry, auctionEntry->owner, auctionEntry->bidder);
```

### 3. `src/game/Entities/TradeHandler.cpp` – `OnTradeAccepted`

Insert at the end of `WorldSession::HandleAcceptTradeOpcode`, after both sides have
confirmed and items have been transferred:

```cpp
sAchievementHooks.OnTradeAccepted(GetPlayer(), trader,
                                   GetPlayer()->GetTradeData(),
                                   trader->GetTradeData());
// Also call for the other side:
trader->GetSession()->sAchievementHooks.OnTradeAccepted(trader, GetPlayer(),
                                   trader->GetTradeData(),
                                   GetPlayer()->GetTradeData());
```

*(Exact argument names should be confirmed against the current
`cmangos/mangos-classic` source before writing the final patch.)*

---

## Verification Checklist

Before merging the new patch:

- [ ] `AchievementHooks.h` compiles standalone (no implicit Module.h / ModuleMgr.h pull-in)
- [ ] All 55 surviving hook call sites compile against current `mangos-classic` master
- [ ] The 3 new call sites compile and link
- [ ] No `sModuleMgr` reference remains anywhere in the patch
- [ ] `ENABLE_MODULES` is not defined anywhere in the build
- [ ] Achievement DB tables load successfully
- [ ] `OnPreLoadFromDB` fires `ON_LOGIN` criteria on first login
- [ ] Timed achievement for WS battle start fires correctly
