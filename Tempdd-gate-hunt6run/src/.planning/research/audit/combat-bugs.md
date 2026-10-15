# Combat playtest notes: investigation (read-only audit)

Source of the notes: `.planning/research/playtest-notes.md` (friend's playtest, 2026-10). Code state: `v1.8`, HEAD `0b6e2f8`. Nothing was edited. Companion numbers are in `balance-data.md` and `data/*.csv`.

Tags: **VERIFIED** = confirmed by reading the code path end to end (what the code does is certain; whether it matches what the player saw is stated separately). **SUSPECTED** = could not reproduce by static reading, cause is a hypothesis. **[calc]** = exact arithmetic; **[model]** = my Monte-Carlo re-implementation (not run in the game); **[inferred]** = needs a GameMaker behaviour I could not run.

A caution that applies to items 4, 5 and 6: several of these were already "fixed" in commit `f39236b` (2026-03-05, "player testing fixes"): the skillbook de-duplication, the stationary mini boss, the faster player skill FX and the +4 skill hit bonus. HEAD contains all of them, so either the friend played a build older than that commit, or the fixes are not enough. The notes do not say which build was played; **ask which build/APK the friend used before changing code.**

## Summary table

| # | note | verdict | one-line cause |
|---|---|---|---|
| 1 | no damage while poisoned | tick VERIFIED to exist; report not reproducible statically (SUSPECTED perception) | player is ticked 2-3 HP after each of his own actions, nearly silently; skipped on the killing blow, failed Run |
| 2 | Foresight, what does it do | VERIFIED (mechanics + description) | "next skill cannot miss", 9 actions, wasted by a basic attack; shown only as a tiny "Foresight+" text tag |
| 3 | "bone shud be foresight +" | SUSPECTED (no bone item/skill exists) | most likely about the buff label/icon; see candidates |
| 4 | skill books twice | SUSPECTED, not reproducible at HEAD | two guards already exist (Inv_Add, menu dedupe); likely old save or old build |
| 5 | Ice Spear / Hilt Bash animation slow | VERIFIED (timing) | both sit at the speed cap already; length = native frames, plus a fixed 1 s hold |
| 6 | mini boss moves | SUSPECTED stale build; HEAD code cannot move him | `ai_stationary = true` since f39236b |
| 7 | 4-5 missed Horizontal Slashes | VERIFIED math: 66-89% hit; a 4-5 streak is a ~1-10% per-session event | RNG plus slime Solidify; weapon acc / Foresight irrelevant |

---

## 1. "I don't take damage while being poisoned"

**What the code does (VERIFIED).**

Application. Only the Spider applies Poison (`Poison Fangs`, scr_db_skill.gml:308-332: power 2, status Poison, `status_chance 0.70`, `uses_defensive_qte`, used with chance 0.10-0.25 per action and never on the action after another skill). On a hit the roll is `random(1) <= 0.70 * enemy_status_chance_mult` (scr_db_skill.gml:1147-1153). Base duration 2 -> 4 after `Skill_AdjustStatusTurns` (scr_db_skill.gml:865-869, 882-885); then, because the skill has a defensive QTE and did damage, `Battle_DefQTEAdjustPlayerStatuses` overwrites the duration with `round(2 * (1 + 3*(1 - ratio)))`, i.e. 2 ticks if every arrow prompt was hit, 8 if none (scr_combat.gml:1172-1230). Probability a given spider action poisons you: about 0.175 x 0.45 (hit) x 0.70 = 6% [calc].

Tick. `Status_Tick(p)` is called from `Battle_PlayerFinalizeTurn` (scr_combat.gml:470-473) after every player action: timed basic attack (L619), skill (L722), item (L755), and the stun skip (L457). Poison is `tick:{hp_min:-3, hp_max:-2}` (scr_status.gml:124); `Status_Tick` does `delta = irandom_range(-3,-2); _ch.hp = clamp(_ch.hp + delta, 0, _ch.max_hp)` (scr_status.gml:496-501), then `turns -= 1` and removes at 0 (L510-513). Death is checked right after (`Battle_CheckEnd`, scr_combat.gml:473). The HUD reads `bc.p` live (obj_ui_controller/Draw_64.gml:16, 66-68) and flashes the bars for 8 frames when HP drops (obj_ui_controller/Step_0.gml:11-17, Draw_64.gml:56-65). So in code the player **does** lose 2-3 HP per own action while poisoned; no code path nullifies it (armor passives only touch `Combat_ApplyDamage`, scr_combat.gml:109-116; Mirror Stitch can reflect the status away on application, scr_equip.gml:249-268).

**Why it can look like "no damage" (SUSPECTED, in order of likelihood).**
1. The tick is nearly silent: no log line, no damage number, no SFX, no camera shake (every enemy hit shakes the camera, scr_combat.gml:1282/1521/1571; the tick does none). The only cues are the `HP x / y` text changing by 2-3 and a brief bar flash, while the player has 15-24 HP and the battle log is busy with other messages.
2. Poison only ticks on the *player's* actions. If poison lands on the enemy's last action and the player's next action kills the enemy, it never ticks: the kill is resolved before `Battle_PlayerFinalizeTurn` (`Battle_CheckEnd` returns early at scr_combat.gml:596 for the timed attack and L697 for skills, L752 for items) and `Status_ClearAll` wipes it at battle end (L387). A failed Run also does not tick (scr_combat.gml:799-803, no `Status_Tick`).
3. A perfect defensive QTE shortens it to 2 ticks (about 5 HP total).
4. Poison also silently gives INT -1 (`stat_mods`, scr_status.gml:123) and its description says only "Lose 2-3 HP each turn." (scr_status.gml:321).

**Acceptance check to write first (Rule 1):** with Normal difficulty and a debug-added Poison status (turns 4) on a full-HP player in `rm_battle`, press Attack -> HP must fall by 2 or 3 after the attack resolves, once per player action, 4 times; then Run (failed) -> no change. If this passes in the IDE the report is a feedback problem, not a damage bug.

**Suggested direction (not applied):** add a combat-log line and a hit SFX/flash for DoT ticks (the log hook is `Combat_Log`, scr_combat.gml:184-209).

---

## 2. "Foresight skill - idk what it does"

**What it does (VERIFIED).** Mage skill, 3 MP, target self, no damage (scr_db_skill.gml:283-302): applies status `STATUS_HIT_UP` named "Foresight" with `always_hit: true, consume_on_attack: true` (scr_status.gml:205-215).
- `always_hit`: in `Combat_AttemptHit` the attacker's roll is skipped and the result is a hit (scr_combat.gml:75-79). It only matters for hit rolls, i.e. **player skills** (and `Double Shot`'s two hits are both covered, one consume after the loop, scr_db_skill.gml:1145). Order matters: a defender's `force_dodge` (Solidify, Evasion) is checked first and still wins (L68-73).
- Duration: base 3 -> **9** player actions (`Skill_AdjustStatusTurns`: non-DoT, player user, mult 3.0, scr_db_skill.gml:871-876), but it is removed by the first attack of any kind: `Status_ConsumeByField(..., "consume_on_attack")` after a damage skill (scr_db_skill.gml:1145) **and after a basic attack** (scr_combat.gml:594).
- **A basic attack never rolls to hit** (hit/miss is the timing minigame, scr_combat.gml:521-587), so casting Foresight and then pressing ATTACK spends 3 MP and an action for nothing.
- Value when used correctly: turns one skill's 66-89% hit chance into 100% [calc]: +11 to +34 points for one cast.

