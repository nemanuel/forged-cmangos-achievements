# Minimal Hook Set

## Final categorization

### A. Replaceable via ScriptMgr

No achievement hook has a drop-in replacement in the current `mangos-classic` event systems audited above.

### B. Requires lightweight core hook (55 consumer rows)

| Hook | Why it must remain | Current achievement consumer |
|---|---|---|
| `OnWorldInitialized` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnInitialize` |
| `OnWorldUpdated` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnUpdate` |
| `OnSellItem(AuctionEntry* auctionEntry, Player* player)` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnSellItem(AuctionEntry* auctionEntry, Player* player)` |
| `OnSellItem(Player* player, Item* item, uint32 money)` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnSellItem(Player* player, Item* item, uint32 money)` |
| `OnUpdateBid` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnUpdateBid(AuctionEntry* auctionEntry, Player* player, uint32 newBid)` |
| `OnEndBattleGround` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnEndBattleGround(BattleGround* battleground, uint32 winnerTeam)` |
| `OnLeaveBattleGround` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnLeaveBattleGround(BattleGround* battleground, Player* player)` |
| `OnJoinBattleGround` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnJoinBattleGround(BattleGround* battleground, Player* player)` |
| `OnStartBattleGround` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnStartBattleGround(BattleGround* battleground)` |
| `OnUpdatePlayerScore` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnUpdatePlayerScore(BattleGround* battleground, Player* player, uint8 scoreType, uint32 value)` |
| `OnPickUpFlag` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnPickUpFlag(BattleGroundWS* battleground, Player* player, uint32 team)` |
| `OnEmote` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnEmote(Player* player, Unit* target, uint32 emote)` |
| `OnUse` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnUse(GameObject* gameObject, Unit* user)` |
| `OnBuyBankSlot` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnBuyBankSlot(Player* player, uint32 slot, uint32 price)` |
| `OnLogOut` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnLogOut(Player* player)` |
| `OnPreCharacterCreated` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnPreCharacterCreated(Player* player)` |
| `OnDeath(Player* player, Unit* killer)` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnDeath(Player* player, Unit* killer)` |
| `OnDeath(Player* player, uint8 environmentalDamageType)` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnDeath(Player* player, uint8 environmentalDamageType)` |
| `OnModifyMoney` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnModifyMoney(Player* player, int32 diff)` |
| `OnGiveLevel` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnGiveLevel(Player* player, uint32 level)` |
| `OnAddSpell` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnAddSpell(Player* player, uint32 spellId)` |
| `OnResetTalents` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnResetTalents(Player* player, uint32 cost)` |
| `OnDeleteFromDB` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnDeleteFromDB(uint32 playerId)` |
| `OnUpdateSkill` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnUpdateSkill(Player* player, uint16 skillId)` |
| `OnAreaExplored` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnAreaExplored(Player* player, uint32 areaId)` |
| `OnUpdateHonor` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnUpdateHonor(Player* player)` |
| `OnRewardHonor` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnRewardHonor(Player* player, Unit* victim)` |
| `OnDuelComplete` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnDuelComplete(Player* player, Player* opponent, uint8 type)` |
| `OnStoreItem` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnStoreItem(Player* player, Item* item)` |
| `OnEquipItem` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnEquipItem(Player* player, Item* item)` |
| `OnMoveItemToInventory` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnMoveItemToInventory(Player* player, Item* item)` |
| `OnRewardQuest` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnRewardQuest(Player* player, const Quest* quest)` |
| `OnKilledMonsterCredit` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnKilledMonsterCredit(Player* player, uint32 entry, ObjectGuid& guid)` |
| `OnPreLoadFromDB` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnPreLoadFromDB(Player* player)` |
| `OnLoadFromDB` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnLoadFromDB(Player* player)` |
| `OnSaveToDB` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnSaveToDB(Player* player)` |
| `OnTaxiFlightRouteStart` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnTaxiFlightRouteStart(Player* player, const Taxi::Tracker& taxiTracker, bool initial)` |
| `OnTaxiFlightRouteEnd` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnTaxiFlightRouteEnd(Player* player, const Taxi::Tracker& taxiTracker, bool final)` |
| `OnSummoned` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnSummoned(Player* player, const ObjectGuid& summoner)` |
| `OnRewardPlayerAtKill` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnRewardPlayerAtKill(Player* player, Unit* victim)` |
| `OnHandleFall` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnHandleFall(Player* player, const MovementInfo& movementInfo, float lastFallZ, uint32 damage)` |
| `OnHandlePageTextQuery` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnHandlePageTextQuery(Player* player, const WorldPacket& packet)` |
| `OnDealDamage` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnDealDamage(Unit* dealer, Unit* victim, uint32 health, uint32 damage)` |
| `OnKill` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnKill(Unit* killer, Unit* victim)` |
| `OnDealHeal` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnDealHeal(Unit* dealer, Unit* victim, int32 gain, uint32 addHealth)` |
| `OnHandleLootMasterGive` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnHandleLootMasterGive(Loot* loot, Player* target, LootItem* lootItem)` |
| `OnPlayerWinRoll` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnPlayerWinRoll(Loot* loot, Player* player, uint8 rollType, uint8 rollAmount, uint32 itemSlot, uint8 inventoryResult)` |
| `OnSendGold` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnSendGold(Loot* loot, Player* player, uint32 gold, uint8 lootMethod)` |
| `OnPlayerRoll` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnPlayerRoll(Loot* loot, Player* player, uint32 itemSlot, uint8 rollType)` |
| `OnSendMail` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnSendMail(const MailDraft& mail, Player* player, const ObjectGuid& receiver, uint32 cost)` |
| `OnAbandonQuest` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnAbandonQuest(Player* player, uint32 questId)` |
| `OnSetReputation` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnSetReputation(Player* player, const FactionEntry* factionEntry, int32 standing, bool incremental)` |
| `OnHit` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnHit(Spell* spell, Unit* caster, Unit* target)` |
| `OnCast` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnCast(Spell* spell, Unit* caster, Unit* target)` |
| `OnUseItem` | Needed because current core has no global callback replacement for this event | `AchievementsModule::OnUseItem(Player* player, Item* item)` |

