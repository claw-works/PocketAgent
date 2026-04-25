import 'package:flutter/material.dart';
import 'main_shell.dart';
import 'desktop_shell.dart';

/// 宽度 >= 900 使用桌面端三栏布局，否则用移动端 Tab 布局
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({super.key});

  static const double desktopBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => c.maxWidth >= desktopBreakpoint
          ? const DesktopShell()
          : const MainShell(),
    );
  }
}
