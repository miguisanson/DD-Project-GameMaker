# Importing the merchant sprite (owner, in the GameMaker IDE)

Files: `art/merchant/spr_merchant_idle/` has `spr_merchant_idle_0.png`, `spr_merchant_idle_1.png` (16x16, transparent) and `spr_merchant_idle_strip.png` (32x16, both frames). Recommended candidate: C (see `merchant_preview.png`). Other candidates are in `art/merchant/candidates/` (`cand_A..D_*.png`); to use one instead, import its two frames under the same name.

## Steps
1. Asset Browser > Sprites > right-click > Create Sprite, name it `spr_merchant_idle` (exactly; the code looks it up by name).
2. In the Sprite Editor choose Import > Add from file, select `spr_merchant_idle_0.png` then `spr_merchant_idle_1.png` (two frames, in that order). Do not use the strip unless you slice it as 2 frames of 16x16.
3. Size 16 x 16. Origin: Custom, X 0 Y 0 (top-left, same as nobody_down, knight_down and the other characters; NOT bottom-centre).
4. Playback: 8 fps (the other characters' speed); for an idle bob 2 fps looks calmer. The merchant code currently sets `image_speed = 0`, so the bob only plays once the code uses it.
5. Collision mask: Automatic, Rectangle, tolerance 0, bounding box Automatic (matches the characters; expected box about x 1..14, y 1..15).
6. Texture group: same as the other character sprites (Default). Leave "Separate collision masks", 3D and pre-multiply alpha off. Save the project.

## Code (not changed here; for the build session)
- Look the sprite up with `asset_get_index("spr_merchant_idle")`. If it returns `-1`, fall back to the current placeholder (`nobody_down` with `image_blend = make_color_rgb(240, 200, 90)`) exactly as `Merchant_EnsureInRoom` in `scripts/scr_loot/scr_loot.gml` does today (D94). Note the existing lookup uses the name `"merchant_down"`; switch it to `"spr_merchant_idle"`.
- Keep the gold `image_blend` on the new sprite (D110): it is designed for that multiply. Set `image_speed = 0.25` (or similar) instead of 0 for the 2-frame bob; that is the only behaviour change the new sprite needs.
- Check on a pale floor and in the alcove (rm_floor8) at native scale: on a dark background the cloak merges with the wall, only the gold eyes and the pack show.

## Provenance
Pose and proportions were taken from a hand-built silhouette (`sources/structure_guide.png`) and rendered with ComfyUI (SDXL base 1.0 + pixel-art-xl LoRA + sdxl_vae_fp16_fix, img2img, `tools/comfy.py`). Raw renders for A, B, C are in `sources/`. The 16x16 sprites were then reduced to the 4-colour palette and hand-cleaned in `tools/cands.py` (the AI renders are a design reference at this size; the final pixels are placed by script). No external assets.
