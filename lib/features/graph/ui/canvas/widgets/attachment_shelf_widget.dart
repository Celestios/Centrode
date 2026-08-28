import 'package:centrode/shared/theme/design_tokens.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:centrode/src/rust/domain/base_models.dart';
import 'package:centrode/shared/utils/app_paths.dart';

/// Renders the attachment chips shelf (for non-image or file attachments).
class AttachmentShelfWidget extends StatefulWidget {
  final List<Attachment> attachments;
  final String? assetDirectory;
  final Color textColor;
  final Color bgColor;
  final double scale;
  final void Function(Attachment attachment)? onAttachmentTap;
  final void Function(Attachment attachment)? onAttachmentRemove;

  const AttachmentShelfWidget({
    super.key,
    required this.attachments,
    this.assetDirectory,
    this.textColor = Colors.white,
    this.bgColor = const Color(0xFF1E293B),
    this.scale = 1.0,
    this.onAttachmentTap,
    this.onAttachmentRemove,
  });

  @override
  State<AttachmentShelfWidget> createState() => _AttachmentShelfWidgetState();
}

class _AttachmentShelfWidgetState extends State<AttachmentShelfWidget> {
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

  Future<void> _openWithOS(Attachment attachment) async {
    if (widget.onAttachmentTap != null) {
      widget.onAttachmentTap!(attachment);
      return;
    }
    final dir = widget.assetDirectory ?? _resolvedDir ?? await AppPaths.attachmentsDirectory;
    final ext = attachment.name.contains('.')
        ? attachment.name.split('.').last
        : 'bin';
    final filePath = '$dir/${attachment.hash}.$ext';
    final file = File(filePath);
    if (file.existsSync()) {
      final uri = Uri.file(file.path);
      await launchUrl(uri);
    }
  }

  IconData _getIconForMime(String mime) {
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (mime.startsWith('video/')) return Icons.videocam_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.attach_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final scale = widget.scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.attachments.map((attachment) {
        final icon = _getIconForMime(attachment.mimeType);

        return _AttachmentChip(
          attachment: attachment,
          icon: icon,
          textColor: widget.textColor,
          scale: scale,
          onTap: () => _openWithOS(attachment),
        );
      }).toList(),
    );
  }
}

class _AttachmentChip extends StatefulWidget {
  final Attachment attachment;
  final IconData icon;
  final Color textColor;
  final double scale;
  final VoidCallback onTap;

  const _AttachmentChip({
    required this.attachment,
    required this.icon,
    required this.textColor,
    required this.scale,
    required this.onTap,
  });

  @override
  State<_AttachmentChip> createState() => _AttachmentChipState();
}

class _AttachmentChipState extends State<_AttachmentChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final hoverColor = widget.textColor.withValues(alpha: _isHovered ? 0.18 : 0.08);
    final borderColor = widget.textColor.withValues(alpha: _isHovered ? 0.35 : 0.15);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(4.0 * scale),
          splashColor: widget.textColor.withValues(alpha: 0.15),
          highlightColor: widget.textColor.withValues(alpha: 0.10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 1.5 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 5.0 * scale,
              vertical: 3.0 * scale,
            ),
            decoration: BoxDecoration(
              color: hoverColor,
              borderRadius: BorderRadius.circular(4.0 * scale),
              border: Border.all(
                color: borderColor,
                width: _isHovered ? 1.0 * scale : 0.8 * scale,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 15.0 * scale,
                  color: widget.textColor.withValues(alpha: _isHovered ? 1.0 : 0.85),
                ),
                SizedBox(width: 5.0 * scale),
                Expanded(
                  child: Text(
                    widget.attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: UiFont.standard * scale,
                      fontWeight: FontWeight.w600,
                      color: widget.textColor,
                      decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: widget.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                SizedBox(width: 4.0 * scale),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 11.0 * scale,
                  color: widget.textColor.withValues(alpha: _isHovered ? 0.9 : 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
