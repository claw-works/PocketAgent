import '../tools/base_tool.dart';
import '../tools/device_info_tool.dart';
import '../tools/clipboard_tool.dart';

class ToolRegistry {
  final Map<String, BaseTool> _tools = {};

  ToolRegistry() {
    register(DeviceInfoTool());
    register(ClipboardTool());
  }

  void register(BaseTool tool) => _tools[tool.name] = tool;

  List<Map<String, dynamic>> toOpenAI() =>
      _tools.values.map((t) => t.toOpenAI()).toList();

  Future<String> call(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) return '错误: 未知工具 "$name"';
    try {
      return await tool.execute(args);
    } catch (e) {
      return '工具执行失败: $e';
    }
  }
}
