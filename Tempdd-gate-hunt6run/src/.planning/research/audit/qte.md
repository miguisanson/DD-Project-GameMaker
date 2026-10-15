# QTE audit (battle)

Audit date 2026-10-13. Read-only; nothing in the game was edited or run. "Verified" = read in code. "Inferred" = my arithmetic or reasoning from the code, never run in the game.

## 0. The big surprise: there are TWO systems, and neither is where the playtester's complaint is

The project has two separate "QTE" mechanics. Both live in `scripts/scr_combat/scr_combat.gml`, `scripts/scr_macros/scr_macros.gml` and `objects/obj_battle_controller/`.

| | Offensive **Attack timing** | Defensive **QTE** ("Guarded x/y") |
|---|---|---|
| Triggered by | Player picks **ATTACK** (basic attack only) | An **enemy skill** that has `uses_defensive_qte: true` and actually hits |
| Player input | One press of confirm | One arrow press per prompt, 1 to 5 prompts |
| Effect | Decides hit or miss and damage tier | Cuts incoming damage by up to 50% and shortens status duration |
| Player SKILLS | **No timing at all** | n/a |

**A playtester missing 4 or 5 Horizontal Slashes in a row is NOT a QTE failure.** Horizontal Slash is a skill. Skills go `Battle_PlayerSkill` (`scr_combat.gml:658`) then `Skill_Use` (`scr_db_skill.gml:913`) then a plain d20 roll in `Combat_AttemptHit` (`scr_combat.gml:65`). There is no timing step on that path. See section 2.8.

---

## 1. How it works end to end

### 1A. Offensive attack timing (basic ATTACK only)

**Flow**
1. Menu: `ATTACK` has state `BSTATE_ATTACK_TIMING` (`obj_battle_controller/Create_0.gml:78`). On confirm, `Step_0.gml:77-78` calls `Battle_AttackTimingBegin` (`scr_combat.gml:494`).
2. Begin: the target point is the **centre of the enemy sprite** (`Battle_AttackTimingTarget`, `scr_combat.gml:406-443`). Enemies are always spawned at screen centre (`Create_0.gml:22-31`, view 160x144), so target Y is always about mid-screen.
3. The "falling" marker starts just above the top of the screen (`y = -10 * visualScale`, `scr_combat.gml:509`) and falls straight down at constant speed. Speed is rolled **once per swing**: `2.8 * enemy_rank_mult * random(0.8..1.3) * visualScale` px per frame (`scr_combat.gml:516-517`, `1001-1003`, macros `scr_macros.gml:218-224`).
4. Every Step (`Battle_PlayerAttackTimingStep`, `scr_combat.gml:622-652`): `attack_timing_y += speed`, then if confirm was pressed and the 2-frame input lock is over, judge `abs(y - target_y)`.
5. Judge (`scr_combat.gml:445-452`), distance converted back to base units by dividing by visual scale:
   - PERFECT: within 2 units, damage x1.00
   - GOOD: within 4 units, x0.75
   - OKAY: within 7 units, x0.50
   - BAD: within 10 units, x0.25
   - MISS: anything else, 0 damage and no hit
   - Macros: `scr_macros.gml:232-235`.
6. If the player never presses, the marker auto-resolves as MISS when it passes `target + 10 + 14` units (`scr_combat.gml:646-651`, `ATTACK_TIMING_END_MARGIN 14`).
7. Resolve (`Battle_PlayerAttackResolveTimed`, `scr_combat.gml:521-620`):
   - Equipment can forgive: `steady_strike` turns MISS into BAD and BAD into OKAY once per turn, and `aim_assist` turns GOOD into PERFECT once per turn (`scr_equip.gml:270-309`).
   - `timing_hit` **replaces the hit roll entirely**. Basic attack never calls `Combat_AttemptHit`, so STR, AGI and weapon accuracy have no effect on hitting.
   - If it hits: crit roll (`Combat_CritCheck`, 5% base, `scr_combat.gml:38-45`), then `Combat_ApplyDamage`, then damage is multiplied by the tier (`floor(base * mult)`, minimum 1, `scr_combat.gml:566-569`; the difference is refunded to enemy HP, which is a roundabout way of scaling).
   - PERFECT also feeds `Equip_PlayerPerfectHitApply` and `pinning_shot` (`scr_equip.gml:427`, `451-460`).

