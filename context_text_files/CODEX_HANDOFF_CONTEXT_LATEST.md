# Codex Handoff Context - Latest Working Summary

Primary source of truth: `AGENT_TRANSFER_CONTEXT_FINAL.txt`.
If this handoff conflicts with current code, trust the code first, then update the handoff.
This summary is meant to help a new coding agent start quickly without assuming that every prior idea was actually implemented.

Source reference used for this handoff: `AGENT_TRANSFER_CONTEXT_FINAL.txt`.

---

## 1) What this project is

This is a GameMaker Studio 2 pixel-art dungeon RPG with a Game Boy-like presentation.

Confirmed core identity:
- low internal resolution: 160x144
- integer-style scaling and handheld-aware fit-to-screen behavior
- 16x16 tile/grid overworld movement
- room-to-room dungeon crawling
- overworld enemies chase the player and collide into battle
- 1v1 turn-based battles in `rm_battle`
- cutscenes, dialogue, and typewriter text
- inventory, consumables, equipment, skillbooks, and loot
- save/load slots
- modal popup UI with dimming and fade-in/fade-out

Narrative/gameplay framing:
- the player starts as `Nobody`
- the player later chooses Knight / Archer / Mage via the class chest in `rm_floor1`
- the game is now treated as a compact level 1-10 RPG, not a long-form 1-99 RPG

Design direction:
- systems are meant to stay data-driven
- centralized helpers are preferred over one-off room hacks
- old docs still have background value, but this handoff + current code are more reliable

---

## 2) Priority docs and read order for a new agent

Use these docs first:
1. `AGENT_TRANSFER_CONTEXT_FINAL.txt`
2. `GAMEPLAY_COMBAT_DATABASE_SNAPSHOT.txt`
3. `MASTER_GAMEPLAY_AND_DATABASE_CONTEXT.txt`

Recommended code read order from the latest handoff:
1. `scripts/scr_macros/scr_macros.gml`
2. `scripts/scr_player/scr_player.gml`
3. `scripts/scr_room_transition/scr_room_transition.gml`
4. `objects/obj_game_controller/Step_0.gml`
5. `objects/obj_ui_controller/Step_0.gml`
6. `objects/obj_ui_controller/Draw_64.gml`
7. `objects/obj_start_controller/Create_0.gml`
8. `objects/obj_start_controller/Step_0.gml`
9. `objects/obj_start_controller/Draw_64.gml`
10. `scripts/scr_dialogue/scr_dialogue.gml`
11. `scripts/scr_menu/scr_menu.gml`
12. `scripts/scr_save_menu/scr_save_menu.gml`
13. `scripts/scr_save/scr_save.gml`
14. `scripts/scr_levelup/scr_levelup.gml`
15. `scripts/scr_stats/scr_stats.gml`
16. `scripts/scr_db_player_class/scr_db_player_class.gml`
17. `scripts/scr_db_skill/scr_db_skill.gml`
18. `scripts/scr_db_item/scr_db_item.gml`
19. `scripts/scr_status/scr_status.gml`
20. `scripts/scr_loot/scr_loot.gml`
21. `scripts/scr_enemy/scr_enemy.gml`
22. `scripts/scr_combat/scr_combat.gml`
23. `objects/obj_battle_controller/Create_0.gml`
24. `objects/obj_battle_controller/Step_0.gml`
25. `objects/obj_battle_controller/Draw_64.gml`

---

## 3) High-level room and game flow

Main rooms:
- `rm_start`: title/main menu
- `rm_cutscene`: centralized cutscene room
- `rm_floor1` onward: overworld dungeon rooms
- `rm_battle`: battle room

Player-facing flow:
- Title -> New Game
- difficulty popup appears
- intro cutscene plays through `rm_cutscene`
- intro ends in `rm_floor1`
- player starts as `Nobody`
- class chest in `rm_floor1` lets the player choose Knight / Archer / Mage
- class swap is hidden under black flash transition

