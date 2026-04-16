import 'dart:convert';
import 'base_tool.dart';
import '../services/platform/accessibility_bridge.dart';

/// 📱 Screen control tool — read UI, click, type, swipe, navigate.
/// This is the core tool that lets the AI operate other apps.
class ScreenControlTool extends BaseTool {
  @override
  String get name => 'screen_control';

  @override
  String get description =>
  @override
  bool get requiresConfirmation => true;
      '（Android）读取当前屏幕上的 UI 元素，并执行点击、输入、滑动等操作来操控其他 App。'
      '使用前先 read_screen 了解界面结构，再执行操作。';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': [
              'check_enabled',
              'open_settings',
              'read_screen',
              'click_text',
              'click_index',
              'tap',
              'input_text',
              'swipe',
              'back',
              'home',
              'recents',
              'notifications',
            ],
            'description':
                'check_enabled: 检查无障碍服务是否开启; '
                'open_settings: 打开无障碍设置页; '
                'read_screen: 读取屏幕上所有 UI 元素; '
                'click_text: 点击包含指定文本的元素; '
                'click_index: 点击指定 index 的元素; '
                'tap: 点击屏幕坐标; '
                'input_text: 在当前焦点输入框中输入文字; '
                'swipe: 滑动手势; '
                'back/home/recents/notifications: 全局导航',
          },
          'text': {
            'type': 'string',
            'description': '文本参数（click_text 的目标文本，或 input_text 的输入内容）',
          },
          'index': {
            'type': 'integer',
            'description': 'read_screen 返回的元素 index（click_index 时使用）',
          },
          'x': {'type': 'number', 'description': 'x 坐标（tap/swipe 起点）'},
          'y': {'type': 'number', 'description': 'y 坐标（tap/swipe 起点）'},
          'x2': {'type': 'number', 'description': 'swipe 终点 x'},
          'y2': {'type': 'number', 'description': 'swipe 终点 y'},
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;

    switch (action) {
      case 'check_enabled':
        final enabled = await AccessibilityBridge.isEnabled();
        return jsonEncode({
          'enabled': enabled,
          'message': enabled ? '无障碍服务已开启' : '无障碍服务未开启，请先调用 open_settings 引导用户开启',
        });

      case 'open_settings':
        await AccessibilityBridge.openSettings();
        return jsonEncode({'status': 'ok', 'message': '已打开无障碍设置页，请引导用户开启 PocketAgent 服务'});

      case 'read_screen':
        final elements = await AccessibilityBridge.readScreen();
        // Compact: only include non-null fields to save tokens
        final compact = elements.map((e) {
          final m = <String, dynamic>{'i': e['index']};
          if (e['text'] != null) m['text'] = e['text'];
          if (e['description'] != null) m['desc'] = e['description'];
          if (e['id'] != null) m['id'] = e['id'];
          if (e['clickable'] == true) m['click'] = true;
          if (e['editable'] == true) m['edit'] = true;
          if (e['scrollable'] == true) m['scroll'] = true;
          m['bounds'] = e['bounds'];
          return m;
        }).toList();
        return jsonEncode({'count': compact.length, 'elements': compact});

      case 'click_text':
        final text = args['text'] as String? ?? '';
        final ok = await AccessibilityBridge.clickByText(text);
        return jsonEncode({'status': ok ? 'ok' : 'not_found', 'text': text});

      case 'click_index':
        final index = args['index'] as int? ?? 0;
        final ok = await AccessibilityBridge.clickByIndex(index);
        return jsonEncode({'status': ok ? 'ok' : 'failed', 'index': index});

      case 'tap':
        final x = (args['x'] as num?)?.toDouble() ?? 0;
        final y = (args['y'] as num?)?.toDouble() ?? 0;
        final ok = await AccessibilityBridge.tap(x, y);
        return jsonEncode({'status': ok ? 'ok' : 'failed'});

      case 'input_text':
        final text = args['text'] as String? ?? '';
        final ok = await AccessibilityBridge.inputText(text);
        return jsonEncode({'status': ok ? 'ok' : 'no_focus', 'message': ok ? '已输入' : '没有找到焦点输入框'});

      case 'swipe':
        final x1 = (args['x'] as num?)?.toDouble() ?? 0;
        final y1 = (args['y'] as num?)?.toDouble() ?? 0;
        final x2 = (args['x2'] as num?)?.toDouble() ?? 0;
        final y2 = (args['y2'] as num?)?.toDouble() ?? 0;
        final ok = await AccessibilityBridge.swipe(x1, y1, x2, y2);
        return jsonEncode({'status': ok ? 'ok' : 'failed'});

      case 'back':
        return jsonEncode({'status': (await AccessibilityBridge.globalAction('back')) ? 'ok' : 'failed'});
      case 'home':
        return jsonEncode({'status': (await AccessibilityBridge.globalAction('home')) ? 'ok' : 'failed'});
      case 'recents':
        return jsonEncode({'status': (await AccessibilityBridge.globalAction('recents')) ? 'ok' : 'failed'});
      case 'notifications':
        return jsonEncode({'status': (await AccessibilityBridge.globalAction('notifications')) ? 'ok' : 'failed'});

      default:
        return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
    }
  }
}
