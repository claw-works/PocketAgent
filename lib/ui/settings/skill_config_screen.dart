import 'package:flutter/material.dart';
import '../widgets/setting_item.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';

class SkillConfigScreen extends StatefulWidget {
  const SkillConfigScreen({super.key});

  @override
  State<SkillConfigScreen> createState() => _SkillConfigScreenState();
}

class _SkillConfigScreenState extends State<SkillConfigScreen> {
  // Placeholder skill list — will be backed by a real skill registry later
  final _skills = <_Skill>[
    _Skill('天气查询', '获取实时天气和预报', Icons.wb_sunny_outlined, true),
    _Skill('翻译助手', '多语言实时翻译', Icons.translate, true),
    _Skill('笔记速记', '语音转文字自动记录', Icons.edit_note, false),
  ];

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
      ..._skills.map((s) => Padding(
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
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: s.enabled ? PAColors.gradientAccent : null,
                      color: s.enabled ? null : PAColors.bgTertiary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.icon, size: 18, color: s.enabled ? Colors.white : PAColors.textMuted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: s.enabled ? PAColors.textPrimary : PAColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(s.desc, style: const TextStyle(fontSize: 12, color: PAColors.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: s.enabled,
                    activeColor: PAColors.accent,
                    onChanged: (v) => setState(() => s.enabled = v),
                  ),
                ],
              ),
            ),
          )),
    ]);
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
      );
}

class _Skill {
  final String name;
  final String desc;
  final IconData icon;
  bool enabled;
  _Skill(this.name, this.desc, this.icon, this.enabled);
}