Load flow:
- title -> load game
- saved room / x / y / face are restored exactly
- title dim is deliberately held through the transition to prevent flicker

Death flow:
- player HP <= 0 routes to `game_over` cutscene in `rm_cutscene`
- after game over, the game attempts to load the latest/current save slot
- if no save exists, it returns to `rm_start`

Battle flow:
- overworld enemy collision may either auto-resolve or transition into `rm_battle`
- on victory: EXP + loot + post-battle reward dialogue back in overworld
- on defeat: game over cutscene flow
- on run: return to overworld through transition system

---

## 4) Title, popup, dim, and transition architecture

This area is fragile and easy to regress.

Current title rules:
- `obj_start_controller` manually draws the title background sprite in Draw GUI
- the room's Background layer is intentionally hidden
- the title background should NOT run its own alpha fade anymore
- the black transition overlay owns the actual screen fade

Difficulty popup is a special-case title popup:
- it lives in `obj_start_controller`, not the normal shared in-game popup stack
- shared modal logic still tracks it, but draw ownership is intentionally special to avoid over-dimming the popup

Modal dim system:
- modal roots own the dim, not each popup individually
- linked popup chains transfer or hold the same root to avoid dim flicker
- helpers live in `scr_player.gml`
- if adding popups, do not hardcode a new dim rectangle unless deliberately replacing the current modal-root system

---

## 5) Display and settings

Display authority lives in `scr_player.gml`.

Confirmed display rules:
- base resolution is 160x144
- integer-fit scaling is used
- viewport is centered with black bars if needed
- GUI size stays tied to internal resolution
- `gpu_set_texfilter(false)` is used to keep pixels crisp
- project expects `application_surface_draw_enable(true)`

Current persistent settings authority:
- `settings_config.json`
- save slots no longer own settings

Shared settings menu fields:
- UI volume
- SFX volume
- BGM volume
- display scale
- fit_screen

---

## 6) Cutscenes and dialogue

Cutscene system:
- all cutscenes route through `rm_cutscene`
- cutscene ids currently include `intro`, `ending`, and `game_over`
- cutscene definitions currently live in `obj_start_controller/Create_0.gml`
- `rm_cutscene` must not show the player

Dialogue system:
- centralized in `scripts/scr_dialogue/scr_dialogue.gml`
- supports normal dialogue box mode and cutscene text-only mode
- includes wrapping, pagination, and typewriter reveal
- while dialogue is active, player is eased back to tile center through `Player_EnsureDialogueSettle`

Important implication:
- if a new agent changes dialogue or transition flow, they should retest post-dialogue player alignment

---

## 7) Current player/class/progression state

Player/class authority:
- `CharacterCreate_Player` in `scr_player.gml`
- `DB_PlayerClass` in `scr_db_player_class.gml`

Classes:
- `CLASS_ARCHER`
- `CLASS_KNIGHT`
- `CLASS_MAGE`
- `CLASS_NOBODY`

Important class facts:
- `Nobody` is a real class/state, not a temporary null placeholder
- `Nobody` uses its own directional sprites
- `Nobody` starts with no skills
- `Nobody` cannot learn skillbooks

Current level cap:
- `LEVEL_CAP = 10`
- `LEVEL_CAP_TECHNICAL = LEVEL_CAP`
- level 10 is now the real cap, not a hidden soft cap

Leveling authority:
- `scripts/scr_levelup/scr_levelup.gml`

Current confirmed level-up rule:
- each level-up gives exactly 1 manual stat point
- each level-up also gives exactly 1 automatic class stat increase
- auto-growth comes from class DB `auto_stat`
- `Nobody` has no auto-growth fallback

Current EXP table:
- 1 -> 2 = 15
- 2 -> 3 = 30
- 3 -> 4 = 50
- 4 -> 5 = 75
- 5 -> 6 = 105
- 6 -> 7 = 140
- 7 -> 8 = 180
- 8 -> 9 = 225
- 9 -> 10 = 275
- beyond 10 = 0 because cap

