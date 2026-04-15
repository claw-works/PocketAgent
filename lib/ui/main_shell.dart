import 'package:flutter/material.dart';
import 'theme.dart';
import 'chat_topics_screen.dart';
import 'activity_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const <Widget>[
    ChatTopicsScreen(),
    ActivityScreen(),
    SettingsMainScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: _buildTabBar(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: PAColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(21, 12, 21, 21),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: PAColors.bgSecondary,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: PAColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _tab(0, Icons.chat_bubble_outline, 'CHAT'),
            _tab(1, Icons.receipt_long_outlined, 'ACTIVITY'),
            _tab(2, Icons.settings_outlined, 'SETTINGS'),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final active = _index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = index),
        child: Container(
          decoration: BoxDecoration(
            gradient: active ? PAColors.gradientAccent : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? PAColors.bgPrimary : PAColors.textMuted),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: active ? PAColors.bgPrimary : PAColors.textMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
