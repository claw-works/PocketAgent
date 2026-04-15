import 'dart:convert';
import 'base_tool.dart';
import '../services/skill/skill_registry.dart';

/// 🎯 Skill tool — list, run, and install automation skills.
class SkillTool extends BaseTool {
  @override
  String get name => 'skill';

  @override
  String get description {
    final skills = SkillRegistry.instance.all;
    final list = skills.map((s) => '${s.name}: ${s.description}').join('; ');
    return '执行预定义的自动化技能。可用技能: $list。也可以从 URL 或 GitHub 安装新技能。';
  }

  @override
  Map<String, dynamic> get parameters {
    final skills = SkillRegistry.instance.all;
    return {
      'type': 'object',
      'properties': {
        'action': {
          'type': 'string',
          'enum': ['list', 'run', 'install_url', 'install_github', 'remove'],
          'description': 'list: 列出技能, run: 执行技能, install_url: 从 URL 安装, install_github: 从 GitHub 安装, remove: 删除技能',
        },
        'skill_name': {
          'type': 'string',
          'description': '技能名称（run/remove 时必填）',
        },
        'params': {
          'type': 'object',
          'description': '传递给技能的参数',
        },
        'url': {
          'type': 'string',
          'description': '技能 JSON 文件的 URL（install_url 时必填）',
        },
        'repo': {
          'type': 'string',
          'description': 'GitHub 路径 owner/repo/path（install_github 时必填）',
        },
      },
      'required': ['action'],
    };
  }

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;

    try {
      switch (action) {
        case 'list':
          final skills = SkillRegistry.instance.all.map((s) => {
                'name': s.name,
                'description': s.description,
                'params': s.params.map((p) => {'name': p.name, 'required': p.required}).toList(),
              }).toList();
          return jsonEncode({'status': 'ok', 'skills': skills, 'dir': await SkillRegistry.skillsDir});

        case 'run':
          final name = args['skill_name'] as String? ?? '';
          final params = args['params'] as Map<String, dynamic>? ?? {};
          return await SkillRegistry.instance.run(name, params);

        case 'install_url':
          final url = args['url'] as String? ?? '';
          await SkillRegistry.instance.installFromUrl(url);
          return jsonEncode({'status': 'ok', 'message': '技能已安装'});

        case 'install_github':
          final repo = args['repo'] as String? ?? '';
          await SkillRegistry.instance.installFromGithub(repo);
          return jsonEncode({'status': 'ok', 'message': '技能已从 GitHub 安装'});

        case 'remove':
          final name = args['skill_name'] as String? ?? '';
          await SkillRegistry.instance.remove(name);
          return jsonEncode({'status': 'ok', 'message': '技能 $name 已删除'});

        default:
          return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
      }
    } catch (e) {
      return jsonEncode({'status': 'error', 'message': '$e'});
    }
  }
}
