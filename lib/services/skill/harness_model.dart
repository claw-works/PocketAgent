import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// A harness execution record.
class HarnessRecord {
  final DateTime time;
  final String sop;
  final bool success;
  final int tokens;
  final String? reason;
  final String? fix;
  final bool autoEvolved;

  HarnessRecord({
    required this.time,
    required this.sop,
    required this.success,
    this.tokens = 0,
    this.reason,
    this.fix,
    this.autoEvolved = false,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'sop': sop,
        'success': success,
        'tokens': tokens,
        if (reason != null) 'reason': reason,
        if (fix != null) 'fix': fix,
        if (autoEvolved) 'auto_evolved': true,
      };

  factory HarnessRecord.fromJson(Map<String, dynamic> j) => HarnessRecord(
        time: DateTime.parse(j['time']),
        sop: j['sop'] ?? '',
        success: j['success'] ?? true,
        tokens: j['tokens'] ?? 0,
        reason: j['reason'],
        fix: j['fix'],
        autoEvolved: j['auto_evolved'] ?? false,
      );
}

/// A harness-enabled skill — self-evolving assistant.
class HarnessSkill {
  final String name;
  final String dirPath;
  String skillPrompt;
  Map<String, String> sops;
  String? harnessPrompt;
  List<HarnessRecord> history;

  HarnessSkill({
    required this.name,
    required this.dirPath,
    required this.skillPrompt,
    this.sops = const {},
    this.harnessPrompt,
    this.history = const [],
  });

  String get displayName {
    final match = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(skillPrompt);
    return match?.group(1) ?? name;
  }

  String get description {
    final lines = skillPrompt.split('\n').where((l) => l.trim().isNotEmpty && !l.startsWith('#')).toList();
    return lines.isNotEmpty ? lines.first.trim() : '';
  }

  int get totalRuns => history.length;
  int get successCount => history.where((r) => r.success).length;
  double get successRate => totalRuns == 0 ? 0 : successCount / totalRuns;
  int get evolutionCount => history.where((r) => r.autoEvolved).length;

  /// Full prompt including harness verification instructions.
  String get fullPrompt {
    final buf = StringBuffer(skillPrompt);
    for (final entry in sops.entries) {
      buf.writeln('\n\n---\n');
      buf.writeln('## SOP: ${entry.key}\n');
      buf.writeln(entry.value);
    }
    if (harnessPrompt != null) {
      buf.writeln('\n\n---\n');
      buf.writeln('## 验证条件 (Harness)');
      buf.writeln(harnessPrompt);

      // 注入最近失败历史（最多 3 条），让 AI 知道常见坑
      final recentFailures = history.reversed
          .where((r) => !r.success)
          .take(3)
          .toList();
      if (recentFailures.isNotEmpty) {
        buf.writeln('\n## 最近失败经验');
        for (final f in recentFailures) {
          buf.writeln('- [${f.sop}] ${f.reason ?? "未知原因"}'
              '${f.fix != null ? "（已修正: ${f.fix}）" : ""}');
        }
      }

      // 注入平均效率基线
      final successful = history.where((r) => r.success).toList();
      if (successful.length >= 3) {
        final avgTokens =
            successful.map((r) => r.tokens).reduce((a, b) => a + b) ~/
                successful.length;
        buf.writeln('\n## 效率基线');
        buf.writeln('历史成功执行平均消耗 $avgTokens tokens，尽量达到或优于此基线。');
      }

      buf.writeln('\n## 自我进化铁律');
      buf.writeln('1. **执行前**：阅读对应的 SOP，严格按步骤执行，不要跳过');
      buf.writeln('2. **执行中**：每一步操作后用 browser(screenshot) 确认页面状态（CDP 静默截图，不打扰用户）');
      buf.writeln('3. **执行后**：严格按"验证条件"核对结果');
      buf.writeln('4. **失败时**：');
      buf.writeln('   a. 先分析失败原因（选择器失效？页面结构变化？流程变更？权限问题？）');
      buf.writeln('   b. 如果是 SOP 问题，用 `skill(update, skill_name, filename, content)` 修正 SOP');
      buf.writeln('   c. 重新执行，最多重试 2 次');
      buf.writeln('   d. 每次修正都要在回复中明确说明"改了什么、为什么改"');
      buf.writeln('5. **成功时**：简要总结执行路径，并用 `skill(record_result)` 记录');
      buf.writeln('6. **必须记录结果**：每次执行（无论成功或失败）结束前，必须调用：');
      buf.writeln('   `skill(record_result, skill_name={当前skill}, sop_name={用的SOP名}, success={bool}, reason?={失败原因}, fix_description?={若修改过SOP的描述})`');
      buf.writeln('   - 成功：只需 success=true');
      buf.writeln('   - 失败未修正：success=false + reason');
      buf.writeln('   - 失败已修正：success=true + fix_description（这会被统计为一次"进化"）');
      buf.writeln('7. **禁止**：不要跳过 SOP 自己瞎试；不要隐瞒失败；不要伪造截图验证；不要忘记 record_result');
    }
    return buf.toString();
  }

  /// Save a new execution record.
  Future<void> addRecord(HarnessRecord record) async {
    history = [...history, record];
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    final file = File('$dirPath/history.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(history.map((r) => r.toJson()).toList()),
    );
  }

  /// Load from directory.
  static Future<HarnessSkill?> loadFromDir(Directory dir) async {
    final skillFile = File('${dir.path}/skill.md');
    if (!await skillFile.exists()) return null;

    try {
      final name = dir.path.split('/').last;
      final skillPrompt = await skillFile.readAsString();
      final sops = <String, String>{};
      String? harnessPrompt;
      var history = <HarnessRecord>[];

      await for (final file in dir.list()) {
        if (file is! File) continue;
        final fileName = file.path.split('/').last;

        if (fileName == 'harness.md') {
          harnessPrompt = await file.readAsString();
        } else if (fileName == 'history.json') {
          try {
            final data = jsonDecode(await file.readAsString()) as List;
            history = data.map((e) => HarnessRecord.fromJson(Map<String, dynamic>.from(e))).toList();
          } catch (_) {}
        } else if (fileName.endsWith('.md') && fileName != 'skill.md') {
          sops[fileName.replaceAll('.md', '')] = await file.readAsString();
        }
      }

      return HarnessSkill(
        name: name,
        dirPath: dir.path,
        skillPrompt: skillPrompt,
        sops: sops,
        harnessPrompt: harnessPrompt,
        history: history,
      );
    } catch (e) {
      debugPrint('[Harness] Failed to load ${dir.path}: $e');
      return null;
    }
  }
}
