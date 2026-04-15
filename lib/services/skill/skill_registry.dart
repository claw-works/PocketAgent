import 'dart:io';
import 'package:flutter/foundation.dart';
import '../pa_paths.dart';

/// A Skill is a directory of markdown files that give the AI knowledge and SOPs.
/// 
/// Structure:
///   ~/.pocketagent/skills/
///   └── shopping_assistant/
///       ├── skill.md              # Role, strategy, context
///       ├── search_product.md     # SOP 1
///       └── checkout.md           # SOP 2
///
/// skill.md is the main entry point (required).
/// All other .md files are SOPs that the AI can reference.
/// Everything is injected into the system prompt.
class Skill {
  final String name;
  final String skillPrompt;      // Content of skill.md
  final Map<String, String> sops; // filename → content

  Skill({required this.name, required this.skillPrompt, this.sops = const {}});

  /// Full prompt text: skill.md + all SOPs concatenated.
  String get fullPrompt {
    final buf = StringBuffer(skillPrompt);
    for (final entry in sops.entries) {
      buf.writeln('\n\n---\n');
      buf.writeln(entry.value);
    }
    return buf.toString();
  }
}

/// Manages skills from ~/.pocketagent/skills/
class SkillRegistry {
  static final SkillRegistry instance = SkillRegistry._();
  SkillRegistry._();

  final _skills = <String, Skill>{};
  static String? _skillsDir;

  static Future<String> get skillsDir async {
    _skillsDir ??= await PAPaths.skillsDir;
    return _skillsDir!;
  }

  List<Skill> get all => _skills.values.toList();
  Skill? get(String name) => _skills[name];

  /// Combined prompt from all enabled skills, injected into system prompt.
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

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        await _loadSkillFromDir(entity);
      }
    }

    if (_skills.isEmpty) {
      await _installBuiltins();
    }

    debugPrint('[Skills] Loaded ${_skills.length} skills: ${_skills.keys.join(', ')}');
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
    // Download a .md file and save as a single-file skill
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final content = await response.transform(const SystemEncoding().decoder).join();

    // Extract name from first heading or URL
    final nameMatch = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(content);
    final name = nameMatch?.group(1)?.toLowerCase().replaceAll(RegExp(r'\s+'), '_') ??
        url.split('/').last.replaceAll('.md', '');

    final dirPath = '${await skillsDir}/$name';
    await Directory(dirPath).create(recursive: true);
    await File('$dirPath/skill.md').writeAsString(content);
    await _loadSkillFromDir(Directory(dirPath));
  }

  Future<void> remove(String name) async {
    _skills.remove(name);
    final dir = Directory('${await skillsDir}/$name');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> _installBuiltins() async {
    final dirPath = await skillsDir;

    // Built-in: Google Search
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

## 输出格式
用简洁的中文总结搜索结果，附上关键链接。
''');
    await File('${searchDir.path}/search.md').writeAsString('''
# 搜索 SOP

## 操作步骤
1. 用 browser 工具导航到 `https://www.google.com/search?q={关键词}`
2. 等待 2 秒让页面加载
3. 用 get_content 获取页面文本
4. 提取搜索结果标题和摘要

## 选择器参考（如果用 execute_js）
- 搜索结果标题：`h3`
- 搜索结果摘要：`.VwiC3b`

## 异常处理
- 如果出现验证码，告诉用户手动处理
- 如果页面结构变化，用 get_content(format: text) 直接读文本
''');

    // Built-in: 通用浏览器助手
    final browserDir = Directory('$dirPath/browser_assistant');
    await browserDir.create(recursive: true);
    await File('${browserDir.path}/skill.md').writeAsString('''
# 浏览器操作助手

## 你的角色
你可以操控用户的浏览器完成各种网页操作。

## 可用工具
- browser(navigate): 打开网页
- browser(get_content): 读取页面内容（text 或 html）
- browser(execute_js): 执行 JavaScript
- browser(click): 点击元素（CSS 选择器）
- browser(type_text): 在输入框输入文字
- browser(screenshot): 截图

## 操作原则
1. 先 navigate 到目标页面
2. 用 get_content 了解页面结构
3. 用精准的 CSS 选择器操作元素
4. 操作后再 get_content 确认结果
5. 遇到问题时用 screenshot 截图分析

## 注意事项
- 不要自动填写密码或支付信息，需要用户确认
- 操作前告诉用户你要做什么
- 如果页面需要登录，提示用户先手动登录
''');

    // Reload
    await for (final entity in Directory(dirPath).list()) {
      if (entity is Directory) {
        await _loadSkillFromDir(entity);
      }
    }
  }
}
