# Bug hunt session 6 - combat (read-only, code of branch `next`, worktree DD-Project-GameMaker-wt/next)

Method: read scr_combat, scr_status, scr_levelup, scr_loot, scr_db_enemy/skill/item and the battle controller events; traced scenarios by hand. Nothing was run or edited.
Paths below are relative to the `next` worktree. Not repeated: bughunt-session5.md and ISSUES.md items.

## 1. P2 - Potions and gear can be used from the Esc/Tab menu in a fight without spending the turn
- Where: `scripts/scr_menu/scr_menu.gml:966-984` (`TabMenu_OnConfirm`, cases "items" and "gear"), `TabItems_Use` :177-188, `Gear_Toggle` :284-304. The menu may open in battle at the root command menu, in the skill/item lists and during messages (`Menu_BattleAllowed` :756-771). None of these functions looks at `room == rm_battle` (only throwables are refused there, with a toast).
- Repro: fight, HP 3/20, press Esc on the command menu, Items tab, HP Potion, Confirm. HP goes up, the potion is spent, the enemy does not act, it is still the player's turn. Repeat for every potion in the bag. Same with Gear: swap armor/accessory before each enemy hit at no cost. `_bc.p` and `gs.player_ch` are the same struct, so the HUD shows the new HP at once.
- Side effect: `Battle_PlayerWeapon` (`scr_combat.gml:1309-1318`) keeps the weapon the fight started with, so a weapon swapped in the menu changes skill damage (`Combat_WeaponPower` reads `equip` live) but not the basic attack's power or bar type.
- Violates: D99 (the Items command is a turn), D140/D141 only say the menu "works in battle" with Abandon and Quit enabled; turn economy of D74.
- Fix idea: in a fight make Items and Gear read-only (rows dim, toast "Not now"), or route a potion use through `Battle_PlayerItem` so it ends the turn.

## 2. P2 - A Rest at the bed is accepted at full HP and MP and uses the bed up
- Where: `scripts/scr_levelup/scr_levelup.gml:413-428` (`Bed_Choose`, heal branch always `ok = true`), `Bed_MenuItems` :432-438 (Rest always `enabled: true`), `scripts/scr_menu/scr_menu.gml:1804-1812` (`BedUi_Choose` prints "HP and MP are full again").
- Repro: arrive at a bed with HP 20/20, MP 8/8, choose Rest. Nothing changes, the bed is marked used (once per run per bed, D47), and the "wake with all HP and MP" line plays. The bed is gone for the rest of the run.
- Violates: D156 "full-HP bed and full potions are refused (and a sweep for similar logic)". Potions are refused (`Item_Use`), the bed was missed.
- Fix idea: `Bed_Choose` returns `ok = false` for "heal" when `hp >= max_hp && mp >= max_mp` (and `Bed_MenuItems` dims the Rest row with a short reason).

## 3. P2 - Closing the window during a fight saves nothing (D141 snapshot is only used by "Quit to title")
- Where: `objects/obj_game_controller/Other_3.gml:2` calls `Run_SaveOnClose` (`scr_room_state.gml:863-867`), which calls `Run_AutoSave`; `Run_AutosaveAllowed` (:822-824) returns false in `rm_battle`. The fight's "moment just before the encounter" is stored in `global.encounter_snapshot` and written only by `Menu_QuitToTitle` (`scr_menu.gml:734-735`, `EnemyPersist_WriteSnapshot` :1260).
- Repro: open a chest (card pick, item) and walk into an enemy within the 10 s autosave gap, then Alt-F4 or click X in the fight. The run file is the older autosave, so the chest, pickups and card are lost. Quit to title in the same fight keeps them.
- Violates: D132 (closing the window saves the run) read together with D141. Note: the Game End event is now imported (`obj_game_controller.yy` has eventType 7), so ISSUES I-071 ("waiting on owner") is already done and this gap is the live part of it.
- Fix idea: in `Run_SaveOnClose`, when `room == rm_battle` and `EnemyPersist_HasSnapshot()`, return `EnemyPersist_WriteSnapshot()` (and clear the snapshot when a fight ends, see session-5 H1).

