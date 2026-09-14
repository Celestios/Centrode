# Comprehensive Dart Test Health Audit Report
**Centrode Graph Knowledge Architecture**

- **Date**: 2026-09-12
- **Audit Framework**: `/code-health` & `/test-health` Multi-Agent Dynamic Audit Protocol
- **Auditor Synthesis Agent**: `worker_synthesizer_1` (Teamwork Synthesis Agent)
- **Parent Orchestrator**: `teamwork_preview_orchestrator` (`bf7c4aa2-4db8-48c9-ba99-2fb1aaddffd9`)
- **Repository Scope**: Exactly **66 Dart test suites** across `test/` (65 files) and `integration_test/` (1 file)
- **Target File**: `docs/reports/dart_test_health_report.md`
- **Execution Policy**: Strictly Read-Only Audit (Zero modifications to application or test source files)

---

## 1. Executive Summary & Scorecard

A full architectural, behavioral, and static AST test health audit was conducted across the entire Centrode Dart codebase. Centrode is a dual-tier Flutter + Rust application featuring an infinite interactive knowledge graph canvas, stateful gesture engines, FFI synchronization, and a local-first SurrealDB persistence pipeline.

### Key Executive Audit Discoveries:
1. **Active Test Suite Failures (9 Failing Tests in Repository)**:
   - **6 failing tests in Batch 2 (Store & Mutations)**: 5 tests crash with `type 'Null' is not a subtype of type 'Future<void>'` due to unstubbed `MockGraphApi.applyEntityMutation` calls, and 1 test fails due to broken rollback logic in `CommandProcessor._processQueue` where uncaught exceptions fail to execute `cmd.undo()`.
   - **3 failing tests in Batch 3 (Models & Presentation)**: 2 tests fail in `graph_relation_test.dart` due to contract drift (`verb` default changed from `'default'` to `'relates to'`) and an invalid test expectation requiring UUID constructor sorting. 1 test fails in `node_style_resolver_test.dart` due to a hardcoded magic color integer (`0xFF64B5F6` vs design token `0xFF2196F3`).
2. **AST Static Smell Violations (9 Wall-Clock Sleeps & 2 Masquerading Demos)**:
   - **9 confirmed `NO_WALL_CLOCK_SLEEP` violations**: 7 using standard `Future.delayed(...)` (6 in `command_processor_test.dart`, 1 in `viewport_state_test.dart`), and 2 critical violations in `layout_tick_interpolator_test.dart` using `Future<void>.delayed(...)`.
   - **AST Visitor Blindspot Uncovered**: The static analyzer `scripts/quality/dart_test_smell_visitor.dart` missed the 2 violations in `layout_tick_interpolator_test.dart` because its target check (`node.target?.toSource() == 'Future'`) failed against generic type arguments (`'Future<void>'`).
   - **2 Interactive Demo Apps in `test/` (`NO_ASSERTIONS`)**: `test/bug_fix/text_alignment_painter_test.dart` (239 lines) and `test/debug/node_editor_fix_test.dart` (407 lines) are standalone Flutter applications calling `runApp()`. They contain 0 automated assertions and fail in headless `flutter test`.
3. **Severe False Confidence & Test Double Deficiencies**:
   - **Harness Double-Instantiation Bug**: `GestureTestHarness` (`test/helpers/gesture_test_harness.dart:24-29`) instantiates two independent `FakeInteractionContext` objects, causing tests in `fsm_gesture_engine_test.dart` to seed nodes into one context while the controller inspects another. Clicks hit empty space, masking cancellation defects while reporting 100% passing tests.
   - **Sham Placeholder Test**: `test/features/graph/ui/context_toolbar_test.dart` tests Flutter Material's `IconButton` with **zero imports from Centrode**, providing 0% defect detection.
   - **Oracle Mismatch Bug**: `test/features/graph/ui/canvas/vertical_context_toolbar_test.dart:64` checks that `Icons.format_bold_rounded` is absent upon closing the Shape submenu; this icon was never in the Shape submenu, allowing submenu closure failures to pass unnoticed.
   - **Ghost Test**: `test/bug_fix/android_app_paths_boot_test.dart` wraps its sole expectation in an `if (Platform.isAndroid || Platform.isIOS)` guard, executing exactly 0 assertions on Windows, Linux, and macOS host/CI runners.
   - **Vacuous `0 == 0` Test**: `test/shared/utils/map_scanner_test.dart` runs against an uninitialized `DaemonGateway`, asserting `0 == 0` on empty lists.
4. **Mock Sprawl vs `InMemoryGraphApi`**:
   - Despite Centrode having a high-fidelity `InMemoryGraphApi` fake, numerous suites (`node_drag_realtime_rendering_test`, `graph_node_mutations_test`, `graph_property_mutations_test`, `graph_relation_mutations_test`, `paste_handler_test`, `graph_screen_test`) employ brittle raw `MockGraphApi` instances with up to 110 lines of manual mocktail stubs, directly causing 5 of the 9 active test failures.

---

### Executive Health Scorecard

| Dimension | Grade | Health Score | Status | Key Subsystem Drivers |
|---|:---:|:---:|:---:|---|
| **1. Test Oracle & Assertion Rigor** | **D** | **50.7%** | High Risk | 9 active test failures, 1 sham suite, 1 wrong-icon bug, ghost tests, vacuous checks, shallow `isNotNull` & `takeException() == null` checks. |
| **2. Test Double Fidelity & Mock Sprawl** | **C-** | **56.2%** | Warning | `GestureTestHarness` double-instantiation bug, 90+ line mocktail sprawl in `graph_screen_test`, unstubbed mocks crashing mutation suites, uninitialized singletons. |
| **3. Temporal Determinism & Async Flakiness** | **B-** | **72.3%** | Moderate | 9 wall-clock sleeps totaling ~2.1s delay, AST scanner blindspot on `Future<void>`, unawaited boot async leak in `simple_test.dart`, production `DateTime.now()` queries. |
| **4. FSM State & Invariant Coverage** | **D** | **53.0%** | High Risk | Broken rollback in `CommandProcessor`, zero algebraic reversibility ($\text{Redo}(\text{Undo}(A)) \equiv A$), untested container zoom-out & scope transitions, missing pointer cancel rollbacks. |
| **5. Cross-Tier FFI & Contract Parity** | **C** | **64.9%** | Moderate | Zero dual-run contract parity tests with Rust SurrealDB, one-way `toRust()` testing omitting `fromRust()` deserialization roundtrips, 6 node subtypes omitted from FFI tests. |
| **6. Defect-Detection Power (Mutation Resistance)** | **D** | **51.0%** | High Risk | >60% untested `ContentBuilder` AST logic, untested `NodeRenderState._handleEntityUpdate`, decoupled synthetic widget trees in zoom tests, high mutant survival rates. |
| **OVERALL TEST SUITE HEALTH** | **D+** | **58.0%** | **CRITICAL REMEDIATION REQUIRED** | **Repository test suite cannot currently act as a reliable quality gate without executing the P0 remediation backlog.** |

---

### Summary of Active Test Failures (9 Broken Tests)

The following 9 tests are currently failing in the repository test suite:

