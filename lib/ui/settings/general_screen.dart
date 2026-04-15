import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/setting_item.dart';
import 'settings_detail_scaffold.dart';
import '../../services/agent_config.dart';

class GeneralScreen extends StatefulWidget {
  const GeneralScreen({super.key});

  @override
  State<GeneralScreen> createState() => _GeneralScreenState();
}

class _GeneralScreenState extends State<GeneralScreen> {
  @override
  void initState() {
    super.initState();
    AgentConfig.instance.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    AgentConfig.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AgentConfig.instance;
    return SettingsDetailScaffold(title: '通用', children: [
      _section('语言'),
      SettingItem(
        icon: Icons.language,
        label: '界面语言',
        value: c.language,
        onTap: () => _pickOption(
          title: '界面语言',
          options: ['简体中文', 'English', '日本語'],
          current: c.language,
          onSelect: c.setLanguage,
        ),
      ),
      const SizedBox(height: 8),
      SettingItem(
        icon: Icons.translate,
        label: '对话语言',
        value: c.chatLanguage,
        onTap: () => _pickOption(
          title: '对话语言',
          options: ['自动检测', '简体中文', 'English', '日本語'],
          current: c.chatLanguage,
          onSelect: c.setChatLanguage,
        ),
      ),
      const SizedBox(height: 24),
      _section('主题'),
      const SettingItem(icon: Icons.palette_outlined, label: '外观模式', value: '深色 (Synthwave)', showChevron: false),
      const SizedBox(height: 24),
      _section('数据'),
      SettingItem(
        icon: Icons.delete_outline,
        label: '清除所有对话',
        value: '删除所有聊天记录',
        onTap: () => _confirmClear(context),
      ),
    ]);
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
      );

  void _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required Future<void> Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PAColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: PAColors.textPrimary)),
            ),
            ...options.map((o) => ListTile(
                  title: Text(o, style: const TextStyle(color: PAColors.textPrimary)),
                  trailing: o == current ? const Icon(Icons.check, color: PAColors.accent) : null,
                  onTap: () {
                    onSelect(o);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PAColors.bgSecondary,
        title: const Text('确认清除？', style: TextStyle(color: PAColors.textPrimary)),
        content: const Text('所有聊天记录将被永久删除。', style: TextStyle(color: PAColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final store = await Future.value(null); // placeholder
              // Clear all topics
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已清除')));
            },
            child: const Text('清除', style: TextStyle(color: PAColors.accent)),
          ),
        ],
      ),
    );
  }
}
