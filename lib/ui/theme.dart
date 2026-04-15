import 'package:flutter/material.dart';

/// PocketAgent Retrowave / Synthwave 主题
class PAColors {
  PAColors._();

  // Synthwave 霓虹色
  static const accent = Color(0xFFFF6B6B); // 霓虹粉红
  static const accentOrange = Color(0xFFFF9F43); // 霓虹橙
  static const accentYellow = Color(0xFFFECA57); // 霓虹黄
  static const accentCyan = Color(0xFF48DBFB); // 霓虹青
  static const accentPurple = Color(0xFFC44DFF); // 霓虹紫
  static const accentSoft = Color(0x33FF6B6B);
  static const success = Color(0xFF0ABDE3); // 青色成功

  // 深色背景（深紫→深蓝）
  static const bgPrimary = Color(0xFF0A0A1A);
  static const bgSecondary = Color(0xFF141432);
  static const bgTertiary = Color(0xFF1E1E4A);
  static const bgInput = Color(0xFF12122E);

  // 文字
  static const textPrimary = Color(0xFFF0E6FF);
  static const textSecondary = Color(0xFF9B8EC4);
  static const textMuted = Color(0xFF5C5080);

  static const border = Color(0xFF2A2060);

  // 气泡
  static const userBubble = Color(0xFFFF6B6B);
  static const aiBubble = Color(0xFF1A1A40);

  // 渐变
  static const gradientAccent = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF9F43), Color(0xFFFECA57)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBg = LinearGradient(
    colors: [Color(0xFF0A0A1A), Color(0xFF141432), Color(0xFF1A0A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const gradientCard = LinearGradient(
    colors: [Color(0xFF1E1E4A), Color(0xFF141432)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientNeon = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFC44DFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class PARadius {
  PARadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

ThemeData paTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PAColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: PAColors.accent,
      surface: PAColors.bgPrimary,
      onSurface: PAColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PAColors.bgPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    fontFamily: 'Inter',
    useMaterial3: true,
  );
}
