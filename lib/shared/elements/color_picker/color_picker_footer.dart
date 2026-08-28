import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'picker_color_model.dart';

/// Footer: "Harmonic Random" generator and the auto-saved hint.
class ColorPickerFooter extends StatelessWidget {
  final PickerColorModel model;

  const ColorPickerFooter({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: InkWell(
            onTap: model.randomize,
            borderRadius: BorderRadius.circular(UiRadius.control),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.casino_outlined, size: UiIconSize.dense, color: Colors.white70),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Harmonic Random',
                      style: TextStyle(fontSize: UiFont.compact, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: UiSpacing.tight),
        const Text(
          'Auto-saved',
          style: TextStyle(fontSize: 10, color: Colors.white38),
        ),
      ],
    );
  }
}
