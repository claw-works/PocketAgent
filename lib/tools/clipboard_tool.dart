import 'package:flutter/services.dart';
import 'base_tool.dart';

class ClipboardTool extends BaseTool {
  @override
  String get name => 'clipboard';

  @override
  String get description => '读取或写入系统剪贴板';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['read', 'write'],
            'description': 'read: 读取剪贴板内容, write: 写入内容到剪贴板',
          },
          'text': {
            'type': 'string',
            'description': '要写入剪贴板的文本（action=write 时必填）',
          },
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;
    if (action == 'read') {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text ?? '(剪贴板为空)';
    } else {
      final text = args['text'] as String? ?? '';
      await Clipboard.setData(ClipboardData(text: text));
      return '已写入剪贴板: $text';
    }
  }
}
