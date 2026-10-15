"""Builds art/sfx_new/*.wav (D116 extra monster takes) from the downloaded CC0 packs.

Run:  python -I art/tools/build_sfx_new.py <pack_dir> <ffmpeg.exe> [--out art/sfx_new]
<pack_dir> holds the unpacked downloads (default layout used on 2026-10-15):
  rd1/x/*.ogg   rubberduck "80 CC0 creature SFX"
  rd2/x/*.ogg   rubberduck "80 CC0 creture SFX #2"
  ogre/x/monster_sfx_pack/*.wav   Ogrebane "Monster Sound Effects Pack"
  snarl/*.ogg   Darsycho "Monster snarls"
and wav/old/<asset>.wav (the existing game sounds decoded to mono 44.1 kHz) used as the loudness reference.
Each take: cut, trim silence, 3 ms fade in / 15 ms fade out, mono 44.1 kHz 16-bit WAV, RMS matched to the
existing take of that monster and event (peak capped at -1 dBFS). Prints one table row per file.
"""
import sys, os, wave, subprocess, tempfile
import numpy as np

SR = 44100
PEAK_CAP = 10 ** (-1.0 / 20)
QUIET_FLOOR_DB = -34.0   # an existing take quieter than this is not copied; the new takes aim at TARGET_FOR_QUIET_DB
TARGET_FOR_QUIET_DB = -30.0

# (monster, event, n, pack, file, (start, end) or None, reference asset (existing take whose RMS is matched))
TAKES = [
 ("slime","spawn",2,"rd2","slime_08",None,"Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing"),
 ("slime","attack",2,"rd2","slime_01",None,"Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing"),
 ("slime","attack",3,"rd2","slime_04",None,"Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing"),
 ("spider","spawn",2,"rd1","bug_01",None,"spider_both_attack_and_spawn"),
 ("spider","attack",2,"rd1","bug_02",None,"Hiss"),
 ("spider","attack",3,"rd2","bug_12",None,"Hiss"),
 ("snake","spawn",2,"rd2","misc_14",None,"snake_spaawn_and_attack"),
 ("snake","attack",2,"rd2","attack_02",None,"snake_spaawn_and_attack"),
 ("snake","attack",3,"rd2","attack_03",None,"snake_spaawn_and_attack"),
 ("dire_wolf","spawn",2,"rd1","howl",None,"dire_wolf_spawn"),
 ("dire_wolf","attack",2,"rd1","barking_02",None,"dire_wolf_attack"),
 ("dire_wolf","attack",3,"snarl","monster-snarl-attack_0.ogg",(1.61,2.91),"dire_wolf_attack"),
 ("killer_plant","spawn",2,"rd1","burble_01",None,"killer_plant_spawn"),
 ("killer_plant","attack",2,"rd1","eat_04",None,"killer_plant_attack"),
 ("killer_plant","attack",3,"rd1","eat_03",None,"killer_plant_attack"),
 ("mad_whisp","spawn",2,"rd2","alien_08",None,"mad_whisp_spawn"),
 ("mad_whisp","attack",2,"rd1","alien_02",None,"mad_whisp_attack"),
 ("mad_whisp","attack",3,"rd2","alien_10",None,"mad_whisp_attack"),
 ("ghost_sword","spawn",2,"rd1","ooh",None,"ghost_sword_spawn"),
 ("ghost_sword","attack",2,"rd1","alien_05",None,"ghost_sword_attack"),
 ("ghost_sword","attack",3,"rd2","alien_11",None,"ghost_sword_attack"),
 ("stranger","spawn",2,"rd2","human_03",None,"Laugh_spooky_3"),
 ("stranger","attack",2,"rd2","human_07",None,"Monster_chatter"),
 ("stranger","attack",3,"rd2","human_05",None,"Monster_chatter"),
 ("mini_boss","spawn",2,"rd2","roar_04",None,"mini_boss_spawn"),
 ("mini_boss","attack",2,"ogre","monster-6",None,"mini_boss_attack"),
 ("mini_boss","attack",3,"ogre","monster-8",None,"mini_boss_attack"),
 ("final_boss","spawn",2,"rd1","roar_02",None,"final_boss_spawn"),
 ("final_boss","attack",2,"rd2","stomp_01",None,"Punch_1"),
 ("final_boss","attack",3,"snarl","monster-snarl-5.ogg",(2.02,3.49),"Punch_1"),
]

