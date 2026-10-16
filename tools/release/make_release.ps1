<#
.SYNOPSIS  NO HOPE release: gate, copy the built game, README / CREDITS / LICENSES, zip. Windows PowerShell 5.1 compatible. No downloads.
.DESCRIPTION
  1. Refuses unless the destination is on drive E: and E: has room (exit 2).
  2. Refuses a dirty working tree, untracked files included (exit 3).
  3. Runs the gate (run_tests.ps1 -Mode fast) on the current commit; it must print GATE PASS and a build id that is not "-dirty" (exit 4).
  4. Copies the built game from <WorkRoot>\out into <DestRoot>\NO-HOPE-v1.0-windows\ : the exe (as "NO HOPE.exe"), data.win, options.ini, data, the Galmuri font
     with its licence, localization\localization.json; README.txt, CREDITS.txt and LICENSES\ from tools\release. Left out on purpose: the Igor leftovers
     (DD-Project.zip, igor.output.manifest), the localization working files, and the two fonts the code never loads (Noto Sans CJK, NanumGothic; -IncludeUnusedFonts keeps them).
  5. Zips the folder to <DestRoot>\NO-HOPE-v1.0-windows.zip.
  -DryRun prints the plan (GATE command, TREE state, SPACE, one FILE line per file of the package, the ZIP path) and changes nothing; a dirty tree is reported as WOULD REFUSE.
  An existing package folder or zip is never overwritten without -Force.
  Exit codes: 0 ok, 2 destination / space / missing tool, 3 dirty tree, 4 gate failed, 5 a source file is missing, 6 the package already exists.
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$IncludeUnusedFonts,
    [switch]$SkipGate,                                # test hook: use the build already in SourceDir; refused for a destination under E:\Games
    [string]$ProjectDir = '',                         # default: the repo this script lives in
    [string]$WorkRoot = 'E:\Temp\dd-gate-release',    # the gate's scratch root (must contain "dd-gate")
    [string]$SourceDir = '',                          # default: <WorkRoot>\out (the gate's build); the dry-run tests point it at a fake one
    [string]$DestRoot = 'E:\Games\NO HOPE Release'
)
$ErrorActionPreference = 'Stop'
$PkgName = 'NO-HOPE-v1.0-windows'
$MinFreeGB = 5

function Refuse([int]$code, [string]$msg) { Write-Host "REFUSED: $msg"; exit $code }

