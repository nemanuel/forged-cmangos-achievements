# ScriptMgr Migration Audit

## Current upstream event systems searched

Current `cmangos/mangos-classic` does **not** expose Trinity-style `PlayerScript`, `UnitScript`, `CreatureScript`, or `WorldScript` classes.

Relevant upstream systems found during audit:

| System | Location | What it provides | Why it does not replace Module hooks globally |
|---|---|---|---|
| `ScriptMgr` (DBScripts) | `src/game/DBScripts/ScriptMgr.h` | Database-driven script command execution | No generic C++ observer callbacks for player/unit/world events |
| `ScriptDevAIMgr` | `src/game/AI/ScriptDevAI/ScriptDevAIMgr.h` | Per-script function pointers for gossip, quest, GO, and event handling | Entry-specific scripted objects only; not a server-wide event bus |
| `CreatureEventAI` | `src/game/AI/EventAI/CreatureEventAI.h` | Database creature event AI | Creature-only and DB-driven |
| `SpellScript` / `AuraScript` | `src/game/Spells/Scripts/SpellScript.h` | Per-spell virtual callbacks | Spell-local only; not a global hook system |

## Per-hook replacement decision (55 hook consumer rows)

| Achievement hook | Candidate in current core | Decision |
|---|---|---|
| `OnWorldInitialized` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnWorldUpdated` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnSellItem(AuctionEntry* auctionEntry, Player* player)` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnSellItem(Player* player, Item* item, uint32 money)` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnUpdateBid` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnEndBattleGround` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnLeaveBattleGround` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnJoinBattleGround` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnStartBattleGround` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnUpdatePlayerScore` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnPickUpFlag` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnEmote` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnUse` | ScriptDevAIMgr::OnGameObjectUse | No - only fires for gameobjects with attached script entries, not for all objects used by achievement criteria |
| `OnBuyBankSlot` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnLogOut` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnPreCharacterCreated` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnDeath(Player* player, Unit* killer)` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnDeath(Player* player, uint8 environmentalDamageType)` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnModifyMoney` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnGiveLevel` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnAddSpell` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnResetTalents` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnDeleteFromDB` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnUpdateSkill` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnAreaExplored` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnUpdateHonor` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnRewardHonor` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnDuelComplete` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnStoreItem` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnEquipItem` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnMoveItemToInventory` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnRewardQuest` | ScriptDevAIMgr::OnQuestRewarded | No - only scripted NPC quest handlers, not a global observer for every quest completion |
| `OnKilledMonsterCredit` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnPreLoadFromDB` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnLoadFromDB` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnSaveToDB` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnTaxiFlightRouteStart` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnTaxiFlightRouteEnd` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnSummoned` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnRewardPlayerAtKill` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnHandleFall` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnHandlePageTextQuery` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnDealDamage` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnKill` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnDealHeal` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnHandleLootMasterGive` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnPlayerWinRoll` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnSendGold` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnPlayerRoll` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnSendMail` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnAbandonQuest` | ScriptDevAIMgr quest callbacks | No - quest script callbacks are per scripted object, not a server-wide player hook |
| `OnSetReputation` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |
| `OnHit` | SpellScript | No - SpellScript is per-spell and not a replacement for a global spell-hit observer |
| `OnCast` | SpellScript | No - SpellScript is per-spell and would require patching or registering every relevant spell rather than observing all casts globally |
| `OnUseItem` | None | No - current mangos-classic has no global callback for this event outside the removed module framework |

## Result

- **Replaceable via existing ScriptMgr-style callback system:** none
- **Partially similar but not drop-in systems:** `ScriptDevAIMgr` for some quest/GO flows and `SpellScript` for spell-local logic
- **Practical implication:** migrating to a modern module requires a narrow achievement-specific core hook layer rather than reviving the full historical module framework
