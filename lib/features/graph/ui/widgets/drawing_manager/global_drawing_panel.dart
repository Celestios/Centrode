import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/presentation/widgets/left_repository_panel.dart';
import 'package:centrode/shared/widgets/color_palette/color_palette.dart';
import 'package:centrode/shared/elements/elements.dart';

class GlobalDrawingPanel extends StatelessWidget {
  const GlobalDrawingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final theme = Theme.of(context);

    final thicknesses = [2.0, 4.0, 8.0, 12.0, 16.0];

    final types = [
      (type: 'pen', label: 'Pen', icon: Icons.edit_rounded),
      (
        type: 'highlighter',
        label: 'Highlighter',
        icon: Icons.highlight_rounded,
      ),
      (type: 'line', label: 'Line', icon: Icons.linear_scale_rounded),
    ];

    return LeftRepositoryPanel(
      title: 'BRUSH SETTINGS',
      child: SingleChildScrollView(
        padding: UiInsets.container,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── BRUSH TYPE ───
            Text(
              'BRUSH TYPE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: UiSpacing.standard),
            ValueListenableBuilder<String>(
              valueListenable: session.brushTypeNotifier,
              builder: (context, activeType, _) {
                return Column(
                  children: types.map((t) {
                    final isActive = activeType == t.type;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: CentrodeButton(
                        onTap: () => session.setBrushType(t.type),
                        borderRadius: BorderRadius.circular(UiRadius.card),
                        enableHover: false,
                        child: AnimatedContainer(
                          duration: UiMotion.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(UiRadius.card),
                            color: isActive
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  )
                                : Colors.transparent,
                            border: Border.all(
                              color: isActive
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    )
                                  : theme.dividerColor.withValues(alpha: 0.1),
                              width: UiStrokeWidth.standard,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                t.icon,
                                size: UiIconSize.dense,
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                              ),
                              const SizedBox(width: UiSpacing.standard),
                              Text(
                                t.label,
                                style: TextStyle(
                                  fontSize: UiFont.standard,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: UiControlSize.dense),

            // ─── BRUSH COLOR ───
            ValueListenableBuilder<String>(
              valueListenable: session.brushColorNotifier,
              builder: (context, activeColor, _) {
                Color parsedColor;
                try {
                  final cleanHex = activeColor.replaceAll('#', '');
                  if (cleanHex.length == 6) {
                    parsedColor = Color(int.parse('FF$cleanHex', radix: 16));
                  } else if (cleanHex.length == 8) {
                    parsedColor = Color(int.parse(cleanHex, radix: 16));
                  } else {
                    parsedColor = const Color(0xFF00E5FF);
                  }
                } catch (_) {
                  parsedColor = const Color(0xFF00E5FF);
                }

                return UniversalColorPalette(
                  initialColor: parsedColor,
                  mode: ColorPaletteMode.advanced,
                  showAlpha: true,
                  customPresets: CentrodeDerivedPalette.of(context).swatches,
                  onColorSelected: (color) {
                    final hexStr =
                        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
                    session.setBrushColor(hexStr);
                  },
                );
              },
            ),

            const SizedBox(height: UiSpacing.gutter),

            // ─── THICKNESS ───
            Text(
              'THICKNESS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: UiSpacing.standard),
            ValueListenableBuilder<double>(
              valueListenable: session.brushThicknessNotifier,
              builder: (context, activeThickness, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: thicknesses.map((t) {
                    final isActive = activeThickness == t;
                    return CentrodeButton(
                      onTap: () => session.setBrushThickness(t),
                      enableHover: false,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: UiMotion.fast,
                            width: 20,
                            height: UiControlSize.dense,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.transparent,
                            ),
                            child: Center(
                              child: Container(
                                width: t / 2 + 2,
                                height: t / 2 + 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: UiSpacing.tight),
                          Text(
                            '${t.toInt()}px',
                            style: TextStyle(
                              fontSize: UiFont.micro,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
