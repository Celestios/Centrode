import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';

class EmptySectionCard extends StatelessWidget {
  final String description;

  const EmptySectionCard({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: WorkspaceTokens.cardWidth,
      height: WorkspaceTokens.cardHeight,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(UiSpacing.container),
            child: Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: UiFont.compact,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = UiStrokeWidth.thick
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(UiRadius.panel),
      ));

    const double dashWidth = 6;
    const double dashSpace = 4;

    final pathMetrics = path.computeMetrics().first;
    final pathLength = pathMetrics.length;
    double distance = 0;

    while (distance < pathLength) {
      final start = pathMetrics.getTangentForOffset(distance)!.position;
      final end = pathMetrics.getTangentForOffset(
        distance + dashWidth > pathLength ? pathLength : distance + dashWidth,
      )!.position;

      canvas.drawLine(start, end, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}
