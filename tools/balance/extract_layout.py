#!/usr/bin/env python3
"""Reads rooms/rm_floor*/rm_floor*.yy (read only) and writes tools/balance/layout.json: what each floor holds, for the run simulator.

  python tools/balance/extract_layout.py            write layout.json
  python tools/balance/extract_layout.py --check    exit 1 when layout.json no longer matches the rooms

Per floor: the authored enemies (the simulator re-rolls the free ones from the floor pool like Shuffle_ApplyRoom does, and leaves bosses and the
Stranger as authored), chests and barrels with their container level, skill/class chests (card picks), beds. Merchants come from the economy
constants of the export (floors 2, 5, 8).
"""
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "layout.json")
FIXED = {"obj_mini_boss": "palehorn", "obj_final_boss": "choirbeast", "obj_stranger": "stranger"}
FREE = {"obj_slime": "slime", "obj_dire_wolf": "dire_wolf", "obj_spider": "spider", "obj_snake": "snake", "obj_killer_plant": "killer_plant",
        "obj_ghost_sword": "ghost_sword", "obj_mad_whisp": "mad_whisp"}
CONTAINER = {"obj_chest_lv1": ("chest", 1), "obj_chest_lv2": ("chest", 2), "obj_chest_lv3": ("chest", 3),
             "obj_barrel_lv1": ("barrel", 1), "obj_barrel_lv2": ("barrel", 2), "obj_barrel_lv3": ("barrel", 3),
             "obj_chest": ("chest", 1), "obj_barrel": ("barrel", 1)}


def build():
    floors = {}
    base = os.path.join(ROOT, "rooms")
    for name in sorted(os.listdir(base)):
        m = re.fullmatch(r"rm_floor(\d+)(?:_(\d+))?", name)
        if not m:
            continue
        floor = int(m.group(1)) + (0.5 if m.group(2) else 0)
        with open(os.path.join(base, name, name + ".yy"), encoding="utf-8") as f:
            text = f.read()
        objs = re.findall(r'"objectId":\{"name":"(obj_[a-z_0-9]+)"', text)
        rec = {"floor": floor, "enemies_free": [], "enemies_fixed": [], "chests": [], "barrels": [], "card_chests": 0, "class_chests": 0, "beds": 0}
        for o in objs:
            if o in FIXED:
                rec["enemies_fixed"].append(FIXED[o])
            elif o in FREE:
                rec["enemies_free"].append(FREE[o])
            elif o in CONTAINER:
                kind, lvl = CONTAINER[o]
                rec["chests" if kind == "chest" else "barrels"].append(lvl)
            elif o == "obj_chest_skillbook":
                rec["card_chests"] += 1
            elif o == "obj_chest_class_select":
                rec["class_chests"] += 1
            elif o == "obj_bed":
                rec["beds"] += 1
        floors[str(floor)] = rec
    return {"generated_from": "rooms/rm_floor*/*.yy", "floors": floors}


def main(argv):
    data = build()
    text = json.dumps(data, indent=1, sort_keys=True) + "\n"
    if "--check" in argv:
        with open(OUT, encoding="utf-8") as f:
            ok = f.read() == text
        print("layout.json OK" if ok else "layout.json is stale: run extract_layout.py")
        return 0 if ok else 1
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote", OUT)
    for k, v in data["floors"].items():
        print(k, "free", len(v["enemies_free"]), "fixed", v["enemies_fixed"], "chests", v["chests"], "barrels", v["barrels"], "cards", v["card_chests"], "class", v["class_chests"], "beds", v["beds"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
