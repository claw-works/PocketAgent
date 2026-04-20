import 'dart:convert';
import 'dart:io';
import 'base_tool.dart';
import '../services/skill/skill_registry.dart';
import '../services/skill/harness_model.dart';

/// 🎯 Skill management — list, create, update, install, remove.
/// AI can autonomously create and update skills based on experience.
class SkillTool extends BaseTool {
  @override
  String get name => 'skill';

  @override
  String get description =>
      '管理 AI 技能。可以查看、创建、更新、安装、删除技能。'
      '当你发现用户反复执行类似操作，或者你学到了新的操作方法时，应该主动创建或更新 Skill。';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['list', 'create', 'update', 'read', 'install_url', 'remove', 'record_result'],
            'description':
                'list: 列出已安装技能; '
                'create: 创建新技能; '
                'update: 更新现有技能的某个文件; '
                'read: 读取技能内容; '
                'install_url: 从 URL 安装; '
                'remove: 删除技能; '
                'record_result: 记录 harness 执行结果（成功/失败/进化）',
          },
          'skill_name': {
            'type': 'string',
            'description': '技能名称（目录名，用英文下划线命名）',
          },
          'filename': {
            'type': 'string',
            'description': '文件名，如 skill.md 或 search_product.md（create/update/read 时使用）',
          },
          'content': {
            'type': 'string',
            'description': 'Markdown 文件内容（create/update 时必填）',
          },
          'url': {
            'type': 'string',
            'description': '技能文件的 URL（install_url 时必填）',
          },
          'success': {
            'type': 'boolean',
            'description': '执行是否成功（record_result 时必填）',
          },
          'sop_name': {
            'type': 'string',
            'description': '执行的 SOP 名称（record_result 时使用）',
          },
          'reason': {
            'type': 'string',
            'description': '失败原因（record_result 失败时使用）',
          },
          'fix_description': {
            'type': 'string',
            'description': '修正描述（record_result 进化时使用）',
          },
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;
    try {
      switch (action) {
        case 'list':
          final skills = SkillRegistry.instance.all.map((s) => {
                'name': s.name,
                'sops': s.sops.keys.toList(),
              }).toList();
          return jsonEncode({'status': 'ok', 'skills': skills});

        case 'read':
          final skillName = args['skill_name'] as String? ?? '';
          final filename = args['filename'] as String? ?? 'skill.md';
          final skill = SkillRegistry.instance.get(skillName);
          if (skill == null) return _err('技能 $skillName 不存在');
          if (filename == 'skill.md') {
            return jsonEncode({'status': 'ok', 'content': skill.skillPrompt});
          }
          final sopName = filename.replaceAll('.md', '');
          final content = skill.sops[sopName];
          if (content == null) return _err('文件 $filename 不存在');
          return jsonEncode({'status': 'ok', 'content': content});

        case 'create':
        case 'update':
          final skillName = args['skill_name'] as String? ?? '';
          final filename = args['filename'] as String? ?? 'skill.md';
          final content = args['content'] as String? ?? '';
          if (skillName.isEmpty || content.isEmpty) {
            return _err('skill_name 和 content 不能为空');
          }
          final dirPath = '${await SkillRegistry.skillsDir}/$skillName';
          await Directory(dirPath).create(recursive: true);
          await File('$dirPath/$filename').writeAsString(content);
          // Reload this skill
          await SkillRegistry.instance.load();
          return jsonEncode({
            'status': 'ok',
            'message': action == 'create'
                ? '技能 $skillName 已创建'
                : '技能 $skillName/$filename 已更新',
          });

        case 'install_url':
          await SkillRegistry.instance.installFromUrl(args['url'] as String? ?? '');
          return jsonEncode({'status': 'ok', 'message': '技能已安装'});

        case 'remove':
          await SkillRegistry.instance.remove(args['skill_name'] as String? ?? '');
          return jsonEncode({'status': 'ok', 'message': '技能已删除'});

        case 'record_result':
          final skillName = args['skill_name'] as String? ?? '';
          final hs = SkillRegistry.instance.getHarness(skillName);
          if (hs == null) return _err('未找到 harness 技能: $skillName');
          final record = HarnessRecord(
            time: DateTime.now(),
            sop: args['sop_name'] as String? ?? '',
            success: args['success'] as bool? ?? true,
            reason: args['reason'] as String?,
            fix: args['fix_description'] as String?,
            autoEvolved: args['fix_description'] != null,
          );
          await hs.addRecord(record);
          return jsonEncode({
            'status': 'ok',
            'message': record.autoEvolved
                ? '已记录进化：${record.fix}'
                : record.success ? '已记录成功' : '已记录失败：${record.reason}',
            'total_runs': hs.totalRuns,
            'success_rate': '${(hs.successRate * 100).toInt()}%',
          });

        default:
          return _err('未知 action: $action');
      }
    } catch (e) {
      return _err('$e');
    }
  }

  String _err(String msg) => jsonEncode({'status': 'error', 'message': msg});
}
