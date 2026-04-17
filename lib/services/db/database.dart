import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import '../pa_paths.dart';

part 'database.g.dart';

// ── Tables ──────────────────────────────────────────────────

class ChatTopics extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant('新对话'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get topicId => text().references(ChatTopics, #id)();
  TextColumn get role => text()(); // user, assistant, system, tool
  TextColumn get content => text()();
  TextColumn get toolName => text().nullable()();
  TextColumn get toolCallId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ActivityEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()();
  TextColumn get detail => text()();
  BoolColumn get success => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Database ────────────────────────────────────────────────

@DriftDatabase(tables: [ChatTopics, ChatMessages, ActivityEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(chatMessages, chatMessages.toolCallId);
          }
        },
      );

  // ── Chat Topics ─────────────────────────────────────────

  Future<List<ChatTopic>> getAllTopics() {
    return (select(chatTopics)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  Stream<List<ChatTopic>> watchAllTopics() {
    return (select(chatTopics)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  Future<void> upsertTopic(ChatTopicsCompanion topic) {
    return into(chatTopics).insertOnConflictUpdate(topic);
  }

  Future<void> deleteTopic(String id) async {
    await (delete(chatMessages)..where((m) => m.topicId.equals(id))).go();
    await (delete(chatTopics)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAllTopics() async {
    await delete(chatMessages).go();
    await delete(chatTopics).go();
  }

  // ── Chat Messages ───────────────────────────────────────

  Future<List<ChatMessage>> getMessages(String topicId, {int? limit}) {
    final q = select(chatMessages)
      ..where((m) => m.topicId.equals(topicId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);
    if (limit != null) q.limit(limit);
    // Query desc then reverse to get chronological order
    return q.get().then((list) => list.reversed.toList());
  }

  Stream<List<ChatMessage>> watchMessages(String topicId, {int? limit}) {
    final q = select(chatMessages)
      ..where((m) => m.topicId.equals(topicId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);
    if (limit != null) q.limit(limit);
    return q.watch().map((list) => list.reversed.toList());
  }

  Future<void> insertMessage(ChatMessagesCompanion msg) {
    return into(chatMessages).insert(msg);
  }

  // Search messages across all topics
  Future<List<ChatMessage>> searchMessages(String query) {
    return (select(chatMessages)..where((m) => m.content.like('%$query%'))).get();
  }

  // ── Activity Log ────────────────────────────────────────

  Future<List<ActivityEntry>> getRecentActivity({int limit = 200}) {
    return (select(activityEntries)
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<ActivityEntry>> watchRecentActivity({int limit = 200}) {
    return (select(activityEntries)
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> insertActivity(ActivityEntriesCompanion entry) {
    return into(activityEntries).insert(entry);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final base = await PAPaths.dataDir;
    final file = File(p.join(base, 'pocket_agent.db'));
    return NativeDatabase.createInBackground(file);
  });
}
