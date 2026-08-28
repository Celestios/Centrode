import 'dart:io';

void main(List<String> args) {
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
          !f.path.contains('frb_generated'))
      .toList();

  stdout.writeln('====================================================');
  stdout.writeln('Centrode Handwritten Dart Literal & Sizing Scanner');
  stdout.writeln('Scanning ${files.length} handwritten Dart files...');
  stdout.writeln('====================================================\n');

  final Map<String, List<String>> numberMatches = {};
  final Map<String, List<String>> stringMatches = {};
  final Map<String, int> numberFrequency = {};
  final Map<String, int> stringFrequency = {};

  // Regex patterns for UI numeric properties
  final numPatterns = [
    RegExp(r'(BorderRadius\.circular\s*\(\s*([0-9.]+)\s*\))'),
    RegExp(r'(EdgeInsets\.(?:all|symmetric|only)\s*\([^)]*\))'),
    RegExp(r'(SizedBox\s*\(\s*(?:width|height):\s*([0-9.]+)\s*\))'),
    RegExp(r'(\b(?:width|height):\s*([0-9.]+))'),
    RegExp(r'(\b(?:fontSize):\s*([0-9.]+))'),
    RegExp(r'(\b(?:strokeWidth):\s*([0-9.]+))'),
    RegExp(r'(\b(?:iconSize|size):\s*([0-9.]+))'),
    RegExp(r'(\b(?:blurRadius|spreadRadius):\s*([0-9.]+))'),
    RegExp(r'(\bDuration\s*\(\s*milliseconds:\s*([0-9]+)\s*\))'),
  ];

  // Regex pattern for UI strings
  final textPattern = RegExp(r"""(?:Text|Tooltip|title|label|message|hintText|confirmLabel|cancelLabel)\s*\(\s*['"]([^'"]{2,})['"]""");

  for (final file in files) {
    final relPath = file.path.replaceAll(r'\', '/');
    final lines = file.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // Skip comment lines and imports
      final trimmed = line.trim();
      if (trimmed.startsWith('//') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('import ') ||
          trimmed.startsWith('export ')) {
        continue;
      }

      // Check numbers
      for (final p in numPatterns) {
        for (final match in p.allMatches(line)) {
          final matchedText = match.group(0)!;
          // Filter out already tokenized references
          if (matchedText.contains('Ui') ||
              matchedText.contains('Tokens') ||
              matchedText.contains('Constants')) {
            continue;
          }
          final loc = '$relPath:$lineNum: $trimmed';
          numberMatches.putIfAbsent(matchedText, () => []).add(loc);
          numberFrequency[matchedText] = (numberFrequency[matchedText] ?? 0) + 1;
        }
      }

      // Check UI strings
      for (final match in textPattern.allMatches(line)) {
        final str = match.group(1)!;
        if (str.trim().isEmpty) continue;
        final loc = '$relPath:$lineNum: "$str"';
        stringMatches.putIfAbsent(str, () => []).add(loc);
        stringFrequency[str] = (stringFrequency[str] ?? 0) + 1;
      }
    }
  }

  stdout.writeln('--- TOP 25 UNTOKENIZED UI NUMERIC CONSTRUCTS ---');
  final sortedNumbers = numberFrequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sortedNumbers.take(25)) {
    stdout.writeln('${entry.value.toString().padLeft(4)}x | ${entry.key}');
  }

  stdout.writeln('\n--- TOP 25 REPEATED UI STRING LITERALS ---');
  final sortedStrings = stringFrequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sortedStrings.take(25)) {
    stdout.writeln('${entry.value.toString().padLeft(4)}x | "${entry.key}"');
  }

  stdout.writeln('\n====================================================');
  stdout.writeln('Total Untokenized Numeric Occurrences: ${sortedNumbers.fold<int>(0, (sum, e) => sum + e.value)}');
  stdout.writeln('Total Extracted UI String Occurrences: ${sortedStrings.fold<int>(0, (sum, e) => sum + e.value)}');
  stdout.writeln('Unique Numbers: ${sortedNumbers.length} | Unique Strings: ${sortedStrings.length}');
  stdout.writeln('====================================================');
}
