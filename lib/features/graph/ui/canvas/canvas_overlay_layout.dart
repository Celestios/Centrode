import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../store/graph_data_query_controller.dart';
import '../../presentation/node_render_state.dart';
import '../../presentation/viewport_state.dart';
import '../../engine/interaction_engine.dart';
import '../../engine/drawing_interceptor.dart';
import '../../presentation/workspace_tabs_controller.dart';
import '../../models/models.dart';
import '../widgets/overlays/canvas_tool_ribbon.dart';
import '../widgets/overlays/canvas_tab_bar.dart';
import '../widgets/overlays/left_repository_drawer.dart';
import '../widgets/overlays/right_property_panel.dart';
import '../widgets/overlays/canvas_status_bar/canvas_status_bar.dart';
import '../widgets/overlays/canvas_status_bar/graph_manual_widget.dart';
import 'context_toolbar_overlay.dart';
import 'package:centrode/features/graph/ui/widgets/tag_manager/global_tags_manager_panel.dart';
import 'package:centrode/features/graph/ui/widgets/template_manager/global_templates_manager_panel.dart';
import 'package:centrode/features/graph/ui/widgets/drawing_manager/global_drawing_panel.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/presentation/widgets/search/search_command_palette.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/presentation/theme/app_theme.dart';
import 'package:centrode/presentation/widgets/window_title_bar.dart';

class CanvasOverlayLayout extends StatelessWidget {
  final BoxConstraints constraints;
  final NodeRenderState renderState;
  final GraphDataQueryController queryController;
  final InteractionController interactionController;
  final ViewportController viewportController;
  final TabSession session;
  final DrawingGestureInterceptor? drawingInterceptor;

  const CanvasOverlayLayout({
    super.key,
    required this.constraints,
    required this.renderState,
    required this.queryController,
    required this.interactionController,
    required this.viewportController,
    required this.session,
    this.drawingInterceptor,
  });

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final statusBarHeight = isAndroid ? MediaQuery.of(context).padding.top : 0.0;
    final bottomPadding = isAndroid ? MediaQuery.of(context).padding.bottom : 0.0;

    return Stack(
      children: [
        // Desktop Top Header Bar (Ribbon + TabBar)
        if (!isAndroid)
          Positioned(
            top: 52.0,
            left: 12.0,
            right: 16.0,
            child: RepaintBoundary(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const CanvasToolRibbon(),
                  const SizedBox(width: 8),
                  const Flexible(child: CanvasTabBar()),
                ],
              ),
            ),
          ),

