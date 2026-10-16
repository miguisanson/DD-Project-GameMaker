"""Checks for the release packet (D188-D190, D194): tools/release/make_release.ps1 in dry-run mode, CREDITS.txt, README.txt, the licence files and the itch.io page.

Run:  python tools/release/test_make_release.py      (nothing is downloaded, E:\\Games is never written: every run points at a scratch folder)

The expected values come from the brief (the package layout, what is left out, the refusals) and from the credits report, not from the script's output.
"""
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
SCRIPT = os.path.join(HERE, "make_release.ps1")
SCRATCH_ROOT = os.environ.get("DD_TEST_TMP", r"E:\Temp")

PKG = "NO-HOPE-v1.0-windows"

# What the zip must hold (relative to the package folder), from the brief: the exe, data.win, data, fonts, localization, options.ini, README, CREDITS, LICENSES.
# Left out on purpose: the Igor leftovers (DD-Project.zip, igor.output.manifest), the localization working files, and the two fonts the code never loads (Noto Sans CJK, NanumGothic).
EXPECTED_FILES = {
    "NO HOPE.exe",
    "data.win",
    "options.ini",
    "data/game_data.json",
    "fonts/galmuri/Galmuri9.ttf",
    "fonts/galmuri/Galmuri11.ttf",
    "fonts/galmuri/OFL-Galmuri.txt",
    "localization/localization.json",
    "README.txt",
    "CREDITS.txt",
    "LICENSES/OFL-Galmuri.txt",
    "LICENSES/CC-BY-4.0-attribution.txt",
}

FAKE_OUT = [
    "DD-Project.exe", "data.win", "DD-Project.zip", "igor.output.manifest", "options.ini", "NanumGothic-Regular.ttf",
    "data/game_data.json",
    "fonts/NotoSansCJKkr-Regular.otf", "fonts/galmuri/Galmuri9.ttf", "fonts/galmuri/Galmuri11.ttf", "fonts/galmuri/OFL-Galmuri.txt",
    "localization/localization.json", "localization/game_text.xlsx", "localization/game_text.legacy.xlsx", "localization/equivalence_report.json",
    "localization/migration_map.csv", "localization/migration_report.json", "localization/runtime_parity_report.json",
]

# Every credit the brief and D190 name (the same list Test_ReleaseNeeds checks in the game).
NEEDS = ["NO HOPE", "PaleRook", "GameMaker", "Kenney 1-Bit Pack", "CC0", "Stable Diffusion", "Pixel Art XL", "Nathan Gibson", "Cyrex Studios",
         "Universal UI/Menu Soundpack", "CC BY 4.0", "Fesliyan Studios", "Atelier Magicae", "Beasts SFX Vol.1", "Monster SFX Vol.1", "YourPalRob",
         "Must-Have Horror Sound Effects", "Ifness", "Fantasy Vol. 3 Kingdoms", "rubberduck", "Ogrebane", "Darsycho", "OpenGameArt", "Galmuri", "Lee Minseo", "OFL",
         "Retro Gaming"]
URLS = ["cyrex-studios.itch.io/universal-ui-soundpack", "creativecommons.org/licenses/by/4.0", "fesliyanstudios.com", "ateliermagicae.itch.io/beasts-sfx-vol1",
        "ateliermagicae.itch.io/monster-sound-effects-vol1", "yourpalrob.itch.io/must-have-horror-sound-effects", "ifness.itch.io/fantasy-vol-3-kingdoms",
        "ifnessfreemusic.com", "opengameart.org", "kenney.nl", "dafont.com"]


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def run_ps(args, cwd=None):
    cmd = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", SCRIPT] + args
    p = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=cwd, timeout=300)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def make_fake_out(root):
    out = os.path.join(root, "out")
    for rel in FAKE_OUT:
        path = os.path.join(out, *rel.split("/"))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(b"x" * 16)
    return out


def make_repo(root, dirty):
    repo = os.path.join(root, "repo")
    os.makedirs(repo)
    env = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t", GIT_COMMITTER_NAME="t", GIT_COMMITTER_EMAIL="t@t")
    subprocess.run(["git", "init", "-q", repo], check=True)
    with open(os.path.join(repo, "a.txt"), "w") as f:
        f.write("a")
    subprocess.run(["git", "-C", repo, "add", "a.txt"], check=True, env=env)
    subprocess.run(["git", "-C", repo, "commit", "-q", "-m", "init"], check=True, env=env)
    if dirty:
        with open(os.path.join(repo, "b.txt"), "w") as f:
            f.write("untracked")
    return repo


