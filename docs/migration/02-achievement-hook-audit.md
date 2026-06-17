# Achievement Hook Audit

## Scope

This report scans the achievement sources and maps every framework hook that still has an achievement consumer.

Scanned files:

- `/home/runner/work/cmangos-achievements/cmangos-achievements/src/AchievementsModule.h`
- `/home/runner/work/cmangos-achievements/cmangos-achievements/src/AchievementsModule.cpp`
- `/home/runner/work/cmangos-achievements/cmangos-achievements/src/AchievementScriptMgr.h`
- `/home/runner/work/cmangos-achievements/cmangos-achievements/src/AchievementScriptMgr.cpp`
- `/home/runner/work/cmangos-achievements/cmangos-achievements/src/achievement_scripts.cpp`
- `/home/runner/work/cmangos-achievements/cmangos-achievements/patches/classic.patch`

## Hooks with achievement consumers (55)

### Lifecycle

| Framework hook | Achievement consumer | Evidence | Usage |
|---|---|---|---|
| `OnWorldInitialized` | `AchievementsModule::OnInitialize` | `src/AchievementsModule.h:795, src/AchievementsModule.cpp:4964` | loads achievement lists, criteria, rewards, completed-achievement cache, and script registrations |
| `OnWorldUpdated` | `AchievementsModule::OnUpdate` | `src/AchievementsModule.h:796, src/AchievementsModule.cpp:5944` | ticks timed achievements for every loaded player manager |
| `OnLogOut` | `AchievementsModule::OnLogOut(Player* player)` | `patches/classic.patch:785; src/AchievementsModule.cpp:5074` | actions: manager_destroy |
| `OnPreCharacterCreated` | `AchievementsModule::OnPreCharacterCreated(Player* player)` | `patches/classic.patch:795; src/AchievementsModule.cpp:5031` | actions: manager_create |
| `OnDeleteFromDB` | `AchievementsModule::OnDeleteFromDB(uint32 playerId)` | `patches/classic.patch:915; src/AchievementsModule.cpp:5087` | actions: delete_db |
| `OnPreLoadFromDB` | `AchievementsModule::OnPreLoadFromDB(Player* player)` | `patches/classic.patch:1137; src/AchievementsModule.cpp:5049` | ACHIEVEMENT_CRITERIA_TYPE_ON_LOGIN |
| `OnLoadFromDB` | `AchievementsModule::OnLoadFromDB(Player* player)` | `patches/classic.patch:1148; src/AchievementsModule.cpp:5955` | actions: check_all |
| `OnSaveToDB` | `AchievementsModule::OnSaveToDB(Player* player)` | `patches/classic.patch:1170; src/AchievementsModule.cpp:5092` | actions: save_db |

### Player gameplay

