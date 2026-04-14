import 'dart:convert';
import 'base_tool.dart';

/// 📍 GPS 定位
class GpsTool extends BaseTool {
  @override
  String get name => 'gps';

  @override
  String get description => '获取当前 GPS 位置，或根据坐标反查地址';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['current_location', 'reverse_geocode'],
            'description': 'current_location: 获取当前位置, reverse_geocode: 坐标转地址',
          },
          'latitude': {'type': 'number', 'description': '纬度（reverse_geocode 时必填）'},
          'longitude': {'type': 'number', 'description': '经度（reverse_geocode 时必填）'},
        },
        'required': ['action'],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;
    // TODO: integrate geolocator + geocoding plugins
    switch (action) {
      case 'current_location':
        return jsonEncode({
          'latitude': 31.2304,
          'longitude': 121.4737,
          'accuracy_m': 10.0,
          'message': '当前位置（stub: 上海）',
        });
      case 'reverse_geocode':
        final lat = args['latitude'];
        final lng = args['longitude'];
        return jsonEncode({
          'address': '上海市黄浦区（stub）',
          'latitude': lat,
          'longitude': lng,
        });
      default:
        return jsonEncode({'status': 'error', 'message': '未知 action: $action'});
    }
  }
}
