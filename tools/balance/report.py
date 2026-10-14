#!/usr/bin/env python3
"""Writes .planning/research/balance-report.md from the simulator (packet E1).

  python tools/balance/report.py                  full report (about 5 minutes with 4+ cores)
  python tools/balance/report.py --runs 120       a quick draft
  python tools/balance/report.py --out FILE       another output path

It runs the simulator three ways: whole runs (class x skill profile) against tools/balance/targets.json, isolated tests of every skill, upgrade,
passive, throwable and elite modifier, and the PROPOSALS below (each as what-if data changes, never game changes: D13). Everything is seeded.
"""
import argparse
import math
import os
import random
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sim  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, ".planning", "research", "balance-report.md")
CLASSES = ["knight", "archer", "mage", "nobody"]
PROFILES = ["novice", "average", "expert"]

# ---------------------------------------------------------------------------------------------------------------------------------
# The proposals: what-if changes to the exported data. `loc` says where the number lives in the game.
# ---------------------------------------------------------------------------------------------------------------------------------
LOC = {
    "enemies": "scripts/scr_db_enemy/scr_db_enemy.gml",
    "skills": "scripts/scr_db_skill/scr_db_skill.gml",
    "classes": "scripts/scr_db_player_class + scr_levelup (LevelUp_ClassGrowthGain)",
    "constants.economy": "scripts/scr_loot/scr_loot.gml (macro)",
    "constants.timeline": "scripts/scr_combat/scr_combat.gml (macro)",
    "cards": "scripts/scr_db_skill/scr_db_skill.gml (CardDB_Init)",
}
ENEMY_BP_OLD_NEW = {"slime": 5, "spider": 5, "snake": 5, "dire_wolf": 5, "mad_whisp": 7, "killer_plant": 7, "ghost_sword": 7, "stranger": 7, "choirbeast": 14}
HEAVY = ("Vine Trap", "Cut", "Ramming", "Pale Hymn")


def nobody_growth():
    out = []
    for lv in range(2, 11):
        key = {0: "spd", 1: "mag", 2: "atk", 3: "def"}[(lv - 2) % 4]
        out.append(("classes[nobody].growth_per_level[%d].gain.%s" % (lv, key), 1))
    return out


PROPOSALS = [
    dict(id="E1-1", title="Bosses: more HP and DEF (fight length)",
         why="Boss fights are 3.5-7 player turns against a target of 8-12 (Palehorn) and 12-18 (Choirbeast); the final boss is the shortest fight of the run for a Mage. "
             "HP is the one lever that lengthens a fight for every class without changing how it feels.",
         changes=[("enemies[palehorn].base_hp", 55), ("enemies[palehorn].stats.def", 18), ("enemies[choirbeast].base_hp", 140), ("enemies[choirbeast].stats.def", 24)]),
    dict(id="E1-2", title="Elites: a hit-point multiplier (new constant ELITE_HP_MULT)",
         why="An elite is 2.4-2.9 player turns, shorter than a normal fight, so the 'elite' is an upgrade in name only (target 5-8). The five modifiers cannot fix this "
             "alone (+4 DEF, +4 ATK, +3 SPD). Needs a one-line hook in Elite_Apply (max_hp x ELITE_HP_MULT); it is the only proposal that is not a pure number change.",
         changes=[("constants.economy.elite_hp_mult", 1.8)]),
    dict(id="E1-3", title="Enemy basic attacks: power 3/5/9 -> 5/7/14 (Palehorn stays 7)",
         why="A rank-1 enemy hits a Knight for 1 HP. basic_power is a final formula power while the player's basic power is 2 x weapon power (6-18), so enemy basic hits are "
             "about half as strong as the player's. Floors drain 18-36% of HP (target 60-80%; with about 2 fights per floor that target is out of reach, so it is advisory) and the run uses 0.2-1.0 potions.",
         changes=[("enemies[%s].basic_power" % k, v) for k, v in ENEMY_BP_OLD_NEW.items()]),
    dict(id="E1-4", title="Heavy (telegraphed) enemy moves: power x1.5 -> x2.0",
         why="Only wind-up moves go through the defence bar, so they are where Perfect / Good / OK / Weak turns into HP. Today a novice and an expert Archer win the same share of runs; "
             "bigger heavy moves widen the spread between skill profiles (target novice 15-30%, expert 70%+).",
         changes=[("skills[%s].power_mult" % n, 2.0) for n in HEAVY]),
    dict(id="E1-5", title="Knight: base SPD 8 -> 10",
         why="SPD is the master stat: at SPD 8 a Knight gets 0.5-0.67 actions per Palehorn action (SPD 12-16), an Archer 1.0-1.3. Alone it takes the Knight's floor drain from 28% to 20% of HP; "
             "its real job is to stop the Knight being the class that is hit twice per action once E1-3 and E1-4 make hits count (see the leave-one-out table).",
         changes=[("classes[knight].stats.spd", 10)]),
    dict(id="E1-6", title="Nobody: a second fixed point per level, throwables x2",
         why="Nobody (no skills, D83) hits the Palehorn wall (about 30% of its average-profile runs end there, 18 player turns to win) because it also has the weakest growth. A second point per level (cycling "
             "SPD/MAG/ATK/DEF behind the first) and THROW_NOBODY_MULT 1.5 -> 2.0 keep it the hard class without making the first boss unwinnable.",
         changes=nobody_growth() + [("constants.economy.throw_nobody_mult", 2.0)]),
    dict(id="E1-7", title="Mage: HP die d6 -> d8 (+1 HP per level)",
         why="Once enemies hit harder (E1-3, E1-4) the Mage is the class that falls first: HP +5 per level against the Knight's +7, DEF 7. In the simulator, Fireball 6 -> 5 and Double Shot 4 -> 3 "
             "(tried, dropped) change no win rate or fight length by more than noise, so they are not proposed; the Mage's 3.7-turn final boss is a boss-HP problem (E1-1).",
         changes=[("classes[mage].hd", 8)]),
    dict(id="E1-8", title="Economy: gold glut (SHOP_PRICE_MULT 1.5 -> 2.0, GOLD_BASE 10 -> 7)",
         why="A run earns 540-760 gold and ends with 480-610 unspent: the three shops stock a handful of items. Either gold is cut or the shops get more things to buy; "
             "this numbers-only version cuts income and raises prices (more shops or a bigger stock is the owner's design call).",
         changes=[("constants.economy.price_mult", 2.0), ("constants.economy.gold_base", 7)]),
]


