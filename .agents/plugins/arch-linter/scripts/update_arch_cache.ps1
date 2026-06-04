# ----------------------------------------------------------------------
# Update Architecture Linter cache from the filesystem
# ----------------------------------------------------------------------
# Delegates to the Dart cache manager to scan and update architecture-cache.json.
# ----------------------------------------------------------------------

$dartScript = Join-Path $PSScriptRoot "cache_manager.dart"

# Execute cache manager scan for Dart
& dart $dartScript scan --dart

if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to refresh Dart Architecture Linter cache using cache_manager.dart."
  exit $LASTEXITCODE
}

# Execute cache manager scan for Rust
& dart $dartScript scan --rust

if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to refresh Rust Architecture Linter cache using cache_manager.dart."
  exit $LASTEXITCODE
}
