# Event Architecture

## Goal

Replace the current tight coupling between the achievements module and the
CMaNGOS core (via the `ModuleMgr` hook layer) with a lightweight,
decoupled event architecture.  The achievements system should **consume
events** rather than injecting logic directly into gameplay systems.

---

## Design Principles

1. **Minimal core footprint** — add the fewest possible lines to the CMaNGOS
   source tree.
2. **Single registration point** — one file in the core registers all event
   subscriptions for the achievements module.
3. **No game-logic in hooks** — hook functions only translate core arguments
   into achievement event payloads and forward them; all decision logic
   remains inside the module.
4. **Compile-time isolation** — if `BUILD_MODULE_ACHIEVEMENTS` is not set,
   zero achievement code is compiled into the core.

---

## Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CMaNGOS Game Core                        │
│  Player, Unit, Spell, BattleGround, Loot, AuctionHouse …    │
│                                                               │
│  Existing ScriptMgr hooks (Category B)                       │
│  Minimal new hooks      (Category A — ~23 call sites)        │
└───────────────────────────┬─────────────────────────────────┘
                             │ translated to typed events
                             ▼
┌─────────────────────────────────────────────────────────────┐
│             AchievementEventDispatcher                        │
│  (registered as a ScriptMgr subscriber + thin shim layer)    │
│                                                               │
│  Receives typed events, validates arguments, and calls        │
│  AchievementsModule::OnEvent(AchievementEvent)               │
└───────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                   AchievementsModule                          │
│  Route to PlayerAchievementMgr::UpdateAchievementCriteria    │
└─────────────────────────────────────────────────────────────┘
```

---

## Proposed Event Catalogue

Each event is a plain C++ struct passed by const reference.  Fields use value
semantics to avoid lifetime issues.

### Player Lifecycle Events

```cpp
struct CharacterCreatedEvent   { ObjectGuid guid; };
struct CharacterDeletedEvent   { uint32 playerId; };
struct PlayerLoginEvent        { Player* player; };
struct PlayerLogoutEvent       { Player* player; };
struct PlayerSaveEvent         { Player* player; };
struct LevelUpEvent            { Player* player; uint32 newLevel; };
```

### Exploration & Travel

```cpp
struct AreaExploredEvent       { Player* player; uint32 areaId; };
struct TaxiFlightStartEvent    { Player* player; uint32 nodeId; bool initial; };
struct TaxiFlightEndEvent      { Player* player; uint32 nodeId; bool finalDest; };
```

### Combat

```cpp
struct CreatureKilledEvent     { Player* player; uint32 creatureEntry; ObjectGuid guid; };
struct PlayerKilledPlayerEvent { Player* killer; Player* victim; };
struct KillingBlowEvent        { Player* player; Unit* victim; };
struct PlayerDeathEvent        { Player* player; Unit* killer; };      // killer may be null
struct EnvDeathEvent           { Player* player; uint8 envDamageType; };
struct FallEvent               { Player* player; float fallHeight; uint32 damage; };
struct DamageDoneEvent         { Unit* dealer; Unit* victim; uint32 damage; };
struct HealingDoneEvent        { Unit* dealer; Unit* victim; uint32 healing; };
```

### Spells & Skills

```cpp
struct SpellLearnedEvent       { Player* player; uint32 spellId; };
struct SpellCastEvent          { Player* caster; Unit* target; uint32 spellId; };
struct SpellHitEvent           { Unit* caster; Unit* target; uint32 spellId; };
struct SkillUpdatedEvent       { Player* player; uint16 skillId; uint32 newValue; };
struct TalentResetEvent        { Player* player; uint32 cost; };
```

### Quests

```cpp
struct QuestCompletedEvent     { Player* player; const Quest* quest; };
struct QuestAbandonedEvent     { Player* player; uint32 questId; };
```

### Items & Loot

```cpp
struct ItemStoredEvent         { Player* player; Item* item; };
struct ItemEquippedEvent       { Player* player; Item* item; uint8 slot; };
struct ItemUsedEvent           { Player* player; Item* item; };
struct ItemCreatedEvent        { Player* player; Item* item; uint32 amount; };
struct ItemLootedEvent         { Player* player; Item* item; };
struct LootGoldEvent           { Player* player; uint32 gold; uint8 lootMethod; };
struct LootRollEvent           { Player* player; uint32 itemEntry; uint8 rollType; };
struct LootRollWonEvent        { Player* player; uint32 itemEntry; uint8 rollType; uint8 rollAmount; };
struct MasterLootGiveEvent     { Player* target; LootItem* lootItem; };
```

### Economy & Social

```cpp
struct MoneyChangedEvent       { Player* player; int32 diff; };
struct BankSlotBoughtEvent     { Player* player; uint32 slot; uint32 price; };
struct ItemSoldToVendorEvent   { Player* player; Item* item; uint32 money; };
struct ReputationChangedEvent  { Player* player; const FactionEntry* faction; int32 standing; bool incremental; };
struct HonorGainedEvent        { Player* player; Unit* victim; };
struct HonorPointsUpdatedEvent { Player* player; };
struct DuelEndEvent            { Player* winner; Player* loser; uint8 type; };
struct EmoteEvent              { Player* player; Unit* target; uint32 emoteId; };
struct TradeCompletedEvent     { Player* player; Player* trader; };
struct SummonAcceptedEvent     { Player* player; ObjectGuid summoner; };
struct MailSentEvent           { Player* sender; ObjectGuid receiver; const MailDraft* mail; uint32 cost; };
struct MailItemTakenEvent      { Player* player; Item* item; ObjectGuid sender; };
struct AuctionCreatedEvent     { Player* player; AuctionEntry* entry; };
struct AuctionBidPlacedEvent   { Player* player; AuctionEntry* entry; uint32 newBid; };
struct AuctionWonEvent         { AuctionEntry* entry; ObjectGuid owner; ObjectGuid bidder; };
struct GroupMemberAddedEvent   { Group* group; Player* player; uint8 method; };
```

### Battleground

```cpp
struct BgStartedEvent          { BattleGround* bg; };
struct BgEndedEvent            { BattleGround* bg; uint32 winnerTeam; };
struct BgPlayerJoinedEvent     { BattleGround* bg; Player* player; };
struct BgPlayerLeftEvent       { BattleGround* bg; Player* player; };
struct BgScoreUpdateEvent      { BattleGround* bg; Player* player; uint8 scoreType; uint32 value; };
struct BgFlagPickedUpEvent     { BattleGround* bg; Player* player; uint32 team; };
```

### Game Objects

```cpp
struct GameObjectUsedEvent     { GameObject* go; Unit* user; };
```

### Addon Protocol

```cpp
struct AddonPageQueryEvent     { Player* player; const WorldPacket* packet; };
```

---

## Dispatcher Design

`AchievementEventDispatcher` is a concrete implementation of the CMaNGOS
`ScriptMgr` player/unit/BG/spell/loot/etc. script interfaces.  It is the
**only** class that touches the CMaNGOS ScriptMgr API.

```cpp
// In the module (not in the core):
class AchievementEventDispatcher
    : public PlayerScript
    , public UnitScript
    , public SpellScript
    , public BattleGroundScript
    , public GameObjectScript
    , public LootScript
    , public GroupScript
{
public:
    // --- Category B replacements (zero new core patch lines) ---
    void OnPlayerLogin(Player* player) override;
    void OnPlayerLogout(Player* player) override;
    void OnPlayerSave(Player* player) override;
    void OnPlayerLevelChanged(Player* player, uint8 oldLevel) override;
    void OnPlayerLearnSpell(Player* player, uint32 spellId) override;
    void OnPlayerDuelEnd(Player* winner, Player* loser, DuelCompleteType type) override;
    void OnPlayerKilledMonsterCredit(Player* player, uint32 entry, ObjectGuid& guid) override;
    void OnPlayerKilledPlayer(Player* killer, Player* victim) override;
    void OnItemAdd(Player* player, Item* item) override;
    void OnPlayerDeath(Player* player, Unit* killer) override;
    void OnItemUse(Player* player, Item* item) override;
    void OnQuestComplete(Player* player, const Quest* quest) override;
    void OnPlayerEmote(Player* player, Unit* target, uint32 emoteId) override;
    void OnPlayerSellItem(Player* player, Item* item, uint32 money) override;
    void OnPlayerExploreArea(Player* player, uint32 areaId) override;
    void OnQuestAbandon(Player* player, uint32 questId) override;
    // ... all other Category B hooks

    // --- Category A thin shims (require minimal new core patch lines) ---
    // Called from the small residual core patch:
    void OnPlayerFall(Player* player, float fallHeight, uint32 damage);
    void OnPlayerReputationChange(Player* player, const FactionEntry*, int32, bool);
    // ... remaining Category A hooks
};
```

The dispatcher translates each call into the appropriate event struct and
forwards it to `AchievementsModule::DispatchEvent(event)`.

---

## Registration

A single file in the core conditionally includes and registers the dispatcher:

```cpp
// src/game/AchievementHooks.cpp  (added to CMaNGOS source tree by the patch)
#ifdef ENABLE_ACHIEVEMENTS
#include "modules/achievements/src/AchievementEventDispatcher.h"

