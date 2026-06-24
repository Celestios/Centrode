import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycelium/features/graph/store/graph_data_controller.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';
import 'package:mycelium/shared/copy_buffer.dart';
import 'package:mycelium/shared/widgets/context_menu_overlay.dart';
import 'paste_handler.dart';

class CanvasContextMenu {
  static OverlayEntry? _entry;

  static void dismiss() {
    try {
      _entry?.remove();
    } catch (_) {}
    _entry = null;
  }

  static void show({
    required BuildContext context,
    required Offset position,
    required GraphDataController dataController,
    required NodeRenderState renderState,
    required CopyBuffer copyBuffer,
    required ViewportController viewportController,
  }) {
    dismiss();

    _entry = ContextMenuOverlay.show(
      context: context,
      position: position,
      items: [
        ContextMenuItem(
          label: 'Copy',
          onTap: () {
            final selectedIds = renderState.selectedEntities.toList();
            if (selectedIds.isNotEmpty) {
              copyBuffer.copy(selectedIds, dataController);
            }
          },
        ),
        ContextMenuItem(
          label: 'Cut',
          onTap: () {
            final selectedIds = renderState.selectedEntities.toList();
            if (selectedIds.isNotEmpty) {
              copyBuffer.copy(selectedIds, dataController);
              renderState.deleteSelectedEntities();
            }
          },
        ),
        ContextMenuItem(
          label: 'Paste',
          onTap: () async {
            if (copyBuffer.hasData) {
              final transform =
                  viewportController.transformController.value;
              final canvasPos = transform.determinant() == 0.0
                  ? Offset.zero
                  : MatrixUtils.transformPoint(
                      Matrix4.inverted(transform),
                      position,
                    );
              final newIds = await copyBuffer.paste(canvasPos, dataController);
              if (newIds.isNotEmpty) {
                renderState.selectEntities(newIds);
              }
            } else {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null && data!.text!.isNotEmpty) {
                final transform =
                    viewportController.transformController.value;
                final canvasPos = transform.determinant() == 0.0
                    ? Offset.zero
                    : MatrixUtils.transformPoint(
                        Matrix4.inverted(transform),
                        position,
                      );
                await pasteTextToCanvas(
                  dataController: dataController,
                  text: data.text!,
                  canvasPosition: canvasPos,
                );
              }
            }
          },
        ),
      ],
    );
  }
}
