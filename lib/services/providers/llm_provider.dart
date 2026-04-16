/// Unified tool call representation across all providers.
class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  ToolCall({required this.id, required this.name, required this.arguments});
}

class TokenUsage {
  final int inputTokens;
  final int outputTokens;
  int get totalTokens => inputTokens + outputTokens;
  const TokenUsage({this.inputTokens = 0, this.outputTokens = 0});
  TokenUsage operator +(TokenUsage other) => TokenUsage(
        inputTokens: inputTokens + other.inputTokens,
        outputTokens: outputTokens + other.outputTokens,
      );
  @override
  String toString() => 'in:$inputTokens out:$outputTokens total:$totalTokens';
}

/// Unified LLM response — either text content or tool calls.
class LlmResponse {
  final String? content;
  final List<ToolCall> toolCalls;
  final Map<String, dynamic> rawAssistantMessage;
  final TokenUsage usage;

  bool get hasToolCalls => toolCalls.isNotEmpty;

  LlmResponse({
    this.content,
    this.toolCalls = const [],
    required this.rawAssistantMessage,
    this.usage = const TokenUsage(),
  });
}

/// Abstract provider interface. Each provider converts to/from its own wire format.
abstract class LlmProvider {
  /// Non-streaming call.
  Future<LlmResponse> call({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  });

  /// Streaming call — yields text deltas. Returns final LlmResponse when done.
  /// [onDelta] is called for each text chunk.
  /// If the response contains tool calls, they are returned in the final LlmResponse.
  Future<LlmResponse> stream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required void Function(String delta) onDelta,
  });

  /// Build a tool-result message to append after executing a tool call.
  Map<String, dynamic> buildToolResultMessage({
    required ToolCall toolCall,
    required String result,
  });
}
