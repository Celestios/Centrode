import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/utils/date_utils.dart';
import '../../../engine/config.dart';
import '../../../models/models.dart';

class MetadataPreviewOverlay extends StatelessWidget {
  final InfoUiNode node;
  final double? nodeWidth;

  const MetadataPreviewOverlay({
    super.key,
    required this.node,
    this.nodeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final hasTags = node.tags.isNotEmpty;
    final hasComments = node.comments.isNotEmpty;

    if (!hasTags && !hasComments) {
      return const SizedBox.shrink();
    }

    // Get the latest comment
    Comment? latestComment;
    if (hasComments) {
      latestComment = node.comments.reduce(
        (a, b) => a.createdAt.toInt() > b.createdAt.toInt() ? a : b,
      );
    }

    final targetWidth = nodeWidth != null
        ? (nodeWidth! * 0.95).clamp(130.0, 170.0)
        : 140.0;

    return GlassPanel(
      borderRadius: 10.0,
      blur: AppConfig.node.metadataPreviewBlur,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SizedBox(
        width: targetWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'METADATA',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  size: 9,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Tags section
            if (hasTags) ...[
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: node.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Color(tag.fields.color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: Color(
                          tag.fields.color,
                        ).withValues(alpha: 0.4),
                        width: 0.75,
                      ),
                    ),
                    child: Text(
                      tag.fields.name,
                      style: TextStyle(
                        fontSize: 8.0,
                        color: Color(tag.fields.color),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (hasComments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Divider(color: Colors.white12, height: 1),
                ),
            ],

            // Comments section
            if (latestComment != null) ...[
              Text(
                'Latest Comment',
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                latestComment.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.0,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatTimestampShort(latestComment.createdAt.toInt()),
                style: TextStyle(
                  fontSize: 7.5,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
