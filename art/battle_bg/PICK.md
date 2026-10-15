# Battle backgrounds: your pick list (D151)

Open `art/battle_bg/contact_sheet.png` (3x zoom; the magenta boxes are for review only: the small box is where the enemy stands, the
lower band is where the bottom panels sit). Each candidate is `art/battle_bg/candidates/<id>.png`, 160x144, exactly the four game colours.
Every candidate keeps the middle dark so the enemy reads; the brightest ground is at the bottom, under the panels.

Reply with one id per row, or "redo" (I regenerate that row with a new prompt/seed; about 1.5 minutes per row).

| Row | Used for | Candidates | My recommendation |
|---|---|---|---|
| A | floors 1-3, forest tunnel | A1, A2, A3 | **A1**: dark tunnel mouth in the middle, leaves on top. A2 has a pale blob right where the enemy stands; A3 is busy at the bottom. |
| B | floors 4-6, caves | B1, B2, B3 | **B2**: stalactites framing a dark passage, boulders low. B1 is also good (pale spot at the bottom). B3 has stray specks. |
| C | floors 7-9, ruins | C1, C2, C3 | **C3**: big arch with a dark doorway, columns on both sides. C1 is a close second (arch inside an arch, a bit busier in the middle). |
| D | boss arena | D1, D2, D3 | **D2**: the arena rim with pillars and a dark far wall; D3 is the most "arena" (round floor) but darker and noisier. D1 has the least depth. |

Then follow `art/battle_bg/IMPORT.md` (4 sprites, about 5 minutes). Until you import, the game keeps the old plain background, so nothing breaks.

Provenance: Stable Diffusion XL base 1.0 + Pixel Art XL LoRA (nerijs), ComfyUI on this PC (licence line in `art/CREDITS-ART.md`), then reduced
and recoloured by `art/battle_bg/tools/quantise.py` (8x8 average, 4-colour thresholds, light ordered dither, enemy zone darkened). Raw 1280x1152
renders are not kept in the repo (they were in `E:\Temp\h9-comfy\raw`); the seeds and prompts are in `art/battle_bg/tools/gen_bg.py`.
