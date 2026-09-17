import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import '../../presentation/settings_category.dart';
import '../../presentation/settings_controller.dart';
import 'settings_canvas_pod.dart';

class SettingsCategorySidebar extends StatelessWidget {
  final SettingsController controller;

  const SettingsCategorySidebar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassPanel(
      width: 195.0,
      borderRadius: SettingsCanvasPod.podCornerRadius,
      border: Border.all(color: Colors.transparent, width: 0.0),
      color: isDark
          ? const Color(0xFF1B1B22).withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.90),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12.0,
          right: 12.0,
          top: 14.0,
          bottom: 14.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top header aligned with right pod controls (height: 38.0)
            SizedBox(
              height: 38.0,
              child: Row(
                children: [
                  const SizedBox(width: 4.0),
                  Icon(
                    Icons.settings_suggest_rounded,
                    size: UiIconSize.standard,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: UiSpacing.standard),
                  Text(
                    'Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: SettingsCategory.values.map((category) {
                      final isSelected = controller.selectedCategory == category;
                      return _CategoryTile(
                        category: category,
                        isSelected: isSelected,
                        onTap: () => controller.selectCategory(category, requestScroll: true),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final SettingsCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final Color bgColor;
    final Border? border;
    if (widget.isSelected) {
      bgColor = primaryColor.withValues(alpha: 0.16);
      border = Border.all(
        color: primaryColor.withValues(alpha: 0.35),
        width: UiStrokeWidth.standard,
      );
    } else if (_isHovered) {
      bgColor = theme.dividerColor.withValues(alpha: UiAlpha.subtle);
      border = null;
    } else {
      bgColor = Colors.transparent;
      border = null;
    }

    final textColor = widget.isSelected
        ? primaryColor
        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: UiMotion.fast,
          margin: const EdgeInsets.symmetric(vertical: 3.0),
          padding: const EdgeInsets.symmetric(
            horizontal: UiSpacing.standard,
            vertical: 10.0,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(UiRadius.card),
            border: border,
          ),
          child: Row(
            children: [
              Icon(
                widget.category.icon,
                size: UiIconSize.standard,
                color: textColor,
              ),
              const SizedBox(width: UiSpacing.standard),
              Expanded(
                child: Text(
                  widget.category.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