**What the player sees** (`Draw_64.gml:219-257`, drawn in GUI space at screen pixels)
- A dark grey 15px disc at the enemy centre (`spr_attack_timing_target`, fades in over 5 frames, `scr_combat.gml:632`).
- A white ring of the same size (`spr_attack_timing_falling`) sliding down from the top, drawn at full alpha from frame 1. Sprites are 16x16, scaled by `ATTACK_TIMING_SPRITE_SCALE 4 * ui_sprite` (`Draw_64.gml:227`).
- After the press: a white text label (PERFECT, GOOD, OKAY, BAD, MISS) floats above the target for 24 frames (0.4 s) (`Draw_64.gml:248-257`). Same colour for every grade.
- Then the normal message box ("You hit for N damage!" or "You missed!"), held for `COMBAT_ACTION_DELAY` 60 frames.

**Inputs**
- Keyboard: **Space only**. Enter is not bound ("UI confirm is intentionally space-only", `scr_input.gml:43-44`).
- Gamepad: face1 (A / Cross) (`scr_input.gml:226-228`).
- **Touch / mouse: none.** I grepped all scripts and objects for `device_mouse`, `mouse_check`, `touch`, virtual keys, `os_android`. There is no touch or mouse input code anywhere. The Android options file only turns on gamepad support (`options/android/options_android.yy:18`). On Android without a controller there is no way to press anything. This is not QTE-specific; it affects the whole game.

**Audio**: nothing plays while the ring falls and nothing plays at the moment of the press. On resolve, `SFX_PlayClassAttack` (`scr_combat.gml:547`) plays the class attack sound even on a miss, then `SFX_PlayMissOrBlocked` plays on a miss. There is no distinct sound for PERFECT vs GOOD vs BAD.

### 1B. Defensive QTE (enemy skills only)

**Which actions trigger it**
- Only enemy **skills** with `uses_defensive_qte: true` (`scr_db_skill.gml:328, 380, 433, 459, 485, 539`): Poison Fangs (Spider), Bite (Snake), Vine Trap (Killer Plant), Scorching Touch (Mad Whisp), Ghost Cut (Ghost Sword), Ramming (Palehorn).
- Gate: `Battle_EnemySkillCanUseDefQTE` (`scr_combat.gml:1027-1036`): effect is "damage", target is the player, `res.hit` is true, and damage > 0.
- **Enemy basic attacks (the non-skill path) never trigger it** (`scr_combat.gml:1532-1581`). Enemy skills trigger on a per-turn chance of 10-50% (e.g. Poison Fangs 0.10-0.25, Bite 0.25-0.30, Ghost Cut 0.50; `scr_db_skill.gml:330-331, 382-383, 487-488`), and an enemy can't use skills on two actions in a row (`scr_combat.gml:1449`). At rank 1 the QTE appears in only about 1 in 5 enemy turns.
- Dire Wolf's skill (Bloodthirsty), Slime (Solidify), Stranger (Steal), Rampage, Curse, Blessing and Final Fury have no QTE. The mini boss Palehorn (rank 3, `is_boss`) uses Ramming and so gets 3-5 prompts; the Final Boss's three skills are all non-damage, so the rank >= 4 branch of `Battle_DefQTEPromptCountForEnemy` is never reached in practice (inferred).

**Flow**
- The hit roll and damage are decided FIRST, inside `Skill_Use`, before any QTE (`scr_combat.gml:1474`). Then `Battle_DefQTEStart` (`scr_combat.gml:1136-1170`) builds 1 to 5 random arrows: 1 prompt at rank 1, 1-3 at rank 2, 2-4 at rank 3, 3-5 at rank 4 or boss (`scr_combat.gml:978-985`). Direction is `choose(UP, DOWN, LEFT, RIGHT)` per prompt (`scr_combat.gml:1005-1007`).
- Each prompt is a 4-phase state machine in `Battle_DefQTEStep` (`scr_combat.gml:1304-1394`):
  - phase 0: fade-in, input ignored
  - phase 1: input window
  - phase 2: feedback hold
  - phase 3: fade-out, then the next prompt
