# ComfyUI pipeline for consistent pixel-art icons (status / skill / item)

Researched 2026-10-13. Read-only investigation: nothing was installed, downloaded or changed.

Evidence labels: **[local]** checked on this PC today. **[source]** read on the linked page.
**[known]** my own background knowledge, not re-checked today. **[inferred]** my reasoning, untested.
Anything marked [known] or [inferred] should be verified before you rely on it.

---

## 0. Local install findings (top of file, as requested)

**ComfyUI IS installed** (Comfy Desktop app, "Standalone" environment). **[local]**

| Item | Value |
|---|---|
| App (Electron shell) | `E:\ComfyDesktop\Comfy Desktop\Comfy Desktop.exe` (also a copy under `E:\AI\ComfyUI\App`) |
| Engine install | `E:\AI\ComfyUI\ComfyUI-Installs\ComfyUI` (ComfyUI v0.37.2, bundle v0.34.0-env1, Python 3.13.12, torch 2.12.1+cu130, ComfyUI-Manager 4.2.2). Launch arg `--enable-manager`. |
| Shared models root | `E:\AI\ComfyUI\ComfyUI-Shared\models` (wired in by `AppData\Roaming\Comfy Desktop\instance-model-paths\inst-1789696541215.yaml`) |
| Shared input / output | `E:\AI\ComfyUI\ComfyUI-Shared\input` and `...\output` (already holds images from a different project, `rpg-gm`: leave them alone; use a per-project filename prefix such as `dd_icons/`) |
| GPU seen by driver | NVIDIA GeForce RTX 4060, 8188 MiB, driver 616.92 |

**Models found (names and sizes only):**

| File | Size |
|---|---|
| `checkpoints\sd_xl_base_1.0.safetensors` | 6617 MB |
| `controlnet\controlnet-union-sdxl-1.0.safetensors` | 2396 MB (downloaded by `E:\AI\ComfyUI\get-controlnet.cmd`) |
| `upscale_models\RealESRGAN_x4plus.pth` | 64 MB |

- **LoRAs: none.** `loras`, `unet`, `vae`, `clip`, `text_encoders`, `ipadapter` folders are empty or absent. No Flux, no GGUF, no SD1.5.
- **Custom nodes: none** beyond ComfyUI's two example files (ComfyUI-Manager is installed as a Python package, so nodes can be installed from its UI).
  So no pixel-art nodes, no GGUF loader, no IPAdapter, no background-removal node yet.
- No StabilityMatrix, no portable ComfyUI, no other Comfy folder on D: or E: (searched to depth 3). `D:\` has nothing model-like.
- Ollama (local LLM) lives at `E:\AI\Ollama`; unrelated to images.

**Disk (df, today):** C: 232 GB total, **71 GB free (below your 80-90 GB floor already: do not put anything on C:)**.
D: 932 GB total, 375 GB free. E: 932 GB total, 270 GB free. Every download below should go under `E:\AI\ComfyUI\ComfyUI-Shared\models\...`
(or D:). ComfyUI-Manager installs custom nodes under the engine folder on E:, but pip dependencies go into the venv on E: too, so C: is untouched.
Note: Comfy Desktop's own AppData folder (`C:\Users\...\AppData\Roaming\Comfy Desktop`) is on C: but is only caches/config.

**What the game actually needs (from the repo, read-only)** **[local]**
- Icons are **16x16 PNGs** (items, status icons `poison_status`, `bleed_status`, `burn_status`, `stun_status`, potions, weapons, armour). Effects are 48x48 animation frames. Screen is 160x144 (Game Boy).
- **Palette is exactly 4 colours** in every icon I sampled (11 icons checked): `#071821` (7,24,33) darkest/outline, `#306850` (48,104,80), `#86C06C` (134,192,108), `#E0F8CF` (224,248,207) lightest. Plus transparent background. (The whole `sprites\` folder has 1851 distinct RGB values only because some big backgrounds/cutscenes are anti-aliased; icons are strictly 4-colour.)
- Style (looked at a 14-icon contact sheet): 1-px darkest outline, chunky silhouette filling ~12-14 px of the 16, 2-3 flat shades inside, light from top-left, hard pixel edges, **status icons are round badges with a glyph inside**.
- Gaps the pipeline should fill: `scr_db_skill.gml` has **28 skills, all with `icon_sprite: noone`**; `scr_status.gml` has **14 statuses and only 4 (poison, bleed, burn, stun) have a real icon**. The other 10 borrow unrelated art: Guard = `rock1`, Rev Up = `torch_asset_moving`, Evasion = `tall_grass_asset`, Take Aim = `skull_2_asset`, **Foresight = a 48x48 effect-sheet frame**, Meditation = `mp_potion`; Solidify/Bloodthirsty/Blessing/Sunder have no icon and fall back to tiny text labels (scale 0.45). So the first real batch is **~28 skill icons + ~10 status icons** (~40 icons), plus a handful of items later.

