# DD-Project
8bit turn based game

## Localization Workflow

Canonical source of truth is a single workbook:
- `datafiles/localization/game_text.xlsx` (sheet: `strings`)

Canonical minimal columns (new):
- `ref` (human-facing reference, also runtime key by default)
- `en`
- `ko`

Legacy schema is still supported by tooling for compatibility.

Build/runtime artifact:
- `datafiles/localization/localization.json`

Migrate legacy workbook -> minimal workbook (safe one-time conversion with mapping/report):

```bash
python tools/localization/migrate_legacy_sheet.py ^
  --input-xlsx datafiles/localization/game_text.xlsx ^
  --output-xlsx datafiles/localization/game_text.xlsx ^
  --backup-xlsx datafiles/localization/game_text.legacy.xlsx ^
  --mapping-csv datafiles/localization/migration_map.csv ^
  --report-json datafiles/localization/migration_report.json
```

Generate or refresh the workbook from current scoped text sources:

```bash
python tools/localization/bootstrap_catalog.py --xlsx datafiles/localization/game_text.xlsx --schema minimal
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
