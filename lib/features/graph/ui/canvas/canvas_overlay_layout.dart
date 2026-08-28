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
import '../widgets/overlays/canvas_status_bar/status_bar_metrics.dart';
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
                  const SizedBox(width: UiSpacing.standard),
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
                    iconSize: UiIconSize.standard,
                    iconColor: primaryColor,
                    enableHover: false,
                  ),
                  const SizedBox(width: UiSpacing.standard),
                  // Middle Search Bar
                  const Expanded(
                    child: Center(
                      child: SearchCommandPalette(),
                    ),
                  ),
                  const SizedBox(width: UiSpacing.standard),
                  // Right Circular Action Button
                  GlassPanel(
                    borderRadius: 20,
                    width: 40,
                    height: UiControlSize.tile,
                    padding: EdgeInsets.zero,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert_rounded, color: primaryColor, size: UiIconSize.standard),
                      tooltip: 'Options Menu',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.panel),
                      ),
                      onSelected: (action) {
                        if (action == 'force_sync') {
                          session.commandProcessor.flushSync();
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
                              Icon(Icons.save_outlined, size: UiIconSize.dense),
                              const SizedBox(width: UiSpacing.standard),
                              Text('Force Sync Save', style: TextStyle(fontSize: UiFont.standard)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'toggle_theme',
                          child: Row(
                            children: [
                              Icon(Icons.palette_outlined, size: UiIconSize.dense),
                              const SizedBox(width: UiSpacing.standard),
                              Text('Toggle Theme', style: TextStyle(fontSize: UiFont.standard)),
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
          ValueListenableBuilder<bool>(
            valueListenable: session.showLeftPanel,
            builder: (context, leftVisible, _) {
              return AnimatedPositioned(
                duration: UiMotion.standard,
                curve: Curves.easeOutCubic,
                top: 112.0,
                left: leftVisible ? 12.0 : -64.0,
                width: 52,
                child: AnimatedOpacity(
                  duration: UiMotion.standard,
                  curve: leftVisible
                      ? const Interval(0.0, 0.4, curve: Curves.easeOut)
                      : const Interval(0.7, 1.0, curve: Curves.easeIn),
                  opacity: leftVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !leftVisible,
                    child: ValueListenableBuilder<LeftPanelType>(
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
                    ),
                  ),
                ),
              );
            },
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
                  return _AnimatedLeftPanel(
                    isLeftVisible: leftVisible,
                    activePanel: activeLeftPanel,
                    constraints: constraints,
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
        ValueListenableBuilder<bool>(
          valueListenable: session.showBottomPanel,
          builder: (context, showBottom, _) {
            final bottomOffset = CanvasStatusBarMetrics.rightPanelBottomOffset(
              screenHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
              bottomPadding: bottomPadding,
              isBottomPanelVisible: showBottom,
            );
            final topOffset = isAndroid ? (statusBarHeight + 104.0) : 112.0;

            return Positioned(
              top: topOffset,
              bottom: bottomOffset,
              right: 12,
              child: ValueListenableBuilder<bool>(
                valueListenable: session.showRightPanel,
                builder: (context, visible, _) {
                  if (!visible) return const SizedBox.shrink();
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
            );
          },
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
                  const SizedBox(width: UiSpacing.standard),
                  const CanvasToolRibbon(),
                  const SizedBox(width: UiSpacing.standard),
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

        ListenableBuilder(
          listenable: renderState.selectionState,
          builder: (context, _) {
            if (renderState.selectedEntities.isEmpty) {
              return const SizedBox.shrink();
            }
            return ContextToolbarOverlay(
              renderState: renderState,
              queryController: queryController,
              interactionContext: interactionController.environment,
              viewportController: viewportController,
              interactionController: interactionController,
            );
          },
        ),
      ],
    );
  }
}

class _AnimatedLeftPanel extends StatefulWidget {
  final bool isLeftVisible;
  final LeftPanelType activePanel;
  final BoxConstraints constraints;

  const _AnimatedLeftPanel({
    required this.isLeftVisible,
    required this.activePanel,
    required this.constraints,
  });

  @override
  State<_AnimatedLeftPanel> createState() => _AnimatedLeftPanelState();
}

class _AnimatedLeftPanelState extends State<_AnimatedLeftPanel> {
  LeftPanelType _displayedPanel = LeftPanelType.none;
  double _measuredHeight = 240.0;
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.activePanel != LeftPanelType.none) {
      _displayedPanel = widget.activePanel;
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedLeftPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePanel != LeftPanelType.none) {
      _displayedPanel = widget.activePanel;
    }
  }

  void _checkHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _contentKey.currentContext;
      if (ctx != null) {
        final renderBox = ctx.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final h = renderBox.size.height;
          if (h > 0 && (_measuredHeight - h).abs() > 4) {
            setState(() {
              _measuredHeight = h;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.isLeftVisible && widget.activePanel != LeftPanelType.none;
    final double targetWidth = 280.0;
    final double maxPanelHeight = (widget.constraints.maxHeight - 112 - 86)
        .clamp(140, 10000)
        .toDouble();
    final double targetHeight = _measuredHeight.clamp(140.0, maxPanelHeight);

    if (isOpen) {
      _checkHeight();
    }

    return AnimatedPositioned(
      duration: UiMotion.standard,
      curve: Curves.easeOutCubic,
      top: 112.0,
      left: 76.0,
      width: isOpen ? targetWidth : 0.0,
      height: isOpen ? targetHeight : 0.0,
      child: AnimatedOpacity(
        duration: UiMotion.standard,
        curve: isOpen
            ? const Interval(0.0, 0.4, curve: Curves.easeOut)
            : const Interval(0.7, 1.0, curve: Curves.easeIn),
        opacity: isOpen ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !isOpen,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UiRadius.panel),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: targetWidth,
              maxWidth: targetWidth,
              minHeight: 0.0,
              maxHeight: maxPanelHeight,
              child: ConstrainedBox(
                key: _contentKey,
                constraints: BoxConstraints(
                  minWidth: targetWidth,
                  maxWidth: targetWidth,
                  minHeight: 0.0,
                  maxHeight: maxPanelHeight,
                ),
                child: _buildContent(_displayedPanel),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(LeftPanelType panel) {
    switch (panel) {
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
