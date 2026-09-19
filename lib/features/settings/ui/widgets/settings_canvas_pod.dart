import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import '../../presentation/settings_category.dart';
import '../../presentation/settings_controller.dart';
import 'floating_search_bar.dart';
import 'sections/top_sections.dart';
import 'sections/physics_settings_section.dart';
import 'sections/relations_settings_section.dart';
import 'sections/ontology_settings_section.dart';
import 'sections/storage_settings_section.dart';

class SettingsCanvasPod extends StatefulWidget {
  static const double podCornerRadius = 32.0;

  final SettingsController controller;

  const SettingsCanvasPod({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsCanvasPod> createState() => _SettingsCanvasPodState();
}

class _SettingsCanvasPodState extends State<SettingsCanvasPod> {
  final ScrollController _scrollController = ScrollController();
  final Map<SettingsCategory, GlobalKey> _sectionKeys = {
    for (final cat in SettingsCategory.values) cat: GlobalKey(),
  };

  late final Map<SettingsCategory, Widget Function(BuildContext, SettingsController)> _sectionBuilders;

  bool _isProgrammaticScrolling = false;

  @override
  void initState() {
    super.initState();
    widget.controller.onRequestScrollToCategory = _scrollToCategory;
    _scrollController.addListener(_onScroll);
    _sectionBuilders = {
      SettingsCategory.appearance: (context, controller) => Column(
        children: [
          ThemeSettingsCard(controller: controller),
          ShaderSettingsCard(controller: controller),
        ],
      ),
      SettingsCategory.canvas: (context, controller) => CanvasSettingsCard(controller: controller),
      SettingsCategory.physics: (context, controller) => const PhysicsSettingsSection(),
      SettingsCategory.relations: (context, controller) => const RelationsSettingsSection(),
      SettingsCategory.ontology: (context, controller) => const OntologySettingsSection(),
      SettingsCategory.storage: (context, controller) => const StorageSettingsSection(),
    };
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.controller.onRequestScrollToCategory = null;
    super.dispose();
  }

  static const double _headerClearance = 82.0;

  void _scrollToCategory(SettingsCategory category) {
    if (category == SettingsCategory.appearance) {
      _isProgrammaticScrolling = true;
      _scrollController
          .animateTo(
            0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          )
          .then((_) {
            _isProgrammaticScrolling = false;
          });
      return;
    }

    final key = _sectionKeys[category];
    final context = key?.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      final scrollBox = _scrollController.position.context.notificationContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && scrollBox != null) {
        _isProgrammaticScrolling = true;
        final targetOffset = renderBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
        final currentScroll = _scrollController.offset;
        final destination = (currentScroll + targetOffset - _headerClearance).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

        _scrollController
            .animateTo(
              destination,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            )
            .then((_) {
              _isProgrammaticScrolling = false;
            });
      }
    }
  }