void RegisterAchievementHooks()
{
    new AchievementEventDispatcher();  // self-registers with ScriptMgr
}
#endif
```

`RegisterAchievementHooks()` is called once from `World::LoadGameObjects` or
the equivalent startup sequence via a single `#ifdef ENABLE_ACHIEVEMENTS` guard.

This means the **entire residual core patch** is:

1. One new source file (`AchievementHooks.cpp`) — ~50 lines.
2. One call site addition per Category A hook — ~23 single-line additions
   scattered across the core.
3. One call to `RegisterAchievementHooks()` in the startup sequence.

Compare to the original patch which modifies dozens of files with multiple
call sites each.

---

## Event Flow Example: Quest Completed

**Before (current architecture):**
```
Player::RewardQuest
  └─> ModuleMgr::OnRewardQuest(player, quest)     [patch call]
        └─> AchievementsModule::OnRewardQuest(player, quest)
              └─> mgr->UpdateAchievementCriteria(COMPLETE_QUEST, questId, ...)
```

**After (new architecture):**
```
Player::RewardQuest
  └─> ScriptMgr::OnQuestComplete(player, quest)   [existing ScriptMgr call — no new patch]
        └─> AchievementEventDispatcher::OnQuestComplete(player, quest)
              └─> AchievementsModule::DispatchEvent(QuestCompletedEvent{player, quest})
                    └─> mgr->UpdateAchievementCriteria(COMPLETE_QUEST, questId, ...)
```

