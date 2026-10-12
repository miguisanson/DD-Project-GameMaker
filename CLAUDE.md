# Claude Code — project notes

**Read [`AGENTS.md`](AGENTS.md) first.** It holds the rules every agent
follows (check first, targeted checks, scope, resource ownership, the gate)
and how work is split between Claude, Codex and the local model. Do not
restate them here.

- **There is no separate design doc or roadmap file.** `README.md` documents
  the localization workflow; `.planning/STATE.md` (GSD Core) is the working
  plan and session handoff, and is the single source of truth for where work
  stands.
- **Domain skills** — load before the matching work, per the AGENTS.md
  "domain craft" row: `game-ui-ux` for HUDs/menus/overlays, `game-feel` for
  hit/jump/pickup/death feedback, `save-systems` for `scr_save`/
  `scr_save_menu`, `audio-design` for `scr_sfx` and sound-bus work,
  `create-game-assets` for new sprite/tile/UI art.

Commands: `/continue_DD-Project-GameMaker` (start any session with it).

## Claude-specific conventions

- No automated test runner exists. Follow AGENTS.md Rule 1's table for what
  counts as "the check" for a given kind of change (a GML assertion block
  run from a debug entry point, a written acceptance checklist walked
  through in the IDE, or a Python check for `tools/localization/`).
- `.gml` files are plain text and safe to edit directly with normal tools.
  `.yyp`/`.yy`/`.resource_order` files are IDE-owned — never hand-edit them
  to add, rename, or delete a resource (AGENTS.md Rule 4).
- No headless build (Igor) is available on this machine right now — the
  gate's build-verification step is the owner (or a remote-controlled IDE
  session) opening the project in GameMaker and confirming no compile or
  runtime errors, not a CLI command.
- Match the file's existing naming: `obj_`/`scr_`/`rm_` prefixes are
  consistent; sprites and sounds are not — follow the sibling assets in the
  same folder rather than inventing a prefix.
- Localization strings go through `datafiles/localization/game_text.xlsx` →
  `tools/localization/build_localization.py` → `localization.json`. Never
  hand-edit `localization.json`; never hardcode new player-facing English
  text without running `tools/localization/lint_hardcoded_text.py`.
- The README's tool commands use Windows `^` line continuations; on a Mac use `\`.
