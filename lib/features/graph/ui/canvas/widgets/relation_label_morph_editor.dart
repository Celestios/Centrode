import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';

class RelationLabelMorphEditor extends StatefulWidget {
  final UiRelation relation;
  final Offset labelCenter;
  final GraphDataQuery queryController;
  final NodeRenderState uiController;
  final InteractionContext interactionContext;
  final ValueChanged<String> onCommit;

  const RelationLabelMorphEditor({
    super.key,
    required this.relation,
    required this.labelCenter,
    required this.queryController,
    required this.uiController,
    required this.interactionContext,
    required this.onCommit,
  });

  @override
  State<RelationLabelMorphEditor> createState() => _RelationLabelMorphEditorState();
}

class _RelationLabelMorphEditorState extends State<RelationLabelMorphEditor> {
  static const double _collapsedWidth = 100.0;
  static const double _collapsedHeight = 28.0;
  static const double _expandedWidth = 200.0;
  static const double _expandedHeight = 230.0;

  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.easeOutCubic;

  static const List<String> _builtinOntologyVerbs = [
    'contradicts',
    'depends_on',
    'supports',
    'causes',
    'part_of',
    'leads_to',
    'blocks',
  ];

  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _isExpanded = false;
  bool _isClosing = false;
  Timer? _closeTimer;
  int _selectedIndex = -1;

  String _mapLanguage = 'en';
  List<String> _contextualVerbs = [];
  List<String> _neuralAutocompleteVerbs = [];