- Timings are defined in seconds (`scr_macros.gml:236-247`) and converted to frames once at start using `game_get_speed(gamespeed_fps)` (`scr_combat.gml:1143-1150`), divided by a speed multiplier (1.15 at rank 1, +0.08 per rank, max 1.45). I computed these frame counts at 60 fps:

| Rank | Fade-in (dead) | **Response window** | Feedback (dead) | Fade-out (dead) |
|---|---|---|---|---|
| 1 | 6 f | **104 f = 1.73 s** | 9 f | 5 f |
| 2 | 6 f | 98 f = 1.63 s | 9 f | 5 f |
| 3 | 5 f | 92 f = 1.53 s | 8 f | 5 f |
| 4 | 5 f | 86 f = 1.43 s | 8 f | 4 f |

- Input (`Battle_DefQTEInputDir`, `scr_combat.gml:1019-1025`): `Input_UIPressed` for move_up, move_down, move_left, move_right, checked in that fixed order. **The first direction pressed during phase 1 ends the prompt**: right = success, wrong = failure. No retry. Timeout = failure.
- Finalize (`Battle_DefQTEFinalize`, `scr_combat.gml:1232-1302`):
  - `ratio = successes / total`
  - damage = `floor(base_dmg * (1 - 0.50 * ratio))`, so the **best case is -50%** (`DEF_QTE_DAMAGE_REDUCTION_MAX`, `scr_macros.gml:243`)
  - status duration = `round(skill.status_turns * lerp(1.0, 4.0, 1 - ratio))` (`scr_combat.gml:1180-1207`, macros `244-245`). Failing every prompt makes a status last up to 4x its base turns. Full success gives 1x.
  - Stun is blocked completely only on 100% success (`DEF_QTE_STATUS_STUN_BLOCK_RATIO 1.00`).
- No randomness in timing. Randomness is only the arrow direction and the prompt count.

**What the player sees** (`Draw_64.gml:306-366`)
- One thin outline arrow (four 1-pixel `draw_line` calls, `Battle_DrawDirectionArrow`, `scr_combat.gml:1406-1428`), base size `9 * ui_sprite` px, centred below the enemy sprite. **No text, no label, no "n/total" counter, no list of the other arrows.**
- A small white bar (50 x 5 base units) under the arrow that drains over the response window (`Draw_64.gml:344-361`).
- After input: the arrow turns green and pops to 1.25x (success), or red and shrinks to 0.95x (fail or timeout), for about 0.15 s (`Draw_64.gml:340`, `scr_combat.gml:1369`). A timeout and a wrong key look identical.
- **Result text appears only afterwards**, in the message box: "Guarded {ok}/{total}. Damage -{pct}%." (`scr_combat.gml:1266-1275`).

**Inputs**: W/A/S/D and arrow keys (`scr_input.gml:15-18`), gamepad D-pad or left stick with deadzone 0.35 (`scr_input.gml:187-198`). Touch: none (see 1A).

**Audio**: each prompt plays `ui_move` (the menu cursor blip, `scr_combat.gml:1133`), success plays `ui_confirm`, failure and timeout play `ui_back` (`scr_combat.gml:1344, 1347, 1362`). These are the menu sounds (Modern2, Modern5, Modern6, `scr_sfx.gml:245-247`), not combat sounds. There is no cue distinguishing "about to hit you" from "menu moved".

**Scaling**: all drawing is GUI-layer (Draw_64) in screen pixels. The GUI is set to the integer-scaled port size (`scr_player.gml:1470-1471`). Positions use `UI_GetVisualScale` and `UI_GetSpriteScale` (`scr_player.gml:771-794`). Arrow base size 9 px times an integer sprite scale (probably 1 in windowed 3x-5x) is about 9 px on a screen about 430-720 px tall. Inferred: that is small.

---

## 2. Problems found, with evidence

