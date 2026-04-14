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
  String _provider = 'openai';

  static const _providers = ['openai', 'anthropic', 'bedrock'];
  static const _providerLabels = {
    'openai': 'OpenAI',
    'anthropic': 'Anthropic',
    'bedrock': 'AWS Bedrock',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _provider = await widget.llm.providerName ?? 'openai';
    _keyCtrl.text = await widget.llm.apiKey ?? '';
    _urlCtrl.text = await widget.llm.baseUrl ?? '';
    _modelCtrl.text = await widget.llm.model ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    await widget.llm.setProvider(_provider);
    await widget.llm.setApiKey(_keyCtrl.text.trim());
    final url = _urlCtrl.text.trim();
    if (url.isNotEmpty) await widget.llm.setBaseUrl(url);
    final model = _modelCtrl.text.trim();
    if (model.isNotEmpty) await widget.llm.setModel(model);
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
          const Text('LLM Provider', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          SegmentedButton<String>(
            segments: _providers
                .map((p) => ButtonSegment(value: p, label: Text(_providerLabels[p]!)))
                .toList(),
            selected: {_provider},
            onSelectionChanged: (v) => setState(() => _provider = v.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'API Base URL（留空用默认值）',
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
              labelText: '模型（留空用默认值）',
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
