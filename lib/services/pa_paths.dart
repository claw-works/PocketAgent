import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Centralized path management for PocketAgent.
/// Desktop: ~/.pocketagent/
/// Mobile: app documents directory / pocketagent/
class PAPaths {
  static String? _base;

  static Future<String> get base async {
    if (_base != null) return _base!;

    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      // Desktop: use ~/.pocketagent
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
      _base = '$home/.pocketagent';
    } else {
      // Mobile: use app documents directory
      final docs = await getApplicationDocumentsDirectory();
      _base = '${docs.path}/pocketagent';
    }

    await Directory(_base!).create(recursive: true);
    return _base!;
  }

  static Future<String> get skillsDir async {
    final b = await base;
    final dir = '$b/skills';
    await Directory(dir).create(recursive: true);
    return dir;
  }

  static Future<String> get chromeProfileDir async {
    final b = await base;
    final dir = '$b/chrome_profile';
    await Directory(dir).create(recursive: true);
    return dir;
  }

  static Future<String> get dataDir async {
    final b = await base;
    final dir = '$b/data';
    await Directory(dir).create(recursive: true);
    return dir;
  }
}
