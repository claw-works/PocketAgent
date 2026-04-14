import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';
import 'tool_registry.dart';

class LlmService {
  final ToolRegistry tools;
  final _storage = const FlutterSecureStorage();

  static const _systemPrompt = '你是 PocketAgent，一个运行在用户手机上的私人 AI 助手。'
      '你可以通过工具直接操控这台设备。回答简洁，用中文。';

  LlmService({required this.tools});

  Future<String?> get apiKey => _storage.read(key: 'openai_api_key');
  Future<void> setApiKey(String key) =>
      _storage.write(key: 'openai_api_key', value: key);

  Future<String?> get baseUrl => _storage.read(key: 'openai_base_url');
  Future<void> setBaseUrl(String url) =>
      _storage.write(key: 'openai_base_url', value: url);

  Future<String?> get model => _storage.read(key: 'llm_model');
  Future<void> setModel(String m) =>
      _storage.write(key: 'llm_model', value: m);

  /// Send conversation to LLM, handle tool calls in a loop, return final text.
  Future<String> chat(List<Message> history) async {
    final key = await apiKey;
    if (key == null || key.isEmpty) return '⚠️ 请先在设置中配置 API Key';

    final base = await baseUrl ?? 'https://api.openai.com';
    final modelName = await model ?? 'gpt-4o-mini';

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => m.toOpenAI()),
    ];

    // Tool-call loop: keep calling until LLM returns plain text
    for (var i = 0; i < 5; i++) {
      final body = jsonEncode({
        'model': modelName,
        'messages': messages,
        'tools': tools.toOpenAI(),
      });

      final resp = await http.post(
        Uri.parse('$base/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: body,
      );

      if (resp.statusCode != 200) {
        return '❌ LLM 请求失败 (${resp.statusCode}): ${resp.body}';
      }

      final data = jsonDecode(resp.body);
      final choice = data['choices'][0];
      final msg = choice['message'];
      final finishReason = choice['finish_reason'];

      // No tool calls — return content
      if (finishReason != 'tool_calls' || msg['tool_calls'] == null) {
        return msg['content'] ?? '';
      }

      // Process tool calls
      messages.add(msg);
      for (final tc in msg['tool_calls']) {
        final fn = tc['function'];
        final name = fn['name'] as String;
        final args = jsonDecode(fn['arguments'] as String) as Map<String, dynamic>;
        final result = await tools.call(name, args);
        messages.add({
          'role': 'tool',
          'tool_call_id': tc['id'],
          'content': result,
        });
      }
    }

    return '⚠️ 工具调用次数过多，已中止';
  }
}
