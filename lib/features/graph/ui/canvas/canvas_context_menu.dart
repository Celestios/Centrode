import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/shared/copy_buffer.dart';
import 'package:centrode/shared/widgets/context_menu_overlay.dart';
import 'paste_handler.dart';

class CanvasContextMenu {
  static OverlayEntry? _entry;

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  static void show({
    required BuildContext context,
    required Offset position,
    required GraphDataQueryController queryController,
    required CommandQueueProcessor commandProcessor,
    required NodeRenderState renderState,
    required CopyBuffer copyBuffer,
    required ViewportController viewportController,
  }) {
    dismiss();

    _entry = ContextMenuOverlay.show(
      context: context,
      position: position,
      onDismissed: () => _entry = null,
      items: [
        ContextMenuItem(
          label: 'Copy',
          onTap: () {
            final selectedIds = renderState.selectedEntities.toList();
            if (selectedIds.isNotEmpty) {
              copyBuffer.copy(selectedIds, queryController);
            }
          },
        ),
        ContextMenuItem(
          label: 'Cut',
          onTap: () {
            final selectedIds = renderState.selectedEntities.toList();
            if (selectedIds.isNotEmpty) {
              copyBuffer.copy(selectedIds, queryController);
              renderState.deleteSelectedEntities();
            }
          },
        ),
        ContextMenuItem(
          label: 'Paste',
          onTap: () async {
            if (copyBuffer.hasData) {
              final transform = viewportController.transformController.value;
              final canvasPos = transform.determinant() == 0.0
                  ? Offset.zero
                  : MatrixUtils.transformPoint(
                      Matrix4.inverted(transform),
                      position,
                    );
              final newIds = await copyBuffer.paste(
                canvasPos,
                commandProcessor,
              );
              if (newIds.isNotEmpty) {
                renderState.selectEntities(newIds);
              }
            } else {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null && data!.text!.isNotEmpty) {
                final transform = viewportController.transformController.value;
                final canvasPos = transform.determinant() == 0.0
                    ? Offset.zero
                    : MatrixUtils.transformPoint(
                        Matrix4.inverted(transform),
                        position,
                      );
                await pasteTextToCanvas(
                  dataController: commandProcessor,
                  text: data.text!,
                  canvasPosition: canvasPos,
                );
              }
            }
          },
        ),
        if (renderState.selectedEntities.isNotEmpty) ...[
          if (renderState.selectedEntities.length > 1)
            ContextMenuItem(
              label: 'Group (Ctrl+G)',
              onTap: () {
                final selectedIds = renderState.selectedEntities.toList();
                commandProcessor.groupNodes(selectedIds);
                renderState.selectEntities(selectedIds);
              },
            ),
          if (renderState.selectedEntities.any((id) {
            final node = queryController.nodeLookup[id];
            return node != null && node.groupId != null;
          }))
            ContextMenuItem(
              label: 'Ungroup (Ctrl+Shift+G)',
              onTap: () {
                final selectedIds = renderState.selectedEntities.toList();
                commandProcessor.ungroupNodes(selectedIds);
                renderState.selectEntities(selectedIds);
              },
            ),
          ContextMenuItem(
            label: 'Group in Frame',
            onTap: () {
              final selectedIds = renderState.selectedEntities.toList();
              final frameId = commandProcessor.createFrameFromSelection(selectedIds);
              renderState.selectEntities([frameId]);
            },
          ),
          ContextMenuItem(
            label: 'Convert to Container',
            onTap: () {
              final selectedIds = renderState.selectedEntities.toList();
              for (final id in selectedIds) {
                commandProcessor.convertNodeToContainer(id);
              }
            },
          ),
          if (renderState.selectedEntities.length == 1 &&
              queryController.nodeLookup[renderState.selectedEntities.first] is ContainerUiNode)
            ContextMenuItem(
              label: 'Zoom into Container',
              onTap: () {
                final selectedId = renderState.selectedEntities.first;
                final node = queryController.nodeLookup[selectedId] as ContainerUiNode;
                final targetScale = ((viewportController.viewportSize.width * 0.8) / node.size.width).clamp(0.2, 5.0);
                final nodeCenter = node.position + Offset(node.size.width / 2, node.size.height / 2);
                final dx = (viewportController.viewportSize.width / 2) - (nodeCenter.dx * targetScale);
                final dy = (viewportController.viewportSize.height / 2) - (nodeCenter.dy * targetScale);

                final targetMatrix = Matrix4.identity()
                  ..translateByDouble(dx, dy, 0, 1)
                  ..scaleByDouble(targetScale, targetScale, targetScale, 1);

                viewportController.transformController.value = targetMatrix;
              },
            ),
        ] else ...[
          ContextMenuItem(
            label: 'New Node',
            onTap: () {
              final transform = viewportController.transformController.value;
              final canvasPos = transform.determinant() == 0.0
                  ? Offset.zero
                  : MatrixUtils.transformPoint(
                      Matrix4.inverted(transform),
                      position,
                    );
              final activeScope = viewportController.activeScopeNotifier.value;
              final parentId = activeScope is ContainerViewportScope
                  ? activeScope.containerId
                  : null;
              final newId = commandProcessor.createNode(
                UiNodes.info,
                canvasPos,
                parentContainerId: parentId,
              );
              renderState.selectEntities([newId]);
            },
          ),
          ContextMenuItem(
            label: 'New Frame',
            onTap: () {
              final transform = viewportController.transformController.value;
              final canvasPos = transform.determinant() == 0.0
                  ? Offset.zero
                  : MatrixUtils.transformPoint(
                      Matrix4.inverted(transform),
                      position,
                    );
              final frameId = commandProcessor.createFrameFromSelection(
                const [],
                defaultPosition: canvasPos,
              );
              renderState.selectEntities([frameId]);
            },
          ),
        ],
      ],
    );
  }
}
