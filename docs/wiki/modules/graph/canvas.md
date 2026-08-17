# Canvas & Rendering

---

## Canvas Widget

`lib/features/graph/ui/canvas/graph_canvas.dart`

`GraphCanvas` is the root widget for the infinite canvas. It:
- Wraps content in a `CanvasInteractiveViewer` (custom `InteractiveViewer`) for pan/zoom
- Hosts the `InteractionController` FSM for gesture processing
- Manages viewport restoration from persistence
- Coordinates tab sessions for multi-map support

---

## Painting Pipeline

The canvas uses a layered painting approach via `UnboundedStack`:

| Layer | File | Responsibility |
|-------|------|----------------|
| Grid | `layers/grid_layer.dart` | Background grid rendering |
| Relations | `layers/relation_layer.dart` | Connection routing and rendering |
| Nodes | `layers/node_layer.dart` | Node widget placement |
| Ports | `layers/port_layer.dart` | Connection port highlights |
| Overlay | `layers/overlay_layer.dart` | Selection boxes, drawing previews |

Each layer is a separate `CustomPainter` or widget, allowing independent repaint optimization.

---

## Node Rendering

Nodes are rendered by type-specific painters:

| Renderer | File | Node Types |
|----------|------|------------|
| `ShapeNodeRenderer` | `painters/nodes/shape_node_renderer.dart` | Info, Task, Comment, Shape |
| `TextNodeRenderer` | `painters/nodes/text_node_renderer.dart` | Text content rendering |
| `FrameNodeRenderer` | `painters/nodes/frame_node_renderer.dart` | Frame boundaries |
| `ContainerNodeRenderer` | `painters/nodes/container_node_renderer.dart` | Container groups |
| `NodeSelectionRenderer` | `painters/nodes/node_selection_renderer.dart` | Selection highlights |
| `ContainerBoundaryPainter` | `painters/container_boundary_painter.dart` | Container boundary lines |

The `NodeRenderEntry` (`painters/node_render_entry.dart`) orchestrates which renderer to use based on node type and state.

---

## Canvas Widgets

| Widget | File | Responsibility |
|--------|------|----------------|
| `CanvasNodesHost` | `widgets/canvas_nodes_host.dart` | Hosts all node widgets on canvas |
| `AttachmentShelfWidget` | `widgets/attachment_shelf_widget.dart` | Renders file attachment chips below a node |
| `MediaNodeWidget` | `widgets/media_node_widget.dart` | Embeds media content (image, video, audio, PDF) |
| `NodeRichText` | `widgets/node_rich_text.dart` | Rich text rendering for node content |
| `DrawNodeWidget` | `widgets/draw_node_widget.dart` | Freehand drawing widget |
| `HighlightFrame` | `widgets/highlight_frame.dart` | Selection highlight frame |

---

## Canvas Utilities

| Utility | File | Responsibility |
|---------|------|----------------|
| `ContainerPaintUtils` | `utils/container_paint_utils.dart` | Container boundary painting helpers |
| `DashedBoxPaintUtils` | `utils/dashed_box_paint_utils.dart` | Dashed rectangle rendering (frames) |
| `PerimeterDockCalculator` | `utils/perimeter_dock_calculator.dart` | Computes port dock positions on node perimeters |

---

## Relation Rendering

Relations are rendered by `RelationPainter` (`painters/relation_painter.dart`):

1. `RelationPaintDtoBuilder` computes DTOs from `ComputedRelation` data
2. `TransformedRelationPainter` applies canvas transformations
3. Arrow endpoints rendered by `EndpointShapes` (Rust-side)

Routing styles: Bezier, B-spline, orthogonal, octilinear, sinewave, straight.

---

## Text Editing

On-canvas text editing system in `ui/canvas/text/`:

| File | Role |
|------|------|
| `canvas_text_editor.dart` | Inline text editor widget |
| `content_text_editing_controller.dart` | Rich text editing controller |
| `text_ast_serializer.dart` | Serialize/deserialize text AST |
| `text_format_models.dart` | Text format data models |
| `text_format_state_machine.dart` | Format state transitions |
| `markdown_text_selection_controls.dart` | Custom selection handles |

---

## Context Menu & Keyboard

- `canvas_context_menu.dart` — right-click context menu
- `canvas_keyboard_handler.dart` — keyboard shortcuts (delete, copy, paste, undo, redo)
- `paste_handler.dart` — clipboard paste handling
- `canvas_overlay_layout.dart` — overlay positioning system

---

## Performance & Repaint Boundaries

To maintain 60–120 FPS on expansive canvas graphs with hundreds of nodes and relations, Centrode uses a multi-layered repaint isolation architecture:

```mermaid
graph TD
    Canvas[GraphCanvas Scaffold] --> RepaintBoundaryGrid[RepaintBoundary: GridLayer]
    Canvas --> RepaintBoundaryRelations[RepaintBoundary: RelationLayer]
    Canvas --> RepaintBoundaryNodes[RepaintBoundary: NodeLayer]
    Canvas --> RepaintBoundaryPorts[RepaintBoundary: PortLayer]
    Canvas --> RepaintBoundaryOverlay[RepaintBoundary: OverlayLayer]

    subgraph TransientState["High-Frequency Gestures (60fps)"]
        Drag[Node Drag / Resize]
        Marquee[Marquee Selection Box]
        RelationDrag[Relation Tip Preview]
    end

    TransientState -->|Updates ONLY| RepaintBoundaryOverlay
    TransientState -.->|Bypasses (No Rebuild)| RepaintBoundaryGrid
    TransientState -.->|Bypasses (No Rebuild)| RepaintBoundaryNodes
```

### Core Optimization Guidelines

1. **Layer Decoupling via `UnboundedStack`**:
   - Background grid, static node widgets, relation paths, ports, and dynamic selection overlays are split into separate layers wrapped in `RepaintBoundary` widgets.
   - High-frequency pointer moves (e.g. marquee box or snap guides) trigger repaints **strictly on the `OverlayLayer`**, leaving heavy node renderers untouched.

2. **Granular Notifier Slicing (`TraceableNotifier`)**:
   - Avoid top-level monolithic `notifyListeners()` calls on whole-graph state during interactive drags.
   - Use fine-grained `ValueNotifier` instances for single-node volatile states (`VolatileNodeState`) and viewport transforms.

3. **Flyweight Style Resolution**:
   - Node styles and typography are resolved once into `StyleFlyweight` caches (`presentation/style_flyweight.dart`), preventing per-frame layout recalculations.

