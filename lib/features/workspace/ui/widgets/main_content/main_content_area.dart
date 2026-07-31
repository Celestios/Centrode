import 'package:flutter/material.dart';
import 'maps_section.dart';
import 'analytics_box.dart';

class MainContentArea extends StatelessWidget {
  const MainContentArea({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipPath(
      clipper: _InwardLeftClipper(),
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            const Positioned.fill(
              child: Column(
                children: [
                  SizedBox(height: 48),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(top: 16),
                      child: MapsSection(),
                    ),
                  ),
                  AnalyticsBox(),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 38,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'CENTRODE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                          TextSpan(
                            text: '  Workspace Hub',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InwardLeftClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 16.0;
    final path = Path();

    path.moveTo(radius, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height / 2, radius, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_InwardLeftClipper oldClipper) => false;
}
