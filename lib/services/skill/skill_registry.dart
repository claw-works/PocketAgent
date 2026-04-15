import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'skill_model.dart';
import 'skill_runner.dart';
import '../cdp_client.dart';
import '../json_file_store.dart';

/// Manages installed skills — load, save, run.
class SkillRegistry {
  static final SkillRegistry instance = SkillRegistry._();
  SkillRegistry._();

  final _store = JsonFileStore('skills.json');
  final _skills = <String, Skill>{};
  final _cdp = CdpClient();

  List<Skill> get all => _skills.values.toList();
  Skill? get(String name) => _skills[name];

  Future<void> load() async {
    final data = await _store.read();
    if (data is List) {
      for (final s in data) {
        final skill = Skill.fromJson(Map<String, dynamic>.from(s));
        _skills[skill.name] = skill;
      }
    }
    // Load built-in skills if empty
    if (_skills.isEmpty) _loadBuiltins();
  }

  Future<void> add(Skill skill) async {
    _skills[skill.name] = skill;
    await _save();
  }

  Future<void> remove(String name) async {
    _skills.remove(name);
    await _save();
  }

  Future<String> run(String name, Map<String, dynamic> params) async {
    final skill = _skills[name];
    if (skill == null) return jsonEncode({'status': 'error', 'message': '未找到技能: $name'});

    if (!_cdp.isConnected) {
      try {
        await _cdp.connect();
      } catch (e) {
        return jsonEncode({'status': 'error', 'message': '浏览器连接失败: $e'});
      }
    }

    final runner = SkillRunner(_cdp);
    return runner.run(skill, params);
  }

  Future<void> _save() async {
    await _store.write(_skills.values.map((s) => s.toJson()).toList());
  }

  void _loadBuiltins() {
    final builtins = [
      Skill(
        name: 'google_search',
        description: '在 Google 搜索关键词并返回结果',
        params: [SkillParam(name: 'query', description: '搜索关键词', required: true)],
        steps: [
          SkillStep(action: 'navigate', args: {'url': 'https://www.google.com'}),
          SkillStep(action: 'wait', args: {'seconds': 1}),
          SkillStep(action: 'type_text', args: {'selector': 'textarea[name=q]', 'text': '{{query}}'}),
          SkillStep(action: 'press_key', args: {'key': 'Enter'}),
          SkillStep(action: 'wait', args: {'seconds': 2}),
          SkillStep(action: 'query_all', args: {'selector': 'h3', 'save_as': 'results', 'limit': 5}),
          SkillStep(action: 'return', args: {'value': '{{results}}'}),
        ],
      ),
      Skill(
        name: 'open_website',
        description: '打开指定网站并获取页面主要内容',
        params: [SkillParam(name: 'url', description: '网站 URL', required: true)],
        steps: [
          SkillStep(action: 'navigate', args: {'url': '{{url}}'}),
          SkillStep(action: 'wait', args: {'seconds': 2}),
          SkillStep(action: 'execute_js', args: {'expression': 'document.title'}),
          SkillStep(action: 'get_text', args: {'selector': 'body', 'save_as': 'content'}),
          SkillStep(action: 'return', args: {'value': '{{content}}'}),
        ],
      ),
    ];
    for (final s in builtins) {
      _skills[s.name] = s;
    }
    _save();
  }
}
