import 'dart:convert';
import 'base_tool.dart';
import '../services/skill/skill_registry.dart';
import '../services/skill/skill_model.dart';

/// 🎯 Skill tool — LLM can list and run predefined browser automation skills.
class SkillTool extends BaseTool {
  @override
  String get name => 'skill';

  @override
  String get description {
    final skills = SkillRegistry.instance.all;
    final list = skills.map((s) => '${s.name}: ${s.description}').join('; ');
    return '执行预定义的自动化技能（SOP）。可用技能: $list';
  }

  @override
  Map<String, dynamic> get parameters {
    final skills = SkillRegistry.instance.all;
    return {
      'type': 'object',
      'properties': {
        'action': {
          'type': 'string',
          'enum': ['list', 'run'],
          'description': 'list: 列出所有可用技能, run: 执行指定技能',
        },
        'skill_name': {
          'type': 'string',
          'enum': skills.map((s) => s.name).toList(),
          'description': '要执行的技能名称',
        },
        'params': {
          'type': 'object',
          'description': '传递给技能的参数（key-value）',
        },
      },
      'required': ['action'],
    };
  }

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;

    switch (action) {
      case 'list':
        final skills = SkillRegistry.instance.all.map((s) => {
              'name': s.name,
              'description': s.description,
              'params': s.params.map((p) => {'name': p.name, 'description': p.description, 'required': p.required}).toList(),
            }).toList();
        return jsonEncode({'status': 'ok', 'skills': skills});

      case 'run':
        final skillName = args['skill_name'] as String? ?? '';
        final params = args['params'] as Map<String, dynamic>? ?? {};
        return await SkillRegistry.instance.run(skillName, params);

      default:
        return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
    }
  }
}