The core is unchanged for Category B events.

---

## Migration Strategy

### Step 1 — Parallel registration

Keep the existing `ModuleMgr` hooks and add `ScriptMgr` subscriptions for
Category B events.  Add guards to prevent double-counting.

### Step 2 — Remove Category B `ModuleMgr` call sites from the patch

For each Category B hook, delete the `ModuleMgr::CallHook` line from the
patch.  The `ScriptMgr` call that already exists handles the event.

### Step 3 — Migrate Category A hooks to thin shim functions

Replace the `Module`-style virtual calls for Category A hooks with direct
calls to named free functions (e.g. `AchievementHooks::OnPlayerFall`).  These
functions are declared in a single header guarded by `ENABLE_ACHIEVEMENTS`.

### Step 4 — Remove Category C hooks

Delete `OnBuyBackItem`, `OnMailTakeMoney`, and `OnWriteDump`/`IsModuleDumpTable`
entirely, both from the module and from the patch.

### Step 5 — Remove the `Module` base class dependency

Once all hooks are routed through either the `ScriptMgr` dispatcher or the
thin Category A shims, `AchievementsModule` no longer needs to inherit from
`Module`.  The cmangos-modules framework dependency can be dropped entirely.

---

## Criteria Type → Event Mapping

The table below records which achievement criteria types are triggered by which
events, for reference during migration.

