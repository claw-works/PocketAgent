import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'json_file_store.dart';

/// Stores LLM connection config.
/// API keys are base64-obfuscated (not true encryption, but avoids plaintext on disk).
/// For production, use platform keychain with proper entitlements.
class LlmConfigStore {
  static final LlmConfigStore instance = LlmConfigStore._();
  LlmConfigStore._();

  final _store = JsonFileStore('llm_config.json');
  Map<String, dynamic> _data = {};

  Future<void> load() async {
    final d = await _store.read();
    if (d is Map<String, dynamic>) _data = d;
  }

  String? get provider => _data['provider'];
  String? get apiKey {
    final encoded = _data['api_key'] as String?;
    if (encoded == null) return null;
    try { return utf8.decode(base64Decode(encoded)); } catch (_) { return encoded; }
  }
  String? get baseUrl => _data['base_url'];
  String? get model => _data['model'];

  Future<void> setProvider(String v) => _set('provider', v);
  Future<void> setApiKey(String v) => _set('api_key', base64Encode(utf8.encode(v)));
  Future<void> setBaseUrl(String v) => _set('base_url', v);
  Future<void> setModel(String v) => _set('model', v);

  Future<void> _set(String key, String value) async {
    _data[key] = value;
    await _store.write(_data);
  }
}
