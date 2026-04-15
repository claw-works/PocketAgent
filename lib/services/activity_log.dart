import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ActivityEntry {
  final String action;
  final String detail;
  final DateTime time;
  final bool success;

  ActivityEntry({
    required this.action,
    required this.detail,
    required this.time,
    required this.success,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'detail': detail,
        'time': time.toIso8601String(),
        'success': success,
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
        action: j['action'],
        detail: j['detail'],
        time: DateTime.parse(j['time']),
        success: j['success'] ?? true,
      );
}

/// Persisted activity log for tool executions.
class ActivityLog extends ChangeNotifier {
  static final ActivityLog instance = ActivityLog._();
  ActivityLog._();

  final _storage = const FlutterSecureStorage();
  static const _key = 'activity_log';
  List<ActivityEntry> _entries = [];

  List<ActivityEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _entries = list.map((e) => ActivityEntry.fromJson(e)).toList();
    }
  }

  Future<void> add(ActivityEntry entry) async {
    _entries.insert(0, entry);
    // Keep last 200 entries
    if (_entries.length > 200) _entries = _entries.sublist(0, 200);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.write(
      key: _key,
      value: jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }
}
