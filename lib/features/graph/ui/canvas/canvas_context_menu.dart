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
    Rect? targetRect,
    Rect? avoidRect,
    List<Rect> avoidRects = const [],
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
      targetRect: targetRect,
      avoidRect: avoidRect,
      avoidRects: avoidRects,
      onDismissed: () => _entry = null,
      items: [
        ContextMenuItem.action(
          label: 'Copy',
          leadingIcon: Icons.copy_rounded,
          shortcut: 'Ctrl+C',
          onTap: () {
            final selectedIds = renderState.selectedEntities.toList();
            if (selectedIds.isNotEmpty) {
              copyBuffer.copy(selectedIds, queryController);
            }
          },
        ),
        ContextMenuItem.action(
          label: 'Cut',
          leadingIcon: Icons.content_cut_rounded,
          shortcut: 'Ctrl+X',
          onTap: () {
            final selectedIds = renderState.selectedEntities.toList();
            if (selectedIds.isNotEmpty) {
              copyBuffer.copy(selectedIds, queryController);
              renderState.deleteSelectedEntities();
            }
          },
        ),
        ContextMenuItem.action(
          label: 'Paste',
          leadingIcon: Icons.paste_rounded,
          shortcut: 'Ctrl+V',
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
          const ContextMenuItem.divider(),
          if (renderState.selectedEntities.length > 1)
            ContextMenuItem.action(
              label: 'Group',
              leadingIcon: Icons.workspaces_outlined,
              shortcut: 'Ctrl+G',
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
            ContextMenuItem.action(
              label: 'Ungroup',
              leadingIcon: Icons.grid_view_rounded,
              shortcut: 'Ctrl+Shift+G',
              onTap: () {
                final selectedIds = renderState.selectedEntities.toList();
                commandProcessor.ungroupNodes(selectedIds);
                renderState.selectEntities(selectedIds);
              },
            ),
          ContextMenuItem.action(
            label: 'Group in Frame',
            leadingIcon: Icons.crop_free_rounded,
            onTap: () {
              final selectedIds = renderState.selectedEntities.toList();
              final frameId = commandProcessor.createFrameFromSelection(selectedIds);
              renderState.selectEntities([frameId]);
            },
          ),
          ContextMenuItem.action(
            label: 'Convert to Container',
            leadingIcon: Icons.folder_outlined,
            onTap: () {
              final selectedIds = renderState.selectedEntities.toList();
              for (final id in selectedIds) {
                commandProcessor.convertNodeToContainer(id);
              }
            },
          ),
          const ContextMenuItem.divider(),
          ContextMenuItem.destructive(
            label: 'Delete Node(s)',
            leadingIcon: Icons.delete_outline_rounded,
            shortcut: 'Del',
            onTap: renderState.deleteSelectedEntities,
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
          ContextMenuItem.action(
            label: 'New Node',
            leadingIcon: Icons.add_circle_outline_rounded,
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
          ContextMenuItem.action(
            label: 'New Frame',
            leadingIcon: Icons.crop_free_rounded,
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
          ContextMenuItem.action(
            label: 'New Media Node (File Picker)...',
            leadingIcon: Icons.perm_media_outlined,
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
          const ContextMenuItem.divider(),
          ContextMenuItem.action(
            label: 'Select All',
            leadingIcon: Icons.select_all_rounded,
            shortcut: 'Ctrl+A',
            onTap: () {
              renderState.selectEntities(queryController.nodeLookup.keys.toList());
            },
          ),
        ],
      ],
    );
  }
}
