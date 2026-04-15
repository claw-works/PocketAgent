import 'package:flutter/material.dart';
import '../theme.dart';

class SettingsDetailScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingsDetailScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.chevron_left, size: 24, color: PAColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: PAColors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
