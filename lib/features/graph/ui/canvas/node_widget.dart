// lib/features/graph/ui/canvas/node_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/graph_metrics.dart';
import '../../models/models.dart';
import '../../store/graph_data_query.dart';
import '../../presentation/view_state.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'canvas_text_editor.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// A passive node widget that renders exactly what the domain instructs.
///
/// This widget is purely presentational – all interaction handling
/// is delegated to the InteractionController via the Listener in GraphCanvas.
///
/// Style resolution is no longer performed here; instead the widget reads
/// `liveNode.resolvedStyle` which is pre‑computed by the StyleManager.
/// When no resolved style is available (e.g. during a brief transition),
/// a safe default `NodeStyle()` is used.
class NodeWidget extends StatelessWidget {
  final UiNode node;
  final NodeViewState viewState;
  final bool isDeleteMenuVisible;
  final VoidCallback onDelete;
  final bool isSelected;
  final bool isEditing;

  const NodeWidget({
    super.key,
    required this.node,
    required this.viewState,
    required this.isDeleteMenuVisible,
    required this.onDelete,
    required this.isSelected,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    // Reactively select the canonical node from the central store.
    // This prevents the widget from rendering stale aesthetics (like old width)
    // when the FSM drops the volatile drag state before the parent layer rebuilds.
    final liveNode = context.select<GraphDataQuery, UiNode>(
      (c) => c.nodeLookup[node.id] ?? node,
    );

    // ── Pure domain‑driven style (no theme lookup) ─────────────
    // In the final design `liveNode.resolvedStyle` will always be set
    // after the StyleManager runs.  Until that infrastructure is in
    // place we fall back to a sensible default.
    final NodeStyle resolvedStyle =
        liveNode.resolvedStyle ??
        NodeStyle(
          bgColor: 0xFFFFFFFF,
          strokeColor: 0xFF000000,
          strokeWidth: 1,
          fontFamily: AppConfig.visuals.defaultFont,
          fontSize: 12.0,
          shape: AppConfig.visuals.defaultShape,
          width: AppConfig.node.defaultWidth.toInt(),
          height: AppConfig.node.defaultSize.height.toInt(),
        );

    // We merge the notifiers so the widget repaints when position, size,
    // or expanded state changes.
    return ListenableBuilder(
      listenable: Listenable.merge([
        viewState.positionNotifier,
        viewState.sizeNotifier,
        viewState.isExpandedNotifier,
        viewState.dragWidthNotifier,
      ]),
      builder: (context, _) {
        final pos = viewState.positionNotifier.value;

        final size = viewState.sizeNotifier.value;

        return Transform.translate(
          offset: pos,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Main Visual Body ──────────────────────────
              Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  color: Color(resolvedStyle.bgColor),
                  borderRadius: resolvedStyle.shape == 'circle'
                      ? BorderRadius.circular(size.width / 2)
                      : BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isSelected
                        ? AppConfig.visuals.selectionAccent
                        : Color(resolvedStyle.strokeColor),
                    width: isSelected
                        ? 2.5
                        : resolvedStyle.strokeWidth.toDouble(),
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x4442A5F5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                ),
                padding: const EdgeInsets.all(8.0),
                child: isEditing
                    ? CanvasTextEditor(
                        entityId: liveNode.id,
                        initialText: liveNode.text,
                        maxLines: null,
                        textStyle: TextStyle(
                          fontSize: resolvedStyle.fontSize,
                          fontFamily: resolvedStyle.fontFamily,
                        ),
                      )
                    : _buildNodeContent(context, liveNode, resolvedStyle),
              ),

              // ── Resize Handle Visual (Right Edge) ─────────
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: AppConfig.node.resizeHandleVisualWidth,
                  decoration: BoxDecoration(
                    // A nearly‑invisible colour that the hit‑tester sees.
                    color: Colors.black.withValues(alpha: 1),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodeContent(
    BuildContext context,
    UiNode liveNode,
    NodeStyle style,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            liveNode.text.isEmpty ? "Empty Node" : liveNode.text,
            style: TextStyle(
              fontSize: style.fontSize,
              fontFamily: style.fontFamily,
            ),
            overflow: TextOverflow.fade,
            maxLines: viewState.isExpandedNotifier.value
                ? null
                : AppConfig.node.collapsedLineLimit,
          ),
        ),
        if (viewState.lineCount > 3)
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(
              viewState.isExpandedNotifier.value ? "Show Less" : "Show More",
              style: const TextStyle(
                fontSize: 10,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (liveNode is TaskUiNode)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              (liveNode).state,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
