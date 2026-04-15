import 'package:flutter/material.dart';
import '../widgets/setting_item.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';
import '../../services/llm_service.dart';
import '../../services/tool_registry.dart';

class ModelConfigScreen extends StatefulWidget {
  const ModelConfigScreen({super.key});

  @override
  State<ModelConfigScreen> createState() => _ModelConfigScreenState();
}

class _ModelConfigScreenState extends State<ModelConfigScreen> {
  late final LlmService _llm;
  String _provider = 'openai';
  final _controllers = <String, TextEditingController>{};

  static const _providers = ['openai', 'anthropic', 'bedrock', 'gemini'];
  static const _providerLabels = {
    'openai': 'OpenAI',
    'anthropic': 'Anthropic',
    'bedrock': 'Amazon Bedrock',
    'gemini': 'Google Gemini',
  };

  @override
  void initState() {
    super.initState();
    _llm = LlmService(tools: ToolRegistry());
    for (final k in ['api_key', 'base_url', 'model']) {
      _controllers[k] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    _provider = await _llm.providerName ?? 'openai';
    _controllers['api_key']!.text = await _llm.apiKey ?? '';
    _controllers['base_url']!.text = await _llm.baseUrl ?? '';
    _controllers['model']!.text = await _llm.model ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    await _llm.setProvider(_provider);
    await _llm.setApiKey(_controllers['api_key']!.text.trim());
    final url = _controllers['base_url']!.text.trim();
    if (url.isNotEmpty) await _llm.setBaseUrl(url);
    final model = _controllers['model']!.text.trim();
    if (model.isNotEmpty) await _llm.setModel(model);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ 已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(title: '模型配置', children: [
      _section('LLM 提供商'),
      const SizedBox(height: 8),
      _providerSelector(),
      const SizedBox(height: 20),
      _section('连接配置'),
      const SizedBox(height: 8),
      _field('base_url', 'API Base URL', '留空使用默认值'),
      const SizedBox(height: 8),
      _field('api_key', 'API Key', '输入你的 API Key', obscure: true),
      const SizedBox(height: 8),
      _field('model', '模型名称', '留空使用默认值'),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: _save,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: PAColors.gradientAccent,
            borderRadius: BorderRadius.circular(PARadius.md),
          ),
          child: const Text('保存',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PAColors.textMuted,
                letterSpacing: 1)),
      );

  Widget _providerSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _providers.map((p) {
        final active = _provider == p;
        return GestureDetector(
          onTap: () => setState(() => _provider = p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? PAColors.gradientAccent : null,
              color: active ? null : PAColors.bgSecondary,
              borderRadius: BorderRadius.circular(PARadius.pill),
              border: active ? null : Border.all(color: PAColors.border),
            ),
            child: Text(_providerLabels[p]!,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : PAColors.textSecondary)),
          ),
        );
      }).toList(),
    );
  }

  Widget _field(String key, String label, String hint, {bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: PAColors.bgSecondary,
        borderRadius: BorderRadius.circular(PARadius.md),
        border: Border.all(color: PAColors.border),
      ),
      child: TextField(
        controller: _controllers[key],
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: PAColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: PAColors.textMuted, fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: PAColors.textMuted, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
