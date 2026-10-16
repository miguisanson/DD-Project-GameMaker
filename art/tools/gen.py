"""Generate SDXL candidates via a running ComfyUI API. Usage: python gen.py <rawdir> [cat/id ...]"""
import json, sys, time, urllib.request, os
sys.path.insert(0, os.path.dirname(__file__))
from icons_manifest import CATS, seed_for
API = "http://127.0.0.1:8188"
SKEL = "game icon, pixel art style, single centered object, flat background, bold silhouette, one single {motif}, large, filling the frame, isolated on a plain flat light gray background, thick dark outline, simple flat green shading"
NEG = "sprite sheet, collage, grid, multiple icons, icon set, pattern, tiles, interface, pink, magenta, purple, multiple eyes, symmetrical pattern, circuit, grid, 3d render, realistic, photo, gradient, soft shading, blurry, text, letters, watermark, frame, border, multiple objects, background scene, shadow on ground, detailed, noisy"
N, SIZE, STEPS = 3, 768, 22
def post(path, obj):
    r = urllib.request.Request(API+path, json.dumps(obj).encode(), {"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(r))
def get(path): return urllib.request.urlopen(API+path).read()
def workflow(prompt, seed, prefix):
    return {
     "1":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":"sd_xl_base_1.0.safetensors"}},
     "2":{"class_type":"CLIPTextEncode","inputs":{"text":prompt,"clip":["1",1]}},
     "3":{"class_type":"CLIPTextEncode","inputs":{"text":NEG,"clip":["1",1]}},
     "4":{"class_type":"EmptyLatentImage","inputs":{"width":SIZE,"height":SIZE,"batch_size":N}},
     "5":{"class_type":"KSampler","inputs":{"model":["1",0],"positive":["2",0],"negative":["3",0],"latent_image":["4",0],
          "seed":seed,"steps":STEPS,"cfg":7.0,"sampler_name":"euler","scheduler":"normal","denoise":1.0}},
     "6":{"class_type":"VAEDecode","inputs":{"samples":["5",0],"vae":["1",2]}},
     "7":{"class_type":"SaveImage","inputs":{"images":["6",0],"filename_prefix":prefix}},
    }
def run(rawdir, only):
    jobs = []
    for cat,(kind,items) in CATS.items():
        for iid,motif in items:
            key=f"{cat}/{iid}"
            if only and key not in only: continue
            if all(os.path.exists(f"{rawdir}/{cat}_{iid}_{k}.png") for k in range(N)): continue
            jobs.append((cat,iid,motif))
    print(len(jobs),"jobs", flush=True)
    for cat,iid,motif in jobs:
        t=time.time()
        prompt = SKEL.format(motif=motif)
        pid = post("/prompt",{"prompt":workflow(prompt,seed_for(cat,iid),f"dd_icons/{cat}_{iid}")})["prompt_id"]
        while True:
            h = json.loads(get(f"/history/{pid}"))
            if pid in h and h[pid].get("outputs"): break
            time.sleep(1)
        imgs = h[pid]["outputs"]["7"]["images"]
        for k,im in enumerate(imgs):
            data = get(f"/view?filename={im['filename']}&subfolder={im['subfolder']}&type={im['type']}")
            open(f"{rawdir}/{cat}_{iid}_{k}.png","wb").write(data)
        print(f"{cat}/{iid} {time.time()-t:.0f}s", flush=True)
if __name__=="__main__":
    run(sys.argv[1], set(sys.argv[2:]))
