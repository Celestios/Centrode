import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

class WindowControlButtons extends StatefulWidget {
  const WindowControlButtons({super.key});

  @override
  State<WindowControlButtons> createState() => _WindowControlButtonsState();
}

class _WindowControlButtonsState extends State<WindowControlButtons>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximizeState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = true;
      });
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = false;
      });
    }
  }

  Future<void> _checkMaximizeState() async {
    final maximized = await windowManager.isMaximized();
    if (mounted && _isMaximized != maximized) {
      setState(() {
        _isMaximized = maximized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color =
        theme.iconTheme.color ?? (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHoverButton(
            icon: Icons.minimize_rounded,
            color: color,
            isDark: isDark,
            onPressed: () => windowManager.minimize(),
          ),
          const SizedBox(width: UiSpacing.tight),
          _buildHoverButton(
            icon: _isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            color: color,
            isDark: isDark,
            onPressed: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
              _checkMaximizeState();
            },
          ),
          const SizedBox(width: UiSpacing.tight),
          _buildHoverButton(
            icon: Icons.close_rounded,
            color: color,
            isDark: isDark,
            isClose: true,
            onPressed: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  Widget _buildHoverButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isClose = false,
    required VoidCallback onPressed,
  }) {
    final defaultBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final hoverBg = isClose
        ? Colors.red.withValues(alpha: 0.85)
        : (isDark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.black.withValues(alpha: 0.12));

    return HoverScaleButton(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(UiRadius.card),
      hoverScale: 1.0,
      pressScale: 1.0,
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: UiMotion.fast,
          width: 32,
          height: UiControlSize.standard,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isHovered ? hoverBg : defaultBg,
            borderRadius: BorderRadius.circular(UiRadius.card),
          ),
          child: Icon(
            icon,
            size: UiIconSize.dense,
            color: (isHovered && isClose)
                ? Colors.white
                : color.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }
}
