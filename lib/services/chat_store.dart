import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

class ChatTopic {
  final String id;
  String title;
  final List<Message> messages;
  DateTime updatedAt;

  ChatTopic({
    required this.id,
    required this.title,
    List<Message>? messages,
    DateTime? updatedAt,
  })  : messages = messages ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages
            .map((m) => {
                  'id': m.id,
                  'role': m.role.name,
                  'content': m.content,
                  'timestamp': m.timestamp.toIso8601String(),
                  if (m.toolName != null) 'toolName': m.toolName,
                })
            .toList(),
      };

  factory ChatTopic.fromJson(Map<String, dynamic> j) {
    final msgs = (j['messages'] as List).map((m) => Message(
          id: m['id'],
          role: MessageRole.values.byName(m['role']),
          content: m['content'],
          timestamp: DateTime.parse(m['timestamp']),
          toolName: m['toolName'],
        )).toList();
    return ChatTopic(
      id: j['id'],
      title: j['title'],
      messages: msgs,
      updatedAt: DateTime.parse(j['updatedAt']),
    );
  }
}

/// Manages chat topics with persistence.
class ChatStore extends ChangeNotifier {
  static final ChatStore instance = ChatStore._();
  ChatStore._();

  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();
  static const _key = 'chat_topics';
  List<ChatTopic> _topics = [];

  List<ChatTopic> get topics => List.unmodifiable(_topics);

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _topics = list.map((e) => ChatTopic.fromJson(e)).toList();
    }
  }

  ChatTopic create({String? title}) {
    final topic = ChatTopic(id: _uuid.v4(), title: title ?? '新对话');
    _topics.insert(0, topic);
    _save();
    notifyListeners();
    return topic;
  }

  Future<void> addMessage(String topicId, Message message) async {
    final topic = _topics.firstWhere((t) => t.id == topicId);
    topic.messages.add(message);
    topic.updatedAt = DateTime.now();
    // Auto-title from first user message
    if (topic.title == '新对话' && message.role == MessageRole.user) {
      topic.title = message.content.length > 20
          ? '${message.content.substring(0, 20)}...'
          : message.content;
    }
    // Move to top
    _topics.remove(topic);
    _topics.insert(0, topic);
    await _save();
    notifyListeners();
  }

  Future<void> delete(String topicId) async {
    _topics.removeWhere((t) => t.id == topicId);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.write(
      key: _key,
      value: jsonEncode(_topics.map((e) => e.toJson()).toList()),
    );
  }
}
