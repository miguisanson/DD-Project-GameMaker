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
    [switch]$NegativeControl,
    [string]$ProjectDir = '',                  # default: repo root of this script
    [string]$WorkRoot = 'E:\Temp\dd-gate'      # test hook: point at C:\ to see the drive guard refuse
)
$ErrorActionPreference = 'Stop'

# ---- game modes: ONE ROW EACH. Flip Impl to $true when a packet implements the mode. ----------
# Strict = also require exit code 0 and the result file (only -runtests; crash exit codes are unreliable).
$GameModes = @(
    @{ Name = 'runtests'; Flag = '-runtests'; Timeout = 30;  Impl = $true;  Strict = $true  }
    @{ Name = 'smoke';    Flag = '-smoke';    Timeout = 60;  Impl = $false; Strict = $false }
    @{ Name = 'bot';      Flag = '-bot';      Timeout = 120; Impl = $false; Strict = $false }
    @{ Name = 'shots';    Flag = '-shots';    Timeout = 60;  Impl = $false; Strict = $false }
)
$BuildTimeout = 300
$ResultFile = 'test_results.txt'
$BadLine = 'UNHANDLED|CRASH|\[TEST\] ERROR'

# ---- helpers ----------------------------------------------------------------------------------
function Refuse([string]$msg) { Write-Host "GATE REFUSED: $msg"; exit 2 }
$script:failed = $false
function Fail([string]$msg) { Write-Host "FAIL $msg"; $script:failed = $true }
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

function Invoke-Proc([string]$exe, [string]$argStr, [string]$wd, [string]$log, [int]$timeout, [string]$style) {
    $p = Start-Process -FilePath $exe -ArgumentList $argStr -WorkingDirectory $wd -PassThru -WindowStyle $style `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    $null = $p.Handle                       # needed or ExitCode comes back empty in PS 5.1
    $timedOut = -not $p.WaitForExit($timeout * 1000)
    if ($timedOut) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; $null = $p.WaitForExit(5000) }
    $code = $null; if (-not $timedOut) { $code = $p.ExitCode }
    if ((Test-Path "$log.err") -and (Get-Item "$log.err").Length -gt 0) { Get-Content "$log.err" | Add-Content -Path $log }
    Remove-Item "$log.err" -Force -ErrorAction SilentlyContinue
    [pscustomobject]@{ Code = $code; TimedOut = $timedOut }
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

# ---- drive guard (VER-15): must run before anything is created or deleted ----------------------
$WorkRoot = [IO.Path]::GetFullPath($WorkRoot).TrimEnd('\')
if ($WorkRoot.Length -le 3) { Refuse "work root '$WorkRoot' is a drive root" }
$D = @{}
foreach ($n in 'src', 'cache', 'tmp', 'out', 'save', 'logs') {
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

# ---- fresh work dirs; copy working tree (tracked + untracked-not-ignored) -----------------------
$sw = [Diagnostics.Stopwatch]::StartNew()
foreach ($n in 'src', 'out', 'save', 'logs') { if (Test-Path $D[$n]) { Remove-Item $D[$n] -Recurse -Force } }
foreach ($n in 'src', 'cache', 'tmp', 'out', 'save', 'logs') { $null = New-Item -ItemType Directory -Force -Path $D[$n] }

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
$runs = if ($Mode -eq 'full') { $GameModes } else { @($GameModes | Where-Object { $_.Name -eq 'runtests' }) }
foreach ($m in $runs) {
    if (-not $m.Impl) { Write-Host "SKIP $($m.Name) (not implemented)"; continue }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    if (Test-Path $D.save) { Remove-Item $D.save -Recurse -Force }
    $null = New-Item -ItemType Directory -Force -Path $D.save
    $log = Join-Path $D.logs "$($m.Name).log"
    $gameArgs = "-game data.win $($m.Flag)"
    if ($NegativeControl) { $gameArgs += ' -testcontrol' }
    $env:LOCALAPPDATA = $D.save                 # VER-06: the game must never see the real save area
    try { $r = Invoke-Proc $exe $gameArgs $D.out $log $m.Timeout 'Minimized' } finally { $env:LOCALAPPDATA = $RealLocal }
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
    $bad | Select-Object -First 20 | ForEach-Object { Write-Host "  $($_.Trim())" }
    if ($why.Count -gt 0) { Fail "$($m.Name): $($why -join '; ')" }
    Step $m.Name $(if ($why.Count -eq 0) { 'OK' } else { 'FAIL' }) $sw
}
Finish
