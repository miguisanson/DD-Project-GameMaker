"""Measure the loudness of every sound under sounds/*/ and write tools/audio/loudness.json.

Per sound name (the asset folder name): integrated loudness (LUFS, gated, BS.1770), the
momentary maximum (400 ms window, 100 ms hop, K-weighted, LUFS), sample peak and true peak
(4x oversampled) in dBFS, and the duration. For a clip shorter than 400 ms the "integrated" and
"momentary_max" are both the K-weighted RMS of the whole clip (no padding, so a short hit is
not diluted). "judged_lufs" is what the gain table aims at: the integrated loudness for music and
ambience loops, the momentary maximum for every one-shot (a hit is judged by its loudest moment).

Needs soundfile, numpy, pyloudnorm (pip into a venv; nothing system-wide):
    python tools/audio/measure_loudness.py   (inside the venv)
Nothing here edits an audio file.
"""
import argparse
import json
import math
import os
import sys

import numpy as np
import pyloudnorm as pyln
import soundfile as sf
from scipy.signal import resample_poly

SILENCE_DB = -120.0
BLOCK_S = 0.400
HOP_S = 0.100
AUDIO_EXT = (".ogg", ".wav", ".mp3")

# Names of the looping music / ambience sounds (judged by integrated loudness, target -20 LUFS).
LOOP_NAMES = {
    "overall_bgm", "forest_bgm__for_everymap_with_trees", "Arrival", "The_Twilight_of_Camelot",
    "Ambience_haunting", "Ambience_haunting_2",
    "Crying_moaning_ambience", "Crying_moaning_ambience_2", "Crying_moaning_ambience_3",
}


def db(x):
    return SILENCE_DB if x <= 1e-12 else max(SILENCE_DB, 10.0 * math.log10(x))


def k_weight(data, rate):
    """Apply the BS.1770 K-weighting filters (pyloudnorm's own) to float data (frames, channels)."""
    meter = pyln.Meter(rate)
    out = np.array(data, dtype="float64", copy=True)
    for f in meter._filters.values():
        for ch in range(out.shape[1]):   # lfilter works along the last axis: filter one channel at a time
            out[:, ch] = f.apply_filter(out[:, ch])
    return out


def channel_gains(n):
    g = np.ones(n)
    if n >= 6:
        g[-2:] = 1.41
    return g


def weighted_mean_square(kdata, start, stop, gains):
    seg = kdata[start:stop]
    if seg.shape[0] == 0:
        return 0.0
    return float(np.sum(gains * np.mean(seg * seg, axis=0)))


def lufs_of_ms(ms):
    return SILENCE_DB if ms <= 1e-12 else max(SILENCE_DB, -0.691 + 10.0 * math.log10(ms))


def measure_array(data, rate):
    """Return a dict of measurements for float data in (frames, channels), values in dB."""
    if data.ndim == 1:
        data = data[:, None]
    frames = data.shape[0]
    duration = frames / float(rate)
    sample_peak = db(float(np.max(np.abs(data))) ** 2) if frames else SILENCE_DB
    # true peak: 4x oversampled
    try:
        up = resample_poly(data, 4, 1, axis=0)
        true_peak = db(float(np.max(np.abs(up))) ** 2)
    except Exception:
        true_peak = sample_peak
    true_peak = max(true_peak, sample_peak)
    gains = channel_gains(data.shape[1])
    block = int(round(BLOCK_S * rate))
    hop = int(round(HOP_S * rate))
    rms_dbfs = db(float(np.mean(data * data))) if frames else SILENCE_DB
    # K-weighted data with 1 s of lead-in so the filter state is settled? use the clip itself.
    kdata = k_weight(data, rate)
    if frames < block:
        ms = weighted_mean_square(kdata, 0, frames, gains)
        integrated = momentary = lufs_of_ms(ms)
    else:
        starts = list(range(0, frames - block + 1, hop))
        blocks = [weighted_mean_square(kdata, s, s + block, gains) for s in starts]
        loud = [lufs_of_ms(b) for b in blocks]
        momentary = max(loud)
        # BS.1770 gating: -70 absolute, then -10 LU relative
        keep = [b for b, l in zip(blocks, loud) if l > -70.0]
        if keep:
            rel = lufs_of_ms(sum(keep) / len(keep)) - 10.0
            keep2 = [b for b, l in zip(blocks, loud) if l > -70.0 and l > rel]
            integrated = lufs_of_ms(sum(keep2) / len(keep2)) if keep2 else lufs_of_ms(sum(keep) / len(keep))
        else:
            integrated = SILENCE_DB
    return {
        "integrated_lufs": round(integrated, 2),
        "momentary_max_lufs": round(momentary, 2),
        "rms_dbfs": round(rms_dbfs, 2),
        "sample_peak_dbfs": round(sample_peak, 2),
        "true_peak_dbfs": round(true_peak, 2),
        "duration_s": round(duration, 3),
    }



def measure_file(path):
    data, rate = sf.read(path, dtype="float64", always_2d=True)
    return measure_array(data, rate)


def judged(name, m):
    return m["integrated_lufs"] if name in LOOP_NAMES else m["momentary_max_lufs"]


def find_sounds(root):
    out = {}
    sounds_dir = os.path.join(root, "sounds")
    for name in sorted(os.listdir(sounds_dir)):
        d = os.path.join(sounds_dir, name)
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if f.lower().endswith(AUDIO_EXT):
                out[name] = os.path.join(d, f)
                break
    return out


def main(argv=None):
    ap = argparse.ArgumentParser()
    root_default = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    ap.add_argument("--root", default=root_default)
    ap.add_argument("--out", default=os.path.join(root_default, "tools", "audio", "loudness.json"))
    args = ap.parse_args(argv)

    result = {}
    for name, path in find_sounds(args.root).items():
        try:
            m = measure_file(path)
        except Exception as e:  # report and carry on; the gain table treats a missing sound as 0 dB
            print("FAILED %s: %s" % (name, e), file=sys.stderr)
            continue
        m["file"] = os.path.relpath(path, args.root).replace("\\", "/")
        m["judged_lufs"] = judged(name, m)
        m["loop"] = name in LOOP_NAMES
        result[name] = m

    with open(args.out, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(result, fh, indent=1, sort_keys=True)
        fh.write("\n")

    ranked = sorted(result.items(), key=lambda kv: kv[1]["judged_lufs"])
    print("%d sounds measured -> %s" % (len(result), args.out))
    print("15 loudest (judged LUFS, sample peak dBFS):")
    for n, m in ranked[::-1][:15]:
        print("  %-60s %7.2f %7.2f" % (n, m["judged_lufs"], m["sample_peak_dbfs"]))
    print("15 quietest:")
    for n, m in ranked[:15]:
        print("  %-60s %7.2f %7.2f" % (n, m["judged_lufs"], m["sample_peak_dbfs"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
