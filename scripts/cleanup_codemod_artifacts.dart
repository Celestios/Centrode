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
    String newContent = content;

    // Fix `const UiMotion.fast` / `const UiMotion.standard`
    newContent = newContent.replaceAll('const UiMotion.fast', 'UiMotion.fast');
    newContent = newContent.replaceAll('const UiMotion.standard', 'UiMotion.standard');

    // Fix partial replacements like `UiFont.micro.5` -> `UiFont.compact`
    newContent = newContent.replaceAll('UiFont.micro.5', 'UiFont.compact');
    newContent = newContent.replaceAll('UiFont.compact.5', 'UiFont.standard');
    newContent = newContent.replaceAll('UiFont.standard.5', 'UiFont.standard');
    newContent = newContent.replaceAll('UiFont.header.5', 'UiFont.header');
    newContent = newContent.replaceAll('UiFont.title.5', 'UiFont.title');

    // Fix partial stroke replacements like `UiStrokeWidth.standard.2` -> `UiStrokeWidth.thick`
    newContent = newContent.replaceAll('UiStrokeWidth.standard.2', 'UiStrokeWidth.thick');
    newContent = newContent.replaceAll('UiStrokeWidth.standard.5', 'UiStrokeWidth.thick');
    newContent = newContent.replaceAll('UiStrokeWidth.standard.8', 'UiStrokeWidth.thick');

    if (newContent != content) {
      file.writeAsStringSync(newContent);
      cleaned++;
    }
  }
  stdout.writeln('Cleaned syntax artifacts in $cleaned files.');
}
