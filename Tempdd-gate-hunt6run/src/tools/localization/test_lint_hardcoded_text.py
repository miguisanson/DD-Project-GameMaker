#!/usr/bin/env python3
"""Self-check for lint_hardcoded_text.py: python tools/localization/test_lint_hardcoded_text.py"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lint_hardcoded_text as lint


class PlaceholderTests(unittest.TestCase):
    def test_pure_placeholders_are_not_text(self):
        for s in ("{n}", "{a}/{b}", "{n}%", " {n} ", "{hp} / {max_hp}", "#{n}"):
            self.assertFalse(lint.looks_player_facing(s), s)

    def test_english_around_a_placeholder_is_flagged(self):
        for s in ("Lv {n}", "Seed {n}", "{n} gold", "You deal {n} damage"):
            self.assertTrue(lint.looks_player_facing(s), s)

    def test_plain_english_still_flagged(self):
        self.assertTrue(lint.looks_player_facing("Press Start"))

    def test_existing_allowances_still_hold(self):
        for s in ("", "menu_up", "ui_confirm", "HP", "{killer}", "12"):
            self.assertFalse(lint.looks_player_facing(s), s)

    def test_literal_scan_on_a_gml_line(self):
        line = 'Ui_Text(x, y, string_replace_all(tpl, "{n}", string(v)), c);'
        self.assertEqual([t for t in lint.iter_literals(line) if lint.looks_player_facing(t)], [])


if __name__ == "__main__":
    unittest.main()
