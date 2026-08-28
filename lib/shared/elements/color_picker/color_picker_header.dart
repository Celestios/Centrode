import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'picker_color_model.dart';

/// Top row of the picker: before/after diff swatch, unified hex input pill with
/// paste/copy, and an optional close button.
class ColorPickerHeader extends StatelessWidget {
  final PickerColorModel model;
  final Color cardBg;
  final Color borderSubtle;
  final Color? originalColor;
  final Color initialColor;
  final VoidCallback? onClose;

  const ColorPickerHeader({
    super.key,
    required this.model,
    required this.cardBg,
    required this.borderSubtle,
    required this.originalColor,
    required this.initialColor,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final oldColor = originalColor ?? initialColor;

    return Row(
      children: [
        // Before / After Diff Swatch
        Container(
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UiRadius.control),
            border: Border.all(color: borderSubtle, width: UiStrokeWidth.subtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(flex: 4, child: Container(color: oldColor)),
              Container(width: 1, color: Colors.black26),
              Expanded(flex: 6, child: Container(color: model.currentColor)),
            ],
          ),
        ),
        const SizedBox(width: UiSpacing.tight),

        // Unified Hex Input Pill with Paste & Copy
        Expanded(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(UiRadius.control),
              border: Border.all(color: borderSubtle, width: UiStrokeWidth.subtle),
            ),
            child: Row(
              children: [
                const Text(
                  '#',
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.bold,
                    fontSize: UiFont.compact,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: model.hexController,
                    onSubmitted: model.onHexSubmitted,
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontWeight: FontWeight.bold,
                      fontSize: UiFont.compact,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: UiIconSize.dense,
                  icon: const Icon(Icons.paste_rounded),
                  tooltip: 'Paste Hex',
                  onPressed: model.pasteFromClipboard,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: UiIconSize.dense,
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy Hex',
                  onPressed: model.copyToClipboard,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                ),
              ],
            ),
          ),
        ),
        if (onClose != null) ...[
          const SizedBox(width: UiSpacing.tight),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: UiIconSize.standard,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ],
    );
  }
}
