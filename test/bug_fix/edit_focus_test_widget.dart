// test/bug_fix/edit_focus_test_widget.dart
library;

/// ============================================================================
/// DIAGNOSTIC & RESOLUTION REPORT: CANVAS NODE TEXT EDIT FOCUS LOSS
/// ============================================================================
///
/// 1. THE PROBLEM
/// --------------
/// When entering inline edit mode on a canvas node (by double-clicking it) and 
/// attempting to click or drag the mouse to highlight/select a subset of text, 
/// the text editor would fail to highlight/select text or would lose focus 
/// altogether. This issue only occurred when the canvas was panned or zoomed 
/// away from the center (origin area), whereas it worked fine near the origin.
///
/// 2. DIAGNOSTIC ANALYSIS
/// ----------------------
/// - Isolated Test Widget: This diagnostic test widget (`edit_focus_test_widget.dart`) 
///   was created to render a `NodeWidget` directly with `isEditing: true` in 
///   isolation, completely removed from the canvas transformation and FSM gesture 
///   handlers. In this isolation, mouse clicks, selection dragging, and text editing 
///   worked perfectly, indicating that the `CanvasTextEditor` / `EditableText` 
///   logic itself was functional.
/// - Hit-Test Clipping: The root cause lay in the Flutter hit-testing system's 
///   interaction with transformed rendering layers. 
///   - The canvas layers (`GridLayer`, `RelationLayer`, `NodeLayer`, `OverlayLayer`) 
///     are children of an `UnboundedStack` inside a `CanvasInteractiveViewer`.
///   - When panned or zoomed, `CanvasInteractiveViewer` applies a matrix 
///     transformation to the `UnboundedStack`, shifting the canvas coordinate system.
///   - While `UnboundedStack` overrides `hitTest` to bypass local size boundary 
///     constraints, `NodeLayer` and `OverlayLayer` were implemented using standard 
///     Flutter `Stack` widgets.
///   - Standard `Stack` widgets use the default `RenderBox.hitTest`, which checks 
///     `if (_size.contains(position))` in local coordinates.
///   - Since these layer stacks were unpositioned children of the parent stack, 
///     their layout sizes were constrained to the size of the viewport (e.g., 1920x1080).
///   - When the canvas was panned, the pointer's canvas coordinates would fall 
///     outside the `1920x1080` local size bounds of `NodeLayer` / `OverlayLayer`.
///   - As a result, the standard `Stack.hitTest` returned `false` immediately 
///     without checking any children, preventing the pointer events from ever 
///     reaching the active editing `NodeWidget` / `CanvasTextEditor` overlays.
///
/// 3. THE RESOLUTION
/// -----------------
/// - Layer Alignment: Aligned `NodeLayer` and `OverlayLayer` with `RelationLayer` 
///   by replacing the standard `Stack` widgets with `UnboundedStack`.
/// - Unbounded Hit-Testing: Since `UnboundedStack` (via `RenderUnboundedStack`) 
///   bypasses local size boundary constraints during hit-testing and propagates 
///   pointer events directly to children, pointer events now successfully bubble 
///   down to the active editing `CanvasTextEditor` and metadata overlays anywhere 
///   on the infinite, transformed canvas.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/features/graph/ui/canvas/node_widget.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/features/graph/store/graph_data_query.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mocktail/mocktail.dart';

class MockGraphDataQuery extends Mock with ChangeNotifier implements GraphDataQuery {
  final Map<String, UiNode> _nodes = {};

  MockGraphDataQuery(UiNode node) {
    _nodes[node.id] = node;
  }

  @override
  Map<String, UiNode> get nodeLookup => _nodes;

  List<UiNode> get nodes => _nodes.values.toList();

  @override
  List<UiRelation> get relations => [];

  @override
  Map<String, UiRelation> get relationLookup => {};
}

class MockThemeController extends Mock with ChangeNotifier implements ThemeController {
  @override
  GraphTheme get currentGraphTheme => const GraphTheme(id: 'default', name: 'Default');

