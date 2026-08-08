import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/vertical_context_toolbar.dart';
import 'package:centrode/features/graph/presentation/strategies/relation_style_strategy.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/ui/widgets/overlays/vertical_text_format_toolbar.dart';
import 'text/content_text_editing_controller.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/shared/copy_buffer.dart';

class ContextToolbarOverlay extends StatelessWidget {
  final NodeRenderState renderState;
  final GraphDataQueryController queryController;
  final InteractionContext interactionContext;
  final ViewportController viewportController;
  final InteractionController interactionController;

  const ContextToolbarOverlay({
    super.key,
    required this.renderState,
    required this.queryController,
    required this.interactionContext,
    required this.viewportController,
    required this.interactionController,
  });

  Widget _buildDragHandle(
    Matrix4 matrix,
    ValueNotifier<Offset> offsetNotifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          final scale = matrix.getMaxScaleOnAxis();
          if (scale > 0) {
            offsetNotifier.value += details.delta / scale;
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              Icons.drag_handle,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMulti = renderState.selectedEntities.length > 1;
    final offsetNotifier = isMulti
        ? renderState.multiToolbarOffsetNotifier
        : renderState.toolbarOffsetNotifier;

    final List<Listenable> listenables = [
      offsetNotifier,
      viewportController.transformController,
      renderState.activeTextSelectionNotifier,
      renderState.activeLeftPanelNotifier,
      renderState.currentTextAlignNotifier,
    ];
    final List<NodeViewState> selectedViewStates = [];
    final List<UiRelation> selectedRelations = [];

    for (final id in renderState.selectedEntities) {
      final vs = renderState.viewStates[id];
      if (vs != null) {
        listenables.add(vs.positionNotifier);
        selectedViewStates.add(vs);
      } else {
        try {
          final rel = queryController.relations.firstWhere((r) => r.id == id);
          selectedRelations.add(rel);
          final sourceVs = renderState.viewStates[rel.fromNodeId];
          final targetVs = renderState.viewStates[rel.toNodeId];
          if (sourceVs != null) listenables.add(sourceVs.positionNotifier);
          if (targetVs != null) listenables.add(targetVs.positionNotifier);
        } catch (_) {}
      }
    }

    final isRelationOnly =
        selectedViewStates.isEmpty && selectedRelations.isNotEmpty;

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final isEditing = renderState.activeEditId != null;

        final double screenWidth = MediaQuery.of(context).size.width;
        final double screenHeight = MediaQuery.of(context).size.height;

        final matrix = viewportController.transformController.value;
        final scale = matrix.getMaxScaleOnAxis();

        // Dynamically retrieve panel layout thresholds
        final tabsController = context.watch<WorkspaceTabsController>();
        final session = tabsController.activeSession;
        final leftVisible = session.showLeftPanel.value;
        final activeLeftPanel = renderState.activeLeftPanelNotifier.value;

        final double leftThreshold = activeLeftPanel != LeftPanelType.none
            ? 356.0
            : (leftVisible ? 76.0 : 12.0);
        final double rightThreshold = MediaQuery.of(context).size.width - 12.0;
        final double topThreshold = 112.0; // Clear the ribbon area
        const double margin = 12.0; // Margin gap in canvas space

        if (isEditing) {
          final RawUuid editedId = renderState.activeEditId!;

          final vs = renderState.viewStates[editedId];
          final Offset anchorCanvas;
          final double entityWidth;

          if (vs != null) {
            final size = Size(
              vs.dragWidthNotifier.value ?? vs.sizeNotifier.value.width,
              vs.sizeNotifier.value.height,
            );
            anchorCanvas = vs.positionNotifier.value;
            entityWidth = size.width;
          } else {
            UiRelation? rel;
            try {
              rel = queryController.relations.firstWhere(
                (r) => r.id == editedId,
              );
            } catch (_) {}

            if (rel != null) {
              final cached = queryController.relationEngine.cache[editedId];
              if (cached != null) {
                anchorCanvas = Offset(
                  cached.labelPosition.x,
                  cached.labelPosition.y,
                );
                entityWidth = 0;
              } else {
                return const SizedBox.shrink();
              }
            } else {
              return const SizedBox.shrink();
            }
          }

          final offset = offsetNotifier.value;
          final defaultOffset = isMulti
              ? AppConfig.toolbar.multiOffset
              : AppConfig.toolbar.singleOffset;
          final dragDelta = offset - defaultOffset;
          final nodeLeftCanvas = anchorCanvas + dragDelta;

          final screenPosition = MatrixUtils.transformPoint(
            matrix,
            nodeLeftCanvas,
          );

          const double toolbarWidth = 76;
          const double toolbarHeight = 430; // Two-column layout

          // Try left placement first
          final double leftX =
              screenPosition.dx - toolbarWidth - (margin * scale);
          // Try right placement
          final double rightX =
              screenPosition.dx + (entityWidth * scale) + (margin * scale);

          bool useRight = false;
          if (leftX < leftThreshold) {
            useRight = true;
          }

          final double maxX1 = math.max(leftThreshold, rightThreshold - toolbarWidth);
          final double maxY1 = math.max(topThreshold, screenHeight - toolbarHeight - 12.0);

          double toolbarLeft = useRight ? rightX : leftX;
          toolbarLeft = toolbarLeft
              .clamp(leftThreshold, maxX1)
              .toDouble();
          double toolbarTop = screenPosition.dy
              .clamp(topThreshold, maxY1)
              .toDouble();

          return Positioned(
            left: toolbarLeft,
            top: toolbarTop,
            child: VerticalTextFormatToolbar(
              onToggleBold: () {
                renderState.applyFormatCallback?.call(TextFormatType.bold);
              },
              onToggleItalic: () {
                renderState.applyFormatCallback?.call(TextFormatType.italic);
              },
              onToggleUnderline: () {
                renderState.applyFormatCallback?.call(TextFormatType.underline);
              },
              onToggleHeader1: () {
                renderState.toggleHeadingCallback?.call(
                  TextFormatType.heading1,
                );
              },
              onToggleHeader2: () {
                renderState.toggleHeadingCallback?.call(
                  TextFormatType.heading2,
                );
              },
              onToggleHeader3: () {
                renderState.toggleHeadingCallback?.call(
                  TextFormatType.heading3,
                );
              },
              onToggleBlockquote: () {
                renderState.toggleHeadingCallback?.call(
                  TextFormatType.blockquote,
                );
              },
              onToggleCodeBlock: () {
                renderState.toggleHeadingCallback?.call(
                  TextFormatType.codeBlock,
                );
              },
              onToggleBulletList: () {
                renderState.toggleHeadingCallback?.call(
                  TextFormatType.bulletList,
                );
              },
              onToggleOrderedList: () {
                renderState.toggleHeadingCallback?.call(
                  TextFormatType.orderedList,
                );
              },
              onClearBlockFormat: () {
                renderState.clearBlockFormatCallback?.call();
              },
              onSelectFontFamily: (fontFamily) {
                renderState.setFontFamilyCallback?.call(fontFamily);
              },
              onCycleTextColor: () {
                renderState.cycleTextColorCallback?.call();
              },
              onToggleHighlight: () {
                renderState.toggleHighlightCallback?.call();
              },
              onCycleHighlightColor: () {
                renderState.cycleHighlightColorCallback?.call();
              },
              onCycleTextAlign: () {
                renderState.cycleTextAlignCallback?.call();
              },
              currentTextAlign: renderState.currentTextAlignNotifier.value,
              onIncreaseFontSize: () {
                interactionController.updateNodeStyle(editedId, (style) {
                  return style.copyWith(
                    fontSize: (style.fontSize + 2.0).clamp(
                      AppConfig.node.minFontSize,
                      AppConfig.node.maxFontSize,
                    ),
                  );
                });
              },
              onDecreaseFontSize: () {
                interactionController.updateNodeStyle(editedId, (style) {
                  return style.copyWith(
                    fontSize: (style.fontSize - 2.0).clamp(
                      AppConfig.node.minFontSize,
                      AppConfig.node.maxFontSize,
                    ),
                  );
                });
              },
              onAddHyperlink: () async {
                final url = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController(text: 'https://');
                    return AlertDialog(
                      title: const Text('Insert Hyperlink'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Enter URL (e.g., https://example.com)',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text),
                          child: const Text('Insert'),
                        ),
                      ],
                    );
                  },
                );
                if (url != null && url.isNotEmpty) {
                  renderState.applyFormatCallback?.call(
                    TextFormatType.link,
                    url: url,
                  );
                }
              },
              dragHandle: _buildDragHandle(matrix, offsetNotifier),
            ),
          );
        }

