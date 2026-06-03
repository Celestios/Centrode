# ----------------------------------------------------------------------
# Update Architecture Linter cache from the filesystem
# ----------------------------------------------------------------------
# Delegates to the Dart cache manager to scan and update architecture-cache.json.
# ----------------------------------------------------------------------

$dartScript = Join-Path $PSScriptRoot "cache_manager.dart"

# Execute cache manager scan
& dart $dartScript scan

if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to refresh Architecture Linter cache using cache_manager.dart."
  exit $LASTEXITCODE
}
