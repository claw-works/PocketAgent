import 'package:flutter/material.dart';
import '../theme.dart';
import '../settings/settings_screen.dart';

/// 全屏设置对话框，右侧满屏，带返回按钮（风格与 AllSkillsDialog 一致）
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const Dialog.fullscreen(
        backgroundColor: PAColors.bgPrimary,
        child: SettingsDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: PAColors.border)),
          ),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: PAColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text('设置',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PAColors.textPrimary)),
          ]),
        ),
        const Expanded(child: SettingsMainScreen()),
      ]),
    );
  }
}
