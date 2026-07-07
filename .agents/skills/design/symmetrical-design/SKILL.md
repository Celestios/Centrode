---
name: symmetrical-design
description: Activate this skill when designing, implementing, or auditing symmetric code structures, undo/redo commands, folder blueprints, API boundaries, or matching testing suites.
---

# Skill: Symmetrical Design (The Primary Principle)

Symmetrical design is the absolute architectural law of the workspace. It extends beyond naming conventions to ensure that the code's conceptual map, structural paradigms, lifecycles, and interfaces are structurally aligned, allowing developers and agents to immediately understand unknown parts of the system by studying their symmetrical counterparts.

---

## Conceptual Invariants

### 1. Structural Paradigm Symmetry (Local vs. Global Handlers)
- **Principle**: Avoid mixing local, ad-hoc inline handlers with global orchestration systems. If a subsystem uses a centralized registry or global coordinator, no individual component should bypass it by implementing local, inline logic.
- **Rule**: If a group of widgets routes user gestures to a global coordinator, a new widget with slightly different gesture needs must not implement inline, localized gesture handling.
- **Remediation**: If the existing global coordinator cannot support the new widget due to logical limitations, do not write a localized helper. Instead, identify the future potential and create a second global coordinator that is similar to the original but specialized. This preserves DRY, SRP, and structural symmetry.

