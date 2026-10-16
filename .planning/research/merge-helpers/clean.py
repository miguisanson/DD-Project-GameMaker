import os, time, shutil, sys
sys.path.insert(0,'E:/Temp/dd-merge')
from du import size
now=time.time(); DRY = '--do' not in sys.argv
def newest(p, limit=200000):
    m=os.stat(p).st_mtime; st=[p]; n=0
    while st and n<limit:
        d=st.pop()
        try:
            for e in os.scandir(d):
                n+=1
                try:
                    m=max(m,e.stat(follow_symlinks=False).st_mtime)
                    if e.is_dir(follow_symlinks=False): st.append(e.path)
                except OSError: pass
        except OSError: pass
    return m
keep_gate={'dd-gate-next','dd-gate-r3levelup','dd-gate-r3ideas1'}
tot=0; cnt=0
for e in os.scandir('E:/Temp'):
    if not e.is_dir() or not e.name.startswith('dd-gate'): continue
    if any(e.name.startswith(k) for k in keep_gate): continue
    if now-newest(e.path) < 2*3600: print('busy, keep', e.name); continue
    s=size(e.path); tot+=s; cnt+=1
    if not DRY: shutil.rmtree(e.path, ignore_errors=True)
print(f'dd-gate: {cnt} folders, {tot/2**30:.1f} GB', 'would delete' if DRY else 'deleted')
tot=0; cnt=0
cur='b7b05abd-6a96-4e4b-87ee-132c46bea5ae'
for proj in os.scandir('E:/Temp/claude'):
    if not proj.is_dir(): continue
    for sess in os.scandir(proj.path):
        if not sess.is_dir() or sess.name==cur: continue
        if now-newest(sess.path) < 24*3600: print('recent, keep', proj.name, sess.name); continue
        s=size(sess.path); tot+=s; cnt+=1
        if not DRY: shutil.rmtree(sess.path, ignore_errors=True)
print(f'claude temp: {cnt} session folders, {tot/2**30:.1f} GB', 'would delete' if DRY else 'deleted')
