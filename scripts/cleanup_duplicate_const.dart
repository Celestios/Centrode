import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  int cleaned = 0;
  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('const const SizedBox')) {
      content = content.replaceAll('const const SizedBox', 'const SizedBox');
      file.writeAsStringSync(content);
      cleaned++;
    }
  }
  stdout.writeln('Cleaned duplicate const keywords in $cleaned files.');
}