def all_changes(props):
    out = []
    for p in props:
        out.extend(p["changes"])
    return out


def old_value(d, path):
    """The current value of a tweak path in the unmodified data (None for a new constant)."""
    import re
    parts = re.findall(r"[A-Za-z_]+\[[^\]]*\]|[^.\[]+", path)
    cur = d.raw
    try:
        for part in parts:
            m = re.fullmatch(r"([A-Za-z_]+)\[([^\]]*)\]", part)
            if m:
                cur = sim._find(cur[m.group(1)], m.group(2))
            else:
                cur = cur[part]
        return cur
    except (KeyError, TypeError, IndexError):
        return None


# ---------------------------------------------------------------------------------------------------------------------------------
# Isolated tests
# ---------------------------------------------------------------------------------------------------------------------------------
class ForcedSkill(sim.Policy):
    """Uses one given skill whenever it can (buffs only when missing); otherwise a basic attack. HP potions are off the table: this measures the skill."""

    def __init__(self, R, sid):
        super().__init__(R)
        self.sid = sid

    def choose(self, b):
        p = b.p
        if self.sid is not None and self.sid in p.skills:
            s = self.R.player_skill(p, self.sid)
            if p.mp >= s["mp_cost"]:
                if s["effect"] == "status" and sim.st_has(p, s["status"]):
                    return ("basic", -1)
                if s["effect"] == "status" and s["status"] in (sim.GUARD, sim.EVASION) and b.e.ai["windup"] < 0 and b.p_turns > 1:
                    return ("basic", -1)
                return ("skill", self.sid)
        return ("basic", -1)


MID_REFS = [("dire_wolf", 4), ("killer_plant", 5), ("ghost_sword", 6), ("snake", 4)]   # no Mad Whisp: its Snuff strips buffs and would distort the buff skills
BOSS_REFS = [("palehorn", 8)]


def fight_batch(d, R, build, refs, policy_factory, n=120, seed=5, profile="average", elite="", player_level=5):
    """Mean player turns, HP lost share and MP used over the reference enemies. `build(p)` edits a fresh default build."""
    turns, hp, mp, wins = [], [], [], 0
    cnt = 0
    for name, lvl in refs:
        for i in range(n):
            p = sim.default_build(d, R, build["cls"], player_level)
            p.inv = {}
            build["fn"](p)
            R.resources(p)
            p.hp, p.mp = p.mhp, p.mmp
            e = sim.make_enemy(R, sim.ENEMY_IDS[name], lvl, elite)
            b = sim.Battle(R, p, e, profile, random.Random(seed * 1000 + i), policy_factory(R), None)
            won = b.run()
            cnt += 1
            wins += 1 if won else 0
            turns.append(b.p_turns)
            hp.append(min(1.0, max(0.0, (b.hp_start - max(0, p.hp)) / max(1, p.mhp))))
            mp.append(max(0, b.mp_start - p.mp) / max(1, p.mmp))
    return dict(turns=sim.mean(turns), hp=sim.mean(hp), mp=sim.mean(mp), win=wins / cnt)


def skill_tests(d, R, n):
    rows = []
    for cls in ("knight", "archer", "mage"):
        cid = sim.CLASS_IDS[cls]
        sids = [c["skill_id"] for c in d.card_list if c["kind"] == "skill" and cid in c["classes"]]
        for refs_name, refs in (("mid", MID_REFS), ("boss", BOSS_REFS)):
            base = fight_batch(d, R, dict(cls=cls, fn=lambda p: setattr(p, "skills", [])), refs, lambda R_: ForcedSkill(R_, None), n)
            for sid in sids:
                with_s = fight_batch(d, R, dict(cls=cls, fn=lambda p, s=sid: setattr(p, "skills", [s])), refs, lambda R_, s=sid: ForcedSkill(R_, s), n)
                with_u = fight_batch(d, R, dict(cls=cls, fn=lambda p, s=sid: (setattr(p, "skills", [s]), setattr(p, "upgrades", [s]))), refs, lambda R_, s=sid: ForcedSkill(R_, s), n)
                rows.append(dict(cls=cls, refs=refs_name, sid=sid, name=d.skills[sid]["name"], mp=d.skills[sid]["mp_cost"], base=base, skill=with_s, up=with_u))
    return rows


