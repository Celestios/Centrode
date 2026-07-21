import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../store/graph_data_query_controller.dart';
import '../../store/command_queue_processor.dart';
import '../../presentation/node_render_state.dart';
import 'package:mycelium/shared/copy_buffer.dart';
import 'paste_handler.dart';
import 'package:mycelium/features/graph/presentation/viewport_state.dart';

/// Dedicated keyboard handler for canvas shortcuts (Ctrl+C/X/V).
/// This widget owns the Focus and does not rebuild on provider changes.
class CanvasKeyboardHandler extends StatefulWidget {
  final Widget child;
  final ViewportController? viewportController;
  final ValueNotifier<Offset?> mousePositionNotifier;

  const CanvasKeyboardHandler({
    super.key,
    required this.child,
    this.viewportController,
    required this.mousePositionNotifier,
  });

  @override
  State<CanvasKeyboardHandler> createState() => _CanvasKeyboardHandlerState();
}

class _CanvasKeyboardHandlerState extends State<CanvasKeyboardHandler> {
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final queryController = context.read<GraphDataQueryController>();
    final commandProcessor = context.read<CommandQueueProcessor>();
    final renderState = context.read<NodeRenderState>();

    if (event.logicalKey == LogicalKeyboardKey.keyC &&
        HardwareKeyboard.instance.isControlPressed) {
      _handleCopy(queryController, renderState);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyX &&
        HardwareKeyboard.instance.isControlPressed) {
      _handleCut(queryController, renderState);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        HardwareKeyboard.instance.isControlPressed) {
      _handlePaste(commandProcessor, renderState);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleCopy(
    GraphDataQueryController queryController,
    NodeRenderState renderState,
  ) {
    final selectedIds = renderState.selectedEntities.toList();
    if (selectedIds.isEmpty) return;

    final copyBuffer = context.read<CopyBuffer>();
    copyBuffer.copy(selectedIds, queryController);
  }

  void _handleCut(
    GraphDataQueryController queryController,
    NodeRenderState renderState,
  ) {
    final selectedIds = renderState.selectedEntities.toList();
    if (selectedIds.isEmpty) return;

    final copyBuffer = context.read<CopyBuffer>();
    copyBuffer.copy(selectedIds, queryController);
    renderState.deleteSelectedEntities();
  }

  Future<void> _handlePaste(
    CommandQueueProcessor commandProcessor,
    NodeRenderState renderState,
  ) async {
    if (renderState.activeEditId != null) return;

    final mousePos = widget.mousePositionNotifier.value;
    if (mousePos == null) return;

    final viewportController = widget.viewportController;
    if (viewportController == null) return;

    final transform = viewportController.transformController.value;
    if (transform.determinant() == 0.0) return;

    final canvasPos = MatrixUtils.transformPoint(
      Matrix4.inverted(transform),
      mousePos,
    );

    final copyBuffer = context.read<CopyBuffer>();
    if (copyBuffer.hasData) {
      final newIds = await copyBuffer.paste(canvasPos, commandProcessor);
      if (newIds.isNotEmpty) {
        renderState.selectEntities(newIds);
      }
      return;
    }

    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      await pasteTextToCanvas(
        dataController: commandProcessor,
        text: data.text!,
        canvasPosition: canvasPos,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
