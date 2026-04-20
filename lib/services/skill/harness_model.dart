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
      buf.writeln(entry.value);
    }
    if (harnessPrompt != null) {
      buf.writeln('\n\n---\n');
      buf.writeln(harnessPrompt);
      buf.writeln('\n## 自我进化指令');
      buf.writeln('执行 SOP 后，你必须按照上述验证条件检查结果。');
      buf.writeln('如果验证失败：');
      buf.writeln('1. 用 screenshot 截图分析当前页面状态');
      buf.writeln('2. 找出失败原因（选择器变了？页面结构变了？流程变了？）');
      buf.writeln('3. 用 skill(update) 工具修正对应的 SOP 文件');
      buf.writeln('4. 重新执行修正后的步骤');
      buf.writeln('5. 修正后告诉用户你做了什么改动');
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
