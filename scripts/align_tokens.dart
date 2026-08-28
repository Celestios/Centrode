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
    'UiSpacing.xxxs': 'UiSpacing.xs',
    'UiSpacing.xxs': 'UiSpacing.xs',
    'UiSpacing.xl': 'UiSpacing.lg',
    'UiSpacing.xxl': 'UiSpacing.lg',

    // Radius
    'UiRadius.xs': 'UiRadius.sm',
    'UiRadius.xl': 'UiRadius.lg',
    'UiRadius.xxl': 'UiRadius.lg',

    // IconSize
    'UiIconSize.xs': 'UiIconSize.sm',
    'UiIconSize.xl': 'UiIconSize.lg',
    'UiIconSize.xxl': 'UiIconSize.lg',

    // ControlSize
    'UiControlSize.micro': 'UiControlSize.dense',
    'UiControlSize.compact': 'UiControlSize.dense',
    'UiControlSize.bar': 'UiControlSize.tile',

    // StrokeWidth
    'UiStrokeWidth.hairline': 'UiStrokeWidth.subtle',
    'UiStrokeWidth.medium': 'UiStrokeWidth.thick',
    'UiStrokeWidth.heavy': 'UiStrokeWidth.thick',
    'UiStrokeWidth.selected': 'UiStrokeWidth.thick',

    // Motion
    'UiMotion.buttonHoverScale': 'UiMotion.hoverScale',
    'UiMotion.buttonPressScale': 'UiMotion.pressScale',
    'UiMotion.smooth': 'UiMotion.standard',
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
      stdout.writeln('Updated ${file.path}: $changesInFile tokens aligned');
    }
  }

  stdout.writeln('\n====================================================');
  stdout.writeln('Token Alignment Complete!');
  stdout.writeln('Files updated: $totalFiles');
  stdout.writeln('Total token alignments: $totalChanges');
  stdout.writeln('====================================================');
}
