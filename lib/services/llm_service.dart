import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';
import 'tool_registry.dart';
import 'agent_config.dart';
import 'providers/llm_provider.dart';
import 'providers/openai_provider.dart';
import 'providers/anthropic_provider.dart';
import 'providers/bedrock_provider.dart';
import 'providers/gemini_provider.dart';

enum LlmProviderType { openai, anthropic, bedrock, gemini }

class LlmService {
  final ToolRegistry tools;
  final _storage = const FlutterSecureStorage();

  static const maxToolRounds = 5;

  LlmService({required this.tools});

  // --- Storage ---
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
      case 'anthropic': return LlmProviderType.anthropic;
      case 'bedrock': return LlmProviderType.bedrock;
      case 'gemini': return LlmProviderType.gemini;
      default: return LlmProviderType.openai;
    }
  }

  LlmProvider _createProvider(LlmProviderType type) {
    switch (type) {
      case LlmProviderType.anthropic: return AnthropicProvider();
      case LlmProviderType.bedrock: return BedrockProvider();
      case LlmProviderType.gemini: return GeminiProvider();
      case LlmProviderType.openai: return OpenAiProvider();
    }
  }

  /// Non-streaming chat (legacy).
  Future<String> chat(List<Message> history) async {
    return streamChat(history, onDelta: (_) {});
  }

  /// Streaming chat — calls [onDelta] for each text chunk.
  Future<String> streamChat(
    List<Message> history, {
    required void Function(String delta) onDelta,
  }) async {
    final key = await apiKey;
    if (key == null || key.isEmpty) return '⚠️ 请先在设置中配置 API Key';

    final type = _parseProvider(await providerName);
    final provider = _createProvider(type);
    final base = await baseUrl ?? _defaultBaseUrls[type]!;
    final modelName = await model ?? _defaultModels[type]!;
    final systemPrompt = AgentConfig.instance.systemPrompt;

    final messages = history.map((m) => m.toOpenAI()).toList();

    for (var i = 0; i < maxToolRounds; i++) {
      final LlmResponse resp;
      try {
        resp = await provider.stream(
          apiKey: key,
          baseUrl: base,
          model: modelName,
          systemPrompt: systemPrompt,
          messages: messages,
          tools: tools.toOpenAI(),
          onDelta: onDelta,
        );
      } catch (e) {
        return '❌ 请求失败: $e';
      }

      if (!resp.hasToolCalls) {
        return resp.content ?? '';
      }

      // Tool call round — execute tools, then loop back (no streaming for tool rounds)
      messages.add(resp.rawAssistantMessage);
      for (final tc in resp.toolCalls) {
        final result = await tools.call(tc.name, tc.arguments);
        messages.add(provider.buildToolResultMessage(toolCall: tc, result: result));
      }
    }

    return '⚠️ 工具调用轮次过多（$maxToolRounds），已中止';
  }
}
