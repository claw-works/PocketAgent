import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';
import 'tool_registry.dart';
import 'providers/llm_provider.dart';
import 'providers/openai_provider.dart';
import 'providers/anthropic_provider.dart';
import 'providers/bedrock_provider.dart';
import 'providers/gemini_provider.dart';

enum LlmProviderType { openai, anthropic, bedrock, gemini }

class LlmService {
  final ToolRegistry tools;
  final _storage = const FlutterSecureStorage();

  static const _systemPrompt = '你是 PocketAgent，一个运行在用户手机上的私人 AI 助手。'
      '你可以通过工具直接操控这台设备。回答简洁，用中文。';

  static const maxToolRounds = 5;

  LlmService({required this.tools});

  // --- Storage keys ---
  Future<String?> get apiKey => _storage.read(key: 'api_key');
  Future<void> setApiKey(String v) => _storage.write(key: 'api_key', value: v);

  Future<String?> get baseUrl => _storage.read(key: 'base_url');
  Future<void> setBaseUrl(String v) => _storage.write(key: 'base_url', value: v);

  Future<String?> get model => _storage.read(key: 'model');
  Future<void> setModel(String v) => _storage.write(key: 'model', value: v);

  Future<String?> get providerName => _storage.read(key: 'provider');
  Future<void> setProvider(String v) => _storage.write(key: 'provider', value: v);

  // --- Provider resolution ---
  static const _defaultBaseUrls = {
    LlmProviderType.openai: 'https://api.openai.com',
    LlmProviderType.anthropic: 'https://api.anthropic.com',
    LlmProviderType.bedrock: 'https://bedrock-runtime.us-east-1.amazonaws.com',
    LlmProviderType.gemini: 'https://generativelanguage.googleapis.com',
  };

  static const _defaultModels = {
    LlmProviderType.openai: 'gpt-4o-mini',
    LlmProviderType.anthropic: 'claude-sonnet-4-20250514',
    LlmProviderType.bedrock: 'anthropic.claude-sonnet-4-20250514-v1:0',
    LlmProviderType.gemini: 'gemini-2.0-flash',
  };

  LlmProviderType _parseProvider(String? name) {
    switch (name) {
      case 'anthropic':
        return LlmProviderType.anthropic;
      case 'bedrock':
        return LlmProviderType.bedrock;
      case 'gemini':
        return LlmProviderType.gemini;
      default:
        return LlmProviderType.openai;
    }
  }

  LlmProvider _createProvider(LlmProviderType type) {
    switch (type) {
      case LlmProviderType.anthropic:
        return AnthropicProvider();
      case LlmProviderType.bedrock:
        return BedrockProvider();
      case LlmProviderType.gemini:
        return GeminiProvider();
      case LlmProviderType.openai:
        return OpenAiProvider();
    }
  }

  /// Main chat entry — resolves provider, runs tool-call loop.
  Future<String> chat(List<Message> history) async {
    final key = await apiKey;
    if (key == null || key.isEmpty) return '⚠️ 请先在设置中配置 API Key';

    final type = _parseProvider(await providerName);
    final provider = _createProvider(type);
    final base = await baseUrl ?? _defaultBaseUrls[type]!;
    final modelName = await model ?? _defaultModels[type]!;

    final messages = history.map((m) => m.toOpenAI()).toList();

    for (var i = 0; i < maxToolRounds; i++) {
      final LlmResponse resp;
      try {
        resp = await provider.call(
          apiKey: key,
          baseUrl: base,
          model: modelName,
          systemPrompt: _systemPrompt,
          messages: messages,
          tools: tools.toOpenAI(),
        );
      } catch (e) {
        return '❌ 请求失败: $e';
      }

      if (!resp.hasToolCalls) {
        return resp.content ?? '';
      }

      // Append assistant message with tool calls
      messages.add(resp.rawAssistantMessage);

      // Execute each tool and append results
      for (final tc in resp.toolCalls) {
        final result = await tools.call(tc.name, tc.arguments);
        messages.add(provider.buildToolResultMessage(
          toolCall: tc,
          result: result,
        ));
      }
    }

    return '⚠️ 工具调用轮次过多（$maxToolRounds），已中止';
  }
}
