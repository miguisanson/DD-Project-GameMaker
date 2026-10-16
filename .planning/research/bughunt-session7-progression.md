# Bug hunt session 7 - progression and economy (read-only, playtest build 7f4d08e, worktree DD-Project-GameMaker-wt/build)

Area: level-up (D143), EXP, cards (D81/D82), echo (D144), skill memory (D148), class pick and chest (D127), loot and chests (D117-D125), elites (D123/D145), merchant (D85/D113), gold, bag, gear, throwables, potions (D156), run stats (D137), seed (D152).
Method: read the code paths and traced scenarios by hand. Nothing was run or edited. Paths are relative to the build worktree. Not repeated: bughunt-session5/6 notes, review-opus-session6, ISSUES.md.
4 findings (1 x P2, 3 x P3). The rest of the area held up (see the last section).

## 1. P2 - A Nobody gets weapons and armor from chests, barrels, enemies and graves that it can never wear

- Where: `scripts/scr_loot/scr_loot.gml:155` (`Loot_ItemClassAllowed`: `if (class_id < 0 || class_id == CLASS_NOBODY) return true;`), used by `Loot_ItemEligibleForPlayer` :185-189 and so by `Loot_RollFromTable` :234 (chests, barrels, enemy drops) and `GraveLoot_RollTierItem` (`scr_interact.gml:149`). The wear rule is `Equip_CanEquip` (`scripts/scr_equip/scr_equip.gml:30-56`): every weapon has `preferred_class` Knight/Archer/Mage and every armor has `allowed_classes` without Nobody (`scr_db_item.gml` items 1-9, 20-25), so a chosen Nobody can wear none of them.
- Repro: win once (Nobody unlocks, D83/D131), start a run, pick Nobody at the class chest, open chests on floors 1-3. About 1 chest in 4 on floor 1 (24% of the common tier, 41% of the middle tier) answers "Received Wooden Sword x1" / "Iron Armor"; in the Gear tab the item is dimmed with "Knight only." Same for 14% of enemy drops from floor 3 (Iron/Platinum Sword and Bow) and for grave rewards. It can only be sold (half price).
- Violates: D118/D117 (a chest always gives an item that is a real reward); inconsistent with the merchant, which knows Nobody wears no gear and sells it throwables instead (`Shop_ClassOk` :521, test `scr_test.gml:6995` "Nobody is sold no gear (it cannot use any)"). Nobody is the hardest class and already has no skills, so a quarter of its chests being dead is felt.
- Fix idea: keep the `CLASS_NOBODY` shortcut only while `class_chosen` is false (the pre-class chest); for a chosen Nobody run the same check as `Shop_ClassOk`/`Equip_CanEquip` (so weapons and armor are skipped, accessories stay).

## 2. P3 - A potion says "Restores 8 HP" on the map and in the shop but heals more once you are level 2+ or hold Potion Lore

- Where: `scripts/scr_db_item/scr_db_item.gml:851-852` (`Item_Sentence`) and :897-898 (`Item_NumberLines`) print `Item_BaseAmount(use)` only. What `Item_Use` applies is `Item_ComputeAmount(user, use)` = base + `floor((level-1) x scale)` and then Potion Lore/Apothecary (:636-657, :679, :691). Only the battle list uses the real number (`scr_combat.gml:2885`, `2889`). The map Items tab (`scr_menu.gml:162-163`), the shop (`:2455-2456`, `:2488-2493`) and the echo/bag panels use the base.
- Repro: Knight, level 5, HP Potion Lv1. Tab > Items shows "Restores 8 HP", "HP 8". Use it at 1/30 HP: you get 12 (8 + 4 levels x 1.0); with Potion Lore 14. In a fight the same potion's panel says 12. HP Potion Lv3 at level 9: panel 28, applied 28 + floor(8 x 1.2) = 37. The messages after use ("Healed 12 HP.") then disagree with the line just read.
- Violates: D126 ("the details panel shows that one number"), D100/BUG-16 (the screen cannot disagree with the game). The tests only pin the shop line at level 1 (`scr_test.gml:7097`, `8284`) and the battle panel at level 5 (`5732`), so the two screens disagree by design of the tests.
- Fix idea: give `Item_Sentence` / `Item_NumberLines` the viewer (`_ch`, already passed to the latter) and print `Item_ComputeAmount(_ch, use)` when a character is known; the shop lists that go through `ShopUi_ItemFor` already have `_ch`.

## 3. P3 - A chest that rolls a throwable you already carry at the cap hands over nothing, and says "x0" (the same loss costs an enemy drop its bad-luck credit)

