import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

class AnalyticsBox extends StatelessWidget {
  const AnalyticsBox({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = CentrodeDerivedPalette.of(context);
    final primaryColor = theme.colorScheme.primary;

    final titleColor = palette.textOn(palette.surface.cardBackground);
    final subtitleColor = titleColor.withValues(alpha: isDark ? 0.60 : 0.55);

    final cardBg = palette.surface.cardBackground;
    final gradientEnd = Color.alphaBlend(
      primaryColor.withValues(alpha: isDark ? 0.14 : 0.08),
      cardBg,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: GlassPanel(
        height: WorkspaceTokens.analyticsBoxHeight,
        borderRadius: UiRadius.panel,
        enableBackdrop: false,
        color: cardBg,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [cardBg, gradientEnd],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : primaryColor.withValues(alpha: 0.18),
          width: UiStrokeWidth.subtle,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(UiRadius.panel),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 340,
                child: IgnorePointer(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.transparent, Colors.white],
                        stops: [0.0, 0.45],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: CentrodeContourPattern(
                      primaryColor: primaryColor,
                      config: const ContourConfig.topographic(
                        origin: ContourOrigin.bottomRight,
                        layerCount: 6,
                        amplitude: 0.30,
                        frequency: 1.35,
                        fillOpacity: 0.22,
                        lineOpacity: 0.45,
                        strokeWidth: 0.9,
                        seed: 108,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UiSpacing.container,
                    vertical: UiSpacing.standard,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: UiIconSize.standard,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: UiSpacing.standard),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Build, analyze, and collaborate with your maps',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: UiSpacing.standard),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.10),
                                    borderRadius: BorderRadius.circular(UiRadius.pill),
                                    border: Border.all(
                                      color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                                      width: UiStrokeWidth.subtle,
                                    ),
                                  ),
                                  child: Text(
                                    'Coming in future versions',
                                    style: TextStyle(
                                      fontSize: UiFont.micro,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? primaryColor.withValues(alpha: 0.95)
                                          : primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Workspace analytics, knowledge metrics, and graph insights will be added in future versions.',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subtitleColor,
                                fontSize: UiFont.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