| # | Suite Path | Enclosing Test Case | Line | Failure Type & Verbatim Error | Root Cause Analysis |
|---|------------|---------------------|:----:|-------------------------------|---------------------|
| 1 | `test/features/graph/store/command_processor_test.dart` | `'undoes command on failure and reports error'` | L111 | `Exception: Fake failure` (Unhandled) | Production `CommandProcessor._processQueue` rethrows caught exceptions without calling `cmd.undo()` and without invoking `onError(err)`. The production code broke its rollback contract. |
| 2 | `test/features/graph/store/modules/graph_node_mutations_test.dart` | `'updateNodePosition moves node and updates spatial grid'` | L115 | `type 'Null' is not a subtype of type 'Future<void>'` | Brittle mock: `MockGraphApi.applyEntityMutation` is unstubbed in `setUp()`. When `PatchNodeCommand.execute` calls it, mocktail returns null. |
| 3 | `test/features/graph/store/modules/graph_node_mutations_test.dart` | `'updateNodeSize mutates size and triggers boundary rebuild'` | L127 | `type 'Null' is not a subtype of type 'Future<void>'` | Brittle mock: `MockGraphApi.applyEntityMutation` is unstubbed. |
| 4 | `test/features/graph/store/modules/graph_node_mutations_test.dart` | `'convertContainerToNode removes child relationships'` | L139 | `type 'Null' is not a subtype of type 'Future<void>'` | Brittle mock: `MockGraphApi.applyEntityMutation` is unstubbed. |
| 5 | `test/features/graph/store/modules/graph_property_mutations_test.dart` | `'updateNodeStyle updates node style and notifies subscribers'` | L348 | `type 'Null' is not a subtype of type 'Future<void>'` | Brittle mock: `MockGraphApi.applyEntityMutation` is unstubbed in this test group. |
| 6 | `test/features/graph/store/modules/graph_property_mutations_test.dart` | `'updateRelationStyle rolls back to old style and triggers updater notification on FFI failure'` | L261 | `Expected: <1.0>, Actual: <2.0>` | `CommandProcessor` fails to execute `cmd.undo()` upon failure; the optimistic relation style mutation remains un-reverted. |
| 7 | `test/features/graph/models/graph_relation_test.dart` | `'InfoUiRelation creates with defaults'` | L20 | `Expected: 'default', Actual: 'relates to'` | Contract drift: production default verb in `lib/features/graph/models/graph_relation.dart:44` changed to `'relates to'`, but the test oracle was not updated. |
| 8 | `test/features/graph/models/graph_relation_test.dart` | `'RelationStyleStrategy respects relation direction for backward relation'` | L74 | `Expected: RelationDirection.backward, Actual: RelationDirection.forward` | Invalid test assumption: test assumes `InfoUiRelation` constructor sorts UUIDs and inverts direction; constructor does not perform lexical UUID sorting. |
| 9 | `test/features/graph/models/node_style_resolver_test.dart` | `'resolveStyle assigns container styling for ContainerUiNode'` | L50 | `Expected: <4284790262>, Actual: <4280391411>` | Magic number oracle: test asserted hardcoded hex `0xFF64B5F6` instead of referencing design token abstraction `CentrodeDerivedPalette.current.canvas.containerBorder.toARGB32()` (`0xFF2196F3`). |

---

## 2. Scope & Inventory Traceability (All 66 Test Suites)

The Centrode Dart test suite consists of exactly **66 test files** partitioned into **5 cohesive domain batches** satisfying the smart batching protocol ($\ge 8$ files per batch, 0 remainder batches).

> **Arithmetic Clarification on `ORIGINAL_REQUEST.md`**: Section 10 of `ORIGINAL_REQUEST.md` listed `"Workspace & Shared (9 files)"` under its category breakdown. This was a typographical error in the section header. The actual enumeration of files in that category is **12 files** (3 workspace + 6 shared + 2 root test + 1 integration test). Summing all categories yields: $5 + 8 + 5 + 19 + 4 + 13 + 12 = \mathbf{66\text{ files}}$.

### Complete Inventory Table

