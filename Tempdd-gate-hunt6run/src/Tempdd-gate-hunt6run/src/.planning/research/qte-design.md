# QTE design research — timed inputs in turn-based RPGs

Date: 2026-10-13. Purpose: input for redesigning battle QTEs in DD-Project-GameMaker (keyboard, gamepad, Android touch).
Method: web search/fetch plus GitHub (gh CLI). **Verified** = read in the cited source. **Inferred** = my reasoning. **Unknown** = no source found (published windows are rare; most numbers come from fan wikis, decompilations or player measurement).

---

## 0. What the game does today (read from code, not researched)

Files: `scripts/scr_macros/scr_macros.gml` (lines ~215-247), `scripts/scr_combat/scr_combat.gml` (`Battle_AttackTimingJudge` ~445, `Battle_DefQTE*` ~966-1108, defence timers ~1320-1379).

- **Attack:** a ring/bar closes on a target. Judge is distance-based with 4 tiers: PERFECT <=2, GOOD <=4, OKAY <=7, BAD <=10 (UI-scale-normalised px), multipliers 1.00 / 0.75 / 0.50 / 0.25, **MISS = 0.00**. The speed is re-rolled for every swing (x0.80 to x1.30) on purpose "so it can't be memorized", plus a threat-rank speed bonus.
- **Defence:** 1 to 5 prompts (more for bosses), each a **random** arrow direction, 2.0 s response time per prompt, speed multiplier up to x1.45, damage reduction up to 50%, status multiplier 1x to 4x.
- **Timing is counted in Steps**, not time (CONCERNS.md: "no `delta_time` anywhere"), so windows change if the room speed changes.

Gaps against the research below, all **inferred**:
1. Random speed per swing breaks "consistent timing per move", so it can't be learned. It reads as luck.
2. Four tiers plus MISS = 0 damage punishes failure instead of rewarding success. A miss should still deal normal damage.
3. Random arrow directions cannot be telegraphed. The player reacts to a symbol instead of timing a visible event, and 3-5 in a row is fatigue.
4. Windows measured in px and Steps are not calibratable in ms and are not frame-rate independent.
5. The code has no assist options (wider window, auto-success).

---

## 1. Game-by-game survey

### 1.1 Super Mario RPG (SNES 1996) and 2023 remake — the origin
- **Input:** press one button just before the attack lands. Specials vary: single press, mash (Continuous Hit), hold (Star Hit), rotate the pad (Rotational Hit). Defence: press just before the hit connects.
- **Window:** two tiers, "close" and "perfect". **Unknown in ms/frames.** Timing varies by weapon and enemy; a "!" icon appears for a new weapon or enemy.
- **Success:** close = +50% damage, perfect = +100%. Specials: +25% / +50%. Block: close = half damage, perfect = no damage. Some good timings extend a single-target attack to all enemies.
- **Failure:** no bonus only. Physical timed hits "never miss". Verified: the bonus is applied after damage calculation and never changes stats.
- **Teaching:** the "!" prompt, and the animation itself is the telegraph.
- **Remake (2023):** a perfect normal attack fires a shockwave that hits all enemies; a perfect block shows a hexagonal barrier; successful commands fill a bottom-left gauge for a Triple Move; unblockable enemy moves show "Action Command Ineffective!"; **Breezy mode** makes the command timing more forgiving and can be switched at any time. No auto-success mode was found.
- Sources: https://www.mariowiki.com/Action_Command , https://www.mariowiki.com/Timed_Hit , https://www.gfinityesports.com/guides/super-mario-rpg-action-commands , https://www.siliconera.com/should-you-pick-breezy-or-normal-difficulty-in-super-mario-rpg/ , https://cms.ggrecon.com/guides/super-mario-rpg-difficulty-settings/