### 2.1 Offensive timing windows are far tighter than the visuals suggest (verified code, inferred numbers)
- Window half-widths are 2 / 4 / 7 / 10 **base units** = in frames (full window width, 60 fps), by swing speed:
  - PERFECT: **1.1 to 1.8 frames** at rank 1 (0.85 to 1.4 at rank 4). That is 18-30 ms. Human timing scatter is around 30-50 ms, so PERFECT is mostly luck.
  - GOOD: 2.2-3.6 f. OKAY: 3.9-6.3 f. BAD: 5.5-8.9 f (rank 1).
- The marker visual is a 60-px disc with a 60-px ring. The ring begins to overlap the disc 60 px before alignment, but the BAD window only reaches +/-6 px (windowed 3x; visual scale = windowed scale / 5). Pressing when the ring "looks like it is on the circle" is likely a MISS. Inferred; needs a playtest to confirm the feel.
- Miss means a full 0-damage miss. A late BAD hit does x0.25. The expected damage of basic attack is therefore well under skill damage even for a decent player (inferred).

### 2.2 Slow, long, rhythm-less fall, with random speed per swing (verified code, inferred numbers)
- At nominal speed the ring takes about 132 frames (2.2 s) to reach the target in every windowed size 3x, 4x, 5x (distance = 72 base units of port scale vs speed scaled by a different ratio, `visual = scale/5`). With the 0.8-1.3 speed roll that is 1.7-2.7 s per swing. Fullscreen differs because `UI_GetVisualScale` is clamped to [0.5, 2.0] while port scale is not, so fall time and window size shift with display mode (inferred, about 100 frames at 1080p fullscreen).
- The random speed (`a39e192`, 2026-09-07: "so every swing differs and can't be memorized") removes the thing that makes timing games learnable: a repeatable rhythm. The player must re-estimate a new speed every swing with only a fraction of a second of observed motion to calibrate on.

### 2.3 Frame-rate dependence (verified)
- Attack timing moves a fixed px per **Step**, not per second (`scr_combat.gml:638`). Defensive QTE converts seconds to frames once at start (`scr_combat.gml:1143-1150`) but then counts Steps. Both are therefore tied to Step count: any slowdown (low-end Android, a hitch) stretches both. Nothing uses `delta_time`.
- The two systems use different approaches (px per frame vs seconds converted to frames), so tuning knobs behave differently.
- Judgement happens on the position after this Step's move, but input is polled per Step with no latency compensation. Display latency of 1-3 frames (about 17-50 ms) is the same size as the PERFECT window.

### 2.4 Input dropping, no buffering (verified)
- Buffering is explicitly disabled globally (`scr_input.gml:355-372` "Input buffering disabled globally"). Defensive QTE ignores presses in phase 0 (fade-in), 2 (feedback) and 3 (fade-out), about 16-20 dead frames (0.27-0.33 s) between prompts (table above). A player who pre-hits the next arrow after seeing the previous one flash will be ignored, with no feedback. Early presses on the next arrow can't count; the arrow isn't even visible yet.
- Wrong-key instantly fails the prompt (`scr_combat.gml:1340-1349`). If two arrows are pressed in the same frame, the first one in UP, DOWN, LEFT, RIGHT order wins (`scr_combat.gml:1020-1023`), which is a coin-flip fail for diagonal mashing.
- `Input_Update` early-returns if `current_time` is unchanged since the last call (`scr_input.gml:242`). If two Steps ever run in the same millisecond (catch-up after a hitch), the second Step reuses the previous Step's `pressed` flags. Low probability, low confidence, but it is a path to a double-fire or stale input.

### 2.5 Defensive QTE is both too loose and meaningless (verified numbers)
- The window is 1.4-1.7 s for a 1-in-4 choice with no timing component. Any press at any time in the window counts, so it is a recognition test, not a timing test. There is no tension. Yet a **wrong arrow** punishes instantly.
- Best reward is -50% damage on an attack that was already going to hit. Worst case adds up to 4x status duration. Reward and penalty are asymmetric and invisible until after the fact.
- It appears rarely (only 6 enemy skills, 10-50% chance each, never on consecutive actions, never on basic attacks). Players have little chance to learn it, and when it shows up it has no label or instruction (see 2.6).

