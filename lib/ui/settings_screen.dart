import 'package:flutter/material.dart';
import '../services/llm_service.dart';

class SettingsScreen extends StatefulWidget {
  final LlmService llm;
  const SettingsScreen({super.key, required this.llm});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _keyCtrl.text = await widget.llm.apiKey ?? '';
    _urlCtrl.text = await widget.llm.baseUrl ?? 'https://api.openai.com';
    _modelCtrl.text = await widget.llm.model ?? 'gpt-4o-mini';
    setState(() {});
  }

  Future<void> _save() async {
    await widget.llm.setApiKey(_keyCtrl.text.trim());
    await widget.llm.setBaseUrl(_urlCtrl.text.trim());
    await widget.llm.setModel(_modelCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ 已保存')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'API Base URL',
              hintText: 'https://api.openai.com',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'API Key'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelCtrl,
            decoration: const InputDecoration(
              labelText: '模型',
              hintText: 'gpt-4o-mini',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _urlCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }
}
