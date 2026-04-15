import 'dart:convert';
import 'dart:io';
import 'base_tool.dart';
import '../services/platform/android_intent_bridge.dart';

/// 🌐 打开网页 / 唤起其他 App / 分享文本
class AppLauncherTool extends BaseTool {
  @override
  String get name => 'app_launcher';

  @override
  String get description => '打开网页 URL、通过 scheme 唤起其他 App、或分享文本到其他应用';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['open_url', 'share_text'],
            'description': 'open_url: 打开链接或 App scheme, share_text: 分享文本',
          },
          'url': {'type': 'string', 'description': '要打开的 URL（open_url 时必填）'},
          'text': {'type': 'string', 'description': '要分享的文本（share_text 时必填）'},
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;

    try {
      if (Platform.isAndroid) {
        return await _android(action, args);
      }
      if (Platform.isMacOS) {
        return await _macos(action, args);
      }
      if (Platform.isWindows) {
        return await _windows(action, args);
      }
      // iOS / others: stub
      return jsonEncode({'status': 'ok', 'message': '已打开（stub）'});
    } catch (e) {
      return jsonEncode({'status': 'error', 'message': '$e'});
    }
  }

  Future<String> _android(String action, Map<String, dynamic> args) async {
    if (action == 'share_text') {
      await AndroidIntentBridge.shareText(args['text'] as String? ?? '');
      return jsonEncode({'status': 'ok', 'message': '已打开分享面板'});
    }
    final url = args['url'] as String? ?? '';
    final result = await AndroidIntentBridge.launch(
      action: 'android.intent.action.VIEW',
      uri: url,
    );
    return jsonEncode({'status': 'ok', ...result});
  }

  Future<String> _macos(String action, Map<String, dynamic> args) async {
    if (action == 'open_url') {
      final url = args['url'] as String? ?? '';
      final result = await Process.run('open', [url]);
      return jsonEncode({
        'status': result.exitCode == 0 ? 'ok' : 'error',
        'message': result.exitCode == 0 ? '已打开 $url' : (result.stderr as String).trim(),
      });
    }
    // macOS share: use AppleScript or just copy
    return jsonEncode({'status': 'ok', 'message': 'macOS 暂不支持分享'});
  }

  Future<String> _windows(String action, Map<String, dynamic> args) async {
    if (action == 'open_url') {
      final url = args['url'] as String? ?? '';
      final result = await Process.run('cmd', ['/c', 'start', '', url]);
      return jsonEncode({
        'status': result.exitCode == 0 ? 'ok' : 'error',
        'message': result.exitCode == 0 ? '已打开 $url' : (result.stderr as String).trim(),
      });
    }
    return jsonEncode({'status': 'ok', 'message': 'Windows 暂不支持分享'});
  }
}
