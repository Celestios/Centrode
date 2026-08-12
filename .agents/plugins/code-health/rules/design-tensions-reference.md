---
activation: reference
referenced_by: code-audit-checklist.md
---

# Reference: Design Tensions & How Symmetry Mediates Them

This file is the deep-dive companion to `code-audit-checklist.md`. The checklist's 8 dimensions each sit inside a real trade-off between two legitimate principles — this doc spells out each tension, gives a Centrode-specific example of it going wrong in both directions, and explains how the Symmetry rules (`symmetrical-design` skill) resolve it. Pull this in when a finding is ambiguous and you need the worked example, not just the one-line rule.

---

## 1. DIP vs KISS

**The tension:** DIP says "depend on abstractions, not concretions." KISS says "don't create an interface for every `fn`." At the FFI boundary this is existential — every Rust struct crossing into Dart becomes a code-generated bridge. One wrong abstraction decision locks in a generation pattern forever.

**Example:** You could abstract the SurrealDB connection behind a `DatabasePort` interface on the Rust side, letting you swap SurrealDB for SQLite later. But FRB already generates a concrete bridge from `rust/src/bridge/api` to `lib/src/rust`. Adding an intermediate trait means every FFI call goes through an extra indirection layer, and every `flutter_rust_bridge.yaml` config change now has two sides to update. The KISS answer: accept the concrete bridge and only abstract if a real second backend appears.

**How Symmetry mediates:** Symmetry demands that if you abstract one side of a boundary (e.g., the database layer gets a `Repository` trait), the other side (the FFI bridge) must also use a symmetric abstraction depth — not a raw concrete call. Bidirectional API Symmetry ensures create/delete pairs share identical parameter layouts, preventing one direction from leaking internals while the other stays abstracted.

---

## 2. SRP vs Cohesion

**The tension:** SRP says a class has one reason to change. Cohesion says related logic belongs together. Pull them apart too far and you get a constellation of single-purpose micro-classes that are impossible to navigate. Leave them too close and you get a God Object.

**Example:** `NodeStore` in `lib/features/graph/store/` manages node CRUD, selection state, and spatial indexing. SRP wants three classes: `NodeRepository`, `SelectionManager`, `SpatialIndex`. But they all share the same in-memory collection and fire `ChangeNotifier` on the same mutation — splitting them means every `addNode` call requires three objects coordinating. High cohesion says keep them in one class with clear internal sections.

**How Symmetry mediates:** Structural Paradigm Symmetry — if `NodeStore` is the single orchestrator, every sibling store (`RelationStore`, `TagStore`) must follow the same structural template. You can't have one God Object and three micro-services. Template Method Symmetry ensures all stores expose the same lifecycle skeleton (`init`, `load`, `dispose`), so a developer who understands one understands all. Symmetry prevents the "one module gets bloated while others stay clean" pattern that makes refactoring impossible later.

---

## 3. DRY vs SRP

**The tension:** DRY says eliminate duplication. SRP says don't merge unrelated responsibilities. The daily refactoring dilemma: a `manageNode()` function that handles create, update, and delete violates SRP but satisfies DRY. Three separate functions violate DRY if they share boilerplate.

**Example:** The Rust persistence layer has `save_node()`, `delete_node()`, `get_node()`. They all open a SurrealDB connection, set the namespace, and run a transaction. DRY wants a `runNodeQuery()` helper that takes a closure. SRP says each function should own its full execution path. Wrong judgment compounds fast — the helper becomes a 200-line function with `match` branches.

**How Symmetry mediates:** Conceptual Mapping Symmetry — write separate, focused functions that share a symmetrical conceptual map. `saveNode()` and `deleteNode()` must have identical parameter formats, error handling, and transaction scopes — knowing one teaches you the other — but they remain separate functions. Symmetry is constrained DRY: you share structure, not implementation.

---

## 4. OCP vs KISS

**The tension:** OCP says "open for extension, closed for modification." KISS says "don't build extension points for hypothetical future needs." Every abstraction-for-extensibility decision creates interfaces, registries, and plugin patterns that a simple `if/else` would solve today.

