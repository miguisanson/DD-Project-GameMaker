"""Generate the sound gain table (asset name -> dB) between the marker comments in scripts/scr_sfx/scr_sfx.gml.

Input: tools/audio/loudness.json (from measure_loudness.py) and gain_config.py (targets, groups, exceptions).
Run with --check to fail (exit 1) when the file on disk differs from what this would write.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gain_config as cfg  # noqa: E402

BEGIN = "// ==== BEGIN GENERATED SFX GAIN TABLE (tools/audio/write_gain_table.py, R-119: do not hand-edit) ===="
END = "// ==== END GENERATED SFX GAIN TABLE ===="


def build_block(loud):
    lines = [BEGIN,
             "// sound asset name -> gain in dB; the play path multiplies it with the bus / settings volume. Comment: file level (LUFS, peak dBFS) and the group target.",
             "function SFX_BuildGainTable() {",
             "    var _t = {};"]
    for name in sorted(loud):
        m = loud[name]
        db = cfg.desired_gain_db(name, m)
        lines.append('    variable_struct_set(_t, "%s", %s);   // %s %.1f LUFS pk %.1f -> %s %.0f' % (
            name, ("%.1f" % db), cfg.group_of(name), m["judged_lufs"], m["sample_peak_dbfs"], "target", cfg.target_of(name) + cfg.OFFSETS.get(name, (0.0, ""))[0]))
    lines += ["    return _t;", "}", END]
    return "\n".join(lines)


def apply(text, block):
    if BEGIN in text and END in text:
        a = text.index(BEGIN)
        b = text.index(END) + len(END)
        return text[:a] + block + text[b:]
    raise SystemExit("markers not found in the GML file")


def main(argv=None):
    ap = argparse.ArgumentParser()
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    ap.add_argument("--root", default=root)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args(argv)
    path = os.path.join(args.root, "scripts", "scr_sfx", "scr_sfx.gml")
    with open(path, encoding="utf-8", newline="") as fh:
        text = fh.read()
    crlf = "\r\n" in text
    work = text.replace("\r\n", "\n")
    new = apply(work, build_block(cfg.load_loudness(args.root)))
    if crlf:
        new = new.replace("\n", "\r\n")
    if args.check:
        if new != text:
            print("gain table is out of date: run tools/audio/write_gain_table.py")
            return 1
        print("gain table up to date")
        return 0
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(new)
    print("gain table written to", path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
