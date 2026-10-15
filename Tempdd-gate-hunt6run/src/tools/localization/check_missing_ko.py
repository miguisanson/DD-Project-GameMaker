#!/usr/bin/env python3
"""Fail (exit 1) when a localization row has no real Korean translation (D9: "a check flags missing translations").

A row is flagged when:
  - ko is empty;
  - ko is the same as en and the row is not allowed;
  - ko has no Hangul at all, still contains words (letters outside {placeholders}) and the row is not allowed.

Allowed (never flagged): refs listed in ko_allowlist.txt (proper nouns such as "NO HOPE"), and rows whose text
is only placeholders, punctuation, digits, or the Latin tokens listed as "token: XYZ" in ko_allowlist.txt
(HP, MP, ATK ... are written in Latin letters in the Korean text too, see .planning/research/ko-glossary.md).

Usage:
  python tools/localization/check_missing_ko.py [--xlsx datafiles/localization/game_text.xlsx] [--allowlist PATH]
  python tools/localization/check_missing_ko.py --selftest
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, Iterable, List, Set, Tuple

SHEET = "strings"
HANGUL_RE = re.compile(r"[가-힣ㄱ-ㆎ]")
PLACEHOLDER_RE = re.compile(r"\{[A-Za-z0-9_]+\}")
WORD_RE = re.compile(r"[A-Za-z]+")


def load_allowlist(path: Path) -> Tuple[Set[str], Set[str]]:
    refs: Set[str] = set()
    tokens: Set[str] = set()
    if not path.exists():
        return refs, tokens
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if line.lower().startswith("token:"):
            for tok in line.split(":", 1)[1].replace(",", " ").split():
                tokens.add(tok)
        else:
            refs.add(line)
    return refs, tokens


def only_allowed_words(text: str, tokens: Set[str]) -> bool:
    """True when every Latin word in text (outside {placeholders}) is an allowed token."""
    stripped = PLACEHOLDER_RE.sub(" ", text)
    return all(w in tokens for w in WORD_RE.findall(stripped))


def check_rows(rows: Iterable[Tuple[str, str, str]], refs: Set[str], tokens: Set[str]) -> List[Tuple[str, str, str]]:
    """rows = (ref, en, ko). Returns [(ref, reason, ko)] for every row that is not translated."""
    bad: List[Tuple[str, str, str]] = []
    for ref, en, ko in rows:
        ref = (ref or "").strip()
        en = (en or "").strip()
        ko = (ko or "").strip()
        if not ref or not en:
            continue
        if not ko:
            bad.append((ref, "ko is empty", ko))
            continue
        if ref in refs:
            continue
        if only_allowed_words(en, tokens):
            continue
        if ko == en:
            bad.append((ref, "ko is the same as en", ko))
        elif not HANGUL_RE.search(ko) and WORD_RE.search(PLACEHOLDER_RE.sub(" ", ko)):
            bad.append((ref, "ko has no Hangul", ko))
    return bad


def read_workbook(xlsx: Path) -> List[Tuple[str, str, str]]:
    from openpyxl import load_workbook

    wb = load_workbook(xlsx, read_only=True, data_only=True)
    ws = wb[SHEET]
    it = ws.iter_rows(values_only=True)
    header = [str(c).strip().lower() if c is not None else "" for c in next(it)]
    ci = {name: header.index(name) for name in ("ref", "en", "ko")}
    rows = []
    for r in it:
        rows.append(tuple("" if r[ci[n]] is None else str(r[ci[n]]) for n in ("ref", "en", "ko")))
    return rows


def selftest() -> int:
    refs, tokens = {"credits.title"}, {"HP", "MP"}
    rows = [
        ("a.empty", "Hello", ""),
        ("a.same", "Hello", "Hello"),
        ("a.nohangul", "Hello", "Hullo"),
        ("a.ok", "Hello", "안녕"),
        ("credits.title", "NO HOPE", "NO HOPE"),
        ("a.stat", "{n} HP", "{n} HP"),
        ("a.dots", "...", "..."),
        ("a.ph", "{enemy}: {msg}", "{enemy}: {msg}"),
    ]
    got = {r for r, _, _ in check_rows(rows, refs, tokens)}
    want = {"a.empty", "a.same", "a.nohangul"}
    if got != want:
        print(f"selftest FAIL: got {sorted(got)} want {sorted(want)}")
        return 1
    print("selftest ok")
    return 0


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--xlsx", default=str(root / "datafiles/localization/game_text.xlsx"))
    ap.add_argument("--allowlist", default=str(root / "tools/localization/ko_allowlist.txt"))
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()
    if args.selftest:
        return selftest()
    refs, tokens = load_allowlist(Path(args.allowlist))
    rows = read_workbook(Path(args.xlsx))
    bad = check_rows(rows, refs, tokens)
    for ref, reason, ko in bad:
        print(f"MISSING KO  {ref}: {reason}" + (f" -> {ko!r}" if ko else ""))
    print(f"check_missing_ko: {len(rows)} rows, {len(bad)} missing")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
