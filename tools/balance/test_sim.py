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

    def test_stagger_fills_to_a_break_that_pushes_back_one_turn(self):  # D191: Slime rank 1 meter 12; Wooden Sword hit power 6 adds 3: the fourth hit breaks
        b = battle("knight", "slime")
        b.e.mhp = b.e.hp = 100
        self.assertEqual(b.e.smax, 12)
        g0 = b.gauge[1]
        for _ in range(3):
            b.stagger_hit(6.0, False, False)
        self.assertFalse(b.e.broken)
        b.stagger_hit(6.0, False, False)
        self.assertTrue(b.e.broken)
        self.assertEqual(b.gauge[1], g0 - 100)

    def test_a_multi_hit_skill_fills_like_one_hit_and_a_stun_skill_x1_5(self):   # D191
        b = battle("archer", "slime")
        b.e.mhp = b.e.hp = 100
        b.stagger_hit(6.0, False, False, 3)
        self.assertEqual(b.e.stagger, 3)                                   # one hit's 3, not 9
        b2 = battle("knight", "slime")
        b2.stagger_hit(6.0, True, False)
        self.assertEqual(b2.e.stagger, 5)                                  # 6 x 0.5 x 1.5 = 4.5 -> 5 (x2 gave 6)


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


class Script:
    """A scripted rng: random() pops the next value, randint() gives the low end, shuffle() keeps the order."""

    def __init__(self, vals):
        self.v = list(vals)

    def random(self):
        return self.v.pop(0)

    def randint(self, a, b):
        return a

    def shuffle(self, x):
        pass


