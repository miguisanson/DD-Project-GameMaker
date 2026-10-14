"""SDXL + Pixel Art XL LoRA candidates via ComfyUI (127.0.0.1:8188).
Usage: python gen_v2.py <rawdir> [cat/id ...]
2 prompts x 2 images = 4 candidates per icon at 1024, saved as <cat>_<id>_<k>.png (k=0..3)."""
import json
import os
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(__file__))
from prompts_v2 import P, SKEL
from icons_manifest import seed_for

API = "http://127.0.0.1:8188"
NEG = ("3d render, realistic, photo, gradient, soft shading, blurry, text, letters, watermark, frame, border, "
       "multiple objects, background scene, shadow on ground, sprite sheet, collage, icon set, grid")
SIZE, STEPS, CFG, LORA_W = 1024, 24, 6.5, 1.0


def post(path, obj):
    r = urllib.request.Request(API + path, json.dumps(obj).encode(), {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(r))


def get(path):
    return urllib.request.urlopen(API + path).read()


def workflow(prompt, seed, prefix, n=2):
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
        "8": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1], "lora_name": "pixel-art-xl.safetensors",
                                                       "strength_model": LORA_W, "strength_clip": LORA_W}},
        "9": {"class_type": "VAELoader", "inputs": {"vae_name": "sdxl_vae_fp16_fix.safetensors"}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["8", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["8", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": SIZE, "height": SIZE, "batch_size": n}},
        "5": {"class_type": "KSampler", "inputs": {"model": ["8", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0],
                                                    "seed": seed, "steps": STEPS, "cfg": CFG, "sampler_name": "dpmpp_2m",
                                                    "scheduler": "karras", "denoise": 1.0}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["9", 0]}},
        "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": prefix}},
    }


def run(rawdir, only):
    os.makedirs(rawdir, exist_ok=True)
    jobs = []
    for key, prompts in P.items():
        if only and key not in only:
            continue
        cat, iid = key.split("/")
        for v, conv in enumerate(prompts):
            if all(os.path.exists(f"{rawdir}/{cat}_{iid}_{v*2+k}.png") for k in range(2)):
                continue
            jobs.append((cat, iid, v, conv))
    print(len(jobs), "jobs", flush=True)
    for cat, iid, v, conv in jobs:
        t = time.time()
        prompt = SKEL.format(conv=conv)
        pid = post("/prompt", {"prompt": workflow(prompt, seed_for(cat, iid) + v * 17, f"dd_icons_v2/{cat}_{iid}_{v}")})["prompt_id"]
        while True:
            h = json.loads(get(f"/history/{pid}"))
            if pid in h and h[pid].get("outputs"):
                break
            time.sleep(1)
        for k, im in enumerate(h[pid]["outputs"]["7"]["images"]):
            data = get(f"/view?filename={im['filename']}&subfolder={im['subfolder']}&type={im['type']}")
            open(f"{rawdir}/{cat}_{iid}_{v*2+k}.png", "wb").write(data)
        print(f"{cat}/{iid} v{v} {time.time()-t:.0f}s", flush=True)


if __name__ == "__main__":
    run(sys.argv[1], set(sys.argv[2:]))