### 2. Conceptual Mapping & Functional Separation (Symmetry as Constrained DRY)
- **Principle**: DRY (Don't Repeat Yourself) pushes for unification, but is bounded by SRP (Single Responsibility). To balance both, implement **Symmetric Separation**. Rather than merging distinct operations into a single generic, multi-purpose function (which violates SRP), write separate, focused functions that share a symmetrical conceptual map.
- **Rule**: Do not create a single function like `manageNode()` to handle creation, updates, and deletions just to satisfy DRY. This violates SRP.
- **Remediation**: Write distinct functions (e.g., `saveNode()` and `deleteNode()`). They separate logical execution paths but maintain a symmetrical conceptual map. Their parameter formats, signatures, error handling, and transaction scopes must mirror each other. Knowing one function immediately instructs you about the internal workings of the other.

### 3. Logical Branching Symmetry (If-Else Balance)
- **Principle**: Sibling conditional branches or case logic should exhibit symmetrical complexity, nesting depth, and vocabulary abstractions.
- **Rule**: If a conditional branch `if (isValid)` executes a sequence of high-level coordinator calls, the corresponding `else` branch must be written with the same level of abstraction. Never pair a high-level facade call in the `if` block with low-level inline math or byte manipulation in the `else` block. Both branches should share the same structural skeleton and cognitive complexity.

### 4. Template Method Symmetry (Lifecycle/Skeleton Parity)
- **Principle**: A family of sibling classes or subclasses must inherit the same structural skeleton or lifecycle sequence, even if their specific step implementations differ.
- **Rule**: Enforce lifecycle symmetry across components. Base abstract classes must define the orchestration pipeline (e.g., `initialize()`, `validate()`, `execute()`, `dispose()`) ensuring subclasses only override specific, focused steps without altering the overall execution template or order.

### 5. Controlled Symmetry Breaking (Architectural Exceptions)
- **Principle**: High-quality software requires controlled symmetry breaking to solve edge cases or performance constraints without destroying the overall structural predictability.
- **Rule**: If a component must deviate from the symmetrical standard (e.g. bypassing FFI serialization for dynamic buffers, or a unique widget requiring direct canvas rendering), you must explicitly isolate and document the break. Use comments detailing:
  - The technical rationale for breaking the symmetry.
  - The strict boundary of the exception (to prevent asymmetrical logic from bleeding into other components).

### 6. Robustness Principle vs. Fail-Fast (Symmetric Validation Boundaries)
- **Principle**: Postel’s Law ("Be liberal in what you accept, conservative in what you send") conflicts with the Fail-Fast principle, which demands immediate failure on invalid state. To reconcile these across system boundaries (e.g., FFI edges or Network I/O), implement **Symmetric Validation Boundaries**. The structural rigor, type-strictness, and edge-case handling applied to egress data (serialization) must perfectly mirror the strictness applied to ingress data (deserialization).
- **Rule**: Do not design a tolerant, schema-less parsing fallback for incoming data if your internal application core and outgoing data models demand strict invariant compliance.
- **Remediation**: If an invalid or partial payload is intercepted at an ingress boundary, do not attempt an asymmetrical inline patching or guessing mechanism. Reject it using the same structural data validation rules that your own serialization layer guarantees to outward-facing components.

### 7. Command-Query Separation vs. Cache Consistency (Symmetric State Projection)
- **Principle**: Command-Query Separation (CQS) isolates mutation pathways from read pathways, yet real-time interfaces demand low latency, which frequently introduces structural divergence between how state is written and read. To maintain system comprehensibility, enforce **Symmetric State Projection**. The structural nesting, indexing keys, and lookup complexities used to mutate state must have a direct, structurally mirrored path in the query layer.
- **Rule**: Do not optimize a write path to update a flat, relational identifier index while forcing the read path to traverse a deeply nested, recursive graph tree to extract the same data.
- **Remediation**: Align the structural models of your command handlers and query models. If a mutation acts upon a normalized collection, the view state must read from a symmetrically normalized projector. Optimization must be achieved via symmetrical denormalization or caching layers on both sides rather than asymmetric data-structure layouts.

### 8. Open-Closed Principle vs. YAGNI (Symmetrical Extensibility)
- **Principle**: The Open-Closed Principle (OCP) drives developers toward abstract, polymorphic architectures open for expansion, while YAGNI (You Aren't Gonna Need It) demands concrete, minimal implementations to avoid over-engineering. To balance these forces, apply **Symmetrical Extensibility**. Extensibility hooks (interfaces, generics, plugins) must never be introduced unilaterally. An abstraction for expansion on one side of a subsystem requires a mandatory, mirrored abstraction on its sibling or inverse subsystem.
- **Rule**: Do not create a highly modular, polymorphic strategy pattern for frontend visual renderers while leaving the backend serialization or data-persistence pipeline as a single monolithic, concrete `switch` statement over enum types.
- **Remediation**: Maintain both the frontend and backend pipelines as flat, concrete implementations until extension is strictly necessary. When the need arises, abstract both sides symmetrically: a new visual component type must correspond to a new serialized component strategy, sharing identical extension interfaces, registration lifecycles, and structural boundaries.

### 9. Law of Demeter vs. High Cohesion (Symmetrical Encapsulation Boundaries)
- **Principle**: The Law of Demeter minimizes coupling by restricting a component's knowledge of internal structures, whereas High Cohesion often groups nested structures together for localized operations. To prevent arbitrary encapsulation boundaries across the system, enforce **Symmetrical Encapsulation Boundaries**. Sibling subsystems or layer boundaries must expose internal state at an identical depth of abstraction.
- **Rule**: A controller must not communicate with Subsystem A through a high-level facade interface while reaching deep into the internal collections and fields of Subsystem B to achieve a coordinated task.
- **Remediation**: Re-encapsulate or expose the internals of the uneven subsystems so that the controller interfaces with both at the same structural depth. If Subsystem A uses a facade pattern, Subsystem B must implement a symmetrical facade pattern, masking its low-level internals to the same degree.

---

## Structural Symmetry Cases

### Case A: Folder & File Parity
- **Rule**: Sibling features must use identical directory structures, naming schemes, and interface implementations.
- **Example**:
  - UI: `lib/features/graph/ui/canvas/nodes/info_node_widget.dart` -> Symmetrical: `lib/features/graph/ui/canvas/nodes/task_node_widget.dart`
  - Controller: `lib/features/graph/presentation/nodes/info_node_controller.dart` -> Symmetrical: `lib/features/graph/presentation/nodes/task_node_controller.dart`

### Case B: Bidirectional API & Interface Symmetry
- **Rule**: Any boundary interface (such as a database client, network service, or FFI bridge) must maintain complete bidirectional balance. If an interface exposes a way to serialize or write data, it must expose the symmetrical inverse way to deserialize or clean up data.
- **Example**: `create_node()`, `update_node()`, `delete_node()`, `get_node()`. If an API provides an endpoint to open a socket or register an event listener, it must provide a symmetrical endpoint to close the socket or unregister the listener with identical parameter layouts.

### Case C: Inverse Command Patterns (Undo/Redo)
- **Rule**: Every mutation command must implement a perfect inverse operation to support undo/redo.
- **Example**:
  ```dart
  class AddNodeCommand implements Command {
    final GraphStore store;
    final GraphNode node;
    AddNodeCommand(this.store, this.node);
    @override void execute() => store.addNode(node);
    @override void undo() => store.deleteNode(node.id);
  }
  ```

### Case D: FSM Lifecycle Symmetry
- **Rule**: Every state transition in a finite state machine must have a symmetrical counterpart.
- **Example**: Transitioning from `CanvasIdleState` to `NodeDraggingState` upon `PointerDown` must have a corresponding transition back to `CanvasIdleState` upon `PointerUp` or `PointerCancel`. If entering a state modifies global configurations or registers system-wide listeners, exiting the state must cleanly revert those changes and unregister those listeners.

### Case E: Telemetry Boundaries (Start/End)
- **Rule**: For every logged start event in telemetry tracking, there must be a matching end event.
- **Example**: Log `NodeDragStarted(nodeId, time)` symmetrically matched by `NodeDragEnded(nodeId, time, finalPosition)`.

### Case F: Testing Parity (Source / Test Files)
- **Rule**: For every Tier 2 and Tier 3 functional file, there must be a corresponding test file mirroring the folder path and testing scenarios.
- **Example**: `lib/features/graph/store/node_store.dart` -> `test/features/graph/store/node_store_test.dart`.

### Case G: Serialization & Deserialization Symmetry
- **Rule**: Models must parse and map symmetrically. Keys extracted in deserialization must be mirrored in serialization.
- **Example**: If `fromJson` extracts `x` and `y` coordinates, `toJson` must output `x` and `y` coordinates with the same types and keys.

### Case H: Dependency Injection & Mocking Parity
- **Rule**: If a repository class has a mock implementation for tests (e.g. `MockNodeRepository`), the mock class must implement the exact same abstract interface as the production repository.

### Case I: CRUD Naming Conventions
- **Rule**: Always use matching prefixes across different layers and languages for database/store operations.
- **Example**:
  - Dart side: `saveNode()`, `deleteNode()`, `getNode()`, `listNodes()`.
  - Rust side: `save_node()`, `delete_node()`, `get_node()`, `list_nodes()`.
