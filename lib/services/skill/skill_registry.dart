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

    // Built-in harness skill: X (Twitter) Post
    final xPostDir = Directory('$dirPath/x_post');
    await xPostDir.create(recursive: true);
    await File('${xPostDir.path}/skill.md').writeAsString('''
# X (Twitter) 发帖助手

## 你的角色
你是一个 X 发帖专家，帮用户把想法发布到 X (Twitter)。

## 策略
- 用户给出大致内容后，主动优化成适合 X 的帖子（简洁、有钩子、可带 emoji）
- 单条帖子限制 280 字符，超过要问用户：截断 / 发成 thread / 精简
- 发帖前务必给用户看最终版本，用户确认后再发
- 如果需要图片/链接附件，提前让用户准备

## 核心流程
1. 生成/确认帖子内容
2. 用户确认 → 执行 publish SOP
3. 验证帖子已发出（URL、时间戳）
4. 失败则按 harness 定义处理

## 可用 SOP
- `publish` — 标准发帖流程
- `publish_thread` — 发 thread (多条串联)
''');

    await File('${xPostDir.path}/publish.md').writeAsString('''
# SOP: publish (发单条帖子)

## 前置条件
- 用户已确认帖子内容 (content)
- 字数 ≤ 280
- 浏览器已登录 X 账号（如未登录，先告诉用户手动登录）

## 步骤
1. `browser(navigate, url: "https://x.com/home")`
2. 等待 2 秒，确认已登录（检查是否有 "Post" 按钮或撰写框）
3. 点击撰写框：`browser(click, selector: '[data-testid="tweetTextarea_0"]')`
4. 输入内容：`browser(type_text, selector: '[data-testid="tweetTextarea_0"]', text: content)`
5. 截图给用户确认
6. 点击发送按钮：`browser(click, selector: '[data-testid="tweetButtonInline"]')`
7. 等待 3 秒，验证：
   - 撰写框被清空
   - 页面出现"Your post was sent"或新帖子出现在时间线
8. 返回新帖子链接（可用 `[data-testid="tweet"] a[href*="/status/"]` 取第一个）

## 选择器参考（可能会变）
| 元素 | 选择器 |
|-----|-------|
| 撰写框 | `[data-testid="tweetTextarea_0"]` |
| 发送按钮 | `[data-testid="tweetButtonInline"]` |
| 已发帖子链接 | `[data-testid="tweet"] a[href*="/status/"]` |

## 异常
- 未登录：停止，告诉用户手动登录
- 字数超限：停止，回报实际字数
- 发送按钮被禁用：可能内容违规，截图让用户判断
''');

    await File('${xPostDir.path}/publish_thread.md').writeAsString('''
# SOP: publish_thread (发 thread)

## 前置条件
- 内容已分段成数组 segments[]，每段 ≤ 280
- 用户已确认所有段落

## 步骤
1. 导航到 `https://x.com/home` 并确认登录
2. 点击撰写框，输入第一段
3. 对于剩余每一段：
   - 点击 "+" 添加按钮：`browser(click, selector: '[data-testid="addButton"]')`
   - 在新增的文本框 `[data-testid="tweetTextarea_{i}"]` 输入内容
4. 截图让用户确认整个 thread
5. 点击发送：`browser(click, selector: '[data-testid="tweetButtonInline"]')`
6. 验证：所有段落出现在时间线，形成串联

## 选择器参考
| 元素 | 选择器 |
|-----|-------|
| 添加按钮 | `[data-testid="addButton"]` |
| 第 i 个文本框 | `[data-testid="tweetTextarea_\${i}"]` |
''');

    await File('${xPostDir.path}/harness.md').writeAsString('''
# 验证条件

## publish SOP 完成后
- 撰写框必须变空
- 页面出现"发送成功"提示，或新帖子出现在时间线顶部
- 必须能返回新帖子的 URL（形如 `https://x.com/{user}/status/{id}`）
- 如果任一条件不满足 → 判定失败

## publish_thread SOP 完成后
- 首条帖子有回复按钮显示 N-1 条回复（N = segments.length）
- 每段内容按顺序对应时间线中的 N 条连续帖子

## 失败处理优先级
1. **登录失效** → 不修正 SOP，直接告诉用户重新登录
2. **选择器失效** → 更新 publish.md / publish_thread.md 的选择器参考表
3. **流程变更** (X 改版增加步骤) → 更新整个 SOP
4. **网络超时** → 重试 1 次，不修改 SOP

## 性能基线
- publish: 期望 ≤ 8 秒
- publish_thread (3 段): 期望 ≤ 15 秒
- 超时 50% 以上 → 检查是否有多余的 wait/screenshot 步骤可优化
''');

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
