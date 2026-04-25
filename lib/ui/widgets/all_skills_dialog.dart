import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/skill/skill_registry.dart';
import '../../services/skill/harness_model.dart';

/// 全屏助手选择器，返回选中的 HarnessSkill 或 null
class AllSkillsDialog extends StatefulWidget {
  const AllSkillsDialog({super.key});

  static Future<HarnessSkill?> show(BuildContext context) {
    return showDialog<HarnessSkill?>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const Dialog.fullscreen(
        backgroundColor: PAColors.bgPrimary,
        child: AllSkillsDialog(),
      ),
    );
  }

  @override
  State<AllSkillsDialog> createState() => _AllSkillsDialogState();
}

class _AllSkillsDialogState extends State<AllSkillsDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = SkillRegistry.instance.harnessSkills;
    final filtered = _query.isEmpty
        ? all
        : all.where((s) =>
            s.displayName.toLowerCase().contains(_query.toLowerCase()) ||
            s.description.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
      child: Column(children: [
        // Header
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
            const Text('选择助手',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PAColors.textPrimary)),
            const Spacer(),
            SizedBox(
              width: 300,
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 13, color: PAColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '搜索助手...',
                  hintStyle: const TextStyle(color: PAColors.textMuted),
                  prefixIcon: const Icon(Icons.search, size: 16, color: PAColors.textMuted),
                  filled: true,
                  fillColor: PAColors.bgInput,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: PAColors.border),
                  ),
                ),
              ),
            ),
          ]),
        ),
        // Grid
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('无匹配助手',
                      style: TextStyle(color: PAColors.textMuted)))
              : GridView.builder(
                  padding: const EdgeInsets.all(32),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 160,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _card(context, filtered[i]),
                ),
        ),
      ]),
    );
  }

  Widget _card(BuildContext context, HarnessSkill s) {
    final rate = s.totalRuns > 0 ? '${(s.successRate * 100).toInt()}%' : '新';
    final rateColor = s.totalRuns == 0 ? PAColors.accent
        : s.successRate > 0.8 ? PAColors.success : PAColors.accent;

    return GestureDetector(
      onTap: () => Navigator.pop(context, s),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: PAColors.gradientCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PAColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: PAColors.gradientAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PAColors.bgPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(rate,
                    style: TextStyle(
                        fontSize: 10, color: rateColor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(s.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: PAColors.textPrimary)),
            if (s.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(s.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: PAColors.textSecondary, height: 1.4)),
            ],
            const Spacer(),
            Text('${s.sops.length} SOP · 进化 ${s.evolutionCount} 次',
                style: const TextStyle(fontSize: 11, color: PAColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
