import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/features/settings/presentation/settings_controller.dart';

class SettingsCardWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const SettingsCardWrapper({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: UiSpacing.container),
      padding: UiInsets.container,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.035)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: UiAlpha.borderSubtle),
          width: UiStrokeWidth.subtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2.0),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
              ),
            ),
          ],
          const SizedBox(height: UiSpacing.standard),
          child,
        ],
      ),
    );
  }
}

class ThemeSettingsCard extends StatelessWidget {
  final SettingsController controller;

  const ThemeSettingsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.currentThemeName;

        return SettingsCardWrapper(
          title: 'Color Theme & Palette',
          subtitle: 'Select the overall visual appearance and contrast profile',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _ThemeButton(
                    label: 'Dark',
                    icon: Icons.dark_mode_outlined,
                    isSelected: current == 'dark',
                    onTap: () => controller.setTheme('dark'),
                  ),
                  const SizedBox(width: UiSpacing.standard),
                  _ThemeButton(
                    label: 'Light',
                    icon: Icons.light_mode_outlined,
                    isSelected: current == 'light',
                    onTap: () => controller.setTheme('light'),
                  ),
                  const SizedBox(width: UiSpacing.standard),
                  _ThemeButton(
                    label: 'Forest',
                    icon: Icons.forest_outlined,
                    isSelected: current == 'forest',
                    onTap: () => controller.setTheme('forest'),
                  ),
                ],
              ),
              const SizedBox(height: UiSpacing.container),
              _LiveThemeSwatchBar(primaryColor: primaryColor),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: UiMotion.fast,
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: UiSpacing.tight,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.18)
                : theme.cardColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(UiRadius.control),
            border: Border.all(
              color: isSelected ? primary : theme.dividerColor.withValues(alpha: 0.2),
              width: isSelected ? UiStrokeWidth.standard : UiStrokeWidth.subtle,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: UiIconSize.dense,
                color: isSelected ? primary : theme.iconTheme.color,
              ),
              const SizedBox(width: UiSpacing.tight),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveThemeSwatchBar extends StatelessWidget {
  final Color primaryColor;

  const _LiveThemeSwatchBar({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final currentTheme = AppThemeManager.instance.currentTheme;

    return Container(
      padding: UiInsets.standard,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(UiRadius.control),
      ),
      child: Row(
        children: [
          Text(
            'Palette Preview:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: UiSpacing.standard),
          _SwatchDot(color: currentTheme.primaryColor, label: 'Primary'),
          const SizedBox(width: UiSpacing.tight),
          _SwatchDot(color: currentTheme.secondaryColor, label: 'Secondary'),
          const SizedBox(width: UiSpacing.tight),
          _SwatchDot(color: currentTheme.accentColor, label: 'Accent'),
          const SizedBox(width: UiSpacing.tight),
          _SwatchDot(color: currentTheme.canvasAccentColor, label: 'Canvas'),
          const SizedBox(width: UiSpacing.tight),
          _SwatchDot(color: currentTheme.cardColor, label: 'Card'),
        ],
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  final Color color;
  final String label;

  const _SwatchDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
      ),
    );
  }
}

class ShaderSettingsCard extends StatelessWidget {
  final SettingsController controller;

  const ShaderSettingsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SettingsCardWrapper(
          title: 'Smart Glass & GLSL Shaders',
          subtitle: 'Optical refraction, backdrop blurring, and GPU metamaterial effects',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liquid Glass Fragment Shader',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Enables real-time dynamic refraction and edge lighting on floating panels',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CentrodeSquareToggle(
                    isActive: controller.enableLiquidGlass,
                    activeColor: primaryColor,
                    tooltip: 'Toggle Liquid Glass Shader',
                    icon: Icons.auto_awesome,
                    onTap: () => controller.setEnableLiquidGlass(!controller.enableLiquidGlass),
                  ),
                ],
              ),
              const SizedBox(height: UiSpacing.standard),
              CentrodeCompactSlider(
                label: 'Refraction Distortion Intensity',
                value: controller.refractionStrength,
                min: 0.0,
                max: 0.4,
                unit: '',
                activeColor: primaryColor,
                onChanged: controller.setRefractionStrength,
              ),
              const SizedBox(height: UiSpacing.standard),
              CentrodeCompactSlider(
                label: 'Optical Backdrop Blur Radius',
                value: controller.blurRadius,
                min: 0.0,
                max: 20.0,
                unit: 'px',
                activeColor: primaryColor,
                onChanged: controller.setBlurRadius,
              ),
            ],
          ),
        );
      },
    );
  }
}

class CanvasSettingsCard extends StatelessWidget {
  final SettingsController controller;

  const CanvasSettingsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final currentGrid = controller.gridSpacing;

        return SettingsCardWrapper(
          title: 'Canvas & Snapping Defaults',
          subtitle: 'Grid quantization, alignment tolerances, and interaction geometry',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Base Grid Spacing',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [10.0, 20.0, 40.0].map((spacing) {
                      final isSelected = currentGrid == spacing;
                      return Padding(
                        padding: const EdgeInsets.only(left: UiSpacing.tight),
                        child: GestureDetector(
                          onTap: () => controller.setGridSpacing(spacing),
                          child: AnimatedContainer(
                            duration: UiMotion.fast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.18)
                                  : theme.cardColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(UiRadius.control),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : theme.dividerColor.withValues(alpha: 0.2),
                                width: isSelected ? 1.0 : 0.8,
                              ),
                            ),
                            child: Text(
                              '${spacing.round()}px',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? primaryColor : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: UiSpacing.standard),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Snap Nodes & Ports to Grid',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Magnetically align dragged nodes to the background coordinate matrix',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CentrodeSquareToggle(
                    isActive: controller.snapToGrid,
                    activeColor: primaryColor,
                    tooltip: 'Toggle Snap to Grid',
                    icon: Icons.grid_on_rounded,
                    onTap: () => controller.setSnapToGrid(!controller.snapToGrid),
                  ),
                ],
              ),
              const SizedBox(height: UiSpacing.standard),
              CentrodeCompactSlider(
                label: 'Port & Node Snap Hitbox Distance',
                value: controller.snapDistance,
                min: 10.0,
                max: 80.0,
                unit: 'px',
                activeColor: primaryColor,
                onChanged: controller.setSnapDistance,
              ),
            ],
          ),
        );
      },
    );
  }
}
