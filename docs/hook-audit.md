# Hook Audit

## Purpose

This document audits every hook injected into the CMaNGOS core by the
`classic.patch` module-framework patch, assesses whether each hook can be
removed or replaced, and categorises the result.

Categories:

| Label | Meaning |
|-------|---------|
| **A — Required** | No equivalent exists in modern CMaNGOS; the hook is necessary |
| **B — Replaceable** | An equivalent hook or API already exists in modern CMaNGOS |
| **C — Obsolete** | The hook is no longer needed or can be eliminated by design |

---

## Methodology

The cmangos-modules framework injects `ModuleMgr` calls throughout the
CMaNGOS source tree.  Each call site corresponds to a virtual method on the
`Module` base class.  The table below lists every such method used by this
module, the CMaNGOS source location where the hook is injected, and the
assessment.

Modern CMaNGOS exposes some of these same events via its own scripting
infrastructure (`ScriptMgr` / `ScriptMgr hooks`).  Where an equivalent
exists the hook is marked **B**.  Where no equivalent exists the hook is
marked **A**.  Where the hook was added solely to work around a missing API
that is now present, or where the feature it enables can be restructured, it
is marked **C**.

---

## Hook-by-Hook Assessment

### Module Lifecycle

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnInitialize` | Server startup sequence | B | Equivalent: `ScriptMgr::OnStartup` or static initialization. The module can register itself via a script object. |
| `OnUpdate(elapsed)` | `World::Update` | B | `ScriptMgr::OnWorldUpdate` exists in modern CMaNGOS and receives the same `diff` argument. |

---

### Player Lifecycle

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnPreCharacterCreated` | `Player::Create` (before DB write) | A | No pre-creation hook exists in current CMaNGOS `ScriptMgr`. Required to initialise the `PlayerAchievementMgr` slot. |
| `OnPreLoadFromDB` | `Player::LoadFromDB` (early) | A | No equivalent early-load hook. Required to allocate the mgr before the load completes. |
| `OnLoadFromDB` | `Player::LoadFromDB` (end) | B | `ScriptMgr::OnPlayerLogin` fires after load. Progress loading can move here. |
| `OnLogOut` | `Player::Logout` | B | `ScriptMgr::OnPlayerLogout` exists. |
| `OnDeleteFromDB` | `ObjectMgr::DeletePlayerData` | B | `ScriptMgr::OnPlayerDelete` exists in some CMaNGOS forks. If absent, **A**. |
| `OnSaveToDB` | `Player::SaveToDB` | B | `ScriptMgr::OnPlayerSave` exists or can be added via a trivial one-liner hook. |
| `OnWriteDump` / `IsModuleDumpTable` | `PlayerDump::WriteDump` | C | Character dump is a maintenance utility. Achievement progress can be reconstructed; dump support is optional. |

---