| Framework hook | Achievement consumer | Evidence | Usage |
|---|---|---|---|
| `OnSellItem(AuctionEntry* auctionEntry, Player* player)` | `AchievementsModule::OnSellItem(AuctionEntry* auctionEntry, Player* player)` | `patches/classic.patch:237,689; src/AchievementsModule.cpp:5699` | ACHIEVEMENT_CRITERIA_TYPE_CREATE_AUCTION |
| `OnSellItem(Player* player, Item* item, uint32 money)` | `AchievementsModule::OnSellItem(Player* player, Item* item, uint32 money)` | `patches/classic.patch:237,689; src/AchievementsModule.cpp:5708` | ACHIEVEMENT_CRITERIA_TYPE_MONEY_FROM_VENDORS |
| `OnEmote` | `AchievementsModule::OnEmote(Player* player, Unit* target, uint32 emote)` | `patches/classic.patch:543; src/AchievementsModule.cpp:5845` | ACHIEVEMENT_CRITERIA_TYPE_DO_EMOTE |
| `OnBuyBankSlot` | `AchievementsModule::OnBuyBankSlot(Player* player, uint32 slot, uint32 price)` | `patches/classic.patch:711; src/AchievementsModule.cpp:5874` | ACHIEVEMENT_CRITERIA_TYPE_BUY_BANK_SLOT |
| `OnDeath(Player* player, Unit* killer)` | `AchievementsModule::OnDeath(Player* player, Unit* killer)` | `patches/classic.patch:818,1369; src/AchievementsModule.cpp:5228` | ACHIEVEMENT_CRITERIA_TYPE_DEATH_AT_MAP, ACHIEVEMENT_CRITERIA_TYPE_DEATH, ACHIEVEMENT_CRITERIA_TYPE_DEATH_IN_DUNGEON; conditions: ACHIEVEMENT_CRITERIA_CONDITION_NO_DEATH |
| `OnDeath(Player* player, uint8 environmentalDamageType)` | `AchievementsModule::OnDeath(Player* player, uint8 environmentalDamageType)` | `patches/classic.patch:818,1369; src/AchievementsModule.cpp:5240` | ACHIEVEMENT_CRITERIA_TYPE_DEATHS_FROM |
| `OnModifyMoney` | `AchievementsModule::OnModifyMoney(Player* player, int32 diff)` | `patches/classic.patch:836; src/AchievementsModule.cpp:5896` | ACHIEVEMENT_CRITERIA_TYPE_HIGHEST_GOLD_VALUE_OWNED |
| `OnGiveLevel` | `AchievementsModule::OnGiveLevel(Player* player, uint32 level)` | `patches/classic.patch:871; src/AchievementsModule.cpp:5935` | ACHIEVEMENT_CRITERIA_TYPE_REACH_LEVEL |
| `OnAddSpell` | `AchievementsModule::OnAddSpell(Player* player, uint32 spellId)` | `patches/classic.patch:892; src/AchievementsModule.cpp:5121` | ACHIEVEMENT_CRITERIA_TYPE_LEARN_SKILL_LINE, ACHIEVEMENT_CRITERIA_TYPE_LEARN_SKILLLINE_SPELLS, ACHIEVEMENT_CRITERIA_TYPE_LEARN_SPELL |
| `OnResetTalents` | `AchievementsModule::OnResetTalents(Player* player, uint32 cost)` | `patches/classic.patch:903; src/AchievementsModule.cpp:5249` | ACHIEVEMENT_CRITERIA_TYPE_GOLD_SPENT_FOR_TALENTS, ACHIEVEMENT_CRITERIA_TYPE_NUMBER_OF_TALENT_RESETS |
| `OnUpdateSkill` | `AchievementsModule::OnUpdateSkill(Player* player, uint16 skillId)` | `patches/classic.patch:960,971,983; src/AchievementsModule.cpp:5259` | ACHIEVEMENT_CRITERIA_TYPE_REACH_SKILL_LEVEL |
| `OnAreaExplored` | `AchievementsModule::OnAreaExplored(Player* player, uint32 areaId)` | `patches/classic.patch:994; src/AchievementsModule.cpp:5914` | ACHIEVEMENT_CRITERIA_TYPE_EXPLORE_AREA |
| `OnUpdateHonor` | `AchievementsModule::OnUpdateHonor(Player* player)` | `patches/classic.patch:1005; src/AchievementsModule.cpp:5923` | ACHIEVEMENT_CRITERIA_TYPE_OWN_RANK |
| `OnRewardHonor` | `AchievementsModule::OnRewardHonor(Player* player, Unit* victim)` | `patches/classic.patch:1016; src/AchievementsModule.cpp:5268` | ACHIEVEMENT_CRITERIA_TYPE_EARN_HONORABLE_KILL, ACHIEVEMENT_CRITERIA_TYPE_HK_CLASS, ACHIEVEMENT_CRITERIA_TYPE_HK_RACE, ACHIEVEMENT_CRITERIA_TYPE_HONORABLE_KILL_AT_AREA, ACHIEVEMENT_CRITERIA_TYPE_HONORABLE_KILL, ACHIEVEMENT_CRITERIA_TYPE_SPECIAL_PVP_KILL |
| `OnDuelComplete` | `AchievementsModule::OnDuelComplete(Player* player, Player* opponent, uint8 type)` | `patches/classic.patch:1027; src/AchievementsModule.cpp:5140` | ACHIEVEMENT_CRITERIA_TYPE_LOSE_DUEL, ACHIEVEMENT_CRITERIA_TYPE_WIN_DUEL |
| `OnStoreItem` | `AchievementsModule::OnStoreItem(Player* player, Item* item)` | `patches/classic.patch:1038,1637; src/AchievementsModule.cpp:5290` | ACHIEVEMENT_CRITERIA_TYPE_RECEIVE_EPIC_ITEM, ACHIEVEMENT_CRITERIA_TYPE_OWN_ITEM |
| `OnEquipItem` | `AchievementsModule::OnEquipItem(Player* player, Item* item)` | `patches/classic.patch:1050,1060,1072; src/AchievementsModule.cpp:5302` | ACHIEVEMENT_CRITERIA_TYPE_EQUIP_ITEM, ACHIEVEMENT_CRITERIA_TYPE_EQUIP_EPIC_ITEM, ACHIEVEMENT_CRITERIA_TYPE_NON_CRAFTED_ITEMS_USED |
| `OnMoveItemToInventory` | `AchievementsModule::OnMoveItemToInventory(Player* player, Item* item)` | `patches/classic.patch:1105; src/AchievementsModule.cpp:5329` | ACHIEVEMENT_CRITERIA_TYPE_RECEIVE_EPIC_ITEM |
| `OnRewardQuest` | `AchievementsModule::OnRewardQuest(Player* player, const Quest* quest)` | `patches/classic.patch:1116; src/AchievementsModule.cpp:5338` | ACHIEVEMENT_CRITERIA_TYPE_MONEY_FROM_QUEST_REWARD, ACHIEVEMENT_CRITERIA_TYPE_COMPLETE_DAILY_QUEST, ACHIEVEMENT_CRITERIA_TYPE_COMPLETE_DAILY_QUEST_DAILY, ACHIEVEMENT_CRITERIA_TYPE_COMPLETE_QUESTS_IN_ZONE, ACHIEVEMENT_CRITERIA_TYPE_COMPLETE_QUEST_COUNT, ACHIEVEMENT_CRITERIA_TYPE_COMPLETE_QUEST |
| `OnKilledMonsterCredit` | `AchievementsModule::OnKilledMonsterCredit(Player* player, uint32 entry, ObjectGuid& guid)` | `patches/classic.patch:1127; src/AchievementsModule.cpp:5158` | ACHIEVEMENT_CRITERIA_TYPE_KILL_CREATURE; timers: ACHIEVEMENT_TIMED_TYPE_CREATURE |
| `OnTaxiFlightRouteStart` | `AchievementsModule::OnTaxiFlightRouteStart(Player* player, const Taxi::Tracker& taxiTracker, bool initial)` | `patches/classic.patch:1193; src/AchievementsModule.cpp:5371` | ACHIEVEMENT_CRITERIA_TYPE_GOLD_SPENT_FOR_TRAVELLING |
| `OnTaxiFlightRouteEnd` | `AchievementsModule::OnTaxiFlightRouteEnd(Player* player, const Taxi::Tracker& taxiTracker, bool final)` | `patches/classic.patch:1204; src/AchievementsModule.cpp:5384` | ACHIEVEMENT_CRITERIA_TYPE_FLIGHT_PATHS_TAKEN, ACHIEVEMENT_CRITERIA_TYPE_GOLD_SPENT_FOR_TRAVELLING |
| `OnSummoned` | `AchievementsModule::OnSummoned(Player* player, const ObjectGuid& summoner)` | `patches/classic.patch:1214; src/AchievementsModule.cpp:5905` | ACHIEVEMENT_CRITERIA_TYPE_ACCEPTED_SUMMONINGS |
| `OnRewardPlayerAtKill` | `AchievementsModule::OnRewardPlayerAtKill(Player* player, Unit* victim)` | `patches/classic.patch:1239,1516; src/AchievementsModule.cpp:5179` | ACHIEVEMENT_CRITERIA_TYPE_KILL_CREATURE_TYPE |
| `OnHandleFall` | `AchievementsModule::OnHandleFall(Player* player, const MovementInfo& movementInfo, float lastFallZ, uint32 damage)` | `patches/classic.patch:1275; src/AchievementsModule.cpp:5191` | ACHIEVEMENT_CRITERIA_TYPE_FALL_WITHOUT_DYING |
| `OnHandlePageTextQuery` | `AchievementsModule::OnHandlePageTextQuery(Player* player, const WorldPacket& packet)` | `patches/classic.patch:1330; src/AchievementsModule.cpp:5207` | ACHIEVEMENT_CRITERIA_TYPE_USE_GAMEOBJECT |
| `OnAbandonQuest` | `AchievementsModule::OnAbandonQuest(Player* player, uint32 questId)` | `patches/classic.patch:1732; src/AchievementsModule.cpp:5993` | ACHIEVEMENT_CRITERIA_TYPE_QUEST_ABANDONED |
| `OnSetReputation` | `AchievementsModule::OnSetReputation(Player* player, const FactionEntry* factionEntry, int32 standing, bool incremental)` | `patches/classic.patch:1757; src/AchievementsModule.cpp:5558` | ACHIEVEMENT_CRITERIA_TYPE_KNOWN_FACTIONS, ACHIEVEMENT_CRITERIA_TYPE_GAIN_REPUTATION, ACHIEVEMENT_CRITERIA_TYPE_GAIN_EXALTED_REPUTATION, ACHIEVEMENT_CRITERIA_TYPE_GAIN_REVERED_REPUTATION, ACHIEVEMENT_CRITERIA_TYPE_GAIN_HONORED_REPUTATION |
| `OnUseItem` | `AchievementsModule::OnUseItem(Player* player, Item* item)` | `patches/classic.patch:1882; src/AchievementsModule.cpp:5318` | ACHIEVEMENT_CRITERIA_TYPE_NON_CRAFTED_ITEMS_USED |

