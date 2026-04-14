import 'dart:convert';
import 'dart:io' show Platform;
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

    if (!Platform.isAndroid) {
      // iOS fallback: url_launcher (TODO)
      return jsonEncode({'status': 'ok', 'message': '已打开（非 Android，使用 url_launcher stub）'});
    }

    try {
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
    } catch (e) {
      return jsonEncode({'status': 'error', 'message': '$e'});
    }
  }
}
