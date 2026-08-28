import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'maps_section.dart';
import 'analytics_box.dart';
import 'package:centrode/shared/elements/elements.dart';

class MainContentArea extends StatelessWidget {
  const MainContentArea({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final statusBarHeight = isAndroid ? MediaQuery.of(context).padding.top : 0.0;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    final content = Container(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: 48 + statusBarHeight),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(top: 16),
                    child: MapsSection(),
                  ),
                ),
                const AnalyticsBox(),
              ],
            ),
          ),
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            height: 48,
            child: Stack(
              children: [
                if (isAndroid)
                  Positioned(
                    left: 8,
                    top: 8,
                    bottom: 8,
                    child: CentrodeIconButton(
                      icon: Icons.menu_rounded,
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      iconSize: 22,
                      iconColor: titleColor,
                      enableHover: false,
                    ),
                  ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_rounded, color: titleColor, size: UiIconSize.dense),
                      const SizedBox(width: UiSpacing.tight),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'CENTRODE',
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w800,
                                fontSize: UiFont.standard,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: '  Workspace Hub',
                              style: TextStyle(
                                color: subtitleColor,
                                fontWeight: FontWeight.w400,
                                fontSize: UiFont.standard,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isAndroid) {
      return content;
    }

    return ClipPath(
      clipper: _InwardLeftClipper(),
      child: content,
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