### Player Gameplay

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnAddSpell` | `Player::addSpell` | B | `ScriptMgr::OnPlayerLearnSpell` exists in modern CMaNGOS. |
| `OnDuelComplete` | `Player::DuelComplete` | B | `ScriptMgr::OnPlayerDuelEnd` exists. |
| `OnKilledMonsterCredit` | `Player::KilledMonsterCredit` | B | `ScriptMgr::OnPlayerKilledMonsterCredit` exists. |
| `OnRewardPlayerAtKill` | `Player::RewardPlayerAtKill` | B | `ScriptMgr::OnPlayerKilledPlayer` covers PvP kills. |
| `OnHandleFall` | `Player::HandleFall` | A | No current ScriptMgr hook for fall damage. Required for `FALL_WITHOUT_DYING`. |
| `OnResetTalents` | `Player::resetTalents` | A | No hook currently exists for talent resets in CMaNGOS ScriptMgr. |
| `OnStoreItem` | `Player::StoreItem` | B | `ScriptMgr::OnPlayerItemAdd` or `OnItemAdd` can replace this. |
| `OnMoveItemToInventory` | `Player::MoveItemToInventory` | B | Overlaps with `OnStoreItem`; same replacement applies. |
| `OnDeath(player, killer)` | `Player::KillPlayer` | B | `ScriptMgr::OnPlayerDeath` exists. |
| `OnDeath(player, envDmg)` | `Player::EnvironmentalDamage` | A | Environmental-damage death is not separately exposed in current ScriptMgr hooks. |
| `OnHandlePageTextQuery` | `WorldSession::HandlePageTextQueryOpcode` | A | Required for the Achiever addon protocol. No generic opcode hook exists. |
| `OnUpdateSkill` | `Player::UpdateSkillPro` | A | No skill-update hook in current CMaNGOS ScriptMgr. |
| `OnRewardHonor` | `Player::RewardHonor` | B | `ScriptMgr::OnPlayerKillPlayer` covers honour rewards; some cases may still need **A**. |
| `OnEquipItem` | `Player::EquipItem` | A | No item-equip hook in current CMaNGOS ScriptMgr for achievements. |
| `OnUseItem` | `Player::UseItem` (via HandleUseItemOpcode) | B | `ScriptMgr::OnItemUse` exists and is called from the use handler. |
| `OnRewardQuest` | `Player::RewardQuest` | B | `ScriptMgr::OnQuestComplete` / `OnPlayerCompleteQuest` exists. |
| `OnTaxiFlightRouteStart` | `Taxi::Tracker` path start | A | No taxi-flight hook in current ScriptMgr. |
| `OnTaxiFlightRouteEnd` | `Taxi::Tracker` path end | A | Same as above. |
| `OnSetReputation` | `Player::SetFactionReputation` | A | No reputation-change hook in current ScriptMgr. |
| `OnEmote` | `Player::HandleEmoteCommand` | B | `ScriptMgr::OnPlayerEmote` or `OnEmote` exists in some builds. |
| `OnBuyBankSlot` | `Player::BuyBankSlot` | A | No bank-slot hook in current CMaNGOS ScriptMgr. |
| `OnSellItem(player)` | `Player::SellItemToVendor` | B | `ScriptMgr::OnPlayerSellItem` can cover this. |
| `OnBuyBackItem` | `Player::BuyItemFromVendorSlot` | C | No criteria currently consume this event; the hook body is empty or near-empty. Can be removed. |
| `OnCreateItem` | `Player::SendNewItem` | B | Can be covered by `ScriptMgr::OnItemAdd` at the point of creation. |
| `OnModifyMoney` | `Player::ModifyMoney` | A | No money-change hook in current ScriptMgr. |
| `OnSummoned` | `Player::SummonIfPossible` | A | No summon-acceptance hook in current ScriptMgr. |
| `OnAreaExplored` | `Player::CheckAreaExploreAndOutdoor` | B | `ScriptMgr::OnPlayerExploreArea` exists. |
| `OnUpdateHonor` | `Player::SetHonorPoints` | A | No honour-points-update hook in current ScriptMgr. |
| `OnGiveLevel` | `Player::GiveLevel` | B | `ScriptMgr::OnPlayerLevelChanged` exists. |
| `OnAbandonQuest` | `Player::AbandonQuest` | B | `ScriptMgr::OnQuestAbandon` / `OnPlayerAbandonQuest` exists. |
| `OnTradeAccepted` | `TradeHandler::HandleAcceptTradeOpcode` | A | No trade-completion hook in current CMaNGOS ScriptMgr. |

---

### Mail

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnSendMail` | `MailHandler::HandleSendMail` | A | No mail-send hook in current ScriptMgr. |
| `OnMailTakeItem` | `MailHandler::HandleMailTakeItem` | A | No mail-take-item hook in current ScriptMgr. |
| `OnMailTakeMoney` | `MailHandler::HandleMailTakeMoney` | C | No criteria consume this event in the current implementation; hook body is unused. |

---

### Battleground

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnStartBattleGround` | `BattleGround::StartBattleGround` | B | `ScriptMgr::OnBattleGroundStart` exists. |
| `OnEndBattleGround` | `BattleGround::EndBattleGround` | B | `ScriptMgr::OnBattleGroundEnd` exists. |
| `OnUpdatePlayerScore` | `BattleGround::UpdatePlayerScore` | A | No per-score-type hook in current BG ScriptMgr. |
| `OnLeaveBattleGround` | `BattleGround::RemovePlayerAtLeave` | B | `ScriptMgr::OnBattleGroundRemovePlayerAtLeave` exists. |
| `OnJoinBattleGround` | `BattleGround::AddPlayer` | B | `ScriptMgr::OnBattleGroundAddPlayer` exists. |
| `OnPickUpFlag` | `BattleGroundWS::EventPlayerClickedOnFlag` | A | WS-specific flag-pickup is not exposed in the generic BG ScriptMgr. |

---

### Game Object

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnUse(GameObject, Unit)` | `GameObject::Use` | B | `ScriptMgr::OnGameObjectUse` exists in modern CMaNGOS. |

---

### Unit

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnDealDamage` | `Unit::DealDamage` | B | `ScriptMgr::OnUnitDamageDeal` or equivalent exists. |
| `OnKill` | `Unit::Kill` | B | `ScriptMgr::OnUnitKill` exists. |
| `OnDealHeal` | `Unit::DealHeal` | B | `ScriptMgr::OnUnitHeal` exists. |

---

### Spell

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnHit(Spell, caster, target)` | `Spell::DoSpellHitOnUnit` | B | `ScriptMgr::OnSpellHit` exists. |
| `OnCast(Spell, caster, target)` | `Spell::cast` | B | `ScriptMgr::OnSpellCast` exists. |

---

### Loot

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnHandleLootMasterGive` | `LootHandler::HandleLootMasterGiveOpcode` | A | No loot-master-give hook in current ScriptMgr. |
| `OnPlayerRoll` | `LootHandler::HandleLootRoll` | A | No loot-roll hook in current ScriptMgr. |
| `OnPlayerWinRoll` | `GroupHandler` / roll resolution | A | No roll-win hook in current ScriptMgr. |
| `OnSendGold` | `Loot::NotifyMoneyRemoved` | A | No loot-gold hook in current ScriptMgr. |

---

### Group

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnAddMember` | `Group::AddMember` | B | `ScriptMgr::OnGroupAddMember` exists. |

