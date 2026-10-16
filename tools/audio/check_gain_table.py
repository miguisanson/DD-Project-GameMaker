"""Check the gain table in scripts/scr_sfx/scr_sfx.gml against tools/audio/loudness.json (R-119).

Passes when, for every measured sound, the level after the table gain is within +-3 dB of its group target
(gain_config.TARGETS, plus a deliberate offset listed in gain_config.OFFSETS) and the sample peak after the
gain is at or below -1 dBFS. Prints the loudest-quietest spread of the sounds the game plays, before
(file levels with the old per-key trims) and after the table. Exit 1 on any failure.
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gain_config as cfg  # noqa: E402

ROW = re.compile(r'variable_struct_set\(_t, "([^"]+)", (-?[0-9.]+)\);')


def parse_table(gml_text):
    a = gml_text.find("BEGIN GENERATED SFX GAIN TABLE")
    b = gml_text.find("END GENERATED SFX GAIN TABLE")
    if a < 0 or b < 0:
        return None
    return {n: float(v) for n, v in ROW.findall(gml_text[a:b])}


def evaluate(loud, table):
    """Return (failures, rows) where rows hold name, group, before, after, peak_after."""
    fails, rows = [], []
    for name, m in sorted(loud.items()):
        if name not in table:
            fails.append("%s: missing from the table" % name)
            continue
        g = table[name]
        after = m["judged_lufs"] + g
        peak = m["sample_peak_dbfs"] + g
        want = cfg.target_of(name) + cfg.OFFSETS.get(name, (0.0, ""))[0]
        if abs(after - want) > cfg.TOLERANCE_DB:
            fails.append("%s: %.1f LUFS after the table, target %.1f (+-%.0f)" % (name, after, want, cfg.TOLERANCE_DB))
        if peak > cfg.PEAK_CEILING_DBFS + 1e-9:
            fails.append("%s: peak %.1f dBFS after the table, ceiling %.1f" % (name, peak, cfg.PEAK_CEILING_DBFS))
        rows.append({"name": name, "group": cfg.group_of(name), "before": m["judged_lufs"] + cfg.legacy_trim_db(name),
                     "after": after, "peak_after": peak})
    return fails, rows


def spread(rows, key):
    vals = [r[key] for r in rows]
    return max(vals) - min(vals)


def main(argv=None):
    ap = argparse.ArgumentParser()
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    ap.add_argument("--root", default=root)
    args = ap.parse_args(argv)
    loud = cfg.load_loudness(args.root)
    with open(os.path.join(args.root, "scripts", "scr_sfx", "scr_sfx.gml"), encoding="utf-8") as fh:
        table = parse_table(fh.read())
    if table is None:
        print("FAIL: no generated gain table in scr_sfx.gml")
        return 1
    fails, rows = evaluate(loud, table)
    for f in fails:
        print("FAIL:", f)
    used = cfg.used_sound_names(args.root, loud.keys())
    urows = [r for r in rows if r["name"] in used]
    for label, subset in (("all %d sounds" % len(rows), rows), ("%d sounds the game plays" % len(urows), urows)):
        if not subset:
            continue
        print("%s: before %.1f dB spread (%.1f .. %.1f), after %.1f dB spread (%.1f .. %.1f)" % (
            label, spread(subset, "before"), min(r["before"] for r in subset), max(r["before"] for r in subset),
            spread(subset, "after"), min(r["after"] for r in subset), max(r["after"] for r in subset)))
    for grp in ("sfx", "ui", "music", "ambience"):
        sub = [r for r in urows if r["group"] == grp]
        if sub:
            print("  %-8s played: before %.1f dB, after %.1f dB (%d sounds)" % (grp, spread(sub, "before"), spread(sub, "after"), len(sub)))
    if rows:
        print("highest peak after the table: %.1f dBFS (%s)" % (max(r["peak_after"] for r in rows), max(rows, key=lambda r: r["peak_after"])["name"]))
    print("GAIN-TABLE CHECK %s" % ("FAIL" if fails else "PASS"))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
