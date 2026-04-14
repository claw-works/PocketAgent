import 'dart:convert';
import 'base_tool.dart';

/// ⚡ iOS: Shortcuts（快捷指令）触发
class ShortcutsTool extends BaseTool {
  @override
  String get name => 'ios_shortcuts';

  @override
  String get description => '（iOS）触发 Apple Shortcuts 快捷指令';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'shortcut_name': {
            'type': 'string',
            'description': '快捷指令名称',
          },
          'input': {
            'type': 'string',
            'description': '传递给快捷指令的输入文本（可选）',
          },
        },
        'required': ['shortcut_name'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final name = args['shortcut_name'] as String;
    // TODO: use url_launcher with shortcuts:// scheme
    return jsonEncode({
      'status': 'ok',
      'shortcut': name,
      'message': '已触发快捷指令（stub）',
    });
  }
}
