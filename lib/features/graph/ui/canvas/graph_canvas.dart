import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../presentation/graph_metrics.dart';
import '../../store/graph_repository.dart';
import '../../presentation/node_render_state.dart';
import '../../presentation/viewport_state.dart';
import '../../engine/interaction_engine.dart';
import '../../engine/base_interaction_state.dart';
import 'package:mycelium/features/graph/engine/interaction_facade.dart';

import '../../../../src/rust/domain/base_models.dart' show BoundingBox;
import 'layers/relation_layer.dart';
import 'layers/node_layer.dart';
import 'layers/overlay_layer.dart';
import 'layers/grid_layer.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  late final ViewportController _viewportController;
  InteractionController? _interactionController;
  final Logger _log = Logger('GraphCanvas');

  bool _hasInitialFramed = false;
  EdgeInsets? _lastElasticMargins;

  @override
  void initState() {
    super.initState();
    _log.info('Initializing GraphCanvas.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataController = context.read<GraphDataController>();
      final renderState = context.read<NodeRenderState>();

      // 1. Initialize your ViewportController bound directly to the data query layer
      _viewportController = ViewportController(dataController);

      // 2. Build the Environment Facade with separate ViewportController access
      final environment = CanvasInteractionEnvironment(
        dataController: dataController,
        renderState: renderState,
        viewportController: _viewportController,
        getScale: () =>
            _viewportController.transformController.value.getMaxScaleOnAxis(),
      );

      // 3. Initialize the pure FSM Engine
      _interactionController = InteractionController(
        transformController: _viewportController.transformController,
        environment: environment,
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    _viewportController.dispose();
    _interactionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderState = context.watch<NodeRenderState>();
    final dataController = context.read<GraphDataController>();
    final interactionController = _interactionController;

    // If InteractionController not yet initialized, show loading
    if (!mounted || interactionController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiProvider(
      providers: [
        Provider<ViewportController>.value(value: _viewportController),
        Provider<InteractionController>.value(value: interactionController),
      ],
      child: ValueListenableBuilder<CanvasInteractionState>(
        valueListenable: interactionController.state,
        builder: (context, state, _) {
          return Stack(
            children: [
              MouseRegion(
                cursor: state.cursor,
                child: Listener(
                  onPointerDown: interactionController.handlePointerDown,
                  onPointerMove: interactionController.handlePointerMove,
                  onPointerUp: interactionController.handlePointerUp,
                  onPointerCancel: interactionController.handlePointerCancel,
                  onPointerHover: interactionController.handlePointerHover,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewport = constraints.biggest;

                      _viewportController.updateViewportSize(viewport);

                      if (!_hasInitialFramed && viewport != Size.zero) {
                        _hasInitialFramed = true;
                        _log.info(
                          'CANVAS: Triggering initial camera framing on bounds.',
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _viewportController.focusOnBounds(
                            dataController.canvasBounds.value,
                          );
                        });
                      }

                      // Listen to the elastic boundaries from the Rust core
                      return ValueListenableBuilder<BoundingBox>(
                        valueListenable: dataController.canvasBounds,
                        builder: (context, bounds, _) {
                          // Calculate dynamic padding to provide the "Elastic Buffer"
                          final padding = AppConfig.canvas.boundaryMargin;

                          // Scale-Aware Geometric Decoupling.
                          // The margin must NEVER be smaller than the maximum possible zoomed-out screen.
                          final minScale = AppConfig.canvas.minScale;
                          final effectiveViewportWidth =
                              viewport.width / minScale;
                          final effectiveViewportHeight =
                              viewport.height / minScale;

                          final leftBound = math.max(
                            effectiveViewportWidth,
                            -bounds.minX.toDouble() + padding,
                          );
                          final topBound = math.max(
                            effectiveViewportHeight,
                            -bounds.minY.toDouble() + padding,
                          );
                          final rightBound = math.max(
                            effectiveViewportWidth,
                            bounds.maxX.toDouble() + padding,
                          );
                          final bottomBound = math.max(
                            effectiveViewportHeight,
                            bounds.maxY.toDouble() + padding,
                          );

                          final elasticMargins = EdgeInsets.fromLTRB(
                            leftBound,
                            topBound,
                            rightBound,
                            bottomBound,
                          );

                          // Trace the pan-space boundaries only upon mutation
                          if (_lastElasticMargins != elasticMargins) {
                            _lastElasticMargins = elasticMargins;
                            _log.fine(
                              'GEOMETRY: Elastic Margins calculated: L:$leftBound, T:$topBound, R:$rightBound, B:$bottomBound',
                            );
                          }

                          return InteractiveViewer(
                            transformationController:
                                _viewportController.transformController,
                            constrained: false,
                            boundaryMargin: elasticMargins,
                            minScale: AppConfig.canvas.minScale,
                            maxScale: AppConfig.canvas.maxScale,
                            scaleFactor: AppConfig.canvas.scaleFactor,
                            panEnabled: state is CanvasIdle,
                            scaleEnabled: state is CanvasIdle,
                            child: GestureDetector(
                              onTap: () {
                                renderState.hideDeleteMenu();
                              },
                              onDoubleTap: () {},
                              onLongPress: () {},
                              // 1x1 Mathematical Reference Plane
                              child: SizedBox(
                                width: 10000,
                                height: 10000,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ValueListenableBuilder<ViewportStateGrid>(
                                      valueListenable: _viewportController
                                          .viewportStateNotifier,
                                      builder: (context, state, _) {
                                        return GridLayer(viewportState: state);
                                      },
                                    ),
                                    const RelationLayer(),
                                    const NodeLayer(),
                                    OverlayLayer(interactionState: state),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
