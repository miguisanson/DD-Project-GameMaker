"""One place for the loudness targets, the groups and the deliberate exceptions (R-119).

All levels are LUFS. The brief's relative targets were music/ambience -20, SFX -18, UI -21; the
whole set is shifted down 4 dB (K = -4) so that typical stacking of simultaneous sounds keeps
headroom below 0 dBFS. SFX and UI are judged by their momentary maximum (400 ms), loops by their
integrated loudness (see measure_loudness.py).
"""
import json
import os
import re

HEADROOM_SHIFT_DB = -4.0
TARGETS = {
    "sfx": -18.0 + HEADROOM_SHIFT_DB,       # -22
    "ui": -21.0 + HEADROOM_SHIFT_DB,        # -25  (3 dB below SFX)
    "music": -20.0 + HEADROOM_SHIFT_DB,     # -24
    "ambience": -20.0 + HEADROOM_SHIFT_DB,  # -24
}
TOLERANCE_DB = 3.0          # after the table every sound is within this of its group target
PEAK_CEILING_DBFS = -1.0    # after the table no sample peak is above this
GEN_PEAK_CEILING_DBFS = -1.9  # what the generator aims at (leaves room for the D116 +10 % volume variation, 0.83 dB)
MAX_BOOST_DB = 18.0
MIN_CUT_DB = -40.0
STEP_DB = 0.5               # table values are rounded to half a dB

MUSIC = {"overall_bgm", "forest_bgm__for_everymap_with_trees", "Arrival", "The_Twilight_of_Camelot",
         "Ambience_haunting", "Ambience_haunting_2"}
AMBIENCE_PREFIX = "Crying_moaning_ambience"
UI_PREFIXES = ("Modern", "Minimalist", "Retro", "Abstract", "African", "Coffee", "Wood_Block")

# Deliberate exceptions: name -> (offset dB from the group target, reason). All inside the +-3 dB band.
OFFSETS = {
    "Monster_Roar_5": (2.0, "boss/roar sound stays 2 dB louder (bloodthirsty)"),
    "Monster_Roar_9": (2.0, "boss/roar sound stays 2 dB louder (rampage)"),
    "Ghost_scream_3": (2.0, "final boss scream stays 2 dB louder (final fury)"),
    "mini_boss_spawn": (2.0, "boss entrance stays 2 dB louder"),
    "mini_boss_spawn_2": (2.0, "boss entrance stays 2 dB louder"),
    "final_boss_spawn": (2.0, "boss entrance stays 2 dB louder"),
    "final_boss_spawn_2": (2.0, "boss entrance stays 2 dB louder"),
}

# Old per-key trims (linear) that the table now replaces, as dB per sound, for the "before" figures only.
# Approximate: a sound shared by two keys keeps the louder of its trims.
def _db(x):
    import math
    return 20.0 * math.log10(x)

MONSTER_PREFIXES = ("slime_", "spider_", "mad_whisp_", "ghost_sword_", "mini_boss_", "final_boss_", "killer_plant_", "stranger_", "snake_")
MONSTER_KEY_SOUNDS = {"Hiss", "Monster_chatter", "Monster_chatter_2", "Monster_chatter_3", "Monster_chatter_4",
                      "Laugh_spooky_3", "Laugh_spooky_4", "Laugh_evil_deep_3", "Ghost_scream_3", "Monster_Roar_9",
                      "Bite_2", "Liquid_slosh", "Whip_2", "Fireball_2", "Knife_stab", "Dropping_keys",
                      "Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing"}


def legacy_trim_db(name):
    if name.startswith("dire_wolf_spawn"):
        return _db(0.3 * 0.8 * 0.9)
    if name.startswith("dire_wolf_"):
        return _db(0.8 * 0.9)
    if name == "Monster_Roar_5":
        return _db(0.8 * 0.8)
    if name == "Ambience_haunting":
        return _db(0.35)
    if name.startswith(MONSTER_PREFIXES) or name in MONSTER_KEY_SOUNDS:
        return _db(0.8)
    return 0.0


def group_of(name):
    if name in MUSIC:
        return "music"
    if name.startswith(AMBIENCE_PREFIX):
        return "ambience"
    if name.startswith(UI_PREFIXES):
        return "ui"
    return "sfx"


def target_of(name):
    return TARGETS[group_of(name)]


def desired_gain_db(name, m):
    """Table value (dB) for one measured sound: bring it to its target (+ deliberate offset), keep the peak under the ceiling."""
    want = target_of(name) + OFFSETS.get(name, (0.0, ""))[0] - m["judged_lufs"]
    want = min(want, GEN_PEAK_CEILING_DBFS - m["sample_peak_dbfs"])
    want = max(MIN_CUT_DB, min(MAX_BOOST_DB, want))
    return round(want / STEP_DB) * STEP_DB


def used_sound_names(root, all_names):
    """Sounds the game code can actually play: a quoted name in scr_sfx / scr_db_skill, or such a name plus _2.._5."""
    text = ""
    for rel in ("scripts/scr_sfx/scr_sfx.gml", "scripts/scr_db_skill/scr_db_skill.gml"):
        with open(os.path.join(root, rel), encoding="utf-8") as fh:
            text += fh.read()
    quoted = set(re.findall(r'"([A-Za-z0-9_ ]+)"', text))
    used = set()
    for n in all_names:
        if n in quoted:
            used.add(n)
        else:
            m = re.match(r"^(.*)_([2-5])$", n)
            if m and m.group(1) in quoted:
                used.add(n)
    return used


def load_loudness(root):
    with open(os.path.join(root, "tools", "audio", "loudness.json"), encoding="utf-8") as fh:
        return json.load(fh)
