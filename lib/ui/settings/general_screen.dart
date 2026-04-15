import 'package:flutter/material.dart';
import '../widgets/setting_item.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';

class GeneralScreen extends StatelessWidget {
  const GeneralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(title: '通用', children: [
      _section('语言'),
      const SettingItem(icon: Icons.language, label: '界面语言', value: '简体中文'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.translate, label: '对话语言', value: '自动检测'),
      const SizedBox(height: 24),
      _section('主题'),
      const SettingItem(icon: Icons.palette_outlined, label: '外观模式', value: '深色'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.brush_outlined, label: '主题色', value: '紫色'),
      const SizedBox(height: 24),
      _section('通知'),
      const SettingItem(icon: Icons.notifications_outlined, label: '推送通知', value: '已开启', showChevron: false),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.volume_up_outlined, label: '提示音', value: '默认', showChevron: false),
    ]);
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
  );
}
