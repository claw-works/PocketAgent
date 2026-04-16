import 'dart:convert';
import 'dart:io' show Platform;
import 'base_tool.dart';

/// 🔔 本地通知
class NotificationTool extends BaseTool {
  @override
  String get name => 'notification';

  @override
  String get description => '发送本地通知或定时提醒';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': '通知标题'},
          'body': {'type': 'string', 'description': '通知内容'},
          'delay_seconds': {
            'type': 'integer',
            'description': '延迟秒数，0 表示立即发送',
          },
        },
        'required': ['title', 'body'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return jsonEncode({'status': 'unavailable', 'message': '此功能在当前平台不可用（需要移动设备）'});
    }
    // TODO: integrate flutter_local_notifications
    final delay = args['delay_seconds'] ?? 0;
    return jsonEncode({
      'status': 'ok',
      'title': args['title'],
      'delay_seconds': delay,
      'message': delay > 0 ? '将在 ${delay}s 后提醒（stub）' : '通知已发送（stub）',
    });
  }
}
