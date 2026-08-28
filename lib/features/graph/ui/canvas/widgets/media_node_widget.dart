import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import '../../../models/models.dart';

/// Renders a standalone [MediaUiNode] directly on the infinite canvas.
class MediaNodeWidget extends StatefulWidget {
  final MediaUiNode node;
  final String? assetDirectory;
  final bool isSelected;

  const MediaNodeWidget({
    super.key,
    required this.node,
    this.assetDirectory,
    this.isSelected = false,
  });

  @override
  State<MediaNodeWidget> createState() => _MediaNodeWidgetState();
}

class _MediaNodeWidgetState extends State<MediaNodeWidget> {
  String? _resolvedDir;

  @override
  void initState() {
    super.initState();
    _resolvedDir = widget.assetDirectory;
    if (_resolvedDir == null) {
      AppPaths.attachmentsDirectory.then((dir) {
        if (mounted) {
          setState(() {
            _resolvedDir = dir;
          });
        }
      });
    }
  }

  File? _resolveLocalFile() {
    final dir = widget.assetDirectory ?? _resolvedDir;
    if (dir == null) return null;
    final ext = widget.node.attachment.name.contains('.')
        ? widget.node.attachment.name.split('.').last
        : (widget.node.mediaType == MediaType.image ? 'png' : 'bin');
    final filePath = '$dir/${widget.node.attachment.hash}.$ext';
    final file = File(filePath);
    return file.existsSync() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final localFile = _resolveLocalFile();

    return SizedBox(
      width: node.size.width,
      height: node.size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UiRadius.control),
        child: _buildMediaContent(context, localFile, node),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, File? localFile, MediaUiNode node) {
    switch (node.mediaType) {
      case MediaType.image:
        if (localFile != null) {
          return Image.file(
            localFile,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(Icons.broken_image_rounded, 'Image unavailable'),
          );
        }
        return _buildFallback(Icons.image_rounded, node.attachment.name);

      case MediaType.audio:
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.audiotrack_rounded,
                size: 32.0,
                color: CentrodeDerivedPalette.of(context).nodeTints.media,
              ),
              const SizedBox(height: UiSpacing.standard),
              Text(
                node.attachment.name,
                style: const TextStyle(fontSize: UiFont.standard, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UiSpacing.tight),
              Text(
                '${(node.attachment.byteSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                style: TextStyle(fontSize: UiFont.micro, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        );

      case MediaType.video:
        return _buildFallback(Icons.videocam_rounded, node.attachment.name);

      case MediaType.pdf:
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                size: 36.0,
                color: CentrodeDerivedPalette.of(context).semantic.danger,
              ),
              const SizedBox(height: UiSpacing.standard),
              Text(
                node.attachment.name,
                style: const TextStyle(fontSize: UiFont.standard, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UiSpacing.tight),
              Text(
                '${(node.attachment.byteSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                style: TextStyle(fontSize: UiFont.micro, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildFallback(IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32.0, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: UiSpacing.tight),
          Padding(
            padding: UiInsets.horizontalStandard,
            child: Text(
              label,
              style: TextStyle(fontSize: UiFont.compact, color: Colors.white.withValues(alpha: 0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
