import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import 'db/database.dart';

/// Chat store backed by SQLite via drift.
class ChatStore extends ChangeNotifier {
  static final ChatStore instance = ChatStore._();
  ChatStore._();

  final _uuid = const Uuid();
  AppDatabase get _db => AppDatabase.instance;

  List<ChatTopic> _topics = [];
  List<ChatTopic> get topics => _topics;

  Future<void> load() async {
    _topics = await _db.getAllTopics();
    // Listen for changes
    _db.watchAllTopics().listen((t) {
      _topics = t;
      notifyListeners();
    });
  }

  Future<ChatTopic> create({String? title}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.upsertTopic(ChatTopicsCompanion.insert(
      id: id,
      title: Value(title ?? '新对话'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    _topics = await _db.getAllTopics();
    notifyListeners();
    return _topics.firstWhere((t) => t.id == id);
  }

  Future<List<ChatMessage>> getMessages(String topicId) {
    return _db.getMessages(topicId);
  }

  Stream<List<ChatMessage>> watchMessages(String topicId) {
    return _db.watchMessages(topicId);
  }

  Future<void> addMessage(String topicId, Message message) async {
    await _db.insertMessage(ChatMessagesCompanion.insert(
      id: message.id,
      topicId: topicId,
      role: message.role.name,
      content: message.content,
      toolName: Value(message.toolName),
    ));

    // Auto-title from first user message
    final topic = _topics.firstWhere((t) => t.id == topicId);
    var title = topic.title;
    if (title == '新对话' && message.role == MessageRole.user) {
      title = message.content.length > 20
          ? '${message.content.substring(0, 20)}...'
          : message.content;
    }

    await _db.upsertTopic(ChatTopicsCompanion(
      id: Value(topicId),
      title: Value(title),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> delete(String topicId) async {
    await _db.deleteTopic(topicId);
  }

  Future<void> clear() async {
    await _db.deleteAllTopics();
  }

  Future<List<ChatMessage>> searchMessages(String query) {
    return _db.searchMessages(query);
  }
}
