import 'package:flutter/material.dart';
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
  final _keyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  static const _providers = ['openai', 'anthropic', 'bedrock', 'gemini'];
  static const _providerLabels = {
    'openai': 'OpenAI',
    'anthropic': 'Anthropic',
    'bedrock': 'Bedrock',
    'gemini': 'Gemini',
  };

  @override
  void initState() {
    super.initState();
    _llm = LlmService(tools: ToolRegistry());
    _provider = _llm.providerName ?? 'openai';
    _keyCtrl.text = _llm.apiKey ?? '';
    _urlCtrl.text = _llm.baseUrl ?? '';
    _modelCtrl.text = _llm.model ?? '';
  }

  Future<void> _save() async {
    try {
      await _llm.setProvider(_provider);
      await _llm.setApiKey(_keyCtrl.text.trim());
      final url = _urlCtrl.text.trim();
      if (url.isNotEmpty) await _llm.setBaseUrl(url);
      final model = _modelCtrl.text.trim();
      if (model.isNotEmpty) await _llm.setModel(model);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ 已保存')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❌ 保存失败: $e')));
      }
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
      _field(_urlCtrl, 'API Base URL', '留空使用默认值'),
      const SizedBox(height: 8),
      _field(_keyCtrl, 'API Key', '输入你的 API Key', obscure: true),
      const SizedBox(height: 8),
      _field(_modelCtrl, '模型名称', '留空使用默认值'),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : PAColors.textSecondary)),
          ),
        );
      }).toList(),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: PAColors.bgSecondary,
        borderRadius: BorderRadius.circular(PARadius.md),
        border: Border.all(color: PAColors.border),
      ),
      child: TextField(
        controller: ctrl,
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
    _keyCtrl.dispose();
    _urlCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }
}