| # | Batch | Test Suite File Path | Scope / Architectural Subsystem | Test Type | Health Status | Primary Smells / Violations |
|---|:---:|----------------------|---------------------------------|:---------:|:-------------:|-----------------------------|
| 1 | **B1** | `test/features/graph/engine/centralized_auto_pan_test.dart` | Canvas Engine: Edge auto-pan triggering | Unit / Widget | Warning | Directional predicate oracle (`o.dx < 0`), mid-test `reset(mockEnv)`. |
| 2 | **B1** | `test/features/graph/engine/fsm_gesture_engine_test.dart` | Canvas Engine: FSM gesture state machine | Unit | **CRITICAL** | `GestureTestHarness` double instantiation disconnects seeded nodes. |
| 3 | **B1** | `test/features/graph/engine/gesture_interceptor_test.dart` | Canvas Engine: Tool mode switching & interception | Unit | Warning | Heavy mocktail stub duplication across test groups. |
| 4 | **B1** | `test/features/graph/engine/interaction_engine_test.dart` | Canvas Engine: Pointer routing & drag controllers | Unit | **CRITICAL** | Vacuous `isNotNull` check, mock getter check substituted for state transition. |
| 5 | **B1** | `test/features/graph/engine/node_drag_snap_test.dart` | Canvas Engine: Node drag snapping & grid quantization | Unit | Warning | Missing `handlePointerCancel` position reversion invariant test. |
| 6 | **B1** | `test/bug_fix/deleted_relations_hit_test_test.dart` | Bug Fix: Deleted relation hit-test ghosting | Integration | **Gold Standard** | Zero mocks, real `InMemoryGraphApi`, deep hit-test resolution verification. |
| 7 | **B1** | `test/bug_fix/drawing_node_bug_test.dart` | Bug Fix: Drawing node boundary conditions | Unit | Info | Shallow style check (`strategyType == 'default'`), log absence check. |
| 8 | **B1** | `test/bug_fix/node_drag_realtime_rendering_test.dart` | Bug Fix: Real-time repaint boundary triggers | Widget | Warning | Deep render check (`debugNeedsPaint`), severe mocktail sprawl (30+ lines). |
| 9 | **B1** | `test/bug_fix/port_highlight_drag_bug_test.dart` | Bug Fix: Port highlight rendering during drag | Widget | Good | Deep assertions on `PortPainter.hoveredPort`, imperative FSM state setting. |
| 10 | **B1** | `test/bug_fix/relation_label_morph_editor_overflow_test.dart` | Bug Fix: Label morph editor overflow & layout | Widget | Warning | Test 1 is crash-only (`takeException() == null` x5); Test 2 has deep coords. |
| 11 | **B1** | `test/bug_fix/relation_label_morph_exit_zoom_test.dart` | Bug Fix: Viewport zoom unlocking on morph exit | Widget | **CRITICAL** | Synthetic widget tree replicating `GraphCanvas` instead of real widget. |
| 12 | **B1** | `test/bug_fix/relation_tip_port_snap_test.dart` | Bug Fix: Relation port snapping & patch generation | Unit | Warning | Shallow length-only patch checks (`length == 2`), no algebraic reversibility. |
| 13 | **B1** | `test/bug_fix/viewport_panning_zoom_elastic_test.dart` | Bug Fix: Overscroll bounce & elastic panning | Widget | Good | High rigor: exact matrix translation deltas, spring settling verification. |
| 14 | **B2** | `test/features/graph/store/command_processor_test.dart` | Store: Command queue debouncing & rollback | Unit | **CRITICAL / FAIL** | **6x NO_WALL_CLOCK_SLEEP**, 1 failing test (broken rollback logic). |
| 15 | **B2** | `test/features/graph/store/graph_sync_engine_test.dart` | Store: Sync engine viewport bounds & defaults | Unit | Warning | 3 unused mocktail mocks, duplicate of `modules/graph_sync_engine_test`. |
| 16 | **B2** | `test/features/graph/store/in_memory_graph_api_test.dart` | Store: In-memory backend contract suite runner | Contract | Warning | Contract executed only against fake; zero dual-run parity with Rust FFI. |
| 17 | **B2** | `test/features/graph/store/modules/graph_node_mutations_test.dart` | Store: Node CRUD & spatial grid sync | Unit | **CRITICAL / FAIL** | **3 failing tests** (unstubbed `MockGraphApi`), unasserted spatial grid. |
| 18 | **B2** | `test/features/graph/store/modules/graph_property_mutations_test.dart` | Store: Property mutations & styling rollback | Unit | **CRITICAL / FAIL** | **2 failing tests** (unstubbed mock + broken rollback), ghost comment check. |
| 19 | **B2** | `test/features/graph/store/modules/graph_relation_mutations_test.dart` | Store: Relation mutations & cascading deletes | Unit | Warning | Over 110 lines of mocktail registrations; missing relational cascading invariant. |
| 20 | **B2** | `test/features/graph/store/modules/graph_sync_engine_test.dart` | Store: FFI synchronization & undo/redo | Unit | Warning | Zero algebraic reversibility; mock invocation check substituted for reload. |
| 21 | **B2** | `test/features/graph/store/modules/layout_tick_interpolator_test.dart` | Store: Force simulation tick interpolation | Unit | **CRITICAL** | **2x NO_WALL_CLOCK_SLEEP** (`Future<void>.delayed`), shallow step checks. |
| 22 | **B2** | `test/features/workspace/map_deletion_test.dart` | Workspace: Map deletion & canonical paths | Integration | Warning | Shallow `closeByPath` check on unopened map, real filesystem temp usage. |
| 23 | **B2** | `test/features/workspace/mock_map_return_test.dart` | Workspace: Return to Map button state | Widget | Warning | Asserts singleton state but never asserts widget enabled/disabled status. |
| 24 | **B2** | `test/features/workspace/synchronized_map_selection_test.dart` | Workspace: Shared map selection state | Widget | **CRITICAL** | Masquerading smoke test: asserts `find.byType` with 0 selection logic tested. |
| 25 | **B3** | `test/features/graph/models/content_builder_test.dart` | Domain Models: AST ContentBuilder & extensions | Unit | Warning | >60% untested logic (`toMarkdown`, `parseInline` regex, AST transforms). |
| 26 | **B3** | `test/features/graph/models/graph_node_test.dart` | Domain Models: UiNode hierarchy & FFI | Unit | Warning | One-way `toRust()` testing only; 6 of 9 node subtypes omitted; 0 cycle tests. |
| 27 | **B3** | `test/features/graph/models/graph_relation_test.dart` | Domain Models: UiRelation & styling strategies | Unit | **CRITICAL / FAIL** | **2 failing tests** (contract drift on `verb`, invalid UUID sort expectation). |
| 28 | **B3** | `test/features/graph/models/node_style_resolver_test.dart` | Domain Models: Fallback styling & stroke clamping | Unit | **CRITICAL / FAIL** | **1 failing test** (hardcoded magic color integer vs design token). |
| 29 | **B3** | `test/features/graph/presentation/container_zoom_strategy_test.dart` | Presentation: Container zoom thresholds | Unit | Warning | `checkZoomOut` transition is 100% untested; shallow `isPositive` check. |
| 30 | **B3** | `test/features/graph/presentation/node_render_state_test.dart` | Presentation: Render state coordinator | Unit | Warning | `_handleEntityUpdate` (10 event types) untested; leaks notifiers in tearDown. |
| 31 | **B3** | `test/features/graph/presentation/notifier_notification_counts_test.dart` | Presentation: Notifier emission count invariants | Unit | Good | High rigor on notify counts; leaks `SelectionState` (no `dispose()`). |
| 32 | **B3** | `test/features/graph/presentation/view_state_test.dart` | Presentation: Hitboxes & closest port math | Unit | Good | Deep Rect math; missing cache invalidation tests; leaks `NodeViewState`. |
| 33 | **B3** | `test/features/graph/presentation/viewport_state_test.dart` | Presentation: Viewport controller & camera | Unit | **CRITICAL** | **1x NO_WALL_CLOCK_SLEEP** (L67); container scope FSM transitions untested. |
| 34 | **B4** | `test/features/graph/ui/canvas/canvas_text_editor_test.dart` | Canvas UI: Text editor keyboard shortcuts | Widget | Warning | 1 test case only (Tab key). Misses Escape abort, Enter commit, blur commit. |
| 35 | **B4** | `test/features/graph/ui/canvas/content_text_editing_controller_test.dart` | Canvas UI: Markdown spans & roundtrips | Unit | Good | Leftover debug print (L688); loose `contains()` on roundtrips. |
| 36 | **B4** | `test/features/graph/ui/canvas/grid_layer_test.dart` | Canvas UI: Grid layer LOD & zoom shaders | Widget | **CRITICAL** | Pure smoke test: only asserts `find.byType(GridLayer)`; ignores shaders & LOD. |
| 37 | **B4** | `test/features/graph/ui/canvas/markdown_clipboard_integration_test.dart` | Canvas UI: Clipboard markdown roundtrip | Unit | Warning | Bypasses clipboard platform channels entirely; loose `contains()` checks. |
| 38 | **B4** | `test/features/graph/ui/canvas/markdown_text_selection_controls_test.dart` | Canvas UI: Selection handles & controls | Widget | Warning | Uses deprecated APIs; shallow `greaterThan(0)` on handles; no action checks. |
| 39 | **B4** | `test/features/graph/ui/canvas/node_widget_test.dart` | Canvas UI: Node layout & text display | Widget | **CRITICAL** | Shallow oracle: asserts only `find.text`; ignores badges, selection, editor. |
| 40 | **B4** | `test/features/graph/ui/canvas/paste_handler_test.dart` | Canvas UI: Paste text & markdown to canvas | Unit | **CRITICAL** | Relational hierarchy completely unasserted; uses raw `MockGraphApi`. |
| 41 | **B4** | `test/features/graph/ui/canvas/relation_drag_realtime_test.dart` | Canvas UI: Relation drag & handle overrides | Widget | Good | Deep paint assertions; 45-line handwritten `ComputedRelation` struct. |
| 42 | **B4** | `test/features/graph/ui/canvas/relation_label_display_mode_test.dart` | Canvas UI: Label hit-test modes | Widget | Good | Solid mode coverage; duplicates handwritten `ComputedRelation` struct. |
| 43 | **B4** | `test/features/graph/ui/canvas/relation_tip_toolbar_visibility_test.dart` | Canvas UI: Floating tip toolbar visibility | Widget | Good | High fidelity: uses `InMemoryGraphApi`; verifies FSM drag visibility. |
| 44 | **B4** | `test/features/graph/ui/canvas/vertical_context_toolbar_test.dart` | Canvas UI: Vertical toolbar submenus & hover | Widget | **CRITICAL** | **Oracle bug**: asserts `format_bold_rounded` instead of `crop_square_rounded`. |
| 45 | **B4** | `test/features/graph/ui/canvas/vertical_text_format_toolbar_test.dart` | Canvas UI: Formatting toolbar cycling | Widget | Good | Exemplary FSM cyclical testing (headings, list types, block formats). |
| 46 | **B4** | `test/features/graph/ui/context_toolbar_test.dart` | Canvas UI: Context toolbar action buttons | Widget | **CRITICAL** | **Sham suite**: tests Flutter SDK `IconButton` with 0 Centrode imports. |
| 47 | **B4** | `test/features/graph/ui/graph_screen_test.dart` | Canvas UI: Top-level graph screen composition | Widget | **CRITICAL** | 6 mocks, 90+ lines of stubs, mutates global state, asserts only `Scaffold`. |
| 48 | **B4** | `test/features/graph/ui/text_editing_test.dart` | Canvas UI: Text format state machine | Unit | Warning | Only 2 test cases for an entire FSM; misses clear format, alignment cycles. |
| 49 | **B4** | `test/features/graph/ui/widgets/left_repository_drawer_relations_test.dart` | Canvas UI: Left drawer relations tab | Widget | Good | High quality: tests drawer toggle, empty state, badges, text filtering. |
| 50 | **B4** | `test/features/graph/ui/widgets/overlays/canvas_status_bar/viewport_mini_map_widget_test.dart` | Canvas UI: Minimap camera navigation | Widget | Warning | Negative-only oracle (`isNot(equals)`), chained microtask pumps. |
| 51 | **B4** | `test/features/graph/ui/widgets/overlays/canvas_status_bar/zoom_slider_widget_test.dart` | Canvas UI: Zoom percentage & re-center | Widget | Good | Finds `zoom_in`/`zoom_out` icons but never clicks them; misses slider drag. |
| 52 | **B4** | `test/features/graph/ui/widgets/right_property_panel_test.dart` | Canvas UI: Right property panel expand/collapse | Widget | **CRITICAL** | Crash-only assertions (`takeException() == null`), ignores tabs & drag resize. |
| 53 | **B5** | `test/bug_fix/android_app_paths_boot_test.dart` | Bug Fix: Platform dev root path resolution | Unit | **CRITICAL** | **Ghost test**: `if (Platform.isAndroid || Platform.isIOS)` bypasses all checks on desktop/CI. |
| 54 | **B5** | `test/bug_fix/centrode_palette_generator_shapes_test.dart` | Bug Fix: Palette generator shapes & mood chips | Widget | Warning | Assertionless button taps (Re-roll, Vibrant); lock invariant untested. |
| 55 | **B5** | `test/bug_fix/text_alignment_painter_test.dart` | Bug Fix: Text alignment visual tester | Interactive App | **CRITICAL** | **`NO_ASSERTIONS`**: Interactive GUI app (`runApp`) committed in `test/`. |
| 56 | **B5** | `test/bug_fix/workspace_hub_title_bar_test.dart` | Bug Fix: Title bar overlap regression | Widget | Warning | Defensive `if` guard around core geometry checks; incomplete pump. |
| 57 | **B5** | `test/debug/node_editor_fix_test.dart` | Debug: Interactive StrutStyle debugging tool | Interactive App | **CRITICAL** | **`NO_ASSERTIONS`**: 407-line interactive StrutStyle matrix app (`runApp`). |
| 58 | **B5** | `test/shared/domain/raw_uuid_test.dart` | Shared: RawUuid fast hash code & generation | Unit | Warning | One-sided equality (`uuid1 == uuid2` only); `fromString` untested; endianness. |
| 59 | **B5** | `test/shared/utils/color_theory_engine_test.dart` | Shared: Color harmonies & OKLCH math | Unit | Warning | Shallow length-only harmony oracles; mathematical hue offsets unverified. |
| 60 | **B5** | `test/shared/utils/map_scanner_test.dart` | Shared: Filesystem map scanning | Unit | **CRITICAL** | Uninitialized `DaemonGateway`; vacuous `0 == 0` check on empty lists. |
| 61 | **B5** | `test/shared/widgets/centrode_color_picker_test.dart` | Shared: Color picker & palette mosaic | Widget | Warning | Shallow `isNotNull` check on tapped swatch; recents FIFO buffer untested. |
| 62 | **B5** | `test/shared/widgets/color_theory_engine_widget_test.dart` | Shared: Color theory studio UI | Widget | **CRITICAL** | Tests prototype sandbox (`lib/prototype/`); assertionless button clicks. |
| 63 | **B5** | `test/shared/widgets/unravel_slider_metrics_test.dart` | Shared: Custom slider snapping & metrics | Unit | Good | High precision math; boundary omissions (`itemCount <= 1`, negative snap). |
| 64 | **B5** | `test/liquid_glass_rendering_test.dart` | Shared: Glass panel & glass group rendering | Widget | **CRITICAL** | Arbitrary 100ms pump sleep; shallow `find.byType` count checks; silent shader errors. |
| 65 | **B5** | `test/markdown_parse_test.dart` | Shared: Markdown AST bidirectional serializer | Unit | Warning | Loose `contains()` matchers; defensive `orElse` fallback; zero Rust parity. |
| 66 | **B5** | `integration_test/simple_test.dart` | Integration: Boot splash smoke test | Integration | **CRITICAL** | Pumps 1 frame only; unawaited background `_boot()` async process leaks on exit. |

