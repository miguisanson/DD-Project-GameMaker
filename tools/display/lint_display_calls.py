#!/usr/bin/env python
"""Source guard for DISP-02 / DISP-09 (display-design.md section 3.1, step B3).

scripts/scr_display/ and objects/obj_display/ are the ONLY code allowed to call the window, surface, GUI-size, view and camera-size
functions below, and nobody may read display_get_gui_width/height (display_set_gui_maximise makes the engine report window / scale,
not the UI grid): UI code uses Display_GuiW() / Display_GuiH().

Usage:  python tools/display/lint_display_calls.py [--root DIR] [--plant]
  exit 0 = clean, exit 1 = violations (printed as path:line: text).
  --plant  adds a synthetic file with one forbidden call; the run must then fail (the gate's negative control uses it).
Camera POSITION writes (follow, cinematic, shake) stay with gameplay code and are not checked here.
"""
import argparse
import os
import re
import sys

# Calls only the display owner may make.
OWNER_ONLY = [
    r"window_set_size", r"window_set_position", r"window_center", r"window_set_fullscreen", r"window_set_showborder",
    r"window_set_colour", r"window_set_color", r"window_set_rectangle", r"window_enable_borderless_fullscreen",
    r"surface_resize\s*\(\s*application_surface", r"application_surface_draw_enable", r"application_surface_enable",
    r"display_set_gui_size", r"display_set_gui_maximise", r"display_reset",
    r"camera_set_view_size", r"camera_set_view_border", r"gpu_set_texfilter",
]
OWNER_RE = re.compile(r"\b(?:" + "|".join(OWNER_ONLY) + r")")
# Assignments to the view arrays (view_enabled, view_visible[i], view_xport[i] ... view_hport[i]); reads are fine.
VIEW_WRITE_RE = re.compile(r"\bview_(?:enabled|visible\s*\[[^\]]*\]|[xywh]port\s*\[[^\]]*\])\s*=(?!=)")
# Nobody reads the engine's GUI size.
GUI_READ_RE = re.compile(r"\bdisplay_get_gui_(?:width|height)\b")

ALLOWED_DIRS = ("scripts/scr_display/", "objects/obj_display/")


def strip_comment(line):
    """Drop a // comment (outside of string literals)."""
    out, in_str, i = [], False, 0
    while i < len(line):
        c = line[i]
        if c == '"':
            in_str = not in_str
        if not in_str and line.startswith("//", i):
            break
        out.append(c)
        i += 1
    return "".join(out)


def scan_text(text, rel, allowed):
    problems = []
    in_block = False
    for n, raw in enumerate(text.splitlines(), 1):
        line = raw
        if in_block:
            if "*/" in line:
                line = line.split("*/", 1)[1]
                in_block = False
            else:
                continue
        while "/*" in line:
            head, tail = line.split("/*", 1)
            if "*/" in tail:
                line = head + tail.split("*/", 1)[1]
            else:
                line = head
                in_block = True
        code = strip_comment(line)
        if allowed:
            continue   # scr_display / obj_display: the owner may call anything, incl. display_get_gui_* (Display_GuiStateStale)
        if GUI_READ_RE.search(code):
            problems.append((rel, n, "display_get_gui_* is forbidden: use Display_GuiW()/Display_GuiH()", raw.strip()))
        if OWNER_RE.search(code) or VIEW_WRITE_RE.search(code):
            problems.append((rel, n, "display-owner call outside scr_display: use Display_Request/Display_BindRoom/...", raw.strip()))
    return problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    ap.add_argument("--plant", action="store_true", help="add a synthetic violation (negative control)")
    args = ap.parse_args()
    root = os.path.abspath(args.root)

    problems = []
    for base in ("scripts", "objects", "rooms"):
        for dirpath, _dirs, files in os.walk(os.path.join(root, base)):
            for f in files:
                if not f.endswith(".gml"):
                    continue
                full = os.path.join(dirpath, f)
                rel = os.path.relpath(full, root).replace("\\", "/")
                allowed = rel.startswith(ALLOWED_DIRS)
                with open(full, encoding="utf-8", errors="replace") as fh:
                    problems += scan_text(fh.read(), rel, allowed)
    if args.plant:
        problems += scan_text("window_set_size(100, 100);\nvar w = display_get_gui_width();\n", "PLANTED/negative_control.gml", False)

    for rel, n, why, text in problems:
        print("%s:%d: %s\n    %s" % (rel, n, why, text))
    if problems:
        print("lint_display_calls: %d violation(s)" % len(problems))
        return 1
    print("lint_display_calls: clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
