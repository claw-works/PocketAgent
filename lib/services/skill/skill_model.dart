/// A Skill is a predefined SOP (Standard Operating Procedure) for automating
/// a sequence of browser/tool actions.
///
/// Example YAML:
/// ```yaml
/// name: google_search
/// description: 在 Google 搜索关键词
/// params:
///   - name: query
///     description: 搜索关键词
///     required: true
/// steps:
///   - action: navigate
///     url: "https://www.google.com"
///   - action: wait
///     seconds: 1
///   - action: query
///     selector: "textarea[name=q]"
///     save_as: search_box
///   - action: type_text
///     selector: "{{search_box}}"
///     text: "{{query}}"
///   - action: click
///     selector: "input[name=btnK]"
///   - action: wait
///     seconds: 2
///   - action: query_all
///     selector: "h3"
///     save_as: results
///   - action: return
///     value: "{{results}}"
/// ```
class Skill {
  final String name;
  final String description;
  final List<SkillParam> params;
  final List<SkillStep> steps;

  Skill({
    required this.name,
    required this.description,
    this.params = const [],
    required this.steps,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      name: json['name'],
      description: json['description'] ?? '',
      params: (json['params'] as List?)
              ?.map((p) => SkillParam.fromJson(p))
              .toList() ??
          [],
      steps: (json['steps'] as List)
          .map((s) => SkillStep.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'params': params.map((p) => p.toJson()).toList(),
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}

class SkillParam {
  final String name;
  final String description;
  final bool required;
  final String? defaultValue;

  SkillParam({
    required this.name,
    this.description = '',
    this.required = false,
    this.defaultValue,
  });

  factory SkillParam.fromJson(Map<String, dynamic> json) => SkillParam(
        name: json['name'],
        description: json['description'] ?? '',
        required: json['required'] ?? false,
        defaultValue: json['default'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'required': required,
        if (defaultValue != null) 'default': defaultValue,
      };
}

class SkillStep {
  final String action;
  final Map<String, dynamic> args;

  SkillStep({required this.action, this.args = const {}});

  factory SkillStep.fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String;
    final args = Map<String, dynamic>.from(json)..remove('action');
    return SkillStep(action: action, args: args);
  }

  Map<String, dynamic> toJson() => {'action': action, ...args};
}
