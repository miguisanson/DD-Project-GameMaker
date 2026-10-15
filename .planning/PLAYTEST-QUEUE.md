# Playtest queue

What the owner needs to play, test or decide after the agents worked while the owner was away. Used by `IMPROVE.md`.

**This is playtest 2:** everything built since playtest 1 (build d312bfb), played in ONE big session of about 60-90 minutes (D71). Playtest 1 is finished: the owner approved the new fights (D72) and its nine entries were replaced by this list (the old text is in git, commit 5ca29fa).

## How this file works

- Each feature or fix that the owner has to judge by playing gets **one entry**, written in the same commit that lands on branch `next`.
- Each entry has the exact steps, the expected result, the build id, and what to say afterwards.
- The **Unplayed** number in the header is the count of entries still marked `unplayed`. There is no cap (D71): the agents build everything that is decided, then you play once.
- When you play, mark each entry `good`, `bad` or `change` (and add a few words). Then say "merge the good ones". Good ones go from `next` to `v1.9` only on your word. Bad ones are reverted on `next` and become a row in `ISSUES.md`.
- The agents never write a verdict for you. A line saying `played` or `good` is written by you (or by the agent only because you said it in chat, with the date).
- The entries are in **play order**: they follow one natural run, from the first launch to the ending. You do not need to stop the game to write notes; mark them afterwards.

**Build to play:** `E:\Games\DD-Project Playtest\fc886c7-20261015\DD-Project.exe` (the build id is shown bottom-right of the title screen) | **Branch:** `next` | **Unplayed:** 57

**Before you play:**
- Your old saves were moved to `E:\Games\DD-Project Playtest\old-saves-2026-10-15`, so the game starts fresh: no run, no story seen, no hints seen yet. Your old *settings* were kept (Windowed, scale 5, volumes UI 50 / SFX 50 / BGM 80), so the first start will probably be a window, not full screen. That is expected (Q-001).
- Keep GameMaker closed.
- Not imported into GameMaker yet (so expect the stand-ins): the new icons are small shapes drawn by the game, the merchant looks like the Nobody character (with the gold glow), and the 30 extra monster sounds are missing (the monsters still vary a little in pitch and volume).
- Plan: play one normal run from the start and do each entry when it comes up. Mark "not reached" for anything you never see.

**Keys**
- Walk: W A S D or the arrow keys. Run: hold Shift.
- Talk, open, use a bed: Space (also Z or Enter). Confirm in menus: Space, Z or Enter. Back: X or Esc.
- Tab menu: I or Tab. Pause menu: Esc (it opens when you stand still). Switch menu tabs: Q and E.
- Controller (if you have one): A confirm, B back, X Tab menu, Y pause, shoulder buttons switch tabs, triggers run.
- Time savers (testing only, may be removed before release): press P once to switch debug on, then L = one level up, K = all items, J = die now. If you use K or L, say so in your note, because it changes the balance.

## Entry template (copy for each new entry)

```
### Q-001 | feature or fix name | commit abc1234 | build fc886c7-20261015
- Status: unplayed   (you change it to: good / bad / change)
- Requirement / issue: (REQ id, D-number or I-id)
- Automated proof already run: (checks, R-ids, build id, screenshot names)
- Steps (about 2 minutes):
  1. ...
  2. ...
- Expected: ...
- Look out for: (what could be wrong that a bot cannot see: feel, speed, sound, readability)
- Your note: 
```

## Entries

Automated proof for everything below: the full gate passed on `next` at e1a322d (795 s, about 800 checks, bot fights, screenshots). Entries marked "(new tonight)" were merged or built after that gate (random-loot fairness is on `next` at 89dba56; the alt-tab pause and the odds text were still being built when this list was written). The main session fills in their final commit and proof.

## Stage 1: First launch (about 8 minutes)

### Q-001 | Window mode and build id at first launch | commit 26a9523 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D91, I-054
- Automated proof already run: Test_Suite_Display, smoke window-mode steps (tests force Windowed, so the real default was never seen on screen).
- Steps (about 1 minute):
  1. Start `DD-Project.exe`.
  2. Is it full screen without borders, or a window?
  3. Read the small build id at the bottom-right of the title. Does it match the folder name?
  4. Check the title list: New Game, Continue (greyed out, no run yet), Settings, Exit Game.
- Expected: a brand-new install opens in borderless full screen. Because your old settings were kept you will most likely get a 5x window instead; that is fine. Title picture sharp, music playing, no flash or jump.
- Look out for: the window changing size or flickering while it starts; build id too faint to read.
- Your note:

### Q-002 | Settings: volume, window mode, window size, language | commit 26a9523 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D91, D49, D95, I-062
- Automated proof already run: Test_Suite_UI (204 checks), smoke drives Settings through the real keys, window-size screenshots.
- Steps (about 3 minutes):
  1. Title, Settings. Up/Down moves (W/S or arrows), Left/Right changes a value (A/D).
  2. Change UI, SFX and BGM volume and listen to each.
  3. Window: try Windowed, Borderless and Exclusive. In Windowed change Scale (3x, 4x, 5x).
  4. Go to Apply (bottom row) and confirm. Leave with Back and open Settings again.
- Expected: Apply changes the window at once and says Saved. Back without Apply keeps the old settings. Scale is greyed out unless Windowed. The picture is never stretched or blurry.
- Look out for: text hard to read at some size; flicker when switching modes; is Apply easy to find; do volume changes feel right?
- Your note:

