import 'package:flutter/material.dart';
import '../theme.dart';
import '../chat_detail_screen.dart';
import '../../services/skill/harness_model.dart';
import '../settings/settings_detail_scaffold.dart';

class HarnessDetailScreen extends StatelessWidget {
  final HarnessSkill skill;
  const HarnessDetailScreen({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(title: skill.displayName, children: [
      // Stats
      _statsRow(),
      const SizedBox(height: 20),

      // SOPs
      _section('SOP 列表'),
      if (skill.sops.isEmpty)
        const Text('暂无 SOP', style: TextStyle(color: PAColors.textMuted, fontSize: 13)),
      ...skill.sops.entries.map((e) => _sopCard(e.key, e.value)),
      const SizedBox(height: 20),

      // Harness
      if (skill.harnessPrompt != null) ...[
        _section('验证条件 (Harness)'),
        _contentCard(skill.harnessPrompt!),
        const SizedBox(height: 20),
      ],

      // History
      if (skill.history.isNotEmpty) ...[
        _section('进化历史（最近 10 条）'),
        ...skill.history.reversed.take(10).map(_historyItem),
        const SizedBox(height: 20),
      ],

      // Launch button
      GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailScreen(harnessSkill: skill)),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: PAColors.gradientAccent,
            borderRadius: BorderRadius.circular(PARadius.md),
          ),
          child: const Text('启动助手', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statBadge('执行', '${skill.totalRuns} 次', PAColors.accentCyan),
        const SizedBox(width: 10),
        _statBadge('成功率', skill.totalRuns > 0 ? '${(skill.successRate * 100).toInt()}%' : '-',
            skill.successRate > 0.8 ? PAColors.success : PAColors.accent),
        const SizedBox(width: 10),
        _statBadge('进化', '${skill.evolutionCount} 次', PAColors.accentPurple),
        const SizedBox(width: 10),
        _statBadge('SOP', '${skill.sops.length} 个', PAColors.accentOrange),
      ],
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: PAColors.bgSecondary,
          borderRadius: BorderRadius.circular(PARadius.sm),
          border: Border.all(color: PAColors.border),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: PAColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
      );

  Widget _sopCard(String name, String content) {
    final preview = content.split('\n').where((l) => l.trim().isNotEmpty && !l.startsWith('#')).take(2).join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PAColors.bgSecondary,
          borderRadius: BorderRadius.circular(PARadius.md),
          border: Border.all(color: PAColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.description_outlined, size: 16, color: PAColors.accentCyan),
            const SizedBox(width: 8),
            Text('$name.md', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PAColors.textPrimary)),
          ]),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: PAColors.textSecondary)),
          ],
        ]),
      ),
    );
  }

  Widget _contentCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PAColors.bgSecondary,
        borderRadius: BorderRadius.circular(PARadius.md),
        border: Border.all(color: PAColors.border),
      ),
      child: Text(
        content.length > 300 ? '${content.substring(0, 300)}...' : content,
        style: const TextStyle(fontSize: 12, color: PAColors.textSecondary, height: 1.5),
      ),
    );
  }

  Widget _historyItem(HarnessRecord r) {
    final time = '${r.time.month}/${r.time.day} ${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: PAColors.bgSecondary,
          borderRadius: BorderRadius.circular(PARadius.sm),
        ),
        child: Row(children: [
          Icon(
            r.autoEvolved ? Icons.auto_fix_high : r.success ? Icons.check_circle : Icons.error,
            size: 14,
            color: r.autoEvolved ? PAColors.accentPurple : r.success ? PAColors.success : PAColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                r.autoEvolved ? '进化: ${r.fix ?? r.sop}' : r.success ? '成功: ${r.sop}' : '失败: ${r.reason ?? r.sop}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: PAColors.textPrimary),
              ),
            ]),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: PAColors.textMuted)),
        ]),
      ),
    );
  }
}