class FairRng(unittest.TestCase):
    """R1 (D117-D121, D123). Expected values come from .planning/R1-CONTRACT.md, not from the simulator."""

    # ---- D117 tier first, then item ----
    def test_tier_roll_is_a_cascade_from_the_rarest(self):          # draw < high -> 3; else draw < mid / (1 - high) -> 2; else 1
        odds = [0.87, 0.115, 0.015]
        self.assertEqual(sim.roll_tier(Script([0.01]), odds), 3)
        self.assertEqual(sim.roll_tier(Script([0.5, 0.11]), odds), 2)        # 0.115 / 0.985 = 0.1168
        self.assertEqual(sim.roll_tier(Script([0.5, 0.12]), odds), 1)
        self.assertEqual(sim.roll_tier(Script([0.0, 0.0]), [1, 0, 0]), 1)    # high 0 and mid 0: always the low tier

    def test_tier_roll_guards_a_certain_high_tier(self):
        self.assertEqual(sim.roll_tier(Script([0.99]), [0, 0, 1]), 3)

    def test_export_without_tier_odds_uses_the_game_values(self):
        self.assertEqual(D.tier_odds["chest"], [[0.87, 0.115, 0.015], [0.65, 0.285, 0.065], [0.43, 0.38, 0.19]])
        self.assertEqual(D.tier_odds["barrel"][2], [0.74, 0.26, 0])
        self.assertEqual(D.tier_odds["enemy"][0], [0.914, 0.084, 0.002])

    def test_export_tier_odds_win_when_present(self):
        d2 = sim.Data(sim.DEFAULT_DATA, [("loot.tier_odds", {"chest": [[0.1, 0.2, 0.7]] * 3})])
        self.assertEqual(d2.tier_odds["chest"][0], [0.1, 0.2, 0.7])

    def run_with(self, script, cls="nobody", seed=3):
        run = sim.RunSim(D, cls, "average", seed, rules=R)
        run.rng = Script(script)
        return run

    def test_item_inside_the_tier_is_picked_by_its_row_weight_alone(self):
        # chest level 1, tier 3 rolled: rows 15 (w14), 18 (w12), 3 (w5), 6 (w5), 9 (w4), 22 (w4), 25 (w4) = 48. x = 0.30 * 48 = 14.4 -> item 18.
        run = self.run_with([0.0, 0.30])
        self.assertEqual(run.roll_table("chest", 1), (18, 1))

    def test_empty_tier_steps_down_then_up(self):
        t3 = (15, 18, 3, 6, 9, 22, 25)
        run = self.run_with([0.0, 0.0])                           # tier 3 rolled, none eligible -> tier 2, first row (item 14)
        self.assertEqual(run.roll_table("chest", 1, exclude=t3), (14, 1))
        t12 = tuple(r["item_id"] for r in D.loot["tables"]["chest"] if r["tier"] in (1, 2) and r["item_id"] > 0)
        run = self.run_with([0.9, 0.9, 0.0])                      # tier 1 rolled, tiers 1 and 2 empty -> up to tier 3, first row (item 15)
        self.assertEqual(run.roll_table("chest", 1, exclude=t12), (15, 1))

    def test_a_tier_two_roll_with_no_tier_two_rows_goes_down_first(self):
        t2 = tuple(r["item_id"] for r in D.loot["tables"]["chest"] if r["tier"] == 2 and r["item_id"] > 0)
        run = self.run_with([0.9, 0.0, 0.0])                      # not high; 0.0 < mid / (1 - high) -> tier 2; empty -> tier 1 first real row (item 10)
        self.assertEqual(run.roll_table("chest", 1, exclude=t2), (10, 1))

    # ---- D118 chests never empty ----
    def test_chest_ignores_the_nothing_row(self):
        run = self.run_with([0.9, 0.9, 0.0])                      # tier 1, first row: the "Nothing found" row (item 0) is gone -> HP Potion (10)
        self.assertEqual(run.roll_table("chest", 1), (10, 1))

    def test_a_chest_roll_is_never_empty_and_gear_is_at_least_one(self):
        run = sim.RunSim(D, "nobody", "average", 3, rules=R)
        for lvl in (1, 2, 3):
            for _ in range(1500):
                got = run.roll_table("chest", lvl)
                self.assertIsNotNone(got)
                self.assertGreaterEqual(got[1], 1)

    def test_gear_row_gives_one_even_when_the_export_row_says_zero(self):
        run = self.run_with([0.9, 0.9, 0.75])                     # chest tier 1 (no nothing row): total 136, x = 102 -> Wooden Sword (item 1), row qty 0..1
        self.assertEqual(run.roll_table("chest", 1), (1, 1))

    def test_a_barrel_can_still_be_empty(self):
        run = self.run_with([0.9, 0.9, 0.0])                      # barrel tier 1, first row is "Nothing found"
        self.assertIsNone(run.roll_table("barrel", 1))

    # ---- D119 crit marble bag ----
    def test_bag_size_is_the_smallest_whole_count(self):
        self.assertEqual(sim.crit_bag_size(0.25), (4, 1))
        self.assertEqual(sim.crit_bag_size(0.5), (2, 1))
        self.assertEqual(sim.crit_bag_size(0.1), (10, 1))
        self.assertEqual(sim.crit_bag_size(0.15), (20, 3))
        self.assertEqual(sim.crit_bag_size(0.05), (20, 1))
        self.assertEqual(sim.crit_bag_size(0.3333), (20, 7))      # no n with n * p whole -> 20 marbles, round(6.666) reds
        self.assertEqual(sim.crit_bag_size(1.0), (1, 1))

    def aim(self, who):
        R.status_add(who, sim.CRIT_UP, 3, 1)

    def test_take_aim_crits_exactly_one_in_every_four(self):          # bonus 25 -> p 0.25 -> bag of 4 with 1 red
        b = battle("archer", seed=4)
        self.aim(b.p)
        for _ in range(10):
            self.assertEqual(sum(b.crit_roll(b.p) for _ in range(4)), 1)

    def test_no_crit_chance_means_no_bag_is_touched(self):
        b = battle("archer", seed=4)
        self.assertFalse(b.crit_roll(b.p))
        self.assertIsNone(b.p.crit_bag)

    def test_applying_take_aim_again_starts_a_fresh_bag(self):
        b = battle("archer", seed=4)
        self.aim(b.p)
        b.crit_roll(b.p)
        self.assertEqual(len(b.p.crit_bag["left"]), 3)
        self.aim(b.p)
        self.assertIsNone(b.p.crit_bag)
        b.crit_roll(b.p)
        self.assertEqual(len(b.p.crit_bag["left"]), 3)

    def test_a_changed_chance_refills_the_bag(self):
        b = battle("archer", seed=4)
        self.aim(b.p)
        b.crit_roll(b.p)
        old = b.R.status_sum
        b.R.status_sum = lambda f, k: 50.0 if k == "crit_bonus" else old(f, k)
        try:
            b.crit_roll(b.p)
        finally:
            b.R.status_sum = old
        self.assertEqual(b.p.crit_bag["p"], 0.5)
        self.assertEqual(len(b.p.crit_bag["left"]), 1)            # bag of 2, one drawn

    def test_an_enemy_uses_the_same_bag(self):
        b = battle("archer", "slime", seed=4)
        self.aim(b.e)
        self.assertEqual(sum(b.crit_roll(b.e) for _ in range(4)), 1)

    # ---- D120 enemy-drop dry counter ----
    def test_drop_chance_rises_a_tenth_per_dry_fight_and_caps_at_one(self):
        self.assertAlmostEqual(sim.drop_chance(0.2, 0), 0.2)
        self.assertAlmostEqual(sim.drop_chance(0.2, 3), 0.5)
        self.assertEqual(sim.drop_chance(0.2, 20), 1.0)

    def test_dry_counter_goes_up_on_nothing_and_resets_on_an_item(self):
        e = sim.make_enemy(R, sim.ENEMY_IDS["slime"], 1)             # enemy_basic, level 1: 20% base
        run = self.run_with([0.45])
        run.enemy_drop(e)
        self.assertEqual(run.drop_dry, 1)                            # 0.45 is above 0.2 + 0
        run = self.run_with([0.45, 0.9, 0.9, 0.0])
        run.drop_dry = 3
        run.enemy_drop(e)                                            # chance 0.5 -> a drop: tier 1, first enemy row (HP Potion)
        self.assertEqual(run.drop_dry, 0)
        self.assertEqual(run.p.inv[10], 3)

    # ---- D123 / D145 elites per floor: none on floors 1 and 2 (hunt5a: the simulator used to give floor 2 at least one) ----
    def test_elite_count_rule(self):
        self.assertEqual(sim.elite_count(1, 0), 0)
        self.assertEqual(sim.elite_count(3, 0), 0)
        self.assertEqual(sim.elite_count(1, 3), 0)
        self.assertEqual(sim.elite_count(1, 10), 0)                  # D145: floor 1 has none, however many enemies
        self.assertEqual(sim.elite_count(1, 20), 0)
        self.assertEqual(sim.elite_count(2, 1), 0)                   # D145: floor 2 has none (was: at least one)
        self.assertEqual(sim.elite_count(2, 3), 0)
        self.assertEqual(sim.elite_count(2, 20), 0)
        self.assertEqual(sim.elite_count(3, 1), 1)                   # from floor 3: at least one
        self.assertEqual(sim.elite_count(3, 3), 1)                   # round(0.45) = 0, raised to the minimum of 1
        self.assertEqual(sim.elite_count(4, 3), 1)
        self.assertEqual(sim.elite_count(4, 10), 2)                  # 1.5 rounds up
        self.assertEqual(sim.elite_count(5, 1), 1)
        self.assertEqual(sim.elite_count(4, 20), 3)
        self.assertEqual(sim.elite_count(6, 20), 3)
        self.assertEqual(sim.elite_count(9, 0), 0)

    def test_floors_1_and_2_have_no_elites_in_a_simulated_run(self):
        for seed in range(1, 25):
            run = sim.RunSim(D, "knight", "average", seed, rules=R)
            for f in (1, 2):
                lay, enemies = run.make_floor(f)
                self.assertTrue(len(enemies) > 0)
                self.assertEqual([el for (_, _, el) in enemies if el], [], "seed %d floor %s" % (seed, f))

    def test_each_floor_has_exactly_the_planned_number_of_elites(self):
        for seed in range(1, 25):
            run = sim.RunSim(D, "knight", "average", seed, rules=R)
            for f in (1, 2, 3, 4, 5, 6, 7, 8, 9, 9.5):
                lay, enemies = run.make_floor(f)
                free = len(lay["enemies_free"])
                n = sum(1 for (_, _, el) in enemies if el)
                self.assertEqual(n, sim.elite_count(int(f), free), "seed %d floor %s" % (seed, f))
                self.assertEqual(len(enemies), free + len(lay["enemies_fixed"]))