**How it is described to the player (VERIFIED).**
- Skill tooltip (`Tooltip_BuildSkillLines`, scr_menu.gml:698-722 -> `Tooltip_SkillEffectLines` case `"status"`, scr_menu.gml:444-452): `Foresight` / `MP 3 | Target: Self` / `Status: Foresight+ 100% | 3 turns` / `Foresight+: Next attack cannot miss.` (`Status_Description`, scr_status.gml:329; sign added by `Status_LabelWithSign`, scr_status.gml:547-554).
- The "3 turns" is the raw `status_turns` (scr_menu.gml:337-351); the real duration is 9.
- In battle the status is **not shown as an icon**: both HUD calls pass `_noncore_text_fallback = true` (obj_ui_controller/Draw_64.gml:73, obj_battle_controller/Draw_64.gml:196), and only Poison/Bleed/Burn/Stun count as "core" icons (`Status_UsesCoreIconSprite`, scr_status.gml:524-533), so Foresight is drawn as a 0.45-scale text tag "Foresight+" (scr_status.gml:556-566, 587/606; `UI_STATUS_FALLBACK_TEXT_SCALE 0.45`, scr_macros.gml:158).
- The cast animation (an eye opening, `foresight_effect_Sheet`, 10 frames) is spawned **on the enemy**, not the player: `Battle_PlayerSkill` places every skill's FX at the enemy position, self-buffs included (scr_combat.gml:676-686). So the player sees an eye open over the monster.
- Wording issue: the tooltip never says it is for skills only, nor that it lasts until you attack, nor that a basic attack burns it.

