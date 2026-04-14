import 'base_tool.dart';

class DeviceInfoTool extends BaseTool {
  @override
  String get name => 'get_device_info';

  @override
  String get description => '获取当前设备的基本信息（平台、型号等）';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {},
        'required': [],
      };

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    // TODO: use device_info_plus for real data
    return '{"platform": "Android", "model": "Pixel 8", "os_version": "15"}';
  }
}