  @override
  void initState() {
    super.initState();
    final initialVerb = widget.relation.verb == 'default' ? '' : widget.relation.verb;
    _textController = TextEditingController(text: initialVerb);
    _focusNode = FocusNode();

    _textController.addListener(_onQueryChanged);

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

      _initializeLanguageAndContext();
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initializeLanguageAndContext() {
    try {
      final tabsController = context.read<WorkspaceTabsController>();
      final api = tabsController.activeSession.api;
      if (api == null) return;

      // 1. Detect language from nodes in current map
      final nodeTexts = widget.queryController.nodeLookup.values
          .map((n) => n.content.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      api.detectMapLanguage(nodeTexts: nodeTexts).then((lang) {
        if (!mounted) return;
        setState(() {
          _mapLanguage = lang;
        });

        // 2. Fetch contextual suggestions for this specific connection (Source -> Target)
        final sourceNode = widget.queryController.nodeLookup[widget.relation.fromNodeId];
        final targetNode = widget.queryController.nodeLookup[widget.relation.toNodeId];
        final srcText = sourceNode?.content.text.trim() ?? '';
        final tgtText = targetNode?.content.text.trim() ?? '';

        if (srcText.isNotEmpty || tgtText.isNotEmpty) {
          api.predictRelationLabels(
            sourceText: srcText,
            targetText: tgtText,
            language: _mapLanguage,
            limit: BigInt.from(4),
          ).then((preds) {
            if (mounted && preds.isNotEmpty) {
              setState(() {
                _contextualVerbs = preds;
              });
            }
          });
        }
      });
    } catch (_) {}
  }

  void _onQueryChanged() {
    if (_isClosing) return;
    setState(() {
      _selectedIndex = -1;
    });

    final query = _textController.text.trim();
    if (query.isEmpty) {
      if (_neuralAutocompleteVerbs.isNotEmpty) {
        setState(() {
          _neuralAutocompleteVerbs = [];
        });
      }
      return;
    }

    // Query native Rust Candle embedder for live query autocomplete & synonyms
    try {
      final tabsController = context.read<WorkspaceTabsController>();
      final api = tabsController.activeSession.api;
      api?.searchSimilarLabels(query: query, limit: BigInt.from(5)).then((results) {
        if (mounted && _textController.text.trim() == query) {
          setState(() {
            _neuralAutocompleteVerbs = results;
          });
        }
      });
    } catch (_) {}
  }

  // --- Group 1: Contextual Candidates for Connected Nodes ---
  List<String> get _group1Contextual {
    final query = _textController.text.trim().toLowerCase();
    if (query.isEmpty) return _contextualVerbs;
    return _contextualVerbs.where((v) => v.toLowerCase().contains(query)).toList();
  }

  // --- Group 2: Live Autocomplete & Synonyms ---
  List<String> get _group2Autocomplete {
    final query = _textController.text.trim().toLowerCase();
    final g1Set = _group1Contextual.toSet();

    final pool = <String>{
      ..._neuralAutocompleteVerbs,
      ..._builtinOntologyVerbs,
    }.where((v) => !g1Set.contains(v)).toList();

    if (query.isEmpty) {
      return pool.take(4).toList();
    }

    final scored = <MapEntry<String, double>>[];
    for (final candidate in pool) {
      final cLower = candidate.toLowerCase();
      double score = 0.0;

      final neuralIdx = _neuralAutocompleteVerbs.indexOf(candidate);
      if (neuralIdx >= 0) {
        score += 10.0 - (neuralIdx * 1.2);
      }

      if (cLower == query) {
        score += 10.0;
      } else if (cLower.startsWith(query)) {
        score += 5.0 + (query.length / cLower.length);
      } else if (cLower.contains(query)) {
        score += 3.0;
      }

      final semanticScore = _calculateNgramSimilarity(query, cLower);
      score += semanticScore * 2.0;

      if (score > 0.0) {
        scored.add(MapEntry(candidate, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(4).toList();
  }

  // --- Group 3: Map Consistency (Verbs already present elsewhere in map) ---
  Map<String, int> get _group3MapVerbs {
    final query = _textController.text.trim().toLowerCase();
    final g1Set = _group1Contextual.toSet();
    final g2Set = _group2Autocomplete.toSet();

    final counts = <String, int>{};
    for (final rel in widget.queryController.relations) {
      if (rel.id == widget.relation.id) continue;
      final v = rel.verb.trim();
      if (v.isNotEmpty && v != 'default' && !g1Set.contains(v) && !g2Set.contains(v)) {
        if (query.isEmpty || v.toLowerCase().contains(query)) {
          counts[v] = (counts[v] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  /// Flat list of all currently displayed selectable words in order
  List<String> get _allSelectableVerbs {
    final list = <String>[];
    list.addAll(_group1Contextual);
    list.addAll(_group2Autocomplete);
    list.addAll(_group3MapVerbs.keys);
    return list;
  }

  double _calculateNgramSimilarity(String s1, String s2) {
    if (s1.length < 2 || s2.length < 2) return 0.0;

    Map<String, int> getNgrams(String text) {
      final map = <String, int>{};
      for (int i = 0; i <= text.length - 2; i++) {
        final gram = text.substring(i, math.min(i + 3, text.length));
        map[gram] = (map[gram] ?? 0) + 1;
      }
      return map;
    }

    final g1 = getNgrams(s1);
    final g2 = getNgrams(s2);

    double dot = 0.0;
    double mag1 = 0.0;
    double mag2 = 0.0;

    for (final val in g1.values) {
      mag1 += val * val;
    }
    for (final val in g2.values) {
      mag2 += val * val;
    }

    if (mag1 == 0.0 || mag2 == 0.0) return 0.0;

    for (final entry in g1.entries) {
      if (g2.containsKey(entry.key)) {
        dot += entry.value * g2[entry.key]!;
      }
    }

    return dot / (math.sqrt(mag1) * math.sqrt(mag2));
  }

  void _handleCommit([String? explicitWord]) {
    if (_isClosing) return;

    final flatList = _allSelectableVerbs;
    final text = explicitWord ??
        (_selectedIndex >= 0 && _selectedIndex < flatList.length
            ? flatList[_selectedIndex]
            : _textController.text.trim());

    if (text.isNotEmpty && text != widget.relation.verb) {
      widget.onCommit(text);
      _resolveAndApplyOntologyStyle(widget.relation.id, text);
    }

    setState(() {
      _isExpanded = false;
      _isClosing = true;
    });

    _closeTimer?.cancel();
    _closeTimer = Timer(_duration, () {
      if (!mounted) return;
      widget.uiController.cancelActiveEdit();
    });
  }

  Future<void> _resolveAndApplyOntologyStyle(RawUuid relationId, String verb) async {
    for (final rel in widget.queryController.relations) {
      if (rel.id != relationId && rel.verb == verb && rel.style != null) {
        widget.interactionContext.onRelationUpdateStyle(relationId, rel.style!);
        return;
      }
    }

    try {
      final tabsController = context.read<WorkspaceTabsController>();
      final api = tabsController.activeSession.api;
      final spec = await api?.getRelationSpec(verb: verb);
      if (spec != null && mounted) {
        widget.interactionContext.onRelationUpdateStyle(relationId, spec);
      }
    } catch (_) {}
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _isClosing) return;

    final flatList = _allSelectableVerbs;
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
    final flatList = _allSelectableVerbs;

    final currentWidth = _isExpanded ? _expandedWidth : _collapsedWidth;
    final currentHeight = _isExpanded ? _expandedHeight : _collapsedHeight;

    final left = widget.labelCenter.dx - (currentWidth / 2);
    final top = widget.labelCenter.dy - (_collapsedHeight / 2);

    final g1 = _group1Contextual;
    final g2 = _group2Autocomplete;
    final g3 = _group3MapVerbs;

    return AnimatedPositioned(
      duration: _duration,
      curve: _curve,
      left: left,
      top: top,
      width: currentWidth,
      height: currentHeight,
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
                final showList = constraints.maxHeight > 45.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Centered Text Input Box
                    SizedBox(
                      height: 26.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    ),
                    if (showList) ...[
                      const Divider(height: 1, thickness: 0.5, color: Colors.white24),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          children: [
                            // 1. Group 1: Contextual Suggestions
                            if (g1.isNotEmpty) ...[
                              _GroupHeader(
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

                            // 2. Group 2: Live Autocomplete & Synonyms
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

                            // 3. Group 3: Map Consistency
                            if (g3.isNotEmpty) ...[
                              _GroupHeader(
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
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: color.withValues(alpha: 0.8),
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
              Text(
                widget.word,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? Colors.white : Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.2,
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
