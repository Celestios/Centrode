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
    [string]$CommitMsg,
    [string[]]$Stage,
    [switch]$StageAll,
    [string]$SyncVersion,
    [string]$PrepareRelease
)

$gitDir = Join-Path $PSScriptRoot "..\.git"
if (-not (Test-Path $gitDir)) {
    Write-Error "Error: Must be run from within the Centrode repository."
    exit 1
}

# Resolve absolute paths for outputs
$diffsDir = Join-Path $gitDir "active_diffs"

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
    "model"    = @("model", "domain", "type", "struct")
}

# Helper to clean up all temporary workspace validation files
function Clear-TempFiles {
    if (Test-Path $diffsDir) {
        Remove-Item -Recurse -Force $diffsDir -ErrorAction SilentlyContinue
    }
}

# --- PREPARATION PHASE ---
if ($Prepare) {
    Write-Host "Analyzing workspace changes..."
    
    # 1. Gather git info
    $currentBranch = (git branch --show-current).Trim()
    $statusText = git status
    
    # Clean up old diffs directory and recreate it
    if (Test-Path $diffsDir) {
        Remove-Item -Recurse -Force $diffsDir -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Force -Path $diffsDir | Out-Null
    
    # Save diffs per file
    $changedFiles = git diff --name-only HEAD
    $savedDiffPaths = @()
    foreach ($file in $changedFiles) {
        if (-not [string]::IsNullOrWhiteSpace($file)) {
            $fileDiffPath = Join-Path $diffsDir ($file + ".patch")
            $parentDir = Split-Path $fileDiffPath
            if (-not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
            }
            git diff HEAD -- $file | Out-File -FilePath $fileDiffPath -Encoding utf8
            # Cleanly format the path with forward slashes for cross-platform/agent compatibility
            $savedDiffPaths += ".git/active_diffs/$($file.Replace('\', '/')).patch"
        }
    }
    
    # 2. Validate Branch
    $branchValid = $false
    $detectedType = ""
    $detectedScope = ""
    $scopeValid = $false
    $warnings = @()
    
    if ($currentBranch -eq "main" -or $currentBranch -eq "master") {
        $branchValid = $true
    } else {
        # Format: <type>/<scope>-<kebab-case-description>
        if ($currentBranch -match "^(?<type>feat|fix|refactor|perf|docs|chore|test)/(?<scope>[a-z0-9]+)-(?<desc>[a-z0-9\-]+)$") {
            $branchValid = $true
            $detectedType = $Matches.type
            $detectedScope = $Matches.scope
            
            # Check if scope is one of the standard ones
            if ($ScopeKeywords.ContainsKey($detectedScope)) {
                $scopeValid = $true
            } else {
                $warnings += "Branch scope '$detectedScope' is not one of the standard scopes: (graph, node, relation, tags, ui, ffi, db, workflow, model)."
            }
        } else {
            $warnings += "Branch name '$currentBranch' does not conform to the standard format '<type>/<scope>-<kebab-case-description>'."
        }
    }
    
    # 3. Check Scope Relevance of Modified Files
    $scopeMatch = $true
    if ($branchValid -and $scopeValid) {
        $changedFilesList = git diff --name-only HEAD | ForEach-Object { $_.ToLower() }
        if ($changedFilesList.Count -gt 0) {
            $keywords = $ScopeKeywords[$detectedScope]
            $matchedFileCount = 0
            
            foreach ($file in $changedFilesList) {
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
    
    # Build JSON report
    $report = @{
        branchName    = $currentBranch
        branchValid   = $branchValid
        detectedType  = $detectedType
        detectedScope = $detectedScope
        scopeValid    = $scopeValid
        scopeMatch    = $scopeMatch
        warnings      = $warnings
    }
    
    Write-Host "--- ACTIVE BRANCH ---"
    Write-Host $currentBranch
    Write-Host ""
    Write-Host "--- ACTIVE STATUS ---"
    Write-Host $statusText
    Write-Host ""
    Write-Host "--- ACTIVE VALIDATION ---"
    $report | ConvertTo-Json -Depth 5
    Write-Host ""
    Write-Host "--- ACTIVE DIFF FILES ---"
    foreach ($path in $savedDiffPaths) {
        Write-Host $path
    }
    Write-Host ""
    Write-Host "Workspace analysis complete. Diffs saved per file in .git/active_diffs/"
    exit 0
}

# --- COMMIT PHASE ---
Write-Host "Debug: CommitMsgFile='$CommitMsgFile'"
Write-Host "Debug: CommitMsg='$CommitMsg'"
if (-not [string]::IsNullOrEmpty($CommitMsgFile) -or -not [string]::IsNullOrEmpty($CommitMsg)) {
    $tempMsgFile = ""
    $resolvedMsg = ""
    if (-not [string]::IsNullOrEmpty($CommitMsgFile)) {
        if (-not (Test-Path $CommitMsgFile)) {
            Write-Error "Error: Commit message file '$CommitMsgFile' not found."
            exit 1
        }
        $resolvedMsg = (Get-Content -Path $CommitMsgFile -Raw).Trim()
        $tempMsgFile = $CommitMsgFile
    } else {
        $resolvedMsg = $CommitMsg.Trim()
        $tempMsgFile = Join-Path $gitDir "temp_proposed_commit_msg.txt"
        $resolvedMsg | Out-File -FilePath $tempMsgFile -Encoding utf8
    }
    
    if ([string]::IsNullOrEmpty($resolvedMsg)) {
        Write-Error "Error: Commit message is empty."
        if ([string]::IsNullOrEmpty($CommitMsgFile)) {
            Remove-Item $tempMsgFile -ErrorAction SilentlyContinue
        }
        exit 1
    }
    
    # Read first line as header
    $lines = $resolvedMsg -split "`r?`n"
    $header = $lines[0]
    
    # Validate Conventional Commit format: <type>(<scope>): <subject> or <type>: <subject>
    # Types: feat|fix|refactor|perf|docs|chore|test
    $ccPattern = "^(feat|fix|refactor|perf|docs|chore|test)(\([a-z0-9\-]+\))?!?: .+$"
    if ($header -notmatch $ccPattern) {
        Write-Error "Error: Commit header '$header' does not conform to Conventional Commits format."
        Write-Error "Example: feat(ui): add zoom support"
        if ([string]::IsNullOrEmpty($CommitMsgFile)) {
            Remove-Item $tempMsgFile -ErrorAction SilentlyContinue
        }
        exit 1
    }
    
    # Enforce commit body presence (exempting release commits)
    if ($header -notmatch "^chore\(release\)") {
        $hasBody = $false
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if (-not [string]::IsNullOrWhiteSpace($lines[$i])) {
                $hasBody = $true
                break
            }
        }
        if (-not $hasBody) {
            Write-Error "Error: Commit message must include a body describing the changes."
            if ([string]::IsNullOrEmpty($CommitMsgFile)) {
                Remove-Item $tempMsgFile -ErrorAction SilentlyContinue
            }
            exit 1
        }
    }
    
    # Branch guard checks
    $currentBranch = (git branch --show-current).Trim()
    if (($currentBranch -eq "main" -or $currentBranch -eq "master") -and $header -notmatch "^chore\(release\)") {
        Write-Error "Error: Direct commits to main/master are blocked unless they are release commits (e.g. chore(release): ...)."
        if ([string]::IsNullOrEmpty($CommitMsgFile)) {
            Remove-Item $tempMsgFile -ErrorAction SilentlyContinue
        }
        exit 1
    }
    
    # Stage specified files or patterns
    if ($Stage -and $Stage.Count -gt 0) {
        foreach ($pattern in $Stage) {
            Write-Host "Staging pattern: $pattern"
            git add $pattern
        }
    }
    # Stage all changes automatically before committing if StageAll is specified
    elseif ($StageAll) {
        Write-Host "Staging all changes..."
        git add -A
    }
    
    # Execute the commit
    Write-Host "Committing changes using conventional commit message..."
    git commit -F $tempMsgFile
    
    $commitExitCode = $LASTEXITCODE
    if ([string]::IsNullOrEmpty($CommitMsgFile)) {
        Remove-Item $tempMsgFile -ErrorAction SilentlyContinue
    }
    
    if ($commitExitCode -eq 0) {
        Write-Host "✅ Commit successful!"
        # Automatically clean up all temporary files
        Clear-TempFiles
        if (-not [string]::IsNullOrEmpty($CommitMsgFile)) {
            Remove-Item $CommitMsgFile -ErrorAction SilentlyContinue
        }
    } else {
        Write-Error "Error: git commit failed."
        exit $commitExitCode
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