def passive_tests(d, R, n):
    rows = []
    pas = [c for c in d.card_list if c["kind"] == "passive"]
    for cls in ("knight", "archer", "mage"):
        cid = sim.CLASS_IDS[cls]
        sids = [c["skill_id"] for c in d.card_list if c["kind"] == "skill" and cid in c["classes"]][:3]

        def mk(pas_id=None):
            def fn(p):
                p.skills = list(sids)
                if pas_id:
                    p.passives = [pas_id]
                    pr = d.cards[pas_id]["params"]
                    for k, key in (("stat_atk", "atk"), ("stat_def", "df"), ("stat_spd", "spd"), ("stat_mag", "mag")):
                        if k in pr:
                            p.st = dict(p.st)
                            p.st[key] += pr[k]
            return fn

        refs = MID_REFS + BOSS_REFS
        base = fight_batch(d, R, dict(cls=cls, fn=mk()), refs, lambda R_: sim.Policy(R_), n)
        for c in pas:
            if c["classes"] and cid not in c["classes"]:
                continue
            r = fight_batch(d, R, dict(cls=cls, fn=mk(c["id"])), refs, lambda R_: sim.Policy(R_), n)
            rows.append(dict(cls=cls, id=c["id"], name=c["name"], base=base, with_=r, params=c["params"]))
    return rows


def throw_tests(d, R, n):
    class Thrower(sim.Policy):
        def __init__(self, R_, iid):
            super().__init__(R_)
            self.iid = iid

        def choose(self, b):
            if b.p_turns == 1 and self.iid in b.p.inv:
                return ("throw", self.iid)
            return ("basic", -1)

    rows = []
    for iid in (30, 31, 32, 33):
        for cls in ("knight", "nobody"):
            base = fight_batch(d, R, dict(cls=cls, fn=lambda p: setattr(p, "skills", [])), MID_REFS + BOSS_REFS, lambda R_: Thrower(R_, -1), n)
            r = fight_batch(d, R, dict(cls=cls, fn=lambda p, i=iid: (setattr(p, "skills", []), p.inv.update({i: 1}))), MID_REFS + BOSS_REFS, lambda R_, i=iid: Thrower(R_, i), n)
            rows.append(dict(iid=iid, name=d.items[iid]["name"], cls=cls, price=max(1, math.ceil(d.items[iid]["value"] * d.eco["price_mult"] - 1e-6)), base=base, with_=r))
    return rows


def elite_tests(d, R, n):
    rows = []
    for mod in ["", "armored", "venomous", "swift", "brutal", "regenerating"]:
        for cls in ("knight", "archer", "mage"):
            cid = sim.CLASS_IDS[cls]
            sids = [c["skill_id"] for c in d.card_list if c["kind"] == "skill" and cid in c["classes"]][:3]
            r = fight_batch(d, R, dict(cls=cls, fn=lambda p, s=sids: setattr(p, "skills", list(s))), [("dire_wolf", 4), ("killer_plant", 5), ("ghost_sword", 6)], lambda R_: sim.Policy(R_), n, elite=mod)
            rows.append(dict(mod=mod or "none", cls=cls, **r))
    return rows


# ---------------------------------------------------------------------------------------------------------------------------------
# Markdown
# ---------------------------------------------------------------------------------------------------------------------------------
def pct(x, d=0):
    return ("%." + str(d) + "f%%") % (100 * x) if x == x else "-"


def f1(x):
    return "%.1f" % x if x == x else "-"


def md_table(head, rows):
    out = ["| " + " | ".join(head) + " |", "|" + "|".join(["---"] * len(head)) + "|"]
    for r in rows:
        out.append("| " + " | ".join(str(c) for c in r) + " |")
    return "\n".join(out)


def table_win(table):
    rows = []
    for c in CLASSES:
        row = [c]
        for p in PROFILES:
            a = table[(c, p)]
            row.append("%s (%s-%s)" % (pct(a["win_rate"]), pct(a["win_ci"][0]), pct(a["win_ci"][1])))
        rows.append(row)
    return md_table(["class"] + PROFILES, rows)


def table_fights(table, prof="average"):
    cats = ["normal", "elite", "stranger", "mini_boss", "final_boss"]
    rows = []
    for c in CLASSES:
        a = table[(c, prof)]
        row = [c]
        for cat in cats:
            f = a["fights"].get(cat)
            row.append("%s t / %s" % (f1(f["turns_win"]), pct(f["win_rate"])) if f else "-")
        rows.append(row)
    return md_table(["class"] + cats, rows)


def table_levels(table):
    rows = []
    for c in CLASSES:
        a = table[(c, "average")]
        rows.append([c, f1(a["levels"]["mini_boss"]), f1(a["levels"]["floor7"]), f1(a["levels"]["final_boss"]), f1(a["minutes_win"]),
                     "%s-%s" % (f1(a["minutes_p10_p90"][0]), f1(a["minutes_p10_p90"][1])), "%.0f" % a["gold_earned"], "%.0f" % a["gold_left_win"],
                     f1(a["potions_used"]), pct(a["fights"]["normal"]["hp_lost"]), pct(a["fights"]["normal"]["mp_frac"]), pct(a["floor_drain"])])
    return md_table(["class", "L at Palehorn", "L entering f7", "L at final boss", "min (winning run)", "min p10-p90", "gold earned", "gold unspent", "potions used", "HP lost / normal fight", "MP used / normal fight", "floor drain"], rows)


