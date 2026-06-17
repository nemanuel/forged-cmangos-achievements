# Core Patch Review

## Purpose

This document provides a mandatory justification record for every call-site
addition that the residual **Category A** core patch would make to the
`cmangos/mangos-classic` source tree.

For each patch site the record states:

1. **Justification** — why the change is necessary.
2. **Alternatives considered** — what was tried or evaluated instead.
3. **Why existing extension points are insufficient** — the specific gap in the
   current `ScriptMgr` API that forces a new call site.

Category B hooks (those with a direct ScriptMgr equivalent) require **no** core
patch at all and are therefore not listed here.  Category C hooks have been
dropped entirely.  Only the ~23 Category A sites that have no existing
ScriptMgr counterpart appear below.

---

## 1. `Player::HandleFall` → `AchievementHooks::OnPlayerFall`

**Justification**
The `FALL_WITHOUT_DYING` criteria requires knowing the damage taken from each
fall and whether the player survived.  Both pieces of information are only
available inside `Player::HandleFall` after the damage is resolved.

**Alternatives considered**
- Subscribing to `ScriptMgr::OnPlayerDeath` and inferring a fall — rejected
  because a player who falls but survives never triggers an `OnPlayerDeath`
  event, so surviving falls can never be credited.
- Using the existing `ScriptMgr::OnUnitDamageDeal` — rejected because that
  hook does not distinguish environmental fall damage from other damage types
  and does not fire at the moment the fall resolves.

**Why existing extension points are insufficient**
`ScriptMgr` has no hook that fires at the end of
`Player::HandleFall` with both the fall height and survival status.  The
nearest approximation (`OnTakeDamage`) does not expose environmental-damage
sub-types in the current codebase.

---

## 2. `Player::resetTalents` → `AchievementHooks::OnTalentReset`

**Justification**
The `GOLD_SPENT_FOR_TALENTS` and `NUMBER_OF_TALENT_RESETS` criteria track
talent-reset events and their cumulative cost.  The gold cost is only
available inside `Player::resetTalents` at the point of deduction.

**Alternatives considered**
- Using `ScriptMgr::OnModifyMoney` or a money-change hook — rejected because
  `ModifyMoney` is called for every gold transaction and carries no
  information about *why* gold was spent; the criteria would require
  correlating two separate events with a fragile state machine.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no `OnPlayerTalentReset` or equivalent hook.
Detecting talent resets from a generic money-change event is unreliable.

---

## 3. `Player::EnvironmentalDamage` (death path) → `AchievementHooks::OnEnvDeath`

**Justification**
The `DEATHS_FROM` criteria tracks deaths caused by specific environmental
damage types (drowning, fatigue, lava, fire, etc.).  The damage type is a
parameter of `Player::EnvironmentalDamage` and is not propagated to generic
death hooks.

**Alternatives considered**
- Using `ScriptMgr::OnPlayerDeath` with a stored "last env-damage type" —
  rejected because `OnPlayerDeath` fires from `Unit::Kill` which does not
  receive the environmental damage sub-type, requiring a per-player side
  channel that is error-prone under lag or multi-damage scenarios.

**Why existing extension points are insufficient**
`ScriptMgr::OnPlayerDeath` receives `(Player*, Unit* killer)`.  Environmental
deaths set `killer` to `nullptr` and pass zero information about the damage
sub-type.  There is no `OnPlayerEnvironmentalDeath` hook in the current API.

---

## 4. `WorldSession::HandlePageTextQueryOpcode` → `AchievementHooks::OnAddonPageQuery`

**Justification**
The Achiever addon communicates with the server by piggy-backing achievement
data requests on the `CMSG_PAGE_TEXT_QUERY` opcode.  The hook intercepts
such requests before the normal page-text lookup so the module can respond
with achievement data without consuming the opcode.

**Alternatives considered**
- A dedicated new opcode — rejected because adding opcodes requires both
  client-side patches and server changes; the Achiever addon already exists
  and uses this piggy-back mechanism.
- An in-game chat command channel — rejected because the addon communicates
  programmatically at high frequency; a chat command round-trip would break
  the UI.
