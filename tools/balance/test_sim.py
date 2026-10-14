#!/usr/bin/env python3
"""Checks for the balance simulator (packet E1). Expected values come from combat-spec.md (sections 4, 10, 11, 12) and the C2/C3 code, not from
the simulator's own output.   python tools/balance/test_sim.py
"""
import os
import random
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sim  # noqa: E402

D = sim.Data()
R = sim.Rules(D)


def battle(cls="knight", enemy="slime", level=1, profile="average", seed=1, elite=""):
    p = sim.new_player(R, sim.CLASS_IDS[cls])
    p.hp, p.mp = p.mhp, p.mmp
    e = sim.make_enemy(R, sim.ENEMY_IDS[enemy], level, elite)
    return sim.Battle(R, p, e, profile, random.Random(seed), sim.Policy(R), None)


class Vectors(unittest.TestCase):
    def test_reference_vectors_pass_through_the_simulator(self):
        self.assertTrue(sim.check_vectors())


class Statuses(unittest.TestCase):
    def test_poison_three_stacks_costs_six_hp_in_total(self):          # spec section 10: n(n+1)/2
        f = sim.F("x", False)
        f.mhp = f.hp = 50
        R.status_add(f, sim.POISON, 3, 1, 3)
        for _ in range(4):
            R.tick(f, random.Random(1))
        self.assertEqual(50 - f.hp, 6)
        self.assertFalse(sim.st_has(f, sim.POISON))

    def test_second_poison_adds_stacks(self):                           # 3 stacks, tick (-3, 2 left), +3 -> 5 stacks = 15 in all from there
        f = sim.F("x", False)
        f.mhp = f.hp = 50
        R.status_add(f, sim.POISON, 3, 1, 3)
        R.tick(f, random.Random(1))
        R.status_add(f, sim.POISON, 3, 1, 3)
        self.assertEqual(sim.st_stacks(f, sim.POISON), 5)

    def test_burn_ticks_its_power_for_two_turns_and_cuts_def(self):    # spec: Mage MAG 12 burns 4 x 2; DEF 7 -> 5
        f = sim.F("x", False)
        f.mhp = f.hp = 50
        f.st["df"] = 7
        R.status_add(f, sim.BURN, 2, ref_burn(12))
        self.assertEqual(R.eff(f, "df"), 5)
        R.tick(f, random.Random(1))
        R.tick(f, random.Random(1))
        self.assertEqual(50 - f.hp, 8)
        self.assertFalse(sim.st_has(f, sim.BURN))

    def test_bleeding_hurts_per_action_and_not_on_a_stunned_turn(self):  # 3 stacks = 6 per action; acted=False = 0
        f = sim.F("x", False)
        f.mhp = f.hp = 50
        R.status_add(f, sim.BLEED, 3, 1, 3)
        R.tick(f, random.Random(1), acted=False)
        self.assertEqual(f.hp, 50)
        R.action_tick(f)
        self.assertEqual(f.hp, 44)

    def test_foresight_upgrade_does_not_lengthen_it(self):             # Skill_AdjustStatusTurns: a status with a fixed duration ignores the skill's turns
        b = battle("mage")
        b.p.skills = [14]
        b.p.upgrades = [14]
        b.use_skill(b.p, b.p, 14)
        self.assertEqual(sim.st_find(b.p, sim.HIT_UP)["turns"], 3)


class Damage(unittest.TestCase):
    def test_guard_blocks_a_hit_completely_and_is_used_up(self):       # spec section 4: Guard = mult 0
        b = battle("knight", "slime")
        R.status_add(b.p, sim.GUARD, 6, 1)
        before = b.p.hp
        b.hit(b.e, b.p, 3.0, "atk")
        self.assertEqual(b.p.hp, before)
        self.assertFalse(sim.st_has(b.p, sim.GUARD))

    def test_enemy_basic_damage_matches_the_formula(self):             # Slime ATK 8 vs Knight DEF 12: 3*8/20 = 1.2 -> 1
        b = battle("knight", "slime")
        before = b.p.hp
        b.hit(b.e, b.p, 3.0, "atk")
        self.assertEqual(before - b.p.hp, 1)

    def test_break_gives_plus_fifty_percent(self):                     # vector dmg_12 logic: power 6, A 11, D 7 -> 4; x1.5 -> round(6*11*1.5/18 = 5.5) = 6
        b = battle("knight", "slime")
        b.e.st["df"] = 7
        b.p.st["atk"] = 11
        before = b.e.hp
        b.e.hp = b.e.mhp = 100
        b.e.broken = True
        d = b.hit(b.p, b.e, 6.0, "atk")
        self.assertEqual(d, 6)

    def test_throw_firebomb_burn_uses_thrower_stat_12_plus_level(self):   # Throw_BurnBase: burn_tick(13) = round(3.9) = 4 at OK
        b = battle("knight", "slime", 1)
        b.e.mhp = b.e.hp = 100
        b.p.inv = {30: 1}
        b.probs = (0.0, 0.0, 1.0, 0.0)   # always OK
        b.p_throw(30)
        self.assertEqual(sim.st_find(b.e, sim.BURN)["power"], 4)


