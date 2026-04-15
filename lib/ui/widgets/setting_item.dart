import 'package:flutter/material.dart';
import '../theme.dart';

class SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showChevron;
  final VoidCallback? onTap;

  const SettingItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PAColors.bgSecondary,
          borderRadius: BorderRadius.circular(PARadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: PAColors.gradientAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: PAColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13, color: PAColors.textSecondary)),
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right,
                  size: 18, color: PAColors.textMuted),
          ],
        ),
      ),
    );
  }
}
