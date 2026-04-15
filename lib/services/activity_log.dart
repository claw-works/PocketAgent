import 'package:flutter/foundation.dart';
import 'json_file_store.dart';

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

class ActivityLog extends ChangeNotifier {
  static final ActivityLog instance = ActivityLog._();
  ActivityLog._();

  final _store = JsonFileStore('activity_log.json');
  List<ActivityEntry> _entries = [];

  List<ActivityEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final data = await _store.read();
    if (data is List) {
      _entries = data.map((e) => ActivityEntry.fromJson(e)).toList();
    }
  }

  Future<void> add(ActivityEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > 200) _entries = _entries.sublist(0, 200);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _store.write(_entries.map((e) => e.toJson()).toList());
  }
}
