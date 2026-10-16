<#
.SYNOPSIS  DD-Project gate: headless Igor build + game test runs. Windows PowerShell 5.1 compatible.
.DESCRIPTION
  Modes: compile (build only) | fast (build + -runtests, default) | full (fast + smoke/bot/shots).
  Exit 0 = GATE PASS, 1 = GATE FAIL, 2 = refused to start (drive guard / missing tool).
  Output is deliberately short: FAIL/ERROR/SKIP lines, one timing line per step, final GATE line.
  See tools\automation\README.md and .planning\research\automation-igor.md.
#>
[CmdletBinding()]
param(
    [ValidateSet('fast', 'full', 'compile')][string]$Mode = 'fast',
    [switch]$NegativeControl,                  # must end in GATE FAIL; run it whenever this script changes
    [Parameter(Position = 0)][ValidateSet('test', 'syntax', 'unknownfn')][string]$Plant = 'test',   # which plant: test (default, a failing test + a display-guard violation) | syntax (GML syntax error: the build must fail) | unknownfn (call to an unknown function: Igor passes, the test run must catch it). `-NegativeControl syntax` works; `-Plant syntax` alone implies -NegativeControl.
    [ValidateSet('', 'runtests', 'smoke', 'bot', 'shots', 'gridshots', 'exportdata')][string]$Only = '',   # run just this game mode (with fast/full)
    [string]$ProjectDir = '',                  # default: repo root of this script
    [string]$WorkRoot = 'E:\Temp\dd-gate'      # test hook: point at C:\ to see the drive guard refuse
)
$ErrorActionPreference = 'Stop'
if ($PSBoundParameters.ContainsKey('Plant')) { $NegativeControl = [switch]$true }

# ---- game modes: ONE ROW EACH. Flip Impl to $true when a packet implements the mode. ----------
# Strict = also require exit code 0 and the result file (only -runtests; crash exit codes are unreliable).
$GameModes = @(
    @{ Name = 'runtests'; Flag = '-runtests'; Timeout = 30;  Impl = $true;  Strict = $true  }
    @{ Name = 'smoke';    Flag = '-smoke';    Timeout = 900;  Impl = $true;  Strict = $false }
    @{ Name = 'bot';      Flag = '-bot';      Timeout = 480; Impl = $true;  Strict = $false }
    @{ Name = 'shots';    Flag = '-shots';    Timeout = 960; Impl = $true;  Strict = $false; Shots = 440 }   # Shots = number of [SHOT] lines required. (R3 cards +9, R3 menus +14, R3 bvis +10, R3 textfit2 +14, R3 stealth +6, R3 saves2 +42, R3 rarity +15, R3 mouse +12, R3 levelup -3 +15 = +12, R3 ideas1 +11, R3 ideas2 +9. H1: pause-menu pictures -2, one-menu +6. H2 +6. H6 +4. H14 +10. H7 +6. H5 +6. H13a +6. D164 +6. H8a +11. H8b +10. H12a +4, note ask +2. R3 menus +14, R3 bvis +10, R3 textfit2 +14, R3 stealth +6, R3 saves2 +42, R3 rarity +15, R3 mouse +12, R3 levelup -3 +15 = +12, R3 ideas1 +11, R3 ideas2 +9.)
    @{ Name = 'exportdata'; Flag = '-exportdata'; Timeout = 60; Impl = $true;  Strict = $false; Export = $true; Explicit = $true }   # B1: the game's classes/enemies/skills/items/statuses/level table as JSON -> <WorkRoot>\export\export_data.json. Run with -Only exportdata.
    @{ Name = 'gridshots'; Flag = '-gridshots'; Timeout = 120; Impl = $true;  Strict = $false; Shots = 11; ShotDir = 'gridshots'; Explicit = $true }   # D65: 16 px grid over every floor room -> <WorkRoot>\gridshots. Not part of -Mode full: run with -Only gridshots.
)
$BuildTimeout = 300
$ResultFile = 'test_results.txt'
$ShotMaxOneColour = 0.97   # a screenshot where more than this share of sampled pixels is one colour counts as blank
$BadLine = 'UNHANDLED|CRASH|\[TEST\] ERROR'

# ---- helpers ----------------------------------------------------------------------------------
function Refuse([string]$msg) { Write-Host "GATE REFUSED: $msg"; exit 2 }
$script:failed = $false
$script:failCount = 0                      # counts Fail calls; a step compares it with its own starting value, so one step's FAIL never leaks into the next
function Fail([string]$msg) { Write-Host "FAIL $msg"; $script:failed = $true; $script:failCount++ }
function Step([string]$name, [string]$state, $sw) { Write-Host ('{0,-9} {1,-4} {2:N1}s' -f $name, $state, $sw.Elapsed.TotalSeconds) }

function Get-DriveRoots([string]$path) {   # the path's own drive, plus the target drive of any existing junction/symlink on it
    $full = [IO.Path]::GetFullPath($path)
    $roots = @([IO.Path]::GetPathRoot($full))
    $probe = $full
    while ($probe) {
        if (Test-Path -LiteralPath $probe) {
            $t = (Get-Item -LiteralPath $probe -Force).Target
            if ($t) { $roots += [IO.Path]::GetPathRoot([IO.Path]::GetFullPath(@($t)[0])) }
        }
        $probe = Split-Path -Parent $probe
    }
    $roots
}