        // Android Canvas Top Header Bar (Home Button, Search Palette, Action Button)
        if (isAndroid) ...[
          Positioned(
            top: statusBarHeight + 8.0,
            left: 12.0,
            right: 12.0,
            child: RepaintBoundary(
              child: Row(
                children: [
                  // Left Circular Home Button
                  CentrodeIconButton(
                    icon: Icons.home_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    iconSize: 20,
                    iconColor: primaryColor,
                    enableHover: false,
                  ),
                  const SizedBox(width: 8),
                  // Middle Search Bar
                  const Expanded(
                    child: Center(
                      child: SearchCommandPalette(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right Circular Action Button
                  GlassPanel(
                    borderRadius: 20,
                    width: 40,
                    height: 40,
                    padding: EdgeInsets.zero,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert_rounded, color: primaryColor, size: 20),
                      tooltip: 'Options Menu',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (action) {
                        if (action == 'force_sync') {
                          session.commandProcessor?.flushSync();
                        } else if (action == 'toggle_theme') {
                          final current = AppThemeManager.instance.themeNotifier.value;
                          final isDark = current.brightness == Brightness.dark;
                          AppThemeManager.instance.themeNotifier.value = AppTheme(
                            brightness: isDark ? Brightness.light : Brightness.dark,
                            scaffoldBackgroundColor: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
                            cardColor: isDark ? Colors.white : const Color(0xFF1E1E1E),
                            textColor: isDark ? const Color(0xFF212121) : Colors.white,
                            bodyTextColor: isDark ? const Color(0xFF212121) : Colors.white,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'force_sync',
                          child: Row(
                            children: [
                              Icon(Icons.save_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Force Sync Save', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'toggle_theme',
                          child: Row(
                            children: [
                              Icon(Icons.palette_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Toggle Theme', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Android Maps Tabs Row directly below Top Elements
          Positioned(
            top: statusBarHeight + 62.0,
            left: 12.0,
            right: 12.0,
            child: const RepaintBoundary(
              child: CanvasTabBar(),
            ),
          ),
        ],

        // Left Side Panel (Desktop only for Phase 1)
        if (!isAndroid) ...[
          Positioned(
            top: 112.0,
            left: 12,
            width: 52,
            child: ValueListenableBuilder<bool>(
              valueListenable: session.showLeftPanel,
              builder: (context, leftVisible, _) {
                if (!leftVisible) return const SizedBox.shrink();
                return ValueListenableBuilder<LeftPanelType>(
                  valueListenable: renderState.activeLeftPanelNotifier,
                  builder: (context, activeLeftPanel, _) {
                    return LeftRepositoryDrawer(
                      activePanel: activeLeftPanel,
                      onPanelChanged: (panel) {
                        renderState.activeLeftPanelNotifier.value = panel;
                        if (panel == LeftPanelType.draw) {
                          session.setToolMode('draw');
                        } else {
                          session.setToolMode('select');
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),

          ValueListenableBuilder<bool>(
            valueListenable: session.showLeftPanel,
            builder: (context, leftVisible, _) {
              return ValueListenableBuilder<LeftPanelType>(
                valueListenable: renderState.activeLeftPanelNotifier,
                builder: (context, activeLeftPanel, _) {
                  final isOpen = leftVisible && activeLeftPanel != LeftPanelType.none;
                  if (!isOpen) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (event) {
                        final dx = event.localPosition.dx;
                        final dy = event.localPosition.dy;
                        if (dx > 360.0 || dy < 100.0) {
                          renderState.activeLeftPanelNotifier.value = LeftPanelType.none;
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),

          ValueListenableBuilder<bool>(
            valueListenable: session.showLeftPanel,
            builder: (context, leftVisible, _) {
              return ValueListenableBuilder<LeftPanelType>(
                valueListenable: renderState.activeLeftPanelNotifier,
                builder: (context, activeLeftPanel, _) {
                  final isOpen = activeLeftPanel != LeftPanelType.none;
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    top: 112.0,
                    left: leftVisible ? 76.0 : -300.0,
                    width: (leftVisible && isOpen) ? 280.0 : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: (leftVisible && isOpen) ? 1.0 : 0.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: UnconstrainedBox(
                          alignment: Alignment.topLeft,
                          clipBehavior: Clip.hardEdge,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: 280.0,
                              maxWidth: 280.0,
                              minHeight: 180,
                              maxHeight: (constraints.maxHeight - 112 - 86)
                                  .clamp(180, 10000)
                                  .toDouble(),
                            ),
                            child: _buildLeftPanelContent(activeLeftPanel),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],

        // Vertical Undo/Redo Buttons attached to left side edge on Android
        if (isAndroid)
          Positioned(
            left: 8.0,
            bottom: bottomPadding + 68.0,
            child: UndoRedoButtons(
              session: session,
              isVertical: true,
            ),
          ),

        // Right Property Panel (Handle right edge aligned with minimap)
        Positioned(
          top: isAndroid ? (statusBarHeight + 104.0) : 112.0,
          bottom: isAndroid ? (bottomPadding + 68.0) : 224.0,
          right: 12,
          child: ValueListenableBuilder<bool>(
            valueListenable: session.showRightPanel,
            builder: (context, visible, _) {
              if (!visible) return const SizedBox.shrink();
              final topOffset = isAndroid ? (statusBarHeight + 104.0) : 112.0;
              final bottomOffset = isAndroid ? (bottomPadding + 68.0) : 224.0;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 180,
                  maxWidth: 360,
                  maxHeight: (constraints.maxHeight - topOffset - bottomOffset)
                      .clamp(180, 10000)
                      .toDouble(),
                ),
                child: const RightPropertyPanel(),
              );
            },
          ),
        ),

        // Bottom Tool Ribbon on Android (Framed by Manual Guide on Left and Extra Menu on Right)
        if (isAndroid)
          Positioned(
            bottom: bottomPadding + 10.0,
            left: 12.0,
            right: 12.0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const GraphManualWidget(isSquareIconOnly: true),
                  const SizedBox(width: 8),
                  const CanvasToolRibbon(),
                  const SizedBox(width: 8),
                  ExtraRibbonMenuWidget(session: session),
                ],
              ),
            ),
          ),

        // Bottom Status Bar / Zoom Bar (Desktop)
        if (!isAndroid)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: ValueListenableBuilder<bool>(
              valueListenable: session.showBottomPanel,
              builder: (context, visible, _) {
                if (!visible) return const SizedBox.shrink();
                return const CanvasStatusBar();
              },
            ),
          ),

        if (renderState.selectedEntities.isNotEmpty)
          ContextToolbarOverlay(
            renderState: renderState,
            queryController: queryController,
            interactionContext: interactionController.environment,
            viewportController: viewportController,
            interactionController: interactionController,
          ),
      ],
    );
  }

  Widget _buildLeftPanelContent(LeftPanelType activePanel) {
    switch (activePanel) {
      case LeftPanelType.tags:
        return const GlobalTagsManagerPanel();
      case LeftPanelType.templates:
        return const GlobalTemplatesManagerPanel();
      case LeftPanelType.draw:
        return const GlobalDrawingPanel();
      case LeftPanelType.none:
        return const SizedBox.shrink();
    }
  }
}