---

## 1. Bottom line (recommendation)

1. **Use what is already installed first: SDXL base + the "Pixel Art XL" LoRA (nerijs).** It is the best-documented, license-clear option for 8 GB and needs no new base model download (only a ~170 MB LoRA; size [known]).
2. **Treat AI output as a concept sketch, not the final 16x16.** At 16x16 and 4 colours (about 256 pixels) every pixel is a design decision. Realistic plan: generate big, reduce to **32x32 with a contrast-preserving pixelizer**, quantize to the 4-colour game palette, then **hand-finish at 16x16** (about 2-5 minutes per icon in Aseprite/LibreSprite/Pixelorama) **[inferred]**. Expect to redraw most 16x16 icons; expect only light touch-ups if you accept a 32x32 icon size.
3. **Make the consistency come from the pipeline, not the model**: one prompt skeleton, one LoRA weight, one fixed palette, one deterministic post-process, and a **scripted badge frame** for status icons (draw the circle once, generate only the glyph).
4. **Do not use FLUX.1 [dev]-based pixel LoRAs for a shipped game** (non-commercial license). Flux schnell and Z-Image Turbo are the licence-safe newer options; keep them as phase-2 experiments.
5. Keep a **colour-key background** (flat magenta) instead of fancy transparency tools for icons this small; add rembg/BiRefNet only if the key fails.

---

## 2. Model choice for 8 GB VRAM

| Option | Fits 8 GB? | Pixel LoRA availability | Licence for a shipped game | Verdict |
|---|---|---|---|---|
| **SDXL base 1.0** (installed, 6.6 GB fp16) | Yes; ComfyUI offloads automatically. Typical for SDXL on 8 GB **[known]** | **Pixel Art XL** (nerijs) and others | SDXL base: CreativeML Open RAIL++-M **[known]**; Pixel Art XL card says CreativeML OpenRAIL-M **[source: HF page]** (use restrictions apply; commercial use is allowed) | **Start here** |
| SD 1.5 | Easily | Many pixel LoRAs, but weaker prompt adherence and ~512 px native | CreativeML OpenRAIL-M **[known]** | Only if you need speed; no advantage over SDXL here |
| **FLUX.1 [schnell]** GGUF Q4 | Yes, ~6.8 GB file (Q4_K_S 6.78 GB / Q4_0 6.77 GB) + separate CLIP/T5/VAE; ~12 s per 1024 px image quoted **[source: below]** | I found **no schnell-trained pixel LoRA**; the ones found are FLUX.1 [dev] based | **Apache-2.0** for the model **[source: HF model card]** | Phase 2; LoRA-on-GGUF is flagged experimental by ComfyUI-GGUF **[source]** |
| FLUX.1 [dev] + pixel LoRAs | Same as above | Yes (e.g. deAPI-ai/pixelartdotfluxlora) | **FLUX.1 [dev] non-commercial** **[source: HF card]** | **Avoid for shipping** |
| **Z-Image Turbo** (6B, 8-step) GGUF Q4_K_M | Yes; ~5-6 GB quoted (sources disagree: Q4_K_M fits 8 GB, Q8 does not) | `elusarca-pixel-art-style-lora-zimage-turbo` (Apache-2.0, "include the words pixel art"); `tarn59` pixel LoRA listed on Comfy hub (licence not seen) | Base model Apache-2.0 **[source: ComfyUI wiki / HF quant repo]** | **Best phase-2 candidate** if SDXL is not crisp enough |
| FLUX.2 [klein] 4B | Quoted 8 GB minimum (distilled), more for base **(sources disagree)** | Found none | 4B variants Apache-2.0; 9B are non-commercial **[source: official repo via search]** | Watch, don't build on yet |