- A custom `ScriptMgr::OnOpcodeReceived` generic hook — not available in
  the current CMaNGOS ScriptMgr.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no generic opcode-intercept hook.  The only way to
intercept an opcode handler before it runs is to add a call site in the
handler itself.

---

## 5. `Player::UpdateSkillPro` → `AchievementHooks::OnSkillUpdate`

**Justification**
`REACH_SKILL_LEVEL` and `LEARN_SKILL_LEVEL` criteria fire when a skill value
changes.  Both the skill ID and the new value are needed.

**Alternatives considered**
- Using `ScriptMgr::OnPlayerLearnSpell` for spell-based skill ups — rejected
  because skill *level increases* from practice (not spell learning) are the
  primary trigger and these do not fire `OnPlayerLearnSpell`.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no `OnPlayerSkillUpdate` hook.  `OnPlayerLearnSpell`
covers only the spell-learning path, not the skill-proficiency advancement
path inside `UpdateSkillPro`.

---

## 6. `Player::EquipItem` → `AchievementHooks::OnEquipItem`

**Justification**
`EQUIP_EPIC_ITEM` and `EQUIP_ITEM` criteria fire whenever a player equips a
qualifying item.  The item and destination slot must both be known.

**Alternatives considered**
- Using `ScriptMgr::OnItemAdd` — rejected because `OnItemAdd` fires when an
  item enters the player's inventory (including the bag), not when it is
  moved to an equipment slot.
- Polling equipped items on every save or login — rejected because criteria
  progress must be credited immediately and cannot be back-filled from a
  snapshot.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no hook that fires specifically when an item is
moved to an equipment slot via `Player::EquipItem`.

---

## 7–8. `Taxi::Tracker` start/end → `AchievementHooks::OnTaxiStart` / `OnTaxiEnd`

**Justification**
`GOLD_SPENT_FOR_TRAVELLING` requires the fare paid at the end of each taxi
flight.  `FLIGHT_PATHS_TAKEN` requires counting completed flights.  Both
pieces of information are only available inside the Taxi tracker at the
start/end of a route.

**Alternatives considered**
- Using `ScriptMgr::OnModifyMoney` to detect taxi fares — rejected for the
  same reason as the talent-reset case: money changes are indistinguishable
  from other gold expenditures without additional context.
- Using movement hooks — rejected because movement hooks fire continuously
  and do not signal route boundaries or fare amounts.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no taxi-flight event hooks.  The Taxi subsystem is
largely self-contained and does not route through any scriptable event bus.

---

## 9. `Player::SetFactionReputation` → `AchievementHooks::OnReputationChange`

**Justification**
`GAIN_REPUTATION` and `GAIN_EXALTED_REPUTATION` criteria require the faction
entry and the new standing value on every reputation change.

**Alternatives considered**
- Using a periodic poll of player reputation standings — rejected because
  criteria must trigger immediately on reaching a threshold, and polling
  would introduce up-to-one-update lag.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no `OnReputationChange` hook.  `ReputationMgr`
updates are internal and not exposed through the existing script API.

---

## 10. `Player::BuyBankSlot` → `AchievementHooks::OnBuyBankSlot`

**Justification**
`BUY_BANK_SLOT` criteria count the number of bank slots purchased.  The
purchase is only confirmed inside `Player::BuyBankSlot` after the gold
deduction succeeds.

**Alternatives considered**
- Using `ScriptMgr::OnModifyMoney` — rejected because the gold change alone
  does not identify a bank-slot purchase.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no `OnPlayerBuyBankSlot` hook.

---

## 11. `Player::ModifyMoney` → `AchievementHooks::OnMoneyChange`

**Justification**
`HIGHEST_GOLD_VALUE_OWNED` criteria track the peak gold ever held by a
player.  The current gold total must be checked every time money is added.

**Alternatives considered**
- Reading current gold on login/save — rejected because a player could
  accumulate and then spend gold between save points, losing the peak value.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no `OnPlayerMoneyChange` hook that fires on every
call to `Player::ModifyMoney`.

---

