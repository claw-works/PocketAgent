import 'package:flutter/material.dart';
import 'app.dart';
import 'services/activity_log.dart';
import 'services/chat_store.dart';
import 'services/agent_config.dart';
import 'services/llm_config_store.dart';
import 'services/skill/skill_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ActivityLog.instance.load(),
    ChatStore.instance.load(),
    AgentConfig.instance.load(),
    LlmConfigStore.instance.load(),
    SkillRegistry.instance.load(),
  ]);
  runApp(const PocketAgentApp());
}
