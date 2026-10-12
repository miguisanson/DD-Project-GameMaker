# Research index (2026-10-13)

Each file: key findings → the phase that uses it. Phase list: `.planning/ROADMAP.md`.

| File | Key findings | Used by |
|---|---|---|
| `DECISIONS.md` | 24 locked owner decisions (grill-me 2026-10-13). | All phases |
| `playtest-notes.md` | Verbatim inbox: 8 friend notes + 6 owner notes. | Phase 3, `ISSUES.md` |
| `lessons-from-past-projects.md` | Why rpg-gm/NWN ended buggy: checks did not exercise the game, unplayed work piled up, the reviewer read reports instead of running checks, "done" was just a word. §4 = check ladder L1–L5, packet size, max 2 implementers, reviewer duties, regression list, stop rules. | Phase 1, `IMPROVE.md` |
| `AGENTS-CHANGES.md` | Proposed AGENTS.md text (gate, Igor trap, team split, Rule 1 table). Apply after Phase 1 proves the harness. | Phase 1 |
| `automation-igor.md` | Headless Igor compile WORKS (~9–13 s). Game runs, output captured; test flag, battle bot and screenshots proven in a scratch copy. Igor misses unknown functions (exit 0) — runs are needed. Redirect LOCALAPPDATA to protect saves. Only Windows VM Release tried. | Phase 1 |
| `resolution-gamemaker.md` | One display manager; 160x144 surface; integer scale drawn in Post Draw; one GUI-size owner; 13 pitfalls matching our bug; six points need a spike; test matrix + screenshot checker. | Phase 2 |
| `qte-design.md` | Same move = same timing; reward success, don't punish; 2–3 grades; visible telegraph; hit-stop + sound; ms clock; 8 open-source references. | Phase 6 |
| `balance-methods.md` | "4–5 missed slashes" is expected maths of the d20 roll. Fix = one data export + Python Monte Carlo simulator + written target bands; PRD/streak-breaker ideas. | Phases 4, 8 |
| `retro-ui.md` | Status icons need turn counter + last-turn blink; shape (not colour) for buff/debuff; one 9-slice frame; Galmuri (OFL-1.1) for Korean; proposed battle layout. | Phase 9 |
| `icons-comfyui.md` | ComfyUI is installed (E:\ComfyDesktop, models in E:\AI\ComfyUI). SDXL + Pixel Art XL LoRA + PixelOE; AI output = sketch, hand-finish at 16x16; avoid FLUX.1 [dev] LoRAs (non-commercial). | Phase 10 |
| `audit/combat-bugs.md` | Poison tick exists but is silent; Foresight lasts 9 turns, basic attack wastes it, shown as tiny text; books twice / mini boss likely already fixed (old build); Ice Spear / Hilt Bash at FX speed cap + 1 s hold; hit chance 62–89 %. | Phases 3–5 |
| `audit/balance-data.md` + `audit/data/*.csv` | All numbers. One clean pass reaches ~L8 but the final boss is L10; stun combo wins 93 %; DoT dwarfs direct damage; Easy/Hard barely differ; no gold; loot flat from floor 3. | Phases 4, 7, 8 |
| `audit/qte.md` | Two systems (basic-attack ring, enemy-skill arrows); skills have no timing; Perfect ≈ 1–2 frames; random ring speed; frame-rate bound; no feedback. | Phase 6 |
| `audit/resolution.md` | Display code called from 5 places incl. the audio manager and Transition_Finish. Ranked causes of the cutscene/dialogue-end bug (H1 re-apply at transition end, H2 art cleared before fade, …). Owner checklist. | Phase 2 |
| `audit/ui.md` | Flat white/black boxes on 4-colour art, mixed pixel grids, 10 of 14 statuses are text tags, no skill icons, flat inventory, no enemy name/HP. | Phase 9 |
| `audit/icons-needed.md` | 16x16, 4 colours, 1-px outline; 10 status + 14 skill + items + ~14 UI pieces. Skill-book and some stat icons become obsolete (D18, D22). | Phases 9, 10 |
| `../codebase/*` | Architecture, structure, stack, conventions; concerns (≈352 step-counted timer lines, 18 ds creates vs 6 destroys, no atomic save, debug keys always on); what is pure enough to unit-test. | Phases 1, 4, 11 |