Notes on SDXL pixel LoRA settings **[source: huggingface.co/nerijs/pixel-art-xl]**: no trigger word needed, example prompt style
`pixel art, a cute corgi, simple, flat colors`, negative `3d render, realistic`; LoRA weight ~1.2 in its LCM example (8 steps, CFG 1.5 with an LCM LoRA);
**downscale the 1024 output by a factor of 8 with nearest-neighbour** for a clean grid; use a fixed (fp16-fix) VAE to avoid artefacts; no refiner.
(Without the LCM LoRA use ordinary settings: ~25-30 steps, CFG 6-7 **[inferred]**.)

Icon-specific LoRAs found (none verified by me, licences unclear, all optional):
- **Pixel Art Game UI Icons | Inventory & Item Icons** (Civitai 2443581): **Illustrious** base, trigger `pixelarticon`, weight 0.8-1.0, 8-10 steps, CFG 5-7; advises 512 px to 32x32 or 1024 px to 64x64, nearest-neighbour **[source]**. Licence page says "Illustrious License / FAIPL-1.0-SD" with no explicit commercial terms **[source]**; Illustrious is a different base from the SDXL you have installed. **Treat as unverified for commercial use.**
- Game Icon Forge (SDXL, trigger `gicon`, weight ~0.85, 1024 px) and RPG Weapon Icons v2 (SDXL, trigger `weic`, weight ~0.7): these produce painted, framed icons, **not pixel art**; usable only as shape/idea sources **[source: comfy.icu, civarchive via search]**.
- Verdict: no icon LoRA is needed to start. Pixel Art XL + a good subject prompt is enough; revisit if shapes are too busy.

---

## 3. Keeping a whole set consistent

Do **all** of these; each is cheap:

1. **One prompt skeleton**, vary only the `{subject}` phrase (and a `{glyph}` phrase for badges):
   - Positive: `pixel art, {subject}, single object, centered, simple bold silhouette, thick dark outline, flat colors, limited palette, high contrast, game icon, plain flat magenta background`
   - Negative: `3d render, realistic, photo, gradient, soft shading, blurry, text, watermark, frame, border, multiple objects, background scene, shadow on ground`
2. **Fixed everything except the subject**: same checkpoint, same LoRA and weight, same sampler/steps/CFG, same resolution, and a fixed seed per icon id (derive it from the id, e.g. `1000 + skill_id`). Keep batch size fixed when comparing runs (IPAdapter docs warn results differ slightly by batch size **[source]**).
3. **Style anchor**: feed an existing in-game icon (e.g. `hp_potion.png`, nearest-neighbour upscaled to 512) in two ways:
   - **img2img at denoise 0.55-0.75** to make variants in the same line weight and shading;
   - **ControlNet Union (already installed)** with a scribble/canny map made from your own rough 16x16 silhouette, upscaled x32. This locks the *shape* so the AI only adds shading; it also gives you the control a 16x16 icon needs **[inferred]**. Preprocessors come from `Fannovel16/comfyui_controlnet_aux` (Apache-2.0) **[source]**.
   - **IPAdapter (cubiq/ComfyUI_IPAdapter_plus)**: works for style transfer, better on SDXL; weight 0.6-0.85; repository is in maintenance-only mode since April 2025 **[source]**. It also needs a CLIP-vision model and the SDXL IP-Adapter weights (a few GB; sizes [known]). Optional; skip until the simpler methods fail.
