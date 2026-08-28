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

class ContextToolbarConstants {
  static const double panelExpandedWidth = 356.0;
  static const double panelCollapsedWidth = 76.0;
  static const double defaultMargin = 12.0;
  static const double topThreshold = 112.0;
  static const double textToolbarWidth = 40.0;
  static const double textToolbarHeight = 430.0;
  static const double visualToolbarWidth = 48.0;
  static const double toolbarStackWidth = 520.0;
  static const double toolbarHeight = 360.0;
}

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
        final rel = renderState.getRelation(id);
        if (rel != null) {
          selectedRelations.add(rel);
          final sourceVs = renderState.viewStates[rel.fromNodeId];
          final targetVs = renderState.viewStates[rel.toNodeId];
          if (sourceVs != null) listenables.add(sourceVs.positionNotifier);
          if (targetVs != null) listenables.add(targetVs.positionNotifier);
        }
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

        final tabsController = context.watch<WorkspaceTabsController>();
        final session = tabsController.activeSession;
        final leftVisible = session.showLeftPanel.value;
        final activeLeftPanel = renderState.activeLeftPanelNotifier.value;

        final double leftThreshold = activeLeftPanel != LeftPanelType.none
            ? ContextToolbarConstants.panelExpandedWidth
            : (leftVisible
                ? ContextToolbarConstants.panelCollapsedWidth
                : ContextToolbarConstants.defaultMargin);
        final double rightThreshold =
            screenWidth - ContextToolbarConstants.defaultMargin;
        const double topThreshold = ContextToolbarConstants.topThreshold;
        const double margin = ContextToolbarConstants.defaultMargin;

        if (isEditing) {
          return _buildTextFormattingToolbar(
            context,
            matrix: matrix,
            offsetNotifier: offsetNotifier,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            leftThreshold: leftThreshold,
            rightThreshold: rightThreshold,
            topThreshold: topThreshold,
            margin: margin,
          );
        }

        return _buildContextToolbar(
          context,
          matrix: matrix,
          offsetNotifier: offsetNotifier,
          selectedViewStates: selectedViewStates,
          selectedRelations: selectedRelations,
          isMulti: isMulti,
          isRelationOnly: isRelationOnly,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          leftThreshold: leftThreshold,
          topThreshold: topThreshold,
          margin: margin,
        );
      },
    );
  }

  Widget _buildTextFormattingToolbar(
    BuildContext context, {
    required Matrix4 matrix,
    required ValueNotifier<Offset> offsetNotifier,
    required double screenWidth,
    required double screenHeight,
    required double leftThreshold,
    required double rightThreshold,
    required double topThreshold,
    required double margin,
  }) {
    final RawUuid editedId = renderState.activeEditId!;
    final vs = renderState.viewStates[editedId];

    if (vs == null) {
      return const SizedBox.shrink();
    }

    final size = Size(
      vs.dragWidthNotifier.value ?? vs.sizeNotifier.value.width,
      vs.sizeNotifier.value.height,
    );
    final node = queryController.nodeLookup[editedId];
    final anchorCanvas = node?.getAbsoluteWorldPosition(queryController.nodeLookup) ??
        vs.positionNotifier.value;
    final double entityWidth = size.width;

    const double toolbarWidth = ContextToolbarConstants.textToolbarWidth;
    const double toolbarHeight = ContextToolbarConstants.textToolbarHeight;

    final anchorScreen = MatrixUtils.transformPoint(matrix, anchorCanvas);
    final bool isNodeOnRightHalf = anchorScreen.dx > (screenWidth / 2);

    if (offsetNotifier.value == AppConfig.toolbar.singleOffset) {
      offsetNotifier.value = isNodeOnRightHalf
          ? Offset(-toolbarWidth - margin, 0)
          : Offset(entityWidth + margin, 0);
    }

    final bool? lastNodeHalf = renderState.lastNodeOnRightHalf;
    if (lastNodeHalf != null && lastNodeHalf != isNodeOnRightHalf) {
      if (isNodeOnRightHalf && offsetNotifier.value.dx >= 0) {
        final mirroredDx = entityWidth - toolbarWidth - offsetNotifier.value.dx;
        offsetNotifier.value = Offset(mirroredDx, offsetNotifier.value.dy);
      } else if (!isNodeOnRightHalf && offsetNotifier.value.dx < 0) {
        final mirroredDx = entityWidth - toolbarWidth - offsetNotifier.value.dx;
        offsetNotifier.value = Offset(mirroredDx, offsetNotifier.value.dy);
      }
    }
    renderState.lastNodeOnRightHalf = isNodeOnRightHalf;

    final screenPosition = MatrixUtils.transformPoint(
      matrix,
      anchorCanvas + offsetNotifier.value,
    );

    final double maxX = math.max(leftThreshold, rightThreshold - toolbarWidth);
    final double maxY =
        math.max(topThreshold, screenHeight - toolbarHeight * 0.7);

    final double toolbarLeft =
        screenPosition.dx.clamp(leftThreshold, maxX).toDouble();
    final double toolbarTop =
        screenPosition.dy.clamp(topThreshold, maxY).toDouble();

    return Positioned(
      left: toolbarLeft,
      top: toolbarTop,
      child: VerticalTextFormatToolbar(
        onToggleHeader1: () {
          renderState.toggleHeadingCallback?.call(TextFormatType.heading1);
        },
        onToggleHeader2: () {
          renderState.toggleHeadingCallback?.call(TextFormatType.heading2);
        },
        onToggleHeader3: () {
          renderState.toggleHeadingCallback?.call(TextFormatType.heading3);
        },
        onToggleBlockquote: () {
          renderState.toggleHeadingCallback?.call(TextFormatType.blockquote);
        },
        onToggleCodeBlock: () {
          renderState.toggleHeadingCallback?.call(TextFormatType.codeBlock);
        },
        onToggleBulletList: () {
          renderState.toggleHeadingCallback?.call(TextFormatType.bulletList);
        },
        onToggleOrderedList: () {
          renderState.toggleHeadingCallback?.call(TextFormatType.orderedList);
        },
        onClearBlockFormat: () {
          renderState.clearBlockFormatCallback?.call();
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
                    hintText: 'https://example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, controller.text),
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

  Widget _buildContextToolbar(
    BuildContext context, {
    required Matrix4 matrix,
    required ValueNotifier<Offset> offsetNotifier,
    required List<NodeViewState> selectedViewStates,
    required List<UiRelation> selectedRelations,
    required bool isMulti,
    required bool isRelationOnly,
    required double screenWidth,
    required double screenHeight,
    required double leftThreshold,
    required double topThreshold,
    required double margin,
  }) {
    Offset anchor = Offset.zero;
    if (selectedViewStates.isNotEmpty || selectedRelations.isNotEmpty) {
      anchor =
          renderState.calculateToolbarAnchor(renderState.selectedEntities) ??
          Offset.zero;
    }

    const double visualToolbarWidth = ContextToolbarConstants.visualToolbarWidth;
    const double toolbarStackWidth = ContextToolbarConstants.toolbarStackWidth;
    const double toolbarHeight = ContextToolbarConstants.toolbarHeight;

    final double nodeWidth = selectedViewStates.isNotEmpty
        ? (selectedViewStates.first.dragWidthNotifier.value ??
              selectedViewStates.first.sizeNotifier.value.width)
        : 150.0;

    final anchorScreen = MatrixUtils.transformPoint(matrix, anchor);
    final bool isNodeOnRightHalf = anchorScreen.dx > (screenWidth / 2);

    final defaultOffset = isMulti
        ? AppConfig.toolbar.multiOffset
        : AppConfig.toolbar.singleOffset;

    if (offsetNotifier.value == defaultOffset) {
      offsetNotifier.value = isNodeOnRightHalf
          ? Offset(-visualToolbarWidth - margin, 0)
          : Offset(nodeWidth + margin, 0);
    }

    final bool? lastNodeHalf = renderState.lastNodeOnRightHalf;
    if (lastNodeHalf != null && lastNodeHalf != isNodeOnRightHalf) {
      if (isNodeOnRightHalf && offsetNotifier.value.dx >= 0) {
        final mirroredDx = nodeWidth - visualToolbarWidth - offsetNotifier.value.dx;
        offsetNotifier.value = Offset(mirroredDx, offsetNotifier.value.dy);
      } else if (!isNodeOnRightHalf && offsetNotifier.value.dx < 0) {
        final mirroredDx = nodeWidth - visualToolbarWidth - offsetNotifier.value.dx;
        offsetNotifier.value = Offset(mirroredDx, offsetNotifier.value.dy);
      }
    }
    renderState.lastNodeOnRightHalf = isNodeOnRightHalf;

    final screenPosition = MatrixUtils.transformPoint(
      matrix,
      anchor + offsetNotifier.value,
    );

    final bool useRight = offsetNotifier.value.dx >= 0;

    final double leftX =
        screenPosition.dx + visualToolbarWidth - toolbarStackWidth;
    final double rightX = screenPosition.dx;

    final double toolbarLeft = useRight ? rightX : leftX;
    final double maxY =
        math.max(topThreshold, screenHeight - toolbarHeight * 0.7);
    final double toolbarTop =
        screenPosition.dy.clamp(topThreshold, maxY).toDouble();

    final nodeIds = renderState.selectedEntities
        .where((id) => queryController.nodeLookup.containsKey(id))
        .toList();
    final canSaveTemplate = nodeIds.isNotEmpty;
    final RawUuid? singleNodeId =
        (!isMulti && nodeIds.length == 1) ? nodeIds.first : null;

    if (selectedViewStates.isNotEmpty) {
      final vs = selectedViewStates.first;
      final s = Size(
        vs.dragWidthNotifier.value ?? vs.sizeNotifier.value.width,
        vs.sizeNotifier.value.height,
      );
      final singleId = singleNodeId;
      final node =
          singleId != null ? queryController.nodeLookup[singleId] : null;
      final worldPos =
          node?.getAbsoluteWorldPosition(queryController.nodeLookup) ??
          vs.positionNotifier.value;
      final tl = MatrixUtils.transformPoint(matrix, worldPos);
      final br = MatrixUtils.transformPoint(
        matrix,
        worldPos + Offset(s.width, s.height),
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
              final nextFont =
                  style.fontFamily == 'Roboto' ? 'Inter' : 'Roboto';
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
  }
}