### 1.2 Paper Mario series (N64, TTYD, Sticker Star, Color Splash, Origami King)
- **Input:** varies per move: timed A, hold-and-release, mash, stick aim, A+B together. Newer entries use only A (touch screen can stand in for A in Sticker Star / Color Splash). Practice rooms exist (Color Splash Action Command Dojo, Origami King Battle Lab).
- **Window (real numbers):**
  - Block/Guard: **8 frames at 60 fps (~133 ms)** in TTYD; **Superguard 3 frames (~50 ms)**; Simplifier x2 raises superguard to 4 frames; each Unsimplifier cuts 1 frame (mariowiki Superguard page). The Guard page for the N64 game says 3 frames at 30 per second (~100 ms). The two wikis do not agree; I could not reconcile them.
  - From the decompilation (`src/battle/action_cmd.c`, `jump.c`): each command has an **8-level difficulty table of window lengths** in frames, e.g. jump `{7,6,5,4,3,2,1,0}`, hammer `{11,10,9,8,7,6,5,4}`, body slam `{9..2}`, mash-type `{130..60}`. Block window is `blockWindow = 3` (5 with the Dodge Master badge), checked against a **ring buffer of past button presses**. Dodge Master lowers the difficulty level by 3. The decomp's tick rate is not stated in the file; the PM64 battle loop runs at 30 per second per the wiki, so 3 frames is about 100 ms. That is **inferred**.
  - **Anti-mash rule (verified in code):** any press in the 10 frames *before* the block window marks the block as EARLY and fails it. Pressing the button before the window opens in `jump.c` also fails the command (`wrongButtonPressed`).
  - **Auto-succeed exists in the code** (`acs->autoSucceed`): the HUD shows the "right on" icon and the command is auto-passed. It is what the in-game simplifier effectively uses.
- **Success:** more damage (jump/hammer) or less damage taken; Guard = reduced damage, Superguard = no damage plus a counter hit on physical attackers (1 dmg) plus cancels multi-hit; Stylish moves (TTYD) give extra Star Power and audience reaction.
- **Failure:** no bonus; plain damage. All or Nothing badge: +1 power but failed commands deal 0 (an opt-in risk, not default).
- **Teaching:** the A-button HUD icon appears and, in the decomp, **is drawn pressed two frames before the window opens**; tutorial battles; "GREAT"/"NICE" text with different colors (orange GREAT for superguard, blue NICE for guard).
- **Difficulty knobs:** Dodge Master (wider), Simplifier / Unsimplifier (easier but less Star Power / harder but more), Damage Dodge (more damage blocked). Accessibility is a trade: easier = less bonus resource.
- Sources: https://www.mariowiki.com/Superguard , https://www.mariowiki.com/Action_Command , https://www.mariowiki.com/Guard , https://github.com/pmret/papermario/blob/main/src/battle/action_cmd.c , https://github.com/pmret/papermario/blob/main/src/battle/action_cmd/jump.c , https://www.dampfkraft.com/games/paper-mario-combat.html (design analysis: fixed base damage plus tiny stats makes one timed point matter a lot; the animation is the telegraph)

### 1.3 Mario & Luigi series
- **Input:** each brother has his own button (A / B in Superstar Saga; X / Y in Partners in Time and later); hammer = hold and release; Bros. Attacks are mini-games with extra button/direction (Dream Team adds gyro). Defence = jump or hammer at the right moment; jump over the attack or stomp the enemy; hammer can counter or bat projectiles back. Remakes and later games add an Emergency Guard/Block button.
- **Window:** not documented in the sources I found (**unknown**). Cue is "press when the brother lands" and "press when the hammer shakes".
- **Success:** double damage in Superstar Saga for correct timing; avoid damage; counter-damage.
- **Failure:** Bros. Attacks lose damage or end early on a miss; basic moves just lose the bonus.
- **Teaching:** every attack animation is the cue; the series later became more mini-game-like.
- Sources: https://www.mariowiki.com/Action_Command , https://www.mariowiki.com/Bros._Attack , https://www.nintendo.com/eu/media/downloads/games_8/quick_start_guide/QuickStartGuide_3DS_MarioAndLuigiDreamTeamBros_EN.pdf