  void _onScroll() {
    if (_isProgrammaticScrolling) return;

    SettingsCategory? mostVisible;
    double minDistance = double.infinity;

    final scrollBox = _scrollController.position.context.notificationContext?.findRenderObject() as RenderBox?;

    for (final entry in _sectionKeys.entries) {
      final context = entry.value.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = scrollBox != null
              ? renderBox.localToGlobal(Offset.zero, ancestor: scrollBox)
              : renderBox.localToGlobal(Offset.zero);
          final distance = (position.dy - _headerClearance).abs();
          if (position.dy <= _headerClearance + 150.0 && distance < minDistance) {
            minDistance = distance;
            mostVisible = entry.key;
          }
        }
      }
    }

    if (mostVisible != null) {
      widget.controller.onSectionVisible(mostVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const podCornerRadius = SettingsCanvasPod.podCornerRadius;
    const podShape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(podCornerRadius),
        topRight: Radius.circular(podCornerRadius),
      ),
    );

    return GlassPanel(
      borderRadius: podCornerRadius,
      border: Border.all(color: Colors.transparent, width: 0.0),
      color: isDark
          ? const Color(0xFF16161D).withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.90),
      child: Stack(
        children: [
          Positioned.fill(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final query = widget.controller.searchQuery;

                if (query.isNotEmpty) {
                  return SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      top: 68.0,
                      left: UiSpacing.container,
                      right: UiSpacing.container,
                      bottom: 500.0, // Extra space allowing any section to reach top
                    ),
                    child: _buildSearchResults(query),
                  );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    top: 68.0,
                    left: UiSpacing.container,
                    right: UiSpacing.container,
                    bottom: 500.0, // Extra space allowing last section to reach top
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final category in SettingsCategory.values) ...[
                        _buildSection(category, [
                          _sectionBuilders[category]!(context, widget.controller),
                        ]),
                        if (category != SettingsCategory.storage)
                          const SizedBox(height: 90.0),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Seamless Telegram-style feathered blur header with smooth continuous multi-stop fade
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            height: 108.0,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [
                    0.0,
                    0.20,
                    0.40,
                    0.58,
                    0.72,
                    0.84,
                    0.93,
                    1.0,
                  ],
                  colors: [
                    Colors.black,
                    Colors.black,
                    Color(0xFA000000), // ~98%
                    Color(0xCC000000), // ~80%
                    Color(0x8C000000), // ~55%
                    Color(0x47000000), // ~28%
                    Color(0x14000000), // ~8%
                    Colors.transparent,
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ClipPath(
                clipper: const ShapeBorderClipper(shape: podShape),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [
                          0.0,
                          0.20,
                          0.40,
                          0.58,
                          0.72,
                          0.84,
                          0.93,
                          1.0,
                        ],
                        colors: [
                          (isDark ? const Color(0xFF16161D) : Colors.white)
                              .withValues(alpha: 0.98),
                          (isDark ? const Color(0xFF16161D) : Colors.white)
                              .withValues(alpha: 0.96),
                          (isDark ? const Color(0xFF16161D) : Colors.white)
                              .withValues(alpha: 0.90),
                          (isDark ? const Color(0xFF16161D) : Colors.white)
                              .withValues(alpha: 0.72),
                          (isDark ? const Color(0xFF16161D) : Colors.white)
                              .withValues(alpha: 0.48),
                          (isDark ? const Color(0xFF16161D) : Colors.white)
                              .withValues(alpha: 0.24),
                          (isDark ? const Color(0xFF16161D) : Colors.white)
                              .withValues(alpha: 0.08),
                          (isDark ? const Color(0xFF16161D) : Colors.white)
                              .withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Pinned top controls: horizontally aligned with left pod header (top: 14.0, height: 38.0)
          Positioned(
            top: 14.0,
            left: UiSpacing.container,
            right: UiSpacing.container,
            height: 38.0,
            child: SettingsTopControlsBar(controller: widget.controller),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(SettingsCategory category, List<Widget> children) {
    return Container(
      key: _sectionKeys[category],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryHeader(category: category),
          const SizedBox(height: UiSpacing.container),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSearchResults(String query) {
    final List<Widget> matches = [];

    if ('theme color dark light forest palette'.contains(query)) {
      matches.add(ThemeSettingsCard(controller: widget.controller));
    }
    if ('shader liquid glass refraction blur glsl'.contains(query)) {
      matches.add(ShaderSettingsCard(controller: widget.controller));
    }
    if ('grid snap canvas spacing port'.contains(query)) {
      matches.add(CanvasSettingsCard(controller: widget.controller));
    }

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: UiSpacing.gutter),
        child: Center(
          child: Text(
            'No settings matching "$query"',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: UiFont.standard,
            ),
          ),
        ),
      );
    }

    return Column(children: matches);
  }
}

class _CategoryHeader extends StatelessWidget {
  final SettingsCategory category;

  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              category.icon,
              size: UiIconSize.header,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: UiSpacing.standard),
            Text(
              category.label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3.0),
        Text(
          category.subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
