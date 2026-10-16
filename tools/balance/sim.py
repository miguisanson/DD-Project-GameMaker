#!/usr/bin/env python3
"""DD-Project balance simulator (packet E1, BAL-02). Python 3, standard library only.

Plays the game's rules (combat-spec.md sections 4, 10, 11, 12; the economy of packet C3; the card rules of packet C2) on the data the game
exports (tools/balance/export_data.json, written by `run_tests.ps1 -Mode fast -Only exportdata`) and answers: how long are the fights, how often
does a run win, what does each class / card / skill do. It NEVER changes the game: balance numbers change only through an owner-approved
proposal (D13), see .planning/research/balance-report.md.

The damage, stat, status, stagger and timeline formulas are imported from check_combat_vectors.py (the reference of the spec), so the simulator
cannot drift from the spec; `--vectors` proves it by replaying combat-vectors.json through the simulator's own code and the exported data.

  python tools/balance/sim.py --runs 2000 --class knight --profile average      whole runs, one class, one skill profile
  python tools/balance/sim.py --runs 500 --class all --profile all              the full table (4 classes x 3 profiles)
  python tools/balance/sim.py --fights --enemy ghost_sword --level 6 --class mage  one matchup, many battles
  python tools/balance/sim.py --vectors                                          parity with the reference and the exported data
  python tools/balance/sim.py --check                                            exit 1 when a number is outside tools/balance/targets.json

Player skill profiles (share of Perfect / Good / OK / Weak on every QTE): novice 15/35/35/15, average 30/40/25/5, expert 60/30/10/0.
Policies are deliberately simple and written down in the classes below; they are the "average player", not an optimiser.
"""
import argparse
import json
import math
import os
import random
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_combat_vectors as ref  # noqa: E402  (the reference formulas of the spec; imported, never copied)

DEFAULT_DATA = os.path.join(HERE, "export_data.json")
LAYOUT = os.path.join(HERE, "layout.json")
TARGETS = os.path.join(HERE, "targets.json")

PROFILES = {
    "novice": (0.15, 0.35, 0.35, 0.15),
    "average": (0.30, 0.40, 0.25, 0.05),
    "expert": (0.60, 0.30, 0.10, 0.00),
}
GRADES = ("PERFECT", "GOOD", "OK", "WEAK")
CLASS_IDS = {"archer": 0, "knight": 1, "mage": 2, "nobody": 3}
CLASS_NAMES = {v: k for k, v in CLASS_IDS.items()}
ENEMY_IDS = {"slime": 0, "dire_wolf": 1, "ghost_sword": 2, "spider": 3, "mad_whisp": 4, "snake": 5, "killer_plant": 6, "stranger": 7, "palehorn": 8, "choirbeast": 9}
ENEMY_NAMES = {v: k for k, v in ENEMY_IDS.items()}
# status ids (scr_macros)
POISON, BLEED, BURN, STUN, GUARD, DMG_UP, EVASION, CRIT_UP, HIT_UP, MEDITATION, SOLIDIFY, BLOODTHIRSTY, BLESSING, SUNDER = range(14)
# skill ids (scr_macros)
SK_REGROW, SK_SNUFF, SK_STEAL = 28, 29, 22
STATS = ("atk", "def", "spd", "mag")
BEDS_HEAL_FRAC = 1.0   # C4 (D47): a bed heals all HP and MP (scr_levelup Bed_Heal on branch c4-rest)
# H4 (D143): the level's free point may go to Max HP (+FREE_POINT_HP_GAIN) or Max MP (+FREE_POINT_MP_GAIN) instead of the class stat (scr_macros). what-if knobs:
# constants.free_point_choices=0 plays the old way (always the class stat), constants.free_point_hp_gain / free_point_mp_gain change the amounts.
FREE_POINT_HP_GAIN = 3
FREE_POINT_MP_GAIN = 2
ST_KEY = {"atk": "atk", "def": "df", "spd": "spd", "mag": "mag"}   # the free_default stat name -> the key of a fighter's st
# time proxy (seconds); documented in the report. Battle actions count both sides, a defence bar adds time, the rest is walking and menus.
TIME = dict(action_s=2.5, defence_extra_s=1.5, floor_walk_s=25.0, fight_approach_s=6.0, card_pick_s=8.0, shop_s=45.0, story_s=150.0, item_use_s=3.0)


def rhu(x):
    return ref.rhu(x)


# R1 (D117-D123): the randomness rules of the game, written once so the run code and the tests share them.
LOOT_DRY_STEP = 0.1   # D120: +10 points of enemy-drop chance per fight in a row without a drop
# D117: [low, mid, high] tier odds per container level 1..3. The game exports them as loot.tier_odds; an export from before R1 has none, so these are the values it will export.
DEFAULT_TIER_ODDS = {
    "chest": [[0.87, 0.115, 0.015], [0.65, 0.285, 0.065], [0.43, 0.38, 0.19]],
    "barrel": [[0.95, 0.05, 0], [0.85, 0.15, 0], [0.74, 0.26, 0]],
    "enemy": [[0.914, 0.084, 0.002], [0.754, 0.236, 0.010], [0.588, 0.376, 0.036]],
}


def roll_tier(rng, odds):
    """D117 Loot_RollTier: a cascade from the rarest. draw < high -> tier 3; else draw < mid / (1 - high) -> tier 2; else tier 1."""
    low, mid, high = odds
    if rng.random() < high:
        return 3
    return 2 if rng.random() < mid / (1 - high) else 1   # high >= 1 already returned above, so 1 - high > 0 here


def crit_bag_size(p):
    """D119 Crit_BagSize: the smallest bag n in 1..20 where n * p is a whole number of red marbles; else 20 marbles and round(20 * p) reds."""
    for n in range(1, 21):
        if abs(n * p - round(n * p)) < 1e-6:
            return n, int(round(n * p))
    return 20, int(round(20 * p))


def bag_draw(store, key, p, rng):
    """D126 Bag_Draw: one draw from the marble bag store[key] = dict(p, left=[bool]) for the chance p, shuffled with rng when it has to be filled.
    A chance of 1 or 0 needs no bag and draws no random number; the bag refills when it is empty or when the chance changed."""
    if p >= 0.999999:
        store.pop(key, None)
        return True
    if p <= 0:
        store.pop(key, None)
        return False
    bag = store.get(key)
    if bag is None or not bag["left"] or abs(bag["p"] - p) > 1e-6:
        n, reds = crit_bag_size(p)
        left = [True] * reds + [False] * (n - reds)
        rng.shuffle(left)
        bag = store[key] = dict(p=p, left=left)
    return bag["left"].pop()