### 1.4 The Legend of Dragoon (PS1, "Additions")
- **Input:** attack, then a shrinking square closes on a fixed centre square; press X when they align. Number of inputs = hits minus one. Longer additions can show a **counter**: squares turn red with a sound and you must press Circle instead.
- **Window:** **unknown** (no datamine found). Square colour tells the error: blue = too slow, grey = too fast.
- **Success:** the square flashes white, the combo continues; more damage and SP. Additions level raises attack power about 1.5x to 2x.
- **Failure:** combo ends early.
- **Design intent (developer interview, verified):** early prototypes used directional slashes and multiple buttons; testers found them hard and distracting, and a timing indicator at the bottom of the screen pulled eyes off the battle, so the final version uses one button and an on-target cue. A single button was then too easy, so they spent about half a year adding challenge. Goal: the player should feel involved instead of just issuing commands.
- Sources: https://legendofdragoon.org/interviews/yasuyuki-gb-tm/ (read), https://legendofdragoon.fandom.com/wiki/Additions (seen in search summary only, page returned 402 when fetched)

### 1.5 Shadow Hearts (Judgement Ring) and Lost Odyssey (Aim Ring)
- **Shadow Hearts:** a pointer sweeps a ring with coloured hit areas; press as it crosses each. A narrow **Strike Area** at the end of an area gives about +20% damage but is riskier. Missing an area cuts the attack short or cancels it; in combos a miss breaks the chain. The ring is customisable: slower pointer, wider areas, fewer-but-bigger areas, hidden areas; in Covenant you can even trade damage for an auto-battle ring. Sources: https://en.wikipedia.org/wiki/Shadow_Hearts:_Covenant , https://shadowhearts.fandom.com/wiki/Attack_boost
- **Lost Odyssey:** hold the right trigger as an attack starts, release when two rings overlap; Perfect / Good / Bad. Perfect triggers the equipped ring's full effect; Good about 10% of it (estimate by one preview); Bad gives little or nothing, but a basic attack still lands. Rings are equippable items that add the bonus (element damage, drain, status, steal), so **the timing is a bonus layer on an attack that always works**. Sources: https://www.worthplaying.com/article/2008/1/22/previews/48184-xbox-360-preview-lost-odyssey/ , https://gamesradar.com/lost-odyssey-exclusive-hands-on , https://en.wikipedia.org/wiki/Lost_Odyssey
- Windows: **unknown** for both.
- Lesson: ring-style cues give a visible countdown (good telegraph), and a player-adjustable ring is a ready-made accessibility system.

### 1.6 Sea of Stars (2023)
- **Input:** one button. Timed attack (press at the hit moment, also continues combos), timed block (press as enemy strike lands).
- **Success:** extra damage / half damage taken, sound effect and visual flair on a good timing. **Failure:** no bonus; timing is not required to win.
- **Window:** unknown. **Cue:** developers reportedly said in a Q&A that an on-screen "press now" indicator will not be a feature (secondhand forum report); the animation is the cue. A relic gives a flare on success.
- **Accessibility through Relics (no difficulty menu):** Amulet of Storytelling (double HP, heal after battle), Sequent Flare (visual confirmation of success), **Sixth Sense** (35% chance to auto-block, manual still works), **Adamant Shard** (basic attacks time themselves; halves the timing bonus). Key point: **auto-timing costs part of the bonus**, so it stays fair.
- Player feedback in the demo thread: some found timing on every attack and block "too prevalent" and asked for it to be optional; others liked it as a learned skill and hoped it would not be tightened for important fights.
- Sources: https://caniplaythat.com/2023/11/01/sea-of-stars-accessibility-review/ , https://steamcommunity.com/app/1244090/discussions/0/3805028677406464110 , https://primagames.com/news/where-to-find-and-how-to-use-all-relics-in-sea-of-stars

