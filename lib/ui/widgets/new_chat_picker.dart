import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/skill/skill_registry.dart';
import '../../services/skill/harness_model.dart';
import 'all_skills_dialog.dart';

/// 新建对话选择器：通用对话 + 常用助手 + 更多入口
/// 返回选中的 HarnessSkill，null 表示通用对话，不选则返回空
class NewChatPicker extends StatelessWidget {
  final int maxFrequent;
  const NewChatPicker({super.key, this.maxFrequent = 5});

  static Future<HarnessSkill?> show(BuildContext context, {Offset? anchor}) async {
    // 有锚点 → popover，否则全屏底部 sheet
    if (anchor != null) {
      return _showPopover(context, anchor);
    }
    return showModalBottomSheet<HarnessSkill?>(
      context: context,
      backgroundColor: PAColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SafeArea(child: NewChatPicker()),
    );
  }

  static Future<HarnessSkill?> _showPopover(BuildContext context, Offset anchor) {
    return showDialog<HarnessSkill?>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Stack(children: [
        Positioned(
          left: anchor.dx,
          top: anchor.dy,
          width: 260,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: PAColors.bgTertiary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PAColors.border),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8))],
              ),
              child: const NewChatPicker(),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skills = SkillRegistry.instance.harnessSkills
      ..sort((a, b) => b.totalRuns.compareTo(a.totalRuns));
    final frequent = skills.take(maxFrequent).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('新建对话',
                  style: TextStyle(color: PAColors.textPrimary, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: PAColors.textMuted),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: PAColors.border),
        _item(
          context,
          icon: Icons.chat_bubble_outline,
          iconColor: PAColors.textPrimary,
          iconBg: PAColors.bgPrimary,
          name: '通用对话',
          onTap: () => Navigator.pop(context, null), // null = 通用对话
        ),
        const Divider(height: 1, color: PAColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('常用助手',
                  style: TextStyle(
                      fontSize: 11,
                      color: PAColors.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              GestureDetector(
                onTap: () async {
                  final picked = await AllSkillsDialog.show(context);
                  if (picked != null && context.mounted) {
                    Navigator.pop(context, picked);
                  }
                },
                child: const Text('全部助手 →',
                    style: TextStyle(
                        fontSize: 11,
                        color: PAColors.accent,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        ...frequent.map((s) => _skillItem(context, s)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _skillItem(BuildContext context, HarnessSkill s) {
    return _item(
      context,
      icon: Icons.auto_awesome,
      iconColor: Colors.white,
      iconBg: null, // 用渐变
      gradient: PAColors.gradientAccent,
      name: s.displayName,
      onTap: () => Navigator.pop(context, s),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    Color? iconBg,
    Gradient? gradient,
    required String name,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                gradient: gradient,
                borderRadius: BorderRadius.circular(8),
                border: iconBg != null ? Border.all(color: PAColors.border) : null,
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 10),
            Text(name,
                style: const TextStyle(fontSize: 13, color: PAColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
