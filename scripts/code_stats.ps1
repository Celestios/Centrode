<#
.SYNOPSIS
    Codebase statistics for Mycelium project
.DESCRIPTION
    Counts lines of code, separating manual from generated files,
    broken down by Rust and Dart sides.
#>

param(
    [switch]$Detailed,
    [switch]$Json
)

$ErrorActionPreference = "SilentlyContinue"
$root = $PSScriptRoot | Split-Path

function Count-Lines {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 } }
    $content = Get-Content -Path $Path -ErrorAction SilentlyContinue
    if ($null -eq $content -or $content.Count -eq 0) { return @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 } }
    $total = $content.Count
    $blank = ($content | Where-Object { $_ -match '^\s*$' }).Count
    $comment = ($content | Where-Object { $_ -match '^\s*//' -or $_ -match '^\s*\*' -or $_ -match '^\s*/\*' }).Count
    $code = $total - $blank - $comment
    return @{ total = $total; code = [Math]::Max(0, $code); blank = $blank; comment = $comment; files = 1 }
}

function Merge-Stats {
    param([hashtable]$a, [hashtable]$b)
    return @{
        total   = $a.total + $b.total
        code    = $a.code + $b.code
        blank   = $a.blank + $b.blank
        comment = $a.comment + $b.comment
        files   = $a.files + $b.files
    }
}

function Print-Row {
    param([string]$Label, [hashtable]$Stats, [int]$PadLeft = 2, [hashtable]$Parent = $null)
    $pct = ""
    if ($Parent -and $Parent.code -gt 0) {
        $pct = (" ({0:N1}%)" -f (($Stats.code / $Parent.code) * 100))
    }
    $labelPadded = $Label.PadRight(30)
    $filesStr = $Stats.files.ToString().PadLeft(6)
    $codeStr = $Stats.code.ToString().PadLeft(8)
    $blankStr = $Stats.blank.ToString().PadLeft(8)
    $commentStr = $Stats.comment.ToString().PadLeft(8)
    $totalStr = $Stats.total.ToString().PadLeft(8)
    Write-Host (" " * $PadLeft + "$labelPadded  Files:$filesStr  Code:$codeStr  Blank:$blankStr  Cmt:$commentStr  Total:$totalStr$pct")
}

function Print-Section {
    param([string]$Title, [string]$Color)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor $Color
    Write-Host ("  $Title") -ForegroundColor $Color
    Write-Host ("=" * 70) -ForegroundColor $Color
    Write-Host ("  " + "Label".PadRight(28) + "Files".PadLeft(6) + "    Code".PadLeft(8) + "   Blank".PadLeft(8) + "     Cmt".PadLeft(8) + "   Total".PadLeft(8)) -ForegroundColor DarkGray
    Write-Host ("  " + ("-" * 66)) -ForegroundColor DarkGray
}

# ──────────────────────────────────────────────────────────────
# Rust source files
# ──────────────────────────────────────────────────────────────
$rustGenerated = @("rust/src/frb_generated.rs")

$rustTestFiles = Get-ChildItem -Path "$root\rust\tests" -Filter "*.rs" -Recurse -File -ErrorAction SilentlyContinue
$rustMacroFiles = Get-ChildItem -Path "$root\rust\mycelium_macros\src" -Filter "*.rs" -Recurse -File -ErrorAction SilentlyContinue
$rustScriptFiles = Get-ChildItem -Path "$root\rust\scripts" -Filter "*.rs" -Recurse -File -ErrorAction SilentlyContinue

$rustSrcFiles = Get-ChildItem -Path "$root\rust\src" -Filter "*.rs" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $rustGenerated -notcontains $_.FullName.Replace("$root\", "").Replace("\", "/") }

$rustManualStats = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
$rustGenStats    = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
$rustTestStats   = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
$rustMacroStats  = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
$rustScriptStats = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }

foreach ($f in $rustSrcFiles) { $rustManualStats = Merge-Stats $rustManualStats (Count-Lines $f.FullName) }
foreach ($f in $rustGenerated) { $rustGenStats = Merge-Stats $rustGenStats (Count-Lines (Join-Path $root $f)) }
foreach ($f in $rustTestFiles) { $rustTestStats = Merge-Stats $rustTestStats (Count-Lines $f.FullName) }
foreach ($f in $rustMacroFiles) { $rustMacroStats = Merge-Stats $rustMacroStats (Count-Lines $f.FullName) }
foreach ($f in $rustScriptFiles) { $rustScriptStats = Merge-Stats $rustScriptStats (Count-Lines $f.FullName) }

