# Run flutter and analyze widget rebuilds when done.
#
# Usage:
#   .\scripts\profile_builds.ps1              # default: flutter run on default device
#   .\scripts\profile_builds.ps1 -d windows   # specific device
#   .\scripts\profile_builds.ps1 -t 5         # only show widgets with >5 rebuilds

param(
    [string]$device = "",
    [int]$threshold = 0
)

$logFile = "build_profile.log"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "=== Build Profiler ===" -ForegroundColor Cyan
Write-Host "Logging flutter output to $logFile"
Write-Host "Interact with your app, then close it or press Ctrl+C."
Write-Host ""

# Clear old log
if (Test-Path $logFile) { Remove-Item $logFile }

# Build flutter run command
$flutterArgs = @("run")
if ($device) { $flutterArgs += @("-d", $device) }

# Run flutter, tee output to log file
# Using Start-Process to capture all output (stdout + stderr) to file
$proc = Start-Process -FilePath "flutter" -ArgumentList $flutterArgs `
    -NoNewWindow -PassThru -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.err"

# Wait for flutter to exit
$proc.WaitForExit()

# Merge stderr into log (Flutter mixes stdout/stderr)
if (Test-Path "$logFile.err") {
    $stderr = Get-Content "$logFile.err" -Raw
    if ($stderr) { Add-Content -Path $logFile -Value $stderr }
    Remove-Item "$logFile.err" -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Flutter exited. Analyzing rebuilds..." -ForegroundColor Cyan
Write-Host ""

# Run the analyzer
$analyzerArgs = @("$scriptDir\analyze_builds.py", "-f", $logFile)
if ($threshold -gt 0) { $analyzerArgs += @("-t", $threshold.ToString()) }

python @analyzerArgs

Write-Host ""
Write-Host "Full log saved to: $logFile" -ForegroundColor DarkGray