### Q-003 | QTE assist, text speed, screen shake | commit c819526 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D49, D35
- Automated proof already run: Test_Suite_Assist, smoke assist steps (bar zones x1.5, arrow time x1.3).
- Steps (about 2 minutes, then check again during fights):
  1. In Settings set Text speed to Slow, then Fast (watch the next dialogue).
  2. Set Screen shake Off and Apply (notice that Perfect hits no longer shake the screen).
  3. Set QTE assist On, fight a few battles, then try it Off.
- Expected: dialogue types visibly slower or faster. Shake Off means no shake. Assist On gives wider bar zones (about 50%) and more time on arrow skills (about 30%).
- Look out for: is the difference between text speeds clear? Does Assist On feel like help or like cheating? Does it still feel too hard with Assist On?
- Your note:

### Q-004 | Key rebinding | commit c819526 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D49, D95
- Automated proof already run: Test_Suite_Binds, smoke Controls-page flow.
- Steps (about 2 minutes):
  1. Settings, Controls. Pick Run, confirm, press a new key (for example R).
  2. Pick another action and press a key that is already used. Try Esc while it waits for a key.
  3. Reset to defaults, then change one key again and Apply. Test it in the world later.
- Expected: the row shows "Press a key...". A key already in use swaps the two actions and says so. Esc cancels. Reset puts all keys back. Apply saves. The controller is not changeable.
- Look out for: any key you cannot undo; words that confuse; the new key not working in the world or in menus.
- Your note:

### Q-005 | Button prompts follow the keyboard or the controller | commit c819526 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D92. Needs a controller; skip it (mark "not reached") if you have none.
- Automated proof already run: Test_Suite_Prompt (labels per device), shots of the prompts.
- Steps (about 2 minutes):
  1. Connect a controller and press any controller button on the title.
  2. Open a hint (a tutorial pop-up, a card pick, the prompt over a chest). Note the button letters.
  3. Press a keyboard key and look again.
- Expected: prompts show the device you touched last: A / B / X / Y on the controller, key names on the keyboard. Both work at any time.
- Look out for: a wrong or missing button picture; a delay before the prompt changes.
- Your note:

### Q-006 | Menu controls feel (same in every menu) | commit 642e7bd | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D95, D96, D97, I-061, I-062
- Automated proof already run: Test_Suite_UI, shots of every menu.
- Steps (about 2 minutes, on the title and Settings; you will use it again in Stage 9):
  1. Press Up on the first row (jumps to the last), Down on the last (jumps to the first).
  2. Hold Down: slow at first, then faster.
  3. Mouse: hover moves the cursor, left click confirms, right click goes back, wheel scrolls.
  4. Back goes up one level only. Reopen a menu: the cursor is where you left it.
- Expected: the same keys and behaviour everywhere. Panels slide and fade in about a tenth of a second, with soft clicks.
- Look out for: scrolling too fast or too slow; any menu that behaves differently; sounds too loud or harsh.
- Your note:

## Stage 2: Start of a run and moving around (about 8 minutes)

### Q-007 | New Game, intro cutscene and skipping | commit 4d312bf | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D48, D35, I-051, I-055
- Automated proof already run: smoke display steps (0 re-layouts over room changes, cutscene end, dialogue end), shots at 480x432 / 1000x700 / 1920x1080.
- Steps (about 3 minutes):
  1. Title, New Game. The run starts at once (no difficulty list any more, D35). Later, with a run saved: the title cursor starts on Continue, and New Game asks "Sure? Confirm again" before it throws the saved run away.
  2. Watch the intro for about 10 seconds, then HOLD Space (or Z or Enter) for about 1 second to skip it. (The intro plays only once, so you only get one try.)
  3. Read the first dialogue (tap to advance). Walk into the first room.
- Expected: holding about 1 second skips the intro and counts it as seen. The picture never jumps, shrinks, shifts or flashes when the cutscene or the dialogue ends.
- Look out for: is it clear you must hold to skip? Any screen glitch at the end of the cutscene? Is the "confirm again" on New Game clear enough when you have a run saved?
- Your note:

### Q-008 | Walking, turning, running, bumping | commit bcedf32 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D69, D70, I-048, I-063
- Automated proof already run: movement bot (grid snapping), Test_Suite_Nav, shots.
- Steps (about 2 minutes):
  1. Tap a direction once (you turn without stepping). Hold it to walk. Turn at a corner without stopping.
  2. Hold Shift while walking to run.
  3. Walk into a wall or tree. Stop and look: are you exactly on a tile?
- Expected: snappy and always on the grid. Running is faster and the walk animation speeds up (it does not freeze). Bumping gives a soft sound and a tiny nudge.
- Look out for: getting stuck mid-tile or on corners; run speed too fast or slow; any room where the map looks off the grid (tell me which room).
- Your note:

### Q-009 | Interact hints and the marks over enemies | commit cb984f0 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D70, I-056, I-058, I-059
- Automated proof already run: shot pairs (marks on and off) diffed for stray pixels, corner probe.
- Steps (about 2 minutes):
  1. Face a barrel, a chest, a bed or a door. A small arrow or prompt shows.
  2. Walk near an enemy: a faint dotted ring shows around it.
  3. Start a fight and win (or run away). Look at the ring and the screen corners after.
- Expected: the arrow has a dark outline and is readable on every floor colour. The ring is round the enemy and comes back after a fight. Nothing is drawn in the top-left corner of the screen.
- Look out for: the arrow blending into the floor; odd marks in a corner; the ring missing after a battle.
- Your note:

### Q-010 | Doors and room arrival | commit 946a689 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D64, I-049
- Automated proof already run: smoke door steps (every door reachable, one exit per entry).
- Steps (about 1 minute):
  1. Go through a door, walk off it, go back through. Do this 3 or 4 times.
  2. Notice the fade and where you stand on arrival.
