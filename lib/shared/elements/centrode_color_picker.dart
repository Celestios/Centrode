import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'color_picker/picker_color_model.dart';
import 'color_picker/color_picker_header.dart';
import 'color_picker/color_picker_sv_canvas.dart';
import 'color_picker/color_picker_hue_slider.dart';
import 'color_picker/color_picker_alpha_slider.dart';
import 'color_picker/color_picker_swatch_grid.dart';
import 'color_picker/color_picker_footer.dart';

/// 100% Opaque Neutral Color Control Box Panel.
///
/// Provides a 2D Saturation/Value canvas, continuous Hue and Alpha sliders,
/// direct Hex input with copy/paste, merged Theme & Map swatches, and an
/// anonymous moving auto-recents buffer. Color state lives in [PickerColorModel];
/// the section widgets are split into `color_picker/`.
class CentrodeColorPicker extends StatefulWidget {
  /// Initial / active color being edited.
  final Color initialColor;

  /// Optional original color to show in the old/new diff swatch pill.
  final Color? originalColor;

  /// Callback when the active color changes.
  final ValueChanged<Color>? onColorChanged;

  /// Optional map-persisted custom swatches.
  final List<Color> mapColors;

  /// Optional list of recent colors (FIFO buffer).
  final List<Color> recentColors;

  /// Callback when a recent color is added/updated.
  final ValueChanged<Color>? onRecentColorAdded;

  /// Optional callback when the close button is clicked.
  final VoidCallback? onClose;

  const CentrodeColorPicker({
    super.key,
    required this.initialColor,
    this.originalColor,
    this.onColorChanged,
    this.mapColors = const [],
    this.recentColors = const [],
    this.onRecentColorAdded,
    this.onClose,
  });

  @override
  State<CentrodeColorPicker> createState() => _CentrodeColorPickerState();
}

class _CentrodeColorPickerState extends State<CentrodeColorPicker> {
  late PickerColorModel _model;

  @override
  void initState() {
    super.initState();
    _model = PickerColorModel(
      initialColor: widget.initialColor,
      onColorChanged: widget.onColorChanged,
      onRecentColorAdded: widget.onRecentColorAdded,
      recentColors: widget.recentColors,
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = palette.surface.panelBackground;
    final cardBg = palette.surface.cardBackground;
    final borderSubtle = palette.border(Theme.of(context).dividerColor);

    // Merge theme swatches + active map colors
    final mergedSwatches = <Color>[
      ...palette.swatches,
      ...widget.mapColors.where((c) => !palette.swatches.contains(c)),
    ].take(12).toList();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(UiRadius.panel),
        border: Border.all(color: borderSubtle, width: UiStrokeWidth.standard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: UiInsets.standard,
      child: ListenableBuilder(
        listenable: _model,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header: Before/After Diff Swatch + Unified Hex Input
              ColorPickerHeader(
                model: _model,
                cardBg: cardBg,
                borderSubtle: borderSubtle,
                originalColor: widget.originalColor,
                initialColor: widget.initialColor,
                onClose: widget.onClose,
              ),

              const SizedBox(height: UiSpacing.standard),

              // 2. 2D Saturation / Value Gradient Canvas
              ColorPickerSvCanvas(model: _model, borderSubtle: borderSubtle),

              const SizedBox(height: UiSpacing.tight),

              // 3. Hue Spectrum Slider
              ColorPickerHueSlider(model: _model, borderSubtle: borderSubtle),

              const SizedBox(height: UiSpacing.tight),

              // 4. Alpha Transparency Slider
              ColorPickerAlphaSlider(model: _model, borderSubtle: borderSubtle),

              const SizedBox(height: UiSpacing.standard),

              // 5. Merged Swatches + Anonymous Auto-Recents Moving Row
              ColorPickerSwatchGrid(
                model: _model,
                swatches: mergedSwatches,
                borderSubtle: borderSubtle,
              ),

              const SizedBox(height: UiSpacing.tight),

              // 6. Footer: Harmonic Random Button + Map Persistence Hint
              ColorPickerFooter(model: _model),
            ],
          );
        },
      ),
    );
  }
}
