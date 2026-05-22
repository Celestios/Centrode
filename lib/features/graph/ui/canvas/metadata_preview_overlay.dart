import 'dart:ui';
import 'package:flutter/material.dart';
import '../../presentation/graph_metrics.dart';
import '../../models/models.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;

class MetadataPreviewOverlay extends StatelessWidget {
  final InfoUiNode node;

  const MetadataPreviewOverlay({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final hasTags = node.tags.isNotEmpty;
    final hasComments = node.comments.isNotEmpty;

    if (!hasTags && !hasComments) {
      return const SizedBox.shrink();
    }

    // Get the latest comment
    frb.Comment? latestComment;
    if (hasComments) {
      latestComment = node.comments.reduce((a, b) =>
          a.createdAt.toInt() > b.createdAt.toInt() ? a : b);
    }

    return Container(
      width: AppConfig.node.metadataPreviewWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConfig.node.metadataPreviewBorderRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.node.metadataPreviewBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppConfig.node.metadataPreviewBlur,
            sigmaY: AppConfig.node.metadataPreviewBlur,
          ),
          child: Container(
            color: const Color(0xFF1E1E2E).withValues(alpha: 0.85),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'METADATA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tags section
                if (hasTags) ...[
                  Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: node.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(tag.color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Color(tag.color).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(tag.color),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (hasComments) const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Colors.white12, height: 1),
                  ),
                ],

                // Comments section
                if (latestComment != null) ...[
                  Text(
                    'Latest Comment',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    latestComment.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(latestComment.createdAt.toInt()),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
  }
}
