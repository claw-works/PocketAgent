import 'package:flutter/foundation.dart';
import 'json_file_store.dart';
import 'skill/skill_registry.dart';

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
  int _maxToolRounds = 50;
  bool _autoApproveTool = false;

  String get name => _name;
  String get persona => _persona;
  String get voiceId => _voiceId;
  double get voiceSpeed => _voiceSpeed;
  String get language => _language;
  String get chatLanguage => _chatLanguage;
  int get maxToolRounds => _maxToolRounds;
  bool get autoApproveTool => _autoApproveTool;

  String get systemPrompt {
    final base = '你是 $_name，一个运行在用户设备上的私人 AI 助手。'
        '你的性格是：$_persona。'
        '你可以通过工具直接操控这台设备。回答简洁。\n\n'
        '## 操作策略\n'
        '当你操控浏览器或其他应用时，遵循"观察-行动"循环：\n'
        '1. 执行操作后，用 screenshot(mode: window) 截图查看结果\n'
        '2. 根据截图内容决定下一步操作\n'
        '3. 如果操作结果不符合预期，截图分析原因后重试\n'
        '4. 页面加载、跳转后主动截图确认状态\n'
        '5. 遇到不确定的界面元素时，截图分析而不是猜测\n\n'
        '## 自主学习\n'
        '你有能力创建和更新 Skill（技能）。在以下情况下你应该主动这样做：\n'
        '1. 用户要求你记住某个操作流程时，创建新 Skill\n'
        '2. 你成功完成了一个复杂的多步操作时，主动提议将其保存为 Skill\n'
        '3. 你发现现有 Skill 的操作步骤已过时（如选择器失效），主动更新\n'
        '4. 用户反复让你做类似的事情时，提议创建 Skill 以便下次更快执行\n\n'
        '创建 Skill 时：\n'
        '- skill.md 写清楚角色、策略、注意事项\n'
        '- SOP 文件写清楚操作步骤、关键选择器、异常处理\n'
        '- 用 skill 工具的 create action 写入文件\n';
    final skills = SkillRegistry.instance.combinedPrompt;
    return base + skills;
  }

  Future<void> load() async {
    final data = await _store.read();
    if (data is Map<String, dynamic>) {
      _name = data['name'] ?? _name;
      _persona = data['persona'] ?? _persona;
      _voiceId = data['voiceId'] ?? _voiceId;
      _voiceSpeed = (data['voiceSpeed'] as num?)?.toDouble() ?? _voiceSpeed;
      _language = data['language'] ?? _language;
      _chatLanguage = data['chatLanguage'] ?? _chatLanguage;
      _maxToolRounds = data['maxToolRounds'] as int? ?? _maxToolRounds;
      _autoApproveTool = data['autoApproveTool'] as bool? ?? _autoApproveTool;
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
      'maxToolRounds': _maxToolRounds,
      'autoApproveTool': _autoApproveTool,
    });
    notifyListeners();
  }

  Future<void> setName(String v) async { _name = v; await _save(); }
  Future<void> setPersona(String v) async { _persona = v; await _save(); }
  Future<void> setVoiceId(String v) async { _voiceId = v; await _save(); }
  Future<void> setVoiceSpeed(double v) async { _voiceSpeed = v; await _save(); }
  Future<void> setLanguage(String v) async { _language = v; await _save(); }
  Future<void> setChatLanguage(String v) async { _chatLanguage = v; await _save(); }
  Future<void> setMaxToolRounds(int v) async { _maxToolRounds = v; await _save(); }
  Future<void> setAutoApproveTool(bool v) async { _autoApproveTool = v; await _save(); }
}