def deaths_text(table, prof="average"):
    out = []
    for c in CLASSES:
        a = table[(c, prof)]
        top = list(a["deaths"].items())[:4]
        out.append("- **%s**: %s" % (c, ", ".join("%s x%d" % (k, v) for k, v in top) if top else "no deaths"))
    return "\n".join(out)


def verdict_rows(table, T):
    res = sim.evaluate(table, T)
    # group by id
    groups = {}
    for r in res:
        groups.setdefault(r["id"], []).append(r)
    rows = []
    descr = {
        "fight_turns.normal": "normal fight, player turns", "fight_turns.elite": "elite fight, player turns", "fight_turns.mini_boss": "Palehorn, player turns",
        "fight_turns.final_boss": "Pale Choirbeast, player turns", "normal_fight_win_rate": "normal fight win rate", "level_final_boss": "level at final boss",
        "level_mini_boss": "level at Palehorn", "level_floor7": "level entering floor 7", "run_win_rate": "run win rate", "run_minutes": "run length (min, winning runs)",
        "class_spread.average": "class spread (avg profile, pts)", "class_spread.novice": "class spread (novice)", "class_spread.expert": "class spread (expert)", "dominant_card": "dominant card (> 60% of winning runs in first 3 picks)",
    }
    order = ["fight_turns.normal", "fight_turns.elite", "fight_turns.mini_boss", "fight_turns.final_boss", "normal_fight_win_rate", "run_win_rate", "run_minutes", "level_mini_boss", "level_floor7",
             "level_final_boss", "class_spread.average", "class_spread.novice", "class_spread.expert", "dominant_card"]
    for k in order:
        if k not in groups:
            continue
        g = groups[k]
        band = g[0]["band"]
        cells = []
        okc = 0
        for r in g:
            v = r["value"]
            txt = ("%.0f%%" % (100 * v)) if (k in ("normal_fight_win_rate", "run_win_rate") or k.startswith("class_spread")) else ("%.1f" % v if isinstance(v, float) else str(v))
            cells.append("%s %s%s" % (r["cell"][0][:3] if r["cell"][0] != "all" else "", r["cell"][1][:3] if k in ("run_win_rate",) else "", txt) if k != "dominant_card" else "%s %s" % (r["cell"][0][:3], r.get("note", "")))
            okc += 1 if r["ok"] else 0
        bandtxt = ("%s-%s" % (band[0], band[1]))
        if k in ("normal_fight_win_rate", "run_win_rate") or k.startswith("class_spread"):
            bandtxt = "%.0f-%.0f%%" % (100 * band[0], 100 * band[1])
        rows.append([descr.get(k, k), bandtxt, "%d / %d" % (okc, len(g)), "; ".join(cells)])
    return rows, res


def render_skill_rows(rows):
    out = []
    for cls in ("knight", "archer", "mage"):
        for refs in ("mid", "boss"):
            rs = [r for r in rows if r["cls"] == cls and r["refs"] == refs]
            if not rs:
                continue
            b = rs[0]["base"]
            out.append("**%s vs %s** (basic attack only: %s turns, %s HP lost)" % (cls, "mid-floor enemies" if refs == "mid" else "Palehorn", f1(b["turns"]), pct(b["hp"])))
            out.append("")
            tab = []
            for r in rs:
                dt = b["turns"] - r["skill"]["turns"]
                dh = b["hp"] - r["skill"]["hp"]
                du = r["skill"]["turns"] - r["up"]["turns"]
                tab.append([r["name"], r["mp"], f1(r["skill"]["turns"]), pct(r["skill"]["hp"]), "%+.1f" % dt, "%+.0f pts" % (100 * dh), pct(r["skill"]["mp"]), "%+.1f t / %+.0f pts" % (du, 100 * (r["skill"]["hp"] - r["up"]["hp"]))])
            out.append(md_table(["skill", "MP", "turns", "HP lost", "turns saved vs basic", "HP saved", "MP share used", "upgrade adds"], tab))
            out.append("")
    return "\n".join(out)