        Offset anchor = Offset.zero;
        if (selectedViewStates.isNotEmpty || selectedRelations.isNotEmpty) {
          anchor =
              renderState.calculateToolbarAnchor(
                renderState.selectedEntities,
              ) ??
              Offset.zero;
        }

        final offset = offsetNotifier.value;

        // Calculate the base node position in canvas space including user's drag delta
        final defaultOffset = isMulti
            ? AppConfig.toolbar.multiOffset
            : AppConfig.toolbar.singleOffset;
        final dragDelta = offset - defaultOffset;
        final nodeLeftCanvas = anchor + dragDelta;

        final nodeLeftScreen = MatrixUtils.transformPoint(
          matrix,
          nodeLeftCanvas,
        ).dx;

        final nodeTopScreen = MatrixUtils.transformPoint(
          matrix,
          nodeLeftCanvas,
        ).dy;

        final nodeIds = renderState.selectedEntities
            .where((id) => queryController.nodeLookup.containsKey(id))
            .toList();
        final canSaveTemplate = nodeIds.isNotEmpty;
        final RawUuid? singleNodeId = (!isMulti && nodeIds.length == 1)
            ? nodeIds.first
            : null;

        const double toolbarWidth = 520;
        const double toolbarHeight = 360;

        final double nodeWidth = selectedViewStates.isNotEmpty
            ? (selectedViewStates.first.dragWidthNotifier.value ??
                  selectedViewStates.first.sizeNotifier.value.width)
            : 150.0;

