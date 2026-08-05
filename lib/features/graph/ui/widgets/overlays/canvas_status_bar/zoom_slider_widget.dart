import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../presentation/viewport_state.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

// -----------------------------------------------------------------------------
// BOTTOM RIGHT: Zoom slider & percentage indicator
// -----------------------------------------------------------------------------
class ZoomSliderWidget extends StatelessWidget {
  const ZoomSliderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewportController = context.read<ViewportController>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    return GlassPanel(
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ValueListenableBuilder<ViewportStateGrid>(
        valueListenable: viewportController.viewportStateNotifier,
        builder: (context, gridState, _) {
          final double scale = gridState.scale;
          final percent = (scale * 100).toInt();

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.zoom_out,
                  color: textColor.withValues(alpha: 0.7),
                  size: 14,
                ),
                onPressed: () => _updateZoom(
                  viewportController,
                  (scale - 0.1).clamp(0.2, 3.0),
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              SizedBox(
                width: 80,
                height: 20,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: theme.dividerColor.withValues(
                      alpha: 0.3,
                    ),
                    thumbColor: primaryColor,
                  ),
                  child: Slider(
                    value: scale.clamp(0.2, 3.0),
                    min: 0.2,
                    max: 3.0,
                    onChanged: (val) => _updateZoom(viewportController, val),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.zoom_in,
                  color: textColor.withValues(alpha: 0.7),
                  size: 14,
                ),
                onPressed: () => _updateZoom(
                  viewportController,
                  (scale + 0.1).clamp(0.2, 3.0),
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Reset zoom to 100%',
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _updateZoom(viewportController, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: Icon(
                  Icons.center_focus_strong,
                  color: textColor.withValues(alpha: 0.7),
                  size: 14,
                ),
                tooltip: 'Reset zoom to 100%',
                onPressed: () => _updateZoom(viewportController, 1.0),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateZoom(ViewportController controller, double newScale) {
    controller.updateScale(newScale);
  }
}