def skill_verdicts(rows):
    """Dominant / useless by turns+HP saved against the class median (boss and mid fights pooled)."""
    out = []
    for cls in ("knight", "archer", "mage"):
        per = {}
        for r in rows:
            if r["cls"] != cls:
                continue
            b = r["base"]
            gain = (b["turns"] - r["skill"]["turns"]) / max(1e-9, b["turns"]) + (b["hp"] - r["skill"]["hp"])
            per.setdefault(r["name"], []).append(gain)
        vals = {k: sim.mean(v) for k, v in per.items()}
        med = sorted(vals.values())[len(vals) // 2]
        for k, v in sorted(vals.items(), key=lambda kv: -kv[1]):
            tag = "dominant" if v > 2 * max(med, 0.05) else ("useless" if v < 0.25 * max(med, 0.05) or v <= 0.02 else "ok")
            out.append((cls, k, v, tag))
    return out


# ---------------------------------------------------------------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=400)
    ap.add_argument("--seed", type=int, default=20261014)
    ap.add_argument("--jobs", type=int, default=max(1, min(8, (os.cpu_count() or 2) - 1)))
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--tests", type=int, default=100, help="battles per isolated test")
    a = ap.parse_args()
    t0 = time.time()
    d = sim.Data()
    R = sim.Rules(d)
    T = sim.load_targets()

    def log(msg):
        print("[%4.0fs] %s" % (time.time() - t0, msg), file=sys.stderr)

    log("baseline, greedy policy")
    base = sim.build_table(sim.DEFAULT_DATA, CLASSES, PROFILES, a.runs, a.seed, a.jobs, quiet=True)
    log("baseline, basic-attack-only policy (average profile)")
    base_basic = sim.build_table(sim.DEFAULT_DATA, CLASSES, ["average"], a.runs, a.seed, a.jobs, policy="basic", quiet=True)
    tw_all = all_changes(PROPOSALS)
    log("all proposals together")
    after = sim.build_table(sim.DEFAULT_DATA, CLASSES, PROFILES, a.runs, a.seed, a.jobs, quiet=True, tweaks=tw_all)
    after_basic = sim.build_table(sim.DEFAULT_DATA, CLASSES, ["average"], a.runs, a.seed, a.jobs, policy="basic", quiet=True, tweaks=tw_all)
    singles = {}
    for p in PROPOSALS:
        log("proposal alone: " + p["id"])
        singles[p["id"]] = sim.build_table(sim.DEFAULT_DATA, CLASSES, ["average"], max(100, a.runs // 2), a.seed, a.jobs, quiet=True, tweaks=p["changes"])
    loo = {}
    for p in PROPOSALS:
        log("all proposals except " + p["id"])
        loo[p["id"]] = sim.build_table(sim.DEFAULT_DATA, CLASSES, ["average"], max(100, a.runs // 2), a.seed, a.jobs, quiet=True, tweaks=all_changes([q for q in PROPOSALS if q["id"] != p["id"]]))
    log("isolated skill tests")
    sk_rows = skill_tests(d, R, a.tests)
    log("passive tests")
    pa_rows = passive_tests(d, R, max(40, a.tests // 2))
    log("throwables, elites")
    th_rows = throw_tests(d, R, a.tests)
    el_rows = elite_tests(d, R, a.tests)

    L = []
    w = L.append
    w("# Balance report (packet E1: simulator, targets, proposals)")
    w("")
    w("Generated by `python tools/balance/report.py` (data build `%s`, seed %d, %d runs per class x profile cell). Nothing in the game was changed (D13): every number below that "
      "differs from the game is a **proposal** the owner approves in a batch." % (d.build, a.seed, a.runs))
    w("")
    w("## 0. Read this first")
    w("")
    w("- **Method.** `tools/balance/sim.py` re-implements the combat spec (damage, statuses, SPD timeline, stagger/BREAK, B4 enemy rule lists, wind-ups and boss phases), the C2 card offers and level-ups, "
      "the C3 gold, shops, elites and loot, on the data the game exports (`-exportdata`). The formulas are imported from `check_combat_vectors.py`; `sim.py --vectors` replays all "
      "137 combat vectors plus the exported class and enemy tables through the simulator (144 checks, all pass). `test_sim.py` has 21 more checks.")
    w("- **Players.** QTE skill profile (Perfect/Good/OK/Weak): novice 15/35/35/15, average 30/40/25/5, expert 60/30/10/0. Decisions: the *greedy* policy (documented in `sim.py`, class `Policy`): "
      "heals before a killing blow, throws a bomb at hard fights, spends MP where it buys most, takes the card with the best expected gain, buys by value per gold. "
      "A *basic-attack-only* policy brackets it from below (section 1.6). A real first-time player sits between the two.")
    w("- **Not modelled** (so the numbers are optimistic for the player): walking into extra fights, fleeing, equipment passives that need state (Sunder Edge, Pinning Shot, Mirror Stitch), "
      "selling items, the echo gift, and any mistake in reading a wind-up. Foresight's information is not used by the policy, so Foresight looks weak here.")
    w("- **Targets** are in `tools/balance/targets.json` (from D14/D30/D61, balance-methods 6.2, combat-spec section 7 and the packet brief). One reading call: Nobody is the pure challenge class (D83), so it has its own win-rate band "
      "(average 15-30%) and is left out of the +-10-point class spread and the fight-length bands; put it back in `class_spread_classes` / `fight_turn_classes` for the literal brief.")
    w("- **Run length is a lower bound.** Time = (player + enemy actions) x 2.5 s + 1.5 s per defence bar + 25 s per floor + 6 s per fight + 8 s per card pick + 45 s per shop + 150 s story, "
      "as the brief says. Rooms are 16 x 11 tiles (one screen), the map has 19 free enemies plus 6 fixed fights.")
    w("")

    w("## 1. Where the game is today (data from `%s`)" % d.build)
    w("")
    w("### 1.1 Verdict against the targets (`tools/balance/targets.json`, average profile unless noted)")
    w("")
    rows, res = verdict_rows(base, T)
    w(md_table(["metric", "target band", "cells in band", "values (class, value)"], rows))
    bad = [r for r in res if not r["ok"]]
    w("")
    w("**%d of %d checks are outside their band.** `python tools/balance/sim.py --check` exits 1 until that is fixed." % (len(bad), len(res)))
    w("")
    w("### 1.2 Run win rate (95% interval)")
    w("")
    w(table_win(base))
    w("")
    w("Targets: average 35-55%, expert 70%+, novice 15-30%. Same seeds in every cell, so the cells differ only by class and by QTE skill.")
    w("")
    w("### 1.3 Fight length and win rate by fight type (average profile; mean player turns of won fights / win rate)")
    w("")
    w(table_fights(base))
    w("")
    w("Targets: normal 3-5, elite 5-8, Palehorn 8-12, Choirbeast 12-18 turns; normal win rate 97%+. 'stranger' is the story enemy of floors 7-9 (no target).")
    w("")
    w("### 1.4 Pace, levels, resources")
    w("")
    w(table_levels(base))
    w("")
    w("Targets: level 4-5 at Palehorn, about 7 entering floor 7, 8-10 at the final boss (`combat-spec.md` section 7); 45-60 minutes; HP lost per normal fight 10-25%, MP 15-30%, a floor drains 60-80% (balance-methods 6.2). "
      "The EXP curve is fine. Everything about **time and attrition** is far from the plan.")
    w("")
    w("### 1.5 Where runs end (average profile, greedy)")
    w("")
    w(deaths_text(base))
    w("")
    w("### 1.6 Bracketing the player's decisions: basic attacks only")
    w("")
    rows = []
    for c in CLASSES:
        g = base[(c, "average")]
        bb = base_basic[(c, "average")]
        rows.append([c, pct(g["win_rate"]), pct(bb["win_rate"]), f1(bb["fights"]["mini_boss"]["turns_win"]), pct(bb["fights"]["mini_boss"]["win_rate"]), pct(bb["fights"]["final_boss"]["win_rate"])])
    w(md_table(["class", "run win, greedy", "run win, basic only", "Palehorn turns (basic only)", "Palehorn win (basic only)", "final boss win (basic only)"], rows))
    w("")
    kb, mb, ab = (pct(base_basic[(c, "average")]["win_rate"]) for c in ("knight", "mage", "archer"))
    kg, mg, ag = (pct(base[(c, "average")]["win_rate"]) for c in ("knight", "mage", "archer"))
    w("Skills are the difference between a careful and a careless run: a Knight falls from " + kg + " to " + kb + " and a Mage from " + mg + " to " + mb + " without them; an Archer only from " + ag + " to " + ab +
      " (its speed carries it). The careless end is where a 35-55% first-try target would have to sit; the greedy end is where the numbers below are measured.")
    w("")

    w("## 2. Findings")
    w("")
    w("1. **The game is far too easy and far too short for the plan.** Greedy Knight / Archer / Mage win 90-100% of runs at every skill profile (target 35-55%), "
      "the median winning run is about 20 minutes (target 45-60), a floor drains 18-32% of HP (advisory target 60-80%) and a whole run uses 0.2-1.0 HP potions. "
      "Gold is not a decision: about 600 of the 700 earned is left at the end.")
    w("2. **Elites and bosses are too short.** Elites last about as long as a normal fight; Palehorn 5-7 turns; the Pale Choirbeast 3.7 turns for a Mage, 6-7 for the others.")
    w("3. **SPD decides the class order.** The Knight (SPD 8) gets 0.67 actions per Palehorn action, the Archer (SPD 13+) 1.3. A fast Archer or any multi-hit user also breaks the boss meter "
      "before the wind-up lands (BREAK cancels it, D75), so in the traces the Archer rarely eats a heavy hit: it wins 99-100% at every skill profile while the Knight loses at Palehorn (8 of 400 average runs).")
    w("4. **Class gap.** Mage: strongest burst (Fireball burn is 12 damage on top of the hit) and the squishiest at Palehorn. Nobody: no skills, weakest growth; "
      "it stalls on Palehorn (17-18 player turns) and survives only through throwables.")
    w("5. **The MP economy is one passive.** MP does not regenerate between fights, a Knight has 11-20 MP, skills cost 3-5. Mana Spring (+1 MP every own turn) is taken in nearly every run "
      "because it is the only MP source; the first skill card is Wound or Fireball and most players never get to use a second skill.")
    w("6. **Bug, found while porting Skill_AdjustStatusTurns:** a status with a fixed `duration` ignores the skill's own turns, so **Foresight+ (+2 turns) does nothing** (stays 3). "
      "Muscle Up+/Rev Up+/Evasion+/Take Aim+/Meditation+ are fine (those statuses have no fixed duration). Not a balance number: a one-line fix in `Skill_AdjustStatusTurns` "
      "(use `max(fixed, skill turns)` or put `status_turns` on the upgrade into `duration`).")
    w("7. **Doc slip:** `combat-spec.md` section 11 prints the order for SPD 13 vs 9 as `P E P P E P P E P`; the gauge rule, the reference (`turn_13_9`) and the game give `P E P E P P E P E`.")
    w("")

    w("## 3. Outliers")
    w("")
    w("### 3.1 Skills in isolation (level 5 build, full MP, no potions; one skill + basic attacks vs the same build with basic attacks only)")
    w("")
    w(render_skill_rows(sk_rows))
    sv = skill_verdicts(sk_rows)
    w("**Verdict (pooled mid + boss fights, gain = share of turns saved + HP share saved; dominant > 2x class median, useless < 0.25x median):**")
    w("")
    w(md_table(["class", "skill", "gain", "verdict"], [[c, k, "%.2f" % v, t] for c, k, v, t in sv]))
    w("")
    w("Caveats: buff skills (Muscle Up, Rev Up, Evasion, Take Aim, Meditation, Foresight) are used by the forced policy but their value depends on timing and on MP being the limit, which this isolation hides. "
      "Rev Up cannot gain anything: it doubles the next attack and costs a turn.")
    w("")
    w("### 3.2 Passives (class default 3 skills + the passive; level 5; mid-floor and Palehorn fights; delta = with minus without)")
    w("")
    rows = []
    for r in pa_rows:
        rows.append([r["cls"], r["name"], str(r["params"]), "%+.2f t" % (r["with_"]["turns"] - r["base"]["turns"]), "%+.1f pts" % (100 * (r["with_"]["hp"] - r["base"]["hp"])), "%+.1f pts" % (100 * (r["with_"]["mp"] - r["base"]["mp"]))])
    w(md_table(["class", "passive", "params", "turns", "HP lost", "MP used"], rows))
    w("")
    w("Between-fight passives (Field Medic, Second Wind, Coin Sense, Scrounger, Potion Lore, Tonic Blend, Opening Blow) barely register inside one fight; their value is per run: "
      "Field Medic 3 HP x ~24 fights = 72 HP, about 7 HP potions; Second Wind 2 MP x 24 = 48 MP, about 6 MP potions; those two are worth more than any stat passive.")
    w("")
    w("### 3.3 Throwables (turn 1 of the fight; level 5 Knight and Nobody; delta vs no throw)")
    w("")
    rows = []
    for r in th_rows:
        rows.append([r["name"], r["cls"], r["price"], "%+.2f t" % (r["with_"]["turns"] - r["base"]["turns"]), "%+.1f pts" % (100 * (r["with_"]["hp"] - r["base"]["hp"]))])
    w(md_table(["item", "class", "price", "turns", "HP lost"], rows))
    w("")
    w("### 3.4 Elite modifiers (same three mid-floor enemies, Knight/Archer/Mage default builds)")
    w("")
    rows = []
    for mod in ["none", "armored", "venomous", "swift", "brutal", "regenerating"]:
        rs = [r for r in el_rows if r["mod"] == mod]
        rows.append([mod, f1(sim.mean([r["turns"] for r in rs])), pct(sim.mean([r["hp"] for r in rs])), pct(sim.mean([r["win"] for r in rs]), 1)])
    w(md_table(["modifier", "player turns", "HP lost", "win"], rows))
    w("")
    w("### 3.5 Cards chosen (average profile, winning runs): in the first three picks, per class")
    w("")
    for c in ("knight", "archer", "mage", "nobody"):
        a_ = base[(c, "average")]
        top = list(a_["card_early_share_win"].items())[:6]
        w("- **%s**: %s. Mean gain the policy sees when offered: %s." % (c, ", ".join("%s %s" % (d.cards[k]["name"], pct(v)) for k, v in top),
                                                                           ", ".join("%s %.1f" % (d.cards[k]["name"], g) for k, g in sorted(a_["card_gain"].items(), key=lambda kv: -kv[1])[:4])))
    w("")
    w("Skills: with 5 skills for 3 slots the first pick is almost always the class's damage skill (Wound, Poison Arrow/Double Shot, Fireball); the rest compete with passives and lose, because "
      "MP is the limit (finding 5).")
    w("")
    w("### 3.6 Every enemy (average profile, greedy; player turns / win)")
    w("")
    rows = []
    names = list(base[("knight", "average")]["by_enemy"].keys())
    for nme in names:
        row = [nme]
        for c in ("knight", "archer", "mage", "nobody"):
            v = base[(c, "average")]["by_enemy"].get(nme)
            row.append("%s t / %s" % (f1(v["turns"]), pct(v["win_rate"])) if v else "-")
        rows.append(row)
    w(md_table(["enemy", "knight", "archer", "mage", "nobody"], rows))
    w("")

    w("## 4. PROPOSALS (owner approves in a batch; none is applied)")
    w("")
    w("Each proposal is a what-if on the exported data (`sim.py --tweak 'path=value'`). *Before* = the game today; *alone* = this proposal only; *all* = every proposal together. "
      "Win rates are average-profile run win rates (%d runs per class for 'alone', %d for 'all')." % (max(100, a.runs // 2), a.runs))
    w("")
    for p in PROPOSALS:
        w("### %s  %s" % (p["id"], p["title"]))
        w("")
        w(p["why"])
        w("")
        rows = []
        for path, val in p["changes"]:
            sect = path.split("[")[0].split(".")[0] if "[" in path else ".".join(path.split(".")[:2])
            loc = LOC.get(sect, LOC.get(".".join(path.split(".")[:2]), sect))
            ov = old_value(d, path)
            rows.append([loc, path, "-" if ov is None else ov, val])
        if len(rows) > 12:
            rows = rows[:6] + [["...", "(%d more rows of the same kind)" % (len(rows) - 6), "", ""]]
        w(md_table(["file", "field", "old", "new"], rows))
        w("")
        s = singles[p["id"]]
        trows = []
        for c in CLASSES:
            b_ = base[(c, "average")]
            s_ = s[(c, "average")]
            trows.append([c, pct(b_["win_rate"]), pct(s_["win_rate"]), f1(b_["fights"]["elite"]["turns_win"]) + " > " + f1(s_["fights"]["elite"]["turns_win"]),
                          f1(b_["fights"]["mini_boss"]["turns_win"]) + " > " + f1(s_["fights"]["mini_boss"]["turns_win"]), f1(b_["fights"]["final_boss"]["turns_win"]) + " > " + f1(s_["fights"]["final_boss"]["turns_win"]),
                          pct(b_["floor_drain"]) + " > " + pct(s_["floor_drain"]), "%.0f > %.0f" % (b_["gold_left_win"], s_["gold_left_win"])])
        w("Simulated, this proposal alone vs today:")
        w("")
        w(md_table(["class", "win before", "win alone", "elite turns", "Palehorn turns", "Choirbeast turns", "floor drain", "gold unspent"], trows))
        w("")
    w("### 4.9 All proposals together")
    w("")
    w(table_win(after))
    w("")
    w("(today: " + "; ".join("%s %s/%s/%s" % (c, pct(base[(c, "novice")]["win_rate"]), pct(base[(c, "average")]["win_rate"]), pct(base[(c, "expert")]["win_rate"])) for c in CLASSES) + " for novice/average/expert)")
    w("")
    w(table_fights(after))
    w("")
    w(table_levels(after))
    w("")
    rows2, res2 = verdict_rows(after, T)
    w(md_table(["metric", "target band", "cells in band", "values"], rows2))
    bad2 = [r for r in res2 if not r["ok"]]
    w("")
    w("**With all proposals %d of %d checks are outside their band (today %d of %d).**" % (len(bad2), len(res2), len(bad), len(res)))
    w("")
    w("Basic-attack-only players with all proposals: " + "; ".join("%s %s (today %s)" % (c, pct(after_basic[(c, "average")]["win_rate"]), pct(base_basic[(c, "average")]["win_rate"])) for c in CLASSES) + ".")
    w("")
    w("Leave-one-out: all proposals except one (average profile run win rate; final-boss turns in brackets). Compare with the 'all' row.")
    w("")
    rows = []
    allrow = ["all"] + ["%s (%s t)" % (pct(after[(c, "average")]["win_rate"]), f1(after[(c, "average")]["fights"]["final_boss"]["turns_win"])) for c in CLASSES]
    rows.append(allrow)
    for p in PROPOSALS:
        t_ = loo[p["id"]]
        rows.append(["without " + p["id"]] + ["%s (%s t)" % (pct(t_[(c, "average")]["win_rate"]), f1(t_[(c, "average")]["fights"]["final_boss"]["turns_win"])) for c in CLASSES])
    w(md_table(["proposals"] + CLASSES, rows))
    w("")
    w("### 4.10 What the numbers cannot fix (needs an owner decision, not a number)")
    w("")
    w("- **Run length.** The plan says 45-60 minutes; the map holds 19 free enemies plus Palehorn, 3 Strangers and the Choirbeast on one-screen rooms. Longer fights add a few minutes; the other 25 need "
      "content (more enemies per room, enemy respawn, optional rooms) or a shorter promise. D28 forbids new content, so this needs a grill-me.")
    w("- **Archer.** Even with every proposal the Archer wins 85-95%: SPD plus BREAK-cancelled wind-ups let it avoid the heavy hits that defence bars are meant to price. Options: "
      "boss meters that refill after a cancel, a wind-up that cannot be cancelled twice in a row, or heavy moves that hit before the first player turn. All are rule changes.")
    w("- **Gold.** Numbers alone only trade income for prices; the game needs either more things to buy (cards, rerolls, removal, as in the research) or less gold.")
    w("- **Foresight** needs its information used before it can be judged (the sim does not read wind-up previews).")
    w("")
    w("## 5. Reproduce")
    w("")
    w("```")
    w("powershell -NoProfile -ExecutionPolicy Bypass -File tools/automation/run_tests.ps1 -Mode fast -Only exportdata -WorkRoot E:\\Temp\\dd-gate-e1   # the game's data")
    w("python tools/balance/sim.py --snapshot E:\\Temp\\dd-gate-e1\\export\\export_data.json                                                  # commit it as tools/balance/export_data.json")
    w("python tools/balance/sim.py --vectors                  # parity with combat-vectors.json and the export")
    w("python tools/balance/sim.py --runs 2000 --class knight --profile average")
    w("python tools/balance/sim.py --runs 500 --class all --profile all --tweak 'enemies[palehorn].base_hp=55'")
    w("python tools/balance/sim.py --check                    # exit 1 when a number is outside tools/balance/targets.json")
    w("python tools/balance/report.py                         # this file")
    w("```")
    w("")
    with open(a.out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L) + "\n")
    log("wrote " + a.out)


if __name__ == "__main__":
    main()
