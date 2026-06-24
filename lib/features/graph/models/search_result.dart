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

enum DatabaseSearchResultType { infoNode, taskNode, relation }

class DatabaseSearchResult {
  final String key;
  final DatabaseSearchResultType type;
  final String text;
  final String? state;

  const DatabaseSearchResult({
    required this.key,
    required this.type,
    required this.text,
    this.state,
  });
}