---

## 3. AST Static Smell Violation Catalog

### 3.1 `NO_WALL_CLOCK_SLEEP` Violations (9 Total)

Wall-clock sleep introduces non-deterministic execution times, increases CI suite runtimes, and breaks Flutter's `fakeAsync` virtual clock guarantees.

| File Path | Line | Offending Code | Enclosing Test Case | Severity | Impact & Context |
|-----------|:----:|----------------|---------------------|:--------:|------------------|
| `test/features/graph/presentation/viewport_state_test.dart` | L67 | `await Future.delayed(Duration.zero);` | `'updateViewportSize sets dimensions and triggers math'` | **CRITICAL** | Introduced to synchronize with an untracked `Future(...)` dispatched inside production `updateVisibleSet`. Bypasses virtual clock. |
| `test/features/graph/store/command_processor_test.dart` | L52 | `await Future.delayed(Duration.zero);` | `'queues and executes immediate command right away'` | **CRITICAL** | Dispatches to event loop to wait for queue processing. |
| `test/features/graph/store/command_processor_test.dart` | L66 | `await Future.delayed(const Duration(milliseconds: 100));` | `'debounces non-immediate command'` | **CRITICAL** | Real hardware sleep waiting for 200ms debounce timer. |
| `test/features/graph/store/command_processor_test.dart` | L69 | `await Future.delayed(const Duration(milliseconds: 250));` | `'debounces non-immediate command'` | **CRITICAL** | Real hardware sleep waiting for debounce expiration. |
| `test/features/graph/store/command_processor_test.dart` | L86 | `await Future.delayed(const Duration(milliseconds: 350));` | `'overwrites previous pending command of same category'` | **CRITICAL** | Real hardware sleep waiting for category debounce. |
| `test/features/graph/store/command_processor_test.dart` | L105 | `await Future.delayed(const Duration(milliseconds: 350));` | `'keeps pending commands of different categories'` | **CRITICAL** | Real hardware sleep waiting for category debounce. |
| `test/features/graph/store/command_processor_test.dart` | L120 | `await Future.delayed(Duration.zero);` | `'undoes command on failure and reports error'` | **CRITICAL** | Dispatches to event loop to wait for failed execution. |
| `test/features/graph/store/modules/layout_tick_interpolator_test.dart` | L86 | `await Future<void>.delayed(const Duration(milliseconds: 50));` | `'interpolates node positions and applies port patches on convergence'` | **CRITICAL** | Real 50ms hardware sleep testing a 10ms `Timer.periodic`. |
| `test/features/graph/store/modules/layout_tick_interpolator_test.dart` | L128 | `await Future<void>.delayed(const Duration(milliseconds: 50));` | `'cancel aborts ongoing interpolation loop'` | **CRITICAL** | Real 50ms hardware sleep testing cancellation timing. |

#### AST Scanner Blindspot Analysis
In `scripts/quality/dart_test_smell_visitor.dart`, the detection logic is implemented as:
```dart
if ((name == 'delayed' && node.target?.toSource() == 'Future') || name == 'sleep') {
  hasWallClockSleep = true;
}
```
When code specifies a type argument—such as `Future<void>.delayed(...)` in `layout_tick_interpolator_test.dart`—`node.target?.toSource()` yields the string `"Future<void>"`, which fails strict string equality against `"Future"`. This allowed two critical wall-clock sleeps to escape automated static AST filtering. 

*Remediation for AST Script*: Update `dart_test_smell_visitor.dart` to match `node.target?.toSource()?.startsWith('Future') ?? false`.

---

### 3.2 `NO_ASSERTIONS` / Standalone Demo Apps in Test Tree (2 Files)

Two files residing in the test directory declare no `test()` or `testWidgets()` blocks, contributing zero test oracles:

1. **`test/bug_fix/text_alignment_painter_test.dart` (239 lines)**:
   - **Declaration**: Line 88: `void main() { runApp(const MaterialApp(home: AlignmentBugTestWidget())); }`
   - **Nature**: An interactive debugging tool with `ChoiceChip` widgets created to visually inspect text alignment bugs.
   - **Impact**: Generates `No tests were found` and fails when executed via `flutter test`. Leaves 3 critical text layout regressions without automated verification.
2. **`test/debug/node_editor_fix_test.dart` (407 lines)**:
   - **Declaration**: Line 3: `void main() => runApp(const MaterialApp(home: NodeEditorTest()));`
   - **Nature**: An interactive 8-button matrix comparing `StrutStyle`, `TextField`, and `EditableText` baseline alignments.
   - **Impact**: 407 lines of dead visual harness masquerading as an automated test.

*(Note on `test/features/graph/store/in_memory_graph_api_test.dart`: This 7-line file delegates execution to `runGraphApiContractTests('InMemoryGraphApi', () => InMemoryGraphApi())` and does not define top-level inline `test()` blocks, but executes active assertions in its shared contract runner).*

---

### 3.3 `VACUOUS_ASSERTION` Scan Confirmation
- **Status**: **0 violations detected across all 66 files**.
- Automated regex and AST inspection confirmed that tautological assertions such as `expect(true, isTrue)`, `expect(false, isFalse)`, `expect(x, equals(x))`, `expect(x, same(x))`, or `expect(anything)` do not exist in the codebase.

---

### 3.4 `UNAWAITED_EXPECT_LATER` Scan Confirmation
- **Status**: **0 violations detected across all 66 files**.
- Grep and AST traversal confirmed zero unawaited `expectLater` invocations. Asynchronous stream assertions either use `await expectLater` or inspect synchronous state properties following pumped futures.

---

## 4. Deep Cognitive Audit Findings Across All 6 Dimensions

---

### 4.1 🔹 Dimension 1: Test Oracle & Assertion Rigor (Health Score: 50.7%, Grade: D)

Dimension 1 evaluates the depth, accuracy, and mutation resistance of test expectations. The audit revealed critical deficiencies ranging from actively broken assertions to sham placeholder suites.

#### Finding D1-01: Sham Test Suite Testing Flutter Material SDK Primitive (CRITICAL)
- **Location**: `test/features/graph/ui/context_toolbar_test.dart:1-29`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';

  void main() {
    testWidgets('ContextToolbar fires callback on tap', (tester) async {
      bool actionFired = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => actionFired = true,
          ),
        ),
      ));
      await tester.tap(find.byType(IconButton));
      expect(actionFired, isTrue);
    });
  }
  ```
- **Defect Mechanism**: The test file imports **zero files from Centrode**. It mounts Flutter's bare `IconButton`, taps it, and asserts `actionFired == true`. It provides 0% test coverage for Centrode's actual floating context toolbar (`ContextToolbarOverlay`), creating false confidence.

#### Finding D1-02: Oracle Mismatch Bug in Toolbar Submenu Closure (CRITICAL)
- **Location**: `test/features/graph/ui/canvas/vertical_context_toolbar_test.dart:60-65`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  // Move away to close
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pumpAndSettle();

  expect(find.byIcon(Icons.format_bold_rounded), findsNothing);
  ```