  @override
  Future<void> selectTheme(String themeId) async {}

  List<GraphTheme> get availableThemes => [];
}

class MockNodeRenderState extends Mock with ChangeNotifier implements NodeRenderState {
  @override
  final ValueNotifier<TextAlign> currentTextAlignNotifier = ValueNotifier(TextAlign.center);

  @override
  final ValueNotifier<String?> hoveredNodeMetadataNotifier = ValueNotifier(null);

  @override
  Function(dynamic, {String? url})? applyFormatCallback;
  @override
  Function(dynamic)? toggleHeadingCallback;
  @override
  VoidCallback? clearBlockFormatCallback;
  @override
  VoidCallback? cycleFontFamilyCallback;
  @override
  Function(String)? setFontFamilyCallback;
  @override
  VoidCallback? cycleTextColorCallback;
  @override
  Function({String? colorUrl})? toggleHighlightCallback;
  @override
  VoidCallback? cycleHighlightColorCallback;
  @override
  VoidCallback? cycleTextAlignCallback;

  @override
  void updateActiveTextSelection(TextSelection? selection) {}

  @override
  void updateEntityTextLive(String id, dynamic content) {}

  @override
  void cancelActiveEdit() {}

  @override
  void commitEntityText(String id, dynamic content, {dynamic originalTextOrContent}) {}
}

class DiagnosticFocusNodeListener extends StatefulWidget {
  final Widget child;
  const DiagnosticFocusNodeListener({super.key, required this.child});

  @override
  State<DiagnosticFocusNodeListener> createState() => _DiagnosticFocusNodeListenerState();
}

class _DiagnosticFocusNodeListenerState extends State<DiagnosticFocusNodeListener> {
  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: FocusTraversalGroup(
        child: Focus(
          debugLabel: 'DiagnosticFocusNodeListenerParent',
          onFocusChange: (hasFocus) {
            debugPrint('[DiagnosticFocusNodeListener] Focus state changed: parent hasFocus=$hasFocus');
          },
          child: widget.child,
        ),
      ),
    );
  }
}

void main() {
  debugPrint('[edit_focus_test_widget] Starting isolated NodeWidget test application...');

  final node = InfoUiNode(
    id: 'debug-node-1',
    position: const Offset(100, 100),
    size: const Size(250, 150),
    content: ContentFactory.fromText('Click and try to select/highlight only this text using mouse drag. Let\'s see if it loses focus!'),
    resolvedStyle: const NodeStyle(
      bgColor: 0xFFF5F5F5,
      strokeColor: 0xFF2196F3,
      strokeWidth: 2,
      fontFamily: 'System',
      fontSize: 14,
      shape: 'rectangle',
      width: 250,
      height: 150,
      textColor: 0xFF333333,
      borderRadius: 8.0,
      padding: 12.0,
      shadowColor: 0x20000000,
      shadowBlur: 4,
      shadowSpread: 1,
      shadowOffsetX: 0,
      shadowOffsetY: 2,
      strategyType: 'info',
    ),
  );

  final viewState = NodeViewState(node);

  final mockQuery = MockGraphDataQuery(node);
  final mockTheme = MockThemeController();
  final mockRender = MockNodeRenderState();

  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Node Edit Focus Debugger'),
        ),
        body: MultiProvider(
          providers: [
            InheritedProvider<GraphDataQuery>.value(value: mockQuery),
            ChangeNotifierProvider<ThemeController>.value(value: mockTheme),
            ChangeNotifierProvider<NodeRenderState>.value(value: mockRender),
          ],
          child: DiagnosticFocusNodeListener(
            child: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: HighlightFrame(
                    isEditing: true,
                    isSelected: true,
                    borderRadius: node.resolvedStyle?.borderRadius ?? 8.0,
                    shape: node.resolvedStyle?.shape ?? 'rectangle',
                    size: node.size,
                    scale: 1.0,
                    child: NodeWidget(
                      node: node,
                      viewState: viewState,
                      isSelected: true,
                      isEditing: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
