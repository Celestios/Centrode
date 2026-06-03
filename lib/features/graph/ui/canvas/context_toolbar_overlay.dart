import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/features/graph/store/graph_data_controller.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';
import 'package:mycelium/features/graph/engine/interaction_engine.dart';
import 'package:mycelium/features/graph/engine/base_interaction_state.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/features/graph/ui/widgets/overlays/vertical_context_toolbar.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:mycelium/features/graph/presentation/strategies/relation_style_strategy.dart';
import 'package:mycelium/presentation/widgets/template_manager/save_template_dialog.dart';
import 'package:mycelium/features/graph/models/models.dart';

class ContextToolbarOverlay extends StatelessWidget {
  final NodeRenderState renderState;
  final GraphDataController dataController;
  final ViewportController viewportController;
  final InteractionController interactionController;

  const ContextToolbarOverlay({
    super.key,
    required this.renderState,
    required this.dataController,
    required this.viewportController,
    required this.interactionController,
  });

  void _updateNodeStyle(
    String nodeId,
    GraphDataController dataController,
    NodeStyle Function(NodeStyle style) updateFn,
  ) {
    final node = dataController.nodeLookup[nodeId];
    if (node != null) {
      final style = node.style ?? NodeStyleStrategy.resolveStyle(node);
      dataController.updateNodeStyle(nodeId, updateFn(style));
    }
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
          final rel = dataController.relations.firstWhere((r) => r.id == id);
          selectedRelations.add(rel);
          final sourceVs = renderState.viewStates[rel.fromNodeId];
          final targetVs = renderState.viewStates[rel.toNodeId];
          if (sourceVs != null) listenables.add(sourceVs.positionNotifier);
          if (targetVs != null) listenables.add(targetVs.positionNotifier);
        } catch (_) {}
      }
    }

    final isRelationOnly = selectedViewStates.isEmpty && selectedRelations.isNotEmpty;

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        Offset anchor = Offset.zero;
        if (selectedViewStates.isNotEmpty || selectedRelations.isNotEmpty) {
          anchor = renderState.calculateToolbarAnchor(renderState.selectedEntities) ?? Offset.zero;
        }

        final offset = offsetNotifier.value;
        final canvasPosition = anchor + offset;

        final matrix = viewportController.transformController.value;
        final screenPosition = MatrixUtils.transformPoint(matrix, canvasPosition);

        final nodeIds = renderState.selectedEntities
            .where((id) => dataController.nodeLookup.containsKey(id))
            .toList();
        final canSaveTemplate = nodeIds.isNotEmpty;
        final String? singleNodeId = (!isMulti && nodeIds.length == 1) ? nodeIds.first : null;

        return Positioned(
          left: screenPosition.dx - 340,
          top: screenPosition.dy,
          child: VerticalContextToolbar(
            onDelete: renderState.deleteSelectedEntities,
            isMulti: isMulti,
            isRelationOnly: isRelationOnly,
            canSaveTemplate: canSaveTemplate,
            singleNodeId: singleNodeId,
            onRelationLayoutChanged: (layoutType) {
              for (final rel in selectedRelations) {
                dataController.updateRelationLayout(
                  rel.id,
                  strategyType: layoutType,
                );
              }
            },
            onRelationStrokePatternChanged: (pattern) {
              for (final rel in selectedRelations) {
                final currentStyle = rel.style ?? RelationStyleStrategy.resolveStyle(rel);
                dataController.updateRelationStyle(
                  rel.id,
                  currentStyle.copyWith(strokePattern: pattern),
                );
              }
            },
            onDrawConnection: () {
              final nodeIds = renderState.selectedEntities
                  .where((id) => dataController.nodeLookup.containsKey(id))
                  .toList();
              if (nodeIds.isNotEmpty) {
                final vs = renderState.viewStates[nodeIds.first];
                final initialPos = vs != null ? vs.rect.center : Offset.zero;
                interactionController.state.value = RelationDrawing(
                  nodeIds.toSet(),
                  initialPos,
                  isSticky: true,
                  hasReleasedOnce: true,
                );
              }
            },
            onDecreaseFontSize: () {
              if (singleNodeId != null) {
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  return style.copyWith(
                    fontSize: (style.fontSize - 2.0).clamp(8.0, 24.0),
                  );
                });
              }
            },
            onIncreaseFontSize: () {
              if (singleNodeId != null) {
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  return style.copyWith(
                    fontSize: (style.fontSize + 2.0).clamp(8.0, 24.0),
                  );
                });
              }
            },
            onToggleFontFamily: () {
              if (singleNodeId != null) {
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  final nextFont = style.fontFamily == 'Roboto' ? 'Inter' : 'Roboto';
                  return style.copyWith(fontFamily: nextFont);
                });
              }
            },
            onCycleTextColor: () {
              if (singleNodeId != null) {
                const textColors = [
                  0xFF000000,
                  0xFFFFFFFF,
                  0xFF0D47A1,
                  0xFF1B5E20,
                  0xFF880E4F,
                  0xFFE65100,
                  0xFF263238,
                ];
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  final index = textColors.indexOf(style.textColor);
                  final nextColor = textColors[(index + 1) % textColors.length];
                  return style.copyWith(textColor: nextColor);
                });
              }
            },
            onShapeChanged: (shape) {
              if (singleNodeId != null) {
                _updateNodeStyle(singleNodeId, dataController, (style) {
                  return style.copyWith(shape: shape);
                });
              }
            },
            onSaveTemplate: () async {
              final nodeIds = renderState.selectedEntities
                  .where((id) => dataController.nodeLookup.containsKey(id))
                  .toList();
              final relationIds = renderState.selectedEntities
                  .where((id) => dataController.relationLookup.containsKey(id))
                  .toList();
              final name = await showSaveTemplateDialog(context);
              if (name != null) {
                await dataController.saveTemplateFromSelection(
                  name,
                  nodeIds,
                  relationIds,
                );
              }
            },
            dragHandle: Padding(
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
            ),
          ),
        );
      },
    );
  }
}
