import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/activity_log.dart';
import 'services/chat_store.dart';
import 'services/agent_config.dart';
import 'services/llm_config_store.dart';
import 'services/skill/skill_registry.dart';
import 'services/pa_paths.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PAPaths.base;
  await Future.wait([
    ActivityLog.instance.load(),
    ChatStore.instance.load(),
    AgentConfig.instance.load(),
    LlmConfigStore.instance.load(),
    SkillRegistry.instance.load(),
  ]);

  // 桌面端隐藏原生标题栏，但保留 traffic lights
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const opts = WindowOptions(
      size: Size(1280, 820),
      minimumSize: Size(640, 480),
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Color(0xFF0A0A1A),
    );
    await windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const PocketAgentApp());
}