Current resource recompute behavior:
- HP mainly comes from class/base level growth
- DEF only adds a small weighted HP bonus through `PLAYER_HP_DEF_BONUS_FACTOR`
- MP comes from class/base level growth plus INT weighting
- previous runaway retroactive HP/MP behavior was already reduced/cleaned up

Current level-up heal rule:
- level-up does NOT fully heal the player
- HP/MP only increase by the amount of new max HP/max MP gained from that level

Manual stat allocation:
- stats tab in the menu allows spending unspent stat points on STR/AGI/DEF/INT/LUCK
- pending allocation can be confirmed or canceled
- inspect `Menu_StatsSync`, `Menu_StatsApply`, and `Menu_StatsDiscard` before changing stat UI logic

---

## 8) Items, equipment, and skillbooks

Authority:
- `scr_db_item.gml`
- `scr_equip.gml`
- inventory handling inside `scr_menu.gml`

Current rules:
- equipment is handled through inventory use
- equipping does not consume the item
- player effectively has one weapon slot and one body slot
- equipping new gear replaces the old equipped item
- menu UI marks equipped items

Skillbooks:
- class-restricted
- Nobody cannot learn any skillbook
- already-known and wrong-class cases are handled cleanly

Consumables:
- can be used in inventory, not only in battle
- `Item_Use` handles HP/MP/status-related effects

---

## 9) Save, load, and bed flow

Authority:
- `scr_save.gml`
- `scr_save_menu.gml`

Important confirmed rules:
- save snapshots restore exact room/x/y/face
- loading a save clears queued room spawns and uses explicit load-spawn fields
- loading a save reapplies current settings from the main settings authority
- bed interaction opens a bed menu first
- bed save flow heals HP/MP before saving
- after save write, the save flow reloads the selected slot and then shows `Game saved`

Enemy reset notes:
- normal enemies are reset by save flow via reset-version logic
- mini boss and final boss are intentionally not treated like regular respawning enemies

---

## 10) Overworld movement, room transitions, and alignment helpers

Movement:
- 16x16 grid/tile movement
- movement is stateful, not free analog movement

Key action gates/helpers:
- `UI_IsBlocking`
- `Player_CanAcceptMove`
- `Action_CanAct`
- `Action_Request`

Important settle/recovery helpers:
- `Player_StartAutoResolveRecover`
- `Player_EnsureDialogueSettle`

These exist because there were previous bugs where:
- auto-battle left the player offset or semi-stuck
- dialogue transitions left the player slightly off-grid

Current design intent:
- use short settled recovery states instead of relying on the player moving once to refresh state

Room transitions:
- `obj_room_transition/Collision_obj_player.gml`
- `scr_room_db.gml`
- transition entries may use require-direction and require-move gating

---

## 11) Enemy encounters and auto-resolve

Authority:
- `scr_db_enemy.gml`
- `scr_enemy.gml`
- `obj_enemy/*`

Encounter flow:
- collision captures battle return data through `GameState_SetBattleReturn` and `GameState_SetBattleEnemy`
- encounter transition effect is centralized in `scr_room_transition.gml`

Auto-resolve functions:
- `Enemy_CanAutoResolve`
- `Enemy_AutoResolveBuildMessage`
- `Enemy_AutoResolveFinalize`
- `Enemy_AutoResolveFinalizePending`
- `Enemy_AutoResolveEncounter`

Current auto-resolve intent:
- trivial enemies can be skipped if the player sufficiently outlevels them
- reward text should reflect actual rewards and not fake level-ups at cap
- player should go through a short recovery state after auto-resolve instead of needing to move once to restore control

Enemy persistence:
- regular enemies are respawn-reset by save flow
- mini boss and final boss must stay defeated permanently

---

## 12) Current battle system state

Authority:
- `obj_battle_controller/*`
- `scr_combat.gml`

Current menu labels:
- `ATTACK`
- `SKILL`
- `ITEM`
- `RUN`

