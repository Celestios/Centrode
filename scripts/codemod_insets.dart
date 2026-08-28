import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) =>
          !f.path.endsWith('.g.dart') &&
          !f.path.endsWith('.freezed.dart') &&
          !f.path.contains('frb_generated') &&
          !f.path.contains('design_tokens.dart'))
      .toList();

  final Map<Pattern, String> insetsReplacements = {
    RegExp(r'\bEdgeInsets\.all\(\s*4(?:\.0)?\s*\)'): 'UiInsets.tight',
    RegExp(r'\bEdgeInsets\.all\(\s*8(?:\.0)?\s*\)'): 'UiInsets.standard',
    RegExp(r'\bEdgeInsets\.all\(\s*16(?:\.0)?\s*\)'): 'UiInsets.container',
    RegExp(r'\bEdgeInsets\.all\(\s*24(?:\.0)?\s*\)'): 'UiInsets.gutter',

    RegExp(r'\bEdgeInsets\.symmetric\(\s*horizontal:\s*4(?:\.0)?\s*\)'): 'UiInsets.horizontalTight',
    RegExp(r'\bEdgeInsets\.symmetric\(\s*horizontal:\s*8(?:\.0)?\s*\)'): 'UiInsets.horizontalStandard',
    RegExp(r'\bEdgeInsets\.symmetric\(\s*horizontal:\s*16(?:\.0)?\s*\)'): 'UiInsets.horizontalContainer',
    RegExp(r'\bEdgeInsets\.symmetric\(\s*horizontal:\s*24(?:\.0)?\s*\)'): 'UiInsets.horizontalGutter',

    RegExp(r'\bEdgeInsets\.symmetric\(\s*vertical:\s*4(?:\.0)?\s*\)'): 'UiInsets.verticalTight',
    RegExp(r'\bEdgeInsets\.symmetric\(\s*vertical:\s*8(?:\.0)?\s*\)'): 'UiInsets.verticalStandard',
    RegExp(r'\bEdgeInsets\.symmetric\(\s*vertical:\s*16(?:\.0)?\s*\)'): 'UiInsets.verticalContainer',
    RegExp(r'\bEdgeInsets\.symmetric\(\s*vertical:\s*24(?:\.0)?\s*\)'): 'UiInsets.verticalGutter',
  };

  int totalFiles = 0;
  int totalChanges = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content;
    int changesInFile = 0;

    for (final entry in insetsReplacements.entries) {
      final matches = entry.key.allMatches(newContent).length;
      if (matches > 0) {
        newContent = newContent.replaceAll(entry.key, entry.value);
        changesInFile += matches;
      }
    }

    if (changesInFile > 0) {
      if (!newContent.contains("design_tokens.dart") &&
          !newContent.contains("package:centrode/shared/elements/elements.dart")) {
        newContent = "import 'package:centrode/shared/theme/design_tokens.dart';\n" + newContent;
      }

      // Cleanup any duplicate const keywords (const const UiInsets)
      newContent = newContent.replaceAll('const UiInsets.', 'UiInsets.');

      file.writeAsStringSync(newContent);
      totalFiles++;
      totalChanges += changesInFile;
      stdout.writeln('Updated ${file.path}: $changesInFile insets tokenized');
    }
  }

  stdout.writeln('\n====================================================');
  stdout.writeln('UiInsets Codemod Complete!');
  stdout.writeln('Files updated: $totalFiles');
  stdout.writeln('Total insets tokenized: $totalChanges');
  stdout.writeln('====================================================');
}
