import 'dart:convert';
import 'dart:io' show Platform;
import 'base_tool.dart';

bool get _isRealPlatform => Platform.isAndroid || Platform.isIOS;

/// 📷 拍照 / 读取照片库 / 图像分析
class CameraTool extends BaseTool {
  @override
  String get name => 'camera';

  @override
  String get description => '拍照、从相册选取照片、或分析图片内容';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['capture', 'pick_gallery', 'analyze'],
            'description': 'capture: 拍照, pick_gallery: 从相册选取, analyze: 分析最近一张照片',
          },
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;
    // TODO: integrate image_picker + camera plugin
    if (!_isRealPlatform) {
      return jsonEncode({'status': 'unavailable', 'message': '相机功能在当前平台不可用（需要真机）'});
    }
    switch (action) {
      case 'capture':
        return jsonEncode({'status': 'ok', 'path': '/tmp/photo_stub.jpg', 'message': '已拍照（stub）'});
      case 'pick_gallery':
        return jsonEncode({'status': 'ok', 'path': '/tmp/gallery_stub.jpg', 'message': '已选取照片（stub）'});
      case 'analyze':
        return jsonEncode({'status': 'ok', 'description': '图片分析功能待接入 vision model'});
      default:
        return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
    }
  }
}
