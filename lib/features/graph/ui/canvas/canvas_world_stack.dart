import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';
import '../../presentation/viewport_state.dart';
import '../../presentation/workspace_tabs_controller.dart';
import '../../engine/drawing_interceptor.dart';
import 'layers/grid_layer.dart';
import 'layers/relation_layer.dart';
import 'layers/node_layer.dart';
import 'layers/overlay_layer.dart';
import 'layers/port_layer.dart';
import 'layers/active_drawing_layer.dart';

/// Tier 1 assembly that composes all 6 canvas world layers inside an UnboundedStack
/// in deterministic Z-order with clipping disabled.
class CanvasWorldStack extends StatelessWidget {
  final ValueListenable<ViewportStateGrid> viewportStateNotifier;
  final ValueNotifier<Offset?> mousePositionNotifier;
  final ValueNotifier<Offset> elasticOverscrollNotifier;
  final DrawingGestureInterceptor? drawingInterceptor;
  final TabSession session;

  const CanvasWorldStack({
    super.key,
    required this.viewportStateNotifier,
    required this.mousePositionNotifier,
    required this.elasticOverscrollNotifier,
    required this.drawingInterceptor,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return UnboundedStack(
      clipBehavior: Clip.none,
      children: [
        ValueListenableBuilder<ViewportStateGrid>(
          valueListenable: viewportStateNotifier,
          builder: (context, state, _) {
            return GridLayer(
              viewportState: state,
              mousePositionNotifier: mousePositionNotifier,
              elasticOverscrollNotifier: elasticOverscrollNotifier,
            );
          },
        ),
        const RelationLayer(),
        const NodeLayer(),
        const OverlayLayer(),
        const PortLayer(),
        ActiveDrawingLayer(
          drawingInterceptor: drawingInterceptor,
          session: session,
        ),
      ],
    );
  }
}