def path_for(base, pack, name):
    if pack == "rd1": return os.path.join(base, "rd1", "x", name + ".ogg")
    if pack == "rd2": return os.path.join(base, "rd2", "x", name + ".ogg")
    if pack == "ogre": return os.path.join(base, "ogre", "x", "monster_sfx_pack", name + ".wav")
    if pack == "snarl":
        return os.path.join(base, "snarl", name.replace("monster-snarl-attack_0.ogg", "monster-snarl-attack.ogg"))
    raise ValueError(pack)

def decode(ffmpeg, src):
    tmp = tempfile.mktemp(suffix=".wav")
    subprocess.run([ffmpeg, "-v", "error", "-y", "-i", src, "-ac", "1", "-ar", str(SR), "-sample_fmt", "s16", tmp], check=True)
    w = wave.open(tmp); x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768; w.close()
    os.remove(tmp)
    return x

def active(x):
    pk = np.abs(x).max()
    idx = np.where(np.abs(x) > pk * 0.03)[0]
    return x[idx[0]:idx[-1] + 1] if len(idx) else x

def db(v): return 20 * np.log10(max(v, 1e-9))

def rms_db(x): return db(np.sqrt(np.mean(active(x) ** 2)))

def trim(x):
    pk = np.abs(x).max(); thr = pk * 10 ** (-40 / 20)
    idx = np.where(np.abs(x) > thr)[0]
    a = max(0, idx[0] - int(0.010 * SR)); b = min(len(x), idx[-1] + 1 + int(0.020 * SR))
    return x[a:b].copy()

def fades(x):
    fi = int(0.003 * SR); fo = int(0.015 * SR)
    x[:fi] *= np.linspace(0, 1, fi); x[-fo:] *= np.linspace(1, 0, fo)
    return x

def main():
    base, ffmpeg = sys.argv[1], sys.argv[2]
    out = "art/sfx_new"
    if "--out" in sys.argv: out = sys.argv[sys.argv.index("--out") + 1]
    os.makedirs(out, exist_ok=True)
    print("file                         src_dur  ref_rms  target  new_rms  new_peak  note")
    for mon, ev, n, pack, name, seg, ref in TAKES:
        x = decode(ffmpeg, path_for(base, pack, name))
        if seg: x = x[int(seg[0] * SR):int(seg[1] * SR)]
        x = fades(trim(x))
        w = wave.open(os.path.join(base, "wav", "old", ref + ".wav")); r = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768; w.close()
        ref_db = rms_db(r)
        target = ref_db if ref_db >= QUIET_FLOOR_DB else TARGET_FOR_QUIET_DB
        g = 10 ** ((target - rms_db(x)) / 20)
        note = ""
        if np.abs(x).max() * g > PEAK_CAP:
            g = PEAK_CAP / np.abs(x).max(); note = "peak-capped"
        if ref_db < QUIET_FLOOR_DB: note += " ref-too-quiet"
        y = x * g
        fn = f"{mon}_{ev}_{n}.wav"
        pcm = np.clip(np.round(y * 32767), -32768, 32767).astype("<i2")
        wo = wave.open(os.path.join(out, fn), "wb"); wo.setnchannels(1); wo.setsampwidth(2); wo.setframerate(SR); wo.writeframes(pcm.tobytes()); wo.close()
        print(f"{fn:28s} {len(x)/SR:6.2f}s {ref_db:7.1f} {target:7.1f} {rms_db(y):8.1f} {db(np.abs(y).max()):8.1f}  {note}")

if __name__ == "__main__":
    main()