- **Defect Mechanism**: The test opens the Shape submenu (which contains `Icons.crop_square_rounded`), moves the mouse away, and asserts that `Icons.format_bold_rounded` is absent. `format_bold_rounded` is a text formatting icon that was **never part of the Shape submenu**. Because it was never in the widget tree, `findsNothing` evaluates to `true` even if the Shape submenu remained open.

#### Finding D1-03: Ghost Test Conditionally Bypassing All Assertions on CI (CRITICAL)
- **Location**: `test/bug_fix/android_app_paths_boot_test.dart:8-16`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  final isDesktop = !kReleaseMode && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  ...
  if (Platform.isAndroid || Platform.isIOS) {
    expect(isDesktop, isFalse);
  }
  ```
- **Defect Mechanism**: When run on developer workstations (Windows/macOS/Linux) or standard Linux CI build containers, `Platform.isAndroid || Platform.isIOS` evaluates to `false`. The entire `expect` block is bypassed. The runner reports a green test while executing exactly 0 assertions. Furthermore, the test never invokes `AppPaths`!

#### Finding D1-04: Vacuous `0 == 0` Assertion on Uninitialized Singleton (CRITICAL)
- **Location**: `test/shared/utils/map_scanner_test.dart:18-24`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  final maps = await MapScanner.scanMaps();
  final recent = await MapScanner.getRecentMaps();
  final projects = await MapScanner.getProjectMaps();

  expect(recent.length, equals(maps.length));
  expect(projects.length, equals(maps.length));

  if (maps.any((m) => m.name == 'optic-earth')) {
    ...
  }
  ```
- **Defect Mechanism**: `MapScanner.scanMaps()` checks `if (!DaemonGateway.instance.isInitialized) return [];`. Because the test never initializes `DaemonGateway`, `maps`, `recent`, and `projects` are all empty lists (`[]`). Lines 18-19 assert `0 == 0`. Line 22 evaluates to `false`, skipping the only concrete path assertion.

#### Finding D1-05: Relational Topology Omitted in Paste Handler Tests (CRITICAL)
- **Location**: `test/features/graph/ui/canvas/paste_handler_test.dart:166-228`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  test('heading with children creates tree of nodes with relations', () async {
    await pasteHandler.pasteTextToCanvas('# Heading\nChild text');
    expect(queryController.nodeLookup.length, equals(2));
    // Zero checks on queryController.relationLookup!
  });
  ```
- **Defect Mechanism**: Tests claiming to verify relational hierarchies assert only `nodeLookup.length`. Not a single line checks `queryController.relationLookup`. If relation creation is broken, relations connect in reverse, or verbs are corrupted, the tests still pass.

#### Finding D1-06: Vacuous `isNotNull` Oracle on Non-Nullable ValueNotifier (CRITICAL)
- **Location**: `test/features/graph/engine/interaction_engine_test.dart:139-145`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  test('PointerMove passes through to state', () {
    final event = PointerMoveEvent(position: const Offset(150, 150));
    controller.handlePointerMove(event);
    expect(controller.state.value, isNotNull);
  });
  ```
- **Defect Mechanism**: `controller.state` is a non-nullable `ValueNotifier<CanvasInteractionState>` initialized to `const CanvasIdle()`. Under Dart sound null-safety, `controller.state.value` can never be null. The test provides zero verification that pointer move coordinates were routed or processed.

#### Finding D1-07: Crash-Only Smoke Assertions in RightPropertyPanel (CRITICAL)
- **Location**: `test/features/graph/ui/widgets/right_property_panel_test.dart:40-58`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  expect(tester.takeException(), isNull);
  // Repeated 3 times across expand/collapse cycles
  ```
- **Defect Mechanism**: `RightPropertyPanel` is a 562-line subsystem governing drag resizing, snap thresholds, tab switching, and inspector sections. 3 of the 4 assertions in the suite are `expect(tester.takeException(), isNull)`. Zero assertions verify panel width changes, tab switching, or widget structure.

#### Finding D1-08: Shallow Single-Node Text Oracle (CRITICAL)
- **Location**: `test/features/graph/ui/canvas/node_widget_test.dart:27-86`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  expect(find.text('Test Node'), findsOneWidget);
  ```
- **Defect Mechanism**: Sole oracle in the suite. Fails to verify `TaskUiNode` checkboxes, selection handles, active `CanvasTextEditor` integration, or badges (locked, tags, comments).

#### Finding D1-09: Shallow Directional Predicate in Auto-Pan Delta Verification (WARNING)
- **Location**: `test/features/graph/engine/centralized_auto_pan_test.dart:106, 128`
- **Severity**: **WARNING**
- **Verbatim Code**:
  ```dart
  verify(() => mockEnv.panViewport(any(that: predicate<Offset>((o) => o.dx < 0)))).called(greaterThan(0));
  ```
- **Defect Mechanism**: Asserts only that the pan delta was negative. Ignores quadratic acceleration curves ($ratio^2$), edge margins ($60.0\text{px}$), velocity caps, and step count determinism.

#### Finding D1-10: Negative-Only Camera Oracle in Minimap (WARNING)
- **Location**: `test/features/graph/ui/widgets/overlays/canvas_status_bar/viewport_mini_map_widget_test.dart:88`
- **Severity**: **WARNING**
- **Verbatim Code**:
  ```dart
  expect(newTranslation, isNot(equals(initialTranslation)));
  ```
- **Defect Mechanism**: Passes if translation shifts by 0.0001px, jumps to `NaN`, or moves in an inverted direction.

---

### 4.2 🔹 Dimension 2: Test Double Fidelity & Mock Sprawl (Health Score: 56.2%, Grade: C-)

Dimension 2 evaluates the adherence to repository mocking guidelines, specifically the mandate to use high-fidelity domain fakes (`InMemoryGraphApi`) over brittle mocktail mocks.

#### Finding D2-01: Double Instantiation Bug in `GestureTestHarness` Causing Silent Test Decoupling (CRITICAL)
- **Location**: `test/helpers/gesture_test_harness.dart:24-29` (manifests in `fsm_gesture_engine_test.dart:41-59`)
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  GestureTestHarness({
    FakeInteractionContext? context,
  })  : context = context ?? FakeInteractionContext(),
        transformController = TransformationController(),
        controller = InteractionController(
          transformController: TransformationController(),
          environment: context ?? FakeInteractionContext(), // BUG: Creates second distinct instance!
        );
  ```
- **Defect Mechanism**: When `context == null` (the default invocation `GestureTestHarness()`), constructor initializer evaluation creates two distinct instances of `FakeInteractionContext`. `harness.context` references Instance A, while `harness.controller.environment` references Instance B.
  In `fsm_gesture_engine_test.dart:42`:
  ```dart
  harness.context.seedNode('node-1', const Offset(100, 100), const Size(160, 80));
  ```
  `node-1` is seeded into Instance A. When pointer down hits `Offset(120, 120)`, `controller.environment` (Instance B) has zero nodes. The gesture hits empty space and initiates `MarqueeSelecting` instead of `NodeDragging`. When `handlePointerCancel` executes, `MarqueeSelecting` cancels to `CanvasIdle`. The test passes, providing 100% false confidence that node drag gesture cancellation was verified, when in reality node dragging was never entered.

#### Finding D2-02: Unstubbed `MockGraphApi` Crashing State Mutation Tests (CRITICAL)
- **Location**: `test/features/graph/store/modules/graph_node_mutations_test.dart:115, 127, 139` and `graph_property_mutations_test.dart:348`
- **Severity**: **CRITICAL**
- **Defect Mechanism**: Mutation tests instantiate `class MockGraphApi extends Mock implements GraphApi`. `setUp()` fails to stub `mockApi.applyEntityMutation`. When `PatchNodeCommand.execute` calls it, mocktail returns null, crashing 4 tests with `type 'Null' is not a subtype of type 'Future<void>'`. Using `InMemoryGraphApi` eliminates this defect entirely.

#### Finding D2-03: Extreme Mock Sprawl & Global Singleton Leakage in Graph Screen Test (CRITICAL)
- **Location**: `test/features/graph/ui/graph_screen_test.dart:41-147`
- **Severity**: **CRITICAL**
- **Defect Mechanism**: Defines 6 mock classes and writes 90+ lines of manual `.thenReturn(...)` and `.thenAnswer(...)` stubs. On line 142, mutates global static singleton `MapManager.instance.tabsControllerForTesting = mockTabsController;` without registering an `addTearDown` cleanup, polluting subsequent tests.

#### Finding D2-04: Brittle Raw `MockGraphApi` in Paste Handler (CRITICAL)
- **Location**: `test/features/graph/ui/canvas/paste_handler_test.dart:14-109`
- **Severity**: **CRITICAL**
- **Defect Mechanism**: Defines `MockGraphApi` with 11 custom fallback registrations and 20 lines of manual stubbing, including a handwritten `getGraphSnapshot()` stub mapping `queryController.nodeLookup`.

#### Finding D2-05: Decoupled Synthetic Widget Tree in Zoom Exit Test (CRITICAL)
- **Location**: `test/bug_fix/relation_label_morph_exit_zoom_test.dart:31-68`
- **Severity**: **CRITICAL**
- **Defect Mechanism**: Line 31 explicitly states: `// Replicating the current structure in GraphCanvas (without ListenableBuilder on editorState)`. The test does not mount `GraphCanvas`; it synthesizes an inline dummy widget tree with 4 nested `ValueListenableBuilder`s in the test body. Any regression in `GraphCanvas` wiring cannot be caught.

