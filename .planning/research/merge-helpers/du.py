import os, sys
def size(p):
    t=0; st=[p]
    while st:
        d=st.pop()
        try:
            with os.scandir(d) as it:
                for e in it:
                    try:
                        if e.is_dir(follow_symlinks=False): st.append(e.path)
                        else: t+=e.stat(follow_symlinks=False).st_size
                    except OSError: pass
        except OSError: pass
    return t
if __name__=="__main__":
  for name in sys.argv[1:]:
      print(f"{size(name)/2**30:8.1f} GB  {name}", flush=True)