$rustTotalStats = Merge-Stats (Merge-Stats (Merge-Stats (Merge-Stats $rustManualStats $rustGenStats) $rustTestStats) $rustMacroStats) $rustScriptStats

# ──────────────────────────────────────────────────────────────
# Dart source files
# ──────────────────────────────────────────────────────────────
$dartGenPatterns = @("*.g.dart", "*.freezed.dart", "frb_generated.dart", "frb_generated.io.dart", "frb_generated.web.dart", "graph_node.ui.dart")

$dartLibFiles = Get-ChildItem -Path "$root\lib" -Filter "*.dart" -Recurse -File -ErrorAction SilentlyContinue
$dartLibManual = $dartLibFiles | Where-Object {
    $name = $_.Name; $match = $false
    foreach ($pat in $dartGenPatterns) { if ($name -like $pat) { $match = $true; break } }
    -not $match
}
$dartLibGen = $dartLibFiles | Where-Object {
    $name = $_.Name; $match = $false
    foreach ($pat in $dartGenPatterns) { if ($name -like $pat) { $match = $true; break } }
    $match
}

$dartPkgFiles = Get-ChildItem -Path "$root\packages" -Filter "*.dart" -Recurse -File -ErrorAction SilentlyContinue
$dartTestFiles = Get-ChildItem -Path "$root\test" -Filter "*.dart" -Recurse -File -ErrorAction SilentlyContinue
$dartIntegFiles = Get-ChildItem -Path "$root\integration_test" -Filter "*.dart" -Recurse -File -ErrorAction SilentlyContinue

$dartLibManualStats = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
$dartLibGenStats    = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
$dartPkgStats       = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
$dartTestStats      = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
$dartIntegStats     = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }

foreach ($f in $dartLibManual) { $dartLibManualStats = Merge-Stats $dartLibManualStats (Count-Lines $f.FullName) }
foreach ($f in $dartLibGen) { $dartLibGenStats = Merge-Stats $dartLibGenStats (Count-Lines $f.FullName) }
foreach ($f in $dartPkgFiles) { $dartPkgStats = Merge-Stats $dartPkgStats (Count-Lines $f.FullName) }
foreach ($f in $dartTestFiles) { $dartTestStats = Merge-Stats $dartTestStats (Count-Lines $f.FullName) }
foreach ($f in $dartIntegFiles) { $dartIntegStats = Merge-Stats $dartIntegStats (Count-Lines $f.FullName) }

$dartTotalStats = Merge-Stats (Merge-Stats (Merge-Stats (Merge-Stats $dartLibManualStats $dartLibGenStats) $dartPkgStats) $dartTestStats) $dartIntegStats

# ──────────────────────────────────────────────────────────────
# Grand totals
# ──────────────────────────────────────────────────────────────
$grandTotal = Merge-Stats $rustTotalStats $dartTotalStats
$grandManual = Merge-Stats $rustManualStats $dartLibManualStats

$surqlFiles = Get-ChildItem -Path "$root\rust\src" -Filter "*.surql" -Recurse -File -ErrorAction SilentlyContinue
$surqlStats = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 }
foreach ($f in $surqlFiles) { $surqlStats = Merge-Stats $surqlStats (Count-Lines $f.FullName) }

