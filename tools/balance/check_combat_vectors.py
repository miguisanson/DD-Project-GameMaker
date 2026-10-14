#!/usr/bin/env python3
"""Reference implementation of .planning/research/combat-spec.md and the keeper of combat-vectors.json.

The expected numbers in combat-vectors.json come from THIS file (a re-statement of the spec), never from the game.
  python tools/balance/check_combat_vectors.py            verify: JSON == regenerated vectors, and scr_test.gml hard-codes every vector id + value
  python tools/balance/check_combat_vectors.py --write    regenerate the JSON from the reference
  python tools/balance/check_combat_vectors.py --gml      print the GML assertion lines (paste into Test_Suite_Stats / Test_Suite_Combat)
The Python simulator (BAL-02) imports `damage`, `class_state`, ... from here, so it cannot drift from the spec.
"""
import json
import math
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
VECTORS = os.path.join(ROOT, ".planning", "research", "combat-vectors.json")
TESTS = os.path.join(ROOT, "scripts", "scr_test", "scr_test.gml")
EPS = 0.000001
STAT_MAX = 60


def rhu(x):
    return math.floor(x + 0.5 + EPS)


def damage(power, a, d, grade=1.0, mult=1.0):
    """Spec section 4. grade 1.0 -> ok; otherwise moved at least 1 away from ok (D61)."""
    if power <= 0 or mult == 0:
        return 0
    raw = power * a * mult / (a + d)
    ok = max(1, rhu(raw))
    if grade == 1.0:
        return ok
    g = rhu(raw * grade)
    g = max(g, ok + 1) if grade > 1.0 else min(g, ok - 1)
    return max(1, g)


def power_basic(weapon_power):
    return 2.0 * weapon_power


def power_skill(skill_power, power_mult, weapon_power):
    return 2.0 * (skill_power + 0.5 * weapon_power) * power_mult


def power_enemy_skill(skill_power, power_mult):
    return 2.0 * skill_power * power_mult


def hp_max(hd, level):
    return 10 + (level - 1) * (math.ceil(hd / 2) + 2)


def mp_max(mp_gain, level, mag):
    return 10 + (level - 1) * mp_gain + mag // 2


CLASSES = {
    # name: base atk,def,spd,mag, hd, mp_gain, fixed growth fn(level) -> (atk,def,spd,mag), free-point default stat index (0 atk 1 def 2 spd 3 mag)
    "knight": dict(base=(11, 12, 8, 3), hd=10, mp_gain=1, fixed=lambda lv: (1, 1, 0, 0), free=1),
    "archer": dict(base=(9, 8, 13, 4), hd=8, mp_gain=2, fixed=lambda lv: (1, 0, 1, 0), free=0),
    "mage": dict(base=(5, 7, 10, 12), hd=6, mp_gain=2, fixed=lambda lv: (0, 0, 0, 2), free=3),
    "nobody": dict(base=(8, 8, 9, 3), hd=8, mp_gain=1,
                   fixed=lambda lv: [(1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1)][(lv - 2) % 4], free=0),
}


def class_state(cls, level):
    k = CLASSES[cls]
    s = list(k["base"])
    for lv in range(2, level + 1):
        g = k["fixed"](lv)
        for i in range(4):
            s[i] = min(STAT_MAX, s[i] + g[i])
        s[k["free"]] = min(STAT_MAX, s[k["free"]] + 1)
    return dict(atk=s[0], df=s[1], spd=s[2], mag=s[3], hp=hp_max(k["hd"], level), mp=mp_max(k["mp_gain"], level, s[3]))


EXP_NEXT = [12, 24, 40, 58, 80, 105, 135, 170, 210]

ENEMIES = {
    # name: atk, def, spd, mag, base_hp, hd, mp_gain
    "slime": (8, 7, 9, 5, 9, 7), "spider": (8, 7, 10, 5, 10, 7), "snake": (9, 7, 10, 5, 10, 7),
    "mad_whisp": (10, 9, 12, 13, 12, 6), "killer_plant": (12, 11, 9, 10, 14, 8), "dire_wolf": (11, 9, 11, 6, 12, 7),
    "ghost_sword": (14, 12, 12, 10, 15, 8), "stranger": (16, 14, 13, 15, 18, 8),
    "palehorn": (18, 16, 12, 14, 25, 10), "choirbeast": (21, 18, 14, 19, 34, 10),
}


def enemy_hp(name, level):
    e = ENEMIES[name]
    return e[4] + (level - 1) * (math.ceil(e[5] / 2) + 1)


def run_chance(spd_player, spd_enemy):
    return min(0.95, max(0.10, 0.5 + 0.05 * (spd_player - spd_enemy)))


def crit_chance(bonus):
    return min(0.5, max(0.0, bonus / 100.0))


def heal(power, a):
    return power + a // 4


def player_first(spd_player, spd_enemy):
    return spd_player >= spd_enemy