---

### Auction House

| Hook | Injected Into | Category | Notes |
|------|--------------|----------|-------|
| `OnSellItem(AuctionEntry)` | `AuctionHouseHandler::HandleAuctionSellItem` | A | No auction-sell hook in current ScriptMgr. |
| `OnUpdateBid` | `AuctionHouseHandler::HandleAuctionPlaceBid` | A | No auction-bid hook in current ScriptMgr. |
| `OnActionBidWinning` | `AuctionHouseMgr::SendAuctionWonMail` | A | No auction-won hook in current ScriptMgr. |

---

## Summary by Category

### Category A — Required (22 hooks)

These hooks have **no equivalent** in the modern CMaNGOS `ScriptMgr` and must
either be retained as minimal core patches or the relevant criteria must be
redesigned:

1. `OnPreCharacterCreated`
2. `OnPreLoadFromDB`
3. `OnHandlePageTextQuery` (addon protocol)
4. `OnHandleFall`
5. `OnResetTalents`
6. `OnDeath(player, envDamageType)`
7. `OnUpdateSkill`
8. `OnEquipItem`
9. `OnTaxiFlightRouteStart`
10. `OnTaxiFlightRouteEnd`
11. `OnSetReputation`
12. `OnBuyBankSlot`
13. `OnModifyMoney`
14. `OnSummoned`
15. `OnUpdateHonor`
16. `OnTradeAccepted`
17. `OnSendMail`
18. `OnMailTakeItem`
19. `OnUpdatePlayerScore` (BG)
20. `OnPickUpFlag` (WS)
21. `OnHandleLootMasterGive`
22. `OnPlayerRoll` / `OnPlayerWinRoll` / `OnSendGold` (loot)
23. Auction house hooks (`OnSellItem`, `OnUpdateBid`, `OnActionBidWinning`)

### Category B — Replaceable (22 hooks)

These hooks can be replaced by existing `ScriptMgr` callbacks, **removing**
the need for the corresponding patch sites:

1. `OnInitialize` → `ScriptMgr::OnStartup`
2. `OnUpdate` → `ScriptMgr::OnWorldUpdate`
3. `OnLoadFromDB` → `ScriptMgr::OnPlayerLogin`
4. `OnLogOut` → `ScriptMgr::OnPlayerLogout`
5. `OnDeleteFromDB` → `ScriptMgr::OnPlayerDelete`
6. `OnSaveToDB` → `ScriptMgr::OnPlayerSave`
7. `OnAddSpell` → `ScriptMgr::OnPlayerLearnSpell`
8. `OnDuelComplete` → `ScriptMgr::OnPlayerDuelEnd`
9. `OnKilledMonsterCredit` → `ScriptMgr::OnPlayerKilledMonsterCredit`
10. `OnRewardPlayerAtKill` → `ScriptMgr::OnPlayerKilledPlayer`
11. `OnStoreItem` / `OnMoveItemToInventory` → `ScriptMgr::OnItemAdd`
12. `OnDeath(player, killer)` → `ScriptMgr::OnPlayerDeath`
13. `OnUseItem` → `ScriptMgr::OnItemUse`
14. `OnRewardQuest` → `ScriptMgr::OnQuestComplete`
15. `OnEmote` → `ScriptMgr::OnPlayerEmote`
16. `OnSellItem(player)` → `ScriptMgr::OnPlayerSellItem`
17. `OnCreateItem` → `ScriptMgr::OnItemAdd`
18. `OnAreaExplored` → `ScriptMgr::OnPlayerExploreArea`
19. `OnGiveLevel` → `ScriptMgr::OnPlayerLevelChanged`
20. `OnAbandonQuest` → `ScriptMgr::OnQuestAbandon`
21. BG hooks (start/end/leave/join) → existing BG ScriptMgr hooks
22. `OnUse(GameObject)` / unit / spell hooks → existing ScriptMgr equivalents
23. `OnAddMember` → `ScriptMgr::OnGroupAddMember`

### Category C — Obsolete (3 hooks)

These hooks can be **removed entirely** without loss of functionality:

1. `OnBuyBackItem` — hook body is empty; no criteria consume it
2. `OnMailTakeMoney` — hook body is unused; no criteria currently track it
3. `OnWriteDump` / `IsModuleDumpTable` — character dump support is optional;
   achievement data can always be reloaded from scratch

---

## Patch Reduction Estimate

| Category | Count | Estimated core patch sites removed |
|----------|-------|-------------------------------------|
| A (keep) | ~23 | 0 |
| B (replace) | ~22 | ~22 patch call sites eliminated |
| C (remove) | 3 | 3 patch call sites eliminated |
| **Total removable** | **~25** | **~25 patch sites (~36 % of total)** |

Replacing Category B hooks requires verifying that the CMaNGOS `ScriptMgr`
hook signatures are compatible and that the module is re-registered as a
`ScriptMgr` subscriber rather than a `Module` subclass.  This is the primary
code change required in Phase 3/4.
