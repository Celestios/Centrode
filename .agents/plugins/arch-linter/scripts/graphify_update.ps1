# ----------------------------------------------------------------------
# Incremental Graphify update for SRP‑audit workflow
# ----------------------------------------------------------------------
# This script is invoked by the SRP‑audit workflow before the cache refresh.
# It runs the deterministic AST‑only delta update (`graphify . --update`).
# No LLM calls are performed, so the operation is token‑free and fast.
# ----------------------------------------------------------------------

# Run the incremental update on the repository root
graphify . --update

if ($LASTEXITCODE -ne 0) {
  Write-Error "Graphify incremental update failed (exit code $LASTEXITCODE)."
  exit $LASTEXITCODE
}

Write-Host "✅ Graphify incremental update completed successfully."
