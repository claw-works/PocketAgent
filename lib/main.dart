import 'package:flutter/material.dart';
import 'app.dart';
import 'services/activity_log.dart';
import 'services/chat_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ActivityLog.instance.load(),
    ChatStore.instance.load(),
  ]);
  runApp(const PocketAgentApp());
}
