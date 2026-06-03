<#
.SYNOPSIS
    Automated Git Commit and Release Manager script.
.DESCRIPTION
    Automates branch validation, change analysis (preparing text/json reports),
    Conventional Commit validation, version synchronization, and release tagging.
    Designed for developer use or seamless integration with agent tools.
.PARAMETER Prepare
    Runs workspace/branch verification and writes active_status.txt, active_branch.txt,
    active_diff.patch, and active_validation.json to the .git directory.
.PARAMETER CommitMsgFile
    Path to a file containing the conventional commit message to execute.
.PARAMETER StageAll
    Used with -CommitMsgFile to automatically stage all changes (git add -A) before committing.
.PARAMETER SyncVersion
    Version bump strategy ('minor', 'patch', 'build', or a custom semver string like '0.2.0').
.PARAMETER PrepareRelease
    Bumps versions, commits changes, and tags a release version ('minor' or 'patch').
#>
param(
    [switch]$Prepare,
    [string]$CommitMsgFile,
    [switch]$StageAll,
    [string]$SyncVersion,
    [string]$PrepareRelease
)

$gitDir = Join-Path $PSScriptRoot "..\.git"
if (-not (Test-Path $gitDir)) {
    Write-Error "Error: Must be run from within the Mycelium repository."
    exit 1
}

# Resolve absolute paths for outputs
$statusFile = Join-Path $gitDir "active_status.txt"
$branchFile = Join-Path $gitDir "active_branch.txt"
$diffFile = Join-Path $gitDir "active_diff.patch"
$validationFile = Join-Path $gitDir "active_validation.json"

# Scope validation configuration
$ScopeKeywords = @{
    "graph"    = @("graph", "engine", "store")
    "node"     = @("node")
    "relation" = @("relation", "edge", "port", "connection")
    "tags"     = @("tag")
    "ui"       = @("ui", "presentation", "widgets", "canvas", "zoom", "panning", "toolbar")
    "ffi"      = @("ffi", "bridge", "rust", "frb", "binding")
    "db"       = @("db", "surreal", "persistence", "store")
    "workflow" = @("workflow", "agent", "script", "hook", "hooks.json")
}

# Helper to clean up all temporary workspace validation files
function Clear-TempFiles {
    Remove-Item $statusFile -ErrorAction SilentlyContinue
    Remove-Item $branchFile -ErrorAction SilentlyContinue
    Remove-Item $diffFile -ErrorAction SilentlyContinue
    Remove-Item $validationFile -ErrorAction SilentlyContinue
}

# --- PREPARATION PHASE ---
if ($Prepare) {
    Write-Host "Analyzing workspace changes..."
    
    # 1. Gather git info
    $currentBranch = (git branch --show-current).Trim()
    $statusText = git status
    $diffText = git diff HEAD
    
    # Write raw output files for agent consumption
    $statusText | Out-File -FilePath $statusFile -Encoding utf8
    $currentBranch | Out-File -FilePath $branchFile -Encoding utf8
    $diffText | Out-File -FilePath $diffFile -Encoding utf8
    
    # 2. Validate Branch
    $branchValid = $false
    $detectedType = ""
    $detectedScope = ""
    $scopeValid = $false
    $warnings = @()
    
    if ($currentBranch -eq "main" -or $currentBranch -eq "master") {
        $warnings += "Direct commits to main/master are strictly blocked. You must use a feature/fix branch or perform a release flow."
    } else {
        # Format: <type>/<scope>-<kebab-case-description>
        if ($currentBranch -match "^(?<type>feat|fix|refactor|perf|docs|chore|test)/(?<scope>[a-z0-9\-]+)-(?<desc>[a-z0-9\-]+)$") {
            $branchValid = $true
            $detectedType = $Matches.type
            $detectedScope = $Matches.scope
            
            # Check if scope is one of the standard ones
            if ($ScopeKeywords.ContainsKey($detectedScope)) {
                $scopeValid = $true
            } else {
                $warnings += "Branch scope '$detectedScope' is not one of the standard scopes: (graph, node, relation, tags, ui, ffi, db, workflow)."
            }
        } else {
            $warnings += "Branch name '$currentBranch' does not conform to the standard format '<type>/<scope>-<kebab-case-description>'."
        }
    }
    
    # 3. Check Scope Relevance of Modified Files
    $scopeMatch = $true
    if ($branchValid -and $scopeValid) {
        $changedFiles = git diff --name-only HEAD | ForEach-Object { $_.ToLower() }
        if ($changedFiles.Count -gt 0) {
            $keywords = $ScopeKeywords[$detectedScope]
            $matchedFileCount = 0
            
            foreach ($file in $changedFiles) {
                foreach ($kw in $keywords) {
                    if ($file.Contains($kw)) {
                        $matchedFileCount++
                        break
                    }
                }
            }
            
            if ($matchedFileCount -eq 0) {
                $scopeMatch = $false
                $warnings += "Warning: None of the changed files seem to relate to the branch scope '$detectedScope'."
            }
        }
    }
    
    # Write JSON report
    $report = @{
        branchName    = $currentBranch
        branchValid   = $branchValid
        detectedType  = $detectedType
        detectedScope = $detectedScope
        scopeValid    = $scopeValid
        scopeMatch    = $scopeMatch
        warnings      = $warnings
    }
    
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $validationFile -Encoding utf8
    
    Write-Host "Workspace analysis complete. Reports written to .git/ directory:"
    Write-Host "  - .git/active_status.txt"
    Write-Host "  - .git/active_branch.txt"
    Write-Host "  - .git/active_diff.patch"
    Write-Host "  - .git/active_validation.json"
    
    if ($warnings.Count -gt 0) {
        Write-Warning "Warnings detected:"
        foreach ($w in $warnings) {
            Write-Warning "  - $w"
        }
    }
    exit 0
}

