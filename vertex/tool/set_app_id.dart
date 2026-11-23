// Sets the store app ID (Android applicationId, iOS/macOS bundle ID).
//
//   dart run tool/set_app_id.dart com.yourdomain.vertex
//
// Run it before the first store upload: stores tie the listing to this ID
// and it cannot change afterwards. The Android Kotlin package (namespace)
// is internal and is left as is.
import 'dart:io';

final _idPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9_]*)+$');

void main(List<String> args) {
  if (args.length != 1 || !_idPattern.hasMatch(args.single)) {
    stderr.writeln(
      'Usage: dart run tool/set_app_id.dart com.yourdomain.vertex\n'
      'Lowercase, dot-separated, each part starting with a letter.',
    );
    exit(64);
  }
  final next = args.single;
  final gradle = File('android/app/build.gradle.kts');
  final current = RegExp(r'applicationId = "([^"]+)"')
      .firstMatch(gradle.readAsStringSync())
      ?.group(1);
  if (current == null) {
    stderr.writeln('Could not find applicationId in ${gradle.path}.');
    exit(1);
  }
  if (current == next) {
    stdout.writeln('App ID is already $next.');
    return;
  }

  var changed = 0;
  void update(String path, String Function(String) edit) {
    final f = File(path);
    final before = f.readAsStringSync();
    final after = edit(before);
    if (after != before) {
      f.writeAsStringSync(after);
      changed++;
      stdout.writeln('  updated $path');
    }
  }

  String bundleIds(String s) => s.replaceAllMapped(
    RegExp(
      'PRODUCT_BUNDLE_IDENTIFIER = ${RegExp.escape(current)}(\\.RunnerTests)?;',
    ),
    (m) => 'PRODUCT_BUNDLE_IDENTIFIER = $next${m[1] ?? ''};',
  );

  update(
    gradle.path,
    (s) =>
        s.replaceFirst('applicationId = "$current"', 'applicationId = "$next"'),
  );
  update('ios/Runner.xcodeproj/project.pbxproj', bundleIds);
  update('macos/Runner.xcodeproj/project.pbxproj', bundleIds);
  update(
    'macos/Runner/Configs/AppInfo.xcconfig',
    (s) => s.replaceFirst(
      'PRODUCT_BUNDLE_IDENTIFIER = $current',
      'PRODUCT_BUNDLE_IDENTIFIER = $next',
    ),
  );
  stdout.writeln('App ID changed from $current to $next ($changed files).');
}
