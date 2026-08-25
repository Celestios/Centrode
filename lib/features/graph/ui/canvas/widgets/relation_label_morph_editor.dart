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
  static const double _expandedWidth = 160.0;
  static const double _expandedHeight = 180.0;

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

  List<String> _neuralSimilarVerbs = [];

  /// Pure pipeline: Gathers system ontology + active map relations,
  /// passes through verbal + semantic relevance scoring, and ranks candidates.
  List<String> get _rankedCandidateVerbs {
    // 1. Gather all other relations from the map (excluding the currently edited relation to prevent stale duplicates)
    final otherMapVerbs = widget.queryController.relations
        .where((r) => r.id != widget.relation.id)
        .map((r) => r.verb.trim())
        .where((v) => v.isNotEmpty && v != 'default')
        .toSet();

    // 2. Combine with system ontology verbs and neural search matches
    final pool = <String>{
      ..._neuralSimilarVerbs,
      ..._builtinOntologyVerbs,
      ...otherMapVerbs,
    }.toList();

    final query = _textController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return pool;
    }

    // 3. Relevance ranking pipeline
    final scored = <MapEntry<String, double>>[];
    for (final candidate in pool) {
      final cLower = candidate.toLowerCase();
      double score = 0.0;

      // Neural Candle ranking boost
      final neuralIdx = _neuralSimilarVerbs.indexOf(candidate);
      if (neuralIdx >= 0) {
        score += 15.0 - (neuralIdx * 1.5);
      }

      if (cLower == query) {
        score += 10.0;
      } else if (cLower.startsWith(query)) {
        score += 5.0 + (query.length / cLower.length);
      } else if (cLower.contains(query)) {
        score += 3.0;
      }

      // Subword character 3-gram semantic vector similarity
      final semanticScore = _calculateNgramSimilarity(query, cLower);
      score += semanticScore * 2.0;

      if (score > 0.0) {
        scored.add(MapEntry(candidate, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  void _onQueryChanged() {
    if (_isClosing) return;
    setState(() {
      _selectedIndex = -1;
    });

    final query = _textController.text.trim();
    if (query.isEmpty) {
      if (_neuralSimilarVerbs.isNotEmpty) {
        setState(() {
          _neuralSimilarVerbs = [];
        });
      }
      return;
    }

    // Query native Rust Candle embedder asynchronously
    try {
      final tabsController = context.read<WorkspaceTabsController>();
      final api = tabsController.activeSession.api;
      api?.searchSimilarLabels(query: query, limit: BigInt.from(8)).then((results) {
        if (mounted && _textController.text.trim() == query) {
          setState(() {
            _neuralSimilarVerbs = results;
          });
        }
      });
    } catch (_) {}
  }

  /// Calculates cosine similarity over character 3-gram subword frequency vectors.
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
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleCommit([String? explicitWord]) {
    if (_isClosing) return;

    final candidates = _rankedCandidateVerbs;
    final text = (explicitWord ?? (_selectedIndex >= 0 && _selectedIndex < candidates.length
            ? candidates[_selectedIndex]
            : _textController.text))
        .trim();

    final resolvedWord = text.isEmpty ? 'default' : text;
    _textController.text = resolvedWord;
    widget.onCommit(resolvedWord);

    // Resolve relation style from Rust ontology backend
    _resolveAndApplyOntologyStyle(widget.relation.id, resolvedWord);

    // Morph smoothly back into the centered relation label boundary box
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
    // 1. Check if another relation in the map already has a customized style for this verb
    for (final rel in widget.queryController.relations) {
      if (rel.id != relationId && rel.verb == verb && rel.style != null) {
        widget.interactionContext.onRelationUpdateStyle(relationId, rel.style!);
        return;
      }
    }

    // 2. Query the Rust backend ontology service
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

    final candidates = _rankedCandidateVerbs;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (candidates.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, candidates.length - 1);
        });
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (candidates.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(-1, candidates.length - 1);
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
    final candidates = _rankedCandidateVerbs;

    final currentWidth = _isExpanded ? _expandedWidth : _collapsedWidth;
    final currentHeight = _isExpanded ? _expandedHeight : _collapsedHeight;

    // Outward expansion from the middle horizontal center of the label, and downward from the top edge
    final left = widget.labelCenter.dx - (currentWidth / 2);
    final top = widget.labelCenter.dy - (_collapsedHeight / 2);

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
              color: const Color(0xFF1E1E24).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.canvasAccentColor.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
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
                    // Top text input area (centered on relation label)
                    SizedBox(
                      height: 25.0,
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
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          itemCount: candidates.length,
                          itemBuilder: (context, index) {
                            final verb = candidates[index];
                            final isSelected = index == _selectedIndex;

                            return _WordItemRow(
                              word: verb,
                              isSelected: isSelected,
                              onTap: () => _handleCommit(verb),
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
    );
  }
}

class _WordItemRow extends StatefulWidget {
  final String word;
  final bool isSelected;
  final VoidCallback onTap;

  const _WordItemRow({
    required this.word,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: Text(
            widget.word,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.75),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
