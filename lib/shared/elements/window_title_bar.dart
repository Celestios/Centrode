import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:centrode/shared/elements/elements.dart';

class WindowTitleBar extends StatelessWidget {
  final String title;
  final Widget? child;

  const WindowTitleBar({super.key, required this.title, this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      height: 38,
      color: theme.colorScheme.surface,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DragToMoveArea(child: const SizedBox.expand()),
          ),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'CENTRODE',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: '  $title',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: child ?? const WindowControlButtons(),
          ),
        ],
      ),
    );
  }
}