4. **Deterministic post-process identical for every icon** (section 4). Consistency of grid, palette and outline comes almost entirely from here.
5. **Badges by script**: draw the round status badge frame once (or reuse `poison_status` etc. as the template), and only generate/draw the inner glyph (~8-10 px). That guarantees the same silhouette family for all 14+ statuses.
6. **Review sheet**: always assemble all icons on one 8x-scaled contact sheet (like the one used for this research) and judge them side by side at 1x and 4x. Reject by set-fit, not by single-icon beauty.
7. If the set still drifts after ~20 icons: train a small LoRA on your 30-40 existing finished icons plus your cleaned AI ones (style LoRA beats IPAdapter for consistency in practice, per the search summary **[source, weak]**). Needs more than 8 GB comfort, so use SD1.5/SDXL low-rank settings or a rented GPU; **[inferred]**, not tested.

---

## 4. Getting a true pixel grid, the 4-colour palette, outline, transparency

### 4.1 Downscale to the real grid
Never "generate small": SDXL cannot natively draw 16x16. Generate at 1024 (or 768), then reduce.
- **PixelArt Detector** (`dimtoneff/ComfyUI-PixelArt-Detector`, **MIT**) **[source]**: nodes under `Image/PixelArt`: Detector (+Save), Detector (Image->), **Palette Converter**, **Palette Loader**, Palette Generator, AddDitherPattern. Converter options: `pixelize` (Image.quantize / Grid.pixelate / NP.quantize), `reduce_colors_max_colors`, `cleanup_colors`, `dither`, resize modes `contain`/`fit`/`stretch`. **Custom palettes**: drop a 1-px-per-colour PNG in its `palettes/1x` folder. Bundles Lospec palettes. Needs OpenCV, Pillow, numpy, scipy (+pyclustering for some options). README states compatibility tested with ComfyUI 0.3.49; the install here is v0.37.2, so **verify it loads** (Python 3.13 is new) **[inferred]**.
- **PixelOE** (`KohakuBlueleaf/PixelOE`, **Apache-2.0**) **[source]**: "contrast-aware outline expansion": thickens high-contrast edges before shrinking so details survive. Modes: `center`, `contrast`, `k-centroid`, `bicubic`, `nearest`; params include `target_size`, `patch_size`, `thickness`, colour quantization. Available in ComfyUI via the `comfyui_essentials` "Pixelize+" node (`downscale_mode`; k-centroid suits flat illustrated art, contrast suits photoreal) **[source: search listing, parameter names vary by pack]**. **Best candidate for 16x16/32x32** because the outline expansion fights the "mushy tiny icon" problem.
- **Unfake Pixels** (`tauraloke/ComfyUI-Unfake-Pixels`, port of jenissimo/unfake.js; **licence not confirmed**) **[source: search listing]**: edge-aware auto-detection of the pixel scale + grid snapping. Useful only when a model already drew a rough grid (Pixel Art XL at 1024 gives ~8-px blocks, so it can recover 128x128); for hitting an exact 16x16 target use PixelOE or manual factor.
- Suggested chain: 1024 -> (Unfake or `nearest` /8) 128 -> **PixelOE (contrast/k-centroid) to 32x32** -> palette -> **final 16x16 by hand** (or run PixelOE straight to 16 and compare).

### 4.2 Map to the game's 4-colour palette
- Make a 4x1 PNG palette: `#071821 #306850 #86C06C #E0F8CF`, save into PixelArt Detector's `palettes/1x`, select it in the Palette Converter (max colours 4, dither off).
- **Pre-step that matters**: convert to greyscale and stretch contrast (auto-levels / equalize) *before* quantizing, so the 4 palette shades are used evenly; otherwise the colour image collapses into 2 shades **[inferred]**. Map by luminance rank: darkest -> outline, lightest -> highlights.
- Alternative, no custom node needed: a 20-line Python script with Pillow (`-I` isolated mode) that converts to L, posterizes to 4 levels, and maps through the palette. Deterministic, scriptable, easy to put under `tools/` later **[inferred]**.
- Because the lightest palette colour is also a legitimate in-icon colour (glass highlights), **do not key transparency from "lightest colour"** (see 4.4).

