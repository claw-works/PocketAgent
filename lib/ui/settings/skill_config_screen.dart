import 'package:flutter/material.dart';
import '../widgets/setting_item.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';

class SkillConfigScreen extends StatelessWidget {
  const SkillConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(title: 'Skill 配置', children: [
      _section('发现技能'),
      const SettingItem(icon: Icons.storefront_outlined, label: '技能商店', value: '浏览和安装社区技能'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.upload_outlined, label: '导入技能', value: '从文件或 URL 导入'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.code, label: '编写自定义技能', value: '创建你自己的 Skill'),
      const SizedBox(height: 24),
      _section('已安装技能'),
      const SettingItem(icon: Icons.wb_sunny_outlined, label: '天气查询', value: '获取实时天气和预报', showChevron: false),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.translate, label: '翻译助手', value: '多语言实时翻译', showChevron: false),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.edit_note, label: '笔记速记', value: '语音转文字自动记录', showChevron: false),
    ]);
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
  );
}