## 4. P2 - Guard (Brace) can run out before the enemy ever hits
- Where: `scripts/scr_combat/scr_combat.gml:2788-2799` (`Battle_GuardApply` -> `Status_Add(STATUS_BRACE, 2)` then `Battle_PlayerFinalizeTurn` -> `Status_Tick`), `scripts/scr_status/scr_status.gml:285-298` (duration 2, comment "fades after the enemy's turn"), tick rules :816-850. Brace is on the player, so it only ticks on the player's own turns, never on the enemy's.
- Repro A (D74 double turn): Archer SPD 14 against a Slime SPD 9 gives the order P E P P E. Guard on the first P of the "P P": tick 2 -> 1, the second P tick 1 -> 0, Brace is gone, the enemy's hit is unguarded.
- Repro B: Guard, the enemy spends its turn on a wind-up or a buff (no hit), the player's next action ticks Brace away, the big attack lands unguarded.
- Violates: D99 "the next hit deals half" and the status text "Braced for the next hit".
- Fix idea: do not tick Brace on the player's turns; remove it after the enemy's turn ends (or `no_tick_on_apply` plus an expiry in `Battle_EnemyFinalizeTurnState`).

## 5. P3 - Take Aim and Muscle Up last one turn less than their tooltip says
- Where: `scripts/scr_status/scr_status.gml:207-216` (STATUS_CRIT_UP) and :172-182 (STATUS_GUARD) have no `no_tick_on_apply`; Foresight and Evasion have it for exactly this reason (:197, :189). Tooltips: `Battle_SkillDetails` `scr_combat.gml:2714` and `Card_SkillSentence` "Gain {status} for {turns} turns" (`scr_db_skill.gml`, Take Aim `status_turns: 9`, Muscle Up 6).
- Repro: cast Take Aim ("9 turns"). The cast turn's own tick runs at once, the chip reads 8, and only 8 later actions get the 25% crit bag. Muscle Up "6" gives 5. The upgrades ("9 > 12", "6 > 8") shift the same way.
- Violates: D100/BUG-16 (the tooltip number equals the applied number), D21 "durations shown with a turn counter".
- Fix idea: add `no_tick_on_apply: true` to STATUS_CRIT_UP and STATUS_GUARD (Meditation counts its cast-turn tick as an MP tick, so leave it).

## 6. P3 - An item the Stranger steals is lost for good if you flee, and a Smoke Bomb escape skips the Stranger line
- Where: `scripts/scr_db_skill/scr_db_skill.gml:1251-1253` removes the item from the player's inventory and records it only on the battle copy of the enemy (`stolen_items`); it is handed back only in `Battle_GrantRewards` (`scr_combat.gml:441-443`, victory). The flee success path (`:1735-1741`) and the Perfect Smoke Bomb escape (`:1684-1690`) end the fight without giving it back. The Stranger's "first encounter" reaction is queued only in the Run path (`:1737-1739`), not in the Smoke Bomb escape.
- Repro: take the Stranger under 50% HP, he steals a potion or an unworn spare weapon, press Run (or throw a Perfect Smoke Bomb). Back on the map the item is gone; the Stranger on the map is alive with nothing.
- Violates: the intent of I-072 ("stolen items never returned", fixed only for victory); inconsistent between the two escape paths.
- Fix idea: on any escape put `e.stolen_items` back into the inventory (or let the Stranger keep them in the room state); call `Dialogue_NarrativeOnStrangerEncounterResolved()` from the Smoke Bomb escape too.

## Looked at and found sound (no finding)
Damage formula and grades (D61, D77), poison/burn/bleed stacking and ticks (D78), Foresight and Evasion `no_tick_on_apply`, stun/steadfast/BREAK on the timeline (D75), flee chance (D121), marble bags for crits, status chances, enemy deck and gold (D119, D126), drop protection (D120), defence-bar status cutting (D21), level-up maths and card debts, enemy action chains and wind-up, HP/MP clamps, division guards.
Minor, not counted: `Pinning Shot` (`scr_equip.gml:442`, `random(1)`) and the Steal item pick (`scr_db_skill.gml:1240`, `irandom`) roll outside the run's streams (D126, D33); `RunStats_FightWon` is not called for auto-resolved fights (D137); `stat_points_gained` is never counted (dead field).
