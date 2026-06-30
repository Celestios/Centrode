---
activation: always_on
---

# Rule: Code Audit Checklist

Each file in the audit batch must be evaluated against all 8 dimensions below. Read the full source code via `view_file` — do not rely on CLI cache tools alone.

## Dimensions

1. **SRP (Single Responsibility)**: Does the class have a single, clear responsibility? Check for mixed tiers, mixed levels of abstraction, or multiple roles.
2. **OCP (Open/Closed)**: Can behavior be extended without modification? Check for hardcoded mode switchers, conditional chains, and lack of injection.
3. **LSP & ISP (Substitution & Segregation)**: Do subclasses honor parent contracts without throwing `UnimplementedError`? Are they forced to implement fat interfaces?
4. **DIP (Dependency Inversion)**: Does it depend on abstractions or concretions? Check for hardcoded class instantiations inside the code.
5. **DRY (Don't Repeat Yourself)**: Is there structural or algorithmic duplication across sibling files? Use arch-mcp's `query` tool to cross-reference but read the code to verify.
6. **Pattern Fitness**: Does the actual class structure match its designated design pattern? Check if strategies/commands are clean.
7. **Symmetry**: Do sibling classes in the same directory follow the same structural blueprint?
8. **Complexity**: Check line counts (>500) and API counts (>15) as indicators of bloat.

## Rules to Enforce

- Zero-Trust Checklist from `architecture-auditor` skill.
- Symmetry rules from `symmetry-checker` skill.
- `rust-style-guide.md` for Rust core components.
- `abstraction-levels.md`, `no-cross-layer-mutation.md`, and `symmetry-invariants.md` for Flutter/Dart components.

## Dead Code Verification

If any dead code candidates are included in the batch, verify by:
- Reading the symbol's implementation to confirm no side effects make it "live"
- Checking for dynamic invocations (e.g., `Function.apply`, string-based method lookup)
- Confirming the symbol is not a public API consumed by external packages

Report each dead code candidate with:
- Symbol name and file path
- Confidence tier (High/Medium/Low)
- Evidence: caller count, test presence, entry-point status
- Recommendation: Remove / Deprecate / Investigate Further

## Finding Format

For each finding, report:
- **File path** (clickable link)
- **Principle violated** (e.g., SRP, DRY, Open/Closed, Layer Leak, Cross-Layer Mutation)
- **Severity**: 🔴 Critical / 🟡 Warning / 🔵 Info
- **Confidence**: High / Medium / Low
  - *High*: verified via import scan + method count + actual code reading
  - *Medium*: structural similarity detected but not fully verified
  - *Low*: heuristic or graph-based detection only
- **Line range** if applicable
- **Concrete remediation suggestion**
- **What would confirm this** (for Medium/Low confidence): the additional check needed to upgrade confidence
