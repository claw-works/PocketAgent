import 'package:flutter/material.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';
import '../../services/tool_registry.dart';

class ToolsConfigScreen extends StatefulWidget {
  const ToolsConfigScreen({super.key});

  @override
  State<ToolsConfigScreen> createState() => _ToolsConfigScreenState();
}

class _ToolsConfigScreenState extends State<ToolsConfigScreen> {
  late final ToolRegistry _registry;

  static const _toolIcons = <String, IconData>{
    'get_device_info': Icons.phone_android,
    'clipboard': Icons.content_paste,
    'camera': Icons.camera_alt_outlined,
    'gps': Icons.location_on_outlined,
    'calendar': Icons.calendar_today_outlined,
    'notification': Icons.notifications_outlined,
    'app_launcher': Icons.language,
    'speech': Icons.mic,
    'termux_shell': Icons.terminal,
    'ios_shortcuts': Icons.flash_on,
    'screen_control': Icons.touch_app_outlined,
    'macos_shell': Icons.desktop_mac_outlined,
    'browser': Icons.public_outlined,
  };

  static const _toolLabels = <String, String>{
    'get_device_info': '设备信息',
    'clipboard': '剪贴板',
    'camera': '相机',
    'gps': 'GPS 定位',
    'calendar': '日历 / 提醒事项',
    'notification': '本地通知',
    'app_launcher': '打开网页 / 唤起 App',
    'speech': '语音识别 / TTS',
    'termux_shell': 'Termux 互操作',
    'ios_shortcuts': 'iOS 快捷指令',
    'screen_control': '屏幕操控',
    'macos_shell': 'macOS Shell / 打开应用',
    'browser': '浏览器操控 (CDP)',
  };

  @override
  void initState() {
    super.initState();
    _registry = ToolRegistry();
  }

  @override
  Widget build(BuildContext context) {
    final tools = _registry.allTools;
    return SettingsDetailScaffold(
      title: '本机工具',
      children: tools.map((tool) {
        final enabled = _registry.isEnabled(tool.name);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PAColors.bgSecondary,
              borderRadius: BorderRadius.circular(PARadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: enabled ? PAColors.gradientAccent : null,
                    color: enabled ? null : PAColors.bgTertiary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _toolIcons[tool.name] ?? Icons.build_outlined,
                    size: 18,
                    color: enabled ? Colors.white : PAColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _toolLabels[tool.name] ?? tool.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: enabled ? PAColors.textPrimary : PAColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tool.description.split('。').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: PAColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeColor: PAColors.accent,
                  onChanged: (v) {
                    setState(() => _registry.setEnabled(tool.name, v));
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