### Battleground and group

| Framework hook | Achievement consumer | Evidence | Usage |
|---|---|---|---|
| `OnEndBattleGround` | `AchievementsModule::OnEndBattleGround(BattleGround* battleground, uint32 winnerTeam)` | `patches/classic.patch:289; src/AchievementsModule.cpp:5819` | ACHIEVEMENT_CRITERIA_TYPE_WIN_BG, ACHIEVEMENT_CRITERIA_TYPE_COMPLETE_BATTLEGROUND |
| `OnLeaveBattleGround` | `AchievementsModule::OnLeaveBattleGround(BattleGround* battleground, Player* player)` | `patches/classic.patch:300; src/AchievementsModule.cpp:5769` | conditions: ACHIEVEMENT_CRITERIA_CONDITION_BG_MAP |
| `OnJoinBattleGround` | `AchievementsModule::OnJoinBattleGround(BattleGround* battleground, Player* player)` | `patches/classic.patch:311; src/AchievementsModule.cpp:5778` | conditions: ACHIEVEMENT_CRITERIA_CONDITION_BG_MAP |
| `OnStartBattleGround` | `AchievementsModule::OnStartBattleGround(BattleGround* battleground)` | `patches/classic.patch:337,374,438; src/AchievementsModule.cpp:5797` | timers: ACHIEVEMENT_TIMED_TYPE_EVENT |
| `OnUpdatePlayerScore` | `AchievementsModule::OnUpdatePlayerScore(BattleGround* battleground, Player* player, uint8 scoreType, uint32 value)` | `patches/classic.patch:348,385,460; src/AchievementsModule.cpp:5101` | ACHIEVEMENT_CRITERIA_TYPE_BG_OBJECTIVE_CAPTURE |
| `OnPickUpFlag` | `AchievementsModule::OnPickUpFlag(BattleGroundWS* battleground, Player* player, uint32 team)` | `patches/classic.patch:449; src/AchievementsModule.cpp:5787` | timers: ACHIEVEMENT_TIMED_TYPE_SPELL_TARGET |