## 12. `Player::SummonIfPossible` → `AchievementHooks::OnSummon`

**Justification**
`ACCEPTED_SUMMONINGS` criteria count the number of times a player accepts a
summon.  Acceptance is confirmed inside `Player::SummonIfPossible` when the
player clicks "Accept" on the summon dialog.

**Alternatives considered**
- Using a teleport hook — rejected because `SummonIfPossible` is the
  specific code path for player-summon acceptance; other teleport paths
  (hearthstone, portals) must not be credited.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no hook for summon-acceptance.

---

## 13. `Player::SetHonorPoints` → `AchievementHooks::OnHonorUpdate`

**Justification**
`OWN_RANK` criteria depend on the player's current honor point total.  The
hook fires whenever honor points are set so the module can re-evaluate rank
thresholds.

**Alternatives considered**
- Using `ScriptMgr::OnPlayerKilledPlayer` (which fires at the moment of an
  honorable kill) — rejected because honor points are also adjusted by
  honor decay, bonuses, and rank recalculation outside of kills.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no `OnHonorPointsChanged` hook.  `OnPlayerKilledPlayer`
covers only one of several honor-modification paths.

---

## 14. `TradeHandler::HandleAcceptTradeOpcode` → `AchievementHooks::OnTradeAccepted`

**Justification**
`TRADES_DONE` criteria count completed trades.  A trade is completed when
both parties accept, which occurs in `HandleAcceptTradeOpcode`.

**Alternatives considered**
- Using `ScriptMgr::OnItemAdd` to infer trade completion — rejected because
  items received in a trade are indistinguishable from items received by
  other means (mail, loot, vendor purchase).

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no trade-completion hook.

---

## 15. `MailHandler::HandleSendMail` → `AchievementHooks::OnMailSent`

**Justification**
`MAIL_ITEMS` and `MAIL_GOLD` criteria track items and gold sent by mail.
The number of items and the gold amount are available in the send-mail opcode
handler before the mail is committed to the database.

**Alternatives considered**
- Using `ScriptMgr::OnItemRemove` to infer sent items — rejected because
  items removed from inventory can be destroyed, vendored, or traded, not
  only mailed.
- Using `ScriptMgr::OnModifyMoney` for gold — rejected for the same
  ambiguity reason used elsewhere.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no mail-send hook.

---

## 16. `MailHandler::HandleMailTakeItem` → `AchievementHooks::OnMailTakeItem`

**Justification**
`RECEIVE_EPIC_ITEM` criteria require knowing when a player takes a specific
item out of their mailbox.  This can only be detected inside the mail
take-item opcode handler.

**Alternatives considered**
- Using `ScriptMgr::OnItemAdd` — rejected because items arriving via mail
  do not enter the player's inventory at send time; they are retrieved
  explicitly and the item quality must be checked at take-time.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no mail take-item hook.

---

## 17. `BattleGround::UpdatePlayerScore` → `AchievementHooks::OnBgScoreUpdate`

**Justification**
`BG_OBJECTIVE_CAPTURE` and related BG score criteria require the specific
score-type (`SCORE_FLAG_CAPTURES`, `SCORE_DAMAGE_DONE`, etc.) and the
increment value.  This granularity is only available inside
`BattleGround::UpdatePlayerScore`.

**Alternatives considered**
- Using the generic `ScriptMgr::OnBattleGroundEnd` hook and reading final
  scores — rejected because criteria must be credited incrementally during
  the battleground, not only at the end.
- Using `ScriptMgr::OnPlayerKilledPlayer` for kill-based BG scores —
  rejected because it covers only one of several score types.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no `OnBattleGroundScoreUpdate` hook with score-type
granularity.  The existing BG hooks (`OnBattleGroundStart`,
`OnBattleGroundEnd`) do not expose per-tick score events.

---

## 18. `BattleGroundWS::EventPlayerClickedOnFlag` → `AchievementHooks::OnFlagPickUp`

**Justification**
`BG_OBJECTIVE_CAPTURE` for the Warsong Gulch "pick up flag" objective
requires detecting the moment a flag is grabbed.  This event is specific to
`BattleGroundWS` and is not modelled by the generic BG score system.