def int_weights(ws):
    """D126 EnemyAI_IntWeights: the weights as the smallest whole numbers with the same ratios; a deck holds at most about 40 cards."""
    scale = 1
    for _ in range(3):
        if all(abs(w * scale - round(w * scale)) <= 1e-6 for w in ws):
            break
        scale *= 10
    out = [max(1, int(round(w * scale))) for w in ws]
    g = 0
    for n in out:
        g = math.gcd(g, n)
    out = [n // max(1, g) for n in out]
    total = sum(out)
    if total > 40:
        out = [max(1, int(round(n * 40 / total))) for n in out]
    return out


def tick_amount(lo, hi):
    """D126 Status_TickAmount: a tick written as lo..hi is worth its average, rounded half up, every time."""
    return rhu((lo + hi) / 2)


def gold_offsets(spread):
    """D126 Gold_Roll: the five offsets of a gold bag (-spread, -spread/2, 0, +spread/2, +spread)."""
    return [i * spread / 2 for i in range(-2, 3)]


def drop_chance(base, dry):
    """D120 Loot_EnemyDropChance."""
    return min(1.0, base + LOOT_DRY_STEP * dry)


ELITE_FIRST_FLOOR = 3   # D145: no elites on floors 1 and 2 (the game's Shuffle_EliteCount in scr_loot.gml hard-codes the same 3; the export has no field for it)


def elite_count(floor, free, chance=0.15):
    """D123 / D145 Shuffle_EliteCount: elites on one floor, out of its `free` (non-fixed) enemy slots (chance = ELITE_CHANCE, exported as economy.elite_chance).
    None below floor 3; from floor 3, ~chance of the free slots (rounded half up), at least 1, never more than there are."""
    if free <= 0 or int(floor) < ELITE_FIRST_FLOOR:
        return 0
    return min(max(rhu(chance * free), 1), free)


KEY = {"atk": "atk", "df": "def", "spd": "spd", "mag": "mag"}   # the fighter's stat key -> the key the game's data uses


def norm(o):
    """Floats that are whole numbers become ints (GameMaker writes every number as a float)."""
    if isinstance(o, float) and o.is_integer():
        return int(o)
    if isinstance(o, list):
        return [norm(v) for v in o]
    if isinstance(o, dict):
        return {k: norm(v) for k, v in o.items()}
    return o


def _slug(x):
    return str(x).lower().replace(" ", "_")


def _find(section, key):
    """The record of a list section by id, name or (for levels) level number."""
    for rec in section:
        if ("level" in rec and "id" not in rec and _slug(rec["level"]) == _slug(key)) or _slug(rec.get("id")) == _slug(key) or _slug(rec.get("name_en", rec.get("name", ""))) == _slug(key) or _slug(rec.get("name", "")) == _slug(key) or ("level" in rec and "exp_next" in rec and _slug(rec["level"]) == _slug(key)):
            return rec
    for rec in section:   # a short form: choirbeast = "The Pale Choirbeast"
        if _slug(key) in _slug(rec.get("name_en", rec.get("name", ""))) and "name" in rec:
            return rec
    raise KeyError("no record %r" % key)


def apply_tweak(raw, path, value):
    """path: section[key].field.sub (e.g. enemies[palehorn].base_hp, skills[Ramming].power_mult, cards[up:1].up.power, constants.economy.gold_base)."""
    import re
    parts = re.findall(r"[A-Za-z_]+\[[^\]]*\]|[^.\[]+", path)
    cur = raw
    for i, part in enumerate(parts):
        last = (i == len(parts) - 1)
        m = re.fullmatch(r"([A-Za-z_]+)\[([^\]]*)\]", part)
        if m:
            cur = _find(cur[m.group(1)], m.group(2))
            if last:
                raise KeyError("tweak must end in a field: " + path)
            continue
        if last:
            if part not in cur and not isinstance(cur, dict):
                raise KeyError(path)
            cur[part] = value
        else:
            cur = cur[part]


class Data:
    def __init__(self, path=DEFAULT_DATA, tweaks=None):
        with open(path, encoding="utf-8") as f:
            raw = norm(json.load(f))
        for tw_path, tw_val in (tweaks or []):
            apply_tweak(raw, tw_path, tw_val)
        for c in raw["classes"]:   # rebuild the per-level stats from the base stats + fixed growth + the auto-placed free point, so class tweaks reach the simulator
            row = dict(c["stats"])
            for lv in range(1, 11):
                if lv > 1:
                    g = c["growth_per_level"][lv - 2]["gain"]
                    for k in ("atk", "def", "spd", "mag"):
                        row[k] = min(60, row[k] + g[k])
                    fk = ("atk", "def", "spd", "mag")[c["free_default"]]
                    row[fk] = min(60, row[fk] + 1)
                c["by_level"][lv - 1].update(atk=row["atk"], **{"def": row["def"]}, spd=row["spd"], mag=row["mag"])
        self.tweaks = list(tweaks or [])
        self.exp_next = [lv["exp_next"] for lv in raw["levels"]]
        self.raw = raw
        self.build = raw.get("build", "?")
        self.const = raw["constants"]
        self.eco = self.const["economy"]
        self.classes = {c["id"]: c for c in raw["classes"]}
        self.enemies = {e["id"]: e for e in raw["enemies"]}
        self.skills = {s["id"]: s for s in raw["skills"]}
        self.items = {i["id"]: i for i in raw["items"]}
        self.status = {s["id"]: s for s in raw["statuses"]}
        self.cards = {c["id"]: c for c in raw["cards"]}
        self.card_list = raw["cards"]
        self.floors = {f["floor"]: f["pool"] for f in raw["floors"]}
        self.qte = raw["qte"]
        self.tl = self.const["timeline"]
        self.grade_mult = {"PERFECT": self.const["grades"]["perfect"], "GOOD": self.const["grades"]["good"],
                           "OK": self.const["grades"]["ok"], "WEAK": self.const["grades"]["weak"]}
        self.def_mult = {"PERFECT": self.qte["defence_mult"]["perfect"], "GOOD": self.qte["defence_mult"]["good"],
                         "OK": self.qte["defence_mult"]["ok"], "WEAK": self.qte["defence_mult"]["weak"]}
        self.loot = raw["loot"]
        with open(LAYOUT, encoding="utf-8") as f:
            self.layout = json.load(f)["floors"]
        self.skill_cards_by_class = {}
        for cid in CLASS_NAMES:
            self.skill_cards_by_class[cid] = [c for c in self.card_list if c["kind"] != "fallback" and (not c["classes"] or cid in c["classes"])]
        self.tier_weights = self.loot["tier_weights"]   # kept for old readers; since D117 nothing rolls with it
        self.tier_odds = self.loot.get("tier_odds") or DEFAULT_TIER_ODDS


# ---------------------------------------------------------------------------------------------------------------------------------
# Fighters, statuses (combat-spec section 10), stats (section 1)
# ---------------------------------------------------------------------------------------------------------------------------------
class F:
    """One fighter. The player and an enemy share it; fields only one side uses are left at their defaults."""

    def __init__(self, name, is_player):
        self.name = name
        self.is_player = is_player
        self.st = dict(atk=1, df=1, spd=1, mag=1)
        self.hp = self.mhp = 1
        self.mp = self.mmp = 0
        self.status = []
        self.level = 1
        # player
        self.class_id = 3
        self.hd = 8
        self.mp_gain = 1
        self.skills = []          # skill ids
        self.upgrades = []        # skill ids
        self.passives = []        # card ids
        self.equip = dict(weapon=0, armor=0, accessory=0)
        self.inv = {}             # item id -> qty
        self.exp = 0
        self.picks = 0
        self.card_state = dict(pity=0, last=[], offers=0)
        self.rt = {}              # battle-only runtime (equipment passives)
        self.crit_bag = None      # D119: dict(p, left=[bool marbles]) while the fighter has a crit chance
        self.bags = {}            # D126: the other marble bags (status chances "status_<id>", rule chances "rule_<label>") and the move deck "deck"
        # enemy
        self.enemy_id = -1
        self.rank = 1
        self.is_boss = False
        self.elite = ""
        self.basic_power = 3
        self.skills_e = []
        self.brain = None
        self.stagger = 0
        self.smax = 0
        self.broken = False
        self.base_exp = 0
        self.ai = None


def st_find(f, sid):
    for s in f.status:
        if s["id"] == sid:
            return s
    return None


def st_has(f, sid):
    return st_find(f, sid) is not None


def st_stacks(f, sid):
    s = st_find(f, sid)
    return 0 if s is None else s["stacks"]


class Rules:
    """The rules bound to one Data: every function that needs the status table or the item table lives here."""

    def __init__(self, data):
        self.d = data
        self.sdb = data.status
        self.items = data.items
        self.skills = data.skills

    # ---- statuses ----
    def status_remove(self, f, sid):
        f.status = [s for s in f.status if s["id"] != sid]

    def status_add(self, f, sid, turns, power, stacks=1):
        cfg = self.sdb[sid]
        if cfg.get("crit_bonus", 0) > 0:
            f.crit_bag = None   # D119: applying (or re-applying) a crit buff starts a fresh bag
        dot = cfg.get("dot_kind", "")
        max_stacks = cfg.get("max_stacks", 1)
        add = max(1, stacks)
        fresh = cfg.get("no_tick_on_apply", False)
        cur = st_find(f, sid)
        if cur is not None:
            if dot == "poison":
                cur["stacks"] = ref.poison_add(cur["stacks"], add)
                cur["turns"] = cur["stacks"]
            elif dot == "bleed":
                cur["stacks"] = min(max_stacks, cur["stacks"] + add)
                cur["turns"] = max(cur["turns"], turns)
            elif dot == "burn":
                cur["turns"] = max(cur["turns"], turns)
                cur["power"] = power
            else:
                cur["turns"] = max(cur["turns"], turns)
                cur["power"] = max(cur["power"], power)
            if fresh:
                cur["fresh"] = True
            return
        e = dict(id=sid, turns=turns, power=power, stacks=1, fresh=False)
        if dot in ("poison", "bleed"):
            e["stacks"] = min(max_stacks, add)
            if dot == "poison":
                e["turns"] = e["stacks"]
        if fresh:
            e["fresh"] = True
        f.status.append(e)

    def status_mul(self, f, field):
        m = 1.0
        for s in f.status:
            v = self.sdb[s["id"]].get(field)
            if v is not None:
                m *= v
        return m

    def status_sum(self, f, field):
        t = 0
        for s in f.status:
            t += self.sdb[s["id"]].get(field, 0)
        return t

    def status_flag(self, f, field):
        for s in f.status:
            if self.sdb[s["id"]].get(field):
                return True
        return False

    def consume(self, f, field):
        f.status = [s for s in f.status if not self.sdb[s["id"]].get(field)]

    def is_negative(self, sid):
        return sid in (POISON, BLEED, BURN, STUN, SUNDER)

    def dot_damage(self, s, acted=True):
        cfg = self.sdb[s["id"]]
        k = cfg.get("dot_kind")
        if k == "poison":
            return s["stacks"]
        if k == "burn":
            return max(0, s["power"])
        if k == "bleed":
            return ref.bleed_tick(s["stacks"]) if acted else 0
        return 0

    def status_hp_tick(self, f, s, acted):
        cfg = self.sdb[s["id"]]
        if "dot_kind" in cfg:
            dmg = self.dot_damage(s, acted)
            if dmg:
                f.hp = max(0, f.hp - dmg)

    def action_tick(self, f):
        for s in list(f.status):
            if self.sdb[s["id"]].get("dot_kind") == "bleed":
                self.status_hp_tick(f, s, True)

    def tick(self, f, rng, acted=True):
        """Status_Tick: once per turn of the owner."""
        for s in list(f.status):
            if s.get("fresh"):
                s["fresh"] = False
                continue
            cfg = self.sdb[s["id"]]
            self.status_hp_tick(f, s, acted)
            t = cfg.get("tick", {})
            lo, hi = t.get("mp_min", 0), t.get("mp_max", 0)
            if lo or hi:
                f.mp = min(f.mmp, max(0, f.mp + tick_amount(min(lo, hi), max(lo, hi))))   # D126: the exact average
            if cfg.get("dot_kind") == "poison":
                s["stacks"] -= 1
                s["turns"] = s["stacks"]
                if s["stacks"] <= 0:
                    f.status.remove(s)
            else:
                s["turns"] -= 1
                if s["turns"] <= 0:
                    f.status.remove(s)

    # ---- stats ----
    def equip_bonus(self, f, k):
        if not f.is_player:
            return 0
        tot = 0
        for slot in ("weapon", "armor", "accessory"):
            iid = f.equip.get(slot, 0)
            if iid:
                tot += self.items[iid]["bonus"][KEY[k]]
        return tot

    def eff(self, f, k):
        """Combat_EffectiveStat: base + equipment + flat status mods, times the status multipliers, at least 1."""
        v = f.st[k] + self.equip_bonus(f, k)
        m = 1.0
        for s in f.status:
            cfg = self.sdb[s["id"]]
            v += cfg["stat_mods"][KEY[k]] if "stat_mods" in cfg else 0
            sm = cfg.get("stat_mult")
            if sm:
                m *= sm[KEY[k]]
        if m != 1.0:
            v = rhu(v * m)
        return max(1, int(round(v)))

    def passive_sum(self, f, key):
        t = 0
        for pid in f.passives:
            c = self.d.cards[pid]
            if key in c["params"]:
                t += c["params"][key]
        return t

    def weapon(self, f):
        w = f.equip.get("weapon", 0)
        return self.items[w] if w else None

    def weapon_power(self, f):
        w = self.weapon(f)
        return w["power"] if w else self.d.const["unarmed_power"]

    def resources(self, f):
        f.mhp = ref.hp_max(f.hd, f.level) + getattr(f, "hp_bonus", 0)   # D143: + the Max HP bought with free points
        f.mmp = ref.mp_max(f.mp_gain, f.level, f.st["mag"]) + getattr(f, "mp_bonus", 0)
        f.hp = min(f.hp, f.mhp)
        f.mp = min(f.mp, f.mmp)

    # ---- skills as the player holds them (Card_ApplyToSkill) ----
    def player_skill(self, f, sid):
        s = dict(self.skills[sid])
        if sid in f.upgrades:
            up = self.d.cards["up:%d" % sid]["up"]
            if "power" in up:
                s["power"] += up["power"]
            if "mp_cost" in up:
                s["mp_cost"] = max(0, s["mp_cost"] + up["mp_cost"])
            if "status_turns" in up:
                s["status_turns"] += up["status_turns"]
            if "status_stacks" in up:
                s["status_stacks"] = s.get("status_stacks", 1) + up["status_stacks"]
            if "status_chance" in up:
                s["status_chance"] = min(1, s["status_chance"] + up["status_chance"])
        bonus = round(self.passive_sum(f, "skill_power"))
        if bonus > 0 and s["effect"] == "damage":
            s["power"] += bonus
        less = round(self.passive_sum(f, "mp_cost_less"))
        if less > 0 and s["mp_cost"] > 0:
            s["mp_cost"] = max(1, s["mp_cost"] - less)
        return s

    def seq_len(self, f, sid):
        n = self.skills[sid].get("sequence_length", 3)
        if sid in f.upgrades:
            trim = self.d.cards["up:%d" % sid]["up"].get("seq_trim", 0)
            n = max(1, n - trim)
        return n


# ---------------------------------------------------------------------------------------------------------------------------------
# Building fighters
# ---------------------------------------------------------------------------------------------------------------------------------
def new_player(R, class_id):
    c = R.d.classes[class_id]
    p = F(CLASS_NAMES[class_id], True)
    p.class_id = class_id
    p.level = 1
    p.hd = c["hd"]
    p.mp_gain = c["mp_gain"]
    s = c["stats"]
    p.st = dict(atk=s["atk"], df=s["def"], spd=s["spd"], mag=s["mag"])
    R.resources(p)
    p.hp, p.mp = p.mhp, p.mmp
    return p


def level_stats(R, p, class_id, level):
    """The stats the game gives at `level`: fixed growth + the auto-placed free point (by_level of the export), plus the stat passives held."""
    row = R.d.classes[class_id]["by_level"][level - 1]
    st = dict(atk=row["atk"], df=row["def"], spd=row["spd"], mag=row["mag"])
    # a free point placed on another stat than the class default (Whetstone etc.) is carried in p.extra
    for k, v in getattr(p, "extra", {}).items():
        st[k] += v
    return st


def make_enemy(R, eid, level, elite=""):
    cfg = R.d.enemies[eid]
    e = F(cfg["name_en"] if "name_en" in cfg else cfg["name"], False)
    e.enemy_id = eid
    e.level = level
    s = cfg["stats"]
    e.st = dict(atk=max(1, s["atk"]), df=max(1, s["def"]), spd=max(1, s["spd"]), mag=max(1, s["mag"]))
    e.hd = cfg["hd"]
    e.mhp = max(1, cfg["base_hp"] + (level - 1) * (math.ceil(cfg["hd"] / 2) + 1))
    e.hp = e.mhp
    e.basic_power = cfg["basic_power"]
    e.skills_e = list(cfg["skills"])
    e.rank = cfg["threat_rank"]
    e.is_boss = cfg["is_boss"]
    e.base_exp = max(1, round(cfg["exp"] * min(1.4, max(0.7, 1 + (level - cfg["level"]) * 0.10))))
    e.brain = cfg["brain"]
    e.smax = ref.stagger_max(e.rank, e.is_boss)
    bm = R.d.tl.get("boss_stagger_mult")   # a PROPOSED constant (the game hard-codes 2): the boss meter is (4 + 4 x rank) x this
    if e.is_boss and bm:
        e.smax = int(round((4 + 4 * e.rank) * bm))
    em = R.d.tl.get("elite_stagger_mult")  # PROPOSED: elites' meters
    if elite and em:
        e.smax = int(round(e.smax * em))
    e.elite = elite
    if elite:
        m = R.d.eco.get("elite_hp_mult", 1.0)   # a PROPOSED constant (the game has none yet): 1.0 = as today
        if m != 1.0:
            e.mhp = max(1, int(round(e.mhp * m)))
            e.hp = e.mhp
    if elite == "armored":
        e.st["df"] += R.d.eco["elite_def"]
    elif elite == "swift":
        e.st["spd"] += R.d.eco["elite_spd"]
    elif elite == "brutal":
        e.st["atk"] += R.d.eco["elite_atk"]
    e.ai = dict(turns=0, phase=0, uses={}, windup=-1)
    return e


def ai_phase_for(brain, ratio):
    n = 0
    for i, ph in enumerate(brain["phases"]):
        if ph["at"] + 1e-6 >= ratio:
            n = i + 1
    return n


def ai_phase_sync(e):
    target = ai_phase_for(e.brain, e.hp / e.mhp if e.mhp else 1)
    if target <= e.ai["phase"]:
        return False
    for k in range(e.ai["phase"] + 1, target + 1):
        ph = e.brain["phases"][k - 1]
        e.st["spd"] += ph["spd_add"]
        e.st["atk"] += ph["atk_add"]
    e.ai["phase"] = target
    return True


# ---------------------------------------------------------------------------------------------------------------------------------
# One battle
# ---------------------------------------------------------------------------------------------------------------------------------
class Battle:
    def __init__(self, R, p, e, profile, rng, policy, ctx):
        self.R = R
        self.p = p
        self.e = e
        self.rng = rng
        self.policy = policy
        self.ctx = ctx
        self.probs = PROFILES[profile] if isinstance(profile, str) else profile
        self.gauge = [0, 0]      # player, enemy
        self.steadfast = [0, 0]
        self.p_turns = 0
        self.e_actions = 0
        self.p_actions = 0
        self.defences = 0
        self.log = {}
        self.p_turn_counter = 0
        self.windup_pending = False
        self.rt = dict(first_impact_used=False, brace_ready=False, brace_cd=0, once_turn=False)
        p.rt = self.rt
        self.hp_start = p.hp
        self.mp_start = p.mp

    # ---- QTE grades ----
    def grade_probs(self, widen=1.0):
        pr = self.probs
        if widen > 1.0 and pr[0] < 1.0:
            top = min(1.0, pr[0] * widen)
            rest = 1.0 - top
            tot = pr[1] + pr[2] + pr[3]
            if tot <= 0:
                return (top, rest, 0.0, 0.0)
            return (top, rest * pr[1] / tot, rest * pr[2] / tot, rest * pr[3] / tot)
        return pr

    def p_widen(self):
        w = 1.0 + self.R.passive_sum(self.p, "perfect_widen")
        w *= max(1.0, self.R.status_mul(self.p, "perfect_widen"))
        return w

    def draw_grade(self):
        pr = self.grade_probs(self.p_widen())
        r = self.rng.random()
        acc = 0.0
        for g, q in zip(GRADES, pr):
            acc += q
            if r < acc:
                return g
        return "WEAK"

    # ---- timeline (spec section 11) ----
    def tl_next(self):
        R = self.R
        spd = [max(1, R.eff(self.p, "spd")), max(1, R.eff(self.e, "spd"))]
        g = self.gauge
        gm = R.d.tl["gauge_max"]
        if g[0] < gm and g[1] < gm:
            ticks = min(max(1, -(-(gm - g[0]) // spd[0])), max(1, -(-(gm - g[1]) // spd[1])))
            g[0] += spd[0] * ticks
            g[1] += spd[1] * ticks
        who = 0
        if g[1] >= gm and (g[0] < gm or g[1] > g[0]):
            who = 1
        g[who] -= gm
        self.steadfast[who] = max(0, self.steadfast[who] - 1)
        return who

    def tl_stun(self, who):
        if self.steadfast[who] > 0:
            return False
        gm = self.R.d.tl["gauge_max"]
        boss = (who == 1 and self.e.is_boss)
        self.gauge[who] -= int(gm * self.R.d.tl["boss_push"]) if boss else gm
        self.steadfast[who] = self.R.d.tl["steadfast_turns"]
        return True

    def resolve_stun(self):
        for who, f in ((1, self.e), (0, self.p)):
            if st_has(f, STUN):
                self.R.status_remove(f, STUN)
                self.tl_stun(who)

    def stagger_hit(self, power, stun, perfect, hits=1):
        e = self.e
        if e.hp <= 0:
            return
        gain = ref.stagger_gain(power, stun, perfect) * max(1, hits)
        if e.broken or e.smax <= 0:
            return
        e.stagger = min(e.smax, e.stagger + gain)
        if e.stagger < e.smax:
            return
        e.stagger = 0
        e.broken = True
        self.gauge[1] -= self.R.d.tl["gauge_max"]
        self.log["breaks"] = self.log.get("breaks", 0) + 1
        w = e.ai["windup"]
        if w >= 0:
            e.ai["windup"] = -1
            self.windup_pending = False
            self.log["windups_broken"] = self.log.get("windups_broken", 0) + 1

    # ---- damage (Combat_ApplyDamage) ----
    def hit(self, att, dfn, power, stat, grade_mult=1.0, crit=False, skill_mult=1.0):
        R = self.R
        mult = R.status_mul(att, "dmg_mult") * (2.0 if crit else 1.0) * skill_mult
        guard = R.status_mul(dfn, "guard_mult")
        if guard != 1.0:
            mult *= guard
            R.consume(dfn, "consume_on_hit")
        if dfn.broken:
            mult *= R.d.tl["break_mult"]
        dmg = ref.damage(power, R.eff(att, stat), R.eff(dfn, "df"), grade_mult, mult)
        if dfn.is_player and dmg > 0:
            dmg = self.player_reduce(dfn, dmg, att)
        dfn.hp = max(0, dfn.hp - dmg)
        if dfn.is_player and dmg > 0:
            if self.has_passive(dfn, "brace") and not self.rt["brace_ready"] and self.rt["brace_cd"] <= 0:
                self.rt["brace_ready"] = True
            if att.elite == "venomous":
                R.status_add(dfn, POISON, 1, 1, R.d.eco["elite_venom_stacks"])
        return dmg

    def has_passive(self, f, pid):
        for slot in ("weapon", "armor", "accessory"):
            iid = f.equip.get(slot, 0)
            if iid and self.R.items[iid].get("passive_id") == pid:
                return True
        return False

    def passive_param(self, f, pid, key, default):
        for slot in ("weapon", "armor", "accessory"):
            iid = f.equip.get(slot, 0)
            if iid and self.R.items[iid].get("passive_id") == pid:
                return self.R.items[iid]["passive_params"].get(key, default)
        return default

    def player_reduce(self, p, dmg, att, is_skill=False):
        """Equip_PlayerIncomingDamageReduction for the armour/accessory passives that do arithmetic (the rest is not modelled)."""
        fd = dmg
        rt = self.rt
        if rt["brace_ready"]:
            fd = math.floor(fd * self.passive_param(p, "brace", "guard_mult_next_hit", 0.6))
            rt["brace_ready"] = False
            rt["brace_cd"] = 2
        if self.has_passive(p, "first_impact") and not rt["first_impact_used"]:
            fd -= 3
            rt["first_impact_used"] = True
        if self.has_passive(p, "debt_plate") and fd >= 6:
            fd = math.floor(fd * 0.70)
        if not is_skill and fd > 0 and self.has_passive(p, "thin_veil"):
            fd += 1
        red = self.passive_param(p, "hardened", "damage_reduction", 0)
        if red > 0:
            fd = math.floor(fd * (1 - red))
        return max(0, fd)

    def bonus_damage(self, p, e, dealt, is_skill):
        """Weapon/armour passives that add damage after the hit (Executioner, Predator, Ember Lens...)."""
        add = 0.0
        if self.has_passive(p, "executioner") and e.hp > 0 and e.hp / e.mhp < self.passive_param(p, "executioner", "hp_ratio", 0.35):
            add += dealt * (self.passive_param(p, "executioner", "mult", 1.35) - 1)
        if self.has_passive(p, "predator") and e.status:
            add += dealt * (self.passive_param(p, "predator", "mult", 1.3) - 1)
        if is_skill:
            for pid in ("ember_lens", "arcane_surge", "silk_flow"):
                if self.has_passive(p, pid):
                    add += dealt * (self.passive_param(p, pid, "skill_mult", 1.0) - 1)
        add = int(add)
        if add > 0:
            add = min(add, e.hp)
            e.hp -= add
        return add

    # ---- player actions ----
    def status_turns(self, user, target, sid, base_turns):
        R = self.R
        turns = max(1, int(round(base_turns)))
        if sid == STUN:
            return turns
        fixed = R.sdb[sid].get("duration", 0)
        if fixed > 0:
            turns = fixed   # a fixed-duration status ignores the skill's own turns (this is why Foresight+ "+2 turns" does nothing)
        if user.is_player and not target.is_player and sid != POISON:
            turns += self.equip_status_turn_bonus(user)
            turns += max(0, int(round(R.passive_sum(user, "status_turn_bonus"))))
        if user.is_player and target.is_player and sid == GUARD:
            turns += max(0, int(round(R.passive_sum(user, "guard_turns"))))
        return max(1, turns)

    def equip_status_turn_bonus(self, p):
        b = 0
        for pid in ("ember_lens", "silk_flow"):
            if self.has_passive(p, pid):
                b += int(self.passive_param(p, pid, "status_turn_bonus", 0))
        return b

    def status_stacks(self, user, target, sid, base):
        s = max(1, int(round(base)))
        if sid == POISON and user.is_player and not target.is_player:
            s += self.equip_status_turn_bonus(user)
            s += max(0, int(round(self.R.passive_sum(user, "poison_stacks"))))
        return s

    def apply_status(self, user, target, sid, base_turns, base_stacks=1):
        R = self.R
        power = ref.burn_tick(R.eff(user, "mag")) if sid == BURN else 1
        turns = self.status_turns(user, target, sid, base_turns)
        stacks = self.status_stacks(user, target, sid, base_stacks)
        R.status_add(target, sid, turns, power, stacks)

    def crit_roll(self, f):
        c = ref.crit_chance(self.R.status_sum(f, "crit_bonus"))
        if c <= 0:
            return False
        bag = f.crit_bag   # D119: a bag of marbles, drawn without putting them back; refilled when empty or when the chance changed
        if bag is None or not bag["left"] or bag["p"] != c:
            n, reds = crit_bag_size(c)
            left = [True] * reds + [False] * (n - reds)
            self.rng.shuffle(left)
            bag = f.crit_bag = dict(p=c, left=left)
        return bag["left"].pop()

    def status_roll(self, user, sid, chance, slot=""):
        """D126 Skill_StatusRoll: does the status of this skill land? One bag per skill per user (per status for Curse)."""
        return bag_draw(user.bags, "status_%s%s" % (sid, slot), chance, self.rng)

    def use_skill(self, user, target, sid, grade="OK"):
        """Skill_Use for either side. Returns dict(dmg, hit, free, defended_info)."""
        R = self.R
        s = R.player_skill(user, sid) if user.is_player else R.skills[sid]
        res = dict(dmg=0, hit=True, free=bool(s.get("free_action")), crit=False, status_ids=[], before=None)
        gm = R.d.grade_mult[grade] if user.is_player else 1.0
        if user.is_player:
            user.mp -= s["mp_cost"]
        eff = s["effect"]
        if eff == "status":
            if s["status"] != -1:
                self.apply_status(user, target if s["target"] != 1 else user, s["status"], s.get("status_turns", 1), s.get("status_stacks", 1))
            return res
        if eff == "multi_status":
            ch = s.get("status_chance", 1)
            turns = s.get("status_turns_list", [])
            stacks = s.get("status_stacks_list", [])
            for i, sid_m in enumerate(s["status_list"]):
                if not self.status_roll(user, sid, ch, "_%d" % i):
                    continue
                self.apply_status(user, target, sid_m, turns[i] if i < len(turns) else s.get("status_turns", 1), stacks[i] if i < len(stacks) else 1)
            return res
        if eff == "dispel":
            target.status = [x for x in target.status if R.is_negative(x["id"])]
            return res
        if eff == "steal_item":
            res["steal"] = True
            return res
        if eff == "heal":
            amt = ref.heal(s["power"], R.eff(user, "mag" if s["stat_type"] == 3 else "atk"))
            target.hp = min(target.mhp, target.hp + amt)
            res["dmg"] = -amt
            return res
        # damage
        hits = max(1, s.get("hits", 1))
        wp = R.weapon_power(user) if user.is_player else 0
        power = ref.power_skill(s["power"], s.get("power_mult", 1), wp) if user.is_player else ref.power_enemy_skill(s["power"], s.get("power_mult", 1))
        stat = ("atk", "def", "spd", "mag")[s["stat_type"]]
        total = 0
        any_hit = False
        any_crit = False
        for _ in range(hits):
            if not user.is_player and target.is_player and R.status_flag(target, "force_dodge"):
                R.consume(target, "consume_on_defend")
                continue
            crit = self.crit_roll(user)
            d = self.hit(user, target, power, stat, gm, crit)
            if user.is_player and d > 0:
                d += self.bonus_damage(user, target, d, True)
            total += d
            any_hit = True
            any_crit = any_crit or crit
        res.update(hit=any_hit, dmg=total, crit=any_crit)
        R.consume(user, "consume_on_attack")
        chance = s.get("status_chance", 1)
        if any_hit:
            if s["status"] != -1:
                res["before"] = None
                if self.status_roll(user, sid, chance):
                    res["status_ids"].append(s["status"])
                    self.apply_status(user, target, s["status"], max(1, s.get("status_turns", 1)), s.get("status_stacks", 1))
            if "status_list" in s:
                if self.status_roll(user, sid, chance, "_list"):
                    tl = s.get("status_turns_list", [])
                    for i, sid_d in enumerate(s["status_list"]):
                        res["status_ids"].append(sid_d)
                        self.apply_status(user, target, sid_d, tl[i] if i < len(tl) else max(1, s.get("status_turns", 1)), 1)
        res["power"] = power
        res["hits"] = hits
        return res

    def skill_applies_stun(self, s):
        return s.get("status") == STUN or STUN in s.get("status_list", [])

    def timing_grade(self):
        g = self.draw_grade()
        p = self.p
        # weapon passives that forgive a grade (once per turn): Steady Strike WEAK->OK, Aim Assist GOOD->PERFECT
        if not self.rt["once_turn"]:
            if g == "WEAK" and self.has_passive(p, "steady_strike"):
                g = "OK"
                self.rt["once_turn"] = True
            elif g == "GOOD" and self.has_passive(p, "aim_assist"):
                g = "PERFECT"
                self.rt["once_turn"] = True
        return g

    def p_basic(self):
        R, p, e = self.R, self.p, self.e
        g = self.timing_grade()
        w = R.weapon(p)
        wp = w["power"] if w else R.d.const["unarmed_power"]
        stat = ("atk", "def", "spd", "mag")[w["stat_type"]] if w else "atk"
        power = ref.power_basic(wp)
        crit = self.crit_roll(p)
        d = self.hit(p, e, power, stat, R.d.grade_mult[g], crit)
        d += self.bonus_damage(p, e, d, False)
        R.consume(p, "consume_on_attack")
        self.count("basic")
        if e.hp > 0:
            self.stagger_hit(power, False, g == "PERFECT")
        return d

    def count(self, key):
        self.log["use_" + key] = self.log.get("use_" + key, 0) + 1

    def p_skill(self, sid):
        R, p, e = self.R, self.p, self.e
        g = self.draw_grade()
        s = R.player_skill(p, sid)
        target = p if s["target"] == 1 else e
        res = self.use_skill(p, target, sid, g)
        self.count("skill_%d" % sid)
        if e.hp > 0 and s["target"] != 1 and res["hit"]:
            if res["dmg"] > 0:
                self.stagger_hit(res["power"], self.skill_applies_stun(s), g == "PERFECT", res["hits"])
            self.resolve_stun()
        return res

    def p_throw(self, iid):
        R, p, e = self.R, self.p, self.e
        item = R.items[iid]
        u = item["use"]
        g = self.draw_grade()
        gm = R.d.grade_mult[g]
        nm = R.d.eco["throw_nobody_mult"] if p.class_id == 3 else 1.0
        p.inv[iid] -= 1
        if p.inv[iid] <= 0:
            del p.inv[iid]
        self.count("throw_%d" % iid)
        stat_val = R.d.eco["throw_stat_base"] + p.level
        dmg = 0
        if u["power"] > 0:
            mult = nm * (R.d.tl["break_mult"] if e.broken else 1.0)
            guard = R.status_mul(e, "guard_mult")
            if guard != 1.0:
                mult *= guard
                R.consume(e, "consume_on_hit")
            dmg = ref.damage(ref.power_basic(u["power"]), stat_val, R.eff(e, "df"), gm, mult)
            e.hp = max(0, e.hp - dmg)
        if u["burn_turns"] > 0 and e.hp > 0:
            base = rhu(ref.burn_tick(stat_val) * nm)
            burn = qte_scale(base, gm, 1)
            R.status_add(e, BURN, u["burn_turns"], burn)
        if u["stacks"] > 0:
            n = rhu(u["stacks"] * nm)
            st = n + 1 if g == "PERFECT" else (max(1, n - 1) if g == "WEAK" else n)
            R.status_add(e, POISON, st, 1, st)
        stun = False
        if u["stun"] and g != "WEAK" and e.hp > 0:
            R.status_add(e, STUN, 1, 1)
            stun = True
        if u["evade_turns"] > 0:
            R.status_add(p, EVASION, qte_scale(rhu(u["evade_turns"] * nm), gm, 1), 1)
        if e.hp > 0:
            if dmg > 0:
                self.stagger_hit(ref.power_basic(u["power"]), stun, g == "PERFECT")
            self.resolve_stun()
        return dmg

    def p_item(self, iid):
        R, p = self.R, self.p
        it = R.items[iid]
        u = it["use"]
        eff = u["effect"]
        if eff in ("heal", "mp"):
            amt = item_amount(R, p, u, self.rng)
            if eff == "heal":
                p.hp = min(p.mhp, p.hp + amt)
                mpb = round(R.passive_sum(p, "potion_mp"))
                if mpb > 0:
                    p.mp = min(p.mmp, p.mp + mpb)
            else:
                p.mp = min(p.mmp, p.mp + amt)
        elif eff == "cure":
            p.status = [s for s in p.status if s["id"] != u["status"]]
        p.inv[iid] -= 1
        if p.inv[iid] <= 0:
            del p.inv[iid]
        self.count("item_%d" % iid)

    # ---- enemy AI (EnemyAI_Choose) ----
    def cond_holds(self, c, e, p, turn):
        k = c["c"]
        er = e.hp / e.mhp if e.mhp else 1
        if k == "always":
            return True
        if k == "hp_below":
            return er <= c["v"] + 1e-6
        if k == "hp_above":
            return er >= c["v"] - 1e-6
        if k == "player_hp_below":
            return p.hp / p.mhp <= c["v"] + 1e-6
        if k == "player_buffed":
            return any(not self.R.is_negative(s["id"]) for s in p.status)
        if k == "player_has_status":
            return st_has(p, c["status"])
        if k == "player_missing_status":
            return not st_has(p, c["status"])
        if k == "player_status_at_least":
            return st_stacks(p, c["status"]) >= c["v"]
        if k == "self_has_status":
            return st_has(e, c["status"])
        if k == "self_missing_status":
            return not st_has(e, c["status"])
        if k == "every_nth":
            return c["v"] >= 2 and (turn % c["v"]) == 0
        return False

    def usable(self, e, p, act, skill, used_turn):
        if act == "attack":
            return True
        if act != "skill" or skill not in e.skills_e:
            return False
        sk = self.R.skills[skill]
        if sk.get("enemy_passive_action_budget"):
            return False
        if sk.get("enemy_once_per_turn") and skill in used_turn:
            return False
        if "enemy_hp_below_ratio" in sk and (e.hp / e.mhp > min(1, sk["enemy_hp_below_ratio"])):
            return False
        if "enemy_hp_above_ratio" in sk and (e.hp / e.mhp < sk["enemy_hp_above_ratio"]):
            return False
        if sk.get("enemy_require_target_inventory") and not p.inv:
            return False
        if "enemy_require_status_missing" in sk and sk["enemy_require_status_missing"] != -1 and st_has(e, sk["enemy_require_status_missing"]):
            return False
        if "enemy_require_actions_below" in sk and 1 >= sk["enemy_require_actions_below"]:
            return False
        return True

    def ai_choose(self, e, p, used_turn):
        ai = e.ai
        if ai["windup"] >= 0:
            return ("skill", ai["windup"], "windup_attack")
        b = e.brain
        ph = ai["phase"]
        lists = b["phases"][ph - 1] if 1 <= ph <= len(b["phases"]) else b
        turn = ai["turns"] + 1
        for r in lists["rules"]:
            if not all(self.cond_holds(c, e, p, turn) for c in r["when"]):
                continue
            if r["max_uses"] >= 0 and ai["uses"].get(r["label"], 0) >= r["max_uses"]:
                continue
            if not self.usable(e, p, r["act"], r["skill"], used_turn):
                continue
            if r["chance"] < 1 and not bag_draw(e.bags, "rule_%s" % r["label"], r["chance"], self.rng):   # D126: a rule's chance is a bag too
                continue
            return self.result(r["act"], r["skill"], r["label"])
        # D126: the weighted default is a shuffled deck of the whole-number weights of the usable moves, kept on the enemy
        elig = [w for w in lists["weights"] if w["w"] > 0 and self.usable(e, p, w["act"], w["skill"], used_turn)]
        if not elig:
            return ("attack", -1, "default")
        ints = int_weights([w["w"] for w in elig])
        sig = tuple((w["act"], w["skill"], n) for w, n in zip(elig, ints))
        deck = e.bags.get("deck")
        if deck is None or deck["sig"] != sig or not deck["left"]:
            cards = [w for w, n in zip(elig, ints) for _ in range(n)]
            self.rng.shuffle(cards)
            deck = e.bags["deck"] = dict(sig=sig, left=cards)
        w = deck["left"].pop()
        return self.result(w["act"], w["skill"], "default")

    def result(self, act, skill, label):
        if act == "skill" and self.R.skills[skill].get("telegraphed"):
            return ("windup", skill, label)
        return ("skill" if act == "skill" else "attack", skill if act == "skill" else -1, label)

    def defence_adjust(self, p, status_ids, before, grade):
        """Battle_DefenceAdjustStatuses: the defence grade can only shorten or reduce what the hit added."""
        R = self.R
        for sid in status_ids:
            cur = st_find(p, sid)
            if cur is None:
                continue
            b = before.get(sid)
            bt = b["turns"] if b else 0
            bs = b["stacks"] if b else 0
            ns = cur["stacks"]
            cfg = R.sdb[sid]
            is_poison = cfg.get("dot_kind") == "poison"
            added = max(0, ns - bs)
            if not (cur["turns"] > bt or added > 0 or b is None):
                continue
            kept = defence_turns(grade, added if is_poison else cur["turns"])
            if kept <= 0:
                if b:
                    cur["turns"], cur["stacks"], cur["power"] = b["turns"], b["stacks"], b["power"]
                else:
                    R.status_remove(p, sid)
                continue
            if is_poison:
                cur["stacks"] = bs + min(added, kept)
                cur["turns"] = cur["stacks"]
            else:
                cur["turns"] = min(cur["turns"], max(bt, kept))

    def enemy_action(self, used_turn):
        """One enemy action. Returns True when the enemy's turn is over (a free action returns False)."""
        R, p, e = self.R, self.p, self.e
        if ai_phase_sync(e):
            pass
        kind, sid, label = self.ai_choose(e, p, used_turn)
        ai = e.ai
        if label not in ("default", "windup_attack"):
            ai["uses"][label] = ai["uses"].get(label, 0) + 1
        self.e_actions += 1
        if kind == "windup":
            ai["windup"] = sid
            self.windup_pending = True
            self.log["windups"] = self.log.get("windups", 0) + 1
            return True
        if label == "windup_attack":
            ai["windup"] = -1
            self.windup_pending = False
        if kind == "attack":
            if R.status_flag(p, "force_dodge"):
                R.consume(p, "consume_on_defend")
                dmg = 0
                self.log["dodged"] = self.log.get("dodged", 0) + 1
            else:
                crit = self.crit_roll(e)
                dmg = self.hit(e, p, float(e.basic_power), "atk", 1.0, crit)
            R.consume(e, "consume_on_attack")
            self.log["dmg_taken"] = self.log.get("dmg_taken", 0) + dmg
            return True
        sk = R.skills[sid]
        used_turn.append(sid)
        before = {s["id"]: dict(s) for s in p.status}
        hp_before = p.hp
        res = self.use_skill(e, p if sk["target"] != 1 else e, sid)
        if sk["effect"] == "steal_item":
            self.log["steals"] = self.log.get("steals", 0) + 1   # the item comes back when the enemy dies; only the action is lost
        if sk["target"] != 1 and sk["effect"] == "damage":
            if sk.get("uses_defensive_qte") and res["hit"] and res["dmg"] > 0:
                g = self.draw_grade()
                self.defences += 1
                final = qte_scale(res["dmg"], R.d.def_mult[g], 0)
                p.hp = max(0, min(p.mhp, hp_before - final))
                self.defence_adjust(p, res["status_ids"], before, g)
                self.log["def_" + g] = self.log.get("def_" + g, 0) + 1
                res["dmg"] = final
            self.log["dmg_taken"] = self.log.get("dmg_taken", 0) + res["dmg"]
            self.resolve_stun()
        free = res["free"]
        if free:
            return False
        return True

    def enemy_turn(self):
        R, e, p = self.R, self.e, self.p
        used = []
        # Elite_Regen at the start of the turn
        if e.elite == "regenerating" and e.hp > 0:
            amt = min(max(2, rhu(e.mhp * R.d.eco["elite_regen_frac"])), e.mhp - e.hp)
            e.hp += amt
        while True:
            done = self.enemy_action(used)
            if p.hp <= 0 or e.hp <= 0:
                return
            if not done:
                R.action_tick(e)   # a free action (Blessing) is not the end of the turn: bleeding still hurts after it
                if e.hp <= 0:
                    return
                continue
            break
        e.ai["turns"] += 1
        R.tick(e, self.rng, True)

    def player_turn_start(self):
        R, p = self.R, self.p
        self.p_turn_counter += 1
        self.rt["once_turn"] = False
        if self.rt["brace_cd"] > 0:
            self.rt["brace_cd"] -= 1
        # Mana Spring (passive) and equipment mp_gain rings/staffs: +n MP every k turns
        mp = 0
        for pid in p.passives:
            pr = R.d.cards[pid]["params"]
            if "mp_gain" in pr and self.p_turn_counter % max(1, int(pr.get("every_n_turns", 1))) == 0:
                mp += pr["mp_gain"]
        for pid in ("mana_trickle", "ring_mana", "thin_veil"):
            if self.has_passive(p, pid):
                k = self.passive_param(p, pid, "every_n_turns", 2)
                if self.p_turn_counter % k == 0:
                    mp += self.passive_param(p, pid, "mp_gain", 1)
        if mp:
            p.mp = min(p.mmp, p.mp + mp)

    def run(self):
        """Fight until one side is down. Returns True when the player wins."""
        R, p, e = self.R, self.p, self.e
        self.rt["first_impact_used"] = False
        start = int(round(R.passive_sum(p, "start_stagger")))
        if start > 0:
            e.stagger = min(e.smax - 1 if e.smax > 0 else 0, e.stagger + start) if e.smax > 0 else 0
        guard_loops = 0
        while p.hp > 0 and e.hp > 0:
            guard_loops += 1
            if guard_loops > 400:
                return False
            who = self.tl_next()
            if who == 1:
                e.broken = False   # BROKEN lasts until the enemy's next turn starts
                self.enemy_turn()
            else:
                self.player_turn()
        return p.hp > 0

    def player_turn(self):
        R, p, e = self.R, self.p, self.e
        self.player_turn_start()
        self.p_turns += 1
        self.p_actions += 1
        act = self.policy.choose(self)
        kind = act[0]
        if kind == "skill":
            self.p_skill(act[1])
        elif kind == "throw":
            self.p_throw(act[1])
        elif kind == "item":
            self.p_item(act[1])
        else:
            self.p_basic()
        if e.hp <= 0:
            return
        R.tick(p, self.rng, True)


def qte_scale(base, mult, min_result):
    b = int(round(base))
    if b < 1 or mult == 1:
        return b
    r = math.floor(b * mult + 0.5)
    r = max(r, b + 1) if mult > 1 else min(r, b - 1)
    return max(min_result, r)


def defence_turns(grade, turns):
    if turns <= 0:
        return 0
    r = turns
    if grade == "PERFECT":
        return 0
    if grade == "GOOD":
        r = math.floor(turns * 0.5 + 0.5)
    elif grade == "OK":
        r = math.floor(turns * 0.75 + 0.5)
    return max(1, min(turns, r))


def item_amount(R, p, u, rng):
    lo, hi = u.get("min", u.get("power", 0)), u.get("max", u.get("power", 0))
    amt = tick_amount(lo, max(lo, hi))   # D126: a min..max heal gives its exact average
    if "scale" in u:
        amt += math.floor(max(0, p.level - 1) * u["scale"])
    pb = R.passive_sum(p, "item_power")
    if pb > 0:
        amt = max(amt, round(amt * (1 + pb)))
    return amt


# ---------------------------------------------------------------------------------------------------------------------------------
# Expected values (for the policies): no randomness, same formulas
# ---------------------------------------------------------------------------------------------------------------------------------
def exp_damage(power, a, d, mult, probs, grades, crit_p=0.0):
    """Expected damage of one hit over the grade distribution (and a crit chance)."""
    tot = 0.0
    for q, g in zip(probs, GRADES):
        if q <= 0:
            continue
        gm = grades[g]
        base = ref.damage(power, a, d, gm, mult)
        if crit_p > 0:
            base = (1 - crit_p) * base + crit_p * ref.damage(power, a, d, gm, mult * 2.0)
        tot += q * base
    return tot


class Policy:
    """The 'average player': simple, readable, not an optimiser.

    Turn order of ideas (first rule that fires wins):
      1. drink an HP potion when the next enemy hit(s) could kill, or HP is under 30%;
      2. in a hard fight (boss, elite, rank 2+, Stranger) with skills but too little MP for the cheapest one, drink an MP potion;
      3. throw a damaging throwable at a hard fight's start (Nobody throws in every fight: it has nothing else);
      4. use the skill whose value (damage + status + turns saved - MP priced by the fight's difficulty) beats a basic attack;
      5. basic attack.
    """

    def __init__(self, R, mp_price=None):
        self.R = R
        self.mp_price = mp_price or dict(hard=0.30, mid=0.8, easy=1.6)

    # -- enemy threat --
    def enemy_action_values(self, b):
        """[(weight, expected damage to the player, is_windup_attack)] for the enemy's current rule lists (an every-Nth rule counts 1/N)."""
        R, e, p = self.R, b.e, b.p
        brain = e.brain
        ph = e.ai["phase"]
        lists = brain["phases"][ph - 1] if 1 <= ph <= len(brain["phases"]) else brain
        out = []
        rule_share = 0.0
        for r in lists["rules"]:
            nth = [c for c in r["when"] if c["c"] == "every_nth"]
            if nth and r["act"] == "skill":
                w = 1.0 / nth[0]["v"]
                out.append((w, self.enemy_skill_dmg(b, r["skill"]), True))
                rule_share += w
        tot = sum(w["w"] for w in lists["weights"] if w["w"] > 0 and (w["act"] == "attack" or w["skill"] in e.skills_e)) or 1
        for w in lists["weights"]:
            if w["w"] <= 0:
                continue
            share = (1 - rule_share) * w["w"] / tot
            if w["act"] == "attack":
                out.append((share, self.enemy_basic_dmg(b), False))
            elif w["skill"] in e.skills_e:
                out.append((share, self.enemy_skill_dmg(b, w["skill"]), False))
        return out

    def enemy_basic_dmg(self, b):
        R, e, p = self.R, b.e, b.p
        d = ref.damage(float(e.basic_power), R.eff(e, "atk"), R.eff(p, "df"), 1.0, R.status_mul(e, "dmg_mult") * R.status_mul(p, "guard_mult"))
        return d

    def enemy_skill_dmg(self, b, sid):
        R, e, p = self.R, b.e, b.p
        sk = R.skills[sid]
        if sk["effect"] != "damage":
            return 0.0
        power = ref.power_enemy_skill(sk["power"], sk.get("power_mult", 1))
        stat = ("atk", "def", "spd", "mag")[sk["stat_type"]]
        d = ref.damage(power, R.eff(e, stat), R.eff(p, "df"), 1.0, R.status_mul(e, "dmg_mult") * R.status_mul(p, "guard_mult")) * max(1, sk.get("hits", 1))
        if sk.get("uses_defensive_qte"):
            pr = b.grade_probs(b.p_widen())
            d *= sum(q * R.d.def_mult[g] for q, g in zip(pr, GRADES))
        return d

    def enemy_dpa(self, b):
        vals = self.enemy_action_values(b)
        return sum(w * d for w, d, _ in vals)

    def enemy_max_hit(self, b):
        R, e, p = self.R, b.e, b.p
        best = float(ref.damage(float(e.basic_power), R.eff(e, "atk"), R.eff(p, "df"), 1.0, R.status_mul(p, "guard_mult")))
        lists_skills = set(e.skills_e)
        for sid in lists_skills:
            sk = R.skills[sid]
            if sk["effect"] == "damage":
                power = ref.power_enemy_skill(sk["power"], sk.get("power_mult", 1))
                stat = ("atk", "def", "spd", "mag")[sk["stat_type"]]
                best = max(best, float(ref.damage(power, R.eff(e, stat), R.eff(p, "df"), 1.0, R.status_mul(p, "guard_mult")) * max(1, sk.get("hits", 1))))
        return best

    def dot_pending(self, f):
        t = 0
        for s in f.status:
            cfg = self.R.sdb[s["id"]]
            k = cfg.get("dot_kind")
            if k == "poison":
                t += s["stacks"]
            elif k == "burn":
                t += s["power"]
            elif k == "bleed":
                t += ref.bleed_tick(s["stacks"])
        return t

    def difficulty(self, b):
        e = b.e
        if e.is_boss or e.elite or e.enemy_id == 7:
            return "hard"
        if e.rank >= 2:
            return "mid"
        return "easy"

    # -- candidate attack values --
    def attack_options(self, b, with_buffs=True):
        """[(kind, id, score_enemy_hp, mp)] for every action that damages or controls; score in enemy HP."""
        R, p, e = self.R, b.p, b.e
        probs = b.grade_probs(b.p_widen())
        grades = R.d.grade_mult
        crit_p = ref.crit_chance(R.status_sum(p, "crit_bonus"))
        dmgm = R.status_mul(p, "dmg_mult")
        guard = R.status_mul(e, "guard_mult")
        brk = R.d.tl["break_mult"] if e.broken else 1.0
        mult = dmgm * guard * brk
        d_e = R.eff(e, "df")
        out = []
        w = R.weapon(p)
        wp = w["power"] if w else R.d.const["unarmed_power"]
        stat = ("atk", "def", "spd", "mag")[w["stat_type"]] if w else "atk"
        basic = exp_damage(ref.power_basic(wp), R.eff(p, stat), d_e, mult, probs, grades, crit_p)
        out.append(("basic", -1, basic, 0, basic))
        e_dpa = self.enemy_dpa(b)
        my_spd, e_spd = R.eff(p, "spd"), R.eff(e, "spd")
        e_per_p = e_spd / max(1, my_spd)
        exch = basic / max(0.5, e_dpa * e_per_p)       # enemy HP removed per player HP lost
        remaining = max(1.0, e.hp / max(0.5, basic))   # player turns the fight still needs on basic attacks
        self.last_ctx = dict(basic=basic, e_dpa=e_dpa, e_per_p=e_per_p, exch=exch, remaining=remaining)
        for sid in p.skills:
            s = R.player_skill(p, sid)
            if p.mp < s["mp_cost"]:
                continue
            eff = s["effect"]
            score = 0.0
            if eff == "damage":
                wpw = ref.power_skill(s["power"], s.get("power_mult", 1), wp)
                st = ("atk", "def", "spd", "mag")[s["stat_type"]]
                hits = max(1, s.get("hits", 1))
                dd = exp_damage(wpw, R.eff(p, st), d_e, mult, probs, grades, crit_p) * hits
                score = dd
                q = s.get("status_chance", 1) if s["status"] != -1 or "status_list" in s else 0
                sid2 = s["status"]
                turns = b.status_turns(p, e, sid2, s.get("status_turns", 1)) if sid2 != -1 else 0
                if sid2 == POISON:
                    stacks = b.status_stacks(p, e, POISON, s.get("status_stacks", 1))
                    cur = st_stacks(e, POISON)
                    gain = ref.poison_total(min(10, cur + stacks)) - (ref.poison_total(cur) if cur else 0)
                    score += q * min(gain, max(0, e.hp - dd))
                elif sid2 == BURN:
                    tick = ref.burn_tick(R.eff(p, "mag"))
                    score += q * min(tick * turns, max(0, e.hp - dd)) * (0.6 if st_has(e, BURN) else 1.0)
                elif sid2 == BLEED:
                    stk = min(3, st_stacks(e, BLEED) + 1)
                    score += q * min(ref.bleed_tick(stk) * min(turns, remaining * e_per_p), max(0, e.hp - dd))
                elif sid2 == STUN:
                    if b.steadfast[1] <= 0:
                        score += q * e_dpa * exch * (0.5 if e.is_boss else 1.0)
                    stag = ref.stagger_gain(wpw, True, False)
                    score += 0.0
                out.append(("skill", sid, score, s["mp_cost"], dd))
            elif eff == "status" and with_buffs:
                sid2 = s["status"]
                if sid2 == GUARD and not st_has(p, GUARD):
                    nxt = self.next_hit(b)
                    score = nxt * exch * 0.9
                elif sid2 == EVASION and not st_has(p, EVASION):
                    nxt = self.next_hit(b)
                    score = nxt * exch * 0.9
                elif sid2 == DMG_UP and not st_has(p, DMG_UP):
                    score = 0.0   # doubles the next attack but costs the turn: no net gain
                elif sid2 == CRIT_UP and not st_has(p, CRIT_UP):
                    n = min(9, remaining)
                    score = 0.25 * basic * max(0.0, n - 1)
                elif sid2 == MEDITATION and not st_has(p, MEDITATION):
                    n = min(9, remaining)
                    score = 3.0 * n * self.mp_price_of(b) * basic
                elif sid2 == HIT_UP and not st_has(p, HIT_UP):
                    pr2 = b.grade_probs(b.p_widen() * 1.5)
                    gain = exp_damage(ref.power_basic(wp), R.eff(p, stat), d_e, mult, pr2, grades, crit_p) - basic
                    score = gain * 3
                out.append(("skill", sid, score, s["mp_cost"], 0.0))
        return out

    def mp_price_of(self, b):
        base = self.mp_price[self.difficulty(b)]
        p = b.p
        frac = p.mp / p.mmp if p.mmp else 0
        if self.difficulty(b) == "easy" and frac > 0.7:
            base *= 0.6
        # low HP: survival first, MP is worth less
        if p.hp / p.mhp < 0.45:
            base *= 0.5
        return base

    def next_hit(self, b):
        """What the next enemy action will probably do: the pending wind-up attack for sure, else the average."""
        e = b.e
        if e.ai["windup"] >= 0:
            return self.enemy_skill_dmg(b, e.ai["windup"])
        return self.enemy_dpa(b)

    def choose(self, b):
        R, p, e = self.R, b.p, b.e
        diff = self.difficulty(b)
        hp = p.hp
        max_hit = self.enemy_max_hit(b)
        if st_has(p, GUARD) or st_has(p, EVASION):
            max_hit = self.enemy_dpa(b)
        e_acts = max(1.0, R.eff(e, "spd") / max(1, R.eff(p, "spd")))
        danger = max_hit * (1.0 if e_acts < 1.5 else min(2.0, e_acts)) + self.dot_pending(p)
        # 1. heal
        if (hp <= danger * 1.15 or hp < 0.30 * p.mhp):
            it = self.pick_heal(p, p.mhp - hp)
            if it:
                return ("item", it)
        # 2. MP potion in a hard fight when no skill is affordable
        if p.skills and diff != "easy":
            cheapest = min(R.player_skill(p, s)["mp_cost"] for s in p.skills)
            if p.mp < cheapest:
                it = self.pick_mp(p)
                if it:
                    return ("item", it)
        # 3. throwables
        thr = self.pick_throw(b, diff)
        opts = self.attack_options(b)
        ctx = self.last_ctx
        if thr is not None:
            return ("throw", thr)
        # 4. skills
        price = self.mp_price_of(b)
        best = None
        best_val = opts[0][2]   # the basic attack
        for kind, sid, score, mp, dd in opts[1:]:
            val = score - mp * price * ctx["basic"]
            if kind == "skill" and score > 0 and val > best_val:
                best, best_val = ("skill", sid), val
        if best:
            return best
        return ("basic", -1)

    def pick_heal(self, p, missing):
        R = self.R
        best = None
        for iid, n in p.inv.items():
            it = R.items[iid]
            u = it["use"]
            if it["type"] != 2 or u.get("effect") != "heal" or n <= 0:
                continue
            avg = (u["min"] + u["max"]) / 2 + math.floor(max(0, p.level - 1) * u.get("scale", 0))
            pb = R.passive_sum(p, "item_power")
            avg *= (1 + pb)
            # smallest potion that covers most of the gap, else the biggest
            fit = min(avg, missing)
            key = (fit >= 0.7 * missing, -avg if fit >= 0.7 * missing else avg)
            if best is None or key > best[0]:
                best = (key, iid)
        return best[1] if best else None

    def pick_mp(self, p):
        R = self.R
        best = None
        for iid, n in p.inv.items():
            it = R.items[iid]
            u = it["use"]
            if it["type"] != 2 or u.get("effect") != "mp" or n <= 0:
                continue
            avg = (u["min"] + u["max"]) / 2
            if best is None or avg > best[0]:
                best = (avg, iid)
        return best[1] if best else None

    def pick_throw(self, b, diff):
        R, p, e = self.R, b.p, b.e
        if diff == "easy" and p.class_id != 3:
            return None
        cands = [(iid, n) for iid, n in p.inv.items() if R.items[iid].get("throwable") and n > 0 and iid != 33]
        if not cands:
            return None
        # one throw at the start of a hard fight; a Nobody throws whenever it has something and the fight is not nearly done
        if p.class_id != 3:
            if b.p_turns > 1 or e.hp < 0.4 * e.mhp:
                return None
        else:
            if e.hp < 0.25 * e.mhp:
                return None
        best = None
        for iid, n in cands:
            u = R.items[iid]["use"]
            val = u["power"] * 2.0 + u["burn_turns"] * 3 + u["stacks"] * 2.5 + (4 if u["stun"] else 0)
            if iid == 31 and st_stacks(e, POISON) >= 6:
                continue
            if iid == 30 and st_has(e, BURN):
                continue
            if iid == 32 and (b.steadfast[1] > 0):
                continue
            if best is None or val > best[0]:
                best = (val, iid)
        return best[1] if best else None


class BasicOnly(Policy):
    """Used for the per-skill outlier test: never uses skills, potions only to avoid death."""

    def choose(self, b):
        p = b.p
        max_hit = self.enemy_max_hit(b)
        if p.hp <= max_hit * 1.15 or p.hp < 0.3 * p.mhp:
            it = self.pick_heal(p, p.mhp - p.hp)
            if it:
                return ("item", it)
        return ("basic", -1)


# ---------------------------------------------------------------------------------------------------------------------------------
# Expected fight value (for card, gear and shop decisions): the same formulas, no dice
# ---------------------------------------------------------------------------------------------------------------------------------
HP_PER_GOLD = 0.6        # what 1 gold buys, in HP-equivalents (a 12-gold HP potion heals about 8)
MP_VALUE = 0.9           # 1 MP is worth about this many HP (an MP potion costs a bit more than an HP potion)


def exp_fight(R, pol, p, e_proto, probs):
    """Mean-field estimate of one fight: (HP lost, MP spent). The player acts like Policy.choose would, MP-limited, without randomness."""
    e = e_proto
    e = clone_enemy(e)
    pc = clone_player(p)
    pc.status = []
    b = Battle(R, pc, e, probs, random.Random(1), pol, None)
    pc.mp = min(pc.mmp, int(pc.mmp * 0.6) + 2)   # about this much MP is available to one fight (the rest is for the next ones)
    ehp = float(e.hp)
    mp0 = pc.mp
    turns = 0
    while ehp > 0 and turns < 40:
        turns += 1
        opts = pol.attack_options(b, with_buffs=False)
        ctx = pol.last_ctx
        best = opts[0]
        best_val = opts[0][2]
        for o in opts[1:]:
            # the MP a skill costs is priced in the result (MP_VALUE per MP), so the choice itself is made at a small price
            val = o[2] - o[3] * 0.25 * ctx["basic"]
            if o[2] > 0 and val > best_val:
                best, best_val = o, val
        ehp -= best[2]
        pc.mp -= best[3]
        if turns == 1 and ctx["e_per_p"] > 0:
            pass
        mpg = R.passive_sum(pc, "mp_gain")
        pc.mp = min(pc.mmp, pc.mp + mpg)
        # the average enemy's HP is always a fraction of its max: keep the HP ratio for the HP-gated rules roughly right
        e.hp = max(1, int(ehp))
        if turns >= 40:
            break
    ctx = pol.last_ctx
    b.e.hp = e_proto.mhp
    e_dpa = pol.enemy_dpa(b)
    n_e = max(0.0, (turns - 0.5) * ctx["e_per_p"])
    return n_e * e_dpa, max(0, mp0 - pc.mp), turns


def clone_enemy(e):
    c = F(e.name, False)
    c.__dict__.update({k: (dict(v) if isinstance(v, dict) else (list(v) if isinstance(v, list) else v)) for k, v in e.__dict__.items()})
    c.ai = dict(turns=0, phase=0, uses={}, windup=-1)
    c.status = []
    return c


def clone_player(p):
    c = F(p.name, True)
    c.__dict__.update({k: (dict(v) if isinstance(v, dict) else (list(v) if isinstance(v, list) else v)) for k, v in p.__dict__.items()})
    c.status = []
    return c


# ---------------------------------------------------------------------------------------------------------------------------------
# One run
# ---------------------------------------------------------------------------------------------------------------------------------
class RunSim:
    def __init__(self, data, class_name, profile, seed, policy="greedy", rules=None, tweak=None):
        self.d = data
        self.R = rules or Rules(data)
        self.class_id = CLASS_IDS[class_name]
        self.class_name = class_name
        self.profile = profile
        self.probs = PROFILES[profile]
        self.seed = seed
        self.rng = random.Random(seed * 7919 + 17)
        self.pol = BasicOnly(self.R) if policy == "basic" else Policy(self.R)
        self.policy_name = policy
        self.gold = 0
        self.gold_earned = 0
        self.gold_bag = []   # D126: offsets of the fights not paid yet
        self.find_bag = {}   # D126: the Scrounger's marble bag
        self.drop_dry = 0   # D120: enemy fights in a row without a drop
        self.rec = dict(fights=[], picks=[], potions_used=0, mp_potions_used=0, throws=0, shops=[], beds=[], elites=0, card_offers=[], levels={}, buys=[],
                        actions=0, defences=0, item_uses=0, pick_count=0, used_skills={}, card_gain=[])
        self.p = new_player(self.R, self.class_id)
        self.p.inv = {10: 2}
        self.n_fights_done = 0
        self.floor = 1
        self.seed_layout = random.Random(seed * 104729 + 3)

    # ---- helpers ----
    def n_rem(self):
        """Fights still ahead (a rough count for valuing permanent upgrades)."""
        total = 25
        return max(3, total - self.n_fights_done)

    def sync_stats(self):
        """Stats of the current level: the game's class table + stat passives + whetstone points."""
        p, R = self.p, self.R
        row = R.d.classes[p.class_id]["by_level"][p.level - 1]
        st = dict(atk=row["atk"], df=row["def"], spd=row["spd"], mag=row["mag"])
        st["atk"] += int(round(R.passive_sum(p, "stat_atk")))
        st["df"] += int(round(R.passive_sum(p, "stat_def")))
        st["spd"] += int(round(R.passive_sum(p, "stat_spd")))
        st["mag"] += int(round(R.passive_sum(p, "stat_mag")))
        for k, v in p.__dict__.get("extra", {}).items():
            st[ST_KEY.get(k, k)] += v   # the game's stat names (def) are the table's keys (df)
        # D143: a free point placed on Max HP / Max MP is not on the class stat the class table (by_level) counts it on
        hp_pts, mp_pts = p.__dict__.get("hp_pts", 0), p.__dict__.get("mp_pts", 0)
        if hp_pts + mp_pts:
            st[ST_KEY[self.free_stat_key()]] -= hp_pts + mp_pts
        p.hp_bonus = self.d.const.get("free_point_hp_gain", FREE_POINT_HP_GAIN) * hp_pts
        p.mp_bonus = self.d.const.get("free_point_mp_gain", FREE_POINT_MP_GAIN) * mp_pts
        for k in st:
            st[k] = min(60, st[k])
        mhp0, mmp0 = p.mhp, p.mmp
        p.st = st
        R.resources(p)
        p.hp = min(p.mhp, p.hp + max(0, p.mhp - mhp0))
        p.mp = min(p.mmp, p.mp + max(0, p.mmp - mmp0))

    def free_stat_key(self):
        return ("atk", "def", "spd", "mag")[self.R.d.classes[self.p.class_id]["free_default"]]

    def beds_ahead(self):
        """Beds still to come on later floors (each one refills HP and MP to the new maximum)."""
        return sum(v["beds"] for k, v in self.d.layout.items() if float(k) > self.floor)

    def place_free_point(self):
        """D143: the level's free point. The class table (by_level) already counts it on the class stat; Max HP (+3) or Max MP (+2) replaces that when it is
        worth more to the average player, valued like a card pick: the stat and Max MP by the expected-fight value over the fights left, plus the
        points of HP / MP they give now and at every bed to come (Max HP does not change the fight model, so it is only that refill value)."""
        p, R = self.p, self.R
        if not self.d.const.get("free_point_choices", 1):
            return
        n = self.n_rem()
        refills = 1 + self.beds_ahead()
        hp_gain = self.d.const.get("free_point_hp_gain", FREE_POINT_HP_GAIN)
        mp_gain = self.d.const.get("free_point_mp_gain", FREE_POINT_MP_GAIN)
        w = clone_player(p)   # the build without the point on the class stat
        w.st = dict(p.st)
        w.st[ST_KEY[self.free_stat_key()]] -= 1
        R.resources(w)
        base = self.value(w)
        g_stat = (base - self.value(p)) * n
        q = clone_player(w)
        q.mp_bonus = getattr(w, "mp_bonus", 0) + mp_gain
        R.resources(q)
        g_mp = (base - self.value(q)) * n + MP_VALUE * mp_gain * refills
        g_hp = hp_gain * refills
        if max(g_hp, g_mp) <= g_stat:
            return
        if g_hp >= g_mp:
            p.hp_pts = p.__dict__.get("hp_pts", 0) + 1
            self.rec["free_hp"] = self.rec.get("free_hp", 0) + 1
        else:
            p.mp_pts = p.__dict__.get("mp_pts", 0) + 1
            self.rec["free_mp"] = self.rec.get("free_mp", 0) + 1
        self.sync_stats()

    def add_exp(self, amount):
        p, R = self.p, self.R
        if p.level >= 10:
            return 0
        p.exp += amount
        gained = 0
        while p.level < 10 and p.exp >= R.d.exp_next[p.level - 1]:
            p.exp -= R.d.exp_next[p.level - 1]
            p.level += 1
            gained += 1
            p.picks += 1
            mhp0, mmp0, hp0, mp0 = p.mhp, p.mmp, p.hp, p.mp
            self.sync_stats()
            self.place_free_point()   # D143: the class stat (in by_level), Max HP or Max MP
            p.hp = min(p.mhp, hp0 + max(0, p.mhp - mhp0))
            p.mp = min(p.mmp, mp0 + max(0, p.mmp - mmp0))
        if p.level >= 10:
            p.exp = 0
        return gained

    # ---- loot ----
    def class_allows(self, item):
        if self.p.class_id == 3:
            return True
        pc = item.get("preferred_class", -1)
        if pc != -1 and pc != self.p.class_id:
            return False
        ac = item.get("allowed_classes")
        if ac and self.p.class_id not in ac:
            return False
        return True

    def owns(self, iid):
        return iid in self.p.inv or iid in self.p.equip.values()

    def roll_table(self, table, level, extra=None, exclude=()):
        """D117: roll the rarity tier first (the table's odds for this container level), then the item inside it by its row weight alone.
        A tier with no eligible rows steps down (3 -> 2 -> 1), then up from the rolled tier. D118: a chest has no "nothing" row and gear gives at least 1."""
        rows = list(self.d.loot["tables"][table]) + list(extra or [])
        tiers = {1: [], 2: [], 3: []}
        for r in rows:
            if r["weight"] <= 0:
                continue
            iid = r["item_id"]
            if iid > 0:
                it = self.d.items[iid]
                if it["type"] in (0, 1, 4):
                    if not self.class_allows(it) or self.owns(iid):
                        continue
                if iid in exclude:
                    continue
            elif table == "chest":
                continue
            tiers[max(1, min(3, r["tier"]))].append(r)
        odds = self.d.tier_odds.get(table, [[1, 0, 0]] * 3)[max(1, min(3, level)) - 1]
        t = roll_tier(self.rng, odds)
        for t2 in list(range(t, 0, -1)) + list(range(t + 1, 4)):
            if tiers[t2]:
                break
        else:
            return None
        pool = tiers[t2]
        x = self.rng.random() * sum(r["weight"] for r in pool)
        acc = 0.0
        for r in pool:
            acc += r["weight"]
            if x <= acc:
                break
        lo = r["qty_min"]
        if r["item_id"] > 0 and self.d.items[r["item_id"]]["type"] in (0, 1, 4):
            lo = max(1, lo)   # D118: gear is never "0 of it"
        qty = lo if lo >= r["qty_max"] else self.rng.randint(lo, r["qty_max"])
        if qty <= 0 or r["item_id"] <= 0:
            return None
        return (r["item_id"], qty)

    def floor_extras(self, floor):
        band = 1 if floor <= 3 else (2 if floor <= 6 else 3)
        rr = random.Random(self.seed * 31 + band)
        thr = [[33, 30], [30, 32, 31], [31, 32, 30, 33]][band - 1]
        acc = [[40, 41, 42, 43], [41, 42, 43, 44, 45], [44, 45, 46, 42, 43]][band - 1]
        return [dict(item_id=rr.choice(thr), weight=12, tier=1, qty_min=1, qty_max=2), dict(item_id=rr.choice(acc), weight=8, tier=2, qty_min=1, qty_max=1)]

    def grant(self, iid, qty):
        p, R = self.p, self.R
        it = self.d.items[iid]
        if it.get("throwable"):
            cap = self.d.eco["throw_cap_nobody"] if p.class_id == 3 else self.d.eco["throw_cap"]
            qty = min(qty, max(0, cap - p.inv.get(iid, 0)))
            if qty <= 0:
                return
        if it["type"] in (0, 1, 4):
            if self.owns(iid):
                return
            p.inv[iid] = 1
            self.auto_equip()
            return
        p.inv[iid] = p.inv.get(iid, 0) + qty

    def open_container(self, kind, level, floor):
        key = "chest" if kind == "chest" else "barrel"
        cfg = self.d.loot["configs"]["chest_basic" if kind == "chest" else "barrel_basic"]
        chance = cfg["chance"][max(1, min(3, level)) - 1]
        if self.rng.random() > chance:
            return
        r = self.roll_table(cfg["table"], level, self.floor_extras(floor))
        if r:
            self.grant(*r)

    def enemy_drop(self, e):
        cfg = self.d.loot["configs"][self.d.enemies[e.enemy_id]["loot_key"]]
        lvl = max(1, min(3, e.level))
        if self.rng.random() > drop_chance(cfg["chance"][lvl - 1], self.drop_dry):   # D120
            self.drop_dry += 1
            return
        r = self.roll_table(cfg["table"], e.level)
        if r:
            self.grant(*r)
            self.drop_dry = 0
        else:
            self.drop_dry += 1

    # ---- gear ----
    def gear_score(self, p):
        R = self.R
        pol = self.pol
        return -self.value(p)

    def auto_equip(self):
        """Equip the item of each slot that gives the best expected fight (ties keep what is worn)."""
        p, R = self.p, self.R
        for slot, types in (("weapon", (0,)), ("armor", (1,)), ("accessory", (4,))):
            cands = [iid for iid in p.inv if self.d.items[iid]["type"] in types]
            cur = p.equip[slot]
            if cur:
                cands.append(cur)
            if not cands:
                continue
            best, best_v = cur, None
            base = clone_player(p)
            for iid in set(cands):
                base.equip[slot] = iid
                v = self.value(base)
                if best_v is None or v < best_v - 1e-9 or (abs(v - best_v) <= 1e-9 and iid == cur):
                    best, best_v = iid, v
            if best != cur:
                if cur:
                    p.inv[cur] = 1
                p.equip[slot] = best
                p.inv.pop(best, None)

    # ---- the value of a build ----
    def refs(self):
        """Reference fights for the next stretch of the run: (enemy id, level, weight)."""
        f = self.floor
        if f <= 2:
            return [(0, 1, 1.0), (1, 3, 1.0), (8, 8, 0.6)]
        if f <= 4:
            return [(3, 3, 1.0), (6, 4, 1.0), (1, 4, 0.7), (8, 8, 1.0)]
        if f <= 6:
            return [(6, 5, 1.0), (2, 6, 1.0), (4, 6, 1.0), (8, 8, 0.7 if f <= 5 else 0.0), (7, 7, 0.7)]
        return [(4, 7, 1.0), (2, 7, 1.0), (7, 8, 1.0), (9, 10, 1.0)]

    def value(self, p):
        """HP-equivalents the build is expected to lose per fight (lower is better), mean over the reference fights."""
        R = self.R
        tot = 0.0
        wsum = 0.0
        for eid, lvl, w in self.refs():
            if w <= 0:
                continue
            e = make_enemy(R, eid, lvl)
            hp_loss, mp_spent, _ = exp_fight(R, self.pol, p, e, self.probs)
            tot += w * (hp_loss + MP_VALUE * mp_spent)
            wsum += w
        return tot / max(wsum, 1e-9)

    def run_bonus(self, p):
        """HP-equivalents per run from effects the fight model does not see (resources between fights)."""
        R = self.R
        n = self.n_rem()
        v = 0.0
        v += 0.7 * R.passive_sum(p, "heal_after_fight") * n
        v += 0.7 * MP_VALUE * R.passive_sum(p, "mp_after_fight") * n
        v += HP_PER_GOLD * 0.10 * R.passive_sum(p, "gold_mult") / 0.10 * 6.0 if R.passive_sum(p, "gold_mult") else 0.0
        v += 0.3 * 8 * HP_PER_GOLD * R.passive_sum(p, "find_potion_pct") * n if R.passive_sum(p, "find_potion_pct") else 0.0
        v += R.passive_sum(p, "item_power") * 8.0 * 5
        v += 0.4 * R.passive_sum(p, "start_stagger") * n * 0.5
        v += 0.5 * MP_VALUE * 2 * R.passive_sum(p, "potion_mp") * 3
        return v

    def card_value(self, card, base_v, base_rb):
        """Gain (HP-equivalents over the rest of the run) from taking this card now; None when it cannot be taken."""
        p, R = self.p, self.R
        k = card["kind"]
        n = self.n_rem()
        if k == "fallback":
            pr = card["params"]
            if "heal_pct" in pr:
                return min(p.mhp - p.hp, int(p.mhp * pr["heal_pct"])) + MP_VALUE * min(p.mmp - p.mp, int(p.mmp * pr["heal_pct"]))
            if "gold" in pr:
                return pr["gold"] * HP_PER_GOLD
            if "stat_main" in pr:
                q = clone_player(p)
                q.extra = dict(getattr(p, "extra", {}))
                key = self.free_stat_key()
                q.extra[key] = q.extra.get(key, 0) + 1
                q.st = dict(p.st)
                q.st[ST_KEY.get(key, key)] += 1
                return (base_v - self.value(q)) * n
            return 0.0
        q = clone_player(p)
        if k == "skill":
            if card["skill_id"] in p.skills:
                return None
            if len(p.skills) < 3:
                q.skills = p.skills + [card["skill_id"]]
                return (base_v - self.value(q)) * n
            best = None
            for old in p.skills:
                q2 = clone_player(p)
                q2.skills = [card["skill_id"] if s == old else s for s in p.skills]
                q2.upgrades = [u for u in p.upgrades if u != old]
                g = (base_v - self.value(q2)) * n
                if best is None or g > best:
                    best = g
            return best
        if k == "upgrade":
            if card["skill_id"] not in p.skills or card["skill_id"] in p.upgrades:
                return None
            q.upgrades = p.upgrades + [card["skill_id"]]
            return (base_v - self.value(q)) * n
        if k == "passive":
            if card["id"] in p.passives:
                return None
            q.passives = p.passives + [card["id"]]
            pr = card["params"]
            for kk in ("stat_atk", "stat_def", "stat_spd", "stat_mag"):
                if kk in pr:
                    key = {"stat_atk": "atk", "stat_def": "df", "stat_spd": "spd", "stat_mag": "mag"}[kk]
                    q.st = dict(q.st)
                    q.st[key] += pr[kk]
            R.resources(q)
            return (base_v - self.value(q)) * n + (self.run_bonus(q) - base_rb)
        return 0.0

    # ---- cards (Card_OfferGenerate, ported) ----
    def eligible(self, c):
        p = self.p
        if c["kind"] == "fallback":
            return True
        if c["classes"] and p.class_id not in c["classes"]:
            return False
        if c["kind"] == "skill":
            return c["skill_id"] not in p.skills
        if c["kind"] == "upgrade":
            return c["skill_id"] in p.skills and c["skill_id"] not in p.upgrades
        if c["kind"] == "passive":
            return c["id"] not in p.passives
        return False

    def offer(self):
        p, rng = self.p, self.rng
        st = p.card_state
        elig = dict(skill=[], upgrade=[], passive=[])
        for c in self.d.card_list:
            if c["kind"] != "fallback" and self.eligible(c):
                elig[c["kind"]].append(c["id"])
        owned = len(p.skills)
        could_up = len(elig["upgrade"]) > 0

        def without(lists, ids):
            return {k: [x for x in v if x not in ids] for k, v in lists.items()}

        def count(l):
            return sum(len(v) for v in l.values())

        lists = without(elig, st["last"])
        if count(lists) < 3:
            lists = without(elig, [])
        picked = []
        kind_of = lambda cid: self.d.cards[cid]["kind"]
        if st["pity"] >= 2 and could_up:
            pu = lists["upgrade"] or elig["upgrade"]
            pid = rng.choice(pu)
            picked.append(pid)
            lists = without(lists, [pid])
            elig = without(elig, [pid])
        if owned < 2 and not any(kind_of(x) == "skill" for x in picked):
            ps = lists["skill"] or elig["skill"]
            if ps:
                sid = rng.choice(ps)
                picked.append(sid)
                lists = without(lists, [sid])
                elig = without(elig, [sid])

        def weight(kind):
            full = owned >= 3
            return {"skill": 1 if full else 3, "upgrade": 3 if full else 1, "passive": 2}[kind]

        def fill(picked, lists):
            while len(picked) < 3:
                skill_blocked = owned >= 3 and any(kind_of(x) == "skill" for x in picked)
                total = 0
                for k in ("skill", "upgrade", "passive"):
                    if k == "skill" and skill_blocked:
                        continue
                    if lists[k]:
                        total += weight(k)
                if total <= 0:
                    break
                r = rng.random() * total
                acc = 0
                kind = ""
                for k in ("skill", "upgrade", "passive"):
                    if k == "skill" and skill_blocked:
                        continue
                    if not lists[k]:
                        continue
                    acc += weight(k)
                    kind = k
                    if r < acc:
                        break
                src = lists[kind]
                pid = src[rng.randrange(len(src))]
                picked.append(pid)
                lists[kind] = [x for x in src if x != pid]
            return picked

        picked = fill(picked, lists)
        if len(picked) < 3:
            picked = fill(picked, without(elig, picked))
        if len(picked) < 3:
            fbs = ["fb:rest", "fb:gold", "fb:focus"]
            rng.shuffle(fbs)
            for f in fbs:
                if len(picked) < 3 and f not in picked:
                    picked.append(f)
        rng.shuffle(picked)
        has_up = any(self.d.cards[x]["kind"] == "upgrade" for x in picked)
        st["pity"] = 0 if has_up else (st["pity"] + 1 if could_up else st["pity"])
        st["last"] = list(picked)
        st["offers"] += 1
        return picked

    def take_card(self, cid):
        p = self.p
        c = self.d.cards[cid]
        k = c["kind"]
        if k == "skill":
            if len(p.skills) < 3:
                p.skills.append(c["skill_id"])
            else:
                best, best_g = None, None
                base_v = self.value(p)
                for old in p.skills:
                    q = clone_player(p)
                    q.skills = [c["skill_id"] if s == old else s for s in p.skills]
                    q.upgrades = [u for u in p.upgrades if u != old]
                    g = base_v - self.value(q)
                    if best is None or g > best_g:
                        best, best_g = old, g
                p.skills = [c["skill_id"] if s == best else s for s in p.skills]
                p.upgrades = [u for u in p.upgrades if u != best]
        elif k == "upgrade":
            if c["skill_id"] not in p.upgrades:
                p.upgrades.append(c["skill_id"])
        elif k == "passive":
            p.passives.append(cid)
            self.sync_stats()
        elif k == "fallback":
            pr = c["params"]
            if "heal_pct" in pr:
                p.hp = min(p.mhp, p.hp + int(p.mhp * pr["heal_pct"]))
                p.mp = min(p.mmp, p.mp + int(p.mmp * pr["heal_pct"]))
            if "gold" in pr:
                self.gold += pr["gold"]
            if "stat_main" in pr:
                ex = p.__dict__.setdefault("extra", {})
                key = self.free_stat_key()
                ex[key] = ex.get(key, 0) + 1
                self.sync_stats()

    def do_picks(self):
        """Answer every owed card pick with the greedy policy: the card with the best expected gain. There is no Skip (owner note 11): one of the three cards is
        always taken, the first of the best when none helps."""
        p = self.p
        while p.picks > 0:
            p.picks -= 1
            offer = self.offer()
            self.rec["pick_count"] += 1
            self.rec["card_offers"].append(list(offer))
            base_v = self.value(p)
            base_rb = self.run_bonus(p)
            best, best_g = None, None
            for cid in offer:
                g = self.card_value(self.d.cards[cid], base_v, base_rb)
                self.rec["card_gain"].append((cid, g))
                if g is not None and (best_g is None or g > best_g):
                    best, best_g = cid, g
            if best is None:
                best = offer[0]   # nothing helps at all: the highlighted card (the first) is taken
            self.take_card(best)
            self.rec["picks"].append(best)

    # ---- shops ----
    def shop_stock(self, idx):
        p, rng = self.p, random.Random(self.seed * 6151 + idx)
        tier = max(0, min(2, idx))
        rows = []

        def price(iid):
            return max(1, math.ceil(self.d.items[iid]["value"] * self.d.eco["price_mult"] - 1e-6))

        hp_ids, mp_ids = [10, 14, 15], [11, 17, 18]
        rows.append(dict(kind="item", id=hp_ids[tier], qty=3, price=price(hp_ids[tier])))
        o = rng.choice([mp_ids[tier], mp_ids[tier], 12, 13])
        rows.append(dict(kind="item", id=o, qty=2, price=price(o)))
        thr = [30, 31, 32, 33]
        rng.shuffle(thr)
        win = [(0, 20), (18, 40), (34, 70)][tier]
        gear = []
        for ids, typ in (([1, 2, 3, 4, 5, 6, 7, 8, 9], 0), ([20, 21, 22, 23, 24, 25], 1)):
            cands = []
            for iid in ids:
                it = self.d.items[iid]
                if it["type"] != typ or it["value"] < win[0] or it["value"] > win[1] or not self.class_allows(it) or self.owns(iid):
                    continue
                cands.append(iid)
            if cands:
                gear.append(rng.choice(cands))
        n_thr = 2 + (2 - len(gear))
        for t in thr[:n_thr]:
            rows.append(dict(kind="item", id=t, qty=2, price=price(t)))
        for g in gear:
            rows.append(dict(kind="item", id=g, qty=1, price=price(g)))
        accs = [i for i in ([40, 41, 42, 43] if idx <= 0 else ([40, 41, 42, 43, 44, 45] if idx == 1 else [41, 42, 43, 44, 45, 46])) if not self.owns(i)]
        if accs:
            a = rng.choice(accs)
            rows.append(dict(kind="item", id=a, qty=1, price=price(a)))
        n_cards = 1 + rng.randint(0, 1)
        cands = []
        for c in self.d.card_list:
            if c["kind"] == "fallback" or not self.eligible(c):
                continue
            if c["kind"] == "skill" and len(p.skills) >= 3:
                continue
            cands.append(c["id"])
        rng.shuffle(cands)
        cp = self.d.eco["card_price"]
        for cid in cands[:n_cards]:
            rows.append(dict(kind="card", id=cid, qty=1, price=cp[self.d.cards[cid]["kind"]]))
        return rows

    def shop_visit(self, idx):
        p, R = self.p, self.R
        rows = self.shop_stock(idx)
        spent = 0
        bought = []
        while True:
            base_v = self.value(p)
            base_rb = self.run_bonus(p)
            best = None
            for r in rows:
                if r["qty"] <= 0 or r["price"] > self.gold:
                    continue
                v = self.row_value(r, base_v, base_rb)
                if v is None:
                    continue
                ratio = v / r["price"]
                if ratio >= HP_PER_GOLD * 0.6 and (best is None or ratio > best[0]):   # gold has no other use after the last shop: a player spends it
                    best = (ratio, r)
            if best is None:
                break
            r = best[1]
            self.gold -= r["price"]
            spent += r["price"]
            r["qty"] -= 1
            if r["kind"] == "item":
                self.grant(r["id"], 1)
                if self.d.items[r["id"]]["type"] in (0, 1, 4):
                    self.auto_equip()
            else:
                self.take_card(r["id"])
            bought.append(r["id"])
        self.rec["shops"].append(dict(idx=idx, spent=spent, bought=bought))
        self.rec["buys"].extend(bought)

    def row_value(self, r, base_v, base_rb):
        p, R = self.p, self.R
        n = self.n_rem()
        if r["kind"] == "card":
            return self.card_value(self.d.cards[r["id"]], base_v, base_rb)
        it = self.d.items[r["id"]]
        u = it["use"]
        if it["type"] == 2 and not it.get("throwable"):
            have = p.inv.get(r["id"], 0)
            if u["effect"] == "heal":
                avg = (u["min"] + u["max"]) / 2 + math.floor(max(0, p.level - 1) * u.get("scale", 0))
                held_hp = sum(self.d.items[i]["use"].get("min", 0) * c for i, c in p.inv.items() if self.d.items[i]["type"] == 2 and self.d.items[i]["use"].get("effect") == "heal")
                return avg * 0.85 * max(0.15, 1 - 0.18 * have) * (0.4 if held_hp > 70 else 1.0)
            if u["effect"] == "mp":
                if not p.skills:
                    return 0.0
                avg = (u["min"] + u["max"]) / 2 + math.floor(max(0, p.level - 1) * u.get("scale", 0))
                return avg * MP_VALUE * 0.7 * max(0.15, 1 - 0.25 * have)
            if u["effect"] == "cure":
                return 3.0 * max(0.0, 1 - 0.5 * have)
            return 0.0
        if it.get("throwable"):
            have = p.inv.get(r["id"], 0)
            cap = self.d.eco["throw_cap_nobody"] if p.class_id == 3 else self.d.eco["throw_cap"]
            if have >= cap or r["id"] == 33:
                return 0.0 if r["id"] != 33 else 2.0
            nm = self.d.eco["throw_nobody_mult"] if p.class_id == 3 else 1.0
            val = (u["power"] * 2.2 + u["burn_turns"] * 3.2 + u["stacks"] * 2.8 + (3 if u["stun"] else 0)) * nm
            uses = 1.0 if p.class_id != 3 else 3.0
            return val * uses * max(0.2, 1 - 0.3 * have)
        if it["type"] in (0, 1, 4):
            if not self.class_allows(it) or self.owns(r["id"]):
                return None
            q = clone_player(p)
            slot = {0: "weapon", 1: "armor", 4: "accessory"}[it["type"]]
            q.equip[slot] = r["id"]
            gain = (base_v - self.value(q)) * n
            if it["type"] == 4 and it.get("passive_id") == "lucky":
                gain += 0.15 * 300 * HP_PER_GOLD
            return gain
        return 0.0

    # ---- between fights ----
    def recover(self, next_hard=False):
        p, R = self.p, self.R
        used = 0
        while p.hp < 0.5 * p.mhp and used < 4:
            it = self.pol.pick_heal(p, p.mhp - p.hp)
            if not it:
                break
            u = R.items[it]["use"]
            amt = item_amount(R, p, u, self.rng)
            p.hp = min(p.mhp, p.hp + amt)
            mpb = round(R.passive_sum(p, "potion_mp"))
            if mpb > 0:
                p.mp = min(p.mmp, p.mp + mpb)
            p.inv[it] -= 1
            if p.inv[it] <= 0:
                del p.inv[it]
            self.rec["potions_used"] += 1
            self.rec["item_uses"] += 1
            used += 1
        if p.skills and p.mp < min(R.player_skill(p, s)["mp_cost"] for s in p.skills) and (next_hard or p.mp < 0.2 * p.mmp):
            it = self.pol.pick_mp(p)
            if it:
                u = R.items[it]["use"]
                p.mp = min(p.mmp, p.mp + item_amount(R, p, u, self.rng))
                p.inv[it] -= 1
                if p.inv[it] <= 0:
                    del p.inv[it]
                self.rec["mp_potions_used"] += 1
                self.rec["item_uses"] += 1

    def bed(self):
        p = self.p
        hp_f, mp_f = p.hp / p.mhp, (p.mp / p.mmp if p.mmp else 1.0)
        want_heal = hp_f < 0.6 or (p.skills and mp_f < 0.4)
        can_up = [s for s in p.skills if s not in p.upgrades]
        if can_up and not want_heal:
            base_v = self.value(p)
            best, best_g = None, None
            for s in can_up:
                q = clone_player(p)
                q.upgrades = p.upgrades + [s]
                g = base_v - self.value(q)
                if best is None or g > best_g:
                    best, best_g = s, g
            p.upgrades.append(best)
            self.rec["beds"].append("upgrade")
        else:
            fr = self.d.const.get("bed_heal_frac", BEDS_HEAL_FRAC)   # C4 heals everything today; a PROPOSED constant can lower it
            p.hp = min(p.mhp, p.hp + int(p.mhp * fr))
            p.mp = min(p.mmp, p.mp + int(p.mmp * fr))
            self.rec["beds"].append("heal")

    # ---- fights ----
    def fight(self, eid, level, elite, floor):
        R, p = self.R, self.p
        e = make_enemy(R, eid, level, elite)
        if eid == 8:
            self.rec["levels"]["mini_boss"] = p.level
        if eid == 9:
            self.rec["levels"]["final_boss"] = p.level
        b = Battle(R, p, e, self.profile, self.rng, self.pol, self)
        won = b.run()
        cat = "final_boss" if eid == 9 else ("mini_boss" if eid == 8 else ("stranger" if eid == 7 else ("elite" if elite else "normal")))
        self.rec["actions"] += b.p_actions + b.e_actions
        self.rec["defences"] += b.defences
        for k, v in b.log.items():
            if k.startswith("use_"):
                self.rec["used_skills"][k] = self.rec["used_skills"].get(k, 0) + v
        self.rec["fights"].append(dict(cat=cat, enemy=eid, level=level, elite=elite, floor=floor, turns=b.p_turns, won=won,
                                       hp_lost=max(0.0, (b.hp_start - p.hp) / max(1, p.mhp)) if won else 1.0, mp_spent=max(0, b.mp_start - p.mp), mp_frac=max(0, b.mp_start - p.mp) / max(1, p.mmp),
                                       breaks=b.log.get("breaks", 0), windups=b.log.get("windups", 0), dmg_taken=b.log.get("dmg_taken", 0), e_turns=e.ai["turns"]))
        if not won:
            return False
        p.status = []
        self.n_fights_done += 1
        g = self.d.eco
        base = rhu((g["gold_base"] + g["gold_per_level"] * max(1, level)) * (g["gold_boss_mult"] if e.is_boss else (g["gold_rank2_mult"] if e.rank >= 2 else 1)) * (g["gold_elite_mult"] if elite else 1))
        if not self.gold_bag:   # D126: a shuffled bag of 5 offsets around the base, refilled when empty
            self.gold_bag = gold_offsets(g["gold_spread"])
            self.rng.shuffle(self.gold_bag)
        rolled = rhu(base * (1 + self.gold_bag.pop()))
        gm = 1 + R.passive_sum(p, "gold_mult") + sum(self.d.items[i].get("passive_params", {}).get("gold_mult", 0) for i in p.equip.values() if i)
        gold = max(1, rhu(rolled * gm))
        self.gold += gold
        self.gold_earned += gold
        self.add_exp(e.base_exp)
        if elite:
            p.picks += 1
            self.rec["elites"] += 1
        self.enemy_drop(e)
        # Card_OnVictory
        heal = round(R.passive_sum(p, "heal_after_fight"))
        if heal > 0:
            p.hp = min(p.mhp, p.hp + heal)
        mpg = round(R.passive_sum(p, "mp_after_fight"))
        if mpg > 0:
            p.mp = min(p.mmp, p.mp + mpg)
        fp = R.passive_sum(p, "find_potion_pct")
        if fp > 0 and bag_draw(self.find_bag, "find", fp, self.rng):   # D126
            p.inv[10] = p.inv.get(10, 0) + 1
        return True

    # ---- the run ----
    def make_floor(self, f):
        lay = self.d.layout[str(float(f))] if str(float(f)) in self.d.layout else self.d.layout[str(f)]
        pool = self.d.floors.get(int(f), [])
        rr = random.Random(self.seed * 15485863 + int(f * 10))
        enemies = []
        for _ in lay["enemies_free"]:
            eid = rr.choice(pool)
            cfg = self.d.enemies[eid]
            lo = max(1, cfg["species_min_level"])
            hi = max(lo, cfg["species_max_level"])
            lvl = max(lo, min(min(hi, 10), int(f) + rr.randint(-1, 1) + cfg["species_level_offset"]))
            enemies.append((eid, lvl, ""))
        # D123: a fixed number of elites per floor, picked by shuffling the free slots
        slots = list(range(len(enemies)))
        rr.shuffle(slots)
        for k in slots[:elite_count(f, len(slots), self.d.eco["elite_chance"])]:
            eid, lvl, _ = enemies[k]
            enemies[k] = (eid, lvl, rr.choice(["armored", "venomous", "swift", "brutal", "regenerating"]))
        for name in lay["enemies_fixed"]:
            eid = ENEMY_IDS[name]
            cfg = self.d.enemies[eid]
            lvl = max(cfg["species_min_level"], min(cfg["species_max_level"], int(f)))
            enemies.append((eid, lvl, ""))
        rr.shuffle(enemies)
        return lay, enemies

    def play(self):
        p, R = self.p, self.R
        result = dict(win=False, death_floor=None, killer=None)
        order = [1, 2, 3, 4, 5, 6, 7, 8, 9, 9.5]
        self.sync_stats()
        p.hp, p.mp = p.mhp, p.mmp
        for f in order:
            self.floor = int(f)
            if f == 7:
                self.rec["levels"]["floor7"] = p.level
            lay, enemies = self.make_floor(f)
            self.rec["actions"] += 0
            # containers first (free), the class chest (the class is already chosen) and the card chests
            for lvl in lay["chests"]:
                self.open_container("chest", lvl, int(f))
            for lvl in lay["barrels"]:
                self.open_container("barrel", lvl, int(f))
            p.picks += lay["card_chests"]
            self.do_picks()
            for k, (eid, lvl, elite) in enumerate(enemies):
                hard = (eid in (7, 8, 9)) or bool(elite)
                self.recover(next_hard=hard)
                if f == 9.5 or eid == 9:
                    # before the last fight: drink up
                    pass
                ok = self.fight(eid, lvl, elite, f)
                if not ok:
                    result.update(death_floor=f, killer=("final_boss" if eid == 9 else ("mini_boss" if eid == 8 else ("elite" if elite else ENEMY_NAMES[eid]))))
                    return self.finish(result)
                self.do_picks()
                if p.level > 0:
                    self.auto_equip()
            if f == 9.5:
                result["win"] = True
                break
            if f in (2, 5, 8):
                self.shop_visit({2: 0, 5: 1, 8: 2}[f])
            if lay["beds"]:
                self.bed()
            self.do_picks()
        return self.finish(result)

    def finish(self, result):
        p = self.p
        rec = self.rec
        result.update(rec)
        result["level_end"] = p.level
        result["gold_earned"] = self.gold_earned
        result["gold_left"] = self.gold
        result["final_skills"] = list(p.skills)
        result["final_upgrades"] = list(p.upgrades)
        result["final_passives"] = list(p.passives)
        result["weapon"] = p.equip["weapon"]
        result["armor"] = p.equip["armor"]
        result["accessory"] = p.equip["accessory"]
        floors_walked = len(set(f["floor"] for f in rec["fights"])) or 1
        t = TIME
        result["seconds"] = (rec["actions"] * t["action_s"] + rec["defences"] * t["defence_extra_s"] + floors_walked * t["floor_walk_s"]
                             + len(rec["fights"]) * t["fight_approach_s"] + rec["pick_count"] * t["card_pick_s"] + len(rec["shops"]) * t["shop_s"]
                             + t["story_s"] + rec["item_uses"] * t["item_use_s"])
        result["class"] = self.class_name
        return result


# ---------------------------------------------------------------------------------------------------------------------------------
# Many runs, statistics
# ---------------------------------------------------------------------------------------------------------------------------------
_WORKER = {}


def _worker_init(path, tweaks=None):
    d = Data(path, tweaks)
    _WORKER["d"] = d
    _WORKER["R"] = Rules(d)


def _run_chunk(job):
    cls, profile, seeds, policy = job
    d, R = _WORKER["d"], _WORKER["R"]
    out = []
    for s in seeds:
        out.append(RunSim(d, cls, profile, s, policy, rules=R).play())
    return out


def run_cell(path, cls, profile, runs, seed0, jobs, policy="greedy", tweaks=None):
    seeds = list(range(seed0, seed0 + runs))
    if jobs <= 1:
        _worker_init(path, tweaks)
        return _run_chunk((cls, profile, seeds, policy))
    import multiprocessing as mp
    chunk = max(1, min(25, runs // (jobs * 4) or 1))
    jobs_l = [(cls, profile, seeds[i:i + chunk], policy) for i in range(0, runs, chunk)]
    with mp.Pool(jobs, initializer=_worker_init, initargs=(path, tweaks)) as pool:
        res = pool.map(_run_chunk, jobs_l)
    return [r for part in res for r in part]


def wilson(k, n, z=1.96):
    if n == 0:
        return (0.0, 1.0)
    ph = k / n
    den = 1 + z * z / n
    c = ph + z * z / (2 * n)
    m = z * math.sqrt(ph * (1 - ph) / n + z * z / (4 * n * n))
    return ((c - m) / den, (c + m) / den)


def mean(xs):
    xs = list(xs)
    return sum(xs) / len(xs) if xs else float("nan")


def pct(xs, q):
    xs = sorted(xs)
    if not xs:
        return float("nan")
    i = min(len(xs) - 1, max(0, int(round(q * (len(xs) - 1)))))
    return xs[i]


def aggregate(results, d):
    """One cell (class x profile) -> the numbers the targets and the report use."""
    n = len(results)
    wins = [r for r in results if r["win"]]
    out = dict(n=n, wins=len(wins), win_rate=len(wins) / n if n else float("nan"))
    out["win_ci"] = wilson(len(wins), n)
    # fights
    cats = {}
    for r in results:
        for f in r["fights"]:
            cats.setdefault(f["cat"], []).append(f)
    out["fights"] = {}
    for c, fl in cats.items():
        turns = [f["turns"] for f in fl]
        out["fights"][c] = dict(n=len(fl), turns=mean(turns), turns_win=mean([f["turns"] for f in fl if f["won"]]) if any(f["won"] for f in fl) else float("nan"),
                                p90=pct(turns, 0.9), win_rate=mean([1.0 if f["won"] else 0.0 for f in fl]),
                                hp_lost=mean([f["hp_lost"] for f in fl if f["won"]]) if any(f["won"] for f in fl) else float("nan"),
                                mp_spent=mean([f["mp_spent"] for f in fl if f["won"]]) if any(f["won"] for f in fl) else float("nan"),
                                mp_frac=mean([f["mp_frac"] for f in fl if f["won"]]) if any(f["won"] for f in fl) else float("nan"),
                                breaks=mean([f["breaks"] for f in fl]))
    byenemy = {}
    for r in results:
        for f in r["fights"]:
            byenemy.setdefault((f["enemy"], bool(f["elite"])), []).append(f)
    out["by_enemy"] = {("%s%s" % ("elite " if k[1] else "", ENEMY_NAMES[k[0]])): dict(n=len(v), turns=mean([f["turns"] for f in v]), win_rate=mean([1.0 if f["won"] else 0.0 for f in v]),
                                                                                          hp_lost=mean([f["hp_lost"] for f in v if f["won"]]) if any(f["won"] for f in v) else float("nan"))
                       for k, v in sorted(byenemy.items())}
    # floor drain: HP lost to the fights of one floor (before potions, beds), as a share of max HP, mean over the floors a run played through
    drains = []
    for r in results:
        per = {}
        for f in r["fights"]:
            per[f["floor"]] = per.get(f["floor"], 0.0) + f["hp_lost"] * (1.0 if f["won"] else 0.0)
        drains.extend(v for k, v in per.items() if k not in (9.5,))
    out["floor_drain"] = mean(drains)
    # levels
    lv = {}
    for key in ("mini_boss", "floor7", "final_boss"):
        xs = [r["levels"][key] for r in results if key in r["levels"]]
        lv[key] = mean(xs) if xs else float("nan")
    out["levels"] = lv
    out["level_end"] = mean([r["level_end"] for r in results])
    out["level_end_win"] = mean([r["level_end"] for r in wins]) if wins else float("nan")
    # deaths
    dist = {}
    for r in results:
        if not r["win"]:
            k = "floor %s: %s" % (r["death_floor"], r["killer"])
            dist[k] = dist.get(k, 0) + 1
    out["deaths"] = dict(sorted(dist.items(), key=lambda kv: -kv[1]))
    dfloor = {}
    for r in results:
        if not r["win"]:
            dfloor[r["death_floor"]] = dfloor.get(r["death_floor"], 0) + 1
    out["death_floor"] = {str(k): v / n for k, v in sorted(dfloor.items())}
    # time
    secs = [r["seconds"] for r in wins] if wins else []
    out["minutes_win"] = mean(secs) / 60 if secs else float("nan")
    out["minutes_all"] = mean([r["seconds"] for r in results]) / 60
    out["minutes_p10_p90"] = (pct(secs, 0.1) / 60, pct(secs, 0.9) / 60) if secs else (float("nan"), float("nan"))
    # economy
    out["gold_earned"] = mean([r["gold_earned"] for r in results])
    out["gold_left_win"] = mean([r["gold_left"] for r in wins]) if wins else float("nan")
    out["potions_used"] = mean([r["potions_used"] for r in results])
    out["elites"] = mean([r["elites"] for r in results])
    out["picks"] = mean([r["pick_count"] for r in results])
    out["fights_per_run"] = mean([len(r["fights"]) for r in results])
    out["breaks_per_fight"] = mean([f["breaks"] for r in results for f in r["fights"]])
    # card dominance (winning runs): share of winning runs that took / ended with each card
    share = {}
    final_share = {}
    if wins:
        for r in wins:
            taken = set(r["picks"]) | set(r["buys"])
            for c in taken:
                share[c] = share.get(c, 0) + 1
            for s in r["final_skills"]:
                final_share["skill:%d" % s] = final_share.get("skill:%d" % s, 0) + 1
        share = {k: v / len(wins) for k, v in share.items()}
        final_share = {k: v / len(wins) for k, v in final_share.items()}
    early = {}
    if wins:
        for r in wins:
            for c in set(r["picks"][:3]):
                early[c] = early.get(c, 0) + 1
        early = {k: v / len(wins) for k, v in early.items()}
    out["card_early_share_win"] = dict(sorted(early.items(), key=lambda kv: -kv[1]))
    gains = {}
    for r in results:
        for c, g in r["card_gain"]:
            if g is not None:
                gains.setdefault(c, []).append(g)
    out["card_gain"] = {k: mean(v) for k, v in gains.items()}
    out["card_share_win"] = dict(sorted(share.items(), key=lambda kv: -kv[1]))
    out["skill_final_share_win"] = dict(sorted(final_share.items(), key=lambda kv: -kv[1]))
    # offered -> taken (all runs)
    off, tak = {}, {}
    for r in results:
        for o, t in zip(r["card_offers"], r["picks"]):
            for c in o:
                off[c] = off.get(c, 0) + 1
            tak[t] = tak.get(t, 0) + 1
    out["card_offered"] = off
    out["card_taken"] = tak
    # skill use per run
    use = {}
    for r in results:
        for k, v in r["used_skills"].items():
            use[k] = use.get(k, 0) + v
    out["uses_per_run"] = {k: v / n for k, v in sorted(use.items())}
    runs_with = {}
    for r in results:
        for k in r["used_skills"]:
            runs_with[k] = runs_with.get(k, 0) + 1
    out["runs_using"] = {k: v / n for k, v in sorted(runs_with.items())}
    # gear
    out["weapon_share"] = {}
    for r in results:
        k = str(r["weapon"])
        out["weapon_share"][k] = out["weapon_share"].get(k, 0) + 1.0 / n
    return out


# ---------------------------------------------------------------------------------------------------------------------------------
# Targets and the check
# ---------------------------------------------------------------------------------------------------------------------------------
def load_targets(path=TARGETS):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def in_band(x, band):
    return band[0] <= x <= band[1]


def evaluate(table, targets):
    """table[(cls, profile)] = aggregate(...). Returns a list of dict(id, text, ok, value, band, cell)."""
    out = []
    T = targets
    avg_classes = T.get("class_spread_classes", ["knight", "archer", "mage", "nobody"])
    for (cls, prof), a in sorted(table.items()):
        if prof == "average" and cls in T.get("fight_turn_classes", CLASS_IDS):
            for cat, band in T["fight_turns"].items():
                if cat.startswith("_"):
                    continue
                f = a["fights"].get(cat)
                if f:
                    out.append(dict(id="fight_turns.%s" % cat, cell=(cls, prof), value=f["turns_win"], band=band, ok=in_band(f["turns_win"], band)))
        if prof == "average":
            f = a["fights"].get("normal")
            if f:
                out.append(dict(id="normal_fight_win_rate", cell=(cls, prof), value=f["win_rate"], band=[T["normal_fight_win_rate_min"], 1.0], ok=f["win_rate"] >= T["normal_fight_win_rate_min"]))
            out.append(dict(id="level_final_boss", cell=(cls, prof), value=a["levels"]["final_boss"], band=T["level_final_boss"], ok=(a["levels"]["final_boss"] != a["levels"]["final_boss"]) or in_band(a["levels"]["final_boss"], T["level_final_boss"])))
            out.append(dict(id="level_mini_boss", cell=(cls, prof), value=a["levels"]["mini_boss"], band=T["level_mini_boss"], ok=in_band(a["levels"]["mini_boss"], T["level_mini_boss"])))
            out.append(dict(id="level_floor7", cell=(cls, prof), value=a["levels"]["floor7"], band=T["level_floor7"], ok=in_band(a["levels"]["floor7"], T["level_floor7"])))
        band = T["nobody_win_rate"][prof] if (cls == "nobody" and "nobody_win_rate" in T and "nobody" not in T.get("class_spread_classes", [])) else T["run_win_rate"][prof]
        lo, hi = a["win_ci"]
        out.append(dict(id="run_win_rate", cell=(cls, prof), value=a["win_rate"], band=band, ok=(hi >= band[0] and lo <= band[1]), note="95%% CI %.3f..%.3f must overlap the band" % (lo, hi)))
        if prof == "average" and a["wins"] > 0:
            out.append(dict(id="run_minutes", cell=(cls, prof), value=a["minutes_win"], band=T["run_minutes"], ok=in_band(a["minutes_win"], T["run_minutes"])))
        if prof == "average" and a["wins"] > 0:
            for c, v in a["card_early_share_win"].items():
                lim = T["dominance_max_share"]
                if v > lim:
                    out.append(dict(id="dominant_card", cell=(cls, prof), value=v, band=[0, lim], ok=False, note=c + " (in the first 3 picks)"))
    # class spread
    for prof in ("average", "novice", "expert"):
        rates = [table[(c, prof)]["win_rate"] for c in avg_classes if (c, prof) in table]
        if len(rates) >= 2:
            sp = max(rates) - min(rates)
            out.append(dict(id="class_spread.%s" % prof, cell=("all", prof), value=sp, band=[0, T["class_spread_max"]], ok=sp <= T["class_spread_max"]))
    return out


def print_table(table):
    print("%-8s %-8s %5s %7s %17s %8s %8s %8s %9s %7s" % ("class", "profile", "runs", "win%", "95% CI", "lvl end", "L mini", "L f7", "L final", "min(win)"))
    for (cls, prof), a in sorted(table.items(), key=lambda kv: (kv[0][0], ["novice", "average", "expert"].index(kv[0][1]))):
        print("%-8s %-8s %5d %6.1f%% %7.1f..%-6.1f%% %8.2f %8.2f %8.2f %9.2f %7.1f" % (cls, prof, a["n"], 100 * a["win_rate"], 100 * a["win_ci"][0], 100 * a["win_ci"][1], a["level_end"],
                                                                                   a["levels"]["mini_boss"], a["levels"]["floor7"], a["levels"]["final_boss"], a["minutes_win"]))
    print()
    print("fight length (player turns, fights the player won) and win rate, by class and profile")
    for (cls, prof), a in sorted(table.items(), key=lambda kv: (kv[0][0], ["novice", "average", "expert"].index(kv[0][1]))):
        parts = []
        for cat in ("normal", "elite", "stranger", "mini_boss", "final_boss"):
            f = a["fights"].get(cat)
            if f:
                parts.append("%s %.1f t/%.0f%%" % (cat, f["turns_win"], 100 * f["win_rate"]))
        print("  %-8s %-8s %s" % (cls, prof, "  ".join(parts)))


# ---------------------------------------------------------------------------------------------------------------------------------
# Parity with the reference vectors (acceptance: the simulator passes them)
# ---------------------------------------------------------------------------------------------------------------------------------
def fast_timeline_script(spd_p, spd_e, boss, script):
    """The simulator's own timeline (Battle.tl_next / tl_stun) run through the vector script language."""
    d = Data()
    R = Rules(d)
    p, e = F("p", True), F("e", False)
    p.st["spd"], e.st["spd"] = spd_p, spd_e
    e.is_boss = boss
    b = Battle(R, p, e, "average", random.Random(1), Policy(R), None)

    def prev(n):
        saved = (list(b.gauge), list(b.steadfast))
        s = ""
        for _ in range(n):
            s += "PE"[b.tl_next()]
        b.gauge, b.steadfast = saved
        return "(" + s + ")"

    out = ""
    for tok in script.split():
        if tok == "n":
            out += "PE"[b.tl_next()]
        elif tok[0] == "s":
            who = 0 if tok[1] == "P" else 1
            out += "!" if b.tl_stun(who) else "~"
        elif tok[0] == "b":
            who = 0 if tok[1] == "P" else 1
            b.gauge[who] -= 100
            out += "B"
        elif tok[0] == "p":
            out += prev(int(tok[1:]))
    return out


def check_vectors(path=DEFAULT_DATA):
    """True when (a) the reference reproduces combat-vectors.json, (b) the simulator's code and the exported game data give the same numbers."""
    bad = 0
    rc = ref.main([])
    if rc != 0:
        bad += 1
    with open(ref.VECTORS, encoding="utf-8") as f:
        v = json.load(f)
    d = Data(path)
    R = Rules(d)
    n = 0

    def chk(name, got, want):
        nonlocal bad, n
        n += 1
        if got != want:
            bad += 1
            print("FAIL %s: simulator %r, vector %r" % (name, got, want))

    for c in v["damage"]:
        chk("vec " + c["id"], ref.damage(c["power"], c["A"], c["D"], c["grade"], c["mult"]), c["want"])
    for c in v["resources"]:
        chk("vec " + c["id"], ref.hp_max(c["hd"], c["level"]) if c["kind"] == "hp" else ref.mp_max(c["mp_gain"], c["level"], c["mag"]), c["want"])
    for c in v["class_levels"]:
        cid = CLASS_IDS[c["cls"]]
        row = d.classes[cid]["by_level"][c["level"] - 1]
        chk("vec %s (exported by_level)" % c["id"], (row["atk"], row["def"], row["spd"], row["mag"], row["hp"], row["mp"]), (c["atk"], c["df"], c["spd"], c["mag"], c["hp"], c["mp"]))
        p = new_player(R, cid)
        p.level = c["level"]
        row2 = d.classes[cid]["by_level"][c["level"] - 1]
        p.st = dict(atk=row2["atk"], df=row2["def"], spd=row2["spd"], mag=row2["mag"])
        R.resources(p)
        chk("vec %s (simulator hp/mp)" % c["id"], (p.mhp, p.mmp), (c["hp"], c["mp"]))
    for c in v["exp_next"]:
        chk("vec " + c["id"], (d.raw["levels"][c["level"] - 1]["exp_next"]), c["want"])
    for c in v["enemies"]:
        eid = ENEMY_IDS[c["enemy"]]
        e = make_enemy(R, eid, c["level"])
        chk("vec " + c["id"], (e.st["atk"], e.st["df"], e.st["spd"], e.st["mag"], e.mhp), (c["atk"], c["df"], c["spd"], c["mag"], c["hp"]))
    for c in v["statuses"]:
        k = c["kind"]
        if k == "burn_tick":
            chk("vec " + c["id"], ref.burn_tick(c["arg"]), c["want"])
        elif k == "burn_def":
            f = F("x", False)
            f.st["df"] = c["arg"]
            R.status_add(f, BURN, 2, 2)
            chk("vec " + c["id"], R.eff(f, "df"), c["want"])
        elif k == "poison_total":
            chk("vec " + c["id"], ref.poison_total(c["arg"]), c["want"])
        elif k == "poison_add":
            f = F("x", False)
            if c["arg"]:
                R.status_add(f, POISON, 1, 1, c["arg"])
            R.status_add(f, POISON, 1, 1, c["arg2"])
            chk("vec " + c["id"], st_stacks(f, POISON), c["want"])
        elif k == "bleed_tick":
            chk("vec " + c["id"], ref.bleed_tick(c["arg"]), c["want"])
    for c in v["stagger"]:
        if c["kind"] == "gain":
            chk("vec " + c["id"], ref.stagger_gain(c["power"], c["stun"], c["perfect"]), c["want"])
        else:
            chk("vec " + c["id"], ref.stagger_max(c["rank"], c["boss"]), c["want"])
    for c in v["run_chance"]:
        chk("vec " + c["id"], round(ref.run_chance(c["spd_player"], c["spd_enemy"]), 6), c["want"])
    for c in v["timeline"]:
        chk("vec " + c["id"], fast_timeline_script(c["spd_player"], c["spd_enemy"], c["boss"], c["script"]), c["want"])
    # the exported grade numbers are the ones the damage vectors use
    chk("grades perfect/good/ok/weak", (d.grade_mult["PERFECT"], d.grade_mult["GOOD"], d.grade_mult["OK"], d.grade_mult["WEAK"]), (1.3, 1.1, 1.0, 0.75))
    chk("export power scale", d.const["power_scale"], 2)
    chk("export weapon skill share", d.const["weapon_skill_share"], 0.5)
    print("%s: %d simulator checks against combat-vectors.json and the export (%s)" % ("OK" if bad == 0 else "FAIL", n, d.build))
    return bad == 0


# ---------------------------------------------------------------------------------------------------------------------------------
# One matchup
# ---------------------------------------------------------------------------------------------------------------------------------
def default_build(d, R, cls_name, level):
    cid = CLASS_IDS[cls_name]
    p = new_player(R, cid)
    p.level = level
    row = d.classes[cid]["by_level"][level - 1]
    p.st = dict(atk=row["atk"], df=row["def"], spd=row["spd"], mag=row["mag"])
    R.resources(p)
    p.hp, p.mp = p.mhp, p.mmp
    sk = [c["skill_id"] for c in d.card_list if c["kind"] == "skill" and cid in c["classes"]]
    p.skills = sk[:3]
    tier = 0 if level <= 3 else (1 if level <= 6 else 2)
    weapons = {1: [1, 2, 3], 0: [4, 5, 6], 2: [7, 8, 9], 3: [1, 2, 3]}[cid]
    armors = {1: [20, 21, 22], 0: [20, 21, 22], 2: [23, 24, 25], 3: [20, 21, 22]}[cid]
    p.equip["weapon"] = weapons[tier]
    p.equip["armor"] = armors[tier]
    p.inv = {10: 2}
    return p


def matchup(path, cls_name, enemy, level, profile, n, seed, policy="greedy", elite="", tweaks=None, player_level=0):
    d = Data(path, tweaks)
    R = Rules(d)
    eid = ENEMY_IDS[enemy]
    lvl = level
    wins, turns, hp_lost = 0, [], []
    plevel = player_level or (lvl if lvl else 1)
    for i in range(n):
        p = default_build(d, R, cls_name, plevel)
        e = make_enemy(R, eid, lvl or d.enemies[eid]["level"], elite)
        pol = BasicOnly(R) if policy == "basic" else Policy(R)
        b = Battle(R, p, e, profile, random.Random(seed + i), pol, None)
        won = b.run()
        wins += 1 if won else 0
        turns.append(b.p_turns)
        hp_lost.append((b.hp_start - max(0, p.hp)) / p.mhp)
    print("%s L%d %s vs %s L%d (%s policy, %s profile, %d battles): win %.1f%%  player turns mean %.2f (p90 %d)  HP lost %.0f%%" % (
        cls_name, plevel, "", enemy, lvl, policy, profile, n, 100.0 * wins / n, mean(turns), pct(turns, 0.9), 100 * mean(hp_lost)))
    return dict(win=wins / n, turns=mean(turns))


# ---------------------------------------------------------------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------------------------------------------------------------
def build_table(path, classes, profiles, runs, seed, jobs, policy="greedy", quiet=False, tweaks=None):
    d = Data(path, tweaks)
    table = {}
    t0 = time.time()
    for cls in classes:
        for prof in profiles:
            res = run_cell(path, cls, prof, runs, seed, jobs, policy, tweaks)
            table[(cls, prof)] = aggregate(res, d)
            if not quiet:
                print("  %s/%s: %d runs, win %.1f%% (%.0fs)" % (cls, prof, runs, 100 * table[(cls, prof)]["win_rate"], time.time() - t0), file=sys.stderr)
    return table


def parse_tweaks(items):
    out = []
    for it in items:
        k, v = it.rsplit("=", 1)
        try:
            val = json.loads(v)
        except ValueError:
            val = v
        out.append((k.strip(), val))
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description="DD-Project balance simulator (E1)")
    ap.add_argument("--runs", type=int, default=500)
    ap.add_argument("--class", dest="cls", default="knight", help="knight | archer | mage | nobody | all")
    ap.add_argument("--profile", default="average", help="novice | average | expert | all")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--jobs", type=int, default=max(1, min(8, (os.cpu_count() or 2) - 1)))
    ap.add_argument("--data", default=DEFAULT_DATA, help="export_data.json (run_tests.ps1 -Mode fast -Only exportdata)")
    ap.add_argument("--policy", default="greedy", choices=["greedy", "basic"])
    ap.add_argument("--json", help="write the aggregated table here")
    ap.add_argument("--fights", action="store_true", help="one matchup instead of whole runs (needs --enemy --level)")
    ap.add_argument("--enemy", default="slime")
    ap.add_argument("--level", type=int, default=0, help="enemy level (and the player's level in --fights)")
    ap.add_argument("--player-level", type=int, default=0, help="the player's level in --fights (default: the enemy's level)")
    ap.add_argument("--elite", default="", help="armored | venomous | swift | brutal | regenerating")
    ap.add_argument("--vectors", action="store_true", help="prove parity with combat-vectors.json and the export")
    ap.add_argument("--check", action="store_true", help="exit 1 when a number is outside tools/balance/targets.json")
    ap.add_argument("--tweak", action="append", default=[], help="what-if: section[key].field=value, e.g. enemies[palehorn].base_hp=45 (repeatable; the game is not touched)")
    ap.add_argument("--snapshot", help="copy this export_data.json to tools/balance/export_data.json (the committed data)")
    a = ap.parse_args(argv)
    tweaks = parse_tweaks(a.tweak)

    if a.snapshot:
        with open(a.snapshot, encoding="utf-8") as f:
            raw = json.load(f)
        with open(DEFAULT_DATA, "w", encoding="utf-8", newline="\n") as f:
            json.dump(raw, f, indent=1, sort_keys=True)
            f.write("\n")
        print("wrote", DEFAULT_DATA, "build", raw.get("build"))
        return 0
    if a.vectors:
        return 0 if check_vectors(a.data) else 1
    if a.fights:
        matchup(a.data, a.cls if a.cls != "all" else "knight", a.enemy, a.level, a.profile if a.profile != "all" else "average", a.runs, a.seed, a.policy, a.elite, tweaks, a.player_level)
        return 0
    classes = list(CLASS_IDS) if a.cls == "all" else [a.cls]
    profiles = list(PROFILES) if a.profile == "all" else [a.profile]
    if a.check:
        T = load_targets()
        classes = T.get("check_classes", list(CLASS_IDS))
        profiles = list(PROFILES)
        a.runs = T.get("check_runs", 300)
        a.seed = T.get("check_seed", 20261014)
    ok_vec = True
    table = build_table(a.data, classes, profiles, a.runs, a.seed, a.jobs, a.policy, tweaks=tweaks)
    print_table(table)
    if a.json:
        with open(a.json, "w", encoding="utf-8") as f:
            json.dump({"%s/%s" % k: v for k, v in table.items()}, f, indent=1, default=str)
    if a.check:
        T = load_targets()
        res = evaluate(table, T)
        bad = [r for r in res if not r["ok"]]
        print()
        for r in bad:
            print("OUT OF TARGET %-26s %-8s %-8s value %s band %s %s" % (r["id"], r["cell"][0], r["cell"][1], ("%.3f" % r["value"]) if isinstance(r["value"], float) else r["value"], r["band"], r.get("note", "")))
        print("%d checks, %d outside targets" % (len(res), len(bad)))
        return 1 if bad else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
