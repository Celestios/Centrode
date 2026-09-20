import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../engine/interaction_engine.dart';

/// Tier 1 widget that routes raw pointer events to the InteractionController
/// and disambiguates right-click drag (canvas panning) from right-click tap (context menu).
class CanvasGestureRouter extends StatefulWidget {
  final InteractionController interactionController;
  final ValueNotifier<Offset?> mousePositionNotifier;
  final void Function(Offset position) onContextMenuRequested;
  final void Function(Offset position)? onMousePositionChanged;
  final VoidCallback? onHoverExit;
  final Widget child;

  const CanvasGestureRouter({
    super.key,
    required this.interactionController,
    required this.mousePositionNotifier,
    required this.onContextMenuRequested,
    this.onMousePositionChanged,
    this.onHoverExit,
    required this.child,
  });

  @override
  State<CanvasGestureRouter> createState() => _CanvasGestureRouterState();
}

class _CanvasGestureRouterState extends State<CanvasGestureRouter> {
  int _lastMousePosMs = 0;
  Offset? _rightClickDownScreenPos;
  bool _isRightClickDrag = false;

  void _throttleMousePosition(Offset localPosition) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMousePosMs >= 16) {
      _lastMousePosMs = now;
      widget.mousePositionNotifier.value = localPosition;
      widget.onMousePositionChanged?.call(localPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MouseCursor>(
      valueListenable: widget.interactionController.cursor,
      builder: (context, cursor, child) {
        return MouseRegion(
          cursor: cursor,
          onExit: (_) {
            widget.mousePositionNotifier.value = null;
            widget.onHoverExit?.call();
          },
          child: child,
        );
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.mouse &&
              event.buttons == kSecondaryMouseButton) {
            _rightClickDownScreenPos = event.position;
            _isRightClickDrag = false;
          }
          widget.interactionController.handlePointerDown(event);
        },
        onPointerMove: (event) {
          if (_rightClickDownScreenPos != null && !_isRightClickDrag) {
            final dragDistance =
                (event.position - _rightClickDownScreenPos!).distance;
            if (dragDistance > 5.0) {
              _isRightClickDrag = true;
            }
          }
          widget.interactionController.handlePointerMove(event);
          _throttleMousePosition(event.localPosition);
        },
        onPointerUp: (event) {
          if (_rightClickDownScreenPos != null && !_isRightClickDrag) {
            widget.onContextMenuRequested(_rightClickDownScreenPos!);
          }
          _rightClickDownScreenPos = null;
          _isRightClickDrag = false;
          widget.interactionController.handlePointerUp(event);
        },
        onPointerCancel: (event) {
          _rightClickDownScreenPos = null;
          _isRightClickDrag = false;
          widget.interactionController.handlePointerCancel(event);
          widget.mousePositionNotifier.value = null;
          widget.onHoverExit?.call();
        },
        onPointerHover: (event) {
          widget.interactionController.handlePointerHover(event);
          _throttleMousePosition(event.localPosition);
        },
        child: widget.child,
      ),
    );
  }
}
