## Pitfall 1: The "Chicken-and-Egg" Layout Paradox (State vs. Render Lifecycle)

**The Mistake:** Attempting to enforce mathematically pure "Strict Visibility" before the framework had completed its physical layout passes.
**The Reality:** In Flutter, a widget's size is intrinsically tied to its render phase. Our Spatial Hash Grid relies on bounding boxes (`Size` and `Offset`). If we tell the `NodeLayer` to *only* render items in the `visibleNodeIds` set, and that set starts empty at $T=0$, nothing renders. If nothing renders, sizes remain `Size.zero`. If sizes are zero, the spatial hash remains empty, creating an infinite deadlock.
**The Fix:** We must explicitly design "T=0 Bypasses." Mathematical culling can only take over *after* the initial render pass has seeded the physical dimensions into the spatial index.

## Pitfall 2: Coordinate Space Dissonance (Screen vs. Canvas Space)

**The Mistake:** Mixing global screen metrics (`MediaQuery.of(context).size.width`) inside a transformed, infinite canvas (`InteractiveViewer`), and then attempting to hit-test those elements using purely local canvas coordinates.
**The Reality:** The UI layer (`OverlayLayer`) was drawing the multi-selection toolbar using Screen Space, but the physics engine (`CanvasIdle` FSM) was calculating hits using Canvas Space. Furthermore, the FSM was wired to the wrong data pipe (`toolbarOffsetNotifier` instead of `multiToolbarOffsetNotifier`).
**The Fix:** **Absolute Geometric Alignment.** If an interaction occurs inside the canvas, every visual element it interacts with must be calculated using exact Canvas Space bounding boxes. The physics engine and the rendering engine must share the exact same mathematical origin and data routers.

## Pitfall 3: Event Starvation & Framework Assumptions (Input Telemetry)

**The Mistake:** Assuming desktop pointer semantics (mouse movement) mapped cleanly to touch/drag semantics.
**The Reality:** We relied on `onPointerMove` to drive the relation drawing tool. However, Flutter's gesture arena drops `PointerMoveEvent` entirely unless a mouse button is actively held down. By failing to explicitly listen to `PointerHoverEvent`, we starved the FSM of the telemetry required to draw a "sticky" relation line.
**The Fix:** **Opt-In Polymorphic Telemetry.** We bound `PointerHoverEvent` at the root canvas, but to protect UI thread performance (preventing O(N) calculations 120 times a second), we implemented a base `handlePointerHover` that returns O(1) fast-fails, allowing only specific FSM states (like `RelationDrawing`) to consume the expensive event.

## Pitfall 4: Asymmetric State Fallbacks (UI vs. Physics Engine)

**The Mistake:** Applying a T=0 fallback to the UI layer without mirroring it in the physics layer.
**The Reality:** When we restored the $T=0$ bypass in `NodeLayer` so nodes would render before a pan/zoom occurred, we forgot to update the `MarqueeSelecting` state. The UI rendered the nodes, but the FSM's marquee tool was still querying the empty `visibleNodeIds` set, resulting in zero intersections until a zoom forced a spatial query.
**The Fix:** **Symmetrical State.** If the rendering engine has a fallback for uninitialized or "dirty" state, the physics/interaction engine must share that exact same fallback logic.

---

## Core Maxims for Future Development

1. **Never mix Screen Space and Canvas Space.**
2. **The Render pipeline precedes the Spatial index.** (Allow initial renders).
3. **If a State Machine cannot see an event, check the Framework's event dropping rules.**
4. **Symmetry between UI loops and FSM loops is non-negotiable.**

---

## Pitfall 5: The "Infinite Zero" Clipping Trap (Layout Constraints vs. Infinity)

**The Mistake:** Attempting to achieve a truly infinite canvas origin by shrinking the root `SizedBox` dimensions to `0x0`.
**The Reality:** In Flutter, a `Stack` defaults to `Clip.hardEdge`. A `0x0` parent strictly clips all children out of visual existence, regardless of their absolute coordinates. Furthermore, a `CustomPainter` relies on its layout bounds; a `0x0` layout forces the mathematical rendering loop to compute a visible area of zero, drawing absolutely nothing.
**The Fix:** **Provide a Mathematical Reference Plane and Disable Clipping.** You must maintain a large initial constraint size (`AppConfig.graph.canvas.initialSize`) as a stage, explicitly set `clipBehavior: Clip.none` on all underlying `Stack` layers, and completely decouple math-driven painters from layout constraints by passing the absolute viewport dimensions directly into the painter.

## Pitfall 6: Asymmetric Telemetry (The "Deaf" UI)

**The Mistake:** Building a perfect, $O(1)$ telemetry and event pipeline in the Rust core but leaving the Dart UI disconnected during rapid iteration.
**The Reality:** The Rust core accurately calculated boundaries, executed database updates, and broadcasted state changes to the FFI event bus. However, because the Dart presentation layer's stream listener was commented out, the UI remained permanently frozen, creating the illusion of a backend failure when the pipeline was actually executing flawlessly.
**The Fix:** **End-to-End Pipeline Verification.** A pipeline is not complete until the Dart reactive layer (e.g., `ValueNotifier`) is actively consuming, mapping, and logging the FFI union events. Never trust the UI as the sole indicator of backend health; always verify the FFI bridge logs.

## Pitfall 7: Multi-Statement Query Indexing (SurrealDB Rust SDK)

**The Mistake:** Assuming SurrealDB's Rust SDK automatically aggregates results from multi-statement queries into a single response block at index `0`.
**The Reality:** The SDK processes statements strictly sequentially. In a query structured as `LET $xs = ...; LET $ys = ...; RETURN { ... };`, calling `res.take(0)` fetches the empty/null result of the very first `LET` assignment. This caused silent `serde` deserialization failures in Rust, forcing the application into a permanent fallback state despite perfect SurrealQL syntax.
**The Fix:** **Strict Index Targeting.** You must explicitly target the index of the exact `RETURN` or `SELECT` statement in your SurrealQL script (e.g., `res.take(2)` for the third statement). Additionally, always use `SELECT VALUE` when extracting arrays for mathematical aggregation to prevent `NONE` values from silently failing `math::min()` or `math::max()` functions.

## Pitfall 8: Geometric Dissonance & The "Zero-Node Collapse" (InteractiveViewer Math)

**The Mistake:** Equating the pure mathematical bounding box of the graph directly to the physical panning limits of the camera, and inflating the `InteractiveViewer`'s base child to try and prevent clipping.
**The Reality:** `InteractiveViewer` mathematically *adds* its `boundaryMargin` to the dimensions of its child. If the base child is large (e.g., `1000x1000`), it permanently skews the absolute coordinate math. Furthermore, if the mathematical boundary relies purely on node positions, an empty graph or a graph with only 1 node causes a "Zero-Node Collapse." The margin shrinks to near `0x0`, violently trapping the physical camera in a panning box smaller than the user's screen.
**The Fix:** **Geometric Decoupling & The Minimum Viable Pan (MVP).** 1. Force the `InteractiveViewer`'s stage child to strictly `1x1` so the `boundaryMargin` becomes the sole mathematical dictator of coordinate space. 
2. Use layout constraints to dynamically clamp the boundary margin against the physical screen size (`math.max(viewport.width, absolute_boundary)`). This guarantees the user always has at least one full screen-width of panning space to work with, regardless of how small the actual data graph is.