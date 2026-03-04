#!/usr/bin/env python3
"""Lint for new hardcoded player-facing English literals in scoped GML files."""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable, List, Tuple

STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')

DEFAULT_PATHS = [
    "scripts/scr_menu/scr_menu.gml",
    "scripts/scr_save_menu/scr_save_menu.gml",
    "scripts/scr_combat/scr_combat.gml",
    "scripts/scr_dialogue/scr_dialogue.gml",
    "scripts/scr_db_item/scr_db_item.gml",
    "scripts/scr_db_skill/scr_db_skill.gml",
    "scripts/scr_db_enemy/scr_db_enemy.gml",
    "scripts/scr_status/scr_status.gml",
    "scripts/scr_db_player_class/scr_db_player_class.gml",
    "scripts/scr_interact/scr_interact.gml",
    "objects/obj_start_controller/Create_0.gml",
    "objects/obj_start_controller/Step_0.gml",
    "objects/obj_start_controller/Draw_64.gml",
    "objects/obj_battle_controller/Create_0.gml",
    "objects/obj_battle_controller/Step_0.gml",
    "objects/obj_battle_controller/Draw_64.gml",
    "objects/obj_grave/Create_0.gml",
]

ALLOW_EXACT = {
    "",
    "menu_up",
    "menu_down",
    "menu_left",
    "menu_right",
    "confirm",
    "interact",
    "cancel",
    "ui_move",
    "ui_confirm",
    "ui_back",
    "ui_openclose",
    "smoothstep",
    "linear",
    "default",
    "main",
    "cutscene",
    "difficulty",
    "settings",
    "load",
    "save",
    "bed",
    "delete",
    "overwrite",
    "saved",
    "message",
    "title",
    "intro",
    "ending",
    "game_over",
    "normal",
    "slow",
    "Background",
    "Instances",
    "STR",
    "AGI",
    "DEF",
    "INT",
    "LUCK",
    "N/A",
    "HP",
    "MP",
    "MAX",
    "Ag",
    "E",
    "+",
    "-",
    ">",
}

ALLOW_PREFIX = (
    "ui_",
    "menu_",
    "skillbook_",
    "enemy_skill_",
    "dialogue_",
    "interact.name.",
)

SKIP_LINE_TOKENS = (
    "variable_struct_exists",
    "variable_instance_exists",
    "SFX_Play",
    "Input_",
    "Transition_",
    "UI_ModalRoot",
    "asset_get_index",
    "show_debug_message",
    "SaveMenu_Log(",
    "sfx_key:",
    "sfx_candidates:",
    "fx_sprite:",
)

SKIP_FUNCTIONS_BY_FILE = {
    "scripts/scr_dialogue/scr_dialogue.gml": {"DialogueDB_Init"},
    "scripts/scr_db_item/scr_db_item.gml": {"ItemDB_Init", "ItemDB_GetPassiveTemplate"},
    "scripts/scr_db_skill/scr_db_skill.gml": {"SkillDB_Init"},
    "scripts/scr_db_enemy/scr_db_enemy.gml": {"EnemyDB_Init"},
    "scripts/scr_status/scr_status.gml": {"StatusDB_Init"},
}

SKIP_RANGES_BY_FILE = {
    "objects/obj_start_controller/Create_0.gml": (
        "cutscene_definitions = {}",
        "var __localize_cutscene = function",
    ),
}


def decode(raw: str) -> str:
    return (
        raw.replace(r"\\", "\\")
        .replace(r"\"", '"')
        .replace(r"\n", "\n")
        .replace(r"\r", "\r")
        .replace(r"\t", "\t")
    )


def iter_literals(line: str) -> Iterable[str]:
    for m in STRING_RE.finditer(line):
        yield decode(m.group(1))


def looks_player_facing(text: str) -> bool:
    if text in ALLOW_EXACT:
        return False
    if text.startswith(ALLOW_PREFIX):
        return False
    if re.fullmatch(r"[a-z][a-z0-9_]*(\.[a-z0-9_]+)+", text):
        return False
    if re.fullmatch(r"[A-Za-z0-9_]+", text) and "_" in text:
        return False
    if re.fullmatch(r"[a-z0-9_]+", text):
        return False
    if not re.search(r"[A-Za-z]", text):
        return False
    if len(text) <= 1:
        return False
    return True


def lint_file(path: Path, root: Path) -> List[Tuple[int, str]]:
    findings: List[Tuple[int, str]] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    rel_path = path.relative_to(root).as_posix()

    skip_funcs = SKIP_FUNCTIONS_BY_FILE.get(rel_path, set())
    skip_range_markers = SKIP_RANGES_BY_FILE.get(rel_path)
    in_skip_range = False
    in_skip_func = False
    skip_func_depth = 0

    for lineno, line in enumerate(lines, start=1):
        if skip_range_markers:
            start_marker, end_marker = skip_range_markers
            if in_skip_range:
                if end_marker in line:
                    in_skip_range = False
                continue
            elif start_marker in line:
                in_skip_range = True
                continue

        stripped = line.strip()
        if in_skip_func:
            skip_func_depth += line.count("{") - line.count("}")
            if skip_func_depth <= 0:
                in_skip_func = False
            continue

        if skip_funcs:
            for fn_name in skip_funcs:
                if stripped.startswith(f"function {fn_name}("):
                    in_skip_func = True
                    skip_func_depth = line.count("{") - line.count("}")
                    if skip_func_depth <= 0:
                        in_skip_func = False
                    break
            if in_skip_func:
                continue

        if "Loc_T(" in line:
            continue
        if any(tok in line for tok in SKIP_LINE_TOKENS):
            continue

        for text in iter_literals(line):
            if looks_player_facing(text):
                findings.append((lineno, text))

    return findings


def main() -> None:
    parser = argparse.ArgumentParser(description="Lint for hardcoded player-facing English literals.")
    parser.add_argument("--paths", nargs="*", default=DEFAULT_PATHS, help="Files to scan")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    findings_total: List[Tuple[Path, int, str]] = []

    for rel in args.paths:
        path = root / rel
        if not path.exists():
            continue
        findings = lint_file(path, root)
        for lineno, text in findings:
            findings_total.append((path, lineno, text))

    if findings_total:
        print("Potential hardcoded player-facing literals found:")
        for path, lineno, text in findings_total:
            print(f"- {path.relative_to(root).as_posix()}:{lineno}: \"{text}\"")
        raise SystemExit(1)

    print("No hardcoded player-facing literals detected in scoped files.")


if __name__ == "__main__":
    main()
