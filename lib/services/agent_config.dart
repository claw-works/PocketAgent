import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Agent profile configuration — name, persona, voice, etc.
class AgentConfig extends ChangeNotifier {
  static final AgentConfig instance = AgentConfig._();
  AgentConfig._();

  final _storage = const FlutterSecureStorage();

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
    _name = await _storage.read(key: 'agent_name') ?? _name;
    _persona = await _storage.read(key: 'agent_persona') ?? _persona;
    _voiceId = await _storage.read(key: 'agent_voice') ?? _voiceId;
    final speed = await _storage.read(key: 'agent_voice_speed');
    if (speed != null) _voiceSpeed = double.tryParse(speed) ?? _voiceSpeed;
    _language = await _storage.read(key: 'ui_language') ?? _language;
    _chatLanguage = await _storage.read(key: 'chat_language') ?? _chatLanguage;
  }

  Future<void> setName(String v) async {
    _name = v;
    await _storage.write(key: 'agent_name', value: v);
    notifyListeners();
  }

  Future<void> setPersona(String v) async {
    _persona = v;
    await _storage.write(key: 'agent_persona', value: v);
    notifyListeners();
  }

  Future<void> setVoiceId(String v) async {
    _voiceId = v;
    await _storage.write(key: 'agent_voice', value: v);
    notifyListeners();
  }

  Future<void> setVoiceSpeed(double v) async {
    _voiceSpeed = v;
    await _storage.write(key: 'agent_voice_speed', value: v.toString());
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    _language = v;
    await _storage.write(key: 'ui_language', value: v);
    notifyListeners();
  }

  Future<void> setChatLanguage(String v) async {
    _chatLanguage = v;
    await _storage.write(key: 'chat_language', value: v);
    notifyListeners();
  }
}