class MarbleBags(unittest.TestCase):
    """D126: marble bags for status chances, enemy moves, gold and finds; heals and ticks give their exact average."""

    def test_a_75_percent_bag_gives_three_in_four(self):
        store, rng = {}, random.Random(5)
        for _ in range(25):
            self.assertEqual(sum(sim.bag_draw(store, "k", 0.75, rng) for _ in range(4)), 3)

    def test_a_sure_or_impossible_chance_needs_no_bag(self):
        store, rng = {}, random.Random(5)
        self.assertTrue(sim.bag_draw(store, "k", 1, rng))
        self.assertFalse(sim.bag_draw(store, "k", 0, rng))
        self.assertEqual(store, {})

    def test_a_changed_chance_refills_the_bag(self):
        store, rng = {}, random.Random(5)
        sim.bag_draw(store, "k", 0.6, rng)
        self.assertEqual(len(store["k"]["left"]), 4)               # 3 of 5, one drawn
        sim.bag_draw(store, "k", 0.85, rng)
        self.assertEqual(len(store["k"]["left"]), 19)              # 17 of 20, one drawn

    def test_status_roll_is_a_bag_per_skill_per_user(self):
        b = battle("knight", "slime", seed=3)
        got = [b.status_roll(b.p, 7, 0.6) for _ in range(5)]
        self.assertEqual(sum(got), 3)
        other = [b.status_roll(b.e, 7, 0.6) for _ in range(5)]     # another user, another bag
        self.assertEqual(sum(other), 3)
        self.assertEqual(sum(b.status_roll(b.p, 8, 0.75) for _ in range(4)), 3)   # another skill, another bag

    def test_whole_number_weights(self):
        self.assertEqual(sim.int_weights([3, 1]), [3, 1])
        self.assertEqual(sim.int_weights([2, 2]), [1, 1])
        self.assertEqual(sim.int_weights([0.5, 1.5]), [1, 3])
        self.assertEqual(sum(sim.int_weights([37, 61, 11])) <= 41, True)

    def test_a_4_to_1_enemy_uses_its_rare_move_once_in_five(self):   # the Slime: attack 4, Solidify 1 (its hurt rule does not hold at full health)
        b = battle("knight", "slime", seed=9)
        picks = [b.ai_choose(b.e, b.p, [])[1] for _ in range(50)]
        for d in range(10):
            self.assertEqual(sum(1 for x in picks[d * 5:d * 5 + 5] if x != -1), 1)

    def test_a_rule_with_a_chance_uses_its_own_bag(self):
        b = battle("knight", "slime", seed=9)
        b.e.brain = dict(rules=[dict(label="h", when=[], act="skill", skill=b.e.skills_e[0], chance=0.5, max_uses=-1)], weights=[dict(act="attack", skill=-1, w=1)], phases=[])
        picks = [b.ai_choose(b.e, b.p, [])[1] for _ in range(20)]
        for i in range(10):
            self.assertEqual(sum(1 for x in picks[i * 2:i * 2 + 2] if x != -1), 1)

    def test_heals_and_ticks_give_their_average(self):
        self.assertEqual(sim.tick_amount(2, 4), 3)
        self.assertEqual(sim.tick_amount(5, 10), 8)                  # 7.5 rounds up
        self.assertEqual(sim.item_amount(R, sim.new_player(R, sim.CLASS_IDS["knight"]), {"min": 4, "max": 8}, random.Random(1)), 6)

    def test_gold_offsets_average_out(self):
        offs = sim.gold_offsets(0.25)
        self.assertEqual(offs, [-0.25, -0.125, 0.0, 0.125, 0.25])
        self.assertAlmostEqual(sum(offs), 0)

    def test_the_find_bag_gives_three_in_ten(self):
        store, rng = {}, random.Random(2)
        self.assertEqual(sum(sim.bag_draw(store, "find", 0.3, rng) for _ in range(10)), 3)


