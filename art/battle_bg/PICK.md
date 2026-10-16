# Battle backgrounds: your pick list (D151)

Open `art/battle_bg/contact_sheet.png` (3x zoom; the magenta boxes are for review only: the small box is where the enemy stands, the
lower band is where the bottom panels sit). Each candidate is `art/battle_bg/candidates/<id>.png`, 160x144, exactly the four game colours.
Every candidate keeps the middle dark so the enemy reads; the brightest ground is at the bottom, under the panels.

**Update 2026-10-16: rows A, B and C are done (A1, B2, C3 imported). Only the boss row is open, and it is a redo (see below).**

Reply with one id per row, or "redo" (I regenerate that row with a new prompt/seed; about 1.5 minutes per row).

| Row | Used for | Candidates | My recommendation |
|---|---|---|---|
| A | floors 1-3, forest tunnel | A1, A2, A3 | **A1**: dark tunnel mouth in the middle, leaves on top. A2 has a pale blob right where the enemy stands; A3 is busy at the bottom. |
| B | floors 4-6, caves | B1, B2, B3 | **B2**: stalactites framing a dark passage, boulders low. B1 is also good (pale spot at the bottom). B3 has stray specks. |
| C | floors 7-9, ruins | C1, C2, C3 | **C3**: big arch with a dark doorway, columns on both sides. C1 is a close second (arch inside an arch, a bit busier in the middle). |
| D (redo) | boss arena, last stretch of the tunnel before the exit (eye-level, no top-down) | D4, D5, D6, D8, D9, D10, D11, D12, D13 (D7 discarded) | **D13**: roots and branches framing a dark tunnel, darkest middle, dirt path at the bottom. **D10**: leafy tree growth around a dark round tunnel mouth, also dark in the middle. |

Then follow `art/battle_bg/IMPORT.md` (now just one sprite, `spr_battle_bg_boss`, about 2 minutes). Until you import, the game keeps the old plain background, so nothing breaks.

Provenance: Stable Diffusion XL base 1.0 + Pixel Art XL LoRA (nerijs), ComfyUI on this PC (licence line in `art/CREDITS-ART.md`), then reduced
and recoloured by `art/battle_bg/tools/quantise.py` (8x8 average, 4-colour thresholds, light ordered dither, enemy zone darkened). Raw 1280x1152
renders are not kept in the repo (they were in `E:\Temp\h9-comfy\raw`); the seeds and prompts are in `art/battle_bg/tools/gen_bg.py`.

## Boss row redo (owner feedback 2026-10-16)

You said the first boss row (D1-D3) looked like a bird's-eye pig pen. They are removed. The new prompt (`boss`, then `boss2` in `tools/gen_bg.py`; the old one is kept there as `boss_v1`) asks for an eye-level view down the last stretch of the tunnel, rough walls on both sides, a faint opening far back, trees/roots/branches near it, and rejects top-down, fence, pen and arena. Nine kept candidates, all 160x144 and exactly the four game colours (checked pixel by pixel).

- **D13** (recommended): roots and branches curve in from both sides, the middle is the darkest of all, a pale dirt path sits low under the panels. Reads as a tunnel with the outside growing into it. It has no visible bright opening, so the "exit" is only implied.
- **D10** (second): tunnel mouth packed with leaves and tree growth, dark round middle for the enemy, light ground at the bottom. A little busier than D13.
- D4 and D11 show a bright patch of daylight at the top (the clearest "exit"), but the pale patch is next to the enemy area and the top is bright for a "dark" arena. D6 has two small pine branches at the top, rest is stone wall. D5, D8, D9, D12 are good eye-level tunnels with bare rock only (no trees).
- D7 was thrown away: the render came out with a white border, which became a bright dithered frame.
