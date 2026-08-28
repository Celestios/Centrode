import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import '../theme/design_tokens.dart';
import 'window_control_buttons.dart';

/// Centralized unified window title bar for Centrode.
class CentrodeWindowTitleBar extends StatelessWidget {
  final Widget? leading;
  final Widget? center;
  final String? title;
  final List<Widget> actions;
  final bool showWindowControls;
  final double height;
  final bool enableGlass;

  const CentrodeWindowTitleBar({
    super.key,
    this.leading,
    this.center,
    this.title,
    this.actions = const [],
    this.showWindowControls = true,
    this.height = UiControlSize.tile,
    this.enableGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    Widget content = Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: DragToMoveArea(child: const SizedBox.expand()),
        ),
        Row(
          children: [
            if (leading != null) leading!,
            const Spacer(),
            if (actions.isNotEmpty) ...actions,
            if (showWindowControls) const WindowControlButtons(),
          ],
        ),
        if (center != null)
          Center(child: center!)
        else if (title != null)
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'CENTRODE',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w800,
                      fontSize: UiFont.standard,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: '  $title',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w400,
                      fontSize: UiFont.standard,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (enableGlass) {
      return GlassPanel(
        borderRadius: UiRadius.none,
        blur: 16.0,
        color: theme.cardColor.withValues(alpha: 0.65),
        height: height,
        shadow: BoxShadow(
          color: theme.dividerColor.withValues(alpha: 0.2),
          blurRadius: 0,
          offset: const Offset(0, 1),
        ),
        child: content,
      );
    }

    return Container(
      height: height,
      color: theme.colorScheme.surface,
      child: content,
    );
  }
}