### 4.3 Outline clean-up
- After quantizing, run a rule: every opaque pixel touching transparent space (4-neighbour) that is not already darkest becomes darkest -> a guaranteed 1-px outline; delete isolated single pixels (orphans), fill 1-px holes **[inferred]**. UnfakePixelArt has a "cleanup jagged edges" toggle and PixelArt Detector has `cleanup_colors`/`cleanup_pixels_threshold` for the colour side **[source]**.

### 4.4 Transparent background
- **Preferred for tiny icons: colour key.** Prompt a flat magenta background, then in the post-process turn pixels within a tolerance of magenta to alpha 0 *before* downscaling/quantizing (so the key never touches the 4-colour palette). Cheap, deterministic, zero VRAM **[inferred]**.
- If the key bleeds: **background removal node** (rembg-based `Jcd1230/rembg-comfyui-node` (licence not stated), or RMBG/BEN2/InSPyReNet via an "easy" node; the guide rates this "Low VRAM, <=8 GB") **[source]**. Check each model licence: BRIA RMBG weights are non-commercial **[known]**, BiRefNet and rembg's U2Net variants are MIT/Apache **[known]**.
- **LayerDiffuse** (generates real alpha, works with SD1.5 and SDXL; attention-injection model 709 MB, conv model 3.37 GB, transparent decoder 199 MB) **[source]**. Overkill for 16x16 icons and adds VRAM; skip unless you also want large transparent art.

---