# ── Module breakdowns ──
$rustModules = @{}
$rustSrcFiles | ForEach-Object {
    $rel = $_.FullName.Replace("$root\rust\src\", "")
    $mod = if ($rel -notmatch '\\') { "(root)" } else { $rel.Split('\')[0] }
    if (-not $rustModules.ContainsKey($mod)) { $rustModules[$mod] = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 } }
    $rustModules[$mod] = Merge-Stats $rustModules[$mod] (Count-Lines $_.FullName)
}

$dartAreas = @{}
$dartLibManual | ForEach-Object {
    $rel = $_.FullName.Replace("$root\lib\", "")
    $parts = $rel.Split('\')
    $area = if ($parts.Count -ge 2) { "$($parts[0])/$($parts[1])" } else { $parts[0] }
    if (-not $dartAreas.ContainsKey($area)) { $dartAreas[$area] = @{ total = 0; code = 0; blank = 0; comment = 0; files = 0 } }
    $dartAreas[$area] = Merge-Stats $dartAreas[$area] (Count-Lines $_.FullName)
}

# ──────────────────────────────────────────────────────────────
# JSON output
# ──────────────────────────────────────────────────────────────
if ($Json) {
    $output = @{
        rust   = @{
            manual    = $rustManualStats
            generated = $rustGenStats
            tests     = $rustTestStats
            macros    = $rustMacroStats
            scripts   = $rustScriptStats
            total     = $rustTotalStats
            modules   = @{}
        }
        dart   = @{
            lib_manual    = $dartLibManualStats
            lib_generated = $dartLibGenStats
            packages      = $dartPkgStats
            tests         = $dartTestStats
            integration   = $dartIntegStats
            total         = $dartTotalStats
            areas         = @{}
        }
        surql  = $surqlStats
        grand  = @{ total = $grandTotal; manual = $grandManual }
    }
    foreach ($kv in $rustModules.GetEnumerator()) { $output.rust.modules[$kv.Key] = $kv.Value }
    foreach ($kv in $dartAreas.GetEnumerator()) { $output.dart.areas[$kv.Key] = $kv.Value }
    $output | ConvertTo-Json -Depth 5
    return
}

# ──────────────────────────────────────────────────────────────
# Pretty output
# ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ("#" * 70) -ForegroundColor Yellow
Write-Host "  MYCELIUM CODEBASE STATISTICS" -ForegroundColor Yellow
Write-Host ("#" * 70) -ForegroundColor Yellow

Print-Section "RUST SIDE" "Magenta"
Print-Row "  Manual (src/)" $rustManualStats
Print-Row "  Generated (frb)" $rustGenStats
Print-Row "  Tests" $rustTestStats
Print-Row "  Proc Macros" $rustMacroStats
Print-Row "  Scripts" $rustScriptStats
Write-Host ("  " + ("-" * 66)) -ForegroundColor DarkGray
Print-Row "  RUST TOTAL" $rustTotalStats

if ($Detailed) {
    Write-Host ""
    Write-Host "  Rust modules (manual only):" -ForegroundColor DarkGray
    foreach ($mod in ($rustModules.GetEnumerator() | Sort-Object { $_.Value.code } -Descending)) {
        Print-Row "    $($mod.Key)" $mod.Value 4 $rustManualStats
    }
}

Print-Section "DART SIDE" "Blue"
Print-Row "  lib/ (manual)" $dartLibManualStats
Print-Row "  lib/ (generated)" $dartLibGenStats
Print-Row "  packages/" $dartPkgStats
Print-Row "  tests/" $dartTestStats
Print-Row "  integration_test/" $dartIntegStats
Write-Host ("  " + ("-" * 66)) -ForegroundColor DarkGray
Print-Row "  DART TOTAL" $dartTotalStats

if ($Detailed) {
    Write-Host ""
    Write-Host "  Dart feature areas (manual only):" -ForegroundColor DarkGray
    foreach ($area in ($dartAreas.GetEnumerator() | Sort-Object { $_.Value.code } -Descending)) {
        Print-Row "    $($area.Key)" $area.Value 4 $dartLibManualStats
    }
}

if ($surqlStats.files -gt 0) {
    Print-Section "OTHER" "Green"
    Print-Row "  SurQL schema" $surqlStats
}

$allGen = Merge-Stats $rustGenStats $dartLibGenStats
$allTests = Merge-Stats $rustTestStats (Merge-Stats $dartTestStats $dartIntegStats)

Print-Section "GRAND TOTALS" "Yellow"
Print-Row "  Manual (Rust src + Dart lib)" $grandManual
Print-Row "  Generated (frb + freezed + codegen)" $allGen
Print-Row "  All tests" $allTests
Write-Host ("  " + ("-" * 66)) -ForegroundColor DarkGray
Print-Row "  EVERYTHING" $grandTotal

Write-Host ""
Write-Host "  Options: -Detailed for per-module breakdown, -Json for machine output" -ForegroundColor DarkGray
Write-Host ""
