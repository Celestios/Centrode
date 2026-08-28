import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('design_tokens.dart'))
      .toList();

  final Map<String, String> tokenRenames = {
    // Spacing
    'UiSpacing.xs': 'UiSpacing.tight',
    'UiSpacing.sm': 'UiSpacing.standard',
    'UiSpacing.md': 'UiSpacing.container',
    'UiSpacing.lg': 'UiSpacing.gutter',

    // Radius
    'UiRadius.sm': 'UiRadius.control',
    'UiRadius.md': 'UiRadius.card',
    'UiRadius.lg': 'UiRadius.panel',

    // IconSize
    'UiIconSize.sm': 'UiIconSize.dense',
    'UiIconSize.md': 'UiIconSize.standard',
    'UiIconSize.lg': 'UiIconSize.header',
  };

  int totalFiles = 0;
  int totalChanges = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content;
    int changesInFile = 0;

    for (final entry in tokenRenames.entries) {
      if (newContent.contains(entry.key)) {
        final matches = RegExp(RegExp.escape(entry.key)).allMatches(newContent).length;
        newContent = newContent.replaceAll(entry.key, entry.value);
        changesInFile += matches;
      }
    }

    if (changesInFile > 0) {
      file.writeAsStringSync(newContent);
      totalFiles++;
      totalChanges += changesInFile;
      stdout.writeln('Updated ${file.path}: $changesInFile canonical tokens updated');
    }
  }

  stdout.writeln('\n====================================================');
  stdout.writeln('Canonical Alignment Complete!');
  stdout.writeln('Files updated: $totalFiles');
  stdout.writeln('Total token updates: $totalChanges');
  stdout.writeln('====================================================');
}
