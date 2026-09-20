import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/canvas_interactive_viewer.dart';
import '../../presentation/viewport_state.dart';
import '../../presentation/node_render_state.dart';
import '../../engine/interaction_engine.dart';
import '../../engine/config.dart';

/// Tier 1 reactive host that flattens camera gating logic into a single ListenableBuilder,
/// manages floating toolbar tap-dismissal, and wraps CanvasInteractiveViewer while preserving
/// the static child layer stack.
class CanvasCameraHost extends StatefulWidget {
  final ViewportController viewportController;
  final InteractionController interactionController;
  final NodeRenderState renderState;
  final ValueNotifier<Offset> elasticOverscrollNotifier;
  final Widget staticChild;

  const CanvasCameraHost({
    super.key,
    required this.viewportController,
    required this.interactionController,
    required this.renderState,
    required this.elasticOverscrollNotifier,
    required this.staticChild,
  });

  @override
  State<CanvasCameraHost> createState() => _CanvasCameraHostState();
}

class _CanvasCameraHostState extends State<CanvasCameraHost> {
  late final Listenable _gatingListenable;

  @override
  void initState() {
    super.initState();
    _gatingListenable = Listenable.merge([
      widget.viewportController.elasticMargins,
      widget.interactionController.panScaleEnabled,
      widget.viewportController.isTransitioningNotifier,
      widget.renderState.activeEditIdNotifier,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _gatingListenable,
      builder: (context, child) {
        final isEditing = widget.renderState.activeEditId != null;
        final isTransitioning =
            widget.viewportController.isTransitioningNotifier.value;
        final panScaleEnabled =
            widget.interactionController.panScaleEnabled.value;
        final viewerPanEnabled =
            panScaleEnabled && !isEditing && !isTransitioning;
        final boundaryMargin = widget.viewportController.elasticMargins.value;

        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: isEditing ? null : widget.renderState.hideFloatingToolbar,
          onDoubleTap: isEditing ? null : () {},
          onLongPress: isEditing ? null : () {},
          child: CanvasInteractiveViewer(
            transformationController:
                widget.viewportController.transformController,
            constrained: true,
            clipBehavior: Clip.none,
            boundaryMargin: boundaryMargin,
            contentBounds: widget.viewportController.contentBounds,
            minScale: widget.viewportController.currentMinScale,
            maxScale: widget.viewportController.currentMaxScale,
            scaleFactor: AppConfig.canvas.scaleFactor,
            panEnabled: viewerPanEnabled,
            scaleEnabled: viewerPanEnabled,
            onElasticOverscroll: (overscroll) {
              widget.elasticOverscrollNotifier.value = overscroll;
            },
            child: child!,
          ),
        );
      },
      child: widget.staticChild,
    );
  }
}