| Criteria Type | Triggering Event |
|---------------|-----------------|
| `KILL_CREATURE` | `CreatureKilledEvent` |
| `WIN_BG` | `BgEndedEvent` |
| `REACH_LEVEL` | `LevelUpEvent` |
| `REACH_SKILL_LEVEL` | `SkillUpdatedEvent` |
| `COMPLETE_ACHIEVEMENT` | Internal (on achievement completion) |
| `COMPLETE_QUEST_COUNT` | `QuestCompletedEvent` |
| `COMPLETE_DAILY_QUEST_DAILY` | `QuestCompletedEvent` |
| `COMPLETE_QUESTS_IN_ZONE` | `QuestCompletedEvent` |
| `DAMAGE_DONE` | `DamageDoneEvent` |
| `COMPLETE_DAILY_QUEST` | `QuestCompletedEvent` |
| `COMPLETE_BATTLEGROUND` | `BgEndedEvent` |
| `DEATH_AT_MAP` | `PlayerDeathEvent` |
| `DEATH` | `PlayerDeathEvent` |
| `DEATH_IN_DUNGEON` | `PlayerDeathEvent` |
| `COMPLETE_RAID` | `BgEndedEvent` |
| `KILLED_BY_CREATURE` | `PlayerDeathEvent` |
| `KILLED_BY_PLAYER` | `PlayerDeathEvent` |
| `FALL_WITHOUT_DYING` | `FallEvent` |
| `DEATHS_FROM` | `EnvDeathEvent` |
| `COMPLETE_QUEST` | `QuestCompletedEvent` |
| `BE_SPELL_TARGET` / `BE_SPELL_TARGET2` | `SpellHitEvent` (target) |
| `CAST_SPELL` / `CAST_SPELL2` | `SpellCastEvent` |
| `BG_OBJECTIVE_CAPTURE` | `BgScoreUpdateEvent` / `BgFlagPickedUpEvent` |
| `HONORABLE_KILL_AT_AREA` | `HonorGainedEvent` |
| `WIN_ARENA` | `BgEndedEvent` |
| `PLAY_ARENA` | `BgEndedEvent` |
| `LEARN_SPELL` | `SpellLearnedEvent` |
| `HONORABLE_KILL` | `HonorGainedEvent` |
| `OWN_ITEM` | `ItemStoredEvent` |
| `LEARN_SKILL_LEVEL` | `SkillUpdatedEvent` |
| `USE_ITEM` | `ItemUsedEvent` |
| `LOOT_ITEM` | `ItemLootedEvent` |
| `EXPLORE_AREA` | `AreaExploredEvent` |
| `OWN_RANK` | `HonorPointsUpdatedEvent` |
| `BUY_BANK_SLOT` | `BankSlotBoughtEvent` |
| `GAIN_REPUTATION` | `ReputationChangedEvent` |
| `GAIN_EXALTED_REPUTATION` | `ReputationChangedEvent` |
| `EQUIP_EPIC_ITEM` | `ItemEquippedEvent` |
| `ROLL_NEED_ON_LOOT` / `ROLL_GREED_ON_LOOT` | `LootRollEvent` |
| `HK_CLASS` / `HK_RACE` | `PlayerKilledPlayerEvent` |
| `DO_EMOTE` | `EmoteEvent` |
| `HEALING_DONE` | `HealingDoneEvent` |
| `GET_KILLING_BLOWS` | `KillingBlowEvent` |
| `EQUIP_ITEM` | `ItemEquippedEvent` |
| `MONEY_FROM_VENDORS` | `ItemSoldToVendorEvent` |
| `GOLD_SPENT_FOR_TALENTS` | `TalentResetEvent` |
| `NUMBER_OF_TALENT_RESETS` | `TalentResetEvent` |
| `MONEY_FROM_QUEST_REWARD` | `QuestCompletedEvent` |
| `GOLD_SPENT_FOR_TRAVELLING` | `TaxiFlightEndEvent` |
| `GOLD_SPENT_FOR_MAIL` | `MailSentEvent` |
| `LOOT_MONEY` | `LootGoldEvent` |
| `USE_GAMEOBJECT` | `GameObjectUsedEvent` |
| `SPECIAL_PVP_KILL` | `KillingBlowEvent` |
| `FISH_IN_GAMEOBJECT` | `GameObjectUsedEvent` |
| `LEARN_SKILLLINE_SPELLS` | `SpellLearnedEvent` |
| `WIN_DUEL` / `LOSE_DUEL` | `DuelEndEvent` |
| `KILL_CREATURE_TYPE` | `KillingBlowEvent` |
| `GOLD_EARNED_BY_AUCTIONS` | `AuctionWonEvent` |
| `CREATE_AUCTION` | `AuctionCreatedEvent` |
| `HIGHEST_AUCTION_BID` | `AuctionBidPlacedEvent` |
| `WON_AUCTIONS` | `AuctionWonEvent` |
| `HIGHEST_AUCTION_SOLD` | `AuctionCreatedEvent` |
| `HIGHEST_GOLD_VALUE_OWNED` | `MoneyChangedEvent` |
| `LOOT_EPIC_ITEM` | `ItemLootedEvent` |
| `RECEIVE_EPIC_ITEM` | `ItemStoredEvent` / `MailItemTakenEvent` |
| `ROLL_NEED` / `ROLL_GREED` | `LootRollWonEvent` |
| `FLIGHT_PATHS_TAKEN` | `TaxiFlightEndEvent` |
| `LOOT_TYPE` | `LootGoldEvent` |
| `EARN_HONORABLE_KILL` | `HonorGainedEvent` |
| `ACCEPTED_SUMMONINGS` | `SummonAcceptedEvent` |
| `JOINED_GROUP` | `GroupMemberAddedEvent` |
| `MAIL_ITEMS` / `MAIL_GOLD` | `MailSentEvent` |
| `TRADES_DONE` | `TradeCompletedEvent` |
| `NON_CRAFTED_ITEMS_USED` | `ItemUsedEvent` |