**Suggested direction (not applied):** say "Your next skill cannot miss (basic attacks do not use it)" or let it apply to the timing result too; draw buff FX on the player; show real icons.

---

## 3. "Bone should be Foresight +"

**There is no bone item or skill in the game data (VERIFIED).** `grep -ri bone` over scripts/objects finds only: `obj_bone` (objects/obj_bone/Create_0.gml: `sprite_id = bone_asset; interact_name = "Bones"; dialogue_id = "bone"`), a single placement in `rm_floor8` at (96,64) (rooms/rm_floor8/rm_floor8.yy:92), and its dialogue line "A pile of old bones." (scr_dialogue.gml:143). It is a prop with no gameplay effect. `ItemDB`, `SkillDB`, `StatusDB` contain nothing named bone; the Foresight skillbook is item 114 "Skillbook: Foresight" (scr_db_item.gml:564-580).

**Candidate readings (SUSPECTED, cannot tell which):**
1. The friend means the buff *icon/label*: "foresight +" is literally what the HUD prints (`Foresight+`, section 2), and Foresight has no icon in battle. The word may be a mis-typed "icon" ("icon should be foresight +"). Consistent with the owner's own note that buff icons are placeholders (`Status_AssignPlayerBuffIconsFromFX`, scr_status.gml:40-56: Guard uses `rock1`, Rev Up `torch_asset_moving`, Evasion `tall_grass_asset`, Take Aim `skull_2_asset`, Foresight falls back to `take_aim_effect` / `skull_2_asset` if its sprite is missing).
2. A skull/bone-looking placeholder was visible on the Foresight/Take Aim status in an older build: `skull_2_asset` is the Take Aim icon and the Foresight fallback (scr_status.gml:46-47, 195-215); the `noncore_text_fallback` argument was only added in `f39236b` (2026-03-05).
3. A design request: "Foresight+" as a stronger variant (e.g. a bone-themed item that grants it). Nothing in the code supports this.

Ask the friend one question: "was 'bone' an icon, the floor-8 bones prop, or a skill name?"

---

## 4. "Skill books appear in books twice"

**What the code does (VERIFIED).** The inventory tab lists `ch.inventory` through `Menu_InventoryDisplayItems` (scr_menu.gml:863-881; used at L1184 and L1373), which already drops a second entry of the same skillbook id (L872-878). `Inv_Add` already refuses a second copy of a skillbook, weapon or armor (`unique_once`, scr_inventory.gml:20-38: `Inv_Has` guard at L23, plus a check against `player_ch.skills` at L25-33). Skillbooks are `stackable:false, max_stack:1` (scr_db_item.gml:329-580). All inventory writes go through `Inv_Add` (grep: obj_item_pickup/Step_0.gml:6, `Loot_Grant` scr_loot.gml:404-416, scr_equip.gml:527, scr_debug.gml:85/101); there is no other `array_push` into an inventory. Chests/graves exclude owned books (`Loot_ItemEligibleForPlayer`, scr_loot.gml:182-195). The tooltip already hides the redundant "Teaches: X" line (scr_menu.gml:666). Both guards were added in `f39236b`.

**Therefore I cannot produce a duplicate at HEAD (SUSPECTED explanations):**
1. Older build: duplicates were possible before `f39236b`.
2. An existing save that already contains two entries: the menu hides the second, but after reading the first (`Inv_Remove` removes one, scr_menu.gml:1094) the second stays in the inventory forever (unreadable, "Already know X", scr_db_item.gml:843-846) and keeps showing as one book.
3. The friend means the *Skills* tab or the tooltip (skill name shown in the item name and again in "Teaches"): the Skills tab draws `ch.skills` directly with no de-duplication (scr_menu.gml:1436-1470), though `Player_LearnSkill` refuses duplicates (scr_player.gml:1864-1877).
4. The same book appearing from two sources in the same playthrough (chest and grave) is prevented by the eligibility checks above; the only remaining way is an old save.

**Acceptance check to write first:** GML assertion from a debug entry point: build an inventory with `Inv_Add` x2 for id 114 -> `array_length == 1`; push a duplicate struct manually, run `Menu_InventoryDisplayItems` -> 1 entry; then load the friend's save (if available) and assert no duplicate ids among skillbooks and no duplicate ids in `skills`.

