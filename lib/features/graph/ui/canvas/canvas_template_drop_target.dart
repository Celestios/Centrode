import 'package:flutter/material.dart';
import 'package:centrode/features/graph/models/models.dart';

/// Encapsulates drag-and-drop template detection, emitting local screen drop positions
/// to eliminate matrix inversions and direct Tier 3 store calls inside the UI widget.
class CanvasTemplateDropTarget extends StatelessWidget {
  final void Function(String templateKey, Offset localScreenOffset)
  onTemplateDropped;
  final Widget child;

  const CanvasTemplateDropTarget({
    super.key,
    required this.onTemplateDropped,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Template>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localOffset = renderBox.globalToLocal(details.offset);
        onTemplateDropped(details.data.key.key.uuid, localOffset);
      },
      builder: (context, candidateData, rejectedData) => child,
    );
  }
}
