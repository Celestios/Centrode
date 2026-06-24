import 'package:flutter/material.dart';
import '../../../engine/config.dart';
import 'node_visual_constants.dart';

class HighlightFrame extends StatelessWidget {
  final Widget child;
  final bool isEditing;
  final bool isSelected;
  final double borderRadius;
  final String shape;
  final Size size;
  final double scale;

  const HighlightFrame({
    super.key,
    required this.child,
    required this.isEditing,
    required this.isSelected,
    required this.borderRadius,
    required this.shape,
    required this.size,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = isSelected || isEditing;
    if (!isHighlighted) return child;

    final double stroke = (isEditing ? 1.0 : 0.6) * scale;
    final double gap = 1.5 * scale;
    final double totalOffset = gap + stroke;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: -totalOffset,
          top: -totalOffset,
          right: -totalOffset,
          bottom: -totalOffset,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: shape == 'circle'
                    ? BorderRadius.circular((size.width + totalOffset * 2) / 2)
                    : BorderRadius.circular(borderRadius + totalOffset),
                border: Border.all(
                  color: isEditing
                      ? Color(NodeVisualConstants.editingBorderColor)
                      : AppConfig.visuals.selectionAccent,
                  width: stroke,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
