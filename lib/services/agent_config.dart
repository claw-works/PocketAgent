import 'package:flutter/foundation.dart';
import 'json_file_store.dart';

/// Agent profile configuration — name, persona, voice, etc.
/// Non-sensitive, uses file storage.
class AgentConfig extends ChangeNotifier {
  static final AgentConfig instance = AgentConfig._();
  AgentConfig._();

  final _store = JsonFileStore('agent_config.json');

  String _name = 'PocketAgent';
  String _persona = '友好、专业的 AI 助手';
  String _voiceId = 'alloy';
  double _voiceSpeed = 1.0;
  String _language = '简体中文';
  String _chatLanguage = '自动检测';

  String get name => _name;
  String get persona => _persona;
  String get voiceId => _voiceId;
  double get voiceSpeed => _voiceSpeed;
  String get language => _language;
  String get chatLanguage => _chatLanguage;

  String get systemPrompt =>
      '你是 $_name，一个运行在用户手机上的私人 AI 助手。'
      '你的性格是：$_persona。'
      '你可以通过工具直接操控这台设备。回答简洁。';

  Future<void> load() async {
    final data = await _store.read();
    if (data is Map<String, dynamic>) {
      _name = data['name'] ?? _name;
      _persona = data['persona'] ?? _persona;
      _voiceId = data['voiceId'] ?? _voiceId;
      _voiceSpeed = (data['voiceSpeed'] as num?)?.toDouble() ?? _voiceSpeed;
      _language = data['language'] ?? _language;
      _chatLanguage = data['chatLanguage'] ?? _chatLanguage;
    }
  }

  Future<void> _save() async {
    await _store.write({
      'name': _name,
      'persona': _persona,
      'voiceId': _voiceId,
      'voiceSpeed': _voiceSpeed,
      'language': _language,
      'chatLanguage': _chatLanguage,
    });
    notifyListeners();
  }

  Future<void> setName(String v) async { _name = v; await _save(); }
  Future<void> setPersona(String v) async { _persona = v; await _save(); }
  Future<void> setVoiceId(String v) async { _voiceId = v; await _save(); }
  Future<void> setVoiceSpeed(double v) async { _voiceSpeed = v; await _save(); }
  Future<void> setLanguage(String v) async { _language = v; await _save(); }
  Future<void> setChatLanguage(String v) async { _chatLanguage = v; await _save(); }
}