Important confirmed feature:
- basic `ATTACK` now uses a timed-hit minigame
- this replaced the old feel where basic attacks relied on frustrating random misses

Timed attack functions:
- `Battle_AttackTimingBegin`
- `Battle_AttackTimingJudge`
- `Battle_PlayerAttackResolveTimed`
- `Battle_PlayerAttackTimingStep`

Timed attack visuals:
- `spr_attack_timing_target`
- `spr_attack_timing_falling`

Current timed attack behavior:
- a falling ring comes from above toward the enemy target area
- judgment windows are `PERFECT`, `GOOD`, `OKAY`, `BAD`, `MISS`
- successful timing results connect reliably and scale damage by multiplier
- `MISS` deals 0 damage
- timing constants live in `scr_macros.gml`

Battle room draw notes:
- reward text and long log text were cleaned up to avoid duplication and truncation problems
- enemy visual fade follows transition alpha when returning from battle

---

## 13) Status system and current presentation rules

Status authority:
- `scr_status.gml`

Core negative statuses with dedicated icons:
- `poison_status`
- `bleed_status`
- `burn_status`
- `stun_status`

Current important presentation rule:
- placeholder icons for non-core enemy buffs/debuffs were intentionally removed from the enemy battle display path
- if an enemy status does not have one of the core dedicated icons above, enemy-side battle UI uses a text fallback label instead
- current fallback uses signs, not arrows:
  - positive buff: `StatusName +`
  - negative debuff: `StatusName -`

Why:
- Unicode arrows were unreliable with the current font
- sprite arrow fallback was also removed after visual/runtime issues

Important subtlety:
- the DB may still contain placeholder `icon_sprite` fields for some statuses
- the important thing is the actual battle draw path, not just the raw DB field

Relevant helpers:
- `Status_AssignCoreIcons`
- `Status_AssignPlayerBuffIconsFromFX`
- `Status_AssignMissingIconsFromSkillFX`

---

## 14) Loot, chests, and containers

Loot authority:
- `scr_loot.gml`

Important current pattern:
- chests and barrels use container tables
- enemies use loot keys such as `enemy_basic`, `enemy_mid`, `enemy_elite`, `enemy_boss`
- skillbook rolls are class-aware

Important chest split:
- `obj_chest_skillbook` keeps skillbook-drop behavior
- `obj_chest_class_select` is the dedicated class selection chest

---

## 15) Debug/testing helpers

Debug authority:
- `scr_debug.gml`

Useful functions:
- `Debug_Toggle`
- `Debug_GiveAllItems`
- `Debug_LevelUp`
- `Debug_Save`
- `Debug_Load`
- `Debug_KillPlayer`

Notable behavior:
- `Debug_LevelUp` grants exactly the EXP needed to level once, unless already at cap
- `Debug_KillPlayer` uses the normal game-over path

---

## 16) Important fragile areas that a new agent should not casually break

1. Title load transition and dim handoff
   - title menu load is special
   - dim must remain sustained while leaving the title
   - main menu buttons must not flash back in

2. Title difficulty popup layering
   - it is a deliberate title-only special case

3. Popup dim ownership
   - do not reintroduce popup-by-popup dim rectangles unless replacing the modal-root system on purpose

4. Exact save-load position restore
   - load uses explicit spawn restore, not just default room spawn

5. `rm_cutscene` player visibility
   - cutscene room should never show the player

6. Class application timing
   - class swap is intentionally hidden under black flash

7. Status icon assumptions
   - DB placeholder icon fields do not necessarily mean the battle UI still uses them

8. Battle log/reward duplication
   - reward presentation was already cleaned up

9. Grid alignment after auto-resolve or dialogue transitions
   - recovery helpers exist for a reason

10. `settings_config.json` as the single settings authority
   - do not silently restore settings from save slots again

---

## 17) Recent design discussions from chat that may NOT all be implemented yet

This section is important: these are recent directions and recommendations from chat, but they should be treated as ideas to verify in code, not guaranteed reality.

