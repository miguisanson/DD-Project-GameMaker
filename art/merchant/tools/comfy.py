"""img2img via the local ComfyUI API: python comfy.py guide.png outdir denoise seeds... (SDXL base + pixel-art-xl LoRA + fp16-fix VAE)"""
import sys,json,time,uuid,urllib.request,os,io
H='http://127.0.0.1:8188'
POS=("pixel art, tiny game boy style character sprite, hooded mysterious travelling merchant, creepy, long cloak, "
     "face hidden in shadow, glowing eyes, large backpack of wares, front view, full body, plain background, "
     "limited palette of four greens, dark green and pale green, chunky pixels")
NEG="photo, realistic, 3d, blurry, text, watermark, multiple characters, gradient, noise, cropped, smooth, anti-aliased, detailed background"
def post(path,data,ct='application/json'):
    r=urllib.request.Request(H+path,data=data,headers={'Content-Type':ct}); return json.load(urllib.request.urlopen(r))
def upload(fn):
    b='----x'+uuid.uuid4().hex
    body=(f'--{b}\r\nContent-Disposition: form-data; name="image"; filename="{os.path.basename(fn)}"\r\nContent-Type: image/png\r\n\r\n').encode()+open(fn,'rb').read()+(f'\r\n--{b}\r\nContent-Disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n--{b}--\r\n').encode()
    return post('/upload/image',body,f'multipart/form-data; boundary={b}')['name']
def run(guide,out,denoise,seed,pos=POS,tag=''):
    name=upload(guide)
    wf={"1":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":"sd_xl_base_1.0.safetensors"}},
        "2":{"class_type":"LoraLoader","inputs":{"model":["1",0],"clip":["1",1],"lora_name":"pixel-art-xl.safetensors","strength_model":1.0,"strength_clip":1.0}},
        "3":{"class_type":"VAELoader","inputs":{"vae_name":"sdxl_vae_fp16_fix.safetensors"}},
        "4":{"class_type":"CLIPTextEncode","inputs":{"clip":["2",1],"text":pos}},
        "5":{"class_type":"CLIPTextEncode","inputs":{"clip":["2",1],"text":NEG}},
        "6":{"class_type":"LoadImage","inputs":{"image":name}},
        "7":{"class_type":"VAEEncode","inputs":{"pixels":["6",0],"vae":["3",0]}},
        "8":{"class_type":"KSampler","inputs":{"model":["2",0],"positive":["4",0],"negative":["5",0],"latent_image":["7",0],"seed":seed,"steps":28,"cfg":7.0,"sampler_name":"euler","scheduler":"normal","denoise":denoise}},
        "9":{"class_type":"VAEDecode","inputs":{"samples":["8",0],"vae":["3",0]}},
        "10":{"class_type":"SaveImage","inputs":{"images":["9",0],"filename_prefix":"merch"}}}
    pid=post('/prompt',json.dumps({"prompt":wf}).encode())['prompt_id']
    while True:
        h=json.load(urllib.request.urlopen(f'{H}/history/{pid}'))
        if pid in h: break
        time.sleep(2)
    st=h[pid]['status']
    if st['status_str']!='success': raise SystemExit(json.dumps(st)[:1500])
    im=h[pid]['outputs']['10']['images'][0]
    data=urllib.request.urlopen(f"{H}/view?filename={im['filename']}&subfolder={im['subfolder']}&type={im['type']}").read()
    fn=os.path.join(out,f'{tag}d{int(denoise*100)}_s{seed}.png'); open(fn,'wb').write(data); print(fn,flush=True)
if __name__=='__main__':
    g,out,dn=sys.argv[1],sys.argv[2],float(sys.argv[3]); os.makedirs(out,exist_ok=True)
    for s in sys.argv[4:]: run(g,out,dn,int(s))