class WeakPoints(unittest.TestCase):
    """D173 (IDEA-07): the simulator plays WeakPoint_Table (scr_status): +1 Burning turn (cap 4), +1 stack (never past 10 / 3), chance halved and rounded down to a whole percent."""

    def foe(self, weak=-1, resist=-1):
        e = sim.F("x", False)
        e.weak, e.resist = weak, resist
        return e

    def test_a_weak_enemy_burns_one_turn_longer_up_to_four(self):
        e = self.foe(weak=sim.BURN)
        self.assertEqual(R.wp_adjust(e, sim.BURN, 2, 1), (3, 1))
        self.assertEqual(R.wp_adjust(e, sim.BURN, 3, 1), (4, 1))
        self.assertEqual(R.wp_adjust(e, sim.BURN, 4, 1), (4, 1))
        self.assertEqual(R.wp_adjust(self.foe(), sim.BURN, 2, 1), (2, 1))

    def test_stacks_stop_at_the_d78_caps(self):
        e = self.foe(weak=sim.POISON)
        self.assertEqual(R.wp_adjust(e, sim.POISON, 1, 2), (1, 3))
        R.status_add(e, sim.POISON, 1, 1, 8)
        self.assertEqual(R.wp_adjust(e, sim.POISON, 1, 2), (1, 2))        # 8 + 2 reaches the cap of 10: no room for the bonus
        b = self.foe(weak=sim.BLEED)
        R.status_add(b, sim.BLEED, 3, 0, 2)
        self.assertEqual(R.wp_adjust(b, sim.BLEED, 3, 1), (3, 1))         # 2 + 1 + 1 would pass the cap of 3

    def test_a_resisted_chance_is_halved_and_rounded_down(self):
        e = self.foe(resist=sim.POISON)
        self.assertEqual(R.wp_resist_chance(e, sim.POISON, 0.75), 0.37)
        self.assertEqual(R.wp_resist_chance(e, sim.POISON, 1), 0.5)
        self.assertEqual(R.wp_resist_chance(e, sim.POISON, 0.65), 0.32)
        self.assertEqual(R.wp_resist_chance(e, sim.BURN, 0.75), 0.75)
        p = sim.F("p", True)
        p.resist = sim.POISON
        self.assertEqual(R.wp_resist_chance(p, sim.POISON, 0.75), 0.75)   # never on the player

    def test_the_rule_is_off_when_the_data_has_no_weak_points(self):
        e = sim.make_enemy(R, sim.ENEMY_IDS["slime"], 1)
        if "weak" not in R.d.enemies[sim.ENEMY_IDS["slime"]]:
            self.assertEqual((e.weak, e.resist), (-1, -1))