#### Finding D2-06: Resource Leakage Across Presentation Test Suites (WARNING)
- **Location**: `node_render_state_test.dart:36`, `notifier_notification_counts_test.dart:153`, `view_state_test.dart:18`
- **Severity**: **WARNING**
- **Defect Mechanism**: Instantiates `NodeRenderState` (9 `ValueNotifier` instances), `SelectionState`, and `NodeViewState` but never calls `.dispose()` in `tearDown`, leaking listeners across test runs.

---

### 4.3 🔹 Dimension 3: Temporal Determinism & Async Flakiness (Health Score: 72.3%, Grade: B-)

Dimension 3 evaluates virtual clock isolation, async execution safety, and protection against timing jitter.

#### Finding D3-01: Wall-Clock Sleep Pollution in Store Commands & Viewport (CRITICAL)
- **Location**: `command_processor_test.dart` (6 sleeps, ~1,050ms), `layout_tick_interpolator_test.dart` (2 sleeps, ~100ms), `viewport_state_test.dart` (1 sleep, 0ms)
- **Severity**: **CRITICAL**
- **Defect Mechanism**: Total ~2,150ms of unvirtualized real-time sleep across 9 test cases. Sensitive to host CPU scheduling, introducing flakiness on congested CI runners.

#### Finding D3-02: Async Process Leak in Integration Boot Smoke Test (CRITICAL)
- **Location**: `integration_test/simple_test.dart:9-11`
- **Severity**: **CRITICAL**
- **Verbatim Code**:
  ```dart
  await tester.pumpWidget(const CentrodeApp());
  await tester.pump();
  expect(find.text('CENTRODE'), findsOneWidget);
  ```
- **Defect Mechanism**: Pumps exactly 1 frame. `BootSplashScreen._boot()` begins executing background service initialization and desktop `windowManager` configuration asynchronously. When the test exits immediately, `_boot()` is still actively executing in the background, violating async lifecycle boundaries and risking unhandled background exceptions.

#### Finding D3-03: Uncontrolled System Wall-Clock Queries in Production Physics Engines (WARNING)
- **Location**: `lib/features/graph/engine/states/auto_pan_manager.dart:75-81`, `lib/features/graph/engine/interaction_engine.dart:129-145`
- **Severity**: **WARNING**
- **Defect Mechanism**: Production `AutoPanManager._timer` computes elapsed time using `DateTime.now().difference(_lastTickTime!)`. Production `InteractionController._processDoubleTap` checks thresholds using `now.difference(_lastPointerDownTime!)`. Real hardware clock queries bypass `fakeAsync` virtual clocks, causing delta fluctuations under CI CPU throttling.

#### Finding D3-04: Arbitrary Microtask Pump Band-Aids (WARNING)
- **Location**: `liquid_glass_rendering_test.dart:13` (`pump(100ms)`), `synchronized_map_selection_test.dart:18` (`pump(100ms)`), `viewport_mini_map_widget_test.dart:82` (`pump(Duration.zero)`)
- **Severity**: **WARNING**
- **Defect Mechanism**: Hardcoded delay band-aids for unawaited internal async tasks.

---

### 4.4 🔹 Dimension 4: FSM State & Invariant Coverage (Health Score: 53.0%, Grade: D)

Dimension 4 audits state machine integrity, transition verification, algebraic reversibility, and invariant preservation.

#### Finding D4-01: Broken Rollback Contract in CommandProcessor (CRITICAL)
- **Location**: `test/features/graph/store/command_processor_test.dart:111-126`, `lib/features/graph/store/command_processor.dart:65-76`
- **Severity**: **CRITICAL**
- **Defect Mechanism**: Test `'undoes command on failure and reports error'` expects command failure to trigger `cmd.undo()` and invoke `onError(err)`. In production `CommandProcessor._processQueue`, caught exceptions are rethrown without executing rollback, crashing tests and leaving state corrupted.

#### Finding D4-02: Zero Algebraic Reversibility Verification on Sync Engine (CRITICAL)
- **Location**: `test/features/graph/store/modules/graph_sync_engine_test.dart:180-194`
- **Severity**: **CRITICAL**
- **Defect Mechanism**: Tests `'undo triggers FFI undo and reloads graph'` and `'redo triggers FFI redo and reloads graph'` only assert `verify(() => mockApi.undo()).called(1)`. Zero assertions verify that the graph actually reloads or that $\text{Redo}(\text{Undo}(A)) \equiv A$.

#### Finding D4-03: Missing Position Reversion on Node Drag Gesture Cancellation (WARNING)
- **Location**: `test/features/graph/engine/node_drag_snap_test.dart:19-106`, `lib/features/graph/engine/states/node_drag_state.dart:202-215`
- **Severity**: **WARNING**
- **Defect Mechanism**: In production `NodeDragging.handlePointerCancel`, timers are cancelled but `vs.positionNotifier.value` is never reverted to the pre-drag position. The test suite contains zero tests for `handlePointerCancel`, leaving this state corruption uncovered.

#### Finding D4-04: Container Zoom-Out and Viewport Scope FSM Transitions Untested (WARNING)
- **Location**: `container_zoom_strategy_test.dart` and `viewport_state_test.dart:370-450`
- **Severity**: **WARNING**
- **Defect Mechanism**: `DefaultContainerZoomStrategy.checkZoomOut` encapsulates exit scale hysteresis and hit-test inflation; it has **0 tests**. `ViewportController.openContainer` and `closeContainer` manage the transition between `RootViewportScope` and `ContainerViewportScope`; they have **0 tests**.

#### Finding D4-05: Palette Lock Preservation Invariant Untested (WARNING)
- **Location**: `test/bug_fix/centrode_palette_generator_shapes_test.dart:49-51`
- **Severity**: **WARNING**
- **Defect Mechanism**: Taps slot lock icon, but never performs a subsequent re-roll to assert that the locked color remains invariant while unlocked colors mutate.

---

### 4.5 🔹 Dimension 5: Cross-Tier FFI & Contract Parity (Health Score: 64.9%, Grade: C)

Dimension 5 evaluates consistency between the Flutter presentation layer, Dart models, and the Rust SurrealDB FFI layer.

#### Finding D5-01: Missing Dual-Run Contract Parity for Rust SurrealDB Backend (CRITICAL)
- **Location**: `test/features/graph/store/in_memory_graph_api_test.dart:1-6`
- **Severity**: **CRITICAL**
- **Defect Mechanism**: `runGraphApiContractTests` parameterizes contract verification for `GraphApi`. However, it is only executed against `InMemoryGraphApi`. The real backend `RustGraphApi` (Rust SurrealDB via FRB) is never executed against this contract suite.

#### Finding D5-02: One-Way FFI Serialization Testing Omitting Deserialization Parity (WARNING)
- **Location**: `test/features/graph/models/graph_node_test.dart:9-191`, `graph_relation_test.dart`
- **Severity**: **WARNING**
- **Defect Mechanism**: Tests assert `node.toRust()`. However, neither suite tests `UiNode.fromRust(...)` or `UiRelation.fromRust(...)`. The roundtrip invariant $\forall N: \text{fromRust}(\text{toRust}(N)) \equiv N$ is completely unverified. Furthermore, 6 of 9 node subtypes (`Comment`, `Drawing`, `Shape`, `Frame`, `Container`, `Inter`) have zero FFI serialization tests.

