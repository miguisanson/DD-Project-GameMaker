"""H9 (D151): raw battle-background candidates through ComfyUI (127.0.0.1:8188), SDXL base + Pixel Art XL LoRA + fp16-fix VAE.
Usage: python gen_bg.py <rawdir> [band ...]   bands: forest caves ruins boss
3 seeds per band at 1280x1152 (10:9, the game picture is 160x144), saved as <band>_<k>.png. Existing files are skipped."""
import json
import os
import sys
import time
import urllib.request

API = "http://127.0.0.1:8188"
W, H, STEPS, CFG, LORA_W = 1280, 1152, 26, 6.5, 1.0
SKEL = ("pixel art, game boy style, limited green palette, {scene}, wide establishing view, symmetrical composition, "
        "dark empty open space in the middle for a character to stand, strong depth, clean pixel clusters")
NEG = ("3d render, realistic, photo, text, letters, watermark, frame, border, character, creature, person, monster, "
       "sprite sheet, collage, UI, bright centre, blurry, gradient, vignette frame")
BANDS = {
    "forest": "inside a dark forest tunnel, thick tree trunks and a leafy canopy arching overhead, ferns and moss, a worn dirt path running to a dark vanishing point",
    "caves": "inside a rocky cave, stalactites hanging from the ceiling, rough stone walls, uneven stone floor, a few glowing crystals, deep dark passage ahead",
    "ruins": "inside deep ancient ruins, broken stone columns and crumbling arches, fallen rubble, cracked flagstone floor, a vast dark hall receding into shadow",
    "boss": "inside a circular stone arena, tall carved pillars around the edge, braziers with flames, a huge sealed gate in the far wall, ominous, cracked stone floor",
}
SEEDS = {"forest": [1101, 1102, 1103], "caves": [2101, 2102, 2103], "ruins": [3101, 3102, 3103], "boss": [4101, 4102, 4103]}


def post(path, obj):
    r = urllib.request.Request(API + path, json.dumps(obj).encode(), {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(r))


def get(path):
    return urllib.request.urlopen(API + path).read()


def workflow(prompt, seed, prefix):
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
        "8": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1], "lora_name": "pixel-art-xl.safetensors",
                                                       "strength_model": LORA_W, "strength_clip": LORA_W}},
        "9": {"class_type": "VAELoader", "inputs": {"vae_name": "sdxl_vae_fp16_fix.safetensors"}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["8", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["8", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": W, "height": H, "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {"model": ["8", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0],
                                                    "seed": seed, "steps": STEPS, "cfg": CFG, "sampler_name": "dpmpp_2m",
                                                    "scheduler": "karras", "denoise": 1.0}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["9", 0]}},
        "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": prefix}},
    }


def run(rawdir, only):
    os.makedirs(rawdir, exist_ok=True)
    for band, scene in BANDS.items():
        if only and band not in only:
            continue
        for k, seed in enumerate(SEEDS[band]):
            out = f"{rawdir}/{band}_{k}.png"
            if os.path.exists(out):
                continue
            t = time.time()
            pid = post("/prompt", {"prompt": workflow(SKEL.format(scene=scene), seed, f"dd_bg/{band}_{k}")})["prompt_id"]
            while True:
                h = json.loads(get(f"/history/{pid}"))
                if pid in h and h[pid].get("outputs"):
                    break
                if pid in h and h[pid].get("status", {}).get("status_str") == "error":
                    raise SystemExit("comfy error: " + json.dumps(h[pid]["status"])[:600])
                time.sleep(1)
            im = h[pid]["outputs"]["7"]["images"][0]
            open(out, "wb").write(get(f"/view?filename={im['filename']}&subfolder={im['subfolder']}&type={im['type']}"))
            print(f"{band} {k} seed {seed} {time.time()-t:.0f}s", flush=True)


if __name__ == "__main__":
    run(sys.argv[1], set(sys.argv[2:]))