        // Try left placement first
        final double leftX = nodeLeftScreen - toolbarWidth - (margin * scale);
        // Try right placement
        final double rightX =
            nodeLeftScreen + (nodeWidth * scale) + (margin * scale);

        bool useRight = false;
        if (leftX < leftThreshold) {
          useRight = true;
        }

        final double maxX2 = math.max(leftThreshold, rightThreshold - toolbarWidth);
        final double maxY2 = math.max(topThreshold, screenHeight - toolbarHeight - 12.0);

        double toolbarLeft = useRight ? rightX : leftX;

        // Clamp X and Y coordinates to keep the toolbar fully visible on screen
        toolbarLeft = toolbarLeft
            .clamp(leftThreshold, maxX2)
            .toDouble();
        double toolbarTop = nodeTopScreen
            .clamp(topThreshold, maxY2)
            .toDouble();

        // If the selected node itself is completely off-screen, hide the toolbar
        if (selectedViewStates.isNotEmpty) {
          final vs = selectedViewStates.first;
          final s = Size(
            vs.dragWidthNotifier.value ?? vs.sizeNotifier.value.width,
            vs.sizeNotifier.value.height,
          );
          final tl = MatrixUtils.transformPoint(
            matrix,
            vs.positionNotifier.value,
          );
          final br = MatrixUtils.transformPoint(
            matrix,
            vs.positionNotifier.value + Offset(s.width, s.height),
          );
          final nodeScreenRect = Rect.fromPoints(tl, br);
          final screenRect = Rect.fromLTWH(0, 0, screenWidth, screenHeight);
          if (!screenRect.overlaps(nodeScreenRect)) {
            return const SizedBox.shrink();
          }
        }

