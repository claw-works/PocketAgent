import 'package:flutter/material.dart';
import '../widgets/setting_item.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';

class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(title: 'Agent 形象', children: [
      Center(
        child: Column(children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(color: PAColors.accentSoft, borderRadius: BorderRadius.circular(48)),
            child: const Icon(Icons.smart_toy_outlined, size: 48, color: PAColors.accent),
          ),
          const SizedBox(height: 12),
          const Text('点击更换形象', style: TextStyle(fontSize: 13, color: PAColors.textMuted)),
        ]),
      ),
      const SizedBox(height: 24),
      _section('基本信息'),
      const SettingItem(icon: Icons.person_outline, label: '名字', value: 'PocketAgent'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.auto_awesome, label: '人设 / 性格', value: '友好、专业的 AI 助手'),
      const SizedBox(height: 24),
      _section('形象与声音'),
      const SettingItem(icon: Icons.image_outlined, label: '头像风格', value: '机器人'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.graphic_eq, label: '语音音色', value: 'alloy'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.speed, label: '语速', value: '正常', showChevron: false),
    ]);
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
  );
}
