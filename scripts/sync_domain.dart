// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final coreDomainDir = Directory('rust/centrode_core/src/domain');
  final coreDomainFile = File('rust/centrode_core/src/domain.rs');
  final daemonDomainDir = Directory('rust/centrode_daemon/src/domain');
  final daemonDomainFile = File('rust/centrode_daemon/src/domain.rs');

  if (!coreDomainDir.existsSync()) {
    stderr.writeln('Error: ${coreDomainDir.path} does not exist.');
    exit(1);
  }

  if (daemonDomainDir.existsSync()) {
    daemonDomainDir.deleteSync(recursive: true);
  }
  daemonDomainDir.createSync(recursive: true);

  if (coreDomainFile.existsSync()) {
    final content = coreDomainFile.readAsStringSync();
    daemonDomainFile.writeAsStringSync(content);
    print('Synced domain.rs from centrode_core to centrode_daemon');
  }

  int count = 0;
  for (final entity in coreDomainDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.rs')) {
      final relativePath = entity.path.substring(coreDomainDir.path.length + 1);
      final destFile = File('${daemonDomainDir.path}/$relativePath');
      destFile.parent.createSync(recursive: true);
      destFile.writeAsBytesSync(entity.readAsBytesSync());
      count++;
    }
  }

  print('Successfully synced $count domain source files from centrode_core to centrode_daemon/src/domain.');
}
