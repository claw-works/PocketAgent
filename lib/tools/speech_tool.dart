import 'dart:convert';
import 'dart:io' show Platform;
import 'base_tool.dart';

/// 🎙️ 语音识别 / TTS 朗读
class SpeechTool extends BaseTool {
  @override
  String get name => 'speech';

  @override
  String get description => '语音识别（听）或文字转语音朗读（说）';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['listen', 'speak'],
            'description': 'listen: 语音识别, speak: TTS 朗读',
          },
          'text': {'type': 'string', 'description': '要朗读的文本（speak 时必填）'},
          'language': {
            'type': 'string',
            'description': '语言代码，默认 zh-CN',
          },
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return jsonEncode({'status': 'unavailable', 'message': '此功能在当前平台不可用（需要移动设备）'});
    }
    final action = args['action'] as String;
    // TODO: integrate speech_to_text + flutter_tts
    switch (action) {
      case 'listen':
        return jsonEncode({'status': 'ok', 'transcript': '你好世界（stub）'});
      case 'speak':
        return jsonEncode({'status': 'ok', 'message': '正在朗读（stub）: ${args['text']}'});
      default:
        return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
    }
  }
}
