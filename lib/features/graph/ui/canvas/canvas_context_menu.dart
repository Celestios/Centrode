import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/presentation/strategies/node_layout_strategy.dart';
import 'package:centrode/shared/copy_buffer.dart';
import 'package:centrode/shared/utils/app_paths.dart';
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
          if (renderState.selectedEntities.length == 1 &&
              (queryController.nodeLookup[renderState.selectedEntities.first] is InfoUiNode ||
               queryController.nodeLookup[renderState.selectedEntities.first] is TaskUiNode)) ...[
            ContextMenuItem(
              label: 'Attach File (File Picker)...',
              onTap: () async {
                final selectedId = renderState.selectedEntities.first;
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: 'Select File to Attach',
                  allowMultiple: true,
                );
                if (result == null || result.files.isEmpty) return;

                final assetDir = await AppPaths.attachmentsDirectory;
                for (final file in result.files) {
                  if (file.path == null) continue;
                  final rawBytes = await File(file.path!).readAsBytes();
                  final ext = p.extension(file.name).replaceAll('.', '').toLowerCase();
                  String mime = 'application/octet-stream';
                  if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
                    mime = 'image/$ext';
                  } else if (['mp3', 'wav', 'ogg', 'm4a'].contains(ext)) {
                    mime = 'audio/$ext';
                  } else if (['mp4', 'webm', 'mov'].contains(ext)) {
                    mime = 'video/$ext';
                  } else if (ext == 'pdf') {
                    mime = 'application/pdf';
                  }

                  int? imgW;
                  int? imgH;
                  if (mime.startsWith('image/')) {
                    try {
                      final codec = await ui.instantiateImageCodec(rawBytes);
                      final frameInfo = await codec.getNextFrame();
                      imgW = frameInfo.image.width;
                      imgH = frameInfo.image.height;
                    } catch (_) {}
                  }

                  var attachment = await commandProcessor.api.ingestAsset(
                    assetDir: assetDir,
                    fileName: file.name,
                    fileBytes: rawBytes,
                    mimeType: mime,
                  );

                  if (imgW != null && imgH != null) {
                    attachment = Attachment(
                      id: attachment.id,
                      hash: attachment.hash,
                      name: attachment.name,
                      mimeType: attachment.mimeType,
                      byteSize: attachment.byteSize,
                      width: imgW,
                      height: imgH,
                      durationMs: attachment.durationMs,
                    );
                  }

                  final node = queryController.nodeLookup[selectedId];
                  if (node != null) {
                    if (node is InfoUiNode) {
                      node.attachments = [...node.attachments, attachment];
                    } else if (node is TaskUiNode) {
                      node.attachments = [...node.attachments, attachment];
                    }
                    final layoutStrategy = const DefaultNodeLayoutStrategy();
                    final calculated = layoutStrategy.calculateSize(node);
                    node.size = calculated.size;

                    final vs = renderState.viewStates[selectedId];
                    if (vs != null) {
                      vs.onSizeChanged(node);
                    }

                    commandProcessor.triggerUpdate();
                    queryController.triggerUpdate();
                  }
                }
              },
            ),
          ],
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
          ContextMenuItem(
            label: 'New Media Node (File Picker)...',
            onTap: () async {
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

              final result = await FilePicker.platform.pickFiles(
                dialogTitle: 'Select Media File',
              );
              if (result == null || result.files.isEmpty || result.files.single.path == null) return;

              final file = result.files.single;
              final rawBytes = await File(file.path!).readAsBytes();
              final ext = p.extension(file.name).replaceAll('.', '').toLowerCase();
              String mime = 'application/octet-stream';
              MediaType mediaType = MediaType.image;
              if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
                mime = 'image/$ext';
                mediaType = MediaType.image;
              } else if (['mp3', 'wav', 'ogg', 'm4a'].contains(ext)) {
                mime = 'audio/$ext';
                mediaType = MediaType.audio;
              } else if (['mp4', 'webm', 'mov'].contains(ext)) {
                mime = 'video/$ext';
                mediaType = MediaType.video;
              } else if (ext == 'pdf') {
                mime = 'application/pdf';
                mediaType = MediaType.pdf;
              }

              int? imgW;
              int? imgH;
              if (mime.startsWith('image/')) {
                try {
                  final codec = await ui.instantiateImageCodec(rawBytes);
                  final frameInfo = await codec.getNextFrame();
                  imgW = frameInfo.image.width;
                  imgH = frameInfo.image.height;
                } catch (_) {}
              }

              final assetDir = await AppPaths.attachmentsDirectory;
              var attachment = await commandProcessor.api.ingestAsset(
                assetDir: assetDir,
                fileName: file.name,
                fileBytes: rawBytes,
                mimeType: mime,
              );

              if (imgW != null && imgH != null) {
                attachment = Attachment(
                  id: attachment.id,
                  hash: attachment.hash,
                  name: attachment.name,
                  mimeType: attachment.mimeType,
                  byteSize: attachment.byteSize,
                  width: imgW,
                  height: imgH,
                  durationMs: attachment.durationMs,
                );
              }

              final newId = commandProcessor.createNode(
                UiNodes.media,
                canvasPos,
                parentContainerId: parentId,
                mediaType: mediaType,
                attachment: attachment,
              );
              final createdNode = queryController.nodeLookup[newId];
              if (createdNode != null && imgW != null && imgH != null && imgW > 0) {
                final double nodeW = imgW.toDouble().clamp(200.0, 360.0);
                final double nodeH = (nodeW * (imgH / imgW)).clamp(100.0, 400.0);
                createdNode.size = Size(nodeW, nodeH);
                final vs = renderState.viewStates[newId];
                if (vs != null) {
                  vs.onSizeChanged(createdNode);
                }
              }
              renderState.selectEntities([newId]);
            },
          ),
        ],
      ],
    );
  }
}
