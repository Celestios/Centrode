import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mycelium/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:mycelium/presentation/widgets/left_repository_panel.dart';
import 'package:mycelium/shared/widgets/color_palette/color_palette.dart';

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
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: session.brushTypeNotifier,
              builder: (context, activeType, _) {
                return Column(
                  children: types.map((t) {
                    final isActive = activeType == t.type;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: InkWell(
                        onTap: () => session.setBrushType(t.type),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
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
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                t.icon,
                                size: 16,
                                color: isActive
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                t.label,
                                style: TextStyle(
                                  fontSize: 12,
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

            const SizedBox(height: 20),

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
                  customPresets: const [
                    Color(0xFF00E5FF),
                    Color(0xFFD500F9),
                    Color(0xFFFF6D00),
                    Color(0xFFFFD600),
                    Color(0xFFFFFFFF),
                    Color(0xFF818CF8),
                    Color(0xFF34D399),
                    Color(0xFFFBBF24),
                  ],
                  onColorSelected: (color) {
                    final hexStr = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
                    session.setBrushColor(hexStr);
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // ─── THICKNESS ───
            Text(
              'THICKNESS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<double>(
              valueListenable: session.brushThicknessNotifier,
              builder: (context, activeThickness, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: thicknesses.map((t) {
                    final isActive = activeThickness == t;
                    return GestureDetector(
                      onTap: () => session.setBrushThickness(t),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20,
                            height: 20,
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
                          const SizedBox(height: 4),
                          Text(
                            '${t.toInt()}px',
                            style: TextStyle(
                              fontSize: 9,
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