### 2.6 Unclear feedback and unclear meaning of "success" (verified)
- The "Defend!" label and the "Press {key}" line were deleted (`ae5e6a3` removed the header, the four-arrow hint row, "n/total" and "%"; `420e5b2` removed the key line). What remains is a lone thin white arrow with no explanation.
- No count of how many prompts remain, no indication a series is coming.
- Timeout and wrong-key both show the same red. The countdown bar is white and does not change colour or urgency near the end.
- **HP bar drops before the QTE is played.** `Skill_Use` applies full damage to the player (`scr_combat.gml:1474`), then `_bc.p = p` is stored (`:1510`), and the HUD reads `hud_bc.p` (`obj_ui_controller/Step_0.gml:10-14`). So the HUD HP drops and the hurt flash fires (`obj_ui_controller/Step_0.gml:16`) at the **start** of the QTE; at the end `Finalize` refunds part of it (`scr_combat.gml:1250`). A successful defence looks like HP going back up, with no flash. The player sees "already damaged" while being asked to prevent it. Inferred from the code; worth a playtest check.
- Success feedback is a 1.25x pop for about 0.15 s. There is no hit-stop, shake, spark, or "BLOCK" word. Failure has no extra feedback. The only explanation of the result is the message-box line after the fact.

### 2.7 Offensive feedback gaps (verified)
- Label is white for all five outcomes, and appears at the same time as the screen goes to the message box. No colour, no size change, no screen shake or hit-stop on PERFECT. PERFECT has nothing the player can feel except the label.
- No audio during the fall or at the press, and no sound difference per tier.
- Enemy hit shake plays only when damage > 0 (`scr_combat.gml:604, 611`); a BAD hit and a PERFECT hit use the same shake and same sound.

### 2.8 Hit rate: Horizontal Slash misses are the base d20 roll, not QTE (verified code, inferred odds)
- Horizontal Slash: `acc: 0`, STR, power 5, x1.5, 5 MP (`scr_db_skill.gml:91-109`). No `uses_defensive_qte`, and player skills never enter attack timing.
- Roll: `d20 + skill.acc + StatMod(STR) + 4` vs `d20 + StatMod(enemy AGI) + dodge status` (`scr_db_skill.gml:1112-1113`, `scr_combat.gml:81-83`). The "+4" is `PLAYER_SKILL_HIT_BONUS` (`scr_macros.gml:213`). Hit is `>=` so ties go to the attacker. Equipped **weapon accuracy is not used for skills**.
- Knight at level 1: STR 10 + 1 = 11, mod 0. Enemy AGI mods: Slime 9 (-1), Spider/Snake/Wolf 10-11 (0), Mad Whisp/Ghost 12 (+1), Palehorn 12, Final Boss 14 (+2).
- Per-swing hit chance (my computation of d20 vs d20): net +5 = 74%, +4 = 70%, +3 = 66%, +2 = 62%. So roughly a **26-38% miss rate per skill swing**. Four to five misses in a row is about a 0.5-2% event per attempt. Unlikely, but over a whole playthrough it will happen, and a missed 5-MP skill feels terrible. Mini boss and boss (AGI 12-14) with any dodge buff will be worse.
- Compare basic ATTACK, which has no d20 at all and is purely the timing minigame, so the same player faces two completely different hit systems for "swing at the enemy". The playtester's request "increase the hit rate of skills a tiny bit" is a valid fix for the roll, but unrelated to the QTE.
- Skills have no timing minigame at all, so skill hits have zero player agency. Basic attack has high agency and low payoff. This is an inconsistency, not a bug (see ranked list).

### 2.9 Other inconsistencies
- Three different "success" notions: attack timing (4 tiers + miss), defensive QTE (binary per arrow, averaged), skills (none).
- `ATTACK_TIMING_RING_RADIUS`, `ATTACK_TIMING_TARGET_RADIUS` (`scr_macros.gml:229-230`) are leftovers from the circle-drawing version. Sprites replaced them in `1db1b36`, so they're dead constants (verified: no use outside macros and older commits).
- `Battle_AttackTimingSpeedMultForEnemy` reuses `Battle_DefQTEThreatRank` (`scr_combat.gml:995`). The two systems share a difficulty source.
- Repetitiveness: the basic attack is the same single-ring drop every time, no variation in pattern, only in speed.

