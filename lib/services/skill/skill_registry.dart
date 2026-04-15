import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'skill_model.dart';
import 'skill_runner.dart';
import '../cdp_client.dart';

/// Manages installed skills from ~/.pocketagent/skills/
class SkillRegistry {
  static final SkillRegistry instance = SkillRegistry._();
  SkillRegistry._();

  final _skills = <String, Skill>{};
  final _cdp = CdpClient();

  static String get _baseDir {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    return '$home/.pocketagent';
  }

  static String get skillsDir => '$_baseDir/skills';

  List<Skill> get all => _skills.values.toList();
  Skill? get(String name) => _skills[name];

  Future<void> load() async {
    final dir = Directory(skillsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      await _installBuiltins();
    }

    // Scan all subdirectories for skill.yaml / skill.json
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        await _loadSkillFromDir(entity);
      }
    }

    debugPrint('[Skills] Loaded ${_skills.length} skills: ${_skills.keys.join(', ')}');
  }

  Future<void> _loadSkillFromDir(Directory dir) async {
    // Try skill.json first, then skill.yaml
    final jsonFile = File('${dir.path}/skill.json');
    final yamlFile = File('${dir.path}/skill.yaml');

    try {
      if (await jsonFile.exists()) {
        final data = jsonDecode(await jsonFile.readAsString());
        final skill = Skill.fromJson(Map<String, dynamic>.from(data));
        _skills[skill.name] = skill;
      } else if (await yamlFile.exists()) {
        // Simple YAML parser for our subset (or read as JSON-compatible YAML)
        // For now, skills use JSON format. YAML support can be added with a package.
        debugPrint('[Skills] YAML not yet supported, use skill.json: ${dir.path}');
      }
    } catch (e) {
      debugPrint('[Skills] Failed to load skill from ${dir.path}: $e');
    }
  }

  /// Install a skill from a remote URL (raw JSON file).
  Future<void> installFromUrl(String url) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    final skill = Skill.fromJson(Map<String, dynamic>.from(data));
    await _saveSkill(skill);
    _skills[skill.name] = skill;
    debugPrint('[Skills] Installed: ${skill.name}');
  }

  /// Install a skill from a GitHub repo path: owner/repo/path/to/skill.json
  Future<void> installFromGithub(String repoPath) async {
    final url = 'https://raw.githubusercontent.com/$repoPath/main/skill.json';
    await installFromUrl(url);
  }

  Future<void> add(Skill skill) async {
    await _saveSkill(skill);
    _skills[skill.name] = skill;
  }

  Future<void> remove(String name) async {
    _skills.remove(name);
    final dir = Directory('$skillsDir/$name');
    if (await dir.exists()) await dir.delete(recursive: true);
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

  Future<void> _saveSkill(Skill skill) async {
    final dir = Directory('$skillsDir/${skill.name}');
    await dir.create(recursive: true);
    final file = File('${dir.path}/skill.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(skill.toJson()));
  }

  Future<void> _installBuiltins() async {
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
          SkillStep(action: 'get_text', args: {'selector': 'body', 'save_as': 'content'}),
          SkillStep(action: 'return', args: {'value': '{{content}}'}),
        ],
      ),
    ];
    for (final s in builtins) {
      await _saveSkill(s);
      _skills[s.name] = s;
    }
  }
}