- Where: `scripts/scr_loot/scr_loot.gml:348-352` (`Loot_Grant`: `qty = min(qty, cap - held)`, `it.qty = qty`, `continue` at 0). The chest caller `scripts/scr_interact/scr_interact.gml:456-468` runs `MapFx_OpenedAt(loot)` first, grants, then reads `it.qty` (now 0) for the line: "Received Smoke Bomb x0." Also `Loot_RollEnemy` :335 (`run.drop_dry = is_struct(it) ? 0 : ...`) counts that unreceived throwable as a drop.
- Repro: floors 1-3, hold 5 of the band's throwable (Smoke Bomb; Firebomb on the other band-1 seed) as a non-Nobody. Open a chest: the floor-band extra row (weight 12 of about 148 in the common tier, `Loot_FloorExtras` :937) rolls it about 1 time in 15. Result: the burst rises with the bomb icon, the box says "x0", the bag is unchanged, the chest is spent. An enemy drop of the same bomb leaves no line at all and resets the +10%-per-fight counter (D120).
- Violates: D118 ("chests always give an item", no empty chests); D120 (the counter should reset only when an item is received).
- Fix idea: make `Loot_ItemEligibleForPlayer` refuse a throwable whose stack is already at `Throw_Cap` (same pattern as the owned-gear check), so the roll picks something else; that fixes chests, drops and graves in one place.

## 4. P3 - The level-up prompt shows only the last level's class growth and the last level's number when one fight gives several levels

- Where: `scripts/scr_menu/scr_menu.gml:1666` (`CardsUi_StatMenu`: title `ch.level`, note `LevelUp_GrowthText(ch.class_id, ch.level)`), banked points come from `LevelUp_ApplyLevel` (`scr_levelup.gml:146`). The prompt is opened once per banked point (`Cards_NextOwed` :278).
- Repro: Nobody (growth rotates, `LevelUp_ClassGrowthGain` :65-76) kills something worth two levels (L2 to L4). The stat prompt opens twice, both titled "Level 4: Place 1 Point" with "Nobody growth: ..." for level 4 only; the level-2 and level-3 gains (already applied to the stats) are never shown. Same before the class pick (a Nobody prompt whose growth is thrown away when `Card_ClassCharacter` rebuilds the stats from the real class).
- Violates: D143 ("SHOW the growth on the level-up screen" and the victory text no longer lists it, so this screen is the only place). Knight/Archer/Mage are constant per level so only the title is off for them.
- Fix idea: keep the list of levels gained this fight on the character (or show the sum from `last_growth`) and title the prompts "Level 3" then "Level 4"; at least show the summed growth on the first prompt.

## Looked at and found sound (no finding)

- Level-up maths and cards owed: `LevelUp_FromExp` carries the rest over, one pick and one point per level, `Cards_NextOwed` order, `Cards_ConsumePick`, skill-swap `skill_pending` and its Back, offers saved on the character (`offer`), picks wait for the class, no pick at the cap. Free point to a stat or Max HP/MP applies the number shown (`Cards_FreePointOptions` vs `Level_ApplyResourcePoint`); `Card_ClassCharacter` refunds spent points and the Max HP/MP bonus together.
- Cards: offer rules and pity (`Card_OfferGenerate`), upgrades keyed by skill id and removed with a replaced skill, the card text built from the same data as the effect (`Skill_WithUpgrade`), skip gold (+5 into `run.gold`), Coin Purse/Second Breath/Whetstone, stat passives re-applied on a class change.
- Echo (D144) and skill memory (D148): only skills of the picked class, not owned, drawn from a seed-made stream; every route to a skill goes through `Skill_Discover`.
- Loot: tier odds sum to 1 for every table and level, `Loot_RollTier` keeps the odds, chest/barrel loot comes from its own seed stream (`Shuffle_ChestLoot`), `drop_dry` is saved and the auto-resolve thinning keeps it right, owned gear is never rolled again.
- Merchant and gold: buy/sell never gives gold back beyond half the price, worn gear and key items refused, stock saved in the run so a reload does not restock, sold-out/owned/slots/gold refusals leave gold and the bag untouched, gold never goes below 0.
- Elites: none on floors 1-2, at least 1 from floor 3 (one room per floor, so "per room" equals "per floor"), guaranteed pick and double gold, never auto-resolved.
- Run stats (D137): counted on a live run only, saved and copied into the history. Seed (D152) for layout, chests, shop stock and cards is order-independent as the decisions require.

Minor, not counted: Equip passives and Aim Assist upgrade a GOOD press to PERFECT before `RunStats_Qte` counts it, so the run summary's Perfect rate is a little generous; `RunStats_Taken` counts the full blow including the part beyond 0 HP; Cold Focus (and Ember Lens) add no turns to Poison, only stacks (by design in `Skill_AdjustStatusTurns`, but the card text says "statuses ... last 1 turn longer").
