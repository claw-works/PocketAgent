import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'json_file_store.dart';

/// Stores LLM config per provider. Switching providers preserves each one's settings.
class LlmConfigStore {
  static final LlmConfigStore instance = LlmConfigStore._();
  LlmConfigStore._();

  final _store = JsonFileStore('llm_config.json');
  Map<String, dynamic> _data = {};

  Future<void> load() async {
    final d = await _store.read();
    if (d is Map<String, dynamic>) _data = d;
    // Migrate old flat format to per-provider format
    if (_data.containsKey('api_key') && !_data.containsKey('providers')) {
      final old = Map<String, dynamic>.from(_data);
      final provider = old.remove('provider') ?? 'openai';
      _data = {
        'active': provider,
        'providers': {provider: old},
      };
      await _save();
    }
  }

  String get activeProvider => _data['active'] as String? ?? 'openai';

  Map<String, dynamic> _providerConfig(String provider) {
    final providers = _data['providers'];
    if (providers is! Map) return {};
    final config = providers[provider];
    if (config is! Map) return {};
    return Map<String, dynamic>.from(config);
  }

  // Active provider's config
  String? get apiKey => _activeConfig['api_key'] != null
      ? _decodeKey(_activeConfig['api_key']) : null;
  String? get baseUrl => _activeConfig['base_url'];
  String? get model => _activeConfig['model'];

  Map<String, dynamic> get _activeConfig => _providerConfig(activeProvider);

  // Read config for any provider (for settings UI)
  String? apiKeyFor(String provider) {
    final encoded = _providerConfig(provider)['api_key'] as String?;
    return encoded != null ? _decodeKey(encoded) : null;
  }
  String? baseUrlFor(String provider) => _providerConfig(provider)['base_url'];
  String? modelFor(String provider) => _providerConfig(provider)['model'];

  // Write
  Future<void> setActiveProvider(String v) async {
    _data['active'] = v;
    await _save();
  }

  Future<void> setApiKey(String provider, String v) =>
      _setProviderField(provider, 'api_key', base64Encode(utf8.encode(v)));
  Future<void> setBaseUrl(String provider, String v) =>
      _setProviderField(provider, 'base_url', v);
  Future<void> setModel(String provider, String v) =>
      _setProviderField(provider, 'model', v);

  Future<void> _setProviderField(String provider, String key, String value) async {
    final providers = _data['providers'] is Map
        ? Map<String, dynamic>.from(_data['providers'])
        : <String, dynamic>{};
    final config = providers[provider] is Map
        ? Map<String, dynamic>.from(providers[provider])
        : <String, dynamic>{};
    config[key] = value;
    providers[provider] = config;
    _data['providers'] = providers;
    await _save();
  }

  Future<void> _save() => _store.write(_data);

  String _decodeKey(String encoded) {
    try { return utf8.decode(base64Decode(encoded)); } catch (_) { return encoded; }
  }
}
