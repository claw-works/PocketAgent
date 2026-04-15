import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'db/database.dart';

/// Activity log backed by SQLite.
class ActivityLog extends ChangeNotifier {
  static final ActivityLog instance = ActivityLog._();
  ActivityLog._();

  AppDatabase get _db => AppDatabase.instance;

  List<ActivityEntry> _entries = [];
  List<ActivityEntry> get entries => _entries;

  Future<void> load() async {
    _entries = await _db.getRecentActivity();
    _db.watchRecentActivity().listen((e) {
      _entries = e;
      notifyListeners();
    });
  }

  Future<void> add({
    required String action,
    required String detail,
    required bool success,
  }) async {
    await _db.insertActivity(ActivityEntriesCompanion.insert(
      action: action,
      detail: detail,
      success: Value(success),
    ));
  }
}