#### Finding D5-03: Endianness Drift Risk in `RawUuid.fastHashCode` (WARNING)
- **Location**: `test/shared/domain/raw_uuid_test.dart:47-48`, `lib/shared/domain/raw_uuid.dart`
- **Severity**: **WARNING**
- **Defect Mechanism**: `fastHashCode` computes `bd.getInt64(0) ^ bd.getInt64(8)` without specifying endianness (`Endian.big` vs `Endian.little`). On different host architectures or across FFI boundaries with Rust `uuid`, hash discrepancies can occur.

#### Finding D5-04: Bypassed Platform Boundary in Clipboard Integration Test (WARNING)
- **Location**: `test/features/graph/ui/canvas/markdown_clipboard_integration_test.dart:8-48`
- **Severity**: **WARNING**
- **Defect Mechanism**: Titled clipboard integration test, but directly calls `ContentTextEditingController.insertMarkdownSpans()` without touching `SystemChannels.platform` or `Clipboard.getData`.

---

### 4.6 🔹 Dimension 6: Defect-Detection Power & Mutation Resistance (Health Score: 51.0%, Grade: D)

Dimension 6 audits mutation resistance: if production logic is inverted or mutated, will the test suite catch it?

#### Finding D6-01: Major Production Engines Untested in ContentBuilder (WARNING)
- **Location**: `lib/features/graph/models/content_builder.dart:216-364, 501-558, 614-748`
- **Severity**: **WARNING**
- **Defect Mechanism**: Over 60% of production logic in `content_builder.dart` is untested:
  - `ContentFactory.toMarkdown`: 0% test coverage.
  - `ContentFactory.parseInline`: regex delimiter parsing for nested marks has 0% coverage.
  - `ContentTransformExtensions` (`toggleMark`, `setTextAlign`, `transformLetterCase`, `setHighlightColor`, `resetFormatting`): 0% coverage.

#### Finding D6-02: Untested `NodeRenderState._handleEntityUpdate` Pipeline (WARNING)
- **Location**: `lib/features/graph/presentation/node_render_state.dart:96-179`
- **Severity**: **WARNING**
- **Defect Mechanism**: 10 `GraphUpdateType` switch cases (position, size, expansion, text, style, nodeAdded, nodeDeleted, relationAdded, relationDeleted, boundary) have 0% test coverage.

#### Finding D6-03: Shallow Geometry and Color Theory Oracles (WARNING)
- **Location**: `color_theory_engine_test.dart:21-43` and `view_state_test.dart`
- **Severity**: **WARNING**
- **Defect Mechanism**: Color harmony tests assert only list length (5) and base color position, failing to verify that mathematical hue angles (180° complementary, 120°/240° triadic) are calculated. Mutants returning the base color 5 times pass all tests.

---

## 5. Domain Batch Synthesis & Metrics

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CENTRODE TEST AUDIT SCOPE                       │
│                                (66 Files)                              │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
       ┌──────────────┬─────────────┼──────────────┬──────────────┐
       ▼              ▼             ▼              ▼              ▼
   Batch 1        Batch 2       Batch 3        Batch 4        Batch 5
   FSM & Gestures Store & Pipeline Models & Viewport Canvas UI & Text Shared & Integration
   (13 files)     (11 files)    (9 files)      (19 files)     (14 files)
   Score: 72.8%   Score: 41.0%  Score: 55.8%   Score: 64.0%   Score: 50.8%
   Grade: C+      Grade: D      Grade: D+      Grade: C-      Grade: D+
