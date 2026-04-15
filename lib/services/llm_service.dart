import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'tool_registry.dart';
import 'agent_config.dart';
import 'llm_config_store.dart';
import 'providers/llm_provider.dart';
import 'providers/openai_provider.dart';
import 'providers/anthropic_provider.dart';
import 'providers/bedrock_provider.dart';
import 'providers/gemini_provider.dart';

enum LlmProviderType { openai, anthropic, bedrock, gemini }

class LlmService {
  final ToolRegistry tools;
  static const maxToolRounds = 5;

  LlmService({required this.tools});

  LlmConfigStore get _config => LlmConfigStore.instance;

  String? get apiKey => _config.apiKey;
  String? get baseUrl => _config.baseUrl;
  String? get model => _config.model;
  String? get providerName => _config.activeProvider;

  Future<void> setApiKey(String v) => _config.setApiKey(_config.activeProvider, v);
  Future<void> setBaseUrl(String v) => _config.setBaseUrl(_config.activeProvider, v);
  Future<void> setModel(String v) => _config.setModel(_config.activeProvider, v);
  Future<void> setProvider(String v) => _config.setActiveProvider(v);

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

  Future<String> chat(List<Message> history) async {
    return streamChat(history, onDelta: (_) {});
  }

  Future<String> streamChat(
    List<Message> history, {
    required void Function(String delta) onDelta,
    void Function(String status)? onStatus,
  }) async {
    final key = apiKey;
    if (key == null || key.isEmpty) return '⚠️ 请先在设置中配置 API Key';

    final type = _parseProvider(providerName);
    final provider = _createProvider(type);
    final base = baseUrl ?? _defaultBaseUrls[type]!;
    final modelName = model ?? _defaultModels[type]!;
    final systemPrompt = AgentConfig.instance.systemPrompt;

    debugPrint('[LLM] provider=$type model=$modelName base=$base');

    final messages = history.map((m) => m.toOpenAI()).toList();

    for (var i = 0; i < maxToolRounds; i++) {
      final LlmResponse resp;
      final isFirstRound = i == 0;
      try {
        if (isFirstRound) {
          resp = await provider.stream(
            apiKey: key,
            baseUrl: base,
            model: modelName,
            systemPrompt: systemPrompt,
            messages: messages,
            tools: tools.toOpenAI(),
            onDelta: onDelta,
          );
        } else {
          resp = await provider.call(
            apiKey: key,
            baseUrl: base,
            model: modelName,
            systemPrompt: systemPrompt,
            messages: messages,
            tools: tools.toOpenAI(),
          );
        }
      } catch (e, st) {
        debugPrint('[LLM] ❌ Error (round $i): $e');
        debugPrint('[LLM] StackTrace: $st');
        return '❌ 请求失败: $e';
      }

      debugPrint('[LLM] Round $i: hasToolCalls=${resp.hasToolCalls}, content=${resp.content?.length ?? 0} chars');

      if (!resp.hasToolCalls) {
        if (!isFirstRound && resp.content != null) {
          onStatus?.call('');
          onDelta(resp.content!);
        }
        return resp.content ?? '';
      }

      messages.add(resp.rawAssistantMessage);
      for (final tc in resp.toolCalls) {
        debugPrint('[LLM] Tool call: ${tc.name}(${tc.arguments})');
        onStatus?.call('🔧 正在执行: ${tc.name}');
        final result = await tools.call(tc.name, tc.arguments);
        debugPrint('[LLM] Tool result: ${result.length} chars');
        messages.add(provider.buildToolResultMessage(toolCall: tc, result: result));
      }
      onStatus?.call('🤔 正在思考...');
    }

    return '⚠️ 工具调用轮次过多（$maxToolRounds），已中止';
  }
}