def build():
    v = {"version": 1, "spec": ".planning/research/combat-spec.md", "round_half_up_epsilon": EPS}
    dmg = [
        ("dmg_01", 6, 11, 7, 1.0, 1.0), ("dmg_02", 7, 5, 5, 1.0, 1.0), ("dmg_03", 1, 1, 60, 1.0, 1.0), ("dmg_04", 6, 11, 7, 1.30, 1.0),
        ("dmg_05", 6, 11, 7, 1.10, 1.0), ("dmg_06", 6, 11, 7, 0.75, 1.0), ("dmg_07", 1, 1, 60, 0.75, 1.0), ("dmg_08", 1, 1, 60, 1.30, 1.0),
        ("dmg_09", 6, 11, 7, 1.0, 0.0), ("dmg_10", 6, 11, 7, 1.0, 0.8), ("dmg_11", 6, 8, 7, 1.0, 0.25), ("dmg_12", 6, 11, 7, 1.0, 2.0),
        ("dmg_13", 19.5, 11, 7, 1.0, 1.0), ("dmg_14", 22, 29, 18, 1.0, 1.0), ("dmg_15", 0, 11, 7, 1.0, 1.0), ("dmg_16", 4, 8, 12, 1.0, 1.0),
        ("dmg_17", 12, 12, 12, 1.30, 1.0), ("dmg_18", 18, 6, 6, 0.75, 1.0), ("dmg_19", 9, 21, 18, 1.0, 1.0), ("dmg_20", 13, 5, 60, 1.0, 1.0),
        ("dmg_21", 6, 11, 7, 1.0, 4.0), ("dmg_22", 6, 11, 7, 1.0, 0.65),
    ]
    v["damage"] = [dict(id=i, power=p, A=a, D=d, grade=g, mult=m, want=damage(p, a, d, g, m)) for i, p, a, d, g, m in dmg]
    pw = [
        ("pow_01", "basic", 3, 0, 1.0), ("pow_02", "basic", 6, 0, 1.0), ("pow_03", "basic", 1, 0, 1.0),
        ("pow_04", "skill", 3, 5, 1.5), ("pow_05", "skill", 9, 4, 1.0), ("pow_06", "enemy_skill", 0, 4, 1.0),
    ]
    out = []
    for i, kind, wp, sp, pm in pw:
        want = {"basic": power_basic(wp), "skill": power_skill(sp, pm, wp), "enemy_skill": power_enemy_skill(sp, pm)}[kind]
        out.append(dict(id=i, kind=kind, weapon_power=wp, skill_power=sp, power_mult=pm, want=want))
    v["power"] = out
    v["resources"] = (
        [dict(id="hp_%d_%d" % (hd, lv), kind="hp", hd=hd, level=lv, want=hp_max(hd, lv)) for hd, lv in [(10, 1), (10, 10), (8, 5), (6, 10), (8, 3)]]
        + [dict(id="mp_%d_%d_%d" % (g, lv, mag), kind="mp", mp_gain=g, level=lv, mag=mag, want=mp_max(g, lv, mag)) for g, lv, mag in [(1, 1, 3), (2, 10, 39), (2, 1, 12), (1, 5, 4)]]
    )
    v["class_levels"] = []
    for cls in ("knight", "archer", "mage", "nobody"):
        for lv in (1, 2, 3, 5, 10):
            s = class_state(cls, lv)
            v["class_levels"].append(dict(id="cls_%s_%d" % (cls, lv), cls=cls, level=lv, **s))
    v["exp_next"] = [dict(id="exp_%d" % (i + 1), level=i + 1, want=w) for i, w in enumerate(EXP_NEXT)] + [dict(id="exp_10", level=10, want=0)]
    v["enemies"] = []
    for name, lv in [("slime", 1), ("spider", 3), ("snake", 4), ("mad_whisp", 6), ("killer_plant", 5), ("dire_wolf", 4), ("ghost_sword", 6),
                     ("stranger", 8), ("palehorn", 8), ("choirbeast", 10)]:
        e = ENEMIES[name]
        v["enemies"].append(dict(id="en_%s_%d" % (name, lv), enemy=name, level=lv, atk=e[0], df=e[1], spd=e[2], mag=e[3], hp=enemy_hp(name, lv)))
    v["run_chance"] = [dict(id="run_%d_%d" % (a, b), spd_player=a, spd_enemy=b, want=round(run_chance(a, b), 4)) for a, b in [(8, 9), (13, 9), (30, 5), (1, 40), (10, 10)]]
    v["crit_chance"] = [dict(id="crit_%d" % b, bonus=b, want=crit_chance(b)) for b in (0, 25, 80)]
    v["heal"] = [dict(id="heal_5_12", power=5, A=12, want=heal(5, 12))]
    v["first_actor"] = [dict(id="first_%d_%d" % (a, b), spd_player=a, spd_enemy=b, player_first=player_first(a, b)) for a, b in [(8, 9), (9, 9), (13, 9)]]
    return v