- Expected: you arrive on the door tile of the new room, you do not bounce back, and the door works again once you step off and return. The fade is smooth and the picture steady.
- Look out for: bouncing, a door that triggers twice, a pause or jump during the fade.
- Your note:

### Q-011 | Enemies: sight, "!", chase, searching, personalities | commit bcedf32 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D63, D66, D67, I-047, I-050
- Automated proof already run: Test_Suite_Nav, bot parts A-F (path around walls, no overlap, sight blocked by walls, search then go home).
- Steps (about 4 minutes, on floors 1-3):
  1. Approach an enemy from behind a wall (it should not notice you), then step into its view: a "!" pops with a sound.
  2. Run away (hold Shift). It follows around walls, a little slower than you.
  3. Break the line of sight: it checks the last spot, then walks home.
  4. Watch enemies that have not seen you: slimes wander slowly, wolves patrol, plants stay put, ghosts drift.
  5. Let one touch you: the fight starts with its cry.
- Expected: as above. Wolves keep up with you. Enemies never stack on top of each other or get stuck.
- Look out for: is sight range fair (3-5 tiles)? Chase speeds fair? Any enemy stuck or jittering?
- Your note:

## Stage 3: Chests (about 5 minutes)

### Q-012 | The first class or skill chest gives the class choice | commit ebfcaed | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D73, D34, D83, I-057
- Automated proof already run: Test_Suite_Cards (140 checks), smoke steps 133-141, card shots.
- Steps (about 2 minutes):
  1. On floor 1 open the first chest you can reach that is a class chest or a skill chest (Space while facing it).
  2. On the class screen look at Knight, Archer, Mage and Nobody (Nobody shows Locked). Read the details on the right.
  3. Pick a class and confirm "Become ...?".
- Expected: whichever of the two chests you open first gives the class choice; the other one later gives a card pick (Q-013). Nobody is locked. You never see "nothing is there".
- Look out for: confusing words; the details panel missing numbers; the screen feeling slow or abrupt.
- Your note:

### Q-013 | Later skill chests: pick 1 of 3 cards | commit ebfcaed | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D81, D82, D18
- Automated proof already run: Test_Suite_Cards (offers, upgrades, passives, max 3 skills), card shots.
- Steps (about 3 minutes; skill chests are on floors 1, 4, 5, 7 and 9):
  1. Open a skill chest. You get 3 cards: new skill, upgrade ("+") or passive. Left/Right moves, Confirm takes.
  2. Try Skip once (it gives a little gold).
  3. When you already have 3 skills and take a 4th skill, it asks which one to replace.
- Expected: each card has an icon, one plain sentence and exact numbers. Maximum 3 skills at once. The first time, a "Cards" pop-up explains it.
- Look out for: are the choices readable and different from each other? Offers repeating too much? Wording?
- Your note:

### Q-014 | Item chests and barrels: chests are never empty (new tonight) | commit 89dba56 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D118, D117
- Automated proof already run: Test_Suite_FairRng (no empty chest result, tier odds), merged with the logic in 89dba56; the full gate after this merge is still to run (main session fills in).
- Steps (about 2 minutes):
  1. Open every chest you meet (item chests are on floors 3, 4, 6, 7 and 9) and a few barrels.
  2. Note what you get and on which floor.
- Expected: a chest always gives an item, never "Nothing found" and never a zero amount. Barrels may be empty. Plain items come most often, rarer ones less often, and later floors give better things.
- Look out for: any empty chest (tell me the floor); the same junk every time; gear that never fits your class.
- Your note:

## Stage 4: Battle (about 20 minutes, spread over the run)

### Q-015 | Battle screen and command menu | commit 505bd3b | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D99, D89, D96, I-066, I-067
- Automated proof already run: battle HUD shots, bot fight with a levelled Knight, smoke battle steps.
- Steps (about 3 minutes):
  1. Touch an enemy to start a fight.
  2. Look at the screen: turn strip across the top, enemy name with HP bar, stagger meter and status icons, your HP and MP bottom-left, commands bottom-right (Attack, Skill, Item, Guard, Run), a short log.
  3. Open the Skill and Item lists and move the cursor: a details panel shows numbers, MP cost and the arrows.
  4. Use Guard once.
- Expected: everything readable and not overlapping. Confirm picks, Back goes back. The details text matches what really happens. Guard lowers the damage you take; check that its description says so.
- Look out for: text too small; something hidden behind a panel; a menu that feels slow.
- Your note:

### Q-016 | Sliding bar for the basic attack | commit 90b59e4 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D56, D60, D61, D20. Approved in playtest 1 (D72); only check that nothing got worse.
- Automated proof already run: Test_Suite_Qte, bot Perfect and fail variants, shot_qte_bar.png.
- Steps (about 2 minutes):
  1. In 4 or 5 fights use Attack and press early, late, on the bright core, and not at all.
- Expected: the cursor sweeps the bar. A grade word (PERFECT / GOOD / OK / WEAK) with its own sound. You never fully miss. Perfect has a tiny freeze and shake.
- Look out for: sweep speed and zone size still right? Does the pop-up for the bar show once?
- Your note:

### Q-017 | Arrow sequences for skills | commit 5129de8 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D57, D58, D61. Approved in playtest 1 (D72); quick check only.
- Automated proof already run: Test_Suite_Qte arrow grader, bot casts per class, shot_qte_arrows.png.
- Steps (about 2 minutes):
  1. Use each skill you own a few times. Make one wrong press on purpose.