### 1.7 Clair Obscur: Expedition 33 (2025)
- **Input:** enemy turn is real time: dodge, jump or parry; **gradient** attacks use a counter/ different input (a grey swirl marks that an attack is a gradient, but you still time the animation). Dodging first is a common way to learn an attack's rhythm.
- **Window (player-measured, not official):** parry about **0.15 s (9 frames at 60 fps) on the harder settings**, dodge roughly 1.5x to 2x wider (one thread lists 0.35 / 0.22 s dodge and 0.25 / 0.15 s parry per difficulty, order unclear). Perfect parry on Expert described as about 2 frames in one guide (conflicts with the above; I do not trust it).
- **Official change:** patch 1.3.0 increased parry and dodge windows by **40% on Story difficulty only** and cut incoming damage there (60% to 50% of normal hit). The game has no standalone timing-window slider; a popular mod doubles windows and a middle-ground slider is a recurring player request.
- **Success:** a parry or dodge triggers a strong counterattack; mastering rhythms makes skills stronger; no-damage runs are possible.
- **Failure:** you take the hit.
- **Design intent (director):** "reactive turn-based"; plan on your own time, react in real time during enemy turns; borrowed reward structure from Souls, Devil May Cry and NieR.
- Sources: https://gamingtrend.com/news/clair-obscur-expedition-33-gets-developer-deep-dive-on-playstation-blog , https://www.siliconera.com/clair-obscur-expedition-33-patch-adjusts-dodge-and-parry-timing/ , https://steamcommunity.com/app/1903340/discussions/0/567001738550196339 , https://www.nexusmods.com/clairobscurexpedition33/mods/28

### 1.8 South Park: The Stick of Truth / The Fractured But Whole
- **Input:** A at the right moment to power up most moves; timed presses during enemy attacks. Stick of Truth had more QTE weight; Fractured But Whole added grid positioning.
- **Success:** extra damage; during defence, timed presses recover some HP after being hit and **fill the shared Ultimate meter** (verified from reviews). **Failure:** no bonus.
- **Window / cue design:** **unknown**. One reviewer reported prompts that sometimes did not register (anecdote).
- Sources: https://southpark.wiki.gg/wiki/Combat_in_South_Park:_The_Fractured_But_Whole , https://gamingtrend.com/feature/reviews/i-believe-in-you-or-at-least-in-your-farts-south-park-the-fractured-but-whole/

### 1.9 Undertale (attack bar)
- **Input:** choosing FIGHT slides a bar across a meter; press Z / Enter; **centre = maximum damage**, edges less. Letting the bar cross the whole meter is a miss.
- **Variants by weapon:** two bars (Torn Notebook; both centred = golden animation and more damage), three bars (Ballet Shoes), four fast presses (Tough Glove). Weapons change speed, number of bars and animation.
- Window / speed: **unknown**. The bar position, not the character animation, is the cue, so it works as an abstract meter (relevant: this is close to what the game has now).
- Source: https://undertale.fandom.com/wiki/Encounter

### 1.10 Child of Light and Costume Quest
- **Child of Light:** the timing is on the **turn timeline**, not a button QTE: the bar has a long wait part and a short red "cast" part; hitting an enemy during its cast **interrupts** it and pushes it back (same for your party). Igniculus (second cursor) can slow an enemy's bar. Lesson: timing can be strategic positioning, not reflex. Source: https://www.denofgeek.com/games/child-of-light-review , https://www.avclub.com/child-of-light-review-multi-platform
- **Costume Quest:** each attack/defence/heal has a quick press ("right button at the right time") or a stick meter you fill by wiggling; enemy attacks prompt presses to cut damage. In Costume Quest 2 you tap as a falling circle reaches a marker and can hold to charge a counter and release as the enemy connects. Windows: **unknown**. Source: https://www.gameinformer.com/games/costume_quest_2/b/pc/archive/2014/10/07/costume-quest-2-review.aspx , https://giantbomb.com/reviews/costume-quest-review

---

## 2. Design principles (distilled)

Cited items are verified; the rest is my synthesis.