class DryRun(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        os.makedirs(SCRATCH_ROOT, exist_ok=True)
        cls.tmp = tempfile.mkdtemp(prefix="dd-release-test-", dir=SCRATCH_ROOT)
        cls.out = make_fake_out(cls.tmp)
        cls.dest = os.path.join(cls.tmp, "Release")
        cls.clean = make_repo(os.path.join(cls.tmp, "clean"), False)
        cls.dirty = make_repo(os.path.join(cls.tmp, "dirty"), True)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def dry(self, repo=None, dest=None):
        return run_ps(["-DryRun", "-SourceDir", self.out, "-DestRoot", dest or self.dest, "-ProjectDir", repo or self.clean])

    def test_script_exists(self):
        self.assertTrue(os.path.isfile(SCRIPT), "tools/release/make_release.ps1 is missing")

    def test_dry_run_lists_exactly_the_package(self):
        code, text = self.dry()
        self.assertEqual(code, 0, text)
        files = set(re.findall(r"^FILE (.+)$", text, re.M))
        files = {f.strip().replace("\\", "/") for f in files}
        self.assertEqual(files, EXPECTED_FILES, text)

    def test_dry_run_names_the_zip_and_the_gate(self):
        code, text = self.dry()
        self.assertEqual(code, 0, text)
        self.assertIn(os.path.join(self.dest, PKG + ".zip"), text)
        self.assertRegex(text, r"(?m)^GATE .*run_tests\.ps1.* -Mode fast")
        self.assertIn(r"E:\Temp\dd-gate-release", text)

    def test_dry_run_writes_nothing(self):
        self.dry()
        self.assertFalse(os.path.exists(self.dest), "a dry run must not create the destination")

    def test_dirty_tree_is_reported_in_a_dry_run_and_refused_for_real(self):
        code, text = self.dry(repo=self.dirty)
        self.assertEqual(code, 0, text)
        self.assertIn("WOULD REFUSE", text)
        code, text = run_ps(["-SourceDir", self.out, "-DestRoot", self.dest, "-ProjectDir", self.dirty])
        self.assertEqual(code, 3, text)
        self.assertIn("REFUSED", text)
        self.assertFalse(os.path.exists(self.dest), "a refusal must not create the destination")

    def test_clean_tree_is_not_refused(self):
        code, text = self.dry(repo=self.clean)
        self.assertNotIn("WOULD REFUSE", text)
        self.assertIn("TREE clean", text)

    def test_destination_must_be_on_e(self):
        bad = r"C:\dd-release-test-never-created"
        code, text = self.dry(dest=bad)
        self.assertEqual(code, 2, text)
        self.assertIn("REFUSED", text)
        self.assertFalse(os.path.exists(bad))

    def test_free_space_is_checked(self):
        code, text = self.dry()
        self.assertRegex(text, r"(?m)^SPACE E: [0-9.]+ GB free")


class RealRun(unittest.TestCase):
    """The copy and the zip for real, into a scratch folder, with the gate skipped (a test hook that is refused for the E:/Games folder)."""

    @classmethod
    def setUpClass(cls):
        os.makedirs(SCRATCH_ROOT, exist_ok=True)
        cls.tmp = tempfile.mkdtemp(prefix="dd-release-real-", dir=SCRATCH_ROOT)
        cls.out = make_fake_out(cls.tmp)
        cls.dest = os.path.join(cls.tmp, "Release")
        cls.repo = make_repo(os.path.join(cls.tmp, "clean"), False)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def run_it(self, extra=None):
        return run_ps(["-SkipGate", "-SourceDir", self.out, "-DestRoot", self.dest, "-ProjectDir", self.repo] + (extra or []))

    def test_a_real_run_copies_and_zips_exactly_the_package(self):
        code, text = self.run_it()
        self.assertEqual(code, 0, text)
        pkg = os.path.join(self.dest, PKG)
        on_disk = set()
        for root, _dirs, files in os.walk(pkg):
            for f in files:
                on_disk.add(os.path.relpath(os.path.join(root, f), pkg).replace("\\", "/"))
        self.assertEqual(on_disk, EXPECTED_FILES)
        import zipfile
        z = zipfile.ZipFile(os.path.join(self.dest, PKG + ".zip"))
        names = {n for n in z.namelist() if not n.endswith("/")}
        self.assertEqual(names, {PKG + "/" + f for f in EXPECTED_FILES})
        self.assertTrue(all("\\" not in n for n in z.namelist()), "zip entries must use forward slashes")
        self.assertIsNone(z.testzip())
        self.assertIn("RELEASE OK", text)
        code, text = self.run_it()
        self.assertEqual(code, 6, text)   # never overwrites

    def test_skip_gate_is_refused_into_games(self):
        bad = r"E:\Games\dd-release-test-never-created"
        code, text = run_ps(["-SkipGate", "-SourceDir", self.out, "-DestRoot", bad, "-ProjectDir", self.repo])
        self.assertEqual(code, 2, text)
        self.assertFalse(os.path.exists(bad))


class Texts(unittest.TestCase):
    def test_credits_txt_has_every_credit_and_url(self):
        text = read(os.path.join(HERE, "CREDITS.txt"))
        for n in NEEDS:
            self.assertIn(n, text, n)
        for u in URLS:
            self.assertIn(u, text, u)
        low = text.lower()
        for bad in ("battle / boss", "owner's pick", "owner to supply", "pending", "tbd", "[owner"):
            self.assertNotIn(bad, low, bad)

    def test_credits_txt_carries_every_line_the_game_shows(self):
        loc = json.loads(read(os.path.join(REPO, "datafiles", "localization", "localization.json")))
        strings = loc["strings"] if "strings" in loc else loc
        text = re.sub(r"\s+", " ", read(os.path.join(HERE, "CREDITS.txt")))
        n = 0
        for key, val in strings.items():
            if not key.startswith("credits.") or key == "credits.hint":
                continue
            en = val["en"] if isinstance(val, dict) else val
            n += 1
            self.assertIn(re.sub(r"\s+", " ", en), text, key)
        self.assertGreaterEqual(n, 20, "the credits keys were not found in localization.json")

    def test_readme_explains_how_to_play_and_remove(self):
        text = read(os.path.join(HERE, "README.txt"))
        for need in ("NO HOPE", "Windows", "keyboard", "gamepad", "mouse", r"%LOCALAPPDATA%\DD_Project", "profile", "delete the folder", "CREDITS.txt"):
            self.assertIn(need.lower(), text.lower(), need)

    def test_licences_are_there(self):
        self.assertTrue(os.path.isfile(os.path.join(REPO, "datafiles", "fonts", "galmuri", "OFL-Galmuri.txt")))
        cc = read(os.path.join(HERE, "LICENSES", "CC-BY-4.0-attribution.txt"))
        for need in ("Nathan Gibson", "Cyrex Studios", "Ifness", "Justin Allan Arnold", "creativecommons.org/licenses/by/4.0", "Attribution 4.0 International"):
            self.assertIn(need, cc, need)


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    assert head[:8] == b"\x89PNG\r\n\x1a\n", path
    return struct.unpack(">II", head[16:24])


class ItchPage(unittest.TestCase):
    def setUp(self):
        self.text = read(os.path.join(HERE, "itch-page.md"))

    def test_sections(self):
        low = self.text.lower()
        for need in ("title", "tagline", "description", "features", "controls", "system requirements", "windows 10", "credits", "full credits in game", "ai-assisted",
                     "tags", "pay what you want", "screenshots", "NO HOPE".lower(), "PaleRook".lower()):
            self.assertIn(need, low, need)

    def test_no_stale_claims(self):
        low = self.text.lower()
        for bad in ("battle music", "boss music", "[owner", "tbd", "pending"):
            self.assertNotIn(bad, low, bad)

    def test_screenshots_are_640x576_and_numbered(self):
        d = os.path.join(HERE, "screenshots")
        names = sorted(os.listdir(d))
        self.assertEqual(names, ["%d.png" % i for i in range(1, 7)], names)
        for n in names:
            self.assertEqual(png_size(os.path.join(d, n)), (640, 576), n)
            self.assertIn(n, self.text, n)


if __name__ == "__main__":
    unittest.main(verbosity=2)