### GameObject, unit, spell

| Framework hook | Achievement consumer | Evidence | Usage |
|---|---|---|---|
| `OnUse` | `AchievementsModule::OnUse(GameObject* gameObject, Unit* user)` | `patches/classic.patch:617; src/AchievementsModule.cpp:5854` | ACHIEVEMENT_CRITERIA_TYPE_FISH_IN_GAMEOBJECT, ACHIEVEMENT_CRITERIA_TYPE_USE_GAMEOBJECT |
| `OnDealDamage` | `AchievementsModule::OnDealDamage(Unit* dealer, Unit* victim, uint32 health, uint32 damage)` | `patches/classic.patch:1357; src/AchievementsModule.cpp:5401` | ACHIEVEMENT_CRITERIA_TYPE_DAMAGE_DONE, ACHIEVEMENT_CRITERIA_TYPE_HIGHEST_HIT_DEALT, ACHIEVEMENT_CRITERIA_TYPE_HIGHEST_HIT_RECEIVED, ACHIEVEMENT_CRITERIA_TYPE_TOTAL_DAMAGE_RECEIVED |
| `OnKill` | `AchievementsModule::OnKill(Unit* killer, Unit* victim)` | `patches/classic.patch:1380; src/AchievementsModule.cpp:5437` | ACHIEVEMENT_CRITERIA_TYPE_GET_KILLING_BLOWS, ACHIEVEMENT_CRITERIA_TYPE_KILLED_BY_PLAYER, ACHIEVEMENT_CRITERIA_TYPE_KILLED_BY_CREATURE |
| `OnDealHeal` | `AchievementsModule::OnDealHeal(Unit* dealer, Unit* victim, int32 gain, uint32 addHealth)` | `patches/classic.patch:1464; src/AchievementsModule.cpp:5470` | ACHIEVEMENT_CRITERIA_TYPE_HEALING_DONE, ACHIEVEMENT_CRITERIA_TYPE_HIGHEST_HEAL_CASTED, ACHIEVEMENT_CRITERIA_TYPE_TOTAL_HEALING_RECEIVED, ACHIEVEMENT_CRITERIA_TYPE_HIGHEST_HEALING_RECEIVED |
| `OnHit` | `AchievementsModule::OnHit(Spell* spell, Unit* caster, Unit* target)` | `patches/classic.patch:1845; src/AchievementsModule.cpp:5572` | ACHIEVEMENT_CRITERIA_TYPE_BE_SPELL_TARGET, ACHIEVEMENT_CRITERIA_TYPE_BE_SPELL_TARGET2, ACHIEVEMENT_CRITERIA_TYPE_CAST_SPELL2; timers: ACHIEVEMENT_TIMED_TYPE_SPELL_TARGET, ACHIEVEMENT_TIMED_TYPE_SPELL_CASTER |
| `OnCast` | `AchievementsModule::OnCast(Spell* spell, Unit* caster, Unit* target)` | `patches/classic.patch:1856; src/AchievementsModule.cpp:5611` | ACHIEVEMENT_CRITERIA_TYPE_USE_ITEM, ACHIEVEMENT_CRITERIA_TYPE_CAST_SPELL; timers: ACHIEVEMENT_TIMED_TYPE_ITEM |

