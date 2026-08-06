<#
.SYNOPSIS
    Writes per-file diffs for a commit range, optionally excluding specific commits.
.DESCRIPTION
    Generates .patch files in .git/active_diffs/ for each changed file across a commit range,
    excluding specified commits. Follows the same output pattern as git-commit.ps1 -Prepare.
.PARAMETER FromCommit
    Starting commit (inclusive).
.PARAMETER ToCommit
    Ending commit (inclusive).
.PARAMETER ExcludeCommits
    Commits to exclude from the diff (e.g. a rename-only commit).
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$FromCommit,
    [Parameter(Mandatory=$true)]
    [string]$ToCommit,
    [string[]]$ExcludeCommits
)

$gitDir = Join-Path $PSScriptRoot "..\.git"
if (-not (Test-Path $gitDir)) {
    Write-Error "Error: Must be run from within the Centrode repository."
    exit 1
}

$diffsDir = Join-Path $gitDir "active_diffs"
if (Test-Path $diffsDir) {
    Remove-Item -Recurse -Force $diffsDir -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $diffsDir | Out-Null

# Build exclusion flags
$excludeArgs = @()
foreach ($ex in $ExcludeCommits) {
    $excludeArgs += "^$ex"
}

# Get changed files from both ranges
$range1End = "$FromCommit"
if ($ExcludeCommits.Count -gt 0) {
    $range1End = "$($ExcludeCommits[0])^"
}

$filesRange1 = @()
$filesRange2 = @()

if ($ExcludeCommits.Count -gt 0) {
    $filesRange1 = git diff --name-only $FromCommit $range1End 2>$null
    $filesRange2 = git diff --name-only $ExcludeCommits[0] $ToCommit 2>$null
} else {
    $filesRange1 = git diff --name-only $FromCommit $ToCommit 2>$null
}

# Union of all changed files
$allFiles = @()
$allFiles += $filesRange1
$allFiles += $filesRange2
$uniqueFiles = $allFiles | Sort-Object -Unique

$savedDiffPaths = @()
foreach ($file in $uniqueFiles) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    
    $fileDiffPath = Join-Path $diffsDir ($file + ".patch")
    $parentDir = Split-Path $fileDiffPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }
    
    # Build combined diff for this file across both ranges
    $patchContent = ""
    
    if ($ExcludeCommits.Count -gt 0) {
        # Range 1: from..exclude^
        $patch1 = git diff $FromCommit $range1End -- $file 2>$null
        if ($patch1) { $patchContent += $patch1 }
        
        # Range 2: exclude..to
        $patch2 = git diff $ExcludeCommits[0] $ToCommit -- $file 2>$null
        if ($patch2) { $patchContent += "`n" + $patch2 }
    } else {
        $patchContent = git diff $FromCommit $ToCommit -- $file 2>$null
    }
    
    if ($patchContent) {
        $patchContent | Out-File -FilePath $fileDiffPath -Encoding utf8
        $savedDiffPaths += ".git/active_diffs/$($file.Replace('\', '/')).patch"
    }
}

# Summary
$totalFiles = $savedDiffPaths.Count
$beforeCount = ($filesRange1 | Where-Object { $_ -and $_.Trim() }).Count
$afterCount = ($filesRange2 | Where-Object { $_ -and $_.Trim() }).Count

Write-Host "--- DIFF RANGE ---"
Write-Host "From: $FromCommit"
Write-Host "To:   $ToCommit"
if ($ExcludeCommits.Count -gt 0) {
    Write-Host "Excluding: $($ExcludeCommits -join ', ')"
}
Write-Host ""
Write-Host "--- STATS ---"
Write-Host "Files in range 1 (before exclude): $beforeCount"
Write-Host "Files in range 2 (after exclude):  $afterCount"
Write-Host "Total unique files with diffs:      $totalFiles"
Write-Host ""
Write-Host "--- PATCH FILES ---"
foreach ($path in $savedDiffPaths) {
    Write-Host $path
}
Write-Host ""
Write-Host "Diffs saved per file in .git/active_diffs/"
