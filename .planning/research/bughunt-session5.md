# Bug-hunt notes, session 5 (from packet reports; triage into ISSUES.md at the build cut)
- H1: global.encounter_snapshot never cleared when a fight ends; a later quit in a battle not started via EnemyPersist_BeginEncounter would write a stale snapshot. Clear it on battle end.
- H1: dead loc keys pause.*, settings.row.apply, settings.help.apply, settings.value.pending/saved.
- H1: pad Start opens the menu but the prompt glyph says "X" (H8 device-aware prompts).
- H3: balance sim still reads elite_chance, doesn't know floors 1-2 have no elites.
- H2: Controls 'Reset to defaults', shop buy, bed upgrade not behind the Yes/No pop-up (Reset should be).
- H7: longest note title truncates ('Torn survey pa..') in the Codex Notes list at 800x720 (H13b text sweep).
- H5: one fast gate run exited with a native crash code AFTER printing fail=0 errors=0 (rerun clean) — check the game's exit path (surfaces/sprites created at runtime, Game End save).
- H13: G7 smoke check g7_the_enemy_turn_with_run_held_takes_about_half_the_time flaked once (368 vs 333 ms) under parallel gates — timing check may need a wider margin or frame-based measure.
- H5: dead D130 item-echo functions (Run_EchoFilter, Run_EchoOptionsFor, Run_EchoPoolAfter, Run_EchoGrantTo) + their checks; remove together.