### C. Unused and removable (34)

| Hook | Why removable |
|---|---|
| `OnPreGossipHello` | No achievement-source consumer was found in the current module |
| `OnExecuteCommand` | No achievement-source consumer was found in the current module |
| `OnAddToWorld` | No achievement-source consumer was found in the current module |
| `OnRespawn` | No achievement-source consumer was found in the current module |
| `OnRespawnRequest` | No achievement-source consumer was found in the current module |
| `OnGossipHello` | No achievement-source consumer was found in the current module |
| `OnBuyBackItem` | No achievement-source consumer was found in the current module |
| `OnGossipSelect` | No achievement-source consumer was found in the current module |
| `OnCharacterCreated` | No achievement-source consumer was found in the current module |
| `OnGiveXP` | No achievement-source consumer was found in the current module |
| `OnGetPlayerLevelInfo` | No achievement-source consumer was found in the current module |
| `OnPreResurrect` | No achievement-source consumer was found in the current module |
| `OnResurrect` | No achievement-source consumer was found in the current module |
| `OnReleaseSpirit` | No achievement-source consumer was found in the current module |
| `OnSetVisibleItemSlot` | No achievement-source consumer was found in the current module |
| `OnMoveItemFromInventory` | No achievement-source consumer was found in the current module |
| `OnLoadActionButtons` | No achievement-source consumer was found in the current module |
| `OnSaveActionButtons` | No achievement-source consumer was found in the current module |
| `OnPreRewardPlayerAtKill` | No achievement-source consumer was found in the current module |
| `OnPreHandleFall` | No achievement-source consumer was found in the current module |
| `OnLearnTalent` | No achievement-source consumer was found in the current module |
| `OnCalculateEffectiveDodgeChance` | No achievement-source consumer was found in the current module |
| `OnCalculateEffectiveParryChance` | No achievement-source consumer was found in the current module |
| `OnCalculateEffectiveBlockChance` | No achievement-source consumer was found in the current module |
| `OnCalculateEffectiveCritChance` | No achievement-source consumer was found in the current module |
| `OnCalculateEffectiveMissChance` | No achievement-source consumer was found in the current module |
| `OnCalculateSpellMissChance` | No achievement-source consumer was found in the current module |
| `OnGetAttackDistance` | No achievement-source consumer was found in the current module |
| `OnAddItem` | No achievement-source consumer was found in the current module |
| `OnFillLoot` | No achievement-source consumer was found in the current module |
| `OnGenerateMoneyLoot` | No achievement-source consumer was found in the current module |
| `OnWriteDump` | No achievement-source consumer was found in the current module |
| `IsModuleDumpTable` | No achievement-source consumer was found in the current module |
| `OnWorldPreInitialized` | No achievement-source consumer was found in the current module |

## Recommendation

- Do **not** restore the old generic module framework.
- Keep only a thin achievement-specific hook surface for the Category B events.
- Delete all Category C call sites while shrinking the patch.
- Revisit Category A only if upstream later grows a real global callback API.
