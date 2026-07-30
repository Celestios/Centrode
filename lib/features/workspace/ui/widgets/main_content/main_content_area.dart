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
        child: const Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: MapsSection(),
              ),
            ),
            AnalyticsBox(),
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
