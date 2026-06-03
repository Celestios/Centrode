enum UiSearchResultType { infoNode, taskNode, relation }

class UiSearchResult {
  final String key;
  final String title;
  final String subtitle;
  final UiSearchResultType type;

  const UiSearchResult({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}
