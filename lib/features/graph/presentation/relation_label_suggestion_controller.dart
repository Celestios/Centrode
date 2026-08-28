import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_api.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';

class RelationSuggestionState {
  final String language;
  final List<String> contextualVerbs;
  final List<String> autocompleteVerbs;
  final Map<String, int> mapVerbs;
  final List<String> flatList;

  const RelationSuggestionState({
    this.language = 'en',
    this.contextualVerbs = const [],
    this.autocompleteVerbs = const [],
    this.mapVerbs = const {},
    this.flatList = const [],
  });

  RelationSuggestionState copyWith({
    String? language,
    List<String>? contextualVerbs,
    List<String>? autocompleteVerbs,
    Map<String, int>? mapVerbs,
    List<String>? flatList,
  }) {
    return RelationSuggestionState(
      language: language ?? this.language,
      contextualVerbs: contextualVerbs ?? this.contextualVerbs,
      autocompleteVerbs: autocompleteVerbs ?? this.autocompleteVerbs,
      mapVerbs: mapVerbs ?? this.mapVerbs,
      flatList: flatList ?? this.flatList,
    );
  }
}

class RelationLabelSuggestionController extends ValueNotifier<RelationSuggestionState> {
  static const Map<String, List<String>> _ontologyVerbsByLanguage = {};

  // Built-in candidate ontology verbs temporarily disabled
  List<String> get _currentLanguageOntologyVerbs =>
      _ontologyVerbsByLanguage[value.language] ?? const [];

  final MlApi? _api;
  final GraphDataQuery _queryController;
  final UiRelation _relation;

  String _currentQuery = '';
  List<String> _neuralAutocompleteVerbs = [];
  List<String> _rawContextualVerbs = [];

  RelationLabelSuggestionController({
    required MlApi? api,
    required GraphDataQuery queryController,
    required UiRelation relation,
  })  : _api = api,
        _queryController = queryController,
        _relation = relation,
        super(const RelationSuggestionState()) {
    _initialize();
  }

  void _initialize() {
    _recomputeState();
    final api = _api;
    if (api == null) return;

    final nodeTexts = _queryController.nodeLookup.values
        .map((n) => n.content.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    api.detectMapLanguage(nodeTexts: nodeTexts).then((lang) {
      value = value.copyWith(language: lang);

      final sourceNode = _queryController.nodeLookup[_relation.fromNodeId];
      final targetNode = _queryController.nodeLookup[_relation.toNodeId];
      final srcText = sourceNode?.content.text.trim() ?? '';
      final tgtText = targetNode?.content.text.trim() ?? '';

      if (srcText.isNotEmpty || tgtText.isNotEmpty) {
        api.predictRelationLabels(
          sourceText: srcText,
          targetText: tgtText,
          language: lang,
          limit: BigInt.from(4),
        ).then((preds) {
          if (preds.isNotEmpty) {
            _rawContextualVerbs = preds;
            _recomputeState();
          }
        });
      }
    });
  }

  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void onQueryChanged(String text) {
    _currentQuery = text.trim();
    _debounceTimer?.cancel();
    if (_currentQuery.isEmpty) {
      _neuralAutocompleteVerbs = [];
      _recomputeState();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      final query = _currentQuery;
      final api = _api;
      if (api != null && query.isNotEmpty) {
        api.searchSimilarLabels(
          query: query,
          category: 'relation',
          language: value.language,
          limit: BigInt.from(5),
        ).then((results) {
          if (_currentQuery == query) {
            _neuralAutocompleteVerbs = results;
            _recomputeState();
          }
        });
      }
    });

    _recomputeState();
  }

  void _recomputeState() {
    final query = _currentQuery.toLowerCase();

    // Group 1: Contextual
    final g1 = query.isEmpty
        ? _rawContextualVerbs
        : _rawContextualVerbs.where((v) => v.toLowerCase().contains(query)).toList();

    // Group 2: Autocomplete & Synonyms (scoped to active map language)
    final g1Set = g1.toSet();
    final pool = <String>{
      ..._neuralAutocompleteVerbs,
      ..._currentLanguageOntologyVerbs,
    }.where((v) => !g1Set.contains(v)).toList();

    final List<String> g2;
    if (query.isEmpty) {
      g2 = pool.take(4).toList();
    } else {
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
      g2 = scored.map((e) => e.key).take(4).toList();
    }

    // Group 3: Map Consistency
    final g2Set = g2.toSet();
    final g3 = <String, int>{};
    for (final rel in _queryController.relations) {
      if (rel.id == _relation.id) continue;
      final v = rel.verb.trim();
      if (v.isNotEmpty && v != 'default' && !g1Set.contains(v) && !g2Set.contains(v)) {
        if (query.isEmpty || v.toLowerCase().contains(query)) {
          g3[v] = (g3[v] ?? 0) + 1;
        }
      }
    }

    final flatList = <String>[
      ...g1,
      ...g2,
      ...g3.keys,
    ];

    value = value.copyWith(
      contextualVerbs: g1,
      autocompleteVerbs: g2,
      mapVerbs: g3,
      flatList: flatList,
    );
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

  Future<void> resolveAndApplyOntologyStyle({
    required RawUuid relationId,
    required String verb,
    required InteractionContext interactionContext,
  }) async {
    for (final rel in _queryController.relations) {
      if (rel.id != relationId && rel.verb == verb && rel.style != null) {
        interactionContext.onRelationUpdateStyle(relationId, rel.style!);
        return;
      }
    }

    final api = _api;
    if (api != null) {
      final spec = await api.getRelationSpec(verb: verb);
      if (spec != null) {
        interactionContext.onRelationUpdateStyle(relationId, spec);
      }
    }
  }
}