---

## 5. "Ice spear animation is slow", "hilt bash animation slow"

**What decides an animation's length (VERIFIED).**
- `Skill_Use` computes `fx_speed`: player skill on an enemy = `fx_speed 0.2 x PLAYER_SKILL_FX_SPEED_MULT 6.0 = 1.2`, or the per-skill `player_fx_speed_mult`, **clamped to `PLAYER_SKILL_FX_SPEED_MAX 1.3`** (scr_db_skill.gml:917-930; scr_macros.gml:209-212). Self-buffs use `0.2 x 3.0 = 0.6` and are not clamped.
- `FX_Spawn` sets that as `image_speed` (scr_combat.gml:130-154); `obj_fx` destroys itself when the animation wraps (obj_fx/Step_0.gml:10-14).
- The battle message state waits for the FX instance to disappear, then another `COMBAT_ACTION_DELAY 60` frames (1 s) before the next state (`Battle_Message`, scr_combat.gml:211-218; obj_battle_controller/Step_0.gml:38-47). So **action time = animation + 1.0 s**. A miss spawns no FX (scr_combat.gml:677) so a miss is faster than a hit.
- All 14 player-skill fx sprites are 48x48 at a native 8 fps (sprites/*/*.yy: `playbackSpeed 8, playbackSpeedType 0`). With `image_speed` as a multiplier of native speed, seconds = frames x 7.5 / image_speed / 60 [inferred; the ordering is exact either way].

| skill | sprite frames | image_speed | animation | + 1 s hold | trailing near-empty/static frames |
|---|---|---|---|---|---|
| Horizontal Slash | 5 | 1.2 | 0.52 s | 1.52 s | 1 (last frame blank) |
| Double Shot | 7 | 1.2 | 0.73 s | 1.73 s | 1 |
| Poison Mist | 8 | 1.2 | 0.83 s | 1.83 s | 0 |
| **Hilt Bash** (stun_effect) | 9 | **1.3 (cap)** | 0.86 s | 1.86 s | **2** (frame 8 has 15 px, frame 9 is empty) |
| Fireball | 9 | 1.2 | 0.94 s | 1.94 s | 2 (last frame empty) |
| **Ice Spear** | 12 | **1.3 (cap)** | 1.15 s | 2.15 s | 1 |
| Wound | 12 | 1.2 | 1.25 s | 2.25 s | 8 (bleed drip is nearly static from frame 5) |
| Poison Arrow | 12 | 1.2 | 1.25 s | 2.25 s | 3 |
| self-buffs: Muscle Up / Evasion / Rev Up / Foresight / Meditation / Take Aim | 7 / 9 / 10 / 10 / 11 / 12 | 0.6 | 1.46 / 1.88 / 2.08 / 2.08 / 2.29 / 2.50 s | 2.5-3.5 s | 0-3 |

**Findings.**
- Ice Spear and Hilt Bash are **already at the maximum speed the code allows** (`player_fx_speed_mult 6.5` = 1.3 = the clamp, scr_db_skill.gml:44, 257). The previous "speed-up" pass hit the ceiling, so raising `player_fx_speed_mult` further does nothing.
- Ice Spear is slow because it is a 12-frame sprite with no wasted frames (a spear falls for 4 frames, then crystals grow to full size on frames 5-12), so it takes 1.15 s; Wound and Poison Arrow are longer (1.25 s) but are not complained about.
- Hilt Bash is mid-pack (0.86 s) but its last two frames are empty, and, more importantly, it is a stun skill that grants **two extra player actions** (scr_combat.gml:699-704), so the player sits through three full action cycles (FX + 1 s hold each) per enemy action. That makes it *feel* slowest. The same applies to Ice Spear.
- The longest waits in the game are the self-buffs (up to 3.5 s for Take Aim), and they play over the enemy (scr_combat.gml:676-686).

**Suggested directions (not applied):** raise `PLAYER_SKILL_FX_SPEED_MAX` or trim frames (`stun_effect` frames 8-9, `explosion_effect` frame 9, `bleed_effect` frames 5-12); shorten the 60-frame hold for free-action turns; let the message state not wait for the tail frames.

---

## 6. "Mini boss moves around so he isn't blocking the way"

**What the code does at HEAD (VERIFIED).** The mini boss is `obj_mini_boss`, child of `obj_enemy` (`parentObjectId obj_enemy`, `solid:false`), one instance in `rm_floor5` at (224,32) with only `persist_id`/`cine_id` creation code (rooms/rm_floor5/InstanceCreationCode_inst_67DC45B9.gml). Its Create event (objects/obj_mini_boss/Create_0.gml:1-8) sets `enemy_id`, calls `Enemy_ApplyConfig`, then `ai_stationary = true; wander_chance = 0; moving = false`. `EnemyAI_Update` returns before any decision or movement when `ai_stationary` is true (scr_enemy.gml:427-432); there is no other code that moves an enemy (`x`/`y` are only saved and restored, `RoomState_Save`, scr_room_state.gml:243-249, and a stationary instance never changes them). His config also has `wander_chance 0` and `ai.move_speed 1.15` unused (scr_db_enemy.gml:245).

So he cannot move around at HEAD. The commit that made him stationary is `f39236b` (2026-03-05; it also adds the `ai_stationary` check in obj_enemy/Step_0.gml:40-47). **Most likely the friend's build predates it (SUSPECTED).**

Other things that can look like "moving" or "not blocking":
- His world sprite `mini_boss_moving` is a 2-frame 16x16 walk cycle at `image_speed 0.15` (obj_enemy/Create_0.gml, sprites/mini_boss_moving), so it animates in place and looks like pacing.
- The enemy is not `solid`; the encounter comes from collision plus a "safety net" that starts the fight whenever the player is within **64 px (4 tiles) square** of a stationary enemy (`scan_radius 64`, obj_enemy/Step_0.gml:40-47) once the player is settled. So he blocks by triggering, not by occupying a tile, and during the 60-frame post-battle cooldown (`battle_cooldown`) the player can walk past (Collision_obj_player.gml:3-4, Step_0.gml:41).
- Layout: he stands on the 1-tile corridor row y=32, 48 px from the exit transition to floor 6 at (272,32); walls at y=16 above and (240..272,48) below, `obj_horned_skull` at (224,48) (rm_floor5.yy). At HEAD he is a proper gate.

**Acceptance check to write first:** open `rm_floor5`, wait 60 s without approaching: his `x,y` stay (224,32); walk to within 4 tiles: the encounter starts; lose/win the fight: he stays removed (`EnemyPersist_SetBossDefeated`, scr_room_state.gml:64-69).

---

## 7. "Missed 4-5 consecutive horizontal slashes"

**Real hit chance (VERIFIED math, [calc]).** Horizontal Slash is a Knight skill (STR, `acc 0`, 5 MP, power 5 x1.5; scr_db_skill.gml:91-110). Its roll (`Skill_Use`, scr_db_skill.gml:1111-1116 -> `Combat_AttemptHit`, scr_combat.gml:81-83): `d20 + 0 + StatMod(STR) + 4` against `d20 + StatMod(enemy AGI)`, ties to the attacker. Knight STR is 11 at L1 (+1 per level), so the bonus is +4 at L1-2, +5/+6 at L3-5, +7 at L6-7, +8 at L8-9, +9 at L10.

Exact hit chance vs typical enemies (from `balance-data.md` section 9):

| Knight level | Slime (AGI mod -1) | Spider/Snake/Wolf (0) | Whisp/Ghost/Stranger/Palehorn (+1) | Final boss (+2) |
|---|---|---|---|---|
| 1 | 73.8% | 70.0% | 66.0% | 61.8% |
| 3 | 77.2% | 73.8% | 70.0% | 66.0% |
| 5 | 80.5% | 77.2% | 73.8% | 70.0% |
| 7 | 83.5% | 80.5% | 77.2% | 73.8% |
| 9 | 86.2% | 83.5% | 80.5% | 77.2% |

So a miss happens 11-38% of the time, typically 20-34% (q). The weapon's `acc` is **not** part of the roll (basic attacks do not roll; skills use skill.acc, scr_db_skill.gml:1112), so a better sword does not help; neither does LUCK. Only STR (class growth), the skill's `acc` (Horizontal Slash has 0), `PLAYER_SKILL_HIT_BONUS` (4, scr_macros.gml:213) and Foresight change it. Bleed or Stun on the enemy (AGI -2, one point of modifier) helps by about 4-5 points.

**Streak probabilities (exact, [calc]).** Four given casts all missing: q^4 = 0.16% (q=0.2), 0.39% (q=0.25), 1.5% (q=0.35); five: 0.03% / 0.1% / 0.5%. For a session (probability of at least one run of 4+ somewhere):

| per-cast miss q | 20 casts | 40 casts | 80 casts | run of 5+ in 40 casts |
|---|---|---|---|---|
| 0.20 | 2.2% | 4.7% | 9.5% | 0.9% |
| 0.25 | 5.0% | 10.5% | 20.5% | 2.6% |
| 0.30 | 9.6% | 19.6% | 36.3% | 6.1% |
| 0.35 | 16.3% | 31.8% | 54.7% | 11.9% |

A 4-5 streak is therefore **plausible but not expected** in one playtest (roughly 1 in 10 at 40 casts and q=0.25; 1 in 40 for 5+). Aggravating factors that raise q on particular fights: a slime's `Solidify` (floors 1, 2, 6) is a `force_dodge` that auto-misses the next skill (scr_combat.gml:68-73), about 15% extra per turn [model]; an L1-2 Knight vs AGI +1 enemies is at 66%; Burn on the player (STR -1) lowers it by up to 4-5 points. The `+4` bonus (added in f39236b) is only applied when the struct has `is_player` set (scr_db_skill.gml:1113); a save loaded from an older version without that field would silently lose it (SUSPECTED, check that a loaded player has `is_player == true`).

**If the owner wants "a tiny bit" more:** each +2 on `PLAYER_SKILL_HIT_BONUS` adds about +6 points at L1-4 and +4-5 at L8-10 (L5 Knight vs AGI 0: bonus 4 = 77%, 6 = 84%, 8 = 89%). For that case the chance of at least one 4-miss run in a 40-cast session falls from 7.5% (bonus 4) to 2.3% (bonus 6) to 0.5% (bonus 8) [calc]. Do not weaken it for the Mage/Archer (same formula).

---

## Additional defects found while tracing (all VERIFIED unless marked)

| # | defect | evidence |
|---|---|---|
| A | **Stun skills give 2 free actions on any hit, even when the 60% stun roll fails**; with the enemy skipping a turn 60% of the time this makes Hilt Bash/Ice Spear the strongest skills in the game ([model]: Mage opening with Ice Spear then spending the free actions beats the final boss 93% at L10, vs 36% for a DoT-only policy that never casts Ice Spear). | scr_combat.gml:699-704 (grant not conditioned on the status landing) |
| B | `Curse` ignores `status_chance` 0.50 and the hit roll; its three DoTs cancel each other (exclusion) leaving only Bleed for 2 ticks, while the log says "Applied Burning, Poison, Bleeding." | scr_db_skill.gml:1003-1035; scr_status.gml:389-391 and DB excludes at L126,137,148 |
| C | Skill tooltips show the base status turns, not the applied ones (Foresight/Take Aim/Meditation "3 turns" = 9; Wound/Fireball "2 turns" = 5; Guard/Rev Up/Evasion 2 = 6). | scr_menu.gml:337-351 vs scr_db_skill.gml:854-888 |
| D | Weapon `acc` (shown as "Acc +1/+2" on tier-3 weapons) never affects a player roll. | grep: `Combat_AttackBonus` only called for enemies (scr_combat.gml:1542); skills ignore weapon (scr_db_skill.gml:1120) |
| E | A failed Run does not tick statuses/decay buffs. | scr_combat.gml:779-804 (no `Status_Tick`) |
| F | Self-buff animations play centred on the enemy, not the player. | scr_combat.gml:676-686 |
| G | All non-core statuses (every buff, Solidify, Bloodthirsty, Blessing) are shown as 0.45-scale text, not icons, in both HUDs. | obj_ui_controller/Draw_64.gml:73; obj_battle_controller/Draw_64.gml:196; scr_status.gml:587,606 |
| H | `SKILL_POWER_STRIKE` (id 0) has a macro and a localization key but no `SkillDB` record. | scr_macros.gml:86, scr_db_skill.gml:709-740 |
| I | Difficulty damage multipliers are floored on integers: Easy turns 1-damage enemy hits into 0, Hard player hits lose a flat 1; `player_stat_mult`/`enemy_stat_mult` are dead. | scr_combat.gml:102-103; scr_player.gml:64-113 |
| J | A Guarded (0-damage) enemy hit still applies its status and skips the defensive QTE, so Guard does not stop DoT skills (and DoT duration is not shortened by QTE). | scr_db_skill.gml:1137-1167; scr_combat.gml:1027-1036 (`dmg > 0` required for QTE) |
| K | Basic attacks pass `1 + crit_bonus` to `Combat_CritCheck` (+1% crit) while skills pass `crit_bonus`. | scr_combat.gml:563, 1551 vs scr_db_skill.gml:1111,1121 |
