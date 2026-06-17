# Hook Usage Matrix

## Summary

| Metric | Count |
|--------|-------|
| Total hooks in `AchievementsModule` | 60 |
| Hooks that fire achievement criteria updates | 53 |
| Hooks that perform lifecycle management only | 7 |
| Hooks with **zero** achievement consumers (removable) | 34 (from old module framework) |
| Criteria types with at least one triggering hook | 79 |
| Criteria types **never triggered** by any hook | 19 |
| Hooks present in module but **absent from** `classic.patch` | 3 (**new call sites needed**) |

---

## Part 1 – Hook → Criteria types (forward mapping)

### Lifecycle hooks (no criteria update, but required)

| Hook | What it does |
|------|-------------|
| `OnInitialize` (`World`) | Loads achievement lists, criteria, rewards, completed-achievement cache, script registrations |
| `OnUpdate(elapsed)` (`World`) | Ticks timed achievements for every active `PlayerAchievementMgr` |
| `OnPreCharacterCreated(Player*)` | Allocates `PlayerAchievementMgr` on character creation |
| `OnPreLoadFromDB(Player*)` | Allocates `PlayerAchievementMgr` + `UpdateAchievementCriteria(ON_LOGIN, 1)` |
| `OnLoadFromDB(Player*)` | Calls `CheckAllAchievementCriteria()` after full load |
| `OnLogOut(Player*)` | Destroys `PlayerAchievementMgr` |
| `OnSaveToDB(Player*)` | Calls `PlayerAchievementMgr::SaveToDB()` |
| `OnDeleteFromDB(uint32 playerId)` | Calls `PlayerAchievementMgr::DeleteFromDB(playerId)` |
| `OnCreateItem(Player*, Item*, uint32)` | Sets `ITEM_FIELD_CREATOR` on consumables (no criteria update; enables `NON_CRAFTED_ITEMS_USED` checks downstream) |

### Player gameplay hooks

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnGiveLevel(Player*, uint32)` | `REACH_LEVEL` |
| `OnUpdateSkill(Player*, uint16)` | `REACH_SKILL_LEVEL` |
| `OnAddSpell(Player*, uint32)` | `LEARN_SPELL`, `LEARN_SKILL_LINE`, `LEARN_SKILLLINE_SPELLS` |
| `OnResetTalents(Player*, uint32)` | `GOLD_SPENT_FOR_TALENTS`, `NUMBER_OF_TALENT_RESETS` |
| `OnDuelComplete(Player*, Player*, uint8)` | `WIN_DUEL` (opponent), `LOSE_DUEL` (player) |
| `OnKilledMonsterCredit(Player*, uint32, ObjectGuid&)` | `KILL_CREATURE`; timer `ACHIEVEMENT_TIMED_TYPE_CREATURE` |
| `OnRewardPlayerAtKill(Player*, Unit*)` | `KILL_CREATURE_TYPE` |
| `OnHandleFall(Player*, MovementInfo, float, uint32)` | `FALL_WITHOUT_DYING` |
| `OnHandlePageTextQuery(Player*, WorldPacket&)` | `USE_GAMEOBJECT` (for book GO) |
| `OnDeath(Player*, Unit* killer)` | `DEATH_AT_MAP`, `DEATH`, `DEATH_IN_DUNGEON`; resets `ACHIEVEMENT_CRITERIA_CONDITION_NO_DEATH` |
| `OnDeath(Player*, uint8 envDamageType)` | `DEATHS_FROM` |
| `OnModifyMoney(Player*, int32)` | `HIGHEST_GOLD_VALUE_OWNED` |
| `OnRewardHonor(Player*, Unit*)` | `EARN_HONORABLE_KILL`, `HK_CLASS`, `HK_RACE`, `HONORABLE_KILL_AT_AREA`, `HONORABLE_KILL`, `SPECIAL_PVP_KILL` |
| `OnUpdateHonor(Player*)` | `OWN_RANK` *(Classic only, expansion guard `#if EXPANSION == 0`)* |
| `OnAreaExplored(Player*, uint32)` | `EXPLORE_AREA` |
| `OnSummoned(Player*, ObjectGuid&)` | `ACCEPTED_SUMMONINGS` |
| `OnStoreItem(Player*, Item*)` | `OWN_ITEM`, `RECEIVE_EPIC_ITEM` |
| `OnEquipItem(Player*, Item*)` | `EQUIP_ITEM`, `EQUIP_EPIC_ITEM`, `NON_CRAFTED_ITEMS_USED` |
| `OnUseItem(Player*, Item*)` | `NON_CRAFTED_ITEMS_USED` |
| `OnMoveItemToInventory(Player*, Item*)` | `RECEIVE_EPIC_ITEM` |
| `OnRewardQuest(Player*, Quest*)` | `COMPLETE_QUEST`, `COMPLETE_QUEST_COUNT`, `COMPLETE_QUESTS_IN_ZONE`, `COMPLETE_DAILY_QUEST`, `COMPLETE_DAILY_QUEST_DAILY`, `MONEY_FROM_QUEST_REWARD` |
| `OnAbandonQuest(Player*, uint32)` | `QUEST_ABANDONED` |
| `OnTaxiFlightRouteStart(Player*, Taxi::Tracker&, bool)` | `GOLD_SPENT_FOR_TRAVELLING` *(initial only)* |
| `OnTaxiFlightRouteEnd(Player*, Taxi::Tracker&, bool)` | `FLIGHT_PATHS_TAKEN` *(final)*; `GOLD_SPENT_FOR_TRAVELLING` *(intermediate)* |
| `OnSetReputation(Player*, FactionEntry*, int32, bool)` | `GAIN_REPUTATION`, `GAIN_EXALTED_REPUTATION`, `GAIN_REVERED_REPUTATION`, `GAIN_HONORED_REPUTATION`, `KNOWN_FACTIONS` |
| `OnEmote(Player*, Unit*, uint32)` | `DO_EMOTE` |
| `OnBuyBankSlot(Player*, uint32, uint32)` | `BUY_BANK_SLOT` |
| `OnSellItem(Player*, Item*, uint32)` | `MONEY_FROM_VENDORS` |
| **`OnTradeAccepted(Player*, Player*, TradeData*, TradeData*)`** ⚠️ | `TRADES_DONE` |

