// ============================================================
//  icon_updater.dart — Flutter App Icon Update CLI Script
// ============================================================
//
//  USAGE:
//    dart run lib/util/icon_updator.dart [options]
//
//  OPTIONS:
//    --project  <path>   Absolute path to the Flutter project root.
//                        If omitted, the current working directory is used.
//    --source   <path>   Absolute path to the icons source folder.
//    --platforms <list>  Comma-separated platforms to update.
//                        Supported: android, ios, web
//                        Example: --platforms android,ios,web
//    --icon-name <name>  Android icon base name (e.g. launcher_icon or ic_launcher).
//                        If omitted, the script will try to detect it from source.
//
//  EXAMPLES:
//    dart run lib/util/icon_updator.dart
//      (fully interactive — will prompt for every value)
//
//    dart run lib/helper/icon_updater.dart \
//      --project /absolute/path/to/my_app \
//      --source  /absolute/path/to/my_logo \
//      --platforms android,ios
//
// ============================================================
//  EXPECTED SOURCE FOLDER STRUCTURE:
//
//  <source>/
//    android/
//      res/
//        mipmap-anydpi-v26/   ← launcher_icon.xml or ic_launcher.xml
//        mipmap-hdpi/         ← launcher_icon.png or ic_launcher.png + layers
//        mipmap-mdpi/
//        mipmap-xhdpi/
//        mipmap-xxhdpi/
//        mipmap-xxxhdpi/
//    ios/
//      AppIcon-20@2x.png      ← all AppIcon-*.png files
//      ...
//      Contents.json
//    web/
//      Icon-192.png           ← used as web/icons/Icon-192.png
//      Icon-512.png           ← used as web/icons/Icon-512.png
//      favicon.png            ← (optional) copied to web/favicon.png
//
// ============================================================

// ignore_for_file: avoid_print

import 'dart:io';

// ─── Entry point ────────────────────────────────────────────

void main(List<String> args) async {
  printBanner();

  final parsed = parseArgs(args);
  final requestedIconName = parsed['iconName'];

  // ── Resolve project path ──────────────────────────────────
  String projectPath = parsed['project'] ?? Directory.current.path;

  if (parsed['project'] == null) {
    final detected = isFlutterProject(projectPath) ? projectPath : null;

    if (detected != null) {
      logInfo('Flutter project detected at current directory:\n  $projectPath');
      final confirm = prompt('Use this as the project root? [Y/n]');
      if (confirm.toLowerCase() == 'n') {
        projectPath = prompt('Enter the Flutter project root path');
      }
    } else {
      projectPath = prompt('Enter the Flutter project root path');
    }
  }

  if (!isFlutterProject(projectPath)) {
    logError(
      'No pubspec.yaml found at "$projectPath". '
      'Please provide a valid Flutter project root.',
    );
    exit(1);
  }

  // ── Resolve source path ───────────────────────────────────
  String sourcePath =
      parsed['source'] ?? prompt('Enter the icons source folder path');

  if (!Directory(sourcePath).existsSync()) {
    logError('Source folder not found: "$sourcePath"');
    exit(1);
  }

  // ── Resolve platforms ─────────────────────────────────────
  List<String> platforms;
  if (parsed['platforms'] != null) {
    platforms = (parsed['platforms'] as String)
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  } else {
    printPlatformMenu();
    final input = prompt(
      'Enter platforms to update (comma-separated, e.g. 1,2,3 or android,ios,web)',
    );
    platforms = resolvePlatformInput(input);
  }

  const supported = ['android', 'ios', 'web'];
  final invalid = platforms.where((p) => !supported.contains(p)).toList();
  if (invalid.isNotEmpty) {
    logError(
      'Unsupported platform(s): ${invalid.join(', ')}'
      '\nSupported: android, ios, web',
    );
    exit(1);
  }

  if (platforms.isEmpty) {
    logError('No platforms selected. Aborting.');
    exit(1);
  }

  // ── Summary before execution ──────────────────────────────
  print('');
  divider();
  print(' Project  : $projectPath');
  print(' Source   : $sourcePath');
  print(' Platforms: ${platforms.join(', ')}');
  divider();
  final go = prompt('Proceed? [Y/n]');
  if (go.toLowerCase() == 'n') {
    logInfo('Aborted by user.');
    exit(0);
  }
  print('');

  // ── Execute per platform ──────────────────────────────────
  int errors = 0;
  for (final platform in platforms) {
    switch (platform) {
      case 'android':
        errors += updateAndroid(
          projectPath,
          sourcePath,
          iconName: requestedIconName,
        );
        break;
      case 'ios':
        errors += updateIos(projectPath, sourcePath);
        break;
      case 'web':
        errors += updateWeb(projectPath, sourcePath);
        break;
    }
  }

  print('');
  divider();
  if (errors == 0) {
    logSuccess('All icons updated successfully!');
    logInfo(
      'Remember to do a clean build:\n'
      '  flutter clean && flutter pub get',
    );
  } else {
    logWarn('Done with $errors error(s). Review the output above.');
  }
  divider();
}

