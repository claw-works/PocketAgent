import 'dart:io' show Platform;
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
import '../tools/screen_control_tool.dart';
import '../tools/macos_tool.dart';
import '../tools/browser_tool.dart';
import '../tools/skill_tool.dart';
import 'activity_log.dart';

class ToolRegistry {
  final Map<String, BaseTool> _tools = {};
  final Set<String> _disabled = {};

  ToolRegistry() {
    // 通用
    register(DeviceInfoTool());
    register(ClipboardTool());
    register(CameraTool());
    register(GpsTool());
    register(CalendarTool());
    register(NotificationTool());
    register(AppLauncherTool());
    register(SpeechTool());
    register(TermuxTool());
    register(ShortcutsTool());
    register(ScreenControlTool());
    // 平台专属
    if (Platform.isMacOS) register(MacOsTool());
    if (Platform.isMacOS || Platform.isLinux) register(BrowserTool());
    register(SkillTool());
  }

  void register(BaseTool tool) => _tools[tool.name] = tool;
  void unregister(String name) => _tools.remove(name);

  void setEnabled(String name, bool enabled) {
    if (enabled) {
      _disabled.remove(name);
    } else {
      _disabled.add(name);
    }
  }

  bool isEnabled(String name) => !_disabled.contains(name);

  List<BaseTool> get allTools => _tools.values.toList();
  List<String> get toolNames => _tools.keys.toList();

  /// Only return enabled tools for LLM.
  List<Map<String, dynamic>> toOpenAI() => _tools.entries
      .where((e) => !_disabled.contains(e.key))
      .map((e) => e.value.toOpenAI())
      .toList();

  Future<String> call(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) return '错误: 未知工具 "$name"';
    try {
      final result = await tool.execute(args);
      // Log to activity
      ActivityLog.instance.add(ActivityEntry(
        action: tool.description.split('。').first.split('（').first,
        detail: '$name(${args.keys.join(", ")})',
        time: DateTime.now(),
        success: !result.contains('"status":"error"'),
      ));
      return result;
    } catch (e) {
      ActivityLog.instance.add(ActivityEntry(
        action: name,
        detail: '执行失败: $e',
        time: DateTime.now(),
        success: false,
      ));
      return '工具执行失败: $e';
    }
  }
}