---

## 3. Git history

Files: `objects/obj_battle_controller/{Create_0,Step_0,Draw_64}.gml`, `scripts/scr_combat/scr_combat.gml`, `scripts/scr_macros/scr_macros.gml`, `scripts/scr_db_skill/scr_db_skill.gml`, `scripts/scr_input/scr_input.gml`.

**Attack timing (offensive)**
- `52e1290` 2026-02-27 "added attack minigame": introduced `Battle_AttackTimingJudge`, windows 2/4/7/10, fixed speed `ATTACK_TIMING_SPEED`.
- `5acdc47` / `1db1b36` 2026-02-27: draw circles changed to the two sprites `spr_attack_timing_target` and `spr_attack_timing_falling`. Radius macros became dead. Fade-in of target added.
- `f7df1bd` 2026-02-27 "finished the attack minigame fully".
- `f39236b` 2026-03-05 "player testing fixes": speed now scales with enemy threat rank (base 2.4, x1.12 + 0.06 per rank).
- `1a5a68b` 2026-03-05: speed, offsets and windows scaled by `UI_GetVisualScale` (this is where px-vs-window scale coupling started).
- `a39e192` 2026-09-07 "update": speed 2.4 to 2.8, base mult 1.12 to 1.00, rank step 0.06 to 0.10, **random per-swing speed 0.8-1.3**, sprite scale 2 to 4.

**Defensive QTE**
- `01c9c18` 2026-03-05 03:51 "fixed": **the whole defensive QTE was added in this one commit** (+596 lines in `scr_combat.gml`, `uses_defensive_qte`, all `DEF_QTE_*` macros, `BSTATE_ENEMY_DEF_QTE`). Original design was text-heavy: header "Defend!", "Press {key}", four-arrow hint row, "n/total", percent.
- `0d8ebb4` 2026-03-05 04:01 **"fixed QTEs"** (10 minutes later). Despite the name, it did not touch the QTE logic (`scr_combat.gml` and macros are not in the commit). Changes: `Draw_64.gml` only moved the FX draw and skill banner ahead of the QTE so the QTE draws on top, added min/max Y clamp (`qte_min_y = 30`, `qte_max_y`), and widened the progress bar from 44x4 to 50x5 with a "%" label. It also re-tuned `Skill_AdjustStatusTurns` for DOT statuses (poison, bleed, burn) in `scr_db_skill.gml`, and changed boot-logo timings in `obj_start_controller`. So "fixed QTEs" was a draw-order and layout fix, not a feel fix.
- `420e5b2` 2026-03-05 "added a debug and fixed the banner": QTE anchored under enemy/status icons; "Press {key}" line removed.
- `ae5e6a3` 2026-03-05 04:22 "added controller support": deleted the "Defend!" header, hint row, counter and percent text. Added gamepad polling in `scr_input.gml`.
- `f39236b` 2026-03-05 "player testing fixes": QTE timings now divided by a threat-rank speed multiplier (1.15 + 0.08 per rank, max 1.45).
- `1a5a68b` / `aea0e29` 2026-03-05 / 03-08: GUI-scale and fullscreen fixes touched QTE draw sizes only.
- Nothing has touched QTE since 2026-03-08 other than the attack-timing changes above. No commit mentions tuning the defensive QTE's window, reward or frequency.

Net story: the defensive QTE was built in about 30 minutes in one sitting on 2026-03-05, then immediately stripped of all its explanatory UI over the next 30 minutes. It has not been revisited. The attack-timing minigame has been through more tuning, each time making it faster or more random.

---

## 4. Why it probably feels bad (ranked, plain language)