class ExportCarriesWeakPoints(unittest.TestCase):
    """R-118: the committed export is the CURRENT build's (the weak / resist fields of D173 are in it), so the simulator plays weak points. Expected: scr_db_enemy.gml."""

    def test_every_enemy_has_a_weak_and_a_resist_field(self):
        for eid, e in D.enemies.items():
            self.assertIn("weak", e, e["name"])
            self.assertIn("resist", e, e["name"])

    def test_the_lists_are_the_games(self):
        want = {0: (sim.BURN, sim.BLEED), 1: (sim.BLEED, sim.POISON), 2: (sim.POISON, sim.BLEED), 3: (sim.BURN, sim.POISON), 7: (sim.BLEED, sim.BURN), 8: (sim.BURN, -1), 9: (sim.POISON, -1)}   # slime, wolf, ghost sword, spider, stranger, mini boss, final boss
        for eid, (w, r) in want.items():
            e = sim.make_enemy(R, eid, 1)
            self.assertEqual((e.weak, e.resist), (w, r), D.enemies[eid]["name"])

    def test_the_braced_status_is_in_the_export(self):               # D180: STATUS_BRACE 14, every hit half until the player's next turn
        s = D.status[sim.BRACED]
        self.assertEqual(s["guard_mult"], 0.5)
        self.assertTrue(s["until_player_turn"])