# Game runs are started WITHOUT activating their window (SW_SHOWMINNOACTIVE through CreateProcess), so a gate run never takes
# keyboard focus from whatever the owner is doing. Start-Process -WindowStyle Minimized (SW_SHOWMINIMIZED) is the fallback;
# the Igor build uses it too (hidden). No focus / foreground API is called anywhere in this script.
$ddLaunchOk = $true
try {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
public static class DDLaunch {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO {
        public int cb; public string lpReserved; public string lpDesktop; public string lpTitle;
        public int dwX; public int dwY; public int dwXSize; public int dwYSize; public int dwXCountChars; public int dwYCountChars;
        public int dwFillAttribute; public int dwFlags; public short wShowWindow; public short cbReserved2;
        public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput; public IntPtr hStdError;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_INFORMATION { public IntPtr hProcess; public IntPtr hThread; public int dwProcessId; public int dwThreadId; }
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool CreateProcess(string app, StringBuilder cmd, IntPtr pa, IntPtr ta, bool inherit, uint flags, IntPtr env, string cwd, ref STARTUPINFO si, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetHandleInformation(IntPtr h, int mask, int flags);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern IntPtr CreateDesktop(string name, IntPtr dev, IntPtr devmode, int flags, uint access, IntPtr sa);
    [DllImport("user32.dll")] static extern bool CloseDesktop(IntPtr d);
    static IntPtr desk = IntPtr.Zero;
    // I-053: a window created on its own desktop can never be the owner's foreground window. Call after the game has exited.
    public static void ReleaseDesktop() { if (desk != IntPtr.Zero) { CloseDesktop(desk); desk = IntPtr.Zero; } }
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    // I-053 probe: process id that owns the foreground window of the owner's desktop (0 when none).
    public static int ForegroundPid() {
        IntPtr w = GetForegroundWindow(); uint pid;
        if (w == IntPtr.Zero) return 0;
        GetWindowThreadProcessId(w, out pid); return (int)pid;
    }
    // Starts exe with stdout+stderr going to logFile, on a private desktop (when it can be created) with the window shown minimized and
    // not activated. Returns the process id.
    public static int Start(string exe, string args, string cwd, string logFile) {
        using (FileStream fs = new FileStream(logFile, FileMode.Create, FileAccess.Write, FileShare.ReadWrite)) {
            IntPtr h = fs.SafeFileHandle.DangerousGetHandle();
            SetHandleInformation(h, 1, 1);                      // HANDLE_FLAG_INHERIT
            STARTUPINFO si = new STARTUPINFO();
            si.cb = Marshal.SizeOf(typeof(STARTUPINFO));
            si.dwFlags = 0x101;                                 // STARTF_USESHOWWINDOW | STARTF_USESTDHANDLES
            si.wShowWindow = 7;                                 // SW_SHOWMINNOACTIVE
            si.hStdOutput = h; si.hStdError = h;
            ReleaseDesktop();
            string dn = "ddgate_" + Guid.NewGuid().ToString("N").Substring(0, 8);
            desk = CreateDesktop(dn, IntPtr.Zero, IntPtr.Zero, 0, 0x10000000, IntPtr.Zero);   // GENERIC_ALL
            if (desk != IntPtr.Zero) si.lpDesktop = "winsta0\\" + dn;
            PROCESS_INFORMATION pi;
            StringBuilder cmd = new StringBuilder("\"" + exe + "\" " + args);
            if (!CreateProcess(null, cmd, IntPtr.Zero, IntPtr.Zero, true, 0, IntPtr.Zero, cwd, ref si, out pi))
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            CloseHandle(pi.hThread); CloseHandle(pi.hProcess);
            return pi.dwProcessId;
        }
    }
}
'@
} catch { $ddLaunchOk = $false }

function Invoke-Proc([string]$exe, [string]$argStr, [string]$wd, [string]$log, [int]$timeout, [string]$style, [bool]$noActivate = $false) {
    $p = $null
    if ($noActivate -and $ddLaunchOk) {
        try { $p = Get-Process -Id ([DDLaunch]::Start($exe, $argStr, $wd, $log)) } catch { $p = $null }
    }
    if (-not $p) {
        $p = Start-Process -FilePath $exe -ArgumentList $argStr -WorkingDirectory $wd -PassThru -WindowStyle $style `
            -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    }
    $null = $p.Handle                       # needed or ExitCode comes back empty in PS 5.1
    # I-053 focus probe: poll the foreground window every 10 ms; FocusMs = first time this process owned it (-1 = never).
    $focusMs = -1; $t0 = [Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        if ($p.WaitForExit(10)) { $timedOut = $false; break }
        if ($focusMs -lt 0 -and $ddLaunchOk -and [DDLaunch]::ForegroundPid() -eq $p.Id) { $focusMs = [int]$t0.ElapsedMilliseconds }
        if ($t0.Elapsed.TotalSeconds -ge $timeout) { $timedOut = $true; break }
    }
    if ($timedOut) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; $null = $p.WaitForExit(5000) }
    $code = $null; if (-not $timedOut) { $code = $p.ExitCode }
    if ($ddLaunchOk) { [DDLaunch]::ReleaseDesktop() }
    if ((Test-Path "$log.err") -and (Get-Item "$log.err").Length -gt 0) { Get-Content "$log.err" | Add-Content -Path $log }
    Remove-Item "$log.err" -Force -ErrorAction SilentlyContinue
    [pscustomobject]@{ Code = $code; TimedOut = $timedOut; FocusMs = $focusMs }
}

function Get-LogLines([string]$log) { if (Test-Path $log) { @(Get-Content -LiteralPath $log -ErrorAction SilentlyContinue) } else { @() } }

function Stop-Leftover([string]$outDir) {   # VER-03: only processes whose exe lives in this run's out dir
    $left = @(Get-Process -Name 'DD-Project' -ErrorAction SilentlyContinue | Where-Object {
            try { $_.Path -like "$outDir\*" } catch { $false } })
    foreach ($x in $left) { Stop-Process -Id $x.Id -Force -ErrorAction SilentlyContinue }
    $left.Count
}

function Get-TreeHash([string]$dir) {       # names + times + SHA256 of every file; contents never printed
    if (-not (Test-Path -LiteralPath $dir)) { return 'ABSENT' }
    $rows = foreach ($f in (Get-ChildItem -LiteralPath $dir -Recurse -File -Force | Sort-Object FullName)) {
        try { $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash } catch { $h = 'UNREADABLE' }
        '{0}:{1}:{2}' -f $f.FullName.Substring($dir.Length), $f.LastWriteTimeUtc.Ticks, $h
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($rows -join '|'))
    [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes))
}

# DISP-04/06/07: pixel checks on a screenshot against the picture rectangle the game predicted (Display_CalcLayout).
# Works on raw pixels (LockBits), so a 1920x1080 picture costs milliseconds, not minutes.
$shotCheckOk = $true
try {
    Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
public static class ShotCheck {
    // Rect (rx, ry, rw, rh) is in PNG pixels. Black = all channels <= 2.
    // Returns: [0] width, [1] height, [2] non-black pixels outside the rect, [3] non-black share inside (0..1),
    //          [4..7] non-black share along the top, bottom, left, right edge line of the rect (0..1), [8] share that differs from the rect's main colour.
    public static double[] Analyze(string path, int rx, int ry, int rw, int rh) {
        using (Bitmap bmp = new Bitmap(path)) {
            int W = bmp.Width, H = bmp.Height;
            BitmapData d = bmp.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try {
                byte[] buf = new byte[Math.Abs(d.Stride) * H];
                System.Runtime.InteropServices.Marshal.Copy(d.Scan0, buf, 0, buf.Length);
                int stride = d.Stride;
                long outside = 0, inside = 0, insideTotal = 0;
                for (int y = 0; y < H; y++) {
                    for (int x = 0; x < W; x++) {
                        int o = y * stride + x * 4;
                        bool nb = buf[o] > 2 || buf[o + 1] > 2 || buf[o + 2] > 2;
                        bool inr = x >= rx && x < rx + rw && y >= ry && y < ry + rh;
                        if (inr) { insideTotal++; if (nb) inside++; } else if (nb) outside++;
                    }
                }
                double[] r = new double[9];
                // [8] share of the rect that differs from its most common colour by more than 30 (L1) = "there is a picture", even on a dark-blue background
                System.Collections.Generic.Dictionary<int, int> hist = new System.Collections.Generic.Dictionary<int, int>();
                int best = 0, bestN = 0;
                for (int y = Math.Max(0, ry); y < Math.Min(H, ry + rh); y += 2) for (int x = Math.Max(0, rx); x < Math.Min(W, rx + rw); x += 2) {
                    int o = y * stride + x * 4; int key = (buf[o] << 16) | (buf[o + 1] << 8) | buf[o + 2];
                    int c; hist.TryGetValue(key, out c); c++; hist[key] = c; if (c > bestN) { bestN = c; best = key; }
                }
                long diff = 0, tot = 0;
                for (int y = Math.Max(0, ry); y < Math.Min(H, ry + rh); y += 2) for (int x = Math.Max(0, rx); x < Math.Min(W, rx + rw); x += 2) {
                    int o = y * stride + x * 4; tot++;
                    int dd = Math.Abs(buf[o] - ((best >> 16) & 255)) + Math.Abs(buf[o + 1] - ((best >> 8) & 255)) + Math.Abs(buf[o + 2] - (best & 255));
                    if (dd > 30) diff++;
                }
                r[8] = tot > 0 ? (double)diff / tot : 0;
                r[0] = W; r[1] = H; r[2] = outside;
                r[3] = insideTotal > 0 ? (double)inside / insideTotal : 0;
                r[4] = Line(buf, stride, W, H, rx, ry, rw, 1);
                r[5] = Line(buf, stride, W, H, rx, ry + rh - 1, rw, 1);
                r[6] = Line(buf, stride, W, H, rx, ry, 1, rh);
                r[7] = Line(buf, stride, W, H, rx + rw - 1, ry, 1, rh);
                return r;
            } finally { bmp.UnlockBits(d); }
        }
    }
    // A1 (I-056/I-058/I-059): picture A (world marks on) against picture B (marks off), both in PNG pixels, offset (ox, oy) removed from every coordinate.
    //   boxes = x,y,w,h ... (places where a difference is allowed); ring = cx,cy,r,tol (an annulus where one is allowed); corner = x,y,n.
    //   rp / bp = probe x,y ... that must DIFFER between A and B (within 1 px); ap = x,y ... that must be exactly the outline colour #071821 in A.
    // Returns: [0] differing pixels outside every allowed place, [1] differing pixels in the corner square, [2],[3] first stray pixel,
    //          [4] ring probes that differ, [5] ring probes, [6] "!" probes that differ, [7] "!" probes, [8] outline probes that match (best bob group), [9] outline probes per group, [10] differing pixels in all.
    public static double[] World(string pa, string pb, int ox, int oy, int[] boxes, double[] ring, int[] corner, int[] rp, int[] bp, int[] ap) {
        using (Bitmap A = new Bitmap(pa)) using (Bitmap B = new Bitmap(pb)) {
            int W = A.Width, H = A.Height;
            if (B.Width != W || B.Height != H) return new double[] { -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
            BitmapData da = A.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            BitmapData db = B.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try {
                byte[] a = new byte[Math.Abs(da.Stride) * H]; byte[] b = new byte[Math.Abs(db.Stride) * H];
                System.Runtime.InteropServices.Marshal.Copy(da.Scan0, a, 0, a.Length);
                System.Runtime.InteropServices.Marshal.Copy(db.Scan0, b, 0, b.Length);
                int stride = da.Stride;
                double[] r = new double[11];
                r[2] = -1; r[3] = -1;
                for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
                    int o = y * stride + x * 4;
                    if (a[o] == b[o] && a[o + 1] == b[o + 1] && a[o + 2] == b[o + 2]) continue;
                    r[10]++;
                    int px = x + ox, py = y + oy;   // back to window pixels, the game's coordinates
                    if (px >= corner[0] && px < corner[0] + corner[2] && py >= corner[1] && py < corner[1] + corner[2]) r[1]++;
                    bool ok = false;
                    for (int i = 0; i + 3 < boxes.Length && !ok; i += 4) ok = px >= boxes[i] && px < boxes[i] + boxes[i + 2] && py >= boxes[i + 1] && py < boxes[i + 1] + boxes[i + 3];
                    if (!ok && ring.Length == 4) { double d = Math.Sqrt((px - ring[0]) * (px - ring[0]) + (py - ring[1]) * (py - ring[1])); ok = Math.Abs(d - ring[2]) <= ring[3]; }
                    if (!ok) { r[0]++; if (r[2] < 0) { r[2] = px; r[3] = py; } }
                }
                for (int i = 0; i + 1 < rp.Length; i += 2) { r[5]++; if (Differs(a, b, stride, W, H, rp[i] - ox, rp[i + 1] - oy)) r[4]++; }
                for (int i = 0; i + 1 < bp.Length; i += 2) { r[7]++; if (Differs(a, b, stride, W, H, bp[i] - ox, bp[i + 1] - oy)) r[6]++; }
                // ap = groups of 7 probes (14 ints), one group per arrow bob height: the picture shows one of them, so the best group counts
                r[9] = 7;
                for (int g = 0; g + 13 < ap.Length; g += 14) {
                    int hit = 0;
                    for (int i = g; i < g + 14; i += 2) {
                        int x = ap[i] - ox, y = ap[i + 1] - oy;
                        if (x >= 0 && y >= 0 && x < W && y < H) { int o = y * stride + x * 4; if (a[o + 2] == 7 && a[o + 1] == 24 && a[o] == 33) hit++; }   // BGRA
                    }
                    if (hit > r[8]) r[8] = hit;
                }
                return r;
            } finally { A.UnlockBits(da); B.UnlockBits(db); }
        }
    }
    static bool Differs(byte[] a, byte[] b, int stride, int W, int H, int cx, int cy) {
        for (int y = cy - 1; y <= cy + 1; y++) for (int x = cx - 1; x <= cx + 1; x++) {
            if (x < 0 || y < 0 || x >= W || y >= H) continue;
            int o = y * stride + x * 4;
            if (a[o] != b[o] || a[o + 1] != b[o + 1] || a[o + 2] != b[o + 2]) return true;
        }
        return false;
    }
    static double Line(byte[] buf, int stride, int W, int H, int x0, int y0, int w, int h) {
        long n = 0, nb = 0;
        for (int y = y0; y < y0 + h; y++) for (int x = x0; x < x0 + w; x++) {
            if (x < 0 || y < 0 || x >= W || y >= H) continue;
            int o = y * stride + x * 4; n++;
            if (buf[o] > 2 || buf[o + 1] > 2 || buf[o + 2] > 2) nb++;
        }
        return n > 0 ? (double)nb / n : 0;
    }
}
'@
} catch { $shotCheckOk = $false; Write-Host "FAIL shot pixel checker did not compile: $($_.Exception.Message)"; $script:failed = $true }

# VER-09 + DISP-04/06/07: copy the PNGs out of the save dir, then check each [SHOT] line: file exists; PNG is the whole window (or, with the
# Windows Scaling option on "keep aspect", the engine's application rectangle); not mostly one colour; and, when the line carries the
# game's predicted picture rectangle (gx gy gw gh): nothing but black outside it, picture on all four of its edges (edge=1), the last
# cutscene art still visible during the exit fade (art=1).
function Test-Shots([string[]]$lines, [int]$expect, [string]$dirKey = 'shots') {
    $problems = @()
    $shotDir = $D[$dirKey]
    Get-ChildItem $D.save -Recurse -Filter 'shot_*.png' -File -ErrorAction SilentlyContinue | ForEach-Object { Copy-Item $_.FullName $shotDir -Force }
    $rows = @($lines | Where-Object { $_ -match '^\[SHOT\] file=(\S+) w=(\d+) h=(\d+)' } | ForEach-Object {
        $line = $_
        $o = [ordered]@{ File = $null; W = 0; H = 0; Rect = $null; App = $null; Edge = $false; Art = $false; Fade = $false; Pair = $null; cornerxy = $null; ringc = $null; rp = $null; bp = $null; ap = $null; boxes = $null }
        $null = $line -match '^\[SHOT\] file=(\S+) w=(\d+) h=(\d+)'; $o.File = $Matches[1]; $o.W = [int]$Matches[2]; $o.H = [int]$Matches[3]
        if ($line -match ' gx=(-?\d+) gy=(-?\d+) gw=(\d+) gh=(\d+)') { $o.Rect = @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4]) }
        if ($line -match ' app=(-?\d+),(-?\d+),(-?\d+),(-?\d+)') { $o.App = @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4]) }
        $o.Edge = ($line -match ' edge=1'); $o.Art = ($line -match ' art=1'); $o.Fade = ($line -match ' fade=1')
        if ($line -match ' pair=(\S+)') { $o.Pair = $Matches[1] }
        foreach ($k in 'cornerxy', 'ringc', 'rp', 'bp', 'ap', 'boxes') { if ($line -match " $k=(\S+)") { $o[$k] = $Matches[1] } }
        [pscustomobject]$o })
    if ($rows.Count -ne $expect) { $problems += "expected $expect [SHOT] lines, got $($rows.Count)" }
    Add-Type -AssemblyName System.Drawing
    foreach ($r in $rows) {
        $path = Join-Path $shotDir $r.File
        if (-not (Test-Path -LiteralPath $path)) { $problems += "$($r.File) missing"; continue }
        $bmp = $null
        try {
            $bmp = New-Object System.Drawing.Bitmap $path
            $pw = $bmp.Width; $ph = $bmp.Height
            $ox = 0; $oy = 0; $sizeOk = ($pw -eq $r.W -and $ph -eq $r.H)
            if (-not $sizeOk -and $r.App -and $pw -eq ($r.App[2] - $r.App[0]) -and $ph -eq ($r.App[3] - $r.App[1])) { $sizeOk = $true; $ox = $r.App[0]; $oy = $r.App[1] }   # keep-aspect: PNG = the application rectangle
            if (-not $sizeOk) { $problems += "$($r.File) is ${pw}x${ph}, window said $($r.W)x$($r.H)" }
            $seen = @{}; $n = 0
            for ($y = 0; $y -lt $ph; $y += 8) { for ($x = 0; $x -lt $pw; $x += 8) {
                $k = $bmp.GetPixel($x, $y).ToArgb(); $seen[$k] = 1 + [int]$seen[$k]; $n++ } }
            $top = ($seen.Values | Measure-Object -Maximum).Maximum / [double]$n
            if ($top -gt $ShotMaxOneColour -and -not $r.Fade) { $problems += ('{0} is {1:P0} one colour' -f $r.File, $top) }
        } catch { $problems += "$($r.File) unreadable: $($_.Exception.Message)"; $sizeOk = $false }
        finally { if ($bmp) { $bmp.Dispose() } }
        if ($sizeOk -and $r.Rect -and $shotCheckOk) {
            $a = [ShotCheck]::Analyze($path, $r.Rect[0] - $ox, $r.Rect[1] - $oy, $r.Rect[2], $r.Rect[3])
            if ($a[2] -gt 0) { $problems += ('{0}: {1} non-black pixels outside the predicted picture rectangle {2},{3} {4}x{5}' -f $r.File, [int]$a[2], $r.Rect[0], $r.Rect[1], $r.Rect[2], $r.Rect[3]) }
            if ($r.Edge -and -not $r.Fade) {
                $names = 'top', 'bottom', 'left', 'right'
                for ($i = 0; $i -lt 4; $i++) { if ($a[4 + $i] -lt 0.4) { $problems += ('{0}: the {1} edge of the predicted rectangle carries picture on only {2:P0} of its length (offset or wrong size)' -f $r.File, $names[$i], $a[4 + $i]) } }
            }
            if ($r.Art -and $a[8] -lt 0.05) { $problems += ('{0}: the cutscene art is gone (only {1:P1} of the picture differs from the background)' -f $r.File, $a[8]) }
        }
        if ($sizeOk -and $r.Pair -and $shotCheckOk) {
            $pb = Join-Path $shotDir $r.Pair
            if (-not (Test-Path -LiteralPath $pb)) { $problems += "$($r.File): partner picture $($r.Pair) missing"; continue }
            $ints = { param($t) if (-not $t) { [int[]]@() } else { [int[]]@($t -split '[;,]' | ForEach-Object { [int]$_ }) } }
            $cxy = & $ints $r.cornerxy
            $rc = [double[]]@(($r.ringc -split ',') | ForEach-Object { [double]$_ })
            $w = [ShotCheck]::World((Join-Path $shotDir $r.File), $pb, $ox, $oy, (& $ints $r.boxes), $rc, [int[]]@($cxy[0], $cxy[1], 24), (& $ints $r.rp), (& $ints $r.bp), (& $ints $r.ap))
            if ($w[0] -lt 0) { $problems += "$($r.File) and $($r.Pair) differ in size" }
            else {
                if ($w[1] -gt 0) { $problems += ('{0}: {1} pixels differ in the top-left 24x24 corner of the picture (a world mark drawn at the corner)' -f $r.File, [int]$w[1]) }
                if ($w[0] -gt 0) { $problems += ('{0}: {1} marked pixels outside the places the marks belong (first at window {2},{3})' -f $r.File, [int]$w[0], [int]$w[2], [int]$w[3]) }
                if ($w[5] -lt 4) { $problems += ('{0}: only {1} light probes on the picture (stage wrong)' -f $r.File, [int]$w[5]) }
                elseif ($w[4] -lt 2) { $problems += ('{0}: the faint sight cone is not drawn (D179 replaces D160): only {1} of {2} sight cells differ with the enemy gone (a tint cannot change a pixel that is already the lightest colour, so not all of them do)' -f $r.File, [int]$w[4], [int]$w[5]) }
                if ($w[6] -lt $w[7]) { $problems += ('{0}: the "!" is not where it belongs' -f $r.File) }
                if ($w[8] -lt $w[9]) { $problems += ('{0}: the interact arrow has no #071821 outline where expected ({1} of {2} probes)' -f $r.File, [int]$w[8], [int]$w[9]) }
            }
        }
    }
    $problems
}

# ---- drive guard (VER-15): must run before anything is created or deleted ----------------------
$WorkRoot = [IO.Path]::GetFullPath($WorkRoot).TrimEnd('\')
if ($WorkRoot.Length -le 3) { Refuse "work root '$WorkRoot' is a drive root" }
$D = @{}
foreach ($n in 'src', 'cache', 'tmp', 'out', 'save', 'logs', 'shots', 'gridshots', 'export') {
    $D[$n] = Join-Path $WorkRoot $n
    foreach ($r in (Get-DriveRoots $D[$n])) {
        if ($r -ieq 'C:\' -or $r -ieq "$env:SystemDrive\") { Refuse "$n dir '$($D[$n])' is on drive C: (everything must live on E:)" }
    }
}
if (-not $ProjectDir) { $ProjectDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) }
$ProjectDir = [IO.Path]::GetFullPath($ProjectDir)
if (-not (Test-Path (Join-Path $ProjectDir 'DD-Project.yyp'))) { Refuse "no DD-Project.yyp in '$ProjectDir'" }

# ---- tools -------------------------------------------------------------------------------------
$RtRoot = 'C:\ProgramData\GameMakerStudio2\Cache\runtimes'
$Runtime = Join-Path $RtRoot 'runtime-2024.14.3.260'
if (-not (Test-Path $Runtime)) {
    $alt = Get-ChildItem $RtRoot -Directory -Filter 'runtime-*' -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
    if ($alt) { $Runtime = $alt.FullName }
}
$Igor = Join-Path $Runtime 'bin\igor\windows\x64\Igor.exe'
if (-not (Test-Path $Igor)) { Refuse "Igor.exe not found under $RtRoot" }
$UserDir = Get-ChildItem (Join-Path $env:APPDATA 'GameMakerStudio2') -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName 'licence.plist') } | Select-Object -First 1   # never touches um.json
if (-not $UserDir) { Refuse 'GameMaker user folder (with licence.plist) not found under %APPDATA%\GameMakerStudio2' }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Refuse 'git not found' }

# ---- real-save protection (VER-06): fingerprint before ----------------------------------------
$RealLocal = $env:LOCALAPPDATA
$RealSave = Join-Path $RealLocal 'DD_Project'
$SaveBefore = Get-TreeHash $RealSave
$Total = [Diagnostics.Stopwatch]::StartNew()

function Finish {
    $env:LOCALAPPDATA = $RealLocal
    if ((Get-TreeHash $RealSave) -ne $SaveBefore) {
        Write-Host '!!! FAIL REAL SAVE FILES CHANGED: %LOCALAPPDATA%\DD_Project differs from before the run !!!'
        $script:failed = $true
    }
    Write-Host ('total     {0:N1}s' -f $Total.Elapsed.TotalSeconds)
    if ($script:failed) { Write-Host 'GATE FAIL'; exit 1 }
    Write-Host 'GATE PASS'; exit 0
}

# ---- display source guard (DISP-02 / DISP-09): only scr_display / obj_display may call the window, surface, GUI-size, view and camera-size
# functions, and nobody may read display_get_gui_*. -NegativeControl plants a violation, so this step (and the gate) must go red.
$lintPy = Join-Path $ProjectDir 'tools\display\lint_display_calls.py'
if (Test-Path $lintPy) {
    $sw = [Diagnostics.Stopwatch]::StartNew(); $fails0 = $script:failCount
    $pyExe = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pyExe) { Fail 'lint: python not found (the display source guard needs it)' }
    else {
        $lintArgs = @($lintPy, '--root', $ProjectDir); if ($NegativeControl -and $Plant -eq 'test') { $lintArgs += '--plant' }
        $lintOut = @(& $pyExe.Source @lintArgs)
        if ($LASTEXITCODE -ne 0) { $lintOut | Select-Object -First 12 | ForEach-Object { Write-Host "  $_" }; Fail 'lint: display source guard found violations' }
    }
    Step 'lint' $(if ($script:failCount -gt $fails0) { 'FAIL' } else { 'OK' }) $sw
}

# ---- hardcoded English (I1): no new player-facing literals in the scoped GML files; the lint's own self-check runs first.
$txtPy = Join-Path $ProjectDir 'tools\localization\lint_hardcoded_text.py'
if (Test-Path $txtPy) {
    $sw = [Diagnostics.Stopwatch]::StartNew(); $fails0 = $script:failCount
    $pyExe = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pyExe) { Fail 'text lint: python not found' }
    else {
        $ErrorActionPreference = 'Continue'   # python writes its test report to stderr; 2>&1 would otherwise throw
        $selfPy = Join-Path $ProjectDir 'tools\localization\test_lint_hardcoded_text.py'
        if (Test-Path $selfPy) {
            $selfOut = @(& $pyExe.Source $selfPy 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch '^System.Management.Automation.RemoteException' })
            if ($LASTEXITCODE -ne 0) { $selfOut | Select-Object -Last 12 | ForEach-Object { Write-Host "  $_" }; Fail 'text lint: self-check failed' }
        }
        $txtOut = @(& $pyExe.Source $txtPy 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch '^System.Management.Automation.RemoteException' })
        if ($LASTEXITCODE -ne 0) { $txtOut | Select-Object -First 12 | ForEach-Object { Write-Host "  $_" }; Fail 'text lint: hardcoded player-facing literals found' }
        $ErrorActionPreference = 'Stop'
    }
    Step 'text-lint' $(if ($script:failCount -gt $fails0) { 'FAIL' } else { 'OK' }) $sw
}

# ---- one word per meaning, Title Case labels (D133, G11): tools/localization/lint_terms.py; its own self-check runs first.
$termsPy = Join-Path $ProjectDir 'tools\localization\lint_terms.py'
if (Test-Path $termsPy) {
    $sw = [Diagnostics.Stopwatch]::StartNew(); $fails0 = $script:failCount
    $pyExe = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pyExe) { Fail 'terms lint: python not found' }
    else {
        $ErrorActionPreference = 'Continue'
        $termsSelf = @(& $pyExe.Source $termsPy --selftest 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch '^System.Management.Automation.RemoteException' })
        if ($LASTEXITCODE -ne 0) { $termsSelf | Select-Object -Last 12 | ForEach-Object { Write-Host "  $_" }; Fail 'terms lint: self-check failed' }
        $termsOut = @(& $pyExe.Source $termsPy 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch '^System.Management.Automation.RemoteException' })
        if ($LASTEXITCODE -ne 0) { $termsOut | Select-Object -First 12 | ForEach-Object { Write-Host "  $_" }; Fail 'terms lint: a banned variant or a label that is not Title Case (docs/terminology-g11.md)' }
        $ErrorActionPreference = 'Stop'
    }
    Step 'terms-lint' $(if ($script:failCount -gt $fails0) { 'FAIL' } else { 'OK' }) $sw
}

# ---- missing Korean (D9): every workbook row needs a real ko (tools/localization/check_missing_ko.py, allowlist in ko_allowlist.txt).
$koPy = Join-Path $ProjectDir 'tools\localization\check_missing_ko.py'
if (Test-Path $koPy) {
    $sw = [Diagnostics.Stopwatch]::StartNew(); $fails0 = $script:failCount
    $pyExe = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pyExe) { Fail 'ko check: python not found' }
    else {
        $koOut = @(& $pyExe.Source $koPy)
        if ($LASTEXITCODE -ne 0) { $koOut | Select-Object -First 12 | ForEach-Object { Write-Host "  $_" }; Fail 'ko check: rows without a Korean translation' }
    }
    Step 'ko-check' $(if ($script:failCount -gt $fails0) { 'FAIL' } else { 'OK' }) $sw
}

# ---- fresh work dirs; copy working tree (tracked + untracked-not-ignored) -----------------------
$sw = [Diagnostics.Stopwatch]::StartNew()
foreach ($n in 'src', 'out', 'save', 'logs', 'shots', 'gridshots') { if (Test-Path $D[$n]) { Remove-Item $D[$n] -Recurse -Force } }
# 'export' is created but never emptied: the last data export stays available for the simulator between runs
foreach ($n in 'src', 'cache', 'tmp', 'out', 'save', 'logs', 'shots', 'gridshots', 'export') { $null = New-Item -ItemType Directory -Force -Path $D[$n] }

$psi = New-Object Diagnostics.ProcessStartInfo 'git'
$psi.Arguments = 'ls-files -co --exclude-standard -z'
$psi.WorkingDirectory = $ProjectDir
$psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true; $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
$gp = [Diagnostics.Process]::Start($psi)
$listing = $gp.StandardOutput.ReadToEnd(); $gp.WaitForExit()
if ($gp.ExitCode -ne 0) { Fail "git ls-files failed in $ProjectDir"; Finish }
$made = New-Object 'System.Collections.Generic.HashSet[string]'
$count = 0
foreach ($rel in ($listing -split "`0")) {
    if (-not $rel) { continue }
    $from = Join-Path $ProjectDir $rel
    if (-not (Test-Path -LiteralPath $from -PathType Leaf)) { continue }   # deleted in the working tree
    $to = Join-Path $D.src $rel
    $dir = Split-Path -Parent $to
    if ($made.Add($dir)) { $null = New-Item -ItemType Directory -Force -Path $dir }
    [IO.File]::Copy($from, $to, $true); $count++
}
Step 'copy' "$count" $sw

# ---- build id (VER-10): stamped into the SCRATCH copy only; the repo's macro stays "dev" -------------
$BuildId = 'nogit'
try {
    $h = (& git -C $ProjectDir rev-parse --short HEAD) | Out-String
    $dirty = (& git -C $ProjectDir status --porcelain) | Out-String
    if ($h.Trim()) { $BuildId = '{0}-{1}{2}' -f $h.Trim(), (Get-Date -Format 'yyyyMMdd'), $(if ($dirty.Trim()) { '-dirty' } else { '' }) }
} catch { }
$macroFile = Join-Path $D.src 'scripts\scr_macros\scr_macros.gml'
$macroText = [IO.File]::ReadAllText($macroFile)
$stamped = [regex]::Replace($macroText, '(?m)^#macro BUILD_ID "[^"\r\n]*"', "#macro BUILD_ID `"$BuildId`"")
if ($stamped -eq $macroText -and $macroText -notmatch ('#macro BUILD_ID "' + [regex]::Escape($BuildId) + '"')) { Fail 'BUILD_ID macro not found in scr_macros.gml'; Finish }
[IO.File]::WriteAllText($macroFile, $stamped, (New-Object Text.UTF8Encoding $false))
Write-Host "build id  $BuildId"

# ---- negative-control plants (R-021): into the SCRATCH copy only; the repo is never touched ------------
if ($NegativeControl -and $Plant -ne 'test') {
    $plantFile = Join-Path $D.src 'scripts\scr_test\scr_test.gml'
    $plantText = [IO.File]::ReadAllText($plantFile)
    if ($Plant -eq 'syntax') {
        $plantText += "`n" + 'function __plant_syntax_error() { var __x = ( ; }' + "`n"   # unbalanced parenthesis: Igor must fail the build
        Write-Host 'plant     syntax error appended to the scratch scr_test.gml (expect: build fails)'
    } else {
        $hook = 'Test_Reset();'
        $fnAt = $plantText.IndexOf('function Test_RunAll()')
        if ($fnAt -lt 0) { Fail 'plant anchor not found: function Test_RunAll() is missing from the scratch scr_test.gml'; Finish }
        $at = $plantText.IndexOf($hook, $fnAt)
        if ($at -lt 0) { Fail "plant anchor not found: '$hook' is missing after function Test_RunAll()"; Finish }
        # Igor compiles an unknown function name without complaint; only running the call raises the error
        $plantText = $plantText.Insert($at + $hook.Length, "`n" + '    Test_RunSuite("PlantUnknownFn", function() { __plant_no_such_function_xyz(); });')
        Write-Host 'plant     call to an unknown function added to the scratch Test_RunAll (expect: build ok, test run fails)'
    }
    [IO.File]::WriteAllText($plantFile, $plantText, (New-Object Text.UTF8Encoding $false))
}

# ---- build (VER-01): the exact command proven in automation-igor.md 2.4 -------------------------
$sw = [Diagnostics.Stopwatch]::StartNew()
$fw = { param($p) $p.Replace('\', '/') }
$buildLog = Join-Path $D.logs 'build.log'
$igorArgs = '-j=4 --project="{0}" --user="{1}" --runtimePath="{2}" --runtime=VM --cache="{3}" --temp="{4}" --of="{5}" --tf="{6}" -- windows PackageZip' -f `
    (& $fw (Join-Path $D.src 'DD-Project.yyp')), (& $fw $UserDir.FullName), (& $fw $Runtime), (& $fw $D.cache), (& $fw $D.tmp), `
    (& $fw (Join-Path $D.out 'DD-Project.win')), (& $fw (Join-Path $D.out 'DD-Project.zip'))
$r = Invoke-Proc $Igor $igorArgs $WorkRoot $buildLog $BuildTimeout 'Hidden'
$errLines = @(Get-LogLines $buildLog | Where-Object { $_ -match '^\s*Error\s*:|System\.\w+Exception' })
$exe = Join-Path $D.out 'DD-Project.exe'
$buildOk = $true
if ($r.TimedOut) { Fail "build timed out after ${BuildTimeout}s"; $buildOk = $false }
elseif ($r.Code -ne 0) { Fail "build exit code $($r.Code)"; $buildOk = $false }
if ($errLines.Count -gt 0) { $buildOk = $false; $errLines | Select-Object -First 12 | ForEach-Object { Write-Host "FAIL build: $($_.Trim())" } }
if ($buildOk -and -not ((Test-Path $exe) -and (Test-Path (Join-Path $D.out 'data.win')))) { Fail 'build produced no DD-Project.exe/data.win'; $buildOk = $false }
if (-not $buildOk) {
    if ($errLines.Count -eq 0) { Get-LogLines $buildLog | Select-Object -Last 5 | ForEach-Object { Write-Host "  log: $_" } }
    $script:failed = $true
}
Step 'build' $(if ($buildOk) { 'OK' } else { 'FAIL' }) $sw
if (-not $buildOk -or $Mode -eq 'compile') { Finish }

# ---- game runs (VER-02/03/05) -------------------------------------------------------------------
$runs = if ($Mode -eq 'full') { @($GameModes | Where-Object { -not $_.Explicit }) } else { @($GameModes | Where-Object { $_.Name -eq 'runtests' }) }
if ($Only) { $runs = @($GameModes | Where-Object { $_.Name -eq $Only }) }
foreach ($m in $runs) {
    if (-not $m.Impl) { Write-Host "SKIP $($m.Name) (not implemented)"; continue }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    if (Test-Path $D.save) { Remove-Item $D.save -Recurse -Force }
    $null = New-Item -ItemType Directory -Force -Path $D.save
    $log = Join-Path $D.logs "$($m.Name).log"
    $gameArgs = "-game data.win $($m.Flag)"
    if ($NegativeControl -and $Plant -eq 'test') { $gameArgs += ' -testcontrol' }
    $env:LOCALAPPDATA = $D.save                 # VER-06: the game must never see the real save area
    try { $r = Invoke-Proc $exe $gameArgs $D.out $log $m.Timeout 'Minimized' $true } finally { $env:LOCALAPPDATA = $RealLocal }
    $lines = Get-LogLines $log
    $why = @()
    if ($r.TimedOut) { $why += "timeout after $($m.Timeout)s" }
    if ($m.Strict -and -not $r.TimedOut -and $r.Code -ne 0) { $why += "exit code $($r.Code)" }
    $left = Stop-Leftover $D.out
    if ($left -gt 0) { $why += "$left DD-Project process(es) left running (killed)" }
    $sum = @($lines | Where-Object { $_ -match '\[TEST-SUMMARY\]\s+pass=(\d+)\s+fail=(\d+)\s+errors=(\d+)' })
    if ($sum.Count -eq 0) { $why += 'missing [TEST-SUMMARY]' }
    else {
        $null = $sum[-1] -match 'pass=(\d+)\s+fail=(\d+)\s+errors=(\d+)'
        if ([int]$Matches[2] -gt 0 -or [int]$Matches[3] -gt 0) { $why += "summary reports fail=$($Matches[2]) errors=$($Matches[3])" }
        elseif ([int]$Matches[1] -eq 0) { $why += 'summary reports pass=0 (no tests ran)' }
    }
    $bad = @($lines | Where-Object { $_ -match "$BadLine|\[TEST\] FAIL" })
    if (@($bad | Where-Object { $_ -match $BadLine }).Count -gt 0) { $why += 'UNHANDLED/CRASH/ERROR line in log' }
    if ($m.Strict -and -not (Get-ChildItem $D.save -Recurse -Filter $ResultFile -File -ErrorAction SilentlyContinue)) { $why += "missing $ResultFile in save area" }
    $bid = @($lines | Where-Object { $_ -match '^\[TEST-BUILD\]\s+(\S+)' } | ForEach-Object { $Matches[1] })   # VER-10
    if ($bid.Count -eq 0) { $why += 'missing [TEST-BUILD]' }
    elseif ($bid[0] -ne $BuildId) { $why += "build id in game '$($bid[0])' differs from stamped '$BuildId'" }
    if ($r.FocusMs -ge 0) { $why += "game window took the foreground after $($r.FocusMs) ms (I-053)" }
    if ($m.Export) {   # B1: copy the data export out of the save dir and check that it parses and every id list is unique
        $ef = Get-ChildItem $D.save -Recurse -Filter 'export_data.json' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $ef) { $why += 'missing export_data.json in save area' }
        else {
            Copy-Item $ef.FullName $D.export -Force
            try {
                $j = Get-Content -Raw -LiteralPath $ef.FullName | ConvertFrom-Json
                foreach ($sec in 'classes', 'enemies', 'skills', 'items', 'statuses') {
                    $ids = @($j.$sec | ForEach-Object { $_.id })
                    if ($ids.Count -eq 0 -or @($ids | Select-Object -Unique).Count -ne $ids.Count) { $why += "export_data.json: $sec ids empty or not unique" }
                }
            } catch { $why += "export_data.json does not parse: $($_.Exception.Message)" }
        }
    }
    if ($m.Shots) { $why += @(Test-Shots $lines $m.Shots $(if ($m.ShotDir) { $m.ShotDir } else { 'shots' })) }
    $bad | Select-Object -First 20 | ForEach-Object { Write-Host "  $($_.Trim())" }
    if ($why.Count -gt 0) { Fail "$($m.Name): $($why -join '; ')" }
    Step $m.Name $(if ($why.Count -eq 0) { 'OK' } else { 'FAIL' }) $sw
    if ($m.Name -eq 'runtests' -and $bid.Count -gt 0) { Write-Host "          build=$($bid[0])" }
}
Finish
