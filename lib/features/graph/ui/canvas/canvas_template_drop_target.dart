import 'package:flutter/material.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/models/models.dart';

/// Encapsulates drag-and-drop template instantiation logic,
/// extracted from GraphCanvas to reduce widget complexity.
class CanvasTemplateDropTarget extends StatelessWidget {
  final ViewportController viewportController;
  final CommandQueueProcessor commandProcessor;
  final Widget child;

  const CanvasTemplateDropTarget({
    super.key,
    required this.viewportController,
    required this.commandProcessor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Template>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) async {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final localOffset = renderBox.globalToLocal(details.offset);
        final transform = viewportController.transformController.value;
        if (transform.determinant() == 0.0) return;
        final inverse = Matrix4.inverted(transform);
        final canvasOffset = MatrixUtils.transformPoint(
          inverse,
          localOffset,
        );
        await commandProcessor.templateMutations.instantiateTemplate(
          details.data.key.key.uuid,
          canvasOffset,
        );
      },
      builder: (context, candidateData, rejectedData) => child,
    );
  }
}