- Expected: arrows with a draining time bar. A wrong press shakes the arrows and costs time. The skill always fires. Grade word and sound.
- Look out for: time limits (3.4 / 4.2 / 5.0 seconds for 3 / 4 / 5 arrows); are the sequences easy to remember?
- Your note:

### Q-018 | Defence bar on big enemy attacks | commit 3eefcc9 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D59, D7, D68, I-066
- Automated proof already run: bot defended Ramming, shot_qte_telegraph.png, shot_qte_defence.png, Test_Suite_EnemyAI.
- Steps (about 3 minutes):
  1. Fight a Snake (Bite), a Spider (Poison Fangs) or the floor-5 mini boss (Ramming).
  2. Watch for a "!" with the attack name one turn before. Then press on the bright zone of the defence bar.
  3. Also notice that normal enemy hits have no bar.
- Expected: a Perfect block takes 25% damage and resists the status; a Weak one takes full damage. A status never lasts longer than normal.
- Look out for: is the warning clear and long enough (0.4 s)? Is blocking satisfying?
- Your note:

### Q-019 | Turn timeline (speed decides who acts) | commit 9dfeac7 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D74, D19
- Automated proof already run: Test_Suite_Turns, bot turn scenarios, timeline shots.
- Steps (about 2 minutes):
  1. In a few fights watch the strip at the top (the next 5 turns).
  2. Fight something fast (a wolf) and something slow (a plant or slime).
  3. Use a stun skill (for example Hilt Bash) and watch the enemy icon move back.
- Expected: faster fighters appear more often and can act twice before a slow one. Stun pushes the target back about one turn. The first time, a "Turn order" pop-up explains it.
- Look out for: can you tell who acts next at a glance? Does the strip flicker or jump?
- Your note:

### Q-020 | Stagger meter, BREAK and Steadfast | commit 9dfeac7 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D75
- Automated proof already run: Test_Suite_Turns (stagger, BREAK, Steadfast), B3 shots.
- Steps (about 3 minutes):
  1. Hit one enemy with Perfect attacks and stun skills and watch its stagger meter fill.
  2. When it is full you see BREAK!: the enemy is pushed back and takes +50% damage until its next turn.
  3. Stun the same enemy again soon after: it shows Steadfast and cannot be stunned for 2 of its turns.
- Expected: as above. Bosses have bigger meters and are pushed only half as far. A "Stagger and BREAK" pop-up shows the first time.
- Look out for: is BREAK obvious and rewarding? Is Steadfast understandable?
- Your note:

### Q-021 | Statuses: poison, burn, bleed (with turn counters) | commit 17a7aa9 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D78, D21, BUG-08
- Automated proof already run: Test_Suite_StatusRules, bot battles A and B, status shots.
- Steps (about 3 minutes):
  1. Get poisoned (Spider, Snake) and/or poison an enemy (Poison Arrow, Poison Mist). Add Fireball for burn and Wound for bleed if you have them.
  2. Watch the icons under the names and the numbers on them. Take a few turns.
- Expected: poison hurts for its stack count each turn, then drops by 1 (maximum 10). Burn is a big hit for 2 turns and cuts DEF by 25%. Bleed hurts only when the bleeder acts, stacks to 3 and lasts 3 turns. Each tick on you gives a log line, a sound and an HP-bar flash. The icon number matches what happens.
- Look out for: can you feel poison working? Icons readable (they are code-drawn shapes until imported)?
- Your note:

### Q-022 | Foresight, Evasion and Solidify | commit e9685dc | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D79, D80, D24, I-002, I-052
- Automated proof already run: Test_Suite_StatusRules, fix-foresight tests (Foresight+ gets its extra turns), shot_fx_* per skill.
- Steps (about 3 minutes; mark "not reached" if you never get these skills):
  1. Cast Foresight (Mage). Look at the eye effect and at the strip.
  2. Cast Evasion (Archer) and let the enemy attack once.
  3. Fight a slime that uses Solidify.
- Expected: Foresight lasts 3 turns, shows the enemy's next action on the strip (hidden big attacks too) and makes every Perfect zone 50% wider. The eye is small and beside the enemy. Enemies never miss by luck; Evasion dodges the next attack fully; Solidify makes the slime take 75% less from the next hit.
- Look out for: is Foresight easy to understand now? Eye size OK? Does the icon look like an eye (the drawn stand-in)?
- Your note:

### Q-023 | Damage numbers, skill speed and effect sizes | commit d0ddcbf | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D55, D92, I-052, I-060, BUG-05, BUG-06, BUG-21
- Automated proof already run: bot measures every skill at most 66 frames, shot_fx_* per skill, Test_Suite_Fx.
- Steps (about 2 minutes, during any fights):
  1. Watch the numbers that pop up when something is hit.
  2. Cast Ice Spear, Hilt Bash and a buff.
- Expected: numbers differ by grade and show "BREAK!" on a break. About 1 second from pressing to your next choice. Effects are at least as big as the target; buffs play on you, not on the enemy.
- Look out for: anything too rushed; numbers hard to read; an effect too big or too small.
- Your note:

### Q-024 | Enemy battle behaviour (rule lists, wind-ups) | commit 3eefcc9 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D68, D7
- Automated proof already run: Test_Suite_EnemyAI, bot_ai_* fights, B4 shots.
- Steps (about 3 minutes):
  1. Fight at least four different kinds of enemy and watch what each one does.
  2. When an enemy announces a big attack, break it (fill its stagger meter that turn) if you can.
- Expected: enemies behave differently (heal when low, weaken you when you are buffed, a big attack every few turns). A BREAK during the wind-up cancels the attack.
- Look out for: moves that feel random or unfair; an enemy that repeats one move; wind-ups you cannot read.
- Your note:

