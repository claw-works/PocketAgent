import 'package:flutter/material.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';
import '../../services/llm_config_store.dart';

class ModelConfigScreen extends StatefulWidget {
  const ModelConfigScreen({super.key});

  @override
  State<ModelConfigScreen> createState() => _ModelConfigScreenState();
}

class _ModelConfigScreenState extends State<ModelConfigScreen> {
  final _config = LlmConfigStore.instance;
  late String _provider;
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
    _provider = _config.activeProvider;
    _loadProvider(_provider);
  }

  void _loadProvider(String provider) {
    _keyCtrl.text = _config.apiKeyFor(provider) ?? '';
    _urlCtrl.text = _config.baseUrlFor(provider) ?? '';
    _modelCtrl.text = _config.modelFor(provider) ?? '';
  }

  void _switchProvider(String provider) {
    // Save current before switching
    _saveCurrentSilently();
    setState(() {
      _provider = provider;
      _loadProvider(provider);
    });
  }

  Future<void> _saveCurrentSilently() async {
    final key = _keyCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    if (key.isNotEmpty) await _config.setApiKey(_provider, key);
    if (url.isNotEmpty) await _config.setBaseUrl(_provider, url);
    if (model.isNotEmpty) await _config.setModel(_provider, model);
  }

  Future<void> _save() async {
    try {
      await _saveCurrentSilently();
      await _config.setActiveProvider(_provider);
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
      _section('${_providerLabels[_provider]} 配置'),
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
        final hasKey = (_config.apiKeyFor(p) ?? '').isNotEmpty;
        return GestureDetector(
          onTap: () => _switchProvider(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? PAColors.gradientAccent : null,
              color: active ? null : PAColors.bgSecondary,
              borderRadius: BorderRadius.circular(PARadius.pill),
              border: active ? null : Border.all(color: PAColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_providerLabels[p]!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : PAColors.textSecondary)),
                if (hasKey && !active) ...[
                  const SizedBox(width: 4),
                  Container(width: 6, height: 6,
                      decoration: const BoxDecoration(color: PAColors.success, shape: BoxShape.circle)),
                ],
              ],
            ),
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
