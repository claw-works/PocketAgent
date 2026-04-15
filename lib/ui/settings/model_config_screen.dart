import 'package:flutter/material.dart';
import '../widgets/setting_item.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';

class ModelConfigScreen extends StatelessWidget {
  const ModelConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(title: '模型配置', children: [
      _section('提供商配置'),
      _provider('Amazon Bedrock', [
        const SettingItem(icon: Icons.language, label: 'Host', value: 'bedrock.us-east-1.amazonaws.com'),
        const SettingItem(icon: Icons.vpn_key, label: 'Access Key', value: 'AKIA••••••••'),
        const SettingItem(icon: Icons.map_outlined, label: 'Region', value: 'us-east-1'),
      ]),
      _provider('OpenAI', [
        const SettingItem(icon: Icons.language, label: 'Host', value: 'api.openai.com'),
        const SettingItem(icon: Icons.vpn_key, label: 'API Key', value: 'sk-••••••••••••'),
      ]),
      _provider('Anthropic', [
        const SettingItem(icon: Icons.language, label: 'Host', value: 'api.anthropic.com'),
        const SettingItem(icon: Icons.vpn_key, label: 'API Key', value: 'sk-ant-••••••••'),
      ]),
      _provider('Google Gemini', [
        const SettingItem(icon: Icons.language, label: 'Host', value: 'generativelanguage.googleapis.com'),
        const SettingItem(icon: Icons.vpn_key, label: 'API Key', value: 'AIza••••••••••••'),
      ]),
      const SizedBox(height: 24),
      _section('模型选择'),
      const SizedBox(height: 12),
      const SettingItem(icon: Icons.chat_bubble_outline, label: '大语言模型', value: 'bedrock/claude-sonnet-4'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.mic, label: '语音模型', value: 'openai/tts-1'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.hearing, label: '语音理解模型', value: 'openai/whisper-1'),
      const SizedBox(height: 8),
      const SettingItem(icon: Icons.videocam_outlined, label: '视频生成模型', value: 'bedrock/nova-reel'),
    ]);
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
  );

  Widget _provider(String name, List<Widget> items) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: PAColors.textPrimary)),
      const SizedBox(height: 8),
      ...items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w)),
    ]),
  );
}
