import 'package:flutter/material.dart';
import '../theme.dart';
import 'harness_detail_screen.dart';
import '../../services/skill/skill_registry.dart';
import '../../services/skill/harness_model.dart';

/// Displays harness skills as launchable assistants.
class HarnessListWidget extends StatefulWidget {
  const HarnessListWidget({super.key});

  @override
  State<HarnessListWidget> createState() => _HarnessListWidgetState();
}

class _HarnessListWidgetState extends State<HarnessListWidget> {
  @override
  void initState() {
    super.initState();
    SkillRegistry.instance.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    SkillRegistry.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = SkillRegistry.instance.harnessSkills;
    if (skills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('助手',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: PAColors.textMuted, letterSpacing: 1)),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: skills.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _card(context, skills[i]),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, HarnessSkill skill) {
    final rate = skill.totalRuns > 0
        ? '${(skill.successRate * 100).toInt()}%'
        : '新';
    final evolutions = skill.evolutionCount;

    return GestureDetector(
      onTap: () => _launch(context, skill),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: PAColors.gradientCard,
          borderRadius: BorderRadius.circular(PARadius.md),
          border: Border.all(color: PAColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: PAColors.gradientAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PAColors.bgPrimary,
                    borderRadius: BorderRadius.circular(PARadius.pill),
                  ),
                  child: Text(rate,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: skill.successRate > 0.8 ? PAColors.success : PAColors.accent)),
                ),
              ],
            ),
            const Spacer(),
            Text(skill.displayName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: PAColors.textPrimary)),
            const SizedBox(height: 2),
            Text('${skill.sops.length} 个 SOP · 进化 $evolutions 次',
                style: const TextStyle(fontSize: 11, color: PAColors.textMuted)),
          ],
        ),
      ),
    );
  }

  void _launch(BuildContext context, HarnessSkill skill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HarnessDetailScreen(skill: skill),
      ),
    );
  }
}
