import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'pa_paths.dart';

/// Simple JSON file storage. All files go under PAPaths.dataDir.
class JsonFileStore {
  final String filename;
  JsonFileStore(this.filename);

  Future<File> get _file async {
    final dir = await PAPaths.dataDir;
    return File('$dir/$filename');
  }

  Future<dynamic> read() async {
    try {
      final f = await _file;
      if (!await f.exists()) return null;
      return jsonDecode(await f.readAsString());
    } catch (e) {
      debugPrint('JsonFileStore read error ($filename): $e');
      return null;
    }
  }

  Future<void> write(dynamic data) async {
    final f = await _file;
    await f.writeAsString(jsonEncode(data));
  }
}
