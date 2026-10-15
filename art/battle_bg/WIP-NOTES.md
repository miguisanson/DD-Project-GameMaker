# H9 battle backgrounds: work-in-progress notes (2026-10-15)

Status: paused before any generation. No art, no code yet. Delete this file when `PICK.md` exists.

## Found (checked, not assumed)
- LoRA is ALREADY downloaded (2026-10-14, earlier icon work): `E:\AI\ComfyUI\ComfyUI-Shared\models\loras\pixel-art-xl.safetensors`,
  170,543,052 bytes, sha256 `4234637c...3eef7` = the LFS oid on huggingface.co/nerijs/pixel-art-xl (verified today). Do not re-download.
- Also present: `checkpoints\sd_xl_base_1.0.safetensors`, `vae\sdxl_vae_fp16_fix.safetensors`. No custom nodes needed (workflow in `art/tools/gen_v2.py`).
- ComfyUI is NOT running. Engine: `E:\AI\ComfyUI\ComfyUI-Installs\ComfyUI` (main.py), Python `...\ComfyUI\standalone-env\python.exe`,
  models via the Comfy Desktop shared-paths yaml. Start headless on 127.0.0.1:8188 (or open Comfy Desktop), then run a gen script like `art/tools/gen_v2.py`
  (checkpoint + LoraLoader + KSampler; swap the 1024x1024 latent for ~1280x1152, steps 24, cfg 6.5, dpmpp_2m/karras).
- Disk 2026-10-15: C: 81 GB free (at the floor: keep everything on E:), E: 181 GB free.
- Palette: `#071821 #306850 #86C06C #E0F8CF`; palette code in `art/tools/pp.py` / `pp2.py`. View 160x144.
- Battle is drawn by `objects/obj_battle_controller` / room `rm_battle`; existing sprite `battle_screen` exists. The draw call site was not yet read.
- D151 text is in the main checkout's DECISIONS.md (this worktree's copy lacks it; rebase on v1.9 when resuming).

## Left to do (task steps 2-6)
Generate 6-8 candidates per area (forest, caves, ruins, boss), downscale + 4-colour palette (darken centre band),
write `art/battle_bg/<area>/cand_<n>.png` + `spr_battle_bg_<area>.png`, contact sheet (3x, with enemy + HUD outlines), `PICK.md`, `IMPORT.md`,
then the small code change (new function at end of `scripts/scr_fx/scr_fx.gml`, one call line in battle draw, test suite in `scr_test.gml`, gate with
`-WorkRoot E:\Temp\dd-gate-h9`).
