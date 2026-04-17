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

/// Callback types for streaming chat.
typedef OnDelta = void Function(String delta);
typedef OnStatus = void Function(String status);
typedef OnToolCall = void Function(String name, Map<String, dynamic> args, String result, bool success);
typedef OnUsage = void Function(TokenUsage total);

class LlmService {
  final ToolRegistry tools;
  bool _cancelled = false;

  LlmService({required this.tools});

  int get maxToolRounds => AgentConfig.instance.maxToolRounds;
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
    LlmProviderType.openai: 'https://api.openai.com/v1',
    LlmProviderType.anthropic: 'https://api.anthropic.com/v1',
    LlmProviderType.bedrock: 'https://bedrock-runtime.us-east-1.amazonaws.com',
    LlmProviderType.gemini: 'https://generativelanguage.googleapis.com/v1beta',
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

  void cancel() => _cancelled = true;

  Future<String> chat(List<Message> history) async {
    return streamChat(history, onDelta: (_) {});
  }

  /// Full streaming chat with tool call visibility and cancel support.
  Future<String> streamChat(
    List<Message> history, {
    required OnDelta onDelta,
    OnStatus? onStatus,
    OnToolCall? onToolCall,
    OnUsage? onUsage,
  }) async {
    _cancelled = false;
    final key = apiKey;
    if (key == null || key.isEmpty) return '⚠️ 请先在设置中配置 API Key';

    final type = _parseProvider(providerName);
    final provider = _createProvider(type);
    final base = baseUrl ?? _defaultBaseUrls[type]!;
    final modelName = model ?? _defaultModels[type]!;
    final systemPrompt = AgentConfig.instance.systemPrompt;

    debugPrint('[LLM] provider=$type model=$modelName');

    // Filter out tool messages from history — they were part of a previous
    // agent loop and don't have matching toolUse blocks in the stored messages.
    final messages = history
        .where((m) => m.role != MessageRole.tool)
        .map((m) => m.toOpenAI())
        .toList();
    final allContent = StringBuffer();
    var totalUsage = const TokenUsage();

    for (var i = 0; i < maxToolRounds; i++) {
      if (_cancelled) return allContent.isEmpty ? '⏹ 已取消' : allContent.toString();

      final LlmResponse resp;
      try {
        // Stream every round
        resp = await provider.stream(
          apiKey: key,
          baseUrl: base,
          model: modelName,
          systemPrompt: systemPrompt,
          messages: messages,
          tools: tools.toOpenAI(),
          onDelta: (delta) {
            allContent.write(delta);
            onDelta(delta);
          },
        );
      } catch (e, st) {
        debugPrint('[LLM] ❌ Error (round $i): $e');
        debugPrint('[LLM] StackTrace: $st');
        if (allContent.isNotEmpty) return allContent.toString();
        return '❌ 请求失败: $e';
      }

      debugPrint('[LLM] Round $i: hasToolCalls=${resp.hasToolCalls}, content=${resp.content?.length ?? 0} chars, usage=${resp.usage}');
      totalUsage = totalUsage + resp.usage;
      onUsage?.call(totalUsage);

      if (!resp.hasToolCalls) {
        return allContent.isEmpty ? (resp.content ?? '') : allContent.toString();
      }

      // Process tool calls
      messages.add(resp.rawAssistantMessage);
      // Collect all tool results for this round, then add as one message
      // (Bedrock requires all toolResults in a single user message)
      final toolResults = <Map<String, dynamic>>[];
      for (final tc in resp.toolCalls) {
        if (_cancelled) return allContent.toString();

        debugPrint('[LLM] Tool call: ${tc.name} id=${tc.id}');
        onStatus?.call('🔧 ${tc.name}');

        final result = await tools.call(tc.name, tc.arguments);
        final success = !result.contains('"status":"error"') && !result.contains('"status":"denied"');
        debugPrint('[LLM] Tool result: ${result.length} chars, success=$success');

        onToolCall?.call(tc.name, tc.arguments, result, success);
        toolResults.add(provider.buildToolResultMessage(toolCall: tc, result: result));
      }
      // Merge tool results: if multiple, combine content arrays into one message
      if (toolResults.length == 1) {
        messages.add(toolResults.first);
      } else if (toolResults.isNotEmpty) {
        final mergedContent = <dynamic>[];
        for (final tr in toolResults) {
          final c = tr['content'];
          if (c is List) {
            mergedContent.addAll(c);
          } else {
            mergedContent.add({'text': c?.toString() ?? ''});
          }
        }
        messages.add({'role': toolResults.first['role'], 'content': mergedContent});
      }
      onStatus?.call('🤔 思考中...');
    }

    return allContent.isEmpty
        ? '⚠️ 工具调用轮次过多（$maxToolRounds），已中止'
        : allContent.toString();
  }
}
