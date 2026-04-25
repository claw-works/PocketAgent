import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme.dart';

/// 自定义标题栏：隐藏原生标题栏后用来替代
/// - 可拖动区域移动窗口
/// - 左边留空位给 macOS 红绿灯按钮（76px）
/// - 右侧放自定义操作按钮
class CustomTitleBar extends StatelessWidget {
  /// 左侧内容（在红绿灯右边）
  final Widget? leading;
  /// 中间内容（整个是拖动区域）
  final Widget? center;
  /// 右侧操作按钮
  final List<Widget> actions;
  final double height;

  const CustomTitleBar({
    super.key,
    this.leading,
    this.center,
    this.actions = const [],
    this.height = 36,
  });

  bool get _isMac => !kIsWeb && Platform.isMacOS;
  bool get _shouldShow =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return GestureDetector(
      // 空白区域双击最大化/还原，单击拖动
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
        height: height,
        color: PAColors.bgPrimary,
        child: Row(children: [
          // macOS 红绿灯预留位
          if (_isMac) const SizedBox(width: 76),
          if (leading != null) leading!,
          Expanded(child: center ?? const SizedBox.shrink()),
          ...actions,
          const SizedBox(width: 8),
        ]),
      ),
    );
  }
}