**Example:** The canvas node rendering system could use a `NodeRenderer` interface with polymorphic dispatch — text nodes, task nodes, and image nodes each implement it. That's OCP: adding a new node type means adding a new renderer, no modification to existing code. But if you only have two node types, that's an interface + factory + registry for what's currently a `switch` statement. KISS says wait until the third type.

**How Symmetry mediates:** Symmetrical Extensibility — extension hooks must never be introduced unilaterally. If you create a polymorphic `NodeRenderer` on the frontend, you must simultaneously create a symmetric `NodeSerializer` on the persistence side. The rule prevents the common trap where one side of the system is abstract and extensible while the other is a monolithic `switch`. Either both sides stay concrete (KISS), or both sides get abstracted (OCP) — never a mismatch.

---

## 5. ISP vs Cohesion

**The tension:** ISP says don't force consumers to depend on methods they don't use. Cohesion says related methods belong in one interface. A narrow ISP creates dozens of tiny interfaces; high cohesion bundles them back together.

**Example:** `GraphService` could expose `addNode`, `deleteNode`, `addRelation`, `deleteRelation`, `findPath`, `getSubgraph`, `exportGraph`, `importGraph`. A `PathFinder` consumer only needs `findPath` and `getSubgraph` — ISP says split it. But `addNode`/`deleteNode` are tightly coupled (same data structures, same invariants) — Cohesion says keep them together.

**How Symmetry mediates:** Symmetrical Encapsulation Boundaries — sibling subsystems must expose internal state at an identical abstraction depth. If `PathFinder` gets a narrow interface (`PathQuery`), the sibling `GraphMutator` must also get a symmetric narrow interface (`GraphMutation`) — not remain a fat `GraphService`. Every consumer sees the same structural depth.

---

## 6. Immutability vs Command-Query Separation

**The tension:** Immutability makes state trivial to reason about — data never changes, so reads are safe and undo is free. CQS demands queries return data and commands mutate state. If the domain model is immutable, there are no commands, only transformations. But CQS explicitly wants a mutation pathway, which requires mutability.

**Example:** Undo/redo. `AddNodeCommand.execute()` calls `store.addNode(node)`. If `store` is immutable, `addNode` must return a new `GraphState` — every command threads state through return values instead of mutating in place. With mutability, `undo()` is just `store.deleteNode(node.id)` — simple but riskier under concurrency.

**How Symmetry mediates:** Symmetric State Projection — the structural nesting, indexing keys, and lookup complexity used to mutate state must have a directly mirrored path in the query layer, whichever choice (mutable or immutable) you make. Symmetry prevents the common pattern where the write path is clean and normalized but the read path traverses a deeply nested recursive graph — that asymmetry is where bugs hide.

---

## 7. Pure Functions vs Encapsulation

**The tension:** Pure functions (no side effects, deterministic) are testable and composable. Encapsulation hides internal state behind methods. `Node::validate(&self) -> bool` is encapsulated; `is_valid_node(node: &Node) -> bool` is pure and trivially testable — but `Node` shouldn't expose its internals publicly just to satisfy a free function.

**How Symmetry mediates:** The Robustness Principle rule — the structural rigor applied to egress data (serialization) must mirror the strictness applied to ingress data (deserialization), regardless of whether you're in a pure-function or encapsulated-method context. Prevents the two systems from diverging in what they consider valid.

---

## 8. Law of Demeter vs KISS

**The tension:** LoD says "only talk to your immediate friends" — no `a.getB().getC().doSomething()` chains. KISS says that's one readable line; forwarding methods for every deep call is boilerplate.

**Example:** `canvas.transform.worldToLocal(pointer.position)` (no LoD) vs. `canvas.worldToLocalPoint(pointer.position)` (LoD, requires a forwarding method).

**How Symmetry mediates:** Symmetrical Encapsulation Boundaries — if `CanvasController` reaches three levels deep into `Transform`, it must also reach three levels deep into `NodeRenderer` (or both get wrapped in facades). Prevents the anti-pattern where one subsystem gets a clean facade and another is accessed through a raw deep chain. LoD violations, when justified, must be applied symmetrically.

---

## 9. Composition Over Inheritance vs KISS

