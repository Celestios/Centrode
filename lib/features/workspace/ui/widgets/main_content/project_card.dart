import 'package:flutter/material.dart';

import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

class ProjectCard extends StatefulWidget {
  final String name;
  final String lastOpened;
  final String? previewPath;
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(covariant ProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name != oldWidget.name && !_isEditing) {
      _controller.text = widget.name;
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

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GlassPanel(
          borderRadius: UiRadius.panel,
          enableBackdrop: false,
          color: _isHovered || widget.isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.cardColor.withValues(alpha: 0.65),
          shadow: _isHovered || widget.isSelected
              ? BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
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
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(UiRadius.panel),
                          ),
                        ),
                        child: widget.previewPath != null
                            ? Image.asset(
                                widget.previewPath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                              )
                            : _buildPlaceholder(theme),
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
                              ? theme.colorScheme.primary
                              : theme.cardColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(UiRadius.control),
                          border: Border.all(
                            color: widget.isSelected
                                ? theme.colorScheme.primary
                                : theme.dividerColor.withValues(alpha: 0.8),
                            width: UiStrokeWidth.thick,
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
                    PopupMenuButton<String>(
                      popUpAnimationStyle: AnimationStyle.noAnimation,
                      tooltip: '',
                      onSelected: (value) {
                        if (value == 'delete') {
                          widget.onDelete?.call();
                        } else if (value == 'share' || value == 'metadata') {
                          // placeholders
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UiRadius.card),
                      ),
                      color: theme.cardColor,
                      elevation: 4,
                      icon: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.dividerColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.more_horiz,
                          size: UiIconSize.dense,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          height: UiControlSize.standard,
                          child: Text('Delete', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          height: UiControlSize.standard,
                          child: Text('Share', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: 'metadata',
                          height: UiControlSize.standard,
                          child: Text('View metadata', style: TextStyle(fontSize: 13)),
                        ),
                      ],
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

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.account_tree_outlined,
        color: theme.colorScheme.primary.withValues(alpha: 0.3),
        size: 32,
      ),
    );
  }
}