## 5. Batch generation
1. Build the workflow once in the ComfyUI UI, test on 3 icons, then **Save (API Format)**.
2. A small Python script (outside the game repo's resource tree, e.g. `tools/icons/`, run with `python -I`) reads a CSV `id,kind,subject,glyph`, patches the prompt/seed/filename-prefix nodes in the API JSON, and POSTs each to `http://127.0.0.1:<port>/prompt`; ComfyUI queues them. (Find the port in the Desktop app; `portConflict` is set to auto, so it may not be 8188.) **[inferred]**
3. Output name = `{kind}_{id}_{seedvariant}`; generate **4 variants per icon** (batch 4 at 1024 px should fit in 8 GB for SDXL, otherwise batch 2) **[inferred]**, pick the best by eye on the contact sheet.
4. Keep the CSV, API JSON, palette file and the post-process script in version control: that *is* the "style bible" and makes a re-run reproducible.
5. Alternative without a script: ComfyUI "Load Prompts From File" style nodes (e.g. Inspire Pack) **[known]**, less controllable.

---

## 6. Recommended node list (SDXL path)

**Install via ComfyUI-Manager (all land on E:):**
`ComfyUI-PixelArt-Detector` (MIT), `comfyui_essentials` (for PixelOE "Pixelize+"), `comfyui_controlnet_aux` (Apache-2.0), optionally `ComfyUI-Unfake-Pixels`, `ComfyUI_IPAdapter_plus`, a background-removal pack. Later: `ComfyUI-GGUF` (`city96`; Unet Loader (GGUF), CLIPLoader (gguf); GGUF files go in `models/unet`) **[source]**.
**Download to `E:\AI\ComfyUI\ComfyUI-Shared\models\`:** `loras\pixel-art-xl.safetensors` (nerijs); a fixed SDXL VAE in `vae\` (madebyollin sdxl-vae-fp16-fix, ~330 MB [known]); nothing else needed for v1.

Graph:
1. `Load Checkpoint` (sd_xl_base_1.0) -> 2. `Load LoRA` (Pixel Art XL, strength 1.0, try 1.2) -> 3. `CLIP Text Encode` x2 (skeleton prompt, negative)
-> 4. `Empty Latent Image` 1024x1024, batch 4
-> (optional guidance branch: `Load Image` -> `Scribble/Canny` preprocessor -> `Load ControlNet Model` (union) -> `Apply ControlNet`; or `Load Image` -> `VAE Encode` for img2img)
-> 5. `KSampler` (control_after_generate = **fixed**, seed from CSV, euler or dpmpp_2m, 25-30 steps, CFG 6-7, denoise 1.0, or 0.55-0.75 for img2img)
-> 6. `VAE Decode` (fixed VAE)
-> 7. **Colour-key magenta to alpha** (custom Python node or `ImageColorToMask` + `JoinImageWithAlpha`)
-> 8. **Pixelize** (PixelOE `Pixelize+`, mode contrast or k-centroid, thickness 2-3, target 32; or `ImageScale` nearest /8 + Unfake)
-> 9. **Greyscale + auto-levels** -> 10. **PixelArt Palette Loader + Palette Converter** (4-colour palette, 4 colours max, no dither)
-> 11. **Outline cleanup** (script / small custom node) -> 12. `ImageScale` nearest x16 (preview) -> `Preview Image` / `Save Image` (prefix `dd_icons/`), plus save the un-upscaled 32x32 or 16x16 PNG.

---

## 7. Licensing notes for a shipped game

- **SDXL base 1.0 and Pixel Art XL: CreativeML Open RAIL(++)-M** - output may be used commercially; the licence carries use-based restrictions (no illegal/harmful use) and requires passing those restrictions on if you redistribute the *model*. You are shipping images, not the model. **[source for Pixel Art XL; known for SDXL base]**
- **FLUX.1 [schnell]: Apache-2.0** (personal, scientific and commercial) **[source]**. **FLUX.1 [dev]: non-commercial**, and so are dev-trained LoRAs such as `deAPI-ai/pixelartdotfluxlora` **[source]**. Do not ship anything produced with them.
- **Z-Image Turbo: Apache-2.0** base **[source]**; elusarca LoRA Apache-2.0 **[source]**; check the licence of any other LoRA individually (the tarn59 one was not visible to me).
- **Illustrious-based LoRAs (FAIPL-1.0-SD)**: terms unclear from what I read; skip for a commercial game unless verified.
- **Custom nodes**: PixelArt Detector MIT, PixelOE Apache-2.0, controlnet_aux Apache-2.0 (all **[source]**). Unfake-Pixels and the rembg node: licence not confirmed.
- **Copyright of the result** **[known, verify before relying on it]**: in the US, purely AI-generated images generally are not copyrightable; human-made redraw/cleanup strengthens your claim. **Steam requires disclosing AI-generated content** on the store page. Another reason to hand-finish every icon.
- Never train or prompt on other games' icons (e.g. "in the style of Pokemon sprites"); use your own 16x16 icons as the style anchor.

---

## 8. Realistic expectations

| Asset | AI-only usable? | What needs hand work |
|---|---|---|
| 16x16 4-colour item/skill icon | No, rarely | Redraw/trim almost every one (shape clarity, 1-px outline, highlight placement, kill orphan pixels). AI = idea + rough shading. |
| 32x32 icon (if you ever raise icon size) | Sometimes | Stray pixels, uneven outline, palette banding: 30-60% need touch-ups **[inferred]** |
| Status badge glyph (~8-10 px) | No | Draw by hand or trace AI sketch; these are simplest to hand-draw and the most important to be readable |
| 48x48 effect animations | No | Not covered here; frame-to-frame consistency is a different, harder problem |

Common failure modes: wobbly outlines that survive quantization as broken lines; objects not centred or cropped; 2-3 objects instead of one; "pixel" look from smooth shading (grid not true); colours collapsing to 2 shades; the lightest tone leaking into the background.
Budget: expect ~40 first-batch icons x (generate+pick ~2 min + hand finish ~3-5 min) = roughly 3-6 hours of attended work **[inferred]**.
A good test before committing: take 5 existing icons, regenerate them with this pipeline, and put old vs. new side by side in the game.

---

## 9. Suggested next steps (when you decide to build it)

1. Install the three nodes via Manager (E: only), download Pixel Art XL + fixed VAE to `E:\AI\ComfyUI\ComfyUI-Shared\models`. Confirm free space (`df -h /c` stays untouched).
2. Create the 4-colour palette PNG and the prompt CSV for the ~10 missing statuses and 28 skills.
3. Run the 5-icon regression test above; decide between "AI sketch then redraw at 16x16" and "raise icons to 32x32".
4. Only if SDXL output is too soft: try Z-Image Turbo Q4_K_M + the Apache-2.0 pixel LoRA as a second model.

---

## Sources
- [ComfyUI PixelArt Detector (dimtoneff, MIT)](https://github.com/dimtoneff/ComfyUI-PixelArt-Detector)
- [PixelOE (KohakuBlueleaf, Apache-2.0)](https://github.com/KohakuBlueleaf/PixelOE)
- [ComfyUI Essentials Pixelize+ listing](https://www.runcomfy.com/comfyui-nodes/ComfyUI_essentials/PixelOEPixelize-)
- [ComfyUI-Unfake-Pixels listing](https://www.runcomfy.com/comfyui-nodes/ComfyUI-Unfake-Pixels) and [pixel-perfect output guide](https://aigaming.nuilab.org/workflows/pixel-perfect-output/)
- [nerijs/pixel-art-xl (Hugging Face)](https://huggingface.co/nerijs/pixel-art-xl)
- [Pixel Art Game UI Icons LoRA (Civitai)](https://civitai.com/models/2443581)
- [SDXL RPG Weapon Icons (CivArchive)](https://civarchive.com/models/2214821/sdxl-rpg-weapon-icons) and [Game Icon Forge (comfy.icu)](https://comfy.icu/models/2750041/Game-Icon-Forge-Turn-Anything-Into-a-Fantasy-RPG-Item-Icon-Original)
- [FLUX.1 schnell model card](https://huggingface.co/black-forest-labs/FLUX.1-schnell)
- [city96/ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF)
- [Flux on 8 GB GGUF guide](https://www.promptzone.com/tara_suzuki/how-to-run-flux-on-8gb-vram-in-2026-the-gguf-low-vram-guide-46k8) and [ComfyUI low-VRAM guide](https://eastondev.com/blog/en/posts/ai/20260721-comfyui-low-vram-acceleration/)
- [deAPI-ai/pixelartdotfluxlora (FLUX dev, non-commercial)](https://huggingface.co/deAPI-ai/pixelartdotfluxlora/blob/main/README.md)
- [elusarca pixel art LoRA for Z-Image Turbo (Apache-2.0)](https://huggingface.co/reverentelusarca/elusarca-pixel-art-style-lora-zimage-turbo) and [Comfy hub pixel art Z-Image Turbo](https://comfy.org/hub/models/local/pixel-art-style-z-image-turbo/)
- [Z-Image Turbo overview](https://comfyui-wiki.com/en/models/z-image/z-image-turbo) and [Z-Image GGUF on 8 GB](https://romptn.com/article/105828)
- [FLUX.2 klein ComfyUI template](https://comfy.org/templates/image_flux2_klein_text_to_image)
- [cubiq/ComfyUI_IPAdapter_plus](https://github.com/cubiq/ComfyUI_IPAdapter_plus)
- [Fannovel16/comfyui_controlnet_aux (Apache-2.0)](https://github.com/Fannovel16/comfyui_controlnet_aux)
- [Jcd1230/rembg-comfyui-node](https://github.com/Jcd1230/rembg-comfyui-node)
- [LayerDiffuse transparent image guide](https://stable-diffusion-art.com/transparent-background) and [ComfyUI background-removal workflow](https://www.comfyui.org/en/remove-backgrounds-with-comfyui)