### Loot, mail, auction

| Framework hook | Achievement consumer | Evidence | Usage |
|---|---|---|---|
| `OnUpdateBid` | `AchievementsModule::OnUpdateBid(AuctionEntry* auctionEntry, Player* player, uint32 newBid)` | `patches/classic.patch:262; src/AchievementsModule.cpp:5717` | ACHIEVEMENT_CRITERIA_TYPE_HIGHEST_AUCTION_BID |
| `OnHandleLootMasterGive` | `AchievementsModule::OnHandleLootMasterGive(Loot* loot, Player* target, LootItem* lootItem)` | `patches/classic.patch:1543; src/AchievementsModule.cpp:5504` | ACHIEVEMENT_CRITERIA_TYPE_LOOT_ITEM, ACHIEVEMENT_CRITERIA_TYPE_LOOT_TYPE, ACHIEVEMENT_CRITERIA_TYPE_LOOT_EPIC_ITEM |
| `OnPlayerWinRoll` | `AchievementsModule::OnPlayerWinRoll(Loot* loot, Player* player, uint8 rollType, uint8 rollAmount, uint32 itemSlot, uint8 inventoryResult)` | `patches/classic.patch:1570; src/AchievementsModule.cpp:5539` | ACHIEVEMENT_CRITERIA_TYPE_ROLL_NEED_ON_LOOT, ACHIEVEMENT_CRITERIA_TYPE_ROLL_GREED_ON_LOOT, ACHIEVEMENT_CRITERIA_TYPE_LOOT_ITEM, ACHIEVEMENT_CRITERIA_TYPE_LOOT_TYPE, ACHIEVEMENT_CRITERIA_TYPE_LOOT_EPIC_ITEM |
| `OnSendGold` | `AchievementsModule::OnSendGold(Loot* loot, Player* player, uint32 gold, uint8 lootMethod)` | `patches/classic.patch:1649; src/AchievementsModule.cpp:5964` | ACHIEVEMENT_CRITERIA_TYPE_LOOT_MONEY |
| `OnPlayerRoll` | `AchievementsModule::OnPlayerRoll(Loot* loot, Player* player, uint32 itemSlot, uint8 rollType)` | `patches/classic.patch:1661; src/AchievementsModule.cpp:5515` | ACHIEVEMENT_CRITERIA_TYPE_ROLL_NEED, ACHIEVEMENT_CRITERIA_TYPE_ROLL_GREED |
| `OnSendMail` | `AchievementsModule::OnSendMail(const MailDraft& mail, Player* player, const ObjectGuid& receiver, uint32 cost)` | `patches/classic.patch:1687; src/AchievementsModule.cpp:5751` | ACHIEVEMENT_CRITERIA_TYPE_GOLD_SPENT_FOR_MAIL |

## Hooks with zero achievement consumers (34)