1. **Telegraph with the animation, then confirm with a cue.** Every game above ties the press to a visible event: the attack animation (Mario RPG, Paper Mario, M&L, Sea of Stars), a closing shape (LoD, Lost Odyssey, Shadow Hearts), or a tell (Clair Obscur). Legend of Dragoon's devs moved the cue onto the target because a bottom-of-screen indicator pulled eyes off the action. Paper Mario draws the button pressed two frames before the window opens. A wind-up of at least 400-500 ms is fair for a reaction input (inferred from window sizes below).
2. **Same move = same timing, every time.** The skill is learning the rhythm (Clair Obscur's director: "mastering attack rhythms"). Random per-attack speed (as in this game) removes learnability. Make variety come from *different moves having different timings*, not from re-rolling one move.
3. **Reward success; do not punish failure.** Mario RPG, Paper Mario, Sea of Stars, Lost Odyssey and South Park all give a plain, working attack or block on a miss, and a bonus on success. The only punishing variants are opt-in (All or Nothing badge) or in combos (Shadow Hearts, Additions: a miss ends the chain, which is a loss of bonus hits, not a loss of the base attack). The QTE criticism literature agrees: failure should be recoverable and instructive (https://www.wayline.io/blog/quick-time-events-killing-immersion).
4. **Two tiers are enough.** Good / Perfect (Mario RPG) reads cleanly. Four tiers plus a zero-damage miss (current game) is more to learn and more to be punished by.
5. **Honest early-press handling.** Paper Mario fails a press made too early (anti-mash). That stops button mashing but makes players feel cheated unless the cue is clear. A gentler option: ignore an early press (no penalty) but show a small "too early" mark, as Legend of Dragoon colours the square grey for too early and blue for too late.
6. **Avoid fatigue.** One input, short, optional bonus (Sea of Stars players asked for optional timing; Paper Mario keeps it to a single button on most moves). Don't chain 3-5 reaction prompts for ordinary fights. Keep long sequences (Additions with 6+ presses, Bros. Attacks) for special moves where the player chose to invest. Mixing archetypes across skills (tap, hold-release, rhythm of 2-3, meter) keeps it fresh without more prompts per turn (Undertale weapons, Costume Quest, Mario RPG specials).
7. **Fuse timing with a resource.** Success fills something that matters: Star Power (TTYD), Triple Move gauge (SMRPG remake), Ultimate meter (South Park), ring effects (Lost Odyssey), counterattacks (Clair Obscur). It gives a reason to engage beyond +X% damage.
8. **Difficulty and accessibility are first-class.** Proven knobs: wider window (Dodge Master; Breezy; Clair Obscur Story +40%); **auto-success with a cost** (Paper Mario autoSucceed / Simplifier gives less Star Power; Sea of Stars auto-timing halves the bonus; Shadow Hearts auto-battle ring trades damage); automatic block chance (Sixth Sense); visual confirmation (Sequent Flare). Game Accessibility Guidelines also recommend a game-speed option for timing-limited players (https://gameaccessibilityguidelines.com/include-an-option-to-adjust-the-game-speed/). Good practice: switchable at any time, from the pause menu.
9. **Scale windows with who is struggling, not just the enemy.** Clair Obscur kept one baseline per difficulty and shipped a patch to widen it. Players ask for a continuous slider; implement the window as a single multiplier.
10. **Latency compensation.** Players adapt to about 50-100 ms of input delay in competitive games (Rhythm Quest devlog), but audio latency is usually the largest and worst on Android (same source). Offer a single calibration screen; judge presses against `target_time + offset`; schedule the success sound *at* the target time, not at the press, so audio matches the cue even on a late press. Don't play sounds during calibration taps. https://rhythmquestgame.com/devlog/10.html
11. **Game-feel on success.** A few frames of **hit-stop** (freeze the attacker and target only, so UI and audio keep running; longer for heavier hits), a flash/shockwave, a distinct sound, a number pop, and optionally small screen shake. Paper Mario / SMRPG remake: unique text colour and a barrier or shockwave on perfect. Sources: https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/ , https://uhiyama-lab.com/en/notes/unity/unity-game-feel-hit-feedback/ . The "Art of Screenshake" talk (Vlambeer) is the standard reference; I could not retrieve its transcript.
12. **Window sizes for reference (total width of accepted press):**

| Source | Window | Approx ms |
|---|---|---|
| Paper Mario TTYD guard | 8 frames @60 | 133 |
| Paper Mario TTYD superguard | 3 frames @60 | 50 |
| Paper Mario 64 guard (decomp) | 3 frames @30 (inferred) | 100 |
| Clair Obscur parry (hard) | 0.15 s | 150 |
| Clair Obscur Story (+40%) | about 0.21 s | 210 |
| Generic forgiving tiers (coyote/buffer guide) | 15-20 frames | 250-333 |

   On a 60 fps game and a touch screen, anything under about 50 ms total is a lottery. Frame quantisation alone is 16.7 ms at 60 fps.

---

## 3. Implementation notes for GameMaker

Verified items cite the GameMaker manual; the rest is standard practice I am confident of but did not look up.

- **Timing source.** `delta_time` is the microseconds between the previous frame and this one (manual: https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Maths_And_Numbers/Date_And_Time/delta_time.htm). `get_timer()` returns microseconds since the game started (https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Maths_And_Numbers/Date_And_Time/get_timer.htm). Recommended pattern: keep a QTE clock in **milliseconds** (`qte_ms += min(delta_time, 50000) / 1000` so a stall can't skip the window), define every cue as `t_open_ms`, `t_target_ms`, `t_close_ms` per move, and judge `abs(press_ms - target_ms)` against ms constants. Windows then live in one table, are the same at 30 / 60 / 120 fps, and can be scaled by one multiplier (assist) and shifted by one calibration offset.
- **Quantisation.** GML polls input once per Step, so a press is timestamped to the frame in which it is seen. At 60 fps that is up to 16.7 ms late. Take the `get_timer()` value at the top of the Step that sees the press, not a value from a later frame; keep windows >= ~100 ms (perfect >= ~50 ms total, i.e. +/-25 ms).
- **Animation-driven cue.** Drive the actor animation from the same QTE clock (set frame from `qte_ms`) instead of `image_speed`, so the visual hit moment and the judged moment cannot drift.
- **Input reading, one abstraction.** Project already has `Input_UIPressed`. Add one `Input_QtePressed()` that returns true for keyboard confirm (`keyboard_check_pressed`), gamepad A (`gamepad_button_check_pressed(device, gp_face1)`), or a touch tap (`device_mouse_check_button_pressed(0, mb_left)`, which maps touches to mouse indices; manual: https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Game_Input/Device_Input/device_mouse_check_button.htm). For touch accept a **large tap zone (whole lower half or whole screen)** in the battle state, not a small button; fingers cover small targets and phones differ in latency. Ignore the press that selected the skill (the code already has `ATTACK_TIMING_INPUT_LOCK_FRAMES 2`; make it ms based, ~100 ms).
- **Early press handling / buffering.** Keep a tiny ring buffer of `(timestamp, device)` presses per Step. Judge the press **closest to the target time inside the open window**; presses before `t_open` are discarded or flagged "early" (design choice from principle 5), not queued for later. Buffering is for menu confirms and for the *next* turn, not for widening the QTE window.
- **Drawing on the GUI layer.** Draw cue, ring and result text in a Draw GUI event so it does not scale with the camera/room. Choose one logical GUI size with `display_set_gui_size` (manual page returned 403 for me; function is documented in the GameMaker manual under Drawing > GUI Layer), and convert touch to GUI coordinates with `device_mouse_x_to_gui(device)` / `device_mouse_y_to_gui(device)` (manual: https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Game_Input/Device_Input/device_mouse_x_to_gui.htm; note it updates only while touched on mobile). This also addresses the project's known resolution/scaling problem, but keep it a separate decision from the QTE redesign.
- **Calibration in ms.** Provide one screen: a marker ping/flash every 600-800 ms, player taps 8 times, take the **median** of `press_ms - ping_ms` (discard the first two), store as `qte_offset_ms`, add it when judging, and also expose a manual +/- 5 ms slider (Deemo-style). Do not play sounds on the taps (Rhythm Quest guidance). Android audio latency can be 100+ ms; a visual-first cue with a quiet sound is safer.
- **Hit-stop.** Implement as a `hitstop_ms` counter that freezes only the two battle actors' animation clocks (not input polling, GUI or audio), 3-6 frames (~50-100 ms) on Good, 6-10 on Perfect, plus a flash; keep result text running.
- **Assist options (store in the save/settings):** `qte_window_mult` (1.0 / 1.5 / 2.0 / 3.0), `qte_auto_success` (off / on, on = bonus reduced, e.g. Good tier only, per the Sea of Stars / Simplifier precedent), `qte_enabled` (off = flat, slightly lower damage and block), `qte_offset_ms`, and optionally a battle animation speed slider.
- **Testing.** The project has no test runner; keep the judge a pure function (`Qte_Judge(press_ms, target_ms, window_table, mult, offset)` returning tier) so a GML assertion block can check it at boundaries (exactly at +/-edge, early, late, with `mult` 2.0, with offset).

---

## 4. Open-source references (turn-based RPGs with timed hits or clean battle structure)

Checked with `gh`. License "none stated" means no license file: read, do not copy.

1. **pmret/papermario** — https://github.com/pmret/papermario — C, decompilation of Paper Mario 64 (no license for game code; reference only). Read `src/battle/action_cmd.c` (difficulty tables, `check_block_input` with ring buffer, early-press rejection, Dodge Master) and `src/battle/action_cmd/jump.c` (state machine: INIT -> APPEAR -> START -> ACTIVE -> DISPOSE; `autoSucceed`; early press = fail). The best source for exact timings that Nintendo shipped.
2. **doldecomp/ttyd** — https://github.com/doldecomp/ttyd — C, MIT, in-progress Thousand-Year Door decomp. Where the 8-frame guard / 3-frame superguard live; still incomplete.
3. **Toastworth/Millennium** — https://github.com/Toastworth/Millennium — C# / Unity, MIT, last updated 2021, README says unstable. A fan framework recreating TTYD battles (stylish moves, action commands). I could not find the action-command files by path (project layout is under `Assets/`); search the tree for "Stylish" / "ActionCommand" before relying on it.
4. **gdquest-demos/godot-open-rpg** — https://github.com/gdquest-demos/godot-open-rpg — GDScript (Godot 4.6), MIT, 3000+ stars, active. Clean turn-based combat architecture: `src/combat/combat.gd` (state/turn driver), `src/combat/actions/battler_action*.gd` (action objects), `src/combat/combat_events.gd` (signals for UI), `src/combat/ui/action_menu/`. No timed hits; read it for how to structure a battle state machine and keep UI event-driven.
5. **NonEuclideanBattleship/jrpg-example** — https://github.com/NonEuclideanBattleship/jrpg-example — C# / Unity, no license stated. "Hybrid ATB / timed hits". State machines in `Assets/Scripts/Runtime/Battle/BattleStateMachine.cs`, `PartyMemberStateMachine.cs`, `EnemyStateMachine.cs`, with a message bus in `Core/MessageManager.cs`. Read for the state-machine split, not for timing math.
6. **speakertone/action-commands-rpg** — https://github.com/speakertone/action-commands-rpg — GDScript, no license, active Nov 2025. Brand-new "Turn-based RPG with a focus on a wide variety of action commands". Skeleton: `scripts/action-commands/action_command.gd` (base class with `command_succeeded` / `command_failed` signals) and `hold_release.gd` (hold-release archetype), `success_indicator.gd`. Shows an archetype-per-command class layout, little content yet.
7. **stareyednya/TimedHitsRPG** — https://github.com/stareyednya/TimedHitsRPG — C# / Unity, no license, 2020, tiny. `Scripts/DetermineAttackTiming.cs`: judges by **animation normalized time** (0.6-0.7 = critical x2.0, 0.45-0.6 or 0.7-0.85 = good x1.5), which is the "animation is the cue" pattern in about 20 lines; `DetermineDefenseTiming.cs` for blocks.
8. **jellees/mlss** — https://github.com/jellees/mlss — Assembly, Mario & Luigi: Superstar Saga decomp, WIP. Reference only if you want the real counter/Bros. window values later.
9. GameMaker: no good open-source GameMaker battle repo found on GitHub. itch.io downloads: **Sara's Turn Based Battle System** (source with a state-machine episode; https://sarajs.itch.io/saras-turn-based-battle-system/devlog/510085/state-machine-update-episode-3-source-code-added) and **Turn Based Battle System Engine** (https://nathanjm080.itch.io/battlesystemengine). Licenses unknown. The Godot template https://samhilly451.itch.io/turn-base-combat-system-template-godot is Paper Mario / Mario & Luigi style with action commands (assets not reusable).

Not relevant (confirmed): the Elden Ring / action-combat reverse-engineering repos.

---

## 5. Three design options for this game

Common to all: judge in milliseconds from one table; one assist multiplier and an auto-success option; a miss still deals normal damage / normal block; success makes a visible and audible hit (hit-stop, flash, sound); touch = big tap zone.

### Option A — One-button action commands (Super Mario RPG / Paper Mario / Sea of Stars)
- **Attack:** the attacker's animation has one telegraphed impact frame, lit by a short ring/flash on the target. Press near it. Good (+/-100 ms): +25%. Perfect (+/-40 ms): +50% and a hit-stop plus shockwave. Miss: normal damage.
- **Defence:** each enemy skill has a fixed wind-up of a fixed length; one press just before the strike lands. Guard: -35%. Perfect Guard: -70% and a small counter. Miss: full damage.
- **Per enemy skill:** a fixed timing (learnable); different skills have different wind-ups, giving variety without new inputs.
- **Assist:** window x1.5 / x2 / x3; auto-success = Good tier only; QTE off = flat -10% damage / +10% taken.
- Pros: easiest to learn and to make readable on all three input types; smallest code change (reuses attack and defence hooks); works on touch; precedent in nearly every game surveyed. Cons: least novel; could feel repetitive across long grinds unless timings vary per skill; need real animation tells.

### Option B — Per-skill timing archetypes (Lost Odyssey / Shadow Hearts / Legend of Dragoon / Undertale weapons)
- Each skill declares an archetype: **tap** (closing ring), **hold-release** (charge and release at the sweet spot), **2-3 beat rhythm** (for signature skills only), **meter** (Undertale-style bar). Success tiers fill a "Focus" meter that powers a stronger skill; ring size and speed are fixed per skill.
- Pros: strongest variety; good fit for the existing bar/ring art; archetype choice becomes part of skill identity and build. Cons: much more content and tuning (each skill needs a tutorial and a ms table); hold-release and multi-beat are harder on touch and for accessibility; more risk of repeating the "unsatisfying QTE" problem if some archetypes are weak.

### Option C — Telegraphed reactive defence (Clair Obscur-lite), simple attacks
- **Attack:** one tap, Option A style, or auto with a bonus on a perfect tap.
- **Defence:** the enemy shows its pattern **ahead of time** (e.g. 1-3 arrows or flashes that appear during the wind-up, not after); the player dodges/parries each when it lands; fixed pattern per enemy skill; perfect parry = counterattack. Keeps the current four-direction idea but makes it readable and consistent.
- Pros: the most "engaging" enemy turn; learning enemy patterns is the skill (Clair Obscur's pitch); keeps the existing arrow input. Cons: most fatiguing if used on every enemy turn, 3-5 prompts hits the "fatigue" risk exactly; hardest to tune and to make fair on touch; needs reliable telegraph art for every enemy.

### Recommendation: **Option A as the base**, with Option B's archetype hook added later for 2-3 signature skills.
Reasons: it is the cheapest way to remove the three biggest faults (random speed, zero-damage miss, unreadable random arrows), it is the system that most surveyed games converge on, and it already supports keyboard, gamepad and touch with the same single input. Make bosses the only place that use short telegraphed 2-3 beat patterns (a small slice of Option C), not every enemy. Suggested first values (to be calibrated by playtest, **not** taken from a source): Good +/-100 ms, Perfect +/-40 ms (assist x1.5 / x2 / x3), attack wind-up 500-700 ms, defence wind-up 600-900 ms, result feedback in under 100 ms, hit-stop 50-100 ms.

---

## 6. Gaps and what I could not confirm
- Exact windows for Super Mario RPG, Mario & Luigi, Legend of Dragoon, Sea of Stars, South Park, Costume Quest, Lost Odyssey, Shadow Hearts, Undertale: **not found**. Treat any number from those games as unknown.
- Paper Mario frame figures: wiki pages disagree (3 vs 8 frames); the decomp confirms table structure and the 3-frame block window, but the tick rate was inferred.
- Clair Obscur ms numbers are player measurements, not from Sandfall; only the +40% Story change is official.
- The Game Developer / Sakurai / "Art of Screenshake" sources were not read in full; hit-stop numbers above are rules of thumb from the two hit-stop articles cited.
- The Legend of Dragoon wiki page and `display_set_gui_size` manual page returned errors (402 / 403) when fetched.