        return Positioned(
          left: toolbarLeft,
          top: toolbarTop,
          child: VerticalContextToolbar(
            positionOnRight: useRight,
            onDelete: renderState.deleteSelectedEntities,
            onCopy: () {
              final copyBuffer = context.read<CopyBuffer>();
              final nodeIds = renderState.selectedEntities
                  .where((id) => queryController.nodeLookup.containsKey(id))
                  .toList();
              if (nodeIds.isNotEmpty) {
                copyBuffer.copy(nodeIds, queryController);
              }
            },
            isMulti: isMulti,
            isRelationOnly: isRelationOnly,
            canSaveTemplate: canSaveTemplate,
            singleNodeId: singleNodeId,
            onRelationLayoutChanged: (layoutType) {
              for (final rel in selectedRelations) {
                interactionContext.onRelationUpdateLayout(
                  rel.id,
                  strategyType: layoutType,
                );
              }
            },
            onRelationStrokePatternChanged: (pattern) {
              for (final rel in selectedRelations) {
                final currentStyle =
                    rel.style ?? RelationStyleStrategy.resolveStyle(rel);
                interactionContext.onRelationUpdateStyle(
                  rel.id,
                  currentStyle.copyWith(strokePattern: pattern),
                );
              }
            },
            onRelationBodyStrategyChanged: (bodyStrategy) {
              for (final rel in selectedRelations) {
                final currentStyle =
                    rel.style ?? RelationStyleStrategy.resolveStyle(rel);
                interactionContext.onRelationUpdateStyle(
                  rel.id,
                  currentStyle.copyWith(bodyStrategy: bodyStrategy),
                );
              }
            },
            onStartShapeChanged: (shape) {
              for (final rel in selectedRelations) {
                final currentStyle =
                    rel.style ?? RelationStyleStrategy.resolveStyle(rel);
                interactionContext.onRelationUpdateStyle(
                  rel.id,
                  currentStyle.copyWith(startShape: shape),
                );
              }
            },
            onEndShapeChanged: (shape) {
              for (final rel in selectedRelations) {
                final currentStyle =
                    rel.style ?? RelationStyleStrategy.resolveStyle(rel);
                interactionContext.onRelationUpdateStyle(
                  rel.id,
                  currentStyle.copyWith(endShape: shape),
                );
              }
            },
            onDrawConnection: () {
              final nodeIds = renderState.selectedEntities
                  .where((id) => queryController.nodeLookup.containsKey(id))
                  .toList();
              if (nodeIds.isNotEmpty) {
                final vs = renderState.viewStates[nodeIds.first];
                final initialPos = vs != null ? vs.rect.center : Offset.zero;
                interactionController.startRelationDrawing(
                  nodeIds.toSet(),
                  initialPos,
                );
              }
            },
            onDecreaseFontSize: () {
              if (singleNodeId != null) {
                interactionController.updateNodeStyle(singleNodeId, (style) {
                  return style.copyWith(
                    fontSize: (style.fontSize - 2.0).clamp(
                      AppConfig.node.minFontSize,
                      AppConfig.node.maxFontSize,
                    ),
                  );
                });
              }
            },
            onIncreaseFontSize: () {
              if (singleNodeId != null) {
                interactionController.updateNodeStyle(singleNodeId, (style) {
                  return style.copyWith(
                    fontSize: (style.fontSize + 2.0).clamp(
                      AppConfig.node.minFontSize,
                      AppConfig.node.maxFontSize,
                    ),
                  );
                });
              }
            },
            onToggleFontFamily: () {
              if (singleNodeId != null) {
                interactionController.updateNodeStyle(singleNodeId, (style) {
                  final nextFont = style.fontFamily == 'Roboto'
                      ? 'Inter'
                      : 'Roboto';
                  return style.copyWith(fontFamily: nextFont);
                });
              }
            },
            onCycleTextColor: () {
              if (singleNodeId != null) {
                final textColors = AppConfig.visuals.textColors;
                interactionController.updateNodeStyle(singleNodeId, (style) {
                  final index = textColors.indexOf(style.textColor);
                  final nextColor = textColors[(index + 1) % textColors.length];
                  return style.copyWith(textColor: nextColor);
                });
              }
            },
            onShapeChanged: (shape) {
              if (singleNodeId != null) {
                interactionController.updateNodeStyle(singleNodeId, (style) {
                  return style.copyWith(shape: shape);
                });
              }
            },
            onSaveTemplate: () {
              interactionController.environment.onSaveTemplate();
            },
            dragHandle: _buildDragHandle(matrix, offsetNotifier),
          ),
        );
      },
    );
  }
}
