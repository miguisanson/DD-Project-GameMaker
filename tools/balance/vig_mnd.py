#!/usr/bin/env python3
"""D176 / D177 / D184: VIG and MND, the reference of the numbers (the GML in scr_stats / scr_levelup restates it; scr_test pins values from the table this prints).

Max HP and Max MP are stats now, like Elden Ring's Vigor and Mind. Every character starts at VIG 10 (Max HP 10); MND starts by class (Knight 11, Archer 12, Mage 16,
Nobody 11: the Max MP the class had at level 1). A point of VIG is worth 3 Max HP, then 2, then 1 (soft caps); a point of MND is 1 Max MP, then 1/2, then 1/4.
Class growth lists VIG and MND next to the other stats. The curves are tuned so that, with the level's free point on the class's usual stat, every class's Max HP / Max MP
at every level 1..10 stays within about 10% of what the old silent per-level growth gave (Resource_MaxHp / Resource_MaxMp, kept as the reference).

  python tools/balance/vig_mnd.py                  print the old-vs-new table (markdown)
  python tools/balance/vig_mnd.py --write PATH     write it to PATH
  python tools/balance/vig_mnd.py --check          exit 1 when a class leaves the +-10% band (or Mage is not the most fragile)
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

VIG_START = 10
MND_START = {"knight": 11, "archer": 12, "mage": 16, "nobody": 11}
MND_BASE = 10
HP_BASE = 10
MP_BASE = 10
# (points in the band, value of each point); the last band has no end
HP_BANDS = [(18, 3.0), (10, 2.0), (None, 1.0)]    # VIG 10..28 -> 3 HP, 28..38 -> 2 HP, beyond -> 1 HP
MP_BANDS = [(34, 1.0), (12, 0.5), (None, 0.25)]   # MND 10..44 -> 1 MP, 44..56 -> 1/2 MP, beyond -> 1/4 MP
HD = {"knight": 10, "archer": 8, "mage": 6, "nobody": 8}
MP_GAIN = {"knight": 1, "archer": 2, "mage": 2, "nobody": 1}
MAG_START = {"knight": 3, "archer": 4, "mage": 12, "nobody": 3}
MAG_GROWTH = {"knight": lambda lv: 0, "archer": lambda lv: 0, "mage": lambda lv: 2,
              "nobody": lambda lv: ((1 if (lv - 2) % 4 == 3 else 0) + (1 if (lv - 2 + 2) % 4 == 3 else 0))}
FREE_STAT_MAG = {"mage": 1}   # the class whose usual free point lands on MAG
LEVEL_CAP = 10


def banded(points, bands):
    total = 0.0
    left = max(0, points)
    for size, value in bands:
        take = left if size is None else min(left, size)
        total += take * value
        left -= take
        if left <= 0:
            break
    return total


def max_hp(vig):
    return HP_BASE + int(math.floor(banded(vig - VIG_START, HP_BANDS) + 1e-9))


def max_mp(mnd):
    return MP_BASE + int(math.floor(banded(mnd - MND_BASE, MP_BANDS) + 1e-9))


def growth(cls, lv):
    """VIG and MND gained on reaching level lv (>= 2)."""
    if cls == "knight":
        return (3 if (lv - 2) % 3 == 2 else 2), 1
    if cls == "archer":
        return 2, 2
    if cls == "mage":
        return (2 if lv % 2 == 0 else 1), 3
    return 2, 1 + (1 if (lv - 2) % 4 == 3 else 0)


def vig_at(cls, lv, extra=0):
    v = VIG_START + extra
    for k in range(2, lv + 1):
        v += growth(cls, k)[0]
    return v


def mnd_at(cls, lv, extra=0):
    m = MND_START[cls] + extra
    for k in range(2, lv + 1):
        m += growth(cls, k)[1]
    return m


def old_hp(cls, lv):
    import check_combat_vectors as ref   # here, not at the top: that script imports this one
    return ref.hp_max(HD[cls], lv)


def old_mp(cls, lv):
    mag = MAG_START[cls] + sum(MAG_GROWTH[cls](k) for k in range(2, lv + 1)) + FREE_STAT_MAG.get(cls, 0) * (lv - 1)
    import check_combat_vectors as ref
    return ref.mp_max(MP_GAIN[cls], lv, mag)


def new_hp(cls, lv, extra=0):
    return max_hp(vig_at(cls, lv, extra))


def new_mp(cls, lv, extra=0):
    return max_mp(mnd_at(cls, lv, extra))


def table():
    out = ["# VIG / MND: old vs new Max HP and Max MP (D176, D177, D184)", "",
           "Old = the silent per-level growth (Resource_MaxHp / Resource_MaxMp), the free point on the class's usual stat (Knight DEF, Archer ATK, Mage MAG, Nobody ATK).",
           "New = Max HP from VIG, Max MP from MND, the free point on a stat other than VIG / MND. Percent = new against old.", "",
           "Curves: HP = 10 + 3 per VIG point above 10 up to VIG 28, then 2 per point up to VIG 38, then 1. MP = 10 + 1 per MND point above 10 up to MND 44, then 1/2 up to 56, then 1/4 (floored).",
           "Start: VIG 10 for every class; MND Knight 11, Archer 12, Mage 16, Nobody 11.", "",
           "Growth on reaching a level (besides the ATK / DEF / SPD / MAG growth that did not change):", "",
           "| Class | VIG | MND |", "|---|---|---|",
           "| Knight | +2, +2, +3 repeating (levels 2,3 / 4 / ...: +3 on levels 4, 7, 10) | +1 |",
           "| Archer | +2 | +2 |",
           "| Mage | +2 on even levels, +1 on odd | +3 |",
           "| Nobody | +2 | +1, +2 on levels 5 and 9 |", ""]
    for cls in ("knight", "archer", "mage", "nobody"):
        out.append("## %s" % cls.capitalize())
        out.append("")
        out.append("| Level | VIG | MND | HP old | HP new | HP % | MP old | MP new | MP % |")
        out.append("|---|---|---|---|---|---|---|---|---|")
        for lv in range(1, LEVEL_CAP + 1):
            oh, nh, om, nm = old_hp(cls, lv), new_hp(cls, lv), old_mp(cls, lv), new_mp(cls, lv)
            out.append("| %d | %d | %d | %d | %d | %+.0f%% | %d | %d | %+.0f%% |" % (lv, vig_at(cls, lv), mnd_at(cls, lv), oh, nh, (nh / oh - 1) * 100, om, nm, (nm / om - 1) * 100))
        out.append("")
    out.append("## Every free point into VIG (or MND): is it easy mode?")
    out.append("")
    out.append("One free point a level (levels 2..10) all on VIG; compared with the same class with the points elsewhere, and with the OLD 'free point = +3 Max HP' (Max HP +3 each).")
    out.append("")
    out.append("| Class | HP at 10, points elsewhere | HP at 10, all on VIG | gain | gain in the old system (+3 a point) | MP at 10, all on MND | MP gain |")
    out.append("|---|---|---|---|---|---|---|")
    for cls in ("knight", "archer", "mage", "nobody"):
        a, b = new_hp(cls, 10), new_hp(cls, 10, extra=9)
        m0, m1 = new_mp(cls, 10), new_mp(cls, 10, extra=9)
        out.append("| %s | %d | %d | +%d (+%.0f%%) | +27 | %d | +%d |" % (cls.capitalize(), a, b, b - a, (b / a - 1) * 100, m1, m1 - m0))
    out.append("")
    return "\n".join(out)


def check():
    bad = []
    for cls in ("knight", "archer", "mage", "nobody"):
        for lv in range(1, LEVEL_CAP + 1):
            for what, o, n in (("HP", old_hp(cls, lv), new_hp(cls, lv)), ("MP", old_mp(cls, lv), new_mp(cls, lv))):
                if abs(n / o - 1) > 0.105:
                    bad.append("%s L%d %s old %d new %d" % (cls, lv, what, o, n))
    for lv in range(2, LEVEL_CAP + 1):
        if not (new_hp("mage", lv) <= min(new_hp(c, lv) for c in ("knight", "archer", "nobody"))):
            bad.append("mage is not the most fragile at level %d" % lv)
    return bad


if __name__ == "__main__":
    if "--check" in sys.argv:
        problems = check()
        for p in problems:
            print(p)
        sys.exit(1 if problems else 0)
    text = table()
    if "--write" in sys.argv:
        path = sys.argv[sys.argv.index("--write") + 1]
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(text + "\n")
    else:
        print(text)
