---
activation: always_on
---

# Rule: Code Audit Checklist

Each file in the audit batch must be evaluated against all 8 dimensions below. Read the full source code via `view_file` — do not rely on CLI cache tools alone.

Each dimension sits inside a real trade-off between two legitimate principles (e.g. SRP vs. Cohesion, DRY vs. SRP) — flagging every deviation as a violation produces false positives. Use the **Tension** to recognize the trade-off, the **Watch for** line as the concrete smell, and the **Symmetry check** as the tie-breaker: a choice that's internally reasonable is still a violation if a structural sibling made the opposite choice for no documented reason. Full worked examples for each tension live in `design-tensions-reference.md` — pull it in when a finding is ambiguous.

## Dimensions

1. **SRP (Single Responsibility)**: Does the class have a single, clear responsibility? Check for mixed tiers, mixed levels of abstraction, or multiple roles.
   - *Tension:* SRP vs. Cohesion — over-splitting produces a constellation of micro-classes; under-splitting produces a God Object.
   - *Watch for:* a store/manager class mixing CRUD, selection state, and indexing purely because they share one mutation trigger.
   - *Symmetry check:* if this class is the "single orchestrator" for its concern, do sibling classes follow the identical lifecycle skeleton (`init`/`load`/`dispose`)? One bloated outlier among otherwise-clean siblings is the real signal — not size alone.

2. **OCP (Open/Closed)**: Can behavior be extended without modification? Check for hardcoded mode switchers, conditional chains, and lack of injection.
   - *Tension:* OCP vs. KISS — building interfaces/registries for hypothetical future cases is as much a smell as a `switch` statement that keeps growing.
   - *Watch for:* hardcoded mode switches or growing if/else chains with no injection point.
   - *Symmetry check:* if one side of a boundary (e.g. frontend renderers) is already polymorphic/strategy-based, does the paired side (e.g. backend serialization) use the same abstraction depth? Don't flag a concrete `switch` unless its structural sibling is already abstracted.

3. **LSP & ISP (Substitution & Segregation)**: Do subclasses honor parent contracts without throwing `UnimplementedError`? Are they forced to implement fat interfaces?
   - *Tension:* ISP vs. Cohesion — narrow role-specific interfaces vs. one cohesive interface for tightly-coupled operations.
   - *Watch for:* subclasses throwing `UnimplementedError`; a consumer depending on an interface several times larger than what it actually calls.
   - *Symmetry check:* if one consumer gets a narrow, focused interface, do sibling consumers doing analogous work get an equally narrow one — or are they stuck on the fat interface "because it was easier"?

4. **DIP (Dependency Inversion)**: Does it depend on abstractions or concretions? Check for hardcoded class instantiations inside the code.
   - *Tension:* DIP vs. KISS and DIP vs. Law of Demeter — abstracting every boundary creates indirection for its own sake; not abstracting locks in concrete dependencies, especially painful at the FFI boundary.
   - *Watch for:* hardcoded instantiation where an injected abstraction belongs; a deep call chain (`a.getB().getC().doThing()`) on one side of a paired boundary but a clean facade on the other.
   - *Symmetry check:* Bidirectional API Symmetry — if the write path exposes a clean facade, does the read path reach the same abstraction depth? Only abstract a boundary when a second real implementation exists, and abstract both sides together, never one.

5. **DRY (Don't Repeat Yourself)**: Is there structural or algorithmic duplication across sibling files? Use arch-mcp's `query` tool to cross-reference but read the code to verify.
   - *Tension:* DRY vs. SRP and DRY vs. Cohesion — a shared multi-purpose helper fixes duplication but merges unrelated responsibilities; extracting shared logic into `shared/` fixes duplication but can strand feature-specific rules or import a second SRP violation into the new helper.
   - *Watch for:* near-identical CRUD functions (`save`/`delete`/`get`) with divergent parameter formats or error handling; or a "generic" helper that grew an internal `match`/`switch` to cover cases that used to be separate functions; or the same conceptual decision (e.g., "filter nodes by scope") applied across N files — even if each instance looks syntactically different.
   - *Symmetry check:* Conceptual Mapping Symmetry (constrained DRY) — sibling functions/modules should share structure (signatures, error handling, transaction scope) without merging implementation. Confirm via arch-mcp `query` for duplicate method names across directories before recommending an extraction.

6. **Pattern Fitness**: Does the actual class structure match its designated design pattern? Check if strategies/commands are clean.
   - *Tension:* Composition vs. Inheritance — mixing both approaches for the same kind of problem breaks predictability even when either choice alone would be fine.
   - *Watch for:* a "strategy" that isn't actually swappable at runtime; a "command" without a real inverse; an inheritance hierarchy where subclasses override orchestration order, not just steps.
   - *Symmetry check:* Meta-Level Behavioral Symmetry — once a pattern is chosen for a domain, every new addition to that domain, and its structural sibling domain, must follow the identical blueprint (same lifecycle hooks, same registration mechanism, same extension points).

7. **Symmetry**: Do sibling classes in the same directory follow the same structural blueprint?
   - *Role:* this dimension is the mediator for the other seven — it's the check for whether the *same kind of problem* is solved the *same way* everywhere in the codebase.
   - *Watch for:* one sibling class refactored recently while its structural counterpart wasn't (Essential Symmetry drift); or forced symmetry imposed between two things that only coincidentally look alike (Coincidental Symmetry), tightly coupling unrelated domains.
   - *Symmetry check:* run the full `symmetry-checker` skill checklist — confirm siblings live in the same architectural space, share the same abstraction layer, and that any intentional deviation is explicitly commented with rationale and a bounded scope (Controlled Symmetry Breaking).

8. **Complexity**: Check line counts (>500) and API counts (>15) as indicators of bloat.
   - *Note:* rarely a standalone violation — usually the downstream symptom of one of the tensions above being resolved asymmetrically (one sibling kept simple, another over-engineered into a dispatcher).
   - *Watch for:* line/API counts over threshold, but more importantly whether the bloat is evenly distributed across siblings (expected, structural) or concentrated in a single outlier (asymmetric — investigate why that one grew while its siblings didn't).

## Rules to Enforce

- Zero-Trust Checklist from `architecture-auditor` skill.
- Symmetry rules from `symmetry-checker` skill.
- `rust-style-guide.md` for Rust core components.
- `abstraction-levels.md` (includes cross-layer mutation boundaries) and the `symmetrical-design` skill for Flutter/Dart components.
- `design-tensions-reference.md` for the full worked example and Symmetry-mediation logic behind each dimension above — use it to resolve ambiguous findings, not as a first-pass reference for every file.

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
- **Tension** (which trade-off this finding sits inside, if applicable — e.g. "DRY vs SRP")
- **Severity**: 🔴 Critical / 🟡 Warning / 🔵 Info
- **Confidence**: High / Medium / Low
  - *High*: verified via import scan + method count + actual code reading
  - *Medium*: structural similarity detected but not fully verified
  - *Low*: heuristic or graph-based detection only
- **Line range** if applicable
- **Concise violation description** (report broken contract; do NOT propose remediation fixes during audit phase)
- **What would confirm this** (for Medium/Low confidence): the additional check needed to upgrade confidence