// ─── Platform handlers ───────────────────────────────────────

/// Copies Android mipmap resource folders from source → project.
int updateAndroid(String project, String source, {String? iconName}) {
  sectionHeader('Android');

  final sep = Platform.pathSeparator;
  final srcRes = Directory('$source${sep}android${sep}res');
  final dstRes = Directory(
    '$project${sep}android${sep}app${sep}src${sep}main${sep}res',
  );

  if (!srcRes.existsSync()) {
    logWarn(
      '  [Android] Source "android/res" folder not found at:\n'
      '    ${srcRes.path}\n'
      '  Skipping Android.',
    );
    return 1;
  }
  if (!dstRes.existsSync()) {
    logWarn(
      '  [Android] Destination res folder not found at:\n'
      '    ${dstRes.path}\n'
      '  Skipping Android.',
    );
    return 1;
  }

  int count = 0;
  int errors = 0;

  final resolvedIconName = iconName ?? detectAndroidIconName(srcRes);

  for (final entity in srcRes.listSync()) {
    if (entity is Directory) {
      final folderName = basename(entity.path);
      final dstFolder = Directory('${dstRes.path}$sep$folderName');
      if (!resetDir(dstFolder)) {
        errors++;
        continue;
      }

      for (final file in entity.listSync().whereType<File>()) {
        try {
          final fileName = basename(file.path);
          file.copySync('${dstFolder.path}$sep$fileName');
          logOk('  [$folderName] $fileName');
          count++;
        } catch (e) {
          logWarn('  Failed to copy ${basename(file.path)}: $e');
          errors++;
        }
      }
    }
  }

  logInfo('  Android: $count file(s) copied.');

  if (resolvedIconName != null) {
    updateAndroidManifestIcon(project, resolvedIconName);
  } else {
    logWarn(
      '  [Android] Could not detect icon base name from source. '
      'Use --icon-name to update AndroidManifest.xml automatically.',
    );
  }
  return errors;
}

/// Copies iOS AppIcon files from source → project AppIcon.appiconset.
int updateIos(String project, String source) {
  sectionHeader('iOS');

  final sep = Platform.pathSeparator;
  final srcDir = Directory('$source${sep}ios');
  final dstDir = Directory(
    '$project${sep}ios${sep}Runner'
    '${sep}Assets.xcassets$sep'
    'AppIcon.appiconset',
  );

  if (!srcDir.existsSync()) {
    logWarn(
      '  [iOS] Source "ios" folder not found at:\n'
      '    ${srcDir.path}\n'
      '  Skipping iOS.',
    );
    return 1;
  }
  if (!dstDir.existsSync()) {
    logWarn(
      '  [iOS] Destination AppIcon.appiconset not found at:\n'
      '    ${dstDir.path}\n'
      '  Skipping iOS.',
    );
    return 1;
  }

  int count = 0;
  int errors = 0;

  final srcFiles = srcDir.listSync().whereType<File>().toList();
  final srcFileNames = srcFiles.map((f) => basename(f.path)).toSet();
  if (!srcFileNames.contains('Contents.json')) {
    logWarn('  [iOS] Contents.json not found in source. Keeping destination Contents.json.');
    srcFileNames.add('Contents.json');
  }

  // Remove old files that are not in the source set.
  for (final file in dstDir.listSync().whereType<File>()) {
    final name = basename(file.path);
    if (!srcFileNames.contains(name)) {
      try {
        file.deleteSync();
      } catch (e) {
        logWarn('  Failed to remove $name: $e');
        errors++;
      }
    }
  }
  for (final file in srcFiles) {
    try {
      final sep = Platform.pathSeparator;
      final fileName = basename(file.path);
      file.copySync('${dstDir.path}$sep$fileName');
      logOk('  $fileName');
      count++;
    } catch (e) {
      logWarn('  Failed to copy ${basename(file.path)}: $e');
      errors++;
    }
  }

  logInfo('  iOS: $count file(s) copied.');
  return errors;
}

