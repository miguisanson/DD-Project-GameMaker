"""Unit tests for the audio tools (R-119).
Run inside the venv that has soundfile, numpy and pyloudnorm:
    python -m unittest discover -s tools/audio -p "test_*.py"
They write only into a temp folder."""
import json
import math
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np
import soundfile as sf


def sine(freq, seconds, amp, rate=44100):
    t = np.arange(int(seconds * rate)) / rate
    return amp * np.sin(2 * math.pi * freq * t)


class MeasureTests(unittest.TestCase):
    def test_known_sine_level(self):
        import measure_loudness as ml
        # 997 Hz at amplitude 0.1: RMS -23.01 dBFS, K-weighting is about 0 dB there, so about -23 LUFS; peak -20 dBFS
        m = ml.measure_array(sine(997, 3.0, 0.1), 44100)
        self.assertAlmostEqual(m["integrated_lufs"], -23.0, delta=0.3)
        self.assertAlmostEqual(m["momentary_max_lufs"], -23.0, delta=0.3)
        self.assertAlmostEqual(m["sample_peak_dbfs"], -20.0, delta=0.1)
        self.assertAlmostEqual(m["true_peak_dbfs"], -20.0, delta=0.3)
        self.assertAlmostEqual(m["duration_s"], 3.0, delta=0.01)

    def test_six_db_louder_reads_six_louder(self):
        import measure_loudness as ml
        a = ml.measure_array(sine(997, 2.0, 0.05), 44100)
        b = ml.measure_array(sine(997, 2.0, 0.10), 44100)
        self.assertAlmostEqual(b["integrated_lufs"] - a["integrated_lufs"], 6.02, delta=0.1)

    def test_short_clip_uses_the_whole_clip(self):
        import measure_loudness as ml
        m = ml.measure_array(sine(997, 0.2, 0.1), 44100)   # shorter than the 400 ms block
        self.assertAlmostEqual(m["momentary_max_lufs"], -23.0, delta=0.8)
        self.assertEqual(m["momentary_max_lufs"], m["integrated_lufs"])

    def test_measure_file_and_json(self):
        import measure_loudness as ml
        with tempfile.TemporaryDirectory() as root:
            os.makedirs(os.path.join(root, "sounds", "tone_a"))
            os.makedirs(os.path.join(root, "sounds", "overall_bgm"))
            sf.write(os.path.join(root, "sounds", "tone_a", "tone_a.wav"), sine(997, 1.0, 0.2), 44100)
            sf.write(os.path.join(root, "sounds", "overall_bgm", "overall_bgm.wav"), sine(997, 2.0, 0.1), 44100)
            out = os.path.join(root, "loudness.json")
            ml.main(["--root", root, "--out", out])
            with open(out) as fh:
                d = json.load(fh)
            self.assertEqual(sorted(d), ["overall_bgm", "tone_a"])
            self.assertAlmostEqual(d["tone_a"]["judged_lufs"], -17.0, delta=0.3)
            self.assertAlmostEqual(d["overall_bgm"]["judged_lufs"], -23.0, delta=0.3)   # a loop: judged by integrated


class TableTests(unittest.TestCase):
    def test_gain_math(self):
        import gain_config as cfg
        # a SFX measured at -30 LUFS (peak -20) is raised to the -22 target: +8 dB
        self.assertEqual(cfg.desired_gain_db("some_sfx", {"judged_lufs": -30.0, "sample_peak_dbfs": -20.0}), 8.0)
        # a loud one is cut: -5 -> -22 is -17
        self.assertEqual(cfg.desired_gain_db("some_sfx", {"judged_lufs": -5.0, "sample_peak_dbfs": -1.0}), -17.0)
        # UI is 3 dB below SFX
        self.assertEqual(cfg.desired_gain_db("Modern5", {"judged_lufs": -25.0, "sample_peak_dbfs": -10.0}), 0.0)
        # a loop aims at -24
        self.assertEqual(cfg.desired_gain_db("overall_bgm", {"judged_lufs": -24.0, "sample_peak_dbfs": -9.0}), 0.0)
        # the boss roar stays 2 dB louder
        self.assertEqual(cfg.desired_gain_db("Monster_Roar_9", {"judged_lufs": -22.0, "sample_peak_dbfs": -9.0}), 2.0)
        # the peak ceiling wins over the target (-3 dBFS peak, ceiling -1.9: at most +1.0 after rounding to half a dB)
        self.assertEqual(cfg.desired_gain_db("some_sfx", {"judged_lufs": -40.0, "sample_peak_dbfs": -3.0}), 1.0)

    def test_groups(self):
        import gain_config as cfg
        self.assertEqual(cfg.group_of("Modern14"), "ui")
        self.assertEqual(cfg.group_of("Crying_moaning_ambience_2"), "ambience")
        self.assertEqual(cfg.group_of("forest_bgm__for_everymap_with_trees"), "music")
        self.assertEqual(cfg.group_of("fireball"), "sfx")

    def test_the_committed_table_passes_the_check(self):
        import check_gain_table as chk
        root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        self.assertEqual(chk.main(["--root", root]), 0)

    def test_check_flags_a_loud_sound(self):
        import check_gain_table as chk
        loud = {"fireball": {"judged_lufs": -8.0, "sample_peak_dbfs": -0.1}}
        fails, _ = chk.evaluate(loud, {"fireball": 0.0})
        self.assertEqual(len(fails), 2)          # 14 dB above target and a peak above -1 dBFS
        fails, _ = chk.evaluate(loud, {"fireball": -14.0})
        self.assertEqual(fails, [])


if __name__ == "__main__":
    unittest.main()