# --- COMMIT PHASE ---
if (-not [string]::IsNullOrEmpty($CommitMsgFile)) {
    if (-not (Test-Path $CommitMsgFile)) {
        Write-Error "Error: Commit message file '$CommitMsgFile' not found."
        exit 1
    }
    
    $commitMsg = (Get-Content -Path $CommitMsgFile -Raw).Trim()
    if ([string]::IsNullOrEmpty($commitMsg)) {
        Write-Error "Error: Commit message is empty."
        exit 1
    }
    
    # Read first line as header
    $header = ($commitMsg -split "`r?`n")[0]
    
    # Validate Conventional Commit format: <type>(<scope>): <subject> or <type>: <subject>
    # Types: feat|fix|refactor|perf|docs|chore|test
    $ccPattern = "^(feat|fix|refactor|perf|docs|chore|test)(\([a-z0-9\-]+\))?!?: .+$"
    if ($header -notmatch $ccPattern) {
        Write-Error "Error: Commit header '$header' does not conform to Conventional Commits format."
        Write-Error "Example: feat(ui): add zoom support"
        exit 1
    }
    
    # Branch guard checks
    $currentBranch = (git branch --show-current).Trim()
    if (($currentBranch -eq "main" -or $currentBranch -eq "master") -and $header -notmatch "^chore\(release\)") {
        Write-Error "Error: Direct commits to main/master are blocked unless they are release commits (e.g. chore(release): ...)."
        exit 1
    }
    
    # Stage all changes automatically before committing if StageAll is specified
    if ($StageAll) {
        Write-Host "Staging all changes..."
        git add -A
    }
    
    # Execute the commit
    Write-Host "Committing changes using conventional commit message..."
    git commit -F $CommitMsgFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Commit successful!"
        # Automatically clean up all temporary files
        Clear-TempFiles
        Remove-Item $CommitMsgFile -ErrorAction SilentlyContinue
    } else {
        Write-Error "Error: git commit failed."
        exit $LASTEXITCODE
    }
    exit 0
}

# --- BILINGUAL VERSION SYNC ---
if (-not [string]::IsNullOrEmpty($SyncVersion)) {
    Write-Host "Running version synchronization..."
    dart scripts/sync_version.dart $SyncVersion
    exit $LASTEXITCODE
}

# --- PREPARE TAGGED RELEASE ---
if (-not [string]::IsNullOrEmpty($PrepareRelease)) {
    if ($PrepareRelease -ne "minor" -and $PrepareRelease -ne "patch") {
        Write-Error "Error: PrepareRelease strategy must be 'minor' or 'patch'."
        exit 1
    }
    
    $currentBranch = (git branch --show-current).Trim()
    if ($currentBranch -ne "main" -and $currentBranch -ne "master") {
        Write-Warning "Typically, releases are prepared and tagged on the main/master branch. Current branch is '$currentBranch'."
    }
    
    Write-Host "Bumping version using strategy: $PrepareRelease..."
    dart scripts/sync_version.dart $PrepareRelease
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: Failed to sync versions."
        exit $LASTEXITCODE
    }
    
    # Read the new version from pubspec.yaml
    $pubspecFile = Join-Path $PSScriptRoot "..\pubspec.yaml"
    $pubspecContent = Get-Content -Path $pubspecFile -Raw
    if ($pubspecContent -match "version:\s*([^\s+]+)") {
        $newVersion = $Matches[1]
    } else {
        Write-Error "Error: Could not parse new version from pubspec.yaml."
        exit 1
    }
    
    Write-Host "Staging version-related files..."
    git add pubspec.yaml rust/Cargo.toml
    
    $releaseMsg = "chore(release): bump version to $newVersion"
    $tempMsgFile = Join-Path $gitDir "temp_release_msg.txt"
    $releaseMsg | Out-File -FilePath $tempMsgFile -Encoding utf8
    
    Write-Host "Creating release commit..."
    git commit -F $tempMsgFile
    Remove-Item $tempMsgFile -ErrorAction SilentlyContinue
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: Failed to commit release bump."
        exit $LASTEXITCODE
    }
    
    Write-Host "Tagging release with v$newVersion..."
    git tag -a "v$newVersion" -m "Release v$newVersion"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: Failed to tag release."
        exit $LASTEXITCODE
    }
    
    Write-Host "✅ Release version $newVersion prepared and tagged locally!"
    Write-Host "To complete the release, push to origin:"
    Write-Host "  git push origin main --tags"
    exit 0
}

# If no parameters passed, display help
Get-Help $PSCommandPath