## Stage 5: Fairer randomness (about 6 minutes, new tonight)

### Q-025 | Critical hits with Take Aim (new tonight) | commit 89dba56, 1f5b7fd | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D119, D124. Needs the Archer; mark "not reached" otherwise.
- Automated proof already run: Test_Suite_FairRng (bag sizing, never more than 6 misses in a row at 25%), merged in 89dba56. The status line comes from the same bag size (Test_Suite_FairUi).
- Steps (about 3 minutes):
  1. As the Archer read Take Aim in the skill list or Skills tab.
  2. Cast it (3 MP, lasts 9 turns), then make 8 or more hits.
  3. Count the critical hits. Cast it again and count again.
- Expected: the text says "1 in every 4 hits is a critical." After each cast exactly 1 hit in every 4 is a critical, in a mixed order. No long runs without one, and not two in a row all the time.
- Look out for: is a critical clearly visible and audible? Is the tooltip clear?
- Your note:

### Q-026 | Fleeing: chance shown and rising (new tonight) | commit 89dba56, 1f5b7fd, d716e76 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D121, D124
- Automated proof already run: Test_Suite_FairRng (flee formula values, +25 points per failed try), merged in 89dba56. The RUN percentage is checked in Test_Suite_FairUi and shot_fairui_run_* (e.g. Knight vs Slime: RUN 52%).
- Steps (about 3 minutes):
  1. In a normal fight read the Run entry in the command menu. It shows a percentage.
  2. Try Run until it fails once, then look at the percentage again.
  3. In a boss fight look at Run.