class Timeline(unittest.TestCase):
    def test_archer_13_vs_slime_9_order(self):
        # Worked by hand from the gauge rule (P 13, E 9, act at 100, overflow kept, ties to the player): P(t8) E(t12) P(t16) E(t23) P(t24) P(t32) E(t34) ...
        # = PEPEPPEPE, which is also what the game's vector turn_13_9 says. (combat-spec.md section 11 prints "P E P P E P P E P" for this pair: a typo in the text.)
        b = battle("archer", "slime")
        b.p.st["spd"], b.e.st["spd"] = 13, 9
        order = "".join("PE"[b.tl_next()] for _ in range(9))
        self.assertEqual(order, "PEPEPPEPE")

    def test_stun_pushes_back_and_steadfast_blocks_the_second(self):
        b = battle("knight", "slime")
        b.p.st["spd"], b.e.st["spd"] = 10, 10
        b.tl_next()
        self.assertTrue(b.tl_stun(1))
        self.assertFalse(b.tl_stun(1))

    def test_stagger_fills_to_a_break_that_pushes_back_one_turn(self):  # Slime rank 1 meter 8; Wooden Sword hit power 6 adds 3
        b = battle("knight", "slime")
        b.e.mhp = b.e.hp = 100
        g0 = b.gauge[1]
        b.stagger_hit(6.0, False, False)
        b.stagger_hit(6.0, False, False)
        self.assertFalse(b.e.broken)
        b.stagger_hit(6.0, False, False)
        self.assertTrue(b.e.broken)
        self.assertEqual(b.gauge[1], g0 - 100)


class AI(unittest.TestCase):
    def test_killer_plant_winds_up_on_its_third_turn_and_a_break_cancels_it(self):  # spec section 12: every 3rd turn -> windup Vine Trap
        b = battle("knight", "killer_plant", 4)
        e = b.e
        kinds = []
        for turn in range(3):
            e.ai["turns"] = turn
            kinds.append(b.ai_choose(e, b.p, [])[0])
        self.assertEqual(kinds[2], "windup")
        e.ai["windup"] = 19
        b.windup_pending = True
        b.stagger_hit(100.0, True, True)
        self.assertEqual(e.ai["windup"], -1)

    def test_windup_is_followed_by_the_big_attack(self):
        b = battle("knight", "palehorn", 8)
        b.e.ai["windup"] = 23
        self.assertEqual(b.ai_choose(b.e, b.p, []), ("skill", 23, "windup_attack"))

    def test_boss_phase_adds_speed_and_attack(self):                   # Palehorn <= 60%: SPD +2; <= 30%: SPD +2, ATK +3
        b = battle("knight", "palehorn", 8)
        e = b.e
        spd0, atk0 = e.st["spd"], e.st["atk"]
        e.hp = int(e.mhp * 0.25)
        sim.ai_phase_sync(e)
        self.assertEqual((e.st["spd"], e.st["atk"]), (spd0 + 4, atk0 + 3))


class Economy(unittest.TestCase):
    def test_gold_of_a_level_5_rank_2_enemy_is_24_plus_minus_25_percent(self):   # (10 + 2*5) * 1.2
        g = D.eco
        base = sim.rhu((g["gold_base"] + g["gold_per_level"] * 5) * g["gold_rank2_mult"])
        self.assertEqual(base, 24)

    def test_card_offer_has_three_distinct_cards_and_forces_an_upgrade_after_two_dry_offers(self):
        run = sim.RunSim(D, "knight", "average", 7, rules=R)
        run.p.skills = [1]
        for _ in range(60):
            offer = run.offer()
            self.assertEqual(len(set(offer)), 3)
            self.assertTrue(all(run.eligible(D.cards[c]) for c in offer))
        # pity: with an upgrade possible, no three offers in a row without one
        run2 = sim.RunSim(D, "knight", "average", 8, rules=R)
        run2.p.skills = [1]
        dry = 0
        for _ in range(60):
            offer = run2.offer()
            if any(D.cards[c]["kind"] == "upgrade" for c in offer):
                dry = 0
            else:
                dry += 1
            self.assertLessEqual(dry, 2)

    def test_level_up_gives_a_pick_per_level_and_keeps_the_overflow(self):
        run = sim.RunSim(D, "knight", "average", 1, rules=R)
        run.sync_stats()
        gained = run.add_exp(12 + 24 + 5)
        self.assertEqual(gained, 2)
        self.assertEqual(run.p.level, 3)
        self.assertEqual(run.p.exp, 5)
        self.assertEqual(run.p.picks, 2)

    def test_runs_are_reproducible_per_seed(self):
        a = sim.RunSim(D, "mage", "average", 11, rules=R).play()
        b = sim.RunSim(D, "mage", "average", 11, rules=R).play()
        self.assertEqual((a["win"], a["level_end"], a["picks"], len(a["fights"])), (b["win"], b["level_end"], b["picks"], len(b["fights"])))

    def test_tweak_changes_the_what_if_data_only(self):
        d2 = sim.Data(sim.DEFAULT_DATA, [("enemies[palehorn].base_hp", 99)])
        self.assertEqual(d2.enemies[8]["base_hp"], 99)
        self.assertEqual(D.enemies[8]["base_hp"], 55)   # the game's Palehorn since D111 (it was 25)


def ref_burn(mag):
    return sim.ref.burn_tick(mag)


if __name__ == "__main__":
    unittest.main(verbosity=1)
