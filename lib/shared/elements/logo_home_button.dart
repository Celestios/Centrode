import 'package:flutter/material.dart';

class LogoHomeButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const LogoHomeButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(
                  alpha: 0.7,
                ),
              ],
            ).createShader(bounds),
            child: CustomPaint(
              size: const Size(18, 20),
              painter: _HomePolygonPainter(),
            ),
          ),
          const SizedBox(width: 2),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(
                  alpha: 0.7,
                ),
              ],
            ).createShader(bounds),
            child: const Text(
              'CENTRODE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePolygonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height * 0.45)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.35, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HomePolygonPainter oldDelegate) => false;
}
