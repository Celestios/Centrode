// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Usage:');
    print('  dart scripts/sync_version.dart <new-version>   (e.g., 0.2.0)');
    print(
      '  dart scripts/sync_version.dart minor           (bumps minor version & increments build)',
    );
    print(
      '  dart scripts/sync_version.dart patch           (bumps patch version & increments build)',
    );
    print(
      '  dart scripts/sync_version.dart build           (only increments build number)',
    );
    exit(1);
  }

  final command = arguments[0].toLowerCase();
  final pubspecFile = File('pubspec.yaml');
  final cargoFile = File('rust/Cargo.toml');
  final installerFile = File('windows/installer.iss');

  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found in the root directory.');
    exit(1);
  }

  if (!cargoFile.existsSync()) {
    print('Error: rust/Cargo.toml not found.');
    exit(1);
  }

  // 1. Read current version from pubspec.yaml
  var pubspecContent = pubspecFile.readAsStringSync();
  final pubspecRegex = RegExp(r'^version:\s*([^\s]+)', multiLine: true);
  final pubspecMatch = pubspecRegex.firstMatch(pubspecContent);

  if (pubspecMatch == null) {
    print('Error: Could not find version line in pubspec.yaml');
    exit(1);
  }

  final currentFullVersion = pubspecMatch.group(1)!; // e.g., 0.1.0+1 or 1.0.0
  var versionPart = currentFullVersion;
  var buildPart = 1;

  if (currentFullVersion.contains('+')) {
    final parts = currentFullVersion.split('+');
    versionPart = parts[0];
    buildPart = int.tryParse(parts[1]) ?? 1;
  }

  final versionMatch = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(versionPart);
  if (versionMatch == null) {
    print('Error: Invalid semver format in pubspec.yaml: $versionPart');
    exit(1);
  }

  var major = int.parse(versionMatch.group(1)!);
  var minor = int.parse(versionMatch.group(2)!);
  var patch = int.parse(versionMatch.group(3)!);

  // 2. Determine new version based on command
  String newVersion;
  int newBuild;

  if (command == 'minor') {
    minor += 1;
    patch = 0;
    newBuild = buildPart + 1;
    newVersion = '$major.$minor.$patch';
  } else if (command == 'patch') {
    patch += 1;
    newBuild = buildPart + 1;
    newVersion = '$major.$minor.$patch';
  } else if (command == 'build') {
    newBuild = buildPart + 1;
    newVersion = '$major.$minor.$patch';
  } else {
    // Treat as explicit version string
    final targetMatch = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(command);
    if (targetMatch == null) {
      print(
        'Error: Invalid command or version format. Expected "minor", "patch", "build" or "x.y.z".',
      );
      exit(1);
    }
    newVersion = command;
    newBuild = buildPart + 1;
  }

  final newFullPubspecVersion = '$newVersion+$newBuild';

  // 3. Write new version to pubspec.yaml
  pubspecContent = pubspecContent.replaceFirst(
    pubspecRegex,
    'version: $newFullPubspecVersion',
  );
  pubspecFile.writeAsStringSync(pubspecContent);
  print(
    '✅ Updated pubspec.yaml: $currentFullVersion ➡️ $newFullPubspecVersion',
  );

  // 4. Write new version to rust/Cargo.toml
  var cargoContent = cargoFile.readAsStringSync();
  final cargoRegex = RegExp(r'^version\s*=\s*"[^"]+"', multiLine: true);

  if (cargoRegex.hasMatch(cargoContent)) {
    cargoContent = cargoContent.replaceFirst(
      cargoRegex,
      'version = "$newVersion"',
    );
    cargoFile.writeAsStringSync(cargoContent);
    print('✅ Updated rust/Cargo.toml: version ➡️ "$newVersion"');
  } else {
    print(
      '⚠️ Warning: Could not find version line in rust/Cargo.toml. Skipping Cargo update.',
    );
  }

  // 5. Write new version to windows/installer.iss
  if (installerFile.existsSync()) {
    var installerContent = installerFile.readAsStringSync();
    final installerRegex = RegExp(
      r'#define\s+MyAppVersion\s+"[^"]+"',
      multiLine: true,
    );

    if (installerRegex.hasMatch(installerContent)) {
      installerContent = installerContent.replaceFirst(
        installerRegex,
        '#define MyAppVersion "$newVersion"',
      );
      installerFile.writeAsStringSync(installerContent);
      print('✅ Updated windows/installer.iss: MyAppVersion ➡️ "$newVersion"');
    }
  }
}
