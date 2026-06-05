# ----------------------------------------------------------------------
# Update Architecture Linter cache from the filesystem
# ----------------------------------------------------------------------
# Delegates to the Dart cache manager to scan and update architecture-cache.json.
# ----------------------------------------------------------------------

$dartScript = Join-Path $PSScriptRoot "arch_linter.dart"

# Execute cache manager check for Dart
& dart $dartScript check --dart

if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to refresh Dart Architecture Linter cache using arch_linter.dart."
  exit $LASTEXITCODE
}

# Execute cache manager check for Rust
& dart $dartScript check --rust

if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to refresh Rust Architecture Linter cache using arch_linter.dart."
  exit $LASTEXITCODE
}