class GuardCommand(unittest.TestCase):
    """D99 / D180: Guard spends the turn; every hit until the player's next turn deals half; max(2, floor(25% max MP)) MP comes back, never above max MP."""

    def test_mp_gain_is_a_quarter_of_max_rounded_down_at_least_two_capped(self):
        b = battle("mage")
        b.p.mmp, b.p.mp = 26, 0
        self.assertEqual(b.guard_mp_gain(), 6)                       # floor(6.5)
        b.p.mmp = 11
        self.assertEqual(b.guard_mp_gain(), 2)                       # floor(2.75) = 2
        b.p.mmp = 7
        self.assertEqual(b.guard_mp_gain(), 2)                       # floor(1.75) = 1 -> at least 2
        b.p.mmp, b.p.mp = 26, 24
        self.assertEqual(b.guard_mp_gain(), 2)                       # only 2 fit
        b.p.mp = 26
        self.assertEqual(b.guard_mp_gain(), 0)

    def test_guard_restores_mp_and_braces(self):
        b = battle("mage")
        b.p.mmp, b.p.mp = 26, 3
        b.p_guard()
        self.assertEqual(b.p.mp, 9)
        self.assertTrue(sim.st_has(b.p, sim.BRACED))

    def test_a_braced_player_takes_half_of_a_hit(self):
        b = battle("knight", "dire_wolf", 3)
        base = sim.ref.damage(float(b.e.basic_power), R.eff(b.e, "atk"), R.eff(b.p, "df"), 1.0, 1.0)
        half = sim.ref.damage(float(b.e.basic_power), R.eff(b.e, "atk"), R.eff(b.p, "df"), 1.0, 0.5)
        self.assertGreater(base, half)
        b.p_guard()
        b.p.hp = b.p.mhp
        got = b.hit(b.e, b.p, float(b.e.basic_power), "atk", 1.0, False)
        self.assertEqual(got, half)

    def test_brace_outlives_the_players_own_tick_and_ends_at_his_next_turn_after_an_enemy_turn(self):
        b = battle("knight", "slime", 1)
        b.p_guard()
        R.tick(b.p, random.Random(1), True)                         # the end of the guarding turn
        self.assertTrue(sim.st_has(b.p, sim.BRACED))
        b.player_turn_start()                                        # up again before the enemy acted (a fast player): still braced
        self.assertTrue(sim.st_has(b.p, sim.BRACED))
        b.enemy_turn()
        self.assertTrue(sim.st_has(b.p, sim.BRACED))                 # it lasts until the player's turn STARTS
        b.player_turn_start()
        self.assertFalse(sim.st_has(b.p, sim.BRACED))


class GuardPolicy(unittest.TestCase):
    """The greedy player guards (1) when the enemy is winding up a heavy hit that would take a quarter of his max HP or more, (2) when a caster cannot pay for any skill in a fight that is not easy and HP is not low."""

    def test_guards_into_a_telegraphed_heavy_hit(self):
        b = battle("knight", "palehorn", 8)
        b.p.hp = b.p.mhp
        b.e.ai["windup"] = next(s for s in b.e.skills_e if R.skills[s].get("telegraphed"))
        self.assertGreaterEqual(sim.Policy(R).next_hit(b), 0.25 * b.p.mhp)
        self.assertEqual(sim.Policy(R).choose(b), ("guard",))

    def test_does_not_guard_into_a_small_hit(self):
        b = battle("knight", "slime", 1)
        b.e.ai["windup"] = -1
        self.assertNotEqual(sim.Policy(R).choose(b), ("guard",))

    def test_a_caster_with_no_mp_for_any_skill_guards_in_a_hard_fight(self):
        b = battle("mage", "ghost_sword", 6)
        b.p.skills = [10, 11]
        b.p.mp = 0
        b.p.hp = b.p.mhp
        b.p.inv = {}
        self.assertEqual(sim.Policy(R).choose(b), ("guard",))

    def test_does_not_guard_when_a_skill_can_be_paid(self):
        b = battle("mage", "ghost_sword", 6)
        b.p.skills = [10]
        b.p.mp = b.p.mmp
        self.assertNotEqual(sim.Policy(R).choose(b), ("guard",))


class ForcedPick(unittest.TestCase):
    """D174: no Skip, one of the three cards is always taken. The greedy player's valuation must not make a card look good that only wastes turns: Meditation (+2..4 MP a turn) is worth
    only the MP that fits under max MP, so it is not cast with a full bar."""

    def meditate_score(self, mp):
        b = battle("mage", "ghost_sword", 6)
        b.p.skills = [13]
        b.p.mp = mp
        pol = sim.Policy(R)
        opts = pol.attack_options(b)
        return next(o for o in opts if o[0] == "skill" and o[1] == 13)[2]

    def test_meditation_is_worth_nothing_with_a_full_bar(self):
        b = battle("mage")
        self.assertEqual(self.meditate_score(b.p.mmp), 0.0)

    def test_meditation_is_worth_something_with_an_empty_bar(self):
        self.assertGreater(self.meditate_score(3), 0.0)

    def test_a_pick_is_always_made(self):
        r = sim.RunSim(D, "mage", "average", 3, "greedy", rules=R)
        r.p.picks = 4
        r.do_picks()
        self.assertEqual(len(r.rec["picks"]), 4)
        self.assertEqual(r.p.picks, 0)


def ref_burn(mag):
    return sim.ref.burn_tick(mag)


if __name__ == "__main__":
    unittest.main(verbosity=1)