**Alternatives considered**
- Using `BattleGround::UpdatePlayerScore` with a flag-event score type —
  rejected because the WS flag pickup does not unconditionally increment a
  named score counter at the moment it occurs.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no WS flag-pickup hook.  `BattleGroundWS` is a
concrete subclass and its events are not exposed generically.

---

## 19. `LootHandler::HandleLootMasterGiveOpcode` → `AchievementHooks::OnMasterLootGive`

**Justification**
`RECEIVE_EPIC_ITEM` and `LOOT_EPIC_ITEM` criteria must also be credited when
a Master Looter distributes an item to a player.  The recipient and item are
only known inside the master-give opcode handler.

**Alternatives considered**
- Using `ScriptMgr::OnItemAdd` — rejected because `OnItemAdd` would fire for
  the item's arrival in the player's bag but there is no way to distinguish
  a master-loot give from a normal loot, crafting, or purchase at that point
  (the item has no "origin" tag in the generic `OnItemAdd` path).

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no master-loot-give hook.

---

## 20–21. `LootHandler::HandleLootRoll` / roll resolution → `AchievementHooks::OnLootRoll` / `OnLootRollWon`

**Justification**
`ROLL_NEED_ON_LOOT`, `ROLL_GREED_ON_LOOT`, `ROLL_NEED`, and `ROLL_GREED`
criteria track what roll type a player cast and whether they won.  Both the
cast-roll and win-roll events are needed.

**Alternatives considered**
- Using `ScriptMgr::OnItemAdd` on the winner — rejected because `OnItemAdd`
  only tells us the item arrived, not that it arrived via a roll win, nor
  the roll type used.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no loot-roll hooks (neither cast nor resolution).

---

## 22. `Loot::NotifyMoneyRemoved` → `AchievementHooks::OnLootGold`

**Justification**
`LOOT_MONEY` and `LOOT_TYPE` criteria need to know when gold is taken from a
loot object, including the amount and whether the loot source was a creature,
chest, etc.

**Alternatives considered**
- Using `ScriptMgr::OnModifyMoney` — rejected because money added from loot
  cannot be distinguished from money received by any other means.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no loot-gold hook.  `NotifyMoneyRemoved` is the
only place where the amount, source, and recipient are all known together.

---

## 23–25. Auction house handlers → `AchievementHooks::OnAuctionCreated` / `OnAuctionBidPlaced` / `OnAuctionWon`

**Justification**
`CREATE_AUCTION`, `HIGHEST_AUCTION_BID`, `HIGHEST_AUCTION_SOLD`,
`GOLD_EARNED_BY_AUCTIONS`, and `WON_AUCTIONS` criteria each require a
different facet of the auction lifecycle:

- `OnAuctionCreated` — fires when a player posts an item; needed for
  `CREATE_AUCTION` and `HIGHEST_AUCTION_SOLD` (tracks starting/buyout price).
- `OnAuctionBidPlaced` — fires when a bid is placed; needed for
  `HIGHEST_AUCTION_BID`.
- `OnAuctionWon` — fires when an auction completes with a buyer; needed for
  `GOLD_EARNED_BY_AUCTIONS` and `WON_AUCTIONS`.

**Alternatives considered**
- Using `ScriptMgr::OnItemAdd` to detect auction wins — rejected because
  items won at auction arrive via mail, not directly into the inventory, so
  `OnItemAdd` does not fire at auction completion time.
- Using `ScriptMgr::OnModifyMoney` to detect auction revenue — rejected
  because gold from an auction win is deposited via mail and the transfer
  cannot be distinguished from other mail-gold receipts.
- Polling the `auction_house` table periodically — rejected because
  real-time credit is required; polling would delay criteria updates by up
  to one tick.

**Why existing extension points are insufficient**
CMaNGOS `ScriptMgr` has no auction-house hooks whatsoever.  The auction
house subsystem (`AuctionHouseHandler`, `AuctionHouseMgr`) does not connect
to the script bus at any point.

---

## Summary