def num(x):
    """The literal as GML source."""
    if isinstance(x, bool):
        return "true" if x else "false"
    return repr(x)


GML_ENEMY = {"slime": "ENEMY_SLIME", "spider": "ENEMY_SPIDER", "snake": "ENEMY_SNAKE", "mad_whisp": "ENEMY_MADWHISP", "killer_plant": "ENEMY_KILLER_PLANT",
             "dire_wolf": "ENEMY_DIREWOLF", "ghost_sword": "ENEMY_GHOSTSWORD", "stranger": "ENEMY_STRANGER", "palehorn": "ENEMY_MINI_BOSS",
             "choirbeast": "ENEMY_FINAL_BOSS"}


def gml_lines(v):
    L = []
    for c in v["damage"]:
        L.append('Test_Eq("vec %s", Combat_RatioDamage(%s, %s, %s, %s, %s), %s);' % (c["id"], num(c["power"]), c["A"], c["D"], num(c["grade"]), num(c["mult"]), c["want"]))
    for c in v["power"]:
        if c["kind"] == "basic":
            call = "Combat_PowerBasic(%s)" % c["weapon_power"]
        elif c["kind"] == "skill":
            call = "Combat_PowerSkill(%s, %s, %s)" % (c["skill_power"], num(c["power_mult"]), c["weapon_power"])
        else:
            call = "Combat_PowerEnemySkill(%s, %s)" % (c["skill_power"], num(c["power_mult"]))
        L.append('Test_Eq("vec %s", %s, %s);' % (c["id"], call, num(c["want"])))
    for c in v["resources"]:
        if c["kind"] == "hp":
            L.append('Test_Eq("vec %s", Resource_MaxHp(%d, %d), %d);' % (c["id"], c["hd"], c["level"], c["want"]))
        else:
            L.append('Test_Eq("vec %s", Resource_MaxMp(%d, %d, %d), %d);' % (c["id"], c["mp_gain"], c["level"], c["mag"], c["want"]))
    for c in v["class_levels"]:
        L.append('Test_ClassAt("vec %s", CLASS_%s, %d, %d, %d, %d, %d, %d, %d);' % (c["id"], c["cls"].upper(), c["level"], c["atk"], c["df"], c["spd"], c["mag"], c["hp"], c["mp"]))
    for c in v["exp_next"]:
        L.append('Test_Eq("vec %s", Exp_NextLevel(%d), %d);' % (c["id"], c["level"], c["want"]))
    for c in v["enemies"]:
        L.append('Test_EnemyAt("vec %s", %s, %d, %d, %d, %d, %d, %d);' % (c["id"], GML_ENEMY[c["enemy"]], c["level"], c["atk"], c["df"], c["spd"], c["mag"], c["hp"]))
    for c in v["run_chance"]:
        L.append('Test_Eq("vec %s", Battle_RunChance(%d, %d), %s);' % (c["id"], c["spd_player"], c["spd_enemy"], num(c["want"])))
    for c in v["crit_chance"]:
        L.append('Test_Eq("vec %s", Combat_CritChance(%d), %s);' % (c["id"], c["bonus"], num(c["want"])))
    for c in v["heal"]:
        L.append('Test_Eq("vec %s", Combat_HealAmount(%d, %d), %d);' % (c["id"], c["power"], c["A"], c["want"]))
    for c in v["first_actor"]:
        L.append('Test_Eq("vec %s", Combat_PlayerActsFirst(%d, %d), %s);' % (c["id"], c["spd_player"], c["spd_enemy"], num(c["player_first"])))
    return L


def main(argv):
    v = build()
    if "--write" in argv:
        with open(VECTORS, "w", encoding="utf-8", newline="\n") as f:
            json.dump(v, f, indent=1)
            f.write("\n")
        print("wrote", VECTORS)
        return 0
    if "--gml" in argv:
        print("\n".join(gml_lines(v)))
        return 0
    bad = 0
    with open(VECTORS, encoding="utf-8") as f:
        on_disk = json.load(f)
    if on_disk != json.loads(json.dumps(v)):
        print("FAIL combat-vectors.json differs from the reference (run --write after changing the spec)")
        bad += 1
    with open(TESTS, encoding="utf-8") as f:
        src = f.read().splitlines()
    for line in gml_lines(v):
        m = re.match(r'(Test_\w+\("vec \S+")', line)
        key = m.group(1)
        hit = [s for s in src if s.strip().startswith(key)]
        if not hit:
            print("FAIL scr_test.gml has no line for", key)
            bad += 1
        elif hit[0].strip() != line:
            print("FAIL scr_test.gml line differs from the vector:\n  have", hit[0].strip(), "\n  want", line)
            bad += 1
    print("OK %d vectors" % len(gml_lines(v)) if bad == 0 else "%d problems" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
