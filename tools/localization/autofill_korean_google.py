#!/usr/bin/env python3
"""Autofill korean_ko cells in the localization workbook using Google Translate.

This is a draft-pass helper for localization; human review is still required.
"""

from __future__ import annotations

import argparse
import re
import time
from pathlib import Path
from typing import Dict, List, Tuple

from deep_translator import GoogleTranslator
from openpyxl import load_workbook

SHEET_NAME = "strings"
REQUIRED_COLUMNS = ("key", "english_en", "korean_ko", "status", "active", "context")
PLACEHOLDER_RE = re.compile(r"\{([A-Za-z0-9_]+)\}")


def norm_str(value: object) -> str:
    if value is None:
        return ""
    return str(value).strip()


def parse_active(value: object) -> int:
    s = norm_str(value)
    if s == "":
        return 1
    try:
        return 1 if int(float(s)) != 0 else 0
    except ValueError:
        return 0


def extract_placeholders(text: str) -> List[str]:
    out: List[str] = []
    for m in PLACEHOLDER_RE.finditer(text):
        p = "{" + m.group(1) + "}"
        if p not in out:
            out.append(p)
    return out


def protect_placeholders(text: str) -> Tuple[str, Dict[str, str]]:
    placeholders = extract_placeholders(text)
    protected = text
    token_map: Dict[str, str] = {}
    for i, ph in enumerate(placeholders):
        token = f"ZZPH{i}ZZ"
        token_map[token] = ph
        protected = protected.replace(ph, token)
    return protected, token_map


def restore_placeholders(text: str, token_map: Dict[str, str]) -> str:
    out = text
    for token, ph in token_map.items():
        out = out.replace(token, ph)
    return out


def build_row_text_for_translation(english: str, context: str) -> str:
    # Keep content-only translation to minimize artifacts.
    _ = context
    return english


def main() -> None:
    parser = argparse.ArgumentParser(description="Autofill korean_ko in game_text.xlsx using Google Translate.")
    parser.add_argument("--xlsx", required=True, help="Workbook path (for example datafiles/localization/game_text.xlsx)")
    parser.add_argument("--sleep-ms", type=int, default=120, help="Delay between requests to reduce throttling risk")
    parser.add_argument("--overwrite", action="store_true", help="Also overwrite non-empty korean_ko values")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    xlsx_path = (root / args.xlsx).resolve() if not Path(args.xlsx).is_absolute() else Path(args.xlsx).resolve()
    wb = load_workbook(xlsx_path)
    if SHEET_NAME not in wb.sheetnames:
        raise SystemExit(f"Missing sheet '{SHEET_NAME}' in {xlsx_path}")
    ws = wb[SHEET_NAME]

    headers: Dict[str, int] = {}
    for c in range(1, ws.max_column + 1):
        h = norm_str(ws.cell(row=1, column=c).value)
        if h:
            headers[h] = c

    missing = [c for c in REQUIRED_COLUMNS if c not in headers]
    if missing:
        raise SystemExit(f"Workbook missing required columns: {', '.join(missing)}")

    tr = GoogleTranslator(source="en", target="ko")

    updated = 0
    skipped = 0
    failed = 0

    for r in range(2, ws.max_row + 1):
        key = norm_str(ws.cell(r, headers["key"]).value)
        en = norm_str(ws.cell(r, headers["english_en"]).value)
        ko = norm_str(ws.cell(r, headers["korean_ko"]).value)
        context = norm_str(ws.cell(r, headers["context"]).value)
        status = norm_str(ws.cell(r, headers["status"]).value).lower() or "new"
        active = parse_active(ws.cell(r, headers["active"]).value)

        if key == "" and en == "":
            continue
        if active != 1:
            skipped += 1
            continue
        if en == "":
            skipped += 1
            continue
        if ko != "" and not args.overwrite:
            skipped += 1
            continue

        source = build_row_text_for_translation(en, context)
        protected, token_map = protect_placeholders(source)

        try:
            translated = tr.translate(protected)
            if translated is None:
                translated = ""
            translated = restore_placeholders(norm_str(translated), token_map)

            # Hard guard on placeholder parity.
            if extract_placeholders(translated) != extract_placeholders(en):
                failed += 1
                continue

            ws.cell(r, headers["korean_ko"]).value = translated
            if status in ("", "new"):
                ws.cell(r, headers["status"]).value = "autofilled"
            updated += 1
        except Exception:
            failed += 1

        if args.sleep_ms > 0:
            time.sleep(args.sleep_ms / 1000.0)

    wb.save(xlsx_path)
    print(f"Autofill finished for {xlsx_path}")
    print(f"updated={updated} skipped={skipped} failed={failed}")


if __name__ == "__main__":
    main()