| # | Call site | Hook name | Criteria served |
|---|-----------|-----------|-----------------|
| 1 | `Player::HandleFall` | `OnPlayerFall` | `FALL_WITHOUT_DYING` |
| 2 | `Player::resetTalents` | `OnTalentReset` | `GOLD_SPENT_FOR_TALENTS`, `NUMBER_OF_TALENT_RESETS` |
| 3 | `Player::EnvironmentalDamage` (death) | `OnEnvDeath` | `DEATHS_FROM` |
| 4 | `WorldSession::HandlePageTextQueryOpcode` | `OnAddonPageQuery` | Achiever addon protocol |
| 5 | `Player::UpdateSkillPro` | `OnSkillUpdate` | `REACH_SKILL_LEVEL`, `LEARN_SKILL_LEVEL` |
| 6 | `Player::EquipItem` | `OnEquipItem` | `EQUIP_EPIC_ITEM`, `EQUIP_ITEM` |
| 7 | `Taxi::Tracker` start | `OnTaxiStart` | `FLIGHT_PATHS_TAKEN` |
| 8 | `Taxi::Tracker` end | `OnTaxiEnd` | `GOLD_SPENT_FOR_TRAVELLING`, `FLIGHT_PATHS_TAKEN` |
| 9 | `Player::SetFactionReputation` | `OnReputationChange` | `GAIN_REPUTATION`, `GAIN_EXALTED_REPUTATION` |
| 10 | `Player::BuyBankSlot` | `OnBuyBankSlot` | `BUY_BANK_SLOT` |
| 11 | `Player::ModifyMoney` | `OnMoneyChange` | `HIGHEST_GOLD_VALUE_OWNED` |
| 12 | `Player::SummonIfPossible` | `OnSummon` | `ACCEPTED_SUMMONINGS` |
| 13 | `Player::SetHonorPoints` | `OnHonorUpdate` | `OWN_RANK` |
| 14 | `TradeHandler::HandleAcceptTradeOpcode` | `OnTradeAccepted` | `TRADES_DONE` |
| 15 | `MailHandler::HandleSendMail` | `OnMailSent` | `MAIL_ITEMS`, `MAIL_GOLD` |
| 16 | `MailHandler::HandleMailTakeItem` | `OnMailTakeItem` | `RECEIVE_EPIC_ITEM` |
| 17 | `BattleGround::UpdatePlayerScore` | `OnBgScoreUpdate` | `BG_OBJECTIVE_CAPTURE` and BG score criteria |
| 18 | `BattleGroundWS::EventPlayerClickedOnFlag` | `OnFlagPickUp` | `BG_OBJECTIVE_CAPTURE` (WS) |
| 19 | `LootHandler::HandleLootMasterGiveOpcode` | `OnMasterLootGive` | `RECEIVE_EPIC_ITEM`, `LOOT_EPIC_ITEM` |
| 20 | `LootHandler::HandleLootRoll` | `OnLootRoll` | `ROLL_NEED_ON_LOOT`, `ROLL_GREED_ON_LOOT` |
| 21 | Roll resolution path | `OnLootRollWon` | `ROLL_NEED`, `ROLL_GREED` |
| 22 | `Loot::NotifyMoneyRemoved` | `OnLootGold` | `LOOT_MONEY`, `LOOT_TYPE` |
| 23 | `AuctionHouseHandler::HandleAuctionSellItem` | `OnAuctionCreated` | `CREATE_AUCTION`, `HIGHEST_AUCTION_SOLD` |
| 24 | `AuctionHouseHandler::HandleAuctionPlaceBid` | `OnAuctionBidPlaced` | `HIGHEST_AUCTION_BID` |
| 25 | `AuctionHouseMgr::SendAuctionWonMail` | `OnAuctionWon` | `GOLD_EARNED_BY_AUCTIONS`, `WON_AUCTIONS` |

All 25 call sites above are required because no equivalent `ScriptMgr` hook
exists.  Every Category B event (which does have a `ScriptMgr` equivalent)
has been removed from the required patch surface and is instead handled via
`AchievementEventDispatcher` registering with the existing `ScriptMgr` API.