### A. Defensive QTE on enemy actions
Latest recommendation from chat:
- do NOT attach defensive QTE to every enemy normal/basic attack
- if used, it is better attached only to enemy damaging attack skills or other flagged high-threat offensive actions
- the enemy should still roll normal hit logic first
- defensive QTE should only happen if the enemy action would already hit
- QTE should reduce damage, not fully erase it by default
- recommended damage model discussed:
  - `success_ratio = successful_qtes / total_qtes`
  - `final_damage_multiplier = 1 - (0.5 * success_ratio)`
  - all correct = 50% damage
  - none correct = 100% damage

Status of this idea:
- treat as discussed design direction unless code confirms implementation

### B. Enemy normal attack QTE was considered too spammy
Discussion outcome:
- putting QTE on every enemy basic attack would probably make fights too long and repetitive
- the more likely recommended direction is to reserve it for enemy damaging skills / danger moments

Status:
- treat as recommendation, not confirmed implementation

### C. Early-game difficulty tuning
Recent recommendations because Slime fights felt too slow and chip-damage-heavy:
- give each class a starting weapon
- make Slime level 1
- lower early enemy HP before lowering enemy DEF
- target pacing: Slime should die in about 2-3 successful ATTACKs, not many more

Reasoning from chat:
- current stat mod formula compresses low-end values, so 10 and 11 can feel nearly identical
- lowering early HP is a safer tuning knob than lowering DEF first

Status:
- treat as recommendation unless code/snapshot confirms it has already been applied

### D. Attack timing visual polish
Recent discussion recommended visually separating:
- the fixed target as a more grounded target/bullseye style element
- the falling marker as a brighter moving ring/marker

Status:
- only treat as an art/UI suggestion unless assets already changed

### E. Buff icon fallback ideas changed over time
Earlier chat explored:
- using animation last frames or text with arrows for buffs without proper icons

Current latest confirmed state from the handoff:
- enemy-side fallback is simple text with `+` or `-`
- do not assume older arrow-based ideas are the real current behavior

### F. Auto-resolve and dialogue transition offset bugs
There were discussions and fixes around:
- post-auto-resolve player offset / semi-stuck state
- dialogue transition leaving the player off-grid

Current confirmed intent from the handoff:
- alignment/recovery helpers should already exist and be used
- if this issue appears again, inspect the settle/recovery helpers first instead of adding ad-hoc movement refresh logic

---

## 18) Practical guidance for the next agent

If taking over in a new chat, the safest pattern is:

1. Read `AGENT_TRANSFER_CONTEXT_FINAL.txt` first.
2. Treat it as the latest architecture handoff.
3. Use `GAMEPLAY_COMBAT_DATABASE_SNAPSHOT.txt` for exact combat numbers.
4. Use `MASTER_GAMEPLAY_AND_DATABASE_CONTEXT.txt` for older background only.
5. Verify any recent design idea in code before assuming it exists.
6. If changing title flow, popup dim, load flow, cutscene routing, battle reward text, or grid alignment, re-test immediately in-engine.

---

## 19) Suggested message to prepend when handing this to another Codex agent

You can give the next agent this instruction before the handoff:

> Read `AGENT_TRANSFER_CONTEXT_FINAL.txt` first and treat it as the latest handoff. Use `GAMEPLAY_COMBAT_DATABASE_SNAPSHOT.txt` for exact combat values. Use older docs only as background. Do not assume every older chat recommendation was implemented. If code conflicts with docs, trust the code.

---

## 20) Final summary

This project is in a workable state with many systems intentionally centralized because local fixes previously caused regressions.

The biggest risks for a new agent are:
- title load/dim/transition behavior
- popup dim ownership
- exact save-load placement restore
- cutscene room ownership
- battle reward/log duplication
- enemy status fallback presentation
- player alignment after auto-resolve/dialogue transitions

If a change touches one of those, test it immediately.

If this handoff conflicts with current code, trust the code first and then update the handoff.