/// Copies web icons (Icon-192, Icon-512, favicon) from source → project.
int updateWeb(String project, String source) {
  sectionHeader('Web');

  final sep = Platform.pathSeparator;
  final srcDir = Directory('$source${sep}web');
  final dstIcons = Directory('$project${sep}web${sep}icons');
  final dstWeb = Directory('$project${sep}web');

  if (!srcDir.existsSync()) {
    logWarn(
      '  [Web] Source "web" folder not found at:\n'
      '    ${srcDir.path}\n'
      '  Skipping Web.',
    );
    return 1;
  }
  if (!dstWeb.existsSync()) {
    logWarn(
      '  [Web] Destination web folder not found at:\n'
      '    ${dstWeb.path}\n'
      '  Skipping Web.',
    );
    return 1;
  }

  if (!dstIcons.existsSync()) {
    dstIcons.createSync(recursive: true);
  }

  // Files that go into web/icons/
  const iconFiles = ['Icon-192.png', 'Icon-512.png'];
  // Files that go into web/ root
  const rootFiles = ['favicon.png', 'favicon.ico'];

  int count = 0;
  int errors = 0;

  // Remove known destination icon files before copying.
  final cleanupTargets = <String>[
    '${dstIcons.path}${sep}Icon-192.png',
    '${dstIcons.path}${sep}Icon-512.png',
    '${dstWeb.path}${sep}favicon.png',
    '${dstWeb.path}${sep}favicon.ico',
  ];
  for (final path in cleanupTargets) {
    final file = File(path);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (e) {
        logWarn('  Failed to remove ${basename(file.path)}: $e');
        errors++;
      }
    }
  }

  for (final file in srcDir.listSync().whereType<File>()) {
    final name = basename(file.path);
    try {
      if (iconFiles.contains(name)) {
        file.copySync('${dstIcons.path}$sep$name');
        logOk('  web/icons/$name');
        count++;
      } else if (rootFiles.contains(name)) {
        file.copySync('${dstWeb.path}$sep$name');
        logOk('  web/$name');
        count++;
      } else if (name.endsWith('.png') ||
          name.endsWith('.svg') ||
          name.endsWith('.jpg')) {
        // Copy any other image to web/icons/
        file.copySync('${dstIcons.path}$sep$name');
        logOk('  web/icons/$name');
        count++;
      }
    } catch (e) {
      logWarn('  Failed to copy $name: $e');
      errors++;
    }
  }

  if (count == 0) {
    logWarn(
      '  [Web] No recognised icon files found in source "web" folder.\n'
      '  Expected: Icon-192.png, Icon-512.png, favicon.png',
    );
  } else {
    logInfo('  Web: $count file(s) copied.');
  }
  return errors;
}

// ─── CLI argument parser ─────────────────────────────────────

Map<String, String?> parseArgs(List<String> args) {
  final result = <String, String?>{
    'project': null,
    'source': null,
    'platforms': null,
    'iconName': null,
  };

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--project':
        if (i + 1 < args.length) result['project'] = args[++i];
        break;
      case '--source':
        if (i + 1 < args.length) result['source'] = args[++i];
        break;
      case '--platforms':
        if (i + 1 < args.length) result['platforms'] = args[++i];
        break;
      case '--icon-name':
        if (i + 1 < args.length) result['iconName'] = args[++i];
        break;
      case '--help':
      case '-h':
        printHelp();
        exit(0);
    }
  }
  return result;
}

// ─── Platform menu resolver ──────────────────────────────────

List<String> resolvePlatformInput(String input) {
  final parts = input.split(',').map((e) => e.trim().toLowerCase()).toList();
  const numToName = {'1': 'android', '2': 'ios', '3': 'web'};
  return parts
      .map((p) => numToName[p] ?? p)
      .where((p) => p.isNotEmpty)
      .toList();
}

// ─── Utilities ────────────────────────────────────────────────

String basename(String path) {
  final parts = path.replaceAll('\\', '/').split('/');
  return parts.last;
}

String basenameWithoutExt(String path) {
  final name = basename(path);
  final dot = name.lastIndexOf('.');
  return dot == -1 ? name : name.substring(0, dot);
}

bool isFlutterProject(String path) =>
    File('$path${Platform.pathSeparator}pubspec.yaml').existsSync();

String prompt(String question) {
  stdout.write(' > $question: ');
  return (stdin.readLineSync() ?? '').trim();
}

bool resetDir(Directory dir) {
  try {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
    return true;
  } catch (e) {
    logWarn('  Failed to reset ${dir.path}: $e');
    return false;
  }
}