| Framework hook | Evidence | Finding |
|---|---|---|
| `OnPreGossipHello` | `patches/classic.patch:410,629,649,736,1712` | no AchievementsModule override or other achievement-source consumer found |
| `OnExecuteCommand` | `patches/classic.patch:515` | no AchievementsModule override or other achievement-source consumer found |
| `OnAddToWorld` | `patches/classic.patch:569` | no AchievementsModule override or other achievement-source consumer found |
| `OnRespawn` | `patches/classic.patch:579` | no AchievementsModule override or other achievement-source consumer found |
| `OnRespawnRequest` | `patches/classic.patch:592` | no AchievementsModule override or other achievement-source consumer found |
| `OnGossipHello` | `patches/classic.patch:636,654,744,1721` | no AchievementsModule override or other achievement-source consumer found |
| `OnBuyBackItem` | `patches/classic.patch:700` | no AchievementsModule override or other achievement-source consumer found |
| `OnGossipSelect` | `patches/classic.patch:754` | no AchievementsModule override or other achievement-source consumer found |
| `OnCharacterCreated` | `patches/classic.patch:806` | no AchievementsModule override or other achievement-source consumer found |
| `OnGiveXP` | `patches/classic.patch:849` | no AchievementsModule override or other achievement-source consumer found |
| `OnGetPlayerLevelInfo` | `patches/classic.patch:859,881` | no AchievementsModule override or other achievement-source consumer found |
| `OnPreResurrect` | `patches/classic.patch:926` | no AchievementsModule override or other achievement-source consumer found |
| `OnResurrect` | `patches/classic.patch:938` | no AchievementsModule override or other achievement-source consumer found |
| `OnReleaseSpirit` | `patches/classic.patch:950` | no AchievementsModule override or other achievement-source consumer found |
| `OnSetVisibleItemSlot` | `patches/classic.patch:1083` | no AchievementsModule override or other achievement-source consumer found |
| `OnMoveItemFromInventory` | `patches/classic.patch:1094` | no AchievementsModule override or other achievement-source consumer found |
| `OnLoadActionButtons` | `patches/classic.patch:1157` | no AchievementsModule override or other achievement-source consumer found |
| `OnSaveActionButtons` | `patches/classic.patch:1180` | no AchievementsModule override or other achievement-source consumer found |
| `OnPreRewardPlayerAtKill` | `patches/classic.patch:1225,1502` | no AchievementsModule override or other achievement-source consumer found |
| `OnPreHandleFall` | `patches/classic.patch:1250` | no AchievementsModule override or other achievement-source consumer found |
| `OnLearnTalent` | `patches/classic.patch:1286` | no AchievementsModule override or other achievement-source consumer found |
| `OnCalculateEffectiveDodgeChance` | `patches/classic.patch:1390` | no AchievementsModule override or other achievement-source consumer found |
| `OnCalculateEffectiveParryChance` | `patches/classic.patch:1402` | no AchievementsModule override or other achievement-source consumer found |
| `OnCalculateEffectiveBlockChance` | `patches/classic.patch:1414` | no AchievementsModule override or other achievement-source consumer found |
| `OnCalculateEffectiveCritChance` | `patches/classic.patch:1427` | no AchievementsModule override or other achievement-source consumer found |
| `OnCalculateEffectiveMissChance` | `patches/classic.patch:1439` | no AchievementsModule override or other achievement-source consumer found |
| `OnCalculateSpellMissChance` | `patches/classic.patch:1452` | no AchievementsModule override or other achievement-source consumer found |
| `OnGetAttackDistance` | `patches/classic.patch:1475` | no AchievementsModule override or other achievement-source consumer found |
| `OnAddItem` | `patches/classic.patch:1583,1594` | no AchievementsModule override or other achievement-source consumer found |
| `OnFillLoot` | `patches/classic.patch:1604` | no AchievementsModule override or other achievement-source consumer found |
| `OnGenerateMoneyLoot` | `patches/classic.patch:1625` | no AchievementsModule override or other achievement-source consumer found |
| `OnWriteDump` | `patches/classic.patch:1909` | no AchievementsModule override or other achievement-source consumer found |
| `IsModuleDumpTable` | `patches/classic.patch:1921` | no AchievementsModule override or other achievement-source consumer found |
| `OnWorldPreInitialized` | `patches/classic.patch:1953` | no AchievementsModule override or other achievement-source consumer found |

## Summary

- Hook consumer rows found in achievement code: **55**
- Framework hook names with no achievement consumer: **34**
- Two lifecycle call sites (`OnWorldInitialized`, `OnWorldUpdated`) are consumed indirectly through `AchievementsModule::OnInitialize` and `AchievementsModule::OnUpdate`.