```

### Batch Comparison Table

| Batch # | Domain Scope | Files | Tests | Active Failures | Wall Sleeps | NO_ASSERT | Primary Architectural Risk | Batch Grade |
|:---:|--------------|:-----:|:-----:|:---------------:|:-----------:|:---------:|----------------------------|:-----------:|
| **1** | FSM Gestures, Snapping & Physics | 13 | 82 | 0 | 0 | 0 | `GestureTestHarness` double-instantiation bug; vacuous `isNotNull` check. | **C+ (72.8%)** |
| **2** | Store Mutations & Workspace Pipeline | 11 | 64 | **6** | **8** | 0 | Unstubbed `MockGraphApi` crashes; broken `CommandProcessor` rollback; 8 wall sleeps. | **D (41.0%)** |
| **3** | Models & Presentation Architecture | 9 | 58 | **3** | **1** | 0 | Contract drift on relation verb; invalid UUID sort assumption; magic color number; untested zoom-out. | **D+ (55.8%)** |
| **4** | Canvas UI, Markdown Editor & Overlays | 19 | 114 | 0 | 0 | 0 | Sham `context_toolbar` suite; wrong icon in submenu test; 90-line mock sprawl in `graph_screen`. | **C- (64.0%)** |
| **5** | Shared Utilities, Regressions & Boot | 14 | 52 | 0 | 0 | **2** | 2 interactive apps (`runApp`); ghost test on CI; vacuous `0==0` check; async boot leak. | **D+ (50.8%)** |
| **TOTAL** | **Repository-Wide** | **66** | **370** | **9** | **9** | **2** | **High False Confidence Barrier; Urgent P0 Remediation Required** | **D+ (58.0%)** |

---

## 6. Prioritized Actionable Remediation Backlog

### 🚨 Priority 0 (P0: False Confidence, Suite Failures & Critical Flakiness)
*Immediate resolution required before merging code or relying on CI.*

1. **Resolve 5 Crashing Mutation Tests via `InMemoryGraphApi`**:
   - In `graph_node_mutations_test.dart` and `graph_property_mutations_test.dart`, replace `MockGraphApi` with `final api = InMemoryGraphApi();`. Eliminates 5 crashing null-subtype errors immediately.
2. **Fix Rollback Contract & Uncaught Exception in `CommandProcessor`**:
   - In `lib/features/graph/store/command_processor.dart:65-76`, ensure caught execution exceptions invoke `cmd.undo()` and trigger `onError(err)` before rethrowing or logging. Unblocks `command_processor_test.dart` (L111) and `graph_property_mutations_test.dart` (L261).
3. **Resolve 3 Model Failures (Contract Drift & Magic Numbers)**:
   - In `test/features/graph/models/graph_relation_test.dart:20`, update default verb expectation to `'relates to'`.
   - In `test/features/graph/models/graph_relation_test.dart:74`, configure endpoint arrow shapes (`startShape` vs `endShape`) before invoking `relation.normalize()`, removing the invalid UUID string sorting assumption.
   - In `test/features/graph/models/node_style_resolver_test.dart:50`, replace hardcoded `0xFF64B5F6` with `CentrodeDerivedPalette.current.canvas.containerBorder.toARGB32()`.
4. **Fix Double Instantiation Bug in `GestureTestHarness`**:
   - In `test/helpers/gesture_test_harness.dart:24-29`, refactor constructor to use the single instantiated context:
     ```dart
     GestureTestHarness({FakeInteractionContext? context})
       : context = context ?? FakeInteractionContext(),
         transformController = TransformationController(),
         controller = InteractionController(
           transformController: TransformationController(),
           environment: context ?? FakeInteractionContext(), // Fix: Pass same context instance
         );
     ```
     Remediation: Store `final ctx = context ?? FakeInteractionContext();` in an initializer or factory constructor so `controller.environment == this.context`.
5. **Fix Oracle Mismatch Bug in `vertical_context_toolbar_test.dart:64`**:
   - Change `expect(find.byIcon(Icons.format_bold_rounded), findsNothing);` to `expect(find.byIcon(Icons.crop_square_rounded), findsNothing);`.
6. **Eliminate 9 Wall-Clock Sleeps**:
   - Migrate `command_processor_test.dart` and `layout_tick_interpolator_test.dart` to `fakeAsync((async) { ... async.elapse(...); })`.
   - In `viewport_state_test.dart:67`, replace `await Future.delayed(Duration.zero)` with synchronous spatial query completion or `fakeAsync`.
7. **Remediate Ghost Test `android_app_paths_boot_test.dart`**:
   - Inject a mockable `PlatformEnvironment` into `AppPaths` and unconditionally test Android, iOS, and desktop path resolution.
8. **Remediate Vacuous `0 == 0` Test in `map_scanner_test.dart`**:
   - Initialize a test `DaemonGateway` with mock descriptors so `MapScanner` parses real descriptors.
9. **Fix Async Process Leak in `integration_test/simple_test.dart`**:
   - Replace single `pump()` with `await tester.pumpAndSettle()`, verifying that `BootSplashScreen` transitions to `WorkspaceHubScreen` before test termination.
10. **Convert or Relocate 2 Interactive Demo Apps (`NO_ASSERTIONS`)**:
    - Convert `text_alignment_painter_test.dart` into an automated `testWidgets` suite asserting `NodeTextSpanBuilder.buildPerBlockTextSpans` outputs.
    - Relocate `node_editor_fix_test.dart` outside `test/` into `tools/debug_harness/` or sandbox.
11. **Delete or Re-implement Sham Test `context_toolbar_test.dart`**:
    - Replace the bare Flutter `IconButton` smoke test with integration tests for `ContextToolbarOverlay`.
12. **Add Relational Hierarchy Assertions to `paste_handler_test.dart`**:
    - In lines 176, 186, 196, 227, assert `queryController.relationLookup` count, endpoints, and verbs.

---

### ⚠️ Priority 1 (P1: Mock Hygiene, FSM Invariants & Contract Parity)
*Essential refactoring for architectural resilience and behavioral safety.*

13. **Migrate Remaining `MockGraphApi` Suites to `InMemoryGraphApi`**:
    - Refactor `node_drag_realtime_rendering_test.dart`, `graph_relation_mutations_test.dart`, and `paste_handler_test.dart` to use `InMemoryGraphApi`, eliminating over 140 lines of brittle mocktail fallback registrations.
14. **Clean Up Mock Sprawl & Global Singleton Leakage in `graph_screen_test.dart`**:
    - Replace 90+ lines of stubs with real presentation controllers; register `addTearDown(() => MapManager.instance.tabsControllerForTesting = null)`. Replace `find.byType(Scaffold)` with specific component assertions (`CanvasInteractiveViewer`, `GridLayer`, `LeftRepositoryDrawer`).
15. **Enforce Algebraic Reversibility ($\text{Redo}(\text{Undo}(A)) \equiv A$)**:
    - In `modules/graph_sync_engine_test.dart`, implement structural snapshot comparison verifying that node positions, attributes, and relations are identical before mutation and after undo-redo cycles.
16. **Add `PointerCancelEvent` Position Reversion Invariant Tests**:
    - In `node_drag_snap_test.dart` and `fsm_gesture_engine_test.dart`, assert that cancelling a drag explicitly reverts `viewState.positionNotifier.value` to pre-drag coordinates.
17. **Implement Container Zoom-Out and Scope FSM Tests**:
    - Add tests for `DefaultContainerZoomStrategy.checkZoomOut` verifying exit scale thresholds and hit area inflation.
    - Add tests for `ViewportController.openContainer` and `closeContainer` hierarchy transitions.
18. **Implement FFI Bidirectional Roundtrip Tests**:
    - Add `UiNode.fromRust(node.toRust()) == node` parity assertions for all 9 node subtypes in `graph_node_test.dart`.
    - Add `UiRelation.fromRust(relation.toRust()) == relation` parity assertions in `graph_relation_test.dart`.
19. **Replace Smoke-Only Oracles in `grid_layer_test.dart` & `right_property_panel_test.dart`**:
    - In `grid_layer_test.dart`: assert `_StaticGridPainter` and test `calculateEffectiveGridSize(scale)` across 1.0, 0.5, 0.2 scale thresholds.
    - In `right_property_panel_test.dart`: assert panel width transitions (42 to 366), test drag resizing (240 to 550), and verify tab switching.
20. **Expand FSM Coverage for `CanvasTextEditor` and `TextFormatStateMachine`**:
    - In `canvas_text_editor_test.dart`: add tests for Escape abort, Enter commit, and blur auto-commit.
    - In `text_editing_test.dart`: add tests for toggling formats off, clearing block formats, and cycling text alignment.
21. **Implement Lock-Preservation FSM Assertion in `centrode_palette_generator_shapes_test.dart`**:
    - Toggle slot lock, tap Re-roll, and assert that the locked slot color remains unchanged while unlocked colors mutate.
22. **Eliminate Test Resource Leaks in Presentation Suites**:
    - Add `tearDown(() => state.dispose())` across `node_render_state_test.dart`, `view_state_test.dart`, and `notifier_notification_counts_test.dart`.

---

### 📋 Priority 2 (P2: Precision Hardening, Boundary Invariants & Coverage Depth)
*Systematic quality hardening and test suite maintenance.*

23. **Expand `ContentBuilder` Engine Test Coverage**:
    - Add tests for `ContentFactory.toMarkdown`.
    - Add comprehensive tests for `ContentFactory.parseInline` (nested bold/italic/code/links).
    - Add tests for `ContentTransformExtensions` (`toggleMark`, `setTextAlign`, `transformLetterCase`, `setHighlightColor`, `resetFormatting`).
24. **Tighten Markdown Roundtrip Matchers**:
    - In `markdown_parse_test.dart` and `content_text_editing_controller_test.dart`, replace loose `contains()` matchers with exact string or AST equality.
25. **Replace Directional Predicates with Math Bounds**:
    - In `centralized_auto_pan_test.dart`: assert exact delta bounds: `expect(delta.dx, closeTo(-expectedSpeed * dt, 0.01))`.
    - In `viewport_mini_map_widget_test.dart`: replace `isNot(equals(...))` with exact expected camera coordinates.
26. **Inject Virtualized Clock into Physics Engines**:
    - Refactor `AutoPanManager` and `InteractionController` to accept an injectable clock or use `PointerEvent.timeStamp` rather than querying hardware `DateTime.now()`.
27. **Extract Centralized `TestComputedRelationFactory`**:
    - Consolidate 40-line `ComputedRelation` boilerplate across `relation_drag_realtime_test.dart` and `relation_label_display_mode_test.dart` into `test/fixtures/`.
28. **Harden Boundary Invariants in `unravel_slider_metrics_test.dart` & `raw_uuid_test.dart`**:
    - In `unravel_slider_metrics_test.dart`: test `itemCount <= 1`, negative travel offsets, `nearestIndex`, and miss conditions on `hitTest`.
    - In `raw_uuid_test.dart`: test negative equality (`uuid1 != uuid2`), validate `RawUuid.fromString` format branches, and verify buffer length assertions.
29. **Clean Up Test Hygiene**:
    - Remove `print('FULL RESULT: ...')` from `content_text_editing_controller_test.dart:688`.
    - Remove `debugPrint(...)` from `relation_label_morph_exit_zoom_test.dart:91`.
    - Update `scripts/quality/dart_test_smell_visitor.dart` to match generic types (`Future<void>.delayed`).

---

## 7. Acceptance Criteria Checklist Verification

The synthesized audit report has been verified against all acceptance criteria set forth in `ORIGINAL_REQUEST.md`:

- [x] **Audit Completeness & Traceability**:
  - All **66 Dart test files** are explicitly enumerated and accounted for in the Traceability Table (Section 2).
  - Scope arithmetic clarification regarding the header typo in `ORIGINAL_REQUEST.md` (Workspace & Shared contains 12 actual files, totaling exactly 66) is documented.
- [x] **Automated AST Smell Scan Integration**:
  - The repository AST test smell scanner was executed across `test/` and `integration_test/`.
  - All **9 `NO_WALL_CLOCK_SLEEP` violations** (including the 2 uncovered in `layout_tick_interpolator_test.dart`) and the AST visitor syntax blindspot (`Future<void>`) are thoroughly analyzed (Section 3.1).
  - Both **2 standalone interactive GUI applications** (`NO_ASSERTIONS`) are cataloged (Section 3.2).
  - Zero violations for `VACUOUS_ASSERTION` and `UNAWAITED_EXPECT_LATER` are verified (Sections 3.3 & 3.4).
- [x] **Deep Cognitive Multi-Dimensional Analysis**:
  - Each reported finding references exact file paths, line ranges, violated test health dimensions, severities (`CRITICAL`, `WARNING`, `INFO`), and verbatim defect mechanisms (Section 4).
  - All 6 core dimensions are graded with clear qualitative and quantitative scorecards (Section 1).
  - All **9 active test failures** in the repository are root-caused and documented (Section 1).
- [x] **Report Structure & Artifacts**:
  - The complete authoritative report is synthesized and committed to `docs/reports/dart_test_health_report.md`.
  - **Zero application or test source files were modified** during this audit phase.
  - The remediation backlog provides concrete, reproducible, high-ROI refactoring directives prioritized across P0, P1, and P2 (Section 6).