---

## Residual Core Patch (Target State)

After full migration, the only required core modifications are:

### New call sites (Category A — ~23 additions)

| Location | Call | Lines |
|----------|------|-------|
| `Player::HandleFall` | `AchievementHooks::OnPlayerFall` | 1 |
| `Player::resetTalents` | `AchievementHooks::OnTalentReset` | 1 |
| `Player::EnvironmentalDamage` (death path) | `AchievementHooks::OnEnvDeath` | 1 |
| `WorldSession::HandlePageTextQueryOpcode` | `AchievementHooks::OnAddonPageQuery` | 1 |
| `Player::UpdateSkillPro` | `AchievementHooks::OnSkillUpdate` | 1 |
| `Player::EquipItem` | `AchievementHooks::OnEquipItem` | 1 |
| `Taxi::Tracker` start | `AchievementHooks::OnTaxiStart` | 1 |
| `Taxi::Tracker` end | `AchievementHooks::OnTaxiEnd` | 1 |
| `Player::SetFactionReputation` | `AchievementHooks::OnReputationChange` | 1 |
| `Player::BuyBankSlot` | `AchievementHooks::OnBuyBankSlot` | 1 |
| `Player::ModifyMoney` | `AchievementHooks::OnMoneyChange` | 1 |
| `Player::SummonIfPossible` | `AchievementHooks::OnSummon` | 1 |
| `Player::SetHonorPoints` | `AchievementHooks::OnHonorUpdate` | 1 |
| `TradeHandler::HandleAcceptTradeOpcode` | `AchievementHooks::OnTradeAccepted` | 1 |
| `MailHandler::HandleSendMail` | `AchievementHooks::OnMailSent` | 1 |
| `MailHandler::HandleMailTakeItem` | `MailHandler::OnMailTakeItem` | 1 |
| `BattleGround::UpdatePlayerScore` | `AchievementHooks::OnBgScoreUpdate` | 1 |
| `BattleGroundWS::EventPlayerClickedOnFlag` | `AchievementHooks::OnFlagPickUp` | 1 |
| `LootHandler::HandleLootMasterGiveOpcode` | `AchievementHooks::OnMasterLootGive` | 1 |
| `LootHandler::HandleLootRoll` | `AchievementHooks::OnLootRoll` | 1 |
| Roll resolution | `AchievementHooks::OnLootRollWon` | 1 |
| `Loot::NotifyMoneyRemoved` | `AchievementHooks::OnLootGold` | 1 |
| Auction house handlers (3) | 3 × `AchievementHooks::OnAuction*` | 3 |

### New files (added to core by patch)

- `src/game/AchievementHooks.h` — declarations of all Category A shim functions
- `src/game/AchievementHooks.cpp` — thin wrappers forwarding to the module

### CMakeLists change

One `target_include_directories` and `target_link_libraries` addition to wire
the achievements module into the server binary when `ENABLE_ACHIEVEMENTS` is
set.

### Total residual patch size

- 2 new files (~100 lines total)
- ~25 single-line call-site additions
- 1 CMakeLists modification

This is a **~90% reduction** from the original `classic.patch` which modifies
dozens of files with multiple call sites each.
