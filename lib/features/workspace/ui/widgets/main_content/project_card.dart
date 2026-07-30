import 'package:flutter/material.dart';

class ProjectCard extends StatefulWidget {
  final String name;
  final String lastOpened;
  final String? previewPath;
  final VoidCallback? onTap;
  final VoidCallback? onMenuPressed;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.name,
    required this.lastOpened,
    this.previewPath,
    this.onTap,
    this.onMenuPressed,
    this.onRename,
    this.onDelete,
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? theme.cardColor.withValues(alpha: 0.9)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.dividerColor.withValues(alpha: 0.2),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
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
            SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isEditing)
                            SizedBox(
                              height: 20,
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
                              fontSize: 10,
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
                        borderRadius: BorderRadius.circular(8),
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
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          height: 32,
                          child: Text('Delete', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          height: 32,
                          child: Text('Share', style: TextStyle(fontSize: 13)),
                        ),
                        const PopupMenuItem(
                          value: 'metadata',
                          height: 32,
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
