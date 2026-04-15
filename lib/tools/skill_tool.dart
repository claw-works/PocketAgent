import 'dart:convert';
import 'base_tool.dart';
import '../services/skill/skill_registry.dart';

/// 🎯 Skill management — list, install, remove skills.
/// Skills are markdown-based knowledge + SOPs injected into system prompt.
/// AI executes SOPs using available tools (browser, shell, etc).
class SkillTool extends BaseTool {
  @override
  String get name => 'skill';

  @override
  String get description =>
      '管理 AI 技能。技能是 markdown 格式的知识和操作指南，安装后自动注入到 AI 的能力中。';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['list', 'install_url', 'remove'],
            'description': 'list: 列出已安装技能, install_url: 从 URL 安装, remove: 删除技能',
          },
          'url': {'type': 'string', 'description': '技能 markdown 文件的 URL（install_url 时必填）'},
          'skill_name': {'type': 'string', 'description': '技能名称（remove 时必填）'},
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
          return jsonEncode({'status': 'ok', 'skills': skills, 'dir': await SkillRegistry.skillsDir});

        case 'install_url':
          await SkillRegistry.instance.installFromUrl(args['url'] as String? ?? '');
          return jsonEncode({'status': 'ok', 'message': '技能已安装，重启对话生效'});

        case 'remove':
          await SkillRegistry.instance.remove(args['skill_name'] as String? ?? '');
          return jsonEncode({'status': 'ok', 'message': '技能已删除'});

        default:
          return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
      }
    } catch (e) {
      return jsonEncode({'status': 'error', 'message': '$e'});
    }
  }
}