1. **The attack timing is a tiny target on a slow, random clock.** You watch a ring crawl for about two seconds, at a speed that changes every swing, then must press within about one frame for the best result. The picture suggests "close enough" is fine, but "close" (a few pixels off) is a miss or a quarter-damage hit. That's not skill, it's luck, and it is the thing you do most often. (Verified code, inferred feel.)
2. **A miss costs the whole turn and gives you nothing to learn from.** There's no sound, no colour, no feedback telling you early or late, so you can't improve. The label is white for all five outcomes. (Verified.)
3. **The defensive QTE is both boring and unexplained.** Almost two seconds to hit one of four arrows is easy, so there is no tension; but a wrong key instantly fails. It shows up rarely, with no "Defend!" text, no "Press this" and no counter, and the result is only explained after the fact. The player does not know what they are being asked to do or what success earned them. (Verified.)
4. **The HP bar lies during the defence.** The full damage is shown before the QTE starts and part of it is given back afterwards. Success reads as a heal, not a block. (Verified code, needs a playtest look.)
5. **Reward is small and the two systems disagree.** Best defence is -50% on a hit that was already decided; basic attack is punished harder than skills (which need no skill at all), so a rational player skips the timing game and spams skills until MP runs out. And skills use a different, invisible d20 roll that feels unfair on a streak (the 4-5 missed slashes). (Verified.)
6. **No audio design.** Menu blips stand in for combat cues; no tension sound while the ring falls; no tiered impact. (Verified.)
7. **Platform and resolution fragility.** Step-locked timing, window sizes that change with display mode, no touch input at all on the Android build. (Verified code, inferred effect.)

---

## 5. Directions the evidence points to (not designed in depth)

1. **Make timing forgiving and readable instead of precise**: drop the per-swing random speed, use a fixed and shorter fall (about 0.7-1.0 s), widen the window to roughly +/-5-6 frames for GOOD, and show the window on screen (a visible sweet-spot band the ring passes through, not a point).
2. **Make feedback the star**: audio tick or rising pitch toward the target, different sounds and colours per grade, hit-stop and shake scaled by grade, and an on-screen word for the defence ("BLOCK", "PARRY") with a clear red/green.
3. **Merge or align the two systems**: one consistent "press at the right moment" language for both attack and defence (for example a defensive window that lines up with the enemy attack animation), instead of a timing bar for offence and an arrow-recognition quiz for defence.
4. **Give skills agency and fix the hit roll**: either add a lighter timing step to skills (bonus damage, not hit/miss), or remove misses from the timing path and keep the d20 hidden; raise `PLAYER_SKILL_HIT_BONUS` or add a miss floor (for example a pity bonus after consecutive misses) so streaks like 4-5 in a row become very unlikely.
5. **Make it frame-rate and platform safe**: drive timing off `delta_time` or a seconds-based timer, keep window sizes in time (ms), not px, and add touch/tap input (a large tap area, since there is currently none) if Android remains a target; consider input buffering for the defensive prompts.

---

## Appendix: file and line index

- `scripts/scr_combat/scr_combat.gml`: 406-452 (target + judge), 494-652 (attack timing begin/resolve/step), 966-1025 (def QTE rank, prompt count, speed, input), 1027-1036 (eligibility), 1102-1394 (def QTE clear/start/adjust/finalize/step), 1406-1428 (arrow draw), 1430-1582 (enemy act, QTE entry at 1508).
- `scripts/scr_macros/scr_macros.gml`: 44 (state), 213 (`PLAYER_SKILL_HIT_BONUS`), 215-247 (all timing and QTE macros).
- `scripts/scr_db_skill/scr_db_skill.gml`: 91-109 (Horizontal Slash), 328/380/433/459/485/539 (QTE flags), 913+ (`Skill_Use`), 1103-1138 (player skill hit roll).
- `scripts/scr_equip/scr_equip.gml`: 270-309 (timing forgiveness passives), 427, 451.
- `scripts/scr_input/scr_input.gml`: 15-18, 43-44, 187-237, 240-303, 355-404.
- `objects/obj_battle_controller/Create_0.gml`: 78, 87-120. `Step_0.gml`: 9, 12, 77-78, 168-176. `Draw_64.gml`: 219-257, 307-366.
- `objects/obj_ui_controller/Step_0.gml`: 10-18 (HUD HP and hurt flash read the damaged `p` during QTE).
- `scripts/scr_player/scr_player.gml`: 771-794 (visual and sprite scale), 1470-1471 (GUI size).
- `scripts/scr_sfx/scr_sfx.gml`: 245-247 (UI sound mapping), 591 (`SFX_PlayUI`), 1036 (`SFX_PlayClassAttack`).
