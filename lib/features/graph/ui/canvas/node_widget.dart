import 'package:centrode/shared/theme/design_tokens.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/config.dart';
import '../../models/models.dart';
import '../../store/graph_data_query.dart';
import '../../presentation/view_state.dart';
import '../../../../shared/utils/app_paths.dart';
import 'text/canvas_text_editor.dart';
import 'widgets/node_visual_constants.dart';
import 'widgets/node_rich_text.dart';
import 'widgets/attachment_shelf_widget.dart';
import 'widgets/media_node_widget.dart';

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

        final attachments = liveNode is InfoUiNode
            ? liveNode.attachments
            : (liveNode is TaskUiNode ? liveNode.attachments : null);
        final hasImageAttachment = attachments != null &&
            attachments.any((a) => a.mimeType.startsWith('image/'));
        final hasOther = attachments != null &&
            attachments.any((a) => !a.mimeType.startsWith('image/'));

        final double scale = NodeVisualConstants.fontScale(resolvedStyle.fontSize);
        final double padding = isEditing
            ? (2.0 * scale)
            : (hasOther ? (4.0 * scale) : resolvedStyle.padding);

        final scaledBadgeFontSize = NodeVisualConstants.scaledBadgeFontSize(resolvedStyle.fontSize);
        final scaledShowMoreFontSize = NodeVisualConstants.scaledShowMoreFontSize(resolvedStyle.fontSize);

        if (liveNode is MediaUiNode) {
          return MediaNodeWidget(
            node: liveNode,
            isSelected: isSelected,
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size.width,
              height: size.height,
              clipBehavior: Clip.antiAlias,
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
              padding: hasImageAttachment
                  ? EdgeInsets.zero
                  : (hasOther
                      ? EdgeInsets.symmetric(horizontal: 2.0 * scale, vertical: 2.5 * scale)
                      : EdgeInsets.all(padding)),
              child: _buildNodeContent(
                context,
                liveNode,
                resolvedStyle,
                isEditing: isEditing,
                padding: padding,
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
    required double padding,
    double scaledBadgeFontSize = 10.0,
    double scaledShowMoreFontSize = 10.0,
  }) {
    final double scale = NodeVisualConstants.fontScale(style.fontSize);

    if (liveNode is MediaUiNode) {
      return MediaNodeWidget(
        node: liveNode,
        isSelected: isSelected,
      );
    }

    final attachments = liveNode is InfoUiNode
        ? liveNode.attachments
        : (liveNode is TaskUiNode ? liveNode.attachments : null);

    final imageAttachment = attachments?.where((a) => a.mimeType.startsWith('image/')).firstOrNull;
    final otherAttachments = attachments?.where((a) => !a.mimeType.startsWith('image/')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageAttachment != null)
          _NodeImageHeader(
            attachment: imageAttachment,
            scale: scale,
          ),
        if (otherAttachments != null && otherAttachments.isNotEmpty)
          Padding(
            padding: imageAttachment != null
                ? EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 2 * scale)
                : EdgeInsets.only(bottom: 2.0 * scale),
            child: AttachmentShelfWidget(
              attachments: otherAttachments,
              textColor: Color(style.textColor),
              bgColor: Color(style.bgColor),
              scale: scale,
            ),
          ),
        Expanded(
          child: Padding(
            padding: imageAttachment != null
                ? EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale)
                : EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: isEditing
                      ? Align(
                          alignment: Alignment.centerLeft,
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
                          alignment: Alignment.centerLeft,
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
                      top: (viewState.isExpandedNotifier.value ? 4.0 : 2.0) * scale,
                    ),
                    width: double.infinity,
                    height: NodeVisualConstants.expandButtonHeight * scale,
                    decoration: BoxDecoration(
                      color: Color(style.textColor).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4.0 * scale),
                    ),
                    child: Center(
                      child: Icon(
                        viewState.isExpandedNotifier.value
                            ? Icons.keyboard_double_arrow_up
                            : Icons.keyboard_double_arrow_down,
                        size: NodeVisualConstants.expandIconSize * scale,
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
                      borderRadius: BorderRadius.circular(UiRadius.control),
                      border: Border.all(
                        color: Color(style.textColor).withValues(alpha: 0.3),
                        width: UiStrokeWidth.standard,
                      ),
                    ),
                    child: Text(
                      liveNode.state.name,
                      style: TextStyle(
                        fontSize: scaledBadgeFontSize,
                        fontWeight: FontWeight.bold,
                        color: Color(style.textColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NodeImageHeader extends StatefulWidget {
  final Attachment attachment;
  final double scale;

  const _NodeImageHeader({
    required this.attachment,
    required this.scale,
  });

  @override
  State<_NodeImageHeader> createState() => _NodeImageHeaderState();
}

class _NodeImageHeaderState extends State<_NodeImageHeader> {
  String? _resolvedDir;

  @override
  void initState() {
    super.initState();
    AppPaths.attachmentsDirectory.then((dir) {
      if (mounted) {
        setState(() {
          _resolvedDir = dir;
        });
      }
    });
  }

  File? _resolveFile() {
    if (_resolvedDir == null) return null;
    final ext = widget.attachment.name.contains('.')
        ? widget.attachment.name.split('.').last
        : 'png';
    final path = '$_resolvedDir/${widget.attachment.hash}.$ext';
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    final file = _resolveFile();
    final hasDim = widget.attachment.width != null &&
        widget.attachment.height != null &&
        widget.attachment.width! > 0 &&
        widget.attachment.height! > 0;
    final aspect = hasDim
        ? (widget.attachment.width! / widget.attachment.height!).clamp(0.5, 2.5)
        : (16 / 9);

    return AspectRatio(
      aspectRatio: aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black12,
            child: file != null
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: UiIconSize.header * widget.scale,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: UiStrokeWidth.thick),
                    ),
                  ),
          ),
          if (file != null)
            Positioned(
              right: 6.0 * widget.scale,
              top: 6.0 * widget.scale,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: UiInsets.container,
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            InteractiveViewer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(UiRadius.panel),
                                child: Image.file(
                                  file,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(4.0 * widget.scale),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 13.0 * widget.scale,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