String? detectAndroidIconName(Directory srcRes) {
  final sep = Platform.pathSeparator;
  final anydpi = Directory('${srcRes.path}${sep}mipmap-anydpi-v26');
  if (anydpi.existsSync()) {
    for (final file in anydpi.listSync().whereType<File>()) {
      if (file.path.toLowerCase().endsWith('.xml')) {
        return basenameWithoutExt(file.path);
      }
    }
  }

  final candidates = ['launcher_icon', 'ic_launcher'];
  final mipmaps = srcRes
      .listSync()
      .whereType<Directory>()
      .where((d) => basename(d.path).startsWith('mipmap-'))
      .toList();

  for (final candidate in candidates) {
    for (final dir in mipmaps) {
      final file = File('${dir.path}$sep$candidate.png');
      if (file.existsSync()) return candidate;
    }
  }

  return null;
}

void updateAndroidManifestIcon(String project, String iconName) {
  final sep = Platform.pathSeparator;
  final manifestPath =
      '$project${sep}android${sep}app${sep}src${sep}main${sep}AndroidManifest.xml';
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    logWarn('  [Android] AndroidManifest.xml not found: $manifestPath');
    return;
  }

  final original = manifestFile.readAsStringSync();
  var updated = original;

  final iconPattern = RegExp(r'android:icon="@mipmap/[^\"]+"');
  if (iconPattern.hasMatch(updated)) {
    updated = updated.replaceFirst(
      iconPattern,
      'android:icon="@mipmap/$iconName"',
    );
  }

  final roundPattern = RegExp(r'android:roundIcon="@mipmap/[^\"]+"');
  if (roundPattern.hasMatch(updated)) {
    updated = updated.replaceFirst(
      roundPattern,
      'android:roundIcon="@mipmap/$iconName"',
    );
  }

  if (updated != original) {
    manifestFile.writeAsStringSync(updated);
    logInfo('  AndroidManifest.xml updated: @mipmap/$iconName');
  } else {
    logWarn('  [Android] android:icon not found in AndroidManifest.xml');
  }
}

// ─── Output helpers ───────────────────────────────────────────

const reset = '\x1B[0m';
const green = '\x1B[32m';
const yellow = '\x1B[33m';
const red = '\x1B[31m';
const cyan = '\x1B[36m';
const bold = '\x1B[1m';

void logOk(String msg) => print('$green  ✔$reset $msg');
void logInfo(String msg) => print('$cyan  ℹ$reset $msg');
void logWarn(String msg) => print('$yellow  ⚠$reset $msg');
void logError(String msg) => print('$red  ✖ ERROR: $msg$reset');
void logSuccess(String msg) => print('$green$bold  ✔ $msg$reset');
void divider() => print('─' * 55);

void sectionHeader(String name) {
  print('');
  print('$bold  ▸ $name$reset');
}

void printBanner() {
  print('');
  divider();
  print('$bold  Flutter App Icon Updater$reset');
  print('  Platforms supported: Android · iOS · Web');
  divider();
  print('');
}

void printPlatformMenu() {
  print('');
  print('  Available Platforms:');
  print('    1) Android');
  print('    2) iOS');
  print('    3) Web');
  print('');
}

void printHelp() {
  printBanner();
  print('''
  USAGE:
    dart run lib/util/icon_updator.dart [options]

  OPTIONS:
    --project  <path>    Flutter project root path.
                         Defaults to current working directory.
    --source   <path>    Icons source folder path (required).
    --platforms <list>   Comma-separated platforms: android, ios, web
                         Example: --platforms android,ios,web
    --icon-name <name>   Android icon base name (launcher_icon or ic_launcher).
               If omitted, the script tries to detect it from source.
    --help, -h           Show this help message.

  EXAMPLES:
    # Interactive (will prompt for all values):
    dart run lib/util/icon_updator.dart

    # Fully automated (Windows):
    dart run lib/util/icon_updator.dart --project "D:\\my_app" --source "D:\\my_logo" --platforms android,ios,web

    # Fully automated (Mac/Linux):
    dart run lib/util/icon_updator.dart --project /path/to/my_app --source /path/to/my_logo --platforms android,ios,web

  EXPECTED SOURCE FOLDER STRUCTURE:
    <source>/
      android/
        res/
          mipmap-anydpi-v26/
          mipmap-hdpi/
          mipmap-mdpi/
          mipmap-xhdpi/
          mipmap-xxhdpi/
          mipmap-xxxhdpi/
      ios/
        AppIcon-*.png  (all icon variants)
        Contents.json
      web/
        Icon-192.png
        Icon-512.png
        favicon.png    (optional)
''');
}