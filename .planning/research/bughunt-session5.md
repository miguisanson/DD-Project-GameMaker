# Bug-hunt notes, session 5 (from packet reports; triage into ISSUES.md at the build cut)
- H1: global.encounter_snapshot never cleared when a fight ends; a later quit in a battle not started via EnemyPersist_BeginEncounter would write a stale snapshot. Clear it on battle end.
- H1: dead loc keys pause.*, settings.row.apply, settings.help.apply, settings.value.pending/saved.
- H1: pad Start opens the menu but the prompt glyph says "X" (H8 device-aware prompts).
- H3: balance sim still reads elite_chance, doesn't know floors 1-2 have no elites.
- H2: Controls 'Reset to defaults', shop buy, bed upgrade not behind the Yes/No pop-up (Reset should be).
- H7: longest note title truncates ('Torn survey pa..') in the Codex Notes list at 800x720 (H13b text sweep).
