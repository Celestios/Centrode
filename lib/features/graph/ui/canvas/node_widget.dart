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
  final bool isSelected;
  final bool isEditing;

  const NodeWidget({
    super.key,
    required this.node,
    required this.viewState,
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

    final resolvedStyle = liveNode.resolvedStyle;
    if (resolvedStyle == null) {
      return const SizedBox.shrink();
    }

    // We merge the notifiers so the widget repaints when position, size,
    // or expanded state changes.
    return ListenableBuilder(
      listenable: Listenable.merge([
        viewState.positionNotifier,
        viewState.sizeNotifier,
        viewState.isExpandedNotifier,
        viewState.dragWidthNotifier,
        viewState.lineCountNotifier,
      ]),
      builder: (context, _) {
        final pos = viewState.positionNotifier.value;
        final rawSize = viewState.sizeNotifier.value;
        final size = Size(
          viewState.dragWidthNotifier.value ?? rawSize.width,
          rawSize.height,
        );

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
                      : BorderRadius.circular(resolvedStyle.borderRadius),
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
                            color: Color(resolvedStyle.shadowColor),
                            blurRadius: resolvedStyle.shadowBlur,
                            spreadRadius: resolvedStyle.shadowSpread,
                            offset: Offset(
                              resolvedStyle.shadowOffsetX,
                              resolvedStyle.shadowOffsetY,
                            ),
                          ),
                        ],
                ),
                padding: EdgeInsets.all(resolvedStyle.padding),
                child: isEditing
                    ? CanvasTextEditor(
                        entityId: liveNode.id,
                        initialText: liveNode.text,
                        maxLines: null,
                        textStyle: TextStyle(
                          fontSize: resolvedStyle.fontSize,
                          fontFamily: resolvedStyle.fontFamily,
                          color: Color(resolvedStyle.textColor),
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
                    color: Colors.black.withValues(alpha: 0.01),
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(resolvedStyle.borderRadius),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: AppConfig.node.resizeHandleVisualWidth,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.01),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(resolvedStyle.borderRadius),
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
          child: Center(
            child: Text(
              liveNode.text.isEmpty ? "Empty Node" : liveNode.text,
              style: TextStyle(
                fontSize: style.fontSize,
                fontFamily: style.fontFamily,
                color: Color(style.textColor),
              ),
              overflow: TextOverflow.fade,
              maxLines: viewState.isExpandedNotifier.value
                  ? null
                  : AppConfig.node.collapsedLineLimit,
            ),
          ),
        ),
        if (viewState.lineCount > 3)
          Container(
            margin: const EdgeInsets.only(top: 0.0),
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 1.0),
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
              color: Color(style.bgColor).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Color(style.textColor).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              (liveNode).state,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(style.textColor),
              ),
            ),
          ),
      ],
    );
  }
}
