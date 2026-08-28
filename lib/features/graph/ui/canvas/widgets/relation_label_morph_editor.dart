import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/relation_label_suggestion_controller.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';

class RelationLabelMorphEditor extends StatefulWidget {
  final UiRelation relation;
  final Offset labelCenter;
  final RelationLabelSuggestionController suggestionController;
  final NodeRenderState uiController;
  final InteractionContext interactionContext;
  final ValueChanged<String> onCommit;

  const RelationLabelMorphEditor({
    super.key,
    required this.relation,
    required this.labelCenter,
    required this.suggestionController,
    required this.uiController,
    required this.interactionContext,
    required this.onCommit,
  });

  @override
  State<RelationLabelMorphEditor> createState() => _RelationLabelMorphEditorState();
}

class _RelationLabelMorphEditorState extends State<RelationLabelMorphEditor> {
  static const double _collapsedWidth = 110.0;
  static const double _collapsedHeight = 32.0;
  static const double _expandedWidth = 200.0;
  static const double _expandedHeight = 230.0;

  static const _openDuration = Duration(milliseconds: 260);
  static const _closeDuration = Duration(milliseconds: 360);
  static const _openCurve = Curves.easeOutCubic;
  static const _closeCurve = Curves.easeInOutCubic;

  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _isExpanded = false;
  bool _isClosing = false;
  Timer? _closeTimer;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    final initialVerb = widget.relation.verb == 'default' ? '' : widget.relation.verb;
    _textController = TextEditingController(text: initialVerb);
    _focusNode = FocusNode();

    _textController.addListener(_onQueryChanged);

    widget.uiController.commitActiveEditCallback = _handleCommit;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_isClosing) {
        _handleCommit();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isExpanded = true;
      });
      _focusNode.requestFocus();
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    if (widget.uiController.editorState.commitActiveEditCallback == _handleCommit) {
      widget.uiController.commitActiveEditCallback = null;
    }
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (_isClosing) return;
    setState(() {
      _selectedIndex = -1;
    });
    widget.suggestionController.onQueryChanged(_textController.text);
  }

  void _handleCommit([String? explicitWord]) {
    if (_isClosing) return;

    final flatList = widget.suggestionController.value.flatList;
    final text = explicitWord ??
        (_selectedIndex >= 0 && _selectedIndex < flatList.length
            ? flatList[_selectedIndex]
            : _textController.text.trim());

    if (text.isNotEmpty && text != widget.relation.verb) {
      widget.onCommit(text);
      widget.suggestionController.resolveAndApplyOntologyStyle(
        relationId: widget.relation.id,
        verb: text,
        interactionContext: widget.interactionContext,
      );
    }

    setState(() {
      _isExpanded = false;
      _isClosing = true;
    });

    _closeTimer?.cancel();
    _closeTimer = Timer(_closeDuration, () {
      if (!mounted) return;
      widget.uiController.cancelActiveEdit();
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _isClosing) return;

    final flatList = widget.suggestionController.value.flatList;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (flatList.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, flatList.length - 1);
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (flatList.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(-1, flatList.length - 1);
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _handleCommit();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _handleCommit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeManager.instance.currentTheme;

    final currentWidth = _isExpanded ? _expandedWidth : _collapsedWidth;
    final currentHeight = _isExpanded ? _expandedHeight : _collapsedHeight;

    final left = widget.labelCenter.dx - (currentWidth / 2);
    final top = widget.labelCenter.dy - (_collapsedHeight / 2);

    final duration = _isClosing ? _closeDuration : _openDuration;
    final curve = _isClosing ? _closeCurve : _openCurve;

    return AnimatedPositioned(
      duration: duration,
      curve: curve,
      left: left,
      top: top,
      width: currentWidth,
      height: currentHeight,
      child: TapRegion(
        onTapOutside: (_) {
          if (!_isClosing) {
            _handleCommit();
          }
        },
        child: AnimatedOpacity(
          duration: duration,
          curve: _isClosing ? Curves.easeInQuad : Curves.easeOutCubic,
          opacity: _isClosing ? 0.0 : 1.0,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: _handleKeyEvent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.canvasAccentColor.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showList = _isExpanded && constraints.maxHeight > 50.0 && constraints.maxWidth > 130.0;

                final inputField = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      readOnly: _isClosing,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'type relation...',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                      onSubmitted: (val) => _handleCommit(val),
                    ),
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showList)
                      SizedBox(
                        height: 26.0,
                        child: inputField,
                      )
                    else
                      Expanded(
                        child: inputField,
                      ),
                    if (showList) ...[
                      const Divider(height: 1, thickness: 0.5, color: Colors.white24),
                      Expanded(
                        child: ValueListenableBuilder<RelationSuggestionState>(
                          valueListenable: widget.suggestionController,
                          builder: (context, state, _) {
                            final g1 = state.contextualVerbs;
                            final g2 = state.autocompleteVerbs;
                            final g3 = state.mapVerbs;
                            final flatList = state.flatList;

                            return ListView(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              children: [
                                if (g1.isNotEmpty) ...[
                                  const _GroupHeader(
                                    icon: Icons.bolt,
                                    label: 'SUGGESTED',
                                    color: Colors.amberAccent,
                                  ),
                                  for (final verb in g1)
                                    _WordItemRow(
                                      word: verb,
                                      isSelected: flatList.indexOf(verb) == _selectedIndex,
                                      onTap: () => _handleCommit(verb),
                                    ),
                                ],
                                if (g2.isNotEmpty) ...[
                                  _GroupHeader(
                                    icon: Icons.search,
                                    label: 'SYNONYMS',
                                    color: theme.canvasAccentColor,
                                  ),
                                  for (final verb in g2)
                                    _WordItemRow(
                                      word: verb,
                                      isSelected: flatList.indexOf(verb) == _selectedIndex,
                                      onTap: () => _handleCommit(verb),
                                    ),
                                ],
                                if (g3.isNotEmpty) ...[
                                  const _GroupHeader(
                                    icon: Icons.bookmark_border,
                                    label: 'IN THIS MAP',
                                    color: Colors.tealAccent,
                                  ),
                                  for (final entry in g3.entries)
                                    _WordItemRow(
                                      word: entry.key,
                                      badge: '${entry.value}x',
                                      isSelected: flatList.indexOf(entry.key) == _selectedIndex,
                                      onTap: () => _handleCommit(entry.key),
                                    ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _GroupHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GroupHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 10, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordItemRow extends StatefulWidget {
  final String word;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _WordItemRow({
    required this.word,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_WordItemRow> createState() => _WordItemRowState();
}

class _WordItemRowState extends State<_WordItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.word,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    widget.badge!,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
