/// Unified tool call representation across all providers.
class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  ToolCall({required this.id, required this.name, required this.arguments});
}

/// Unified LLM response — either text content or tool calls.
class LlmResponse {
  final String? content;
  final List<ToolCall> toolCalls;

  /// Raw assistant message to feed back into conversation (provider-specific).
  final Map<String, dynamic> rawAssistantMessage;

  bool get hasToolCalls => toolCalls.isNotEmpty;

  LlmResponse({
    this.content,
    this.toolCalls = const [],
    required this.rawAssistantMessage,
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
