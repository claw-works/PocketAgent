import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Simple JSON file storage for non-sensitive data (chat history, activity log).
/// Use flutter_secure_storage only for secrets (API keys).
class JsonFileStore {
  final String filename;
  JsonFileStore(this.filename);

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
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
