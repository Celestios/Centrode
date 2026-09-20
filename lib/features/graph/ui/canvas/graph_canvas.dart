import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/copy_buffer.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import '../../engine/config.dart';
import '../../engine/interaction_engine.dart';
import '../../store/graph_data_query_controller.dart';
import '../../store/command_queue_processor.dart';
import '../../presentation/node_render_state.dart';
import '../../presentation/viewport_state.dart';
import '../../presentation/workspace_tabs_controller.dart';
import '../../presentation/canvas_lifecycle_coordinator.dart';
import '../../presentation/canvas_context_menu_coordinator.dart';
import '../widgets/template_manager/save_template_dialog.dart';
import 'canvas_overlay_layout.dart';
import 'canvas_keyboard_handler.dart';
import 'canvas_context_menu.dart';
import 'canvas_template_drop_target.dart';
import 'canvas_stage_scope.dart';
import 'canvas_gesture_router.dart';
import 'canvas_camera_host.dart';
import 'canvas_world_stack.dart';

/// Root canvas assembly shell coordinating the camera, layers, gestures, overlays,
/// and lifecycle subsystems.
class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas>
    with TickerProviderStateMixin {
  final Logger _log = Logger('GraphCanvas');
  bool _initialized = false;
  late final CanvasLifecycleCoordinator _lifecycleCoordinator;
  late final CanvasContextMenuCoordinator _contextMenuCoordinator;
  final ValueNotifier<Offset?> _mousePositionNotifier = ValueNotifier<Offset?>(
    null,
  );
  final ValueNotifier<Offset> _elasticOverscrollNotifier =
      ValueNotifier<Offset>(Offset.zero);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _log.info('Initializing GraphCanvas assembly shell.');
      final queryController = context.read<GraphDataQueryController>();
      final commandProcessor = context.read<CommandQueueProcessor>();
      final renderState = context.read<NodeRenderState>();
      final tabsController = context.read<WorkspaceTabsController>();
      final session = tabsController.activeSession;

      _lifecycleCoordinator = CanvasLifecycleCoordinator(
        session: session,
        queryController: queryController,
        commandProcessor: commandProcessor,
        renderState: renderState,
        onSaveTemplateRequest: (nodeIds, relationIds) async {
          final name = await showSaveTemplateDialog(context);
          if (name != null) {
            await commandProcessor.templateMutations.saveTemplateFromSelection(
              name,
              nodeIds,
              relationIds,
            );
          }
        },
      );
      _lifecycleCoordinator.attachVsync(this);

      _contextMenuCoordinator = CanvasContextMenuCoordinator(
        queryController: queryController,
        renderState: renderState,
        viewportController: _lifecycleCoordinator.viewportController,
        session: session,
        interactionContext: _lifecycleCoordinator.interactionEnv,
        onContextMenuResolved: (resolution) {
          CanvasContextMenu.show(
            context: context,
            position: resolution.screenPosition,
            targetRect: resolution.targetNodeRect,
            avoidRect: resolution.avoidRect,
            queryController: queryController,
            commandProcessor: commandProcessor,
            renderState: renderState,
            copyBuffer: context.read<CopyBuffer>(),
            viewportController: _lifecycleCoordinator.viewportController,
          );
        },
      );
    }
  }

  @override
  void dispose() {
    CanvasContextMenu.dismiss();
    if (_initialized) {
      _lifecycleCoordinator.detachVsync();
      _lifecycleCoordinator.dispose();
      _contextMenuCoordinator.dispose();
    }
    _mousePositionNotifier.dispose();
    _elasticOverscrollNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final renderState = context.watch<NodeRenderState>();
    final commandProcessor = context.read<CommandQueueProcessor>();
    final queryController = context.watch<GraphDataQueryController>();
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final vp = _lifecycleCoordinator.viewportController;
    final interaction = _lifecycleCoordinator.interactionController;

    final backdropRepaintListenable = Listenable.merge([
      vp.transformController,
      renderState.movementNotifier,
    ]);

    return MultiProvider(
      providers: [
        Provider<ViewportController>.value(value: vp),
        Provider<InteractionController>.value(value: interaction),
      ],
      child: CanvasKeyboardHandler(
        viewportController: vp,
        mousePositionNotifier: _mousePositionNotifier,
        child: CanvasStageScope(
          lifecycleCoordinator: _lifecycleCoordinator,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GlassStage(
                mode: GlassMode.performance,
                settings: GlassSettings(
                  refractStrength: AppConfig.liquidGlass.refractStrength,
                  bridgeReachFactor: AppConfig.liquidGlass.bridgeReachFactor,
                  bridgeThicknessFactor:
                      AppConfig.liquidGlass.bridgeThicknessFactor,
                  useLocalCoordinates:
                      AppConfig.liquidGlass.useLocalCoordinates,
                ),
                backdropRepaint: backdropRepaintListenable,
                background: CanvasTemplateDropTarget(
                  onTemplateDropped: (templateKey, localOffset) async {
                    final canvasOffset = vp.screenToCanvas(localOffset);
                    await commandProcessor.templateMutations
                        .instantiateTemplate(templateKey, canvasOffset);
                  },
                  child: Stack(
                    children: [
                      CanvasGestureRouter(
                        interactionController: interaction,
                        mousePositionNotifier: _mousePositionNotifier,
                        onContextMenuRequested:
                            _contextMenuCoordinator.handleContextMenuRequest,
                        onMousePositionChanged: vp.updateMouseScreenPos,
                        onHoverExit: () {
                          vp.updateMouseScreenPos(null);
                          interaction.environment.setHoveredNodeMetadata(null);
                        },
                        child: CanvasCameraHost(
                          viewportController: vp,
                          interactionController: interaction,
                          renderState: renderState,
                          elasticOverscrollNotifier: _elasticOverscrollNotifier,
                          staticChild: CanvasWorldStack(
                            viewportStateNotifier: vp.viewportStateNotifier,
                            mousePositionNotifier: _mousePositionNotifier,
                            elasticOverscrollNotifier:
                                _elasticOverscrollNotifier,
                            drawingInterceptor:
                                _lifecycleCoordinator.drawingInterceptor,
                            session: session,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: session.isInitialized,
                        builder: (context, initialized, _) {
                          if (initialized) return const SizedBox.shrink();
                          return const Positioned.fill(
                            child: IgnorePointer(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                child: CanvasOverlayLayout(
                  constraints: constraints,
                  renderState: renderState,
                  queryController: queryController,
                  interactionController: interaction,
                  viewportController: vp,
                  session: session,
                  drawingInterceptor: _lifecycleCoordinator.drawingInterceptor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