### Battleground hooks

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnStartBattleGround(BattleGround*)` | Timer `ACHIEVEMENT_TIMED_TYPE_EVENT` *(WS battle start)* |
| `OnEndBattleGround(BattleGround*, uint32)` | `WIN_BG`, `COMPLETE_BATTLEGROUND` |
| `OnLeaveBattleGround(BattleGround*, Player*)` | Resets `ACHIEVEMENT_CRITERIA_CONDITION_BG_MAP` |
| `OnJoinBattleGround(BattleGround*, Player*)` | Resets `ACHIEVEMENT_CRITERIA_CONDITION_BG_MAP` |
| `OnUpdatePlayerScore(BattleGround*, Player*, uint8, uint32)` | `BG_OBJECTIVE_CAPTURE` *(WS flag captures/returns)* |
| `OnPickUpFlag(BattleGroundWS*, Player*, uint32)` | Timer `ACHIEVEMENT_TIMED_TYPE_SPELL_TARGET` *(flag-picked fake spell)* |

### GameObject hook

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnUse(GameObject*, Unit*)` | `USE_GAMEOBJECT`, `FISH_IN_GAMEOBJECT` *(fishing hole only)* |

### Unit hooks

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnDealDamage(Unit*, Unit*, uint32, uint32)` | `DAMAGE_DONE`, `HIGHEST_HIT_DEALT`, `HIGHEST_HIT_RECEIVED`, `TOTAL_DAMAGE_RECEIVED` |
| `OnKill(Unit*, Unit*)` | `GET_KILLING_BLOWS`, `KILLED_BY_PLAYER`, `KILLED_BY_CREATURE` |
| `OnDealHeal(Unit*, Unit*, int32, uint32)` | `HEALING_DONE`, `HIGHEST_HEAL_CASTED`, `TOTAL_HEALING_RECEIVED`, `HIGHEST_HEALING_RECEIVED` |

### Spell hooks

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnHit(Spell*, Unit*, Unit*)` | `BE_SPELL_TARGET`, `BE_SPELL_TARGET2`, `CAST_SPELL2`; timers `ACHIEVEMENT_TIMED_TYPE_SPELL_TARGET`, `ACHIEVEMENT_TIMED_TYPE_SPELL_CASTER` |
| `OnCast(Spell*, Unit*, Unit*)` | `CAST_SPELL`, `USE_ITEM`; timer `ACHIEVEMENT_TIMED_TYPE_ITEM` |

