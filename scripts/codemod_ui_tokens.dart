import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln('Error: lib/ directory not found.');
    exit(1);
  }

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

  int totalReplacements = 0;
  int filesModified = 0;

  final Map<Pattern, String> replacements = {
    // Icon & Graphic Sizes
    RegExp(r'\bsize:\s*(?:14|16)(?:\.0)?\b'): 'size: UiIconSize.dense',
    RegExp(r'\bsize:\s*(?:18|20)(?:\.0)?\b'): 'size: UiIconSize.standard',
    RegExp(r'\bsize:\s*24(?:\.0)?\b'): 'size: UiIconSize.header',
    RegExp(r'\biconSize:\s*20(?:\.0)?\b'): 'iconSize: UiIconSize.standard',

    // Control Heights & Widths
    RegExp(r'\bheight:\s*32(?:\.0)?\b'): 'height: UiControlSize.standard',
    RegExp(r'\bheight:\s*30(?:\.0)?\b'): 'height: UiControlSize.standard',
    RegExp(r'\bheight:\s*28(?:\.0)?\b'): 'height: UiControlSize.dense',
    RegExp(r'\bheight:\s*26(?:\.0)?\b'): 'height: UiControlSize.dense',
    RegExp(r'\bheight:\s*20(?:\.0)?\b'): 'height: UiControlSize.dense',
    RegExp(r'\bheight:\s*40(?:\.0)?\b'): 'height: UiControlSize.tile',

    // Stroke Widths & Borders
    RegExp(r'\bwidth:\s*0\.8\b'): 'width: UiStrokeWidth.subtle',
    RegExp(r'\bwidth:\s*1(?:\.0)?\b'): 'width: UiStrokeWidth.standard',
    RegExp(r'\bwidth:\s*1\.5\b'): 'width: UiStrokeWidth.thick',
    RegExp(r'\bwidth:\s*2(?:\.0)?\b'): 'width: UiStrokeWidth.thick',

    // Residual SizedBox
    RegExp(r'\bSizedBox\(\s*width:\s*10(?:\.0)?\s*\)'): 'const SizedBox(width: UiSpacing.standard)',
    RegExp(r'\bSizedBox\(\s*height:\s*10(?:\.0)?\s*\)'): 'const SizedBox(height: UiSpacing.standard)',
    RegExp(r'\bSizedBox\(\s*width:\s*14(?:\.0)?\s*\)'): 'const SizedBox(width: UiSpacing.container)',
    RegExp(r'\bSizedBox\(\s*height:\s*14(?:\.0)?\s*\)'): 'const SizedBox(height: UiSpacing.container)',
    RegExp(r'\bSizedBox\(\s*width:\s*20(?:\.0)?\s*\)'): 'const SizedBox(width: UiSpacing.gutter)',
    RegExp(r'\bSizedBox\(\s*height:\s*20(?:\.0)?\s*\)'): 'const SizedBox(height: UiSpacing.gutter)',

    // Font Micro Steps
    RegExp(r'\bfontSize:\s*8(?:\.0)?\b'): 'fontSize: UiFont.micro',
    RegExp(r'\bfontSize:\s*8\.5\b'): 'fontSize: UiFont.micro',
    RegExp(r'\bfontSize:\s*9(?:\.0)?\b'): 'fontSize: UiFont.micro',
    RegExp(r'\bfontSize:\s*9\.5\b'): 'fontSize: UiFont.micro',
  };

  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content;
    int fileChanges = 0;

    for (final entry in replacements.entries) {
      final matches = entry.key.allMatches(newContent).length;
      if (matches > 0) {
        newContent = newContent.replaceAll(entry.key, entry.value);
        fileChanges += matches;
      }
    }

    if (fileChanges > 0) {
      if (!newContent.contains("design_tokens.dart") &&
          !newContent.contains("package:centrode/shared/elements/elements.dart")) {
        newContent = "import 'package:centrode/shared/theme/design_tokens.dart';\n" + newContent;
      }
      newContent = newContent.replaceAll('const const SizedBox', 'const SizedBox');

      file.writeAsStringSync(newContent);
      filesModified++;
      totalReplacements += fileChanges;
      stdout.writeln('Modified: ${file.path} ($fileChanges token replacements)');
    }
  }

  stdout.writeln('\n====================================================');
  stdout.writeln('Deep Sweep Codemod Complete!');
  stdout.writeln('Files modified: $filesModified');
  stdout.writeln('Total replacements: $totalReplacements');
  stdout.writeln('====================================================');
}
