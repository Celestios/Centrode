import 'dart:io';

void main() {
  final domainSrcDir = Directory('rust/centrode_domain/src');
  final coreDomainDir = Directory('rust/centrode_core/src/domain');
  final coreDomainFile = File('rust/centrode_core/src/domain.rs');

  if (!domainSrcDir.existsSync()) {
    stderr.writeln('Error: ${domainSrcDir.path} does not exist.');
    exit(1);
  }

  if (coreDomainDir.existsSync()) {
    coreDomainDir.deleteSync(recursive: true);
  }
  coreDomainDir.createSync(recursive: true);

  final domainLibFile = File('rust/centrode_domain/src/lib.rs');
  if (domainLibFile.existsSync()) {
    final content = domainLibFile.readAsStringSync();
    coreDomainFile.writeAsStringSync(content);
    print('Synced domain.rs from centrode_domain/src/lib.rs');
  }

  int count = 0;
  for (final entity in domainSrcDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.rs') && !entity.path.endsWith('lib.rs')) {
      final relativePath = entity.path.substring(domainSrcDir.path.length + 1);
      final destFile = File('${coreDomainDir.path}/$relativePath');
      destFile.parent.createSync(recursive: true);
      destFile.writeAsBytesSync(entity.readAsBytesSync());
      count++;
    }
  }

  print('Successfully synced $count domain source files from centrode_domain to centrode_core/src/domain.');
}
