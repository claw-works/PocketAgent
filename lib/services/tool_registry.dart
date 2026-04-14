import '../tools/base_tool.dart';
import '../tools/device_info_tool.dart';
import '../tools/clipboard_tool.dart';
import '../tools/camera_tool.dart';
import '../tools/gps_tool.dart';
import '../tools/calendar_tool.dart';
import '../tools/notification_tool.dart';
import '../tools/app_launcher_tool.dart';
import '../tools/speech_tool.dart';
import '../tools/termux_tool.dart';
import '../tools/shortcuts_tool.dart';

class ToolRegistry {
  final Map<String, BaseTool> _tools = {};

  ToolRegistry() {
    // 通用工具
    register(DeviceInfoTool());
    register(ClipboardTool());
    register(CameraTool());
    register(GpsTool());
    register(CalendarTool());
    register(NotificationTool());
    register(AppLauncherTool());
    register(SpeechTool());
    // 平台专属（运行时按平台启用）
    register(TermuxTool());
    register(ShortcutsTool());
  }

  void register(BaseTool tool) => _tools[tool.name] = tool;

  void unregister(String name) => _tools.remove(name);

  List<String> get toolNames => _tools.keys.toList();

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
