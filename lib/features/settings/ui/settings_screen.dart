import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import '../presentation/settings_controller.dart';
import 'widgets/settings_category_sidebar.dart';
import 'widgets/settings_canvas_pod.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final palette = CentrodeDerivedPalette.of(context);
    final contrastingShellColor = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.2),
      palette.theme?.secondaryColor ?? palette.surface.panelBackground,
    ).withValues(alpha: 0.92);

    Widget shell = Container(
      decoration: ShapeDecoration(
        color: contrastingShellColor,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(SettingsCanvasPod.podCornerRadius),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 32.0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6.0), // Tight spacing acting as pod borders
      child: Row(
        children: [
          SettingsCategorySidebar(controller: _controller),
          const SizedBox(width: 6.0), // Tight inter-pod gap
          Expanded(
            child: SettingsCanvasPod(controller: _controller),
          ),
        ],
      ),
    );

    if (isDesktop) {
      shell = Stack(
        children: [
          Positioned.fill(
            child: DragToMoveArea(child: const SizedBox.expand()),
          ),
          shell,
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Outside barrier: Touching outside closes the settings page, with a soft blur on the visible workspace
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),

          // Centered modal window
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: GestureDetector(
                // Consume taps inside the modal window so it doesn't dismiss
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 880.0,
                    maxHeight: 640.0,
                  ),
                  child: shell,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
