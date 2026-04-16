import 'dart:convert';
import 'dart:io' show Platform;
import 'base_tool.dart';

/// 📅 日历 / 提醒事项读写
class CalendarTool extends BaseTool {
  @override
  String get name => 'calendar';

  @override
  String get description => '读取日历事件、创建新事件、或删除事件';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['list_events', 'create_event', 'delete_event'],
            'description': 'list_events: 查看日程, create_event: 创建事件, delete_event: 删除事件',
          },
          'date': {'type': 'string', 'description': '日期，格式 YYYY-MM-DD（list_events 时使用）'},
          'title': {'type': 'string', 'description': '事件标题（create_event 时必填）'},
          'start_time': {'type': 'string', 'description': '开始时间 HH:MM（create_event 时必填）'},
          'end_time': {'type': 'string', 'description': '结束时间 HH:MM（create_event 时必填）'},
          'event_id': {'type': 'string', 'description': '事件 ID（delete_event 时必填）'},
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return jsonEncode({'status': 'unavailable', 'message': '此功能在当前平台不可用（需要移动设备）'});
    }
    final action = args['action'] as String;
    // TODO: integrate device_calendar plugin
    switch (action) {
      case 'list_events':
        final date = args['date'] ?? 'today';
        return jsonEncode({
          'date': date,
          'events': [
            {'id': '1', 'title': '团队周会（stub）', 'time': '10:00-11:00'},
            {'id': '2', 'title': '午饭（stub）', 'time': '12:00-13:00'},
          ],
        });
      case 'create_event':
        return jsonEncode({
          'status': 'ok',
          'event_id': 'new_${DateTime.now().millisecondsSinceEpoch}',
          'title': args['title'],
          'message': '事件已创建（stub）',
        });
      case 'delete_event':
        return jsonEncode({'status': 'ok', 'message': '事件 ${args['event_id']} 已删除（stub）'});
      default:
        return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
    }
  }
}
