import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/setting_item.dart';
import 'model_config_screen.dart';
import 'tools_config_screen.dart';
import 'skill_config_screen.dart';
import 'general_screen.dart';
import 'agent_profile_screen.dart';

class SettingsMainScreen extends StatelessWidget {
  const SettingsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                SettingItem(
                  icon: Icons.settings,
                  label: '通用',
                  value: '语言、主题、通知',
                  onTap: () => _push(context, const GeneralScreen()),
                ),
                const SizedBox(height: 12),
                SettingItem(
                  icon: Icons.smart_toy_outlined,
                  label: 'Agent 形象',
                  value: '名字、形象、声音',
                  onTap: () => _push(context, const AgentProfileScreen()),
                ),
                const SizedBox(height: 12),
                SettingItem(
                  icon: Icons.memory,
                  label: '模型配置',
                  value: 'LLM 提供商、模型选择',
                  onTap: () => _push(context, const ModelConfigScreen()),
                ),
                const SizedBox(height: 12),
                SettingItem(
                  icon: Icons.build_outlined,
                  label: '本机工具',
                  value: '相机、GPS、剪贴板',
                  onTap: () => _push(context, const ToolsConfigScreen()),
                ),
                const SizedBox(height: 12),
                SettingItem(
                  icon: Icons.extension_outlined,
                  label: 'Skill 配置',
                  value: '技能商店、自定义技能',
                  onTap: () => _push(context, const SkillConfigScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('设置',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: PAColors.textPrimary)),
      ),
    );
  }

  void _push(BuildContext ctx, Widget page) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
  }
}