**The tension:** Composition is flexible but verbose (every capability explicitly wired up). Inheritance is compact but rigid (changing the base affects all subclasses).

**Example:** `TextNode`, `TaskNode`, `ImageNode extends Node` (inheritance) vs. `Node` holding a `NodeContent` interface implemented by `TextContent`/`TaskContent`/`ImageContent` (composition).

**How Symmetry mediates:** Structural Paradigm Symmetry prevents mixing approaches — if the codebase uses composition for node rendering, it must not switch to inheritance for node serialization. Template Method Symmetry further enforces that if inheritance is used, all subclasses share the same lifecycle skeleton so a new type knows exactly which methods to override.

---

## 10. DIP vs Law of Demeter

**The tension:** DIP says depend on abstractions, which often means reaching across layers through interfaces. LoD says stay local — only talk to immediate neighbors.

**Example:** Should `NodeController` hold `NodeRepository` directly (DIP, but reaches across the service layer — LoD violation), or go through `GraphService` (LoD-respecting, but an extra indirection layer that may not be needed)?

**How Symmetry mediates:** Bidirectional API Symmetry — if the FFI boundary exposes `create_node`/`delete_node` with identical parameter layouts, the internal abstraction depth must match on both sides. The controller can't reach through a clean facade on the write side while reaching deep into internals on the read side.

---

## 11. DRY vs Cohesion

**The tension:** DRY says extract shared logic into a common place. Cohesion says related logic belongs in its feature module.

**Example:** `graph/` and `workspace/` both format node timestamps, but with different rules (relative-vs-absolute logic differs). Extracting a single shared `time_formatter.dart` means the shared utility now has two code paths inside it — violating its own SRP.

**How Symmetry mediates:** Conceptual Mapping Symmetry — `graph/time_formatter.dart` and `workspace/time_formatter.dart` stay in their respective modules (cohesion), but their function signatures, parameter formats, and error-handling patterns mirror each other (symmetric DRY). Keeps cohesion without losing the conceptual alignment DRY provides.

---

## 12. Encapsulation

**The tension:** "Hidden" is a spectrum — a `pub` field, a private field with a getter, or a method that calls internal private helpers. Too much encapsulation creates getter/setter sprawl; too little exposes internals consumers come to depend on.

**Example:** `GraphNode.title` as a raw public field (convenient, KISS) vs. wrapped in a validated `node.setTitle(String value)` setter (safer, more verbose).

**How Symmetry mediates:** If `GraphNode.title` has a validated setter, `RelationNode.label` must also have one — not remain a raw public field. Serialization & Deserialization Symmetry (Case G) enforces that `fromJson`/`toJson` operate at the same encapsulation level. Prevents the pattern where some domain objects are tightly encapsulated and others wide open — that inconsistency is where architectural decay begins.

---

## How Symmetry Connects to All Twelve

Symmetry is not a 13th principle in tension with the others — it's the **mediating meta-principle** that resolves or constrains each one:

| Tension | Symmetry's Role |
|---|---|
| DIP vs KISS | Enforces symmetric abstraction depth on both sides of a boundary |
| SRP vs Cohesion | Ensures all sibling modules follow the same structural template |
| DRY vs SRP | Constrained DRY — shared structure, separate implementation |
| OCP vs KISS | Extension hooks introduced symmetrically or not at all |
| ISP vs Cohesion | All consumers see interfaces at the same abstraction depth |
| Immutability vs CQS | Read and write models structurally mirrored |
| Pure Functions vs Encapsulation | Validation rules consistent across both contexts |
| LoD vs KISS | Deep calls, when justified, applied symmetrically across modules |
| Composition vs Inheritance | All sibling subsystems use the same structural paradigm |
| DIP vs LoD | Abstraction depth and locality constraints applied consistently |
| DRY vs Cohesion | Functions stay in their modules but share symmetric signatures |
| Encapsulation | All domain objects at the same tier share the same visibility rules |

**Core insight:** inconsistency is the root cause of architectural decay. When two modules solve the same kind of problem in structurally different ways, developers (and agents) can't generalize from one to the other. Every tension above has a "right answer" that depends on context — Symmetry ensures the same context gets the same answer everywhere.