if (-not $ProjectDir) { $ProjectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$ProjectDir = [IO.Path]::GetFullPath($ProjectDir)
$WorkRoot = [IO.Path]::GetFullPath($WorkRoot).TrimEnd('\')
if (-not $SourceDir) { $SourceDir = Join-Path $WorkRoot 'out' }
$SourceDir = [IO.Path]::GetFullPath($SourceDir).TrimEnd('\')
$DestRoot = [IO.Path]::GetFullPath($DestRoot).TrimEnd('\')
$PkgDir = Join-Path $DestRoot $PkgName
$ZipPath = Join-Path $DestRoot ($PkgName + '.zip')

# ---- 1. drive and space: E: only -----------------------------------------------------------------
if ([IO.Path]::GetPathRoot($DestRoot) -ine 'E:\') { Refuse 2 "the destination '$DestRoot' is not on drive E: (releases are built on E: only)" }
if ($SkipGate -and $DestRoot -like 'E:\Games*') { Refuse 2 '-SkipGate is a test hook and may not write into E:\Games: a release always runs the gate' }
if ($WorkRoot -notlike '*dd-gate*') { Refuse 2 "the work root '$WorkRoot' must contain 'dd-gate'" }
$free = [math]::Round((Get-PSDrive -Name E -ErrorAction Stop).Free / 1GB, 1)
Write-Host "SPACE E: $free GB free (need $MinFreeGB)"
if ($free -lt $MinFreeGB) { Refuse 2 "E: has only $free GB free, need $MinFreeGB" }

# ---- 2. the tree must be clean ----------------------------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Refuse 2 'git not found' }
$dirtyLines = @(& git -C $ProjectDir status --porcelain 2>$null)
$dirty = ($LASTEXITCODE -ne 0) -or ($dirtyLines.Count -gt 0)
if ($dirty) { Write-Host "TREE dirty ($($dirtyLines.Count) changed or untracked paths in $ProjectDir)" } else { Write-Host "TREE clean ($ProjectDir)" }
if ($dirty -and -not $DryRun) { Refuse 3 'the working tree is not clean: commit or stash everything (untracked files too), then run again' }
if ($dirty -and $DryRun) { Write-Host 'WOULD REFUSE: dirty tree (a real run stops here with exit 3)' }

# ---- 3. the plan ---------------------------------------------------------------------------------------
$gateScript = Join-Path $ProjectDir 'tools\automation\run_tests.ps1'
$gateArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$gateScript`" -Mode fast -WorkRoot `"$WorkRoot`""
Write-Host "GATE powershell $gateArgs"

# The package as a list of @{ Src; Rel }. Built again after the gate: before a real run the build folder does not exist yet.
function Get-Plan {
$plan = New-Object System.Collections.ArrayList
function Add-File([string]$src, [string]$rel) { [void]$plan.Add(@{ Src = $src; Rel = $rel }) }
function Add-Tree([string]$srcDir, [string]$relDir) {
    if (-not (Test-Path -LiteralPath $srcDir)) { Add-File $srcDir $relDir; return }   # reported as MISSING
    foreach ($f in (Get-ChildItem -LiteralPath $srcDir -Recurse -File | Sort-Object FullName)) {
        Add-File $f.FullName (($relDir + $f.FullName.Substring($srcDir.Length)).Replace('\', '/'))
    }
}
Add-File (Join-Path $SourceDir 'DD-Project.exe') 'NO HOPE.exe'
Add-File (Join-Path $SourceDir 'data.win') 'data.win'
Add-File (Join-Path $SourceDir 'options.ini') 'options.ini'
Add-Tree (Join-Path $SourceDir 'data') 'data'
Add-Tree (Join-Path $SourceDir 'fonts\galmuri') 'fonts/galmuri'
Add-File (Join-Path $SourceDir 'localization\localization.json') 'localization/localization.json'
if ($IncludeUnusedFonts) {
    Add-File (Join-Path $SourceDir 'fonts\NotoSansCJKkr-Regular.otf') 'fonts/NotoSansCJKkr-Regular.otf'
    Add-File (Join-Path $SourceDir 'NanumGothic-Regular.ttf') 'NanumGothic-Regular.ttf'
}
Add-File (Join-Path $PSScriptRoot 'README.txt') 'README.txt'
Add-File (Join-Path $PSScriptRoot 'CREDITS.txt') 'CREDITS.txt'
$ofl = Join-Path $SourceDir 'fonts\galmuri\OFL-Galmuri.txt'
if (-not (Test-Path -LiteralPath $ofl)) { $ofl = Join-Path $ProjectDir 'datafiles\fonts\galmuri\OFL-Galmuri.txt' }
Add-File $ofl 'LICENSES/OFL-Galmuri.txt'
Add-File (Join-Path $PSScriptRoot 'LICENSES\CC-BY-4.0-attribution.txt') 'LICENSES/CC-BY-4.0-attribution.txt'
return ,$plan
}
$plan = Get-Plan

$missing = @($plan | Where-Object { -not (Test-Path -LiteralPath $_.Src -PathType Leaf) })
foreach ($p in $plan) { Write-Host "FILE $($p.Rel)" }
foreach ($m in $missing) { Write-Host "MISSING $($m.Src)" }
Write-Host "ZIP $ZipPath"

if ($DryRun) {
    Write-Host 'DRYRUN: nothing was run, copied or written.'
    exit 0
}

# ---- 4. nothing may be overwritten, then the gate ----------------------------------------------------
if ((Test-Path -LiteralPath $PkgDir) -and -not $Force) { Refuse 6 "'$PkgDir' already exists (move it away, or use -Force)" }
if ((Test-Path -LiteralPath $ZipPath) -and -not $Force) { Refuse 6 "'$ZipPath' already exists (move it away, or use -Force)" }
if (-not $SkipGate -and -not (Test-Path -LiteralPath $gateScript)) { Refuse 2 "gate script not found: $gateScript" }

if ($SkipGate) {
    Write-Host 'GATE skipped (-SkipGate, test hook)'
} else {
    Write-Host 'Running the gate on the current commit (a few minutes)...'
    $gateOut = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $gateScript -Mode fast -WorkRoot $WorkRoot 2>&1 | ForEach-Object { "$_" })
    $gateOut | Select-Object -Last 12 | ForEach-Object { Write-Host "  $_" }
    if (-not ($gateOut | Where-Object { $_ -match '^GATE PASS' })) { Refuse 4 'the gate did not print GATE PASS' }
    $bid = $gateOut | Where-Object { $_ -match '^build id\s+(\S+)' } | Select-Object -First 1
    if ($bid -match 'dirty') { Refuse 3 "the gate built from uncommitted files ($bid)" }
    Write-Host "BUILD $bid"
}

# ---- 5. copy and zip -----------------------------------------------------------------------------------
$plan = Get-Plan   # the build exists now
$missing = @($plan | Where-Object { -not (Test-Path -LiteralPath $_.Src -PathType Leaf) })
if ($missing.Count -gt 0) { foreach ($m in $missing) { Write-Host "MISSING $($m.Src)" }; Refuse 5 'a file of the package is missing in the build' }
New-Item -ItemType Directory -Force -Path $PkgDir | Out-Null
foreach ($p in $plan) {
    $dst = Join-Path $PkgDir ($p.Rel.Replace('/', '\'))
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath $p.Src -Destination $dst -Force
}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path -LiteralPath $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
# Entry names are written by hand with forward slashes: ZipFile.CreateFromDirectory on Windows PowerShell 5.1 stores backslashes, which the zip format does not allow
# (Explorer and 7-Zip cope, other unzip tools do not).
$zipStream = [IO.File]::Open($ZipPath, [IO.FileMode]::CreateNew)
try {
    $archive = New-Object IO.Compression.ZipArchive($zipStream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($p in $plan) {
            $entry = $archive.CreateEntry($PkgName + '/' + $p.Rel, [IO.Compression.CompressionLevel]::Optimal)
            $es = $entry.Open()
            try {
                $fs = [IO.File]::OpenRead($p.Src)
                try { $fs.CopyTo($es) } finally { $fs.Dispose() }
            } finally { $es.Dispose() }
        }
    } finally { $archive.Dispose() }
} finally { $zipStream.Dispose() }
$zipInfo = Get-Item -LiteralPath $ZipPath
$hash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash
Write-Host ("RELEASE OK {0} ({1:N1} MB) sha256 {2}" -f $ZipPath, ($zipInfo.Length / 1MB), $hash)
exit 0