- Expected: the percentage is your speed divided by (your speed plus the enemy's), rounded down (it only shows 100% when escape is certain). Each failed try in the same fight adds 25 points. It starts fresh in the next fight. Bosses show that you can't flee.
- Look out for: does the shown number match what happens? Does a failed try cost too much? Is the number easy to read?
- Your note:

### Q-027 | Enemy item drops never dry for long (new tonight) | commit 89dba56 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D120
- Automated proof already run: Test_Suite_FairRng and Test_Suite_RunSave (the dry-fight counter is saved and restored), merged in 89dba56.
- Steps (about 1 minute of attention, during the whole run):
  1. After every fight note whether an item dropped (gold always drops).
- Expected: each fight without an item adds 10 points to the next drop chance, and a drop resets it. You should never go about 10 fights in a row without an item, and usually far fewer.
- Look out for: long dry spells; a flood of drops that makes items feel cheap.
- Your note:

## Stage 6: Level-up (about 3 minutes)

### Q-028 | Level-up: fixed growth, 1 free point, then a card | commit 20f6333 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D76, D81, D22, D27
- Automated proof already run: Test_Suite_Stats, Test_Suite_Cards, smoke level-up steps.
- Steps (about 3 minutes):
  1. Win fights until you level up. A "Level N: place 1 point" screen shows each stat with Now and After. Pick one.
  2. Then a 1-of-3 card pick follows.
  3. Open the Status tab and check the numbers grew.
- Expected: your class grows by itself (Knight ATK and DEF, Archer SPD and ATK, Mage MAG) plus the point you place. The Nobody gets a second fixed point. About 10-12 card picks over a whole run. An enemy 3 or more levels below you may be beaten automatically ("You overpower...").
- Look out for: is the pace of levels good? Too many screens in a row? Do the stat numbers mean something you can feel?
- Your note:

## Stage 7: Gold, merchant, throwables, gear, elites (about 10 minutes)

### Q-029 | Gold counter and gold drops | commit 2b16016 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D23
- Automated proof already run: Test_Suite_Economy (about 240 checks), economy shots.
- Steps (about 1 minute of attention):
  1. Find the coin and number at the top-left, in the world and in battle.
  2. Win a few fights, including an elite or the mini boss if you meet one.
- Expected: gold goes up after every fight, more for elites and bosses. The counter never overlaps anything.
- Look out for: amounts too small or too big; counter hard to see.
- Your note:

### Q-030 | Merchant and shop (floors 2, 5 and 8) | commit 9b89e54 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D85, D113, D115, D23
- Automated proof already run: Test_Suite_Economy (shop buy and sell), merchant shots, smoke steps 142-146.
- Steps (about 4 minutes):
  1. On floors 2, 5 and 8 find the merchant (in an alcove near the stairs). It has a pulsing gold glow outline.
  2. Talk to it (Space). Buy something, sell something, and try to buy with too little gold.
  3. Leave and come back in the same run. Next run, look at the stock again.
- Expected: potions, throwables, gear and 1-2 cards for sale; details panel with numbers; names in white. Stock stays the same within a run and changes with every new run. The merchant says different lines.
- Look out for: does the glow make you notice it without looking silly? (The sprite is the Nobody stand-in until you import it.) Prices fair? Shop easy to use?
- Your note:

### Q-031 | Throwables | commit 2b16016 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D84
- Automated proof already run: Test_Suite_Economy (throw damage, Nobody x2), bot throw scenarios.
- Steps (about 2 minutes):
  1. Buy or find a throwable (firebomb, poison pot, ice flask, smoke bomb).
  2. In a fight open Item and throw it. Use the sliding bar.
- Expected: throwing costs your turn, uses the bar for its grade, and the item is used up. You carry at most 5 of a kind (8 for the Nobody, who also throws twice as hard). A "Throwables" pop-up shows the first time.
- Look out for: are throwables worth their price? Is the animation clear?
- Your note:

### Q-032 | Accessory slot and gear comparison | commit 2b16016 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D92, D90
- Automated proof already run: Test_Suite_Economy, Tab menu shots (shot_tabmenu_gear*).
- Steps (about 2 minutes):
  1. Find a ring or charm (shop or chest).
  2. Tab menu, Gear tab. Move over each item.
  3. Equip it.
- Expected: three slots (weapon, armor, accessory). Highlighting an item shows before and after numbers. The accessory gives a small bonus.
- Look out for: confusing before / after numbers; names hard to read.
- Your note:

### Q-033 | Elites: outline, one modifier, better rewards (D123 new tonight) | commit 2b16016, 89dba56 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D86, D123
- Automated proof already run: Test_Suite_Economy (elite stats and modifiers); the per-floor count rule is checked in Test_Suite_FairRng (89dba56).
- Steps (about 3 minutes):
  1. On each floor from 2 on look for an enemy with a pulsing light outline.
  2. Fight it: its name plate shows ELITE and one modifier (Armored, Venomous, Swift, Brutal or Regenerating).
  3. Win and look at the reward.
- Expected: about 1 enemy in 7 is an elite, at least one on every floor from floor 2, spread over the floors (not all in one room). Elites give more gold and a guaranteed card pick. An "Elites" pop-up shows the first time.
- Look out for: is the outline easy to spot? Are elites too hard for what they give? Floors with none, or with too many?
- Note: the simulator says this rule gives about 6 elites a run (the old random roll gave about 3); sim win rates drop 3-6 points (Knight 94 -> 88%). If runs feel too hard, the easy fix is to drop "at least one per floor" (back to about 3 a run).
- Your note:

## Stage 8: Beds and hints (about 4 minutes)

### Q-034 | Beds: heal or upgrade a skill | commit c819526 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D47, D46, I-064
- Automated proof already run: Test_Suite_Bed, smoke steps 161-168.
- Steps (about 2 minutes; beds are on floors 1, 3, 6 and 9):
  1. Face a bed and press Space. Choose Rest, or Upgrade (pick a skill).
  2. Use the same bed again.
- Expected: Rest restores all HP and MP; Upgrade improves one skill you own. Each bed works once per run; the second time it says you rested here already. The bed does not save the game any more (the game saves by itself).
- Look out for: is the choice clear? Should a bed also do something else?
- Your note:

### Q-035 | Tutorial pop-ups and the Help page | commit c819526 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D45
- Automated proof already run: Test_Suite_Tutorial, smoke pop-up steps, shots.
- Steps (about 2 minutes, as they appear; 11 in all: turn order, sliding bar, arrow skills, defence, stagger, cards, shop, throwables, bed, elite, statuses):
  1. Read each pop-up the first time it shows and press Confirm.
  2. Later press Esc, Help: open one you already saw and one you have not.
- Expected: each pop-up is short, shows the right key or button for your device, appears once only, and the press that opened it does not close it. Help lists all 11.
- Look out for: a pop-up at a bad moment (in the middle of a bar or arrows); too wordy; a hint you wish existed.
- Your note:

## Stage 9: Tab menu, Codex and pause (about 8 minutes)

### Q-036 | Tab menu: tabs and details panel | commit e1a322d | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D90, D100, D95, D115, I-061
- Automated proof already run: Test_Suite_UI, shot_tabmenu_* for every tab.
- Steps (about 2 minutes):
  1. Press I or Tab (controller X). Switch tabs with Q and E: Status, Skills, Items, Gear, Codex, Settings. Keep pressing past the end.
  2. In each tab move the list and read the right-hand panel.
  3. Back leaves one level at a time.
- Expected: tabs wrap around; each tab remembers its cursor; the right panel shows one plain sentence and the numbers. Names are white.
- Look out for: numbers overlapping on the Status tab; too much text; a tab that feels empty.
- Your note:

### Q-037 | Items and Skills tabs | commit e1a322d | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D90, D100
- Automated proof already run: Test_Suite_UI (rows come from the real data), tab shots.
- Steps (about 2 minutes):
  1. Items tab: use a potion outside battle.
  2. Skills tab: highlight each skill.
- Expected: the potion works and the list updates. Each skill shows its arrow sequence, MP cost and numbers; the numbers match what you saw in battle.
- Look out for: a tooltip number that disagrees with the game (that is a bug, tell me which); hard-to-use lists.
- Your note:

### Q-038 | Codex: bestiary, notes, runs, unlocks | commit e1a322d | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D88, D107
- Automated proof already run: Test_Suite_UI (Codex rows), Codex shots.
- Steps (about 2 minutes; check again after your first death):
  1. Tab menu, Codex tab. Open Bestiary, Notes, Runs and Unlocks.
  2. Go back one level each time.
- Expected: the Bestiary lists enemies you have met, Notes the lore notes you read, Runs your past runs (class, floor, cause of death), Unlocks what you have earned. Back from a page goes to the Codex list.
- Look out for: pages that are empty or confusing; text cut off.
- Your note:

### Q-039 | Pause menu | commit e1a322d | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D96, D92
- Automated proof already run: smoke pause steps, Test_Suite_UI.
- Steps (about 2 minutes):
  1. Stand still in the world and press Esc (controller Y).
  2. Look at the list: Resume, Help, Settings, Abandon run, Quit to title. Open Settings from here and come back.
  3. Press Esc again to resume.
- Expected: the game is frozen while paused. The help line under each choice explains it. Settings opened here work like the title Settings.
- Look out for: Esc pausing when you wanted Back; the menu being slow to open.
- Your note:

### Q-040 | Alt-tab opens the pause menu (new tonight) | commit 1f5b7fd, d716e76 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D122
- Automated proof already run: Test_Suite_FairUi + smoke fairui_* (bar frozen while paused, Abandon/Quit greyed in a fight, resuming while still unfocused does not re-open the pause); shot_fairui_pause_*.
- Steps (about 3 minutes):
  1. In the world Alt-Tab to another window for a few seconds and come back.
  2. In a fight, start a sliding bar or an arrow skill, then Alt-Tab away for 5 seconds and come back.
  3. Press Resume.
- Expected: the pause menu is open when you return. The music is quieter while you are away. The bar or arrows carry on exactly where they stopped (no lost time). In a fight, Abandon run and Quit to title are greyed out with a reason.
- Look out for: the game still moving while away; music not coming back; losing a turn or a bar.
- Your note:

## Stage 10: Death, the summary and the echo (about 6 minutes)

### Q-041 | Death scene and the rotating lore line | commit 39c0f9b | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D103, D102, D104
- Automated proof already run: Test_Suite_Story (line choice per death count and killer), death-scene shots.
- Steps (about 3 minutes):
  1. Lose a fight (or press P, then J for a quick test).
  2. Watch the fade, the falling sound and the line. Hold Confirm to skip it.
  3. Die again later: the line should be different.
- Expected: a fade to black, a falling and cracking sound, one line for 2-4 seconds. Lines get darker as deaths pile up and sometimes name what killed you. They never hint at what is outside.
- Look out for: tone right? Too long or too short? Skipping works?
- Your note:

### Q-042 | Run summary and the echo pick | commit 4d312bf | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D87, D103
- Automated proof already run: Test_Suite_RunLoop, smoke run-loop steps.
- Steps (about 2 minutes):
  1. After the death line read the summary (floor, class, cause, cards).
  2. Pick 1 of 3 items or cards from what you had in the lost run.
- Expected: the summary is clear. The echo is explained in a short line, and what you pick is waiting for you in the next run.
- Look out for: what if you had almost nothing to pick; wording of "echo".
- Your note:

### Q-043 | Waking at the tunnel entrance, a fresh run | commit 4d312bf | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D102, D26, D27, D33
- Automated proof already run: Test_Suite_RunLoop, Test_Suite_Rng (same seed gives the same shuffles).
- Steps (about 2 minutes):
  1. After the echo you wake at the entrance (floor 1) with a short line.
  2. Check your level, gold and items. Look at what chests and enemies are on the floors this time.
- Expected: level 1, no gold, only the echo item. The line fits how many times you have died. The content is shuffled (different enemies, chests, shop stock), not a copy of the last run.
- Look out for: dying and restarting feeling slow; the new run feeling too much like the last one.
- Your note:

### Q-044 | Abandon run | commit 4d312bf | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D92
- Automated proof already run: smoke abandon steps (two-step confirm).
- Steps (about 1 minute):
  1. Esc, Abandon run. The row changes to "Sure? Confirm again". Move the cursor away and see it reset.
  2. Choose it again and confirm.
- Expected: it needs a second confirm. The run ends like a death (summary, echo), with a line that fits abandoning.
- Look out for: easy to trigger by accident?
- Your note:

## Stage 11: Quit and Continue (about 3 minutes)

### Q-045 | Quit to title, Continue, auto-save | commit 4d312bf | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D46, D36, D125
- Automated proof already run: Test_Suite_RunSave, Test_Suite_Profile, smoke continue steps.
- Steps (about 3 minutes):
  1. Mid-run (after a room change and a fight) press Esc, Quit to title.
  2. On the title Continue is now usable. Choose it.
  3. Do it again, but this time close the game window instead of using the menu, then start it and Continue.
- Expected: you are back in the same room with the same HP, gold, items and cards. Enemies you beat stay beaten. You cannot undo a death by quitting.
- Look out for: losing progress; a long pause; a message that confuses.
- Your note:

## Stage 12: Story and lore (about 4 minutes)

### Q-046 | Story is told only once | commit 4d312bf | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D26, D106
- Automated proof already run: smoke story-once steps, Test_Suite_Profile.
- Steps (about 2 minutes, on your second run):
  1. Start a new run after dying. Walk through the first floors.
- Expected: the intro, the camera pans and the one-time dialogue you saw in run 1 do not play again. Ordinary talking to people still works.
- Look out for: a story scene that repeats; one you missed the first time and now cannot see.
- Your note:

### Q-047 | Boss name banner on later runs | commit 39c0f9b | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D106
- Automated proof already run: Test_Suite_Story (banner timing), banner shot.
- Steps (about 1 minute; only possible once you have seen a boss's camera pan in an earlier run):
  1. In a later run walk up to the floor-5 mini boss or the final boss.
- Expected: no camera pan; instead the boss's name shows for about 1 second.
- Look out for: banner too short or too long; hard to read.
- Your note:

### Q-048 | Lore notes | commit 39c0f9b | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D107
- Automated proof already run: Test_Suite_Story (note placement and death-count gates), note shots.
- Steps (about 2 minutes):
  1. Read notes when you see them: always there on floors 1, 3, 6 and 8. More show up after 3 deaths (floors 2 and 4), 6 deaths (floor 7) and 10 deaths (floor 9).
  2. Check them in the Codex Notes page.
- Expected: you read a note by facing it and pressing Space. Read notes are listed in the Codex. The death-count notes are your own earlier marks.
- Look out for: a note you could not find or read; text too long for the box; tone.
- Your note:

## Stage 13: Winning (about 6 minutes, only if you get there)

### Q-049 | Final boss and the ending | commit 39c0f9b | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D104, D31
- Automated proof already run: Test_Suite_Story (ending text), ending smoke steps.
- Steps (about 3 minutes):
  1. Beat the final boss on floor 10.
  2. Read the ending text.
- Expected: you escape the tunnel, then it turns out the outside is not safe either. It plays in full only the first time you win.
- Look out for: does it make sense? Is it paced well? Any typo?
- Your note:

### Q-050 | Closing credits | commit 39c0f9b | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D105, D109, D40
- Automated proof already run: Test_Suite_Story (credits lines), credits shot.
- Steps (about 2 minutes):
  1. Watch the credits roll after the ending.
- Expected: "Game and art by PaleRook", fonts, tools and sounds, then "Thank you for playing." and "by PaleRook". The sound creators still say "(owner to supply)" until you send the names; the three monster-sound authors are already named.
- Look out for: roll speed; text cut off at the edges; can you skip it? Does it return to the title?
- Your note:

### Q-051 | The Nobody class after the first win | commit ebfcaed | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D83, D88
- Automated proof already run: Test_Suite_Cards (Nobody locked until a win, passives), Test_Suite_Economy.
- Steps (about 5 minutes, only after a win):
  1. Start a new run and open the class chest.
  2. Pick the Nobody and play the first floors with its basic attack, passives and throwables.
- Expected: the Nobody is now selectable, has no skills, throws items twice as hard and carries 8 of each.
- Look out for: does the Nobody feel like a fair challenge, not an impossible one?
- Your note:

## Stage 14: How the whole game feels (about 5 minutes of thinking, no extra play)

### Q-052 | Run length and difficulty | commit 1c8dd66 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D111, D112, D14
- Automated proof already run: simulator report "After D111" (targets inside their bands).
- Steps:
  1. Note how long your best run took, how many deaths you had, and on which floors.
- Expected: a winning run takes about 25-30 minutes. Deaths come from mistakes, not from bad luck.
- Look out for: floors that feel like walls; floors that are too easy; times when you had to grind; potions and MP mattering.
- Your note:

### Q-053 | Floor-5 mini boss (Palehorn) | commit 1c8dd66 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D111, D68, D75
- Automated proof already run: bot boss fights, Test_Suite_EnemyAI (two phases).
- Steps (about 3 minutes):
  1. Fight the mini boss on floor 5. Watch for its phase change and its wind-ups.
- Expected: a longer fight with two phases. The big attack is announced and can be blocked or cancelled with a BREAK.
- Look out for: too long, too short, too hard; boring in the first phase?
- Your note:

### Q-054 | Final boss (Pale Choirbeast) | commit 1c8dd66 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D111, D68
- Automated proof already run: bot boss fights, Test_Suite_EnemyAI (phases).
- Steps (about 3 minutes, only if you get there):
  1. Fight the final boss on floor 10.
- Expected: the hardest fight of the run, with phases and readable wind-ups. It feels earned but beatable with good play.
- Look out for: a wall; a fight you win without trying; a phase that is unreadable.
- Your note:

### Q-055 | Do the classes feel different? | commit 1c8dd66 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D22, D76, D111
- Automated proof already run: simulator report (win rate per class).
- Steps:
  1. Try at least two classes over your runs (Knight, Archer, Mage).
- Expected: each class plays differently (Knight tough, Archer fast with crits, Mage with strong spells and MP use). None feels clearly worse.
- Look out for: a class you would never pick again; a skill that is useless.
- Your note:

## Stage 15: Monster sounds (about 3 minutes, during any fights)

### Q-056 | Monster sound variety | commit 0762b1a | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D116
- Automated proof already run: Test_Suite_Audio (pitch within 6%, volume within 10%, no repeat of the same take twice in a row).
- Steps:
  1. Listen to the same kind of enemy over several fights: its cry when the fight starts and its attack sounds.
  2. Listen especially to the killer plant when a fight starts.
- Expected: every cry sounds slightly different each time (pitch and volume). If the 30 new takes are imported, the same take does not play twice in a row. The killer plant's cry is very quiet in the original sound.
- Look out for: any monster that sounds the same every time; any sound too loud, harsh or too quiet; which of the new sounds you like or dislike (this is by ear, nobody checked it).
- Your note:

## Stage 16: Korean (about 3 minutes)

### Q-057 | Korean language quick look | commit 578c1c3 | build fc886c7-20261015
- Status: unplayed
- Requirement / issue: D9, D98, D93
- Automated proof already run: missing-Korean check in the gate, Korean shots of every screen.
- Steps (about 3 minutes, at the end):
  1. Settings, Language: Korean, Apply.
  2. Look at the title, a fight, the Tab menu, a card pick and a shop. Then switch back to English.
- Expected: the Korean pixel font is crisp, nothing is cut off or overflowing, and no English leftovers. The text is a first draft written by the agents, for you to review.
- Look out for: words that sound unnatural; text too long for its box; mixed English and Korean.
- Your note:

## Questions for the owner

Design questions the agents could not answer from `DECISIONS.md` or the research. They stay parked until you answer. Do not answer in your head; say them in chat so they get written down.

(none yet)

## IDE tasks for the owner

Work that needs a new or changed resource (object, sprite, room, script, font). Agents cannot do these (AGENTS.md Rule 4). Each line: what, why, which requirement.

(none yet)

## Balance proposals (need your yes)

Numbers the agents think should change, with simulator before and after. Nothing here is applied until you approve it by id (D13).

| Proposal | What changes | Before | After | Why (simulator metric out of band) | Your answer |
|---|---|---|---|---|---|
| (none yet) | | | | | |
