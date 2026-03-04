# DD-Project
8bit turn based game

## Localization Workflow

Canonical source of truth is a single workbook:
- `datafiles/localization/game_text.xlsx` (sheet: `strings`)

Build/runtime artifact:
- `datafiles/localization/localization.json`

Generate or refresh the workbook from current scoped text sources:

```bash
python tools/localization/bootstrap_catalog.py --xlsx datafiles/localization/game_text.xlsx
```

Validate workbook + build runtime JSON:

```bash
python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json
```

Autofill blank Korean cells using OpenAI (draft pass only, requires review):

```bash
python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json --autofill-ko --model gpt-4.1-mini
```

Lint for newly introduced hardcoded player-facing English text in scoped files:

```bash
python tools/localization/lint_hardcoded_text.py
```

Runtime notes:
- Localization API is implemented in `scripts/scr_localization/scr_localization.gml`.
- Missing translation fallback chain is: selected language -> English -> provided fallback.
- Language setting is persisted in `settings_config.json` (`language`: `en` or `ko`).
