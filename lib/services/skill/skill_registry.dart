import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../pa_paths.dart';
import 'harness_model.dart';

/// A Skill is a directory of markdown files that give the AI knowledge and SOPs.
/// If it contains harness.md, it becomes a HarnessSkill (self-evolving assistant).
class Skill {
  final String name;
  final String skillPrompt;
  final Map<String, String> sops;

  Skill({required this.name, required this.skillPrompt, this.sops = const {}});

  String get fullPrompt {
    final buf = StringBuffer(skillPrompt);
    for (final entry in sops.entries) {
      buf.writeln('\n\n---\n');
      buf.writeln(entry.value);
    }
    return buf.toString();
  }
}

/// Manages skills and harness skills from ~/.pocketagent/skills/
class SkillRegistry extends ChangeNotifier {
  static final SkillRegistry instance = SkillRegistry._();
  SkillRegistry._();

  final _skills = <String, Skill>{};
  final _harnessSkills = <String, HarnessSkill>{};
  static String? _skillsDir;

  static Future<String> get skillsDir async {
    _skillsDir ??= await PAPaths.skillsDir;
    return _skillsDir!;
  }

  List<Skill> get all => _skills.values.toList();
  List<HarnessSkill> get harnessSkills => _harnessSkills.values.toList();
  Skill? get(String name) => _skills[name];
  HarnessSkill? getHarness(String name) => _harnessSkills[name];

  /// Combined prompt from regular skills (non-harness), injected into system prompt.
  String get combinedPrompt {
    if (_skills.isEmpty) return '';
    final buf = StringBuffer('\n\n# 你的技能\n');
    for (final skill in _skills.values) {
      buf.writeln('\n${skill.fullPrompt}');
    }
    return buf.toString();
  }

  Future<void> load() async {
    final dirPath = await skillsDir;
    final dir = Directory(dirPath);
    await dir.create(recursive: true);

    _skills.clear();
    _harnessSkills.clear();

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        // Check if it's a harness skill
        final harnessFile = File('${entity.path}/harness.md');
        if (await harnessFile.exists()) {
          final hs = await HarnessSkill.loadFromDir(entity);
          if (hs != null) _harnessSkills[hs.name] = hs;
        } else {
          await _loadSkillFromDir(entity);
        }
      }
    }

    if (_skills.isEmpty && _harnessSkills.isEmpty) {
      await _installBuiltins();
    }

    debugPrint('[Skills] Loaded ${_skills.length} skills, ${_harnessSkills.length} harness skills');
    notifyListeners();
  }

  Future<void> _loadSkillFromDir(Directory dir) async {
    final name = dir.path.split('/').last;
    final skillFile = File('${dir.path}/skill.md');
    if (!await skillFile.exists()) return;

    try {
      final skillPrompt = await skillFile.readAsString();
      final sops = <String, String>{};
      await for (final file in dir.list()) {
        if (file is File && file.path.endsWith('.md') && !file.path.endsWith('skill.md')) {
          final sopName = file.path.split('/').last.replaceAll('.md', '');
          sops[sopName] = await file.readAsString();
        }
      }
      _skills[name] = Skill(name: name, skillPrompt: skillPrompt, sops: sops);
    } catch (e) {
      debugPrint('[Skills] Failed to load $name: $e');
    }
  }

  Future<void> installFromUrl(String url) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final content = await response.transform(const SystemEncoding().decoder).join();
    final nameMatch = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(content);
    final name = nameMatch?.group(1)?.toLowerCase().replaceAll(RegExp(r'\s+'), '_') ??
        url.split('/').last.replaceAll('.md', '');
    final dirPath = '${await skillsDir}/$name';
    await Directory(dirPath).create(recursive: true);
    await File('$dirPath/skill.md').writeAsString(content);
    await load();
  }

  Future<void> remove(String name) async {
    _skills.remove(name);
    _harnessSkills.remove(name);
    final dir = Directory('${await skillsDir}/$name');
    if (await dir.exists()) await dir.delete(recursive: true);
    notifyListeners();
  }

  Future<void> _installBuiltins() async {
    final dirPath = await skillsDir;

    // Built-in harness skill: Google Search
    final searchDir = Directory('$dirPath/google_search');
    await searchDir.create(recursive: true);
    await File('${searchDir.path}/skill.md').writeAsString('''
# Google 搜索助手

## 你的角色
你是一个搜索专家，帮用户在 Google 上找到最相关的信息。

## 策略
- 理解用户真正想找什么，必要时追问
- 将自然语言转化为高效的搜索关键词
- 搜索后总结前 5 条结果的要点
- 如果结果不理想，换关键词重试
''');
    await File('${searchDir.path}/search.md').writeAsString('''
# 搜索 SOP

## 操作步骤
1. 用 browser 工具导航到 `https://www.google.com/search?q={关键词}`
2. 等待 2 秒让页面加载
3. 用 get_content 获取页面文本
4. 提取搜索结果标题和摘要

## 选择器参考
- 搜索结果标题：`h3`
- 搜索结果摘要：`.VwiC3b`

## 异常处理
- 如果出现验证码，告诉用户手动处理
- 如果页面结构变化，用 get_content(format: text) 直接读文本
''');
    await File('${searchDir.path}/harness.md').writeAsString('''
# 验证条件

## 搜索执行后
- 必须返回至少 1 条搜索结果
- 每条结果应包含标题
- 如果返回 0 结果且关键词合理，判定为页面结构变化

## 失败处理
- 截图分析页面，检查选择器是否失效
- 更新 search.md 中的选择器参考
- 记录修正原因

## 性能基线
- 搜索应在 15 秒内完成
''');

    // Built-in regular skill: Browser Assistant
    final browserDir = Directory('$dirPath/browser_assistant');
    await browserDir.create(recursive: true);
    await File('${browserDir.path}/skill.md').writeAsString('''
# 浏览器操作助手

## 你的角色
你可以操控用户的浏览器完成各种网页操作。

## 可用工具
- browser(navigate): 打开网页
- browser(get_content): 读取页面内容
- browser(execute_js): 执行 JavaScript
- browser(click): 点击元素
- browser(type_text): 在输入框输入文字
- browser(screenshot): 截图

## 操作原则
1. 先 navigate 到目标页面
2. 用 get_content 了解页面结构
3. 用精准的 CSS 选择器操作元素
4. 操作后截图确认结果
''');

    await load();
  }
}
