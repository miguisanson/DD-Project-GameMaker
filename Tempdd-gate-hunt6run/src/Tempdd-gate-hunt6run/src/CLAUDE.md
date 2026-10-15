# Claude Code — project notes

**Read [`AGENTS.md`](AGENTS.md) first.** It holds the rules every agent
follows (check first, targeted checks, scope, resource ownership, the gate)
and how work is split between Claude, Sonnet subagents and the local model. Do not
restate them here.

- **Plan and state:** `.planning/BOARD.md` is the owner's tracker,
  `.planning/ROADMAP.md` the plan, `.planning/STATE.md` (GSD Core) the session
  handoff, `.planning/research/DECISIONS.md` the owner's locked decisions.
- **Domain skills** — load before the matching work, per the AGENTS.md
  "domain craft" row: `game-ui-ux` for HUDs/menus/overlays, `game-feel` for
  hit/jump/pickup/death feedback, `save-systems` for `scr_save`/
  `scr_save_menu`, `audio-design` for `scr_sfx` and sound-bus work,
  `create-game-assets` for new sprite/tile/UI art.

Commands: `/continue_DD-Project-GameMaker` (start any session with it).

## Claude-specific conventions

- **The check** is a `Test_Suite_*` in `scripts/scr_test/scr_test.gml`, a
  scenario/screenshot run, or an owner checklist for feel (AGENTS.md Rule 1).
- `.gml` files are plain text and safe to edit directly with normal tools.
  `.yyp`/`.yy`/`.resource_order` files are IDE-owned — never hand-edit them
  to add, rename, or delete a resource (AGENTS.md Rule 4).
- **The gate** is `powershell -NoProfile -ExecutionPolicy Bypass -File
  tools/automation/run_tests.ps1 -Mode fast` (Igor headless build + tests);
  see AGENTS.md "The gate".
- Match the file's existing naming: `obj_`/`scr_`/`rm_` prefixes are
  consistent; sprites and sounds are not — follow the sibling assets in the
  same folder rather than inventing a prefix.
- Localization strings go through `datafiles/localization/game_text.xlsx` →
  `tools/localization/build_localization.py` → `localization.json`. Never
  hand-edit `localization.json`; never hardcode new player-facing English
  text without running `tools/localization/lint_hardcoded_text.py`.
- The README's tool commands use Windows `^` line continuations; on a Mac use `\`.
