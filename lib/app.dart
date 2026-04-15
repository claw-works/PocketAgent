import 'package:flutter/material.dart';
import 'ui/theme.dart';
import 'ui/main_shell.dart';

class PocketAgentApp extends StatelessWidget {
  const PocketAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketAgent',
      debugShowCheckedModeBanner: false,
      theme: paTheme(),
      home: const MainShell(),
    );
  }
}
