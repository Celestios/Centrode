import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/config.dart';
import '../../models/models.dart';
import '../../store/graph_data_query.dart';
import '../../presentation/view_state.dart';
import 'text/canvas_text_editor.dart';
import 'widgets/node_visual_constants.dart';
import 'widgets/node_rich_text.dart';

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
    final liveNode = context.select<GraphDataQuery, UiNode>(
      (c) => c.nodeLookup[node.id] ?? node,
    );

    final resolvedStyle = liveNode.resolvedStyle;
    if (resolvedStyle == null) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        viewState.sizeNotifier,
        viewState.isExpandedNotifier,
        viewState.dragWidthNotifier,
        viewState.lineCountNotifier,
        viewState.styleNotifier,
      ]),
      builder: (context, _) {
        final rawSize = viewState.sizeNotifier.value;
        final size = Size(
          viewState.dragWidthNotifier.value ?? rawSize.width,
          rawSize.height,
        );

        final double scale = NodeVisualConstants.fontScale(resolvedStyle.fontSize);
        final double padding = isEditing ? (2.0 * scale) : resolvedStyle.padding;

        final scaledBadgeFontSize = NodeVisualConstants.scaledBadgeFontSize(resolvedStyle.fontSize);
        final scaledShowMoreFontSize = NodeVisualConstants.scaledShowMoreFontSize(resolvedStyle.fontSize);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Color(resolvedStyle.bgColor),
                borderRadius: resolvedStyle.shape == 'circle'
                    ? BorderRadius.circular(size.width / 2)
                    : BorderRadius.circular(resolvedStyle.borderRadius),
                 border: Border.all(
                  color: Color(resolvedStyle.strokeColor),
                  width: resolvedStyle.strokeWidth.toDouble(),
                ),
                boxShadow: isEditing
                    ? [
                        BoxShadow(
                          color: Color(NodeVisualConstants.editingShadowColor),
                          blurRadius: 16 * scale,
                          spreadRadius: 4 * scale,
                        ),
                      ]
                    : (isSelected
                        ? [
                            BoxShadow(
                              color: Color(NodeVisualConstants.selectedShadowColor),
                              blurRadius: 8 * scale,
                              spreadRadius: 2 * scale,
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
                          ]),
              ),
              padding: EdgeInsets.all(padding),
              child: _buildNodeContent(
                context,
                liveNode,
                resolvedStyle,
                isEditing: isEditing,
                scaledBadgeFontSize: scaledBadgeFontSize,
                scaledShowMoreFontSize: scaledShowMoreFontSize,
              ),
            ),

            Positioned(
              right: 0,
              top: (liveNode is InfoUiNode &&
                  (liveNode.tags.isNotEmpty || liveNode.comments.isNotEmpty))
                  ? NodeVisualConstants.handleTopOffset * scale
                  : 0,
              bottom: 0,
              child: Container(
                width: AppConfig.node.resizeHandleVisualWidth * scale,
                decoration: BoxDecoration(
                  color: Color(NodeVisualConstants.handleColor),
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
                width: AppConfig.node.resizeHandleVisualWidth * scale,
                decoration: BoxDecoration(
                  color: Color(NodeVisualConstants.handleColor),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(resolvedStyle.borderRadius),
                  ),
                ),
              ),
            ),

            if (liveNode is InfoUiNode &&
                (liveNode.tags.isNotEmpty || liveNode.comments.isNotEmpty))
              Positioned(
                right:
                    (AppConfig.node.metadataSphereOffsetFromRight -
                    AppConfig.node.metadataSphereRadius) * scale,
                top:
                    (AppConfig.node.metadataSphereOffsetFromTop -
                    AppConfig.node.metadataSphereRadius) * scale,
                child: Container(
                  width: AppConfig.node.metadataSphereRadius * 2 * scale,
                  height: AppConfig.node.metadataSphereRadius * 2 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(
                      NodeVisualConstants.metadataSphereColor(
                        hasTags: liveNode.tags.isNotEmpty,
                        hasComments: liveNode.comments.isNotEmpty,
                      ),
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: AppConfig.node.metadataSphereStrokeWidth * scale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2 * scale,
                        offset: Offset(0, 1 * scale),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNodeContent(
    BuildContext context,
    UiNode liveNode,
    NodeStyle style, {
    required bool isEditing,
    double scaledBadgeFontSize = 10.0,
    double scaledShowMoreFontSize = 10.0,
  }) {
    final double scale = NodeVisualConstants.fontScale(style.fontSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: isEditing
              ? Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: CanvasTextEditor(
                      entityId: liveNode.id,
                      content: liveNode.content,
                      maxLines: null,
                      textStyle: TextStyle(
                        fontSize: style.fontSize,
                        fontFamily: style.fontFamily.isEmpty || style.fontFamily == 'System' ? null : style.fontFamily,
                        color: Color(style.textColor),
                      ),
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: NodeRichText(
                      content: liveNode.content,
                      baseStyle: TextStyle(
                        fontSize: style.fontSize,
                        fontFamily: style.fontFamily.isEmpty || style.fontFamily == 'System' ? null : style.fontFamily,
                        color: Color(style.textColor),
                      ),
                      isExpanded: viewState.isExpandedNotifier.value,
                    ),
                  ),
                ),
        ),
        if (viewState.lineCount > 3)
          Container(
            margin: EdgeInsets.only(
              top: (viewState.isExpandedNotifier.value ? 6.0 : 2.0) * scale,
            ),
            width: double.infinity,
            height: 16.0 * scale,
            decoration: BoxDecoration(
              color: Color(style.textColor).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4.0 * scale),
            ),
            child: Center(
              child: Icon(
                viewState.isExpandedNotifier.value
                    ? Icons.keyboard_double_arrow_up
                    : Icons.keyboard_double_arrow_down,
                size: 12.0 * scale,
                color: Color(style.textColor).withValues(alpha: 0.7),
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
                fontSize: scaledBadgeFontSize,
                fontWeight: FontWeight.bold,
                color: Color(style.textColor),
              ),
            ),
          ),
      ],
    );
  }
}
