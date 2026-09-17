import 'package:centrode/features/settings/ui/settings_screen.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class PanelFooterSection extends StatelessWidget {
  const PanelFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.person_outline,
              size: UiIconSize.standard,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Account',
              style: theme.textTheme.bodyMedium,
            ),
            dense: true,
            onTap: () {},
          ),
          const _SettingsTile(),
          ListTile(
            leading: Icon(
              Icons.help_outline,
              size: UiIconSize.standard,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Help',
              style: theme.textTheme.bodyMedium,
            ),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              size: UiIconSize.standard,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'About',
              style: theme.textTheme.bodyMedium,
            ),
            dense: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatefulWidget {
  const _SettingsTile();

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  final GlobalKey _tileKey = GlobalKey();

  void _openSettings() {
    final renderBox = _tileKey.currentContext?.findRenderObject() as RenderBox?;
    final buttonCenter = renderBox != null
        ? renderBox.localToGlobal(renderBox.size.center(Offset.zero))
        : const Offset(100.0, 600.0);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final screenSize = MediaQuery.of(context).size;
          final alignX = screenSize.width > 0
              ? (buttonCenter.dx / screenSize.width) * 2 - 1
              : -0.8;
          final alignY = screenSize.height > 0
              ? (buttonCenter.dy / screenSize.height) * 2 - 1
              : 0.8;
          final originAlignment = Alignment(alignX, alignY);

          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final isReversing = animation.status == AnimationStatus.reverse;

              final double scale;
              final double opacity;

              if (isReversing) {
                // When closing: disappear early while in motion before fully minimizing
                final t = Curves.easeInQuad.transform(animation.value);
                scale = 0.35 + 0.65 * t;
                opacity = ((animation.value - 0.45) / 0.55).clamp(0.0, 1.0);
              } else {
                // When opening: smooth bloom outward from the button
                final t = Curves.easeOutCubic.transform(animation.value);
                scale = 0.15 + 0.85 * t;
                opacity = (animation.value / 0.35).clamp(0.0, 1.0);
              }

              return Transform.scale(
                alignment: originAlignment,
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      key: _tileKey,
      leading: Icon(
        Icons.settings_outlined,
        size: UiIconSize.standard,
        color: theme.iconTheme.color,
      ),
      title: Text(
        'Settings',
        style: theme.textTheme.bodyMedium,
      ),
      dense: true,
      onTap: _openSettings,
    );
  }
}
