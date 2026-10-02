import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:centrode/shared/elements/elements.dart';

class ProjectCard extends StatefulWidget {
  final String name;
  final String lastOpened;
  final String? previewPath;
  final Color? previewColor;
  final int? seed;
  final ContourConfig? contourConfig;
  final VoidCallback? onTap;
  final VoidCallback? onMenuPressed;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool isSelectionMode;
  final ValueChanged<bool>? onSelectionChanged;

  const ProjectCard({
    super.key,
    required this.name,
    required this.lastOpened,
    this.previewPath,
    this.previewColor,
    this.seed,
    this.contourConfig,
    this.onTap,
    this.onMenuPressed,
    this.onRename,
    this.onDelete,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionChanged,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isHovered = false;
  bool _isEditing = false;
  late TextEditingController _controller;
  late Color _primaryAestheticColor;
  late Color _secondaryAestheticColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
    _initColors();
  }

  void _initColors() {
    final seed = widget.seed ?? widget.name.hashCode;
    final rng = math.Random(seed);
    _primaryAestheticColor = widget.previewColor ??
        ColorTheoryEngine.generateHarmonicRandomColor(random: rng);
    _secondaryAestheticColor = ColorTheoryEngine.shiftHue(
      _primaryAestheticColor,
      35.0 + rng.nextDouble() * 30.0,
    );
  }

  @override
  void didUpdateWidget(covariant ProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name != oldWidget.name && !_isEditing) {
      _controller.text = widget.name;
      _initColors();
    } else if (widget.previewColor != oldWidget.previewColor ||
        widget.seed != oldWidget.seed) {
      _initColors();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = CentrodeDerivedPalette.of(context);
    final primaryColor = theme.colorScheme.primary;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GlassPanel(
          borderRadius: UiRadius.panel,
          enableBackdrop: false,
          color: widget.isSelected
              ? Color.alphaBlend(primaryColor.withValues(alpha: 0.22), palette.surface.cardBackground)
              : _isHovered
                  ? Color.alphaBlend(primaryColor.withValues(alpha: 0.10), palette.surface.cardBackground)
                  : palette.surface.cardBackground,
          border: Border.all(
            color: widget.isSelected
                ? primaryColor
                : (_isHovered
                    ? primaryColor.withValues(alpha: 0.5)
                    : palette.surface.controlBorder),
            width: UiStrokeWidth.subtle,
          ),
          shadow: _isHovered || widget.isSelected
              ? BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CentrodeButton(
                      onTap: () {
                        if (widget.isSelectionMode) {
                          widget.onSelectionChanged?.call(!widget.isSelected);
                        } else {
                          widget.onTap?.call();
                        }
                      },
                      enableHover: false,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(UiRadius.panel),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(UiRadius.panel),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.alphaBlend(
                                _primaryAestheticColor.withValues(
                                  alpha: theme.brightness == Brightness.dark ? 0.24 : 0.16,
                                ),
                                palette.surface.subtleBackground,
                              ),
                              Color.alphaBlend(
                                _secondaryAestheticColor.withValues(
                                  alpha: theme.brightness == Brightness.dark ? 0.12 : 0.08,
                                ),
                                palette.surface.subtleBackground,
                              ),
                            ],
                          ),
                        ),
                        child: widget.previewPath != null
                            ? Image.asset(
                                widget.previewPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(theme, palette),
                              )
                            : _buildPlaceholder(theme, palette),
                      ),
                    ),
                  ),
                  if (_isHovered || widget.isSelected || widget.isSelectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? primaryColor
                              : palette.surface.controlBackground,
                          borderRadius: BorderRadius.circular(UiRadius.control),
                          border: Border.all(
                            color: palette.surface.controlBorder,
                            width: UiStrokeWidth.subtle,
                          ),
                        ),
                        child: CentrodeIconButton(
                          onPressed: () {
                            widget.onSelectionChanged?.call(!widget.isSelected);
                          },
                          enableHover: false,
                          borderRadius: BorderRadius.circular(UiRadius.control),
                          iconSize: 15,
                          buttonSize: 22,
                          icon: Icons.check,
                          iconColor: widget.isSelected ? Colors.white : Colors.transparent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: Padding(
                padding: UiInsets.horizontalStandard,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isEditing)
                            SizedBox(
                              height: UiControlSize.dense,
                              child: TextField(
                                controller: _controller,
                                autofocus: true,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (value) {
                                  final trimmed = value.trim();
                                  if (trimmed.isNotEmpty && trimmed != widget.name) {
                                    widget.onRename?.call(trimmed);
                                  }
                                  setState(() => _isEditing = false);
                                },
                                onTapOutside: (_) {
                                  if (_isEditing) {
                                    setState(() => _isEditing = false);
                                  }
                                },
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isEditing = true;
                                  _controller.text = widget.name;
                                });
                              },
                              child: Text(
                                widget.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Text(
                            widget.lastOpened,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: UiFont.micro,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (btnContext) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          final renderBox =
                              btnContext.findRenderObject() as RenderBox;
                          final targetRect =
                              renderBox.localToGlobal(Offset.zero) &
                                  renderBox.size;
                          CentrodeContextMenu.showAt(
                            context: btnContext,
                            targetRect: targetRect,
                            items: [
                              CentrodeMenuItem.action(
                                label: 'Open',
                                leadingIcon: Icons.open_in_new_rounded,
                                onTap: () => widget.onTap?.call(),
                              ),
                              CentrodeMenuItem.action(
                                label: 'Share',
                                leadingIcon: Icons.share_outlined,
                                onTap: () {},
                              ),
                              CentrodeMenuItem.action(
                                label: 'View metadata',
                                leadingIcon: Icons.info_outline_rounded,
                                onTap: () {},
                              ),
                              const CentrodeMenuItem.divider(),
                              CentrodeMenuItem.destructive(
                                label: 'Delete',
                                leadingIcon: Icons.delete_outline_rounded,
                                shortcut: 'Del',
                                onTap: () => widget.onDelete?.call(),
                              ),
                            ],
                          );
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _isHovered
                                ? palette.hoverOverlay
                                : palette.surface.subtleBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_horiz,
                            size: UiIconSize.dense,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPlaceholder(ThemeData theme, CentrodeDerivedPalette palette) {
    final isDark = theme.brightness == Brightness.dark;
    final seed = widget.seed ?? widget.name.hashCode;

    final config = widget.contourConfig ??
        ContourConfig(
          style: seed.isEven
              ? ContourStyle.topographic
              : ContourStyle.flowingWaves,
          origin: ContourOrigin.bottomRight,
          layerCount: 5,
          amplitude: 0.28,
          frequency: 1.4,
          strokeWidth: 0.8,
          showLines: true,
          showFills: true,
          fillOpacity: isDark ? 0.22 : 0.16,
          lineOpacity: isDark ? 0.35 : 0.25,
          seed: seed,
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        CentrodeContourPattern(
          config: config,
          primaryColor: _primaryAestheticColor,
          secondaryColor: _secondaryAestheticColor,
        ),
        Center(
          child: AnimatedContainer(
            duration: UiMotion.fast,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryAestheticColor.withValues(
                alpha: _isHovered
                    ? (isDark ? 0.28 : 0.22)
                    : (isDark ? 0.18 : 0.14),
              ),
              border: Border.all(
                color: _primaryAestheticColor.withValues(
                  alpha: _isHovered
                      ? (isDark ? 0.55 : 0.45)
                      : (isDark ? 0.35 : 0.25),
                ),
                width: UiStrokeWidth.subtle,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryAestheticColor.withValues(
                    alpha: _isHovered
                        ? (isDark ? 0.35 : 0.20)
                        : (isDark ? 0.15 : 0.08),
                  ),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.hub_rounded,
                color: _primaryAestheticColor,
                size: UiIconSize.header,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
