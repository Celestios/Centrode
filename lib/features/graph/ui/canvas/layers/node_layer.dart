import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/node_render_state.dart';
import '../../../presentation/viewport_state.dart';
import '../../../models/models.dart';
import '../../../presentation/strategies/node_layout_strategy.dart';
import '../node_widget.dart';
import '../widgets/draw_node_widget.dart';
import '../widgets/highlight_frame.dart';
import '../widgets/node_visual_constants.dart';
import '../text/canvas_text_editor.dart';
import '../widgets/canvas_nodes_host.dart';
import '../painters/node_render_entry.dart';
import '../painters/container_boundary_painter.dart';

export '../painters/node_render_entry.dart';

class NodeLayer extends StatelessWidget {
  const NodeLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final query = context.read<GraphDataQuery>();
    final uiState = context.read<NodeRenderState>();
    final viewport = context.read<ViewportController>();

    return ListenableBuilder(
      listenable: Listenable.merge([
        uiState,
        viewport.visibleNodeIds,
        viewport.viewportStateNotifier,
        viewport.activeScopeNotifier,
      ]),
      builder: (context, _) {
        final activeScope = viewport.activeScopeNotifier.value;
        final visibleIds = viewport.visibleNodeIds.value;
        final cameraScale = viewport.viewportStateNotifier.value.scale;

        final renderStack = uiState.zOrder.where((id) {
          final node = query.nodeLookup[id];
          if (node == null) return false;
          if (!query.isNodeInScope(id, activeScope)) return false;
          final bool scopeMatches =
              visibleIds.any((vId) => query.isNodeInScope(vId, activeScope));
          return !scopeMatches || visibleIds.contains(id);
        }).toList();

        final entries = <NodeRenderEntry>[];
        NodeRenderEntry? editingEntry;

        for (final id in renderStack) {
          final node = query.nodeLookup[id];
          final viewState = uiState.viewStates[id];
          if (node == null || viewState == null) continue;
          final isSelected = uiState.selectedEntities.contains(id);
          final isEditing = uiState.activeEditId == id;

          final entry = NodeRenderEntry(
            node: node,
            viewState: viewState,
            isSelected: isSelected,
            isEditing: isEditing,
          );

          if (isEditing) {
            editingEntry = entry;
          }
          entries.add(entry);
        }

        return UnboundedStack(
          clipBehavior: Clip.none,
          children: [
            if (activeScope is ContainerViewportScope)
              Builder(
                builder: (context) {
                  final container = query.nodeLookup[activeScope.containerId]
                      as ContainerUiNode?;
                  final vs = uiState.viewStates[activeScope.containerId];
                  final effectiveOuterSize = (vs != null &&
                          vs.sizeNotifier.value.width > 0 &&
                          vs.sizeNotifier.value.height > 0)
                      ? Size(
                          vs.dragWidthNotifier.value ??
                              vs.sizeNotifier.value.width,
                          vs.sizeNotifier.value.height,
                        )
                      : (activeScope.outerSize.width > 0 &&
                              activeScope.outerSize.height > 0)
                          ? activeScope.outerSize
                          : (container != null)
                              ? const DefaultNodeLayoutStrategy()
                                  .calculateSize(container)
                                  .size
                              : const Size(300.0, 180.0);
                  final aspectRatio = effectiveOuterSize.height /
                      (effectiveOuterSize.width > 0
                          ? effectiveOuterSize.width
                          : 1.0);
                  final internalSize = Size(1600.0, 1600.0 * aspectRatio);
                  return Positioned(
                    left: 0,
                    top: 0,
                    width: internalSize.width,
                    height: internalSize.height,
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: internalSize,
                          painter: ContainerBoundaryPainter(
                            container: container,
                            effectiveSize: effectiveOuterSize,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            RepaintBoundary(
              child: CanvasNodesHost(
                entries: entries,
                hoveredNodeNotifier: uiState.hoveredNodeNotifier,
                cameraScale: cameraScale,
                activeScope: activeScope,
                nodeLookup: query.nodeLookup,
                relations: query.relations,
                relationEngine: query.relationEngine,
              ),
            ),
            if (editingEntry != null)
              Builder(
                builder: (context) {
                  final entry = editingEntry!;
                  return ListenableBuilder(
                    listenable: Listenable.merge([
                      entry.viewState.positionNotifier,
                      entry.viewState.sizeNotifier,
                      entry.viewState.dragWidthNotifier,
                      uiState.hoveredNodeNotifier,
                    ]),
                    builder: (context, _) {
                      final pos = entry.viewState.positionNotifier.value;
                      final rawSize = entry.viewState.sizeNotifier.value;
                      final size = Size(
                        entry.viewState.dragWidthNotifier.value ??
                            rawSize.width,
                        rawSize.height,
                      );
                      final resolvedStyle = entry.node.resolvedStyle;
                      final borderRadius =
                          resolvedStyle?.borderRadius ?? 8.0;
                      final shape = resolvedStyle?.shape ?? 'rectangle';
                      final double fontSize =
                          resolvedStyle?.fontSize ?? 14.0;
                      final double scale =
                          NodeVisualConstants.fontScale(fontSize);
                      final isHovered =
                          uiState.hoveredNodeNotifier.value == entry.node.id;

                      if (entry.node is FrameUiNode) {
                        final frameNode = entry.node as FrameUiNode;
                        return Positioned(
                          key: ValueKey('edit_${entry.node.id}'),
                          left: pos.dx + (size.width / 2),
                          top: pos.dy - 32.0 * scale,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, 0.0),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 4 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: Color(resolvedStyle?.bgColor != 0 && resolvedStyle?.bgColor != 0x00000000
                                    ? resolvedStyle!.bgColor
                                    : 0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(6.0 * scale),
                                border: Border.all(
                                  color: Color(resolvedStyle?.strokeColor != 0
                                      ? resolvedStyle!.strokeColor
                                      : 0xFF00E5FF),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(NodeVisualConstants.editingShadowColor),
                                    blurRadius: 12 * scale,
                                    spreadRadius: 2 * scale,
                                  ),
                                ],
                              ),
                              child: IntrinsicWidth(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 80 * scale,
                                    maxWidth: 320 * scale,
                                  ),
                                  child: CanvasTextEditor(
                                    entityId: frameNode.id,
                                    content: frameNode.content,
                                    maxLines: 1,
                                    textStyle: TextStyle(
                                      fontSize: fontSize * scale,
                                      color: Color(resolvedStyle?.textColor != 0
                                          ? resolvedStyle!.textColor
                                          : 0xFF000000),
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final Widget editWidget;
                      if (entry.node is DrawingUiNode) {
                        editWidget = DrawNodeWidget(
                          node: entry.node as DrawingUiNode,
                          viewState: entry.viewState,
                          isSelected: entry.isSelected,
                          isEditing: true,
                        );
                      } else {
                        editWidget = HighlightFrame(
                          isEditing: true,
                          isSelected: entry.isSelected,
                          isHovered: isHovered,
                          borderRadius: borderRadius,
                          shape: shape,
                          size: size,
                          scale: scale,
                          child: NodeWidget(
                            viewState: entry.viewState,
                            node: entry.node,
                            isSelected: entry.isSelected,
                            isEditing: true,
                          ),
                        );
                      }

                      return Positioned(
                        key: ValueKey('edit_${entry.node.id}'),
                        left: pos.dx,
                        top: pos.dy,
                        child: editWidget,
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
