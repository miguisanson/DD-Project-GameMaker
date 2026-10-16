"""Workbook merge for DD-Project: take next's (HEAD) game_text.xlsx and re-apply the branch's rows that differ from the merge base.
Usage (from the next worktree): python E:/Temp/dd-merge/wbmerge.py <branch>
"""
import subprocess, sys, openpyxl, io

branch = sys.argv[1]
XL = 'datafiles/localization/game_text.xlsx'


def blob(rev):
    return subprocess.run(['git', 'show', f'{rev}:{XL}'], capture_output=True, check=True).stdout


def rows(data):
    wb = openpyxl.load_workbook(io.BytesIO(data))
    ws = wb['strings']
    out = {}
    for r in ws.iter_rows(min_row=2, values_only=True):
        if r[0] is not None:
            out[r[0]] = tuple(r)
    return out


base_rev = subprocess.run(['git', 'merge-base', 'HEAD', branch], capture_output=True, text=True, check=True).stdout.strip()
base, theirs = rows(blob(base_rev)), rows(blob(branch))
wb = openpyxl.load_workbook(io.BytesIO(blob('HEAD')))
ws = wb['strings']
changed = {k: v for k, v in theirs.items() if base.get(k) != v}
removed = [k for k in base if k not in theirs]
idx = {ws.cell(row=i, column=1).value: i for i in range(2, ws.max_row + 1)}
for k, v in changed.items():
    if k in idx:
        for j, val in enumerate(v):
            ws.cell(row=idx[k], column=j + 1, value=val)
    else:
        ws.append(list(v))
for k in removed:
    idx = {ws.cell(row=i, column=1).value: i for i in range(2, ws.max_row + 1)}
    if k in idx:
        ws.delete_rows(idx[k])
wb.save(XL)
print('applied', len(changed), 'changed/added,', len(removed), 'removed:', sorted(changed)[:40], removed)