### Loot hooks

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnHandleLootMasterGive(Loot*, Player*, LootItem*)` | `LOOT_ITEM`, `LOOT_TYPE`, `LOOT_EPIC_ITEM` |
| `OnPlayerRoll(Loot*, Player*, uint32, uint8)` | `ROLL_NEED`, `ROLL_GREED` |
| `OnPlayerWinRoll(Loot*, Player*, uint8, uint8, uint32, uint8)` | `ROLL_NEED_ON_LOOT`, `ROLL_GREED_ON_LOOT`, `LOOT_ITEM`, `LOOT_TYPE`, `LOOT_EPIC_ITEM` |
| `OnSendGold(Loot*, Player*, uint32, uint8)` | `LOOT_MONEY` |

### Group hook

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnAddMember(Group*, Player*, uint8)` | `JOINED_GROUP` |

### Auction house hooks

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnSellItem(AuctionEntry*, Player*)` | `CREATE_AUCTION` |
| `OnUpdateBid(AuctionEntry*, Player*, uint32)` | `HIGHEST_AUCTION_BID` |
| **`OnActionBidWinning(AuctionEntry*, ObjectGuid, ObjectGuid)`** ⚠️ | `WON_AUCTIONS` |

### Mail hooks

| Hook | Criteria types triggered |
|------|--------------------------|
| `OnSendMail(MailDraft&, Player*, ObjectGuid&, uint32)` | `GOLD_SPENT_FOR_MAIL` |
| **`OnMailTakeItem(Mail*, Player*, Item*, ObjectGuid&)`** ⚠️ | `MAIL_ITEMS` |

> ⚠️ = hook is implemented in `AchievementsModule.cpp` but **has no corresponding `sModuleMgr` call site in `classic.patch`**. These three are **new call sites** that must be added to the CMaNGOS source.

### Internally triggered (no call site in CMaNGOS core required)

| Trigger | Criteria types |
|---------|---------------|
| Completing any achievement (internal to `PlayerAchievementMgr`) | `COMPLETE_ACHIEVEMENT`, `EARN_ACHIEVEMENT_POINTS` |
| `CheckAllAchievementCriteria()` on login | `LEARN_SKILL_LEVEL` (evaluated via snapshot, not event-driven) |

---

## Part 2 – Criteria type → Hook (reverse mapping)

| Criteria Type | Triggering Hook |
|---------------|----------------|
| `KILL_CREATURE` | `OnKilledMonsterCredit` |
| `WIN_BG` | `OnEndBattleGround` |
| `REACH_LEVEL` | `OnGiveLevel` |
| `REACH_SKILL_LEVEL` | `OnUpdateSkill` |
| `COMPLETE_ACHIEVEMENT` | *internal – fired when any achievement completes* |
| `COMPLETE_QUEST_COUNT` | `OnRewardQuest` |
| `COMPLETE_DAILY_QUEST_DAILY` | `OnRewardQuest` |
| `COMPLETE_QUESTS_IN_ZONE` | `OnRewardQuest` |
| `DAMAGE_DONE` | `OnDealDamage` |
| `COMPLETE_DAILY_QUEST` | `OnRewardQuest` |
| `COMPLETE_BATTLEGROUND` | `OnEndBattleGround` |
| `DEATH_AT_MAP` | `OnDeath (killer)` |
| `DEATH` | `OnDeath (killer)` |
| `DEATH_IN_DUNGEON` | `OnDeath (killer)` |
| `KILLED_BY_CREATURE` | `OnKill` |
| `KILLED_BY_PLAYER` | `OnKill` |
| `FALL_WITHOUT_DYING` | `OnHandleFall` |
| `DEATHS_FROM` | `OnDeath (env)` |
| `COMPLETE_QUEST` | `OnRewardQuest` |
| `BE_SPELL_TARGET` | `OnHit` |
| `CAST_SPELL` | `OnCast` |
| `BG_OBJECTIVE_CAPTURE` | `OnUpdatePlayerScore` |
| `HONORABLE_KILL_AT_AREA` | `OnRewardHonor` |
| `LEARN_SPELL` | `OnAddSpell` |
| `HONORABLE_KILL` | `OnRewardHonor` |
| `OWN_ITEM` | `OnStoreItem` |
| `LEARN_SKILL_LINE` | `OnAddSpell` |
| `USE_ITEM` | `OnCast` |
| `LOOT_ITEM` | `OnHandleLootMasterGive`, `OnPlayerWinRoll` |
| `EXPLORE_AREA` | `OnAreaExplored` |
| `OWN_RANK` | `OnUpdateHonor` *(Classic only)* |
| `BUY_BANK_SLOT` | `OnBuyBankSlot` |
| `GAIN_REPUTATION` | `OnSetReputation` |
| `GAIN_EXALTED_REPUTATION` | `OnSetReputation` |
| `DO_EMOTE` | `OnEmote` |
| `HEALING_DONE` | `OnDealHeal` |
| `GET_KILLING_BLOWS` | `OnKill` |
| `EQUIP_ITEM` | `OnEquipItem` |
| `MONEY_FROM_VENDORS` | `OnSellItem (Player, Item, money)` |
| `GOLD_SPENT_FOR_TALENTS` | `OnResetTalents` |
| `NUMBER_OF_TALENT_RESETS` | `OnResetTalents` |
| `MONEY_FROM_QUEST_REWARD` | `OnRewardQuest` |
| `GOLD_SPENT_FOR_TRAVELLING` | `OnTaxiFlightRouteStart`, `OnTaxiFlightRouteEnd` |
| `GOLD_SPENT_FOR_MAIL` | `OnSendMail` |
| `LOOT_MONEY` | `OnSendGold` |
| `USE_GAMEOBJECT` | `OnUse`, `OnHandlePageTextQuery` |
| `BE_SPELL_TARGET2` | `OnHit` |
| `SPECIAL_PVP_KILL` | `OnRewardHonor` |
| `FISH_IN_GAMEOBJECT` | `OnUse` |
| `ON_LOGIN` | `OnPreLoadFromDB` |
| `LEARN_SKILLLINE_SPELLS` | `OnAddSpell` |
| `WIN_DUEL` | `OnDuelComplete` |
| `LOSE_DUEL` | `OnDuelComplete` |
| `KILL_CREATURE_TYPE` | `OnRewardPlayerAtKill` |
| `GOLD_EARNED_BY_AUCTIONS` | *(not triggered – see §Part 3)* |
| `CREATE_AUCTION` | `OnSellItem (AuctionEntry, Player)` |
| `HIGHEST_AUCTION_BID` | `OnUpdateBid` |
| `WON_AUCTIONS` | `OnActionBidWinning` ⚠️ *(call site missing from patch)* |
| `HIGHEST_AUCTION_SOLD` | *(not triggered – see §Part 3)* |
| `HIGHEST_GOLD_VALUE_OWNED` | `OnModifyMoney` |
| `GAIN_REVERED_REPUTATION` | `OnSetReputation` |
| `GAIN_HONORED_REPUTATION` | `OnSetReputation` |
| `KNOWN_FACTIONS` | `OnSetReputation` |
| `LOOT_EPIC_ITEM` | `OnHandleLootMasterGive`, `OnPlayerWinRoll` |
| `RECEIVE_EPIC_ITEM` | `OnStoreItem`, `OnMoveItemToInventory` |
| `ROLL_NEED` | `OnPlayerRoll` |
| `ROLL_GREED` | `OnPlayerRoll` |
| `HIGHEST_HIT_DEALT` | `OnDealDamage` |
| `HIGHEST_HIT_RECEIVED` | `OnDealDamage` |
| `TOTAL_DAMAGE_RECEIVED` | `OnDealDamage` |
| `HIGHEST_HEAL_CASTED` | `OnDealHeal` |
| `TOTAL_HEALING_RECEIVED` | `OnDealHeal` |
| `HIGHEST_HEALING_RECEIVED` | `OnDealHeal` |
| `QUEST_ABANDONED` | `OnAbandonQuest` |
| `FLIGHT_PATHS_TAKEN` | `OnTaxiFlightRouteEnd` |
| `LOOT_TYPE` | `OnHandleLootMasterGive`, `OnPlayerWinRoll` |
| `CAST_SPELL2` | `OnHit` |
| `EARN_HONORABLE_KILL` | `OnRewardHonor` |
| `ACCEPTED_SUMMONINGS` | `OnSummoned` |
| `EARN_ACHIEVEMENT_POINTS` | *internal – fired when any achievement completes* |
| `JOINED_GROUP` | `OnAddMember` |
| `MAIL_ITEMS` | `OnMailTakeItem` ⚠️ *(call site missing from patch)* |
| `MAIL_GOLD` | *(not triggered – see §Part 3)* |
| `TRADES_DONE` | `OnTradeAccepted` ⚠️ *(call site missing from patch)* |
| `NON_CRAFTED_ITEMS_USED` | `OnEquipItem`, `OnUseItem` |
| `HK_CLASS` | `OnRewardHonor` |
| `HK_RACE` | `OnRewardHonor` |
| `ROLL_NEED_ON_LOOT` | `OnPlayerWinRoll` |
| `ROLL_GREED_ON_LOOT` | `OnPlayerWinRoll` |
| `EQUIP_EPIC_ITEM` | `OnEquipItem` |

---

## Part 3 – Criteria types never triggered

The following 19 criteria types exist in `AchievementCriteriaTypes` but no hook in the current implementation ever calls `UpdateAchievementCriteria` for them. They are either:
- Expansion-specific features absent from Classic (arena, barber, LFD), or
- Stat-snapshot criteria not wired to an event, or
- Auction sub-types not yet implemented.

| Criteria Type | Reason not triggered |
|---------------|----------------------|
| `COMPLETE_RAID` | No hook; classic raids do not produce a raid-completion event |
| `WIN_ARENA` | No arena in Classic |
| `PLAY_ARENA` | No arena in Classic |
| `WIN_RATED_ARENA` | No arena in Classic |
| `HIGHEST_TEAM_RATING` | No arena in Classic |
| `HIGHEST_PERSONAL_RATING` | No arena in Classic |
| `LEARN_SKILL_LEVEL` | Evaluated during `CheckAllAchievementCriteria` (login snapshot), not event-driven |
| `GOLD_EARNED_BY_AUCTIONS` | No call site; would need `OnActionBidWinning` extension |
| `HIGHEST_AUCTION_SOLD` | No call site; would need `OnActionBidWinning` extension |
| `VISIT_BARBER_SHOP` | No barber shop in Classic |
| `GOLD_SPENT_AT_BARBER` | No barber shop in Classic |
| `MAIL_GOLD` | No call site; `OnSendMail` only tracks cost, not gold enclosed |
| `USE_LFD_TO_GROUP_WITH_PLAYERS` | No LFD in Classic |
| `HIGHEST_HEALTH` | Stat snapshot; not triggered by any event hook |
| `HIGHEST_POWER` | Stat snapshot; not triggered by any event hook |
| `HIGHEST_STAT` | Stat snapshot; not triggered by any event hook |
| `HIGHEST_SPELLPOWER` | Stat snapshot; not triggered by any event hook |
| `HIGHEST_ARMOR` | Stat snapshot; not triggered by any event hook |
| `HIGHEST_RATING` | Stat snapshot; not triggered by any event hook |

---

## Part 4 – Hooks in the old module framework with zero achievement consumers

The following 34 `sModuleMgr` call sites exist in `classic.patch` but no method in `AchievementsModule` implements them. They are safe to omit entirely from the new minimal hook patch.

| Unused module hook |
|--------------------|
| `OnPreGossipHello` |
| `OnGossipHello` |
| `OnGossipSelect` |
| `OnExecuteCommand` |
| `OnAddToWorld` |
| `OnRespawn` |
| `OnRespawnRequest` |
| `OnCharacterCreated` |
| `OnBuyBackItem` |
| `OnGiveXP` |
| `OnGetPlayerLevelInfo` |
| `OnPreResurrect` |
| `OnResurrect` |
| `OnReleaseSpirit` |
| `OnSetVisibleItemSlot` |
| `OnMoveItemFromInventory` |
| `OnLoadActionButtons` |
| `OnSaveActionButtons` |
| `OnPreRewardPlayerAtKill` |
| `OnPreHandleFall` |
| `OnLearnTalent` |
| `OnCalculateEffectiveDodgeChance` |
| `OnCalculateEffectiveParryChance` |
| `OnCalculateEffectiveBlockChance` |
| `OnCalculateEffectiveCritChance` |
| `OnCalculateEffectiveMissChance` |
| `OnCalculateSpellMissChance` |
| `OnGetAttackDistance` |
| `OnAddItem` |
| `OnFillLoot` |
| `OnGenerateMoneyLoot` |
| `OnWriteDump` |
| `IsModuleDumpTable` |
| `OnWorldPreInitialized` |

These 34 hooks inflate the old patch by approximately **68 hunks** (roughly half the total). Removing them is the single largest size reduction in the migration.
