# Big build plan (D71: build everything, then one big playtest)

Spec = `research/DECISIONS.md` (D1-D94). Work lands on branch `next`; at the end, one full gate + one playtest build.
Max 2-3 implementer agents at once, only on non-overlapping files. Every drawing change runs `-Only shots`
and the main session opens the PNGs before merging. Data stays in the GML DB scripts (`scr_db_*`); the
game exports JSON with `-exportdata` for the Python simulator (no Included File needed).

| # | Packet | Decisions / issues | Status |
|---|---|---|---|
| A1 | Draw-space bugs: sight ring + prompt drawn top-left, ring gone after battle; arrow outline; run animation; effects ≥ target size | I-056, I-058, I-059, I-060, I-063 | MERGED to next |
| A2 | Window modes (windowed sizes / borderless / exclusive), resize, rm_floor6_5 clamp, hold-to-skip intro & scenes | D91, D48, I-054, I-055, DISP-10/11 | MERGED to next |
| B1 | Stats ATK/DEF/SPD/MAG + HP/MP, ratio damage, level-up (class growth + 1 free point), `-exportdata` JSON | D22, D76, D77 | MERGED to next |
| B2 | Statuses (poison stacks, burn, bleed), no dice anywhere, Evasion/Solidify, Foresight | D78, D79, D80, D21 | MERGED to next |
| B3 | Turn timeline (next 5), stun push-back + Steadfast, stagger meter + BREAK, damage numbers | D74, D75, D92 | MERGED to next |
| B4 | Battle AI rule lists, telegraphed big attacks, boss phases | D68, D7 | MERGED to next (follow-ups I-065, I-066) |
| C1 | Run loop: run/profile save split, seeded RNG streams, death → entrance, echo gift, abandon run, auto-save + continue, story seen once, run history, unlocks | D25-D27, D30-D33, D36, D46, D87, D88, D92 | MERGED to next |
| C2 | Chests (class first, then cards), class pick (Nobody locked), cards 1-of-3 at chests + level-ups, upgrades, passives (shared + class), max 3 skills equipped | D73, D81, D82, D34, D83 | MERGED to next |
| C3 | Gold, merchant after floors 2/5/8, throwables (all classes, Nobody stronger), accessory slot, elites, per-run shuffles | D23, D33, D84, D85, D86, D92 | MERGED to next |
| C4 | Beds (heal or upgrade), tutorial prompts + Help page, settings (QTE assist, key rebinding, text speed, shake), device button prompts | D45, D47, D49, D92 | MERGED to next |
| D0 | Shared UI framework: one menu component (wrap-around, hold-to-scroll, same confirm/back, back = one level, remembered cursor, mouse hover/click/wheel), frames, fonts, motion, details panel with data-generated text; migrate the title menu first as the pilot | D95-D98, D100 | MERGED to next (title + settings on the framework) |
| D1 | (split: D1a battle HUD + battle menus + dialogue + I-065/I-066 — MERGED to next; D1b Tab menu + pause + inventory/gear + codex + remaining screens — after C3/C4) Every screen on the framework: settings, credits, battle HUD (D99) + battle menus, Tab menu (Status/Skills/Items/Gear/Codex/Settings) + pause, class pick, card pick, shop, bed, level-up, run end, echo pick, dialogue box (D101), prompts; remove the old per-screen menu code | D89, D90, D96, D99, D101, I-061, I-062 | todo |
| D2 | Art: ComfyUI icons (status, skills, items, throwables, passives) + card frame, PNG strips + owner import checklist; code fallbacks until imported | D10, D43, D44, D94 | MERGED to next (script-drawn icons; SDXL base unusable at 16 px; owner import pending) |
| C5 | Story in runs: death scene (D103) + rotating death lines, wake at tunnel entrance, seen-once story with boss name banners (D106), lore notes in existing rooms incl. death-count notes (D107), credits text update (D105) | D102-D107, D26 | MERGED to next |
| D3 | Text: cards, passives, death lines, lore notes, merchant, tutorial, codex (EN + KO draft); credits list (sound creators from owner) | D93, D40, D105, D107 | todo |
| F1 | Full optimisation + consistency pass: frame-time probe in the bot (before/after), per-frame work and allocations, draw calls, room loads; dead/duplicated code, frame-counted timers → ms, global sprawl; consistent controls, wording, colours, sounds, naming | D108, ROB-01..03 | todo |
| E1 | Simulator on `-exportdata` JSON, target bands, balance proposals for the owner | D13, D14 | MERGED to next — proposals await owner (BOARD) |
| E2 | Full gate, regression list run, playtest build + one big PLAYTEST-QUEUE | D71 | todo |

Order: A1+A2 → (B1 ∥ D0) → (B2 ∥ C1) → B3 → (B4 ∥ C2) → C3 → C4 → C5 → D1 (∥ D2 art) → D3 → F1 → E1 → E2.

Step-number ranges (C4: smoke 161-170, shots 160-169, bot v=9) (avoid scenario clashes): smoke C1 100-112, C5 113-121, C2 133-141; shots UI 80-89, B3 90-97, C2 120-128, B4 140-149, C3 150-159, C4 160-169, D1 170-199.
