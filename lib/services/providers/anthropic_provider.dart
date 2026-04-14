import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';

class AnthropicProvider implements LlmProvider {
  @override
  Future<LlmResponse> call({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async {
    // Convert OpenAI-style tools to Anthropic format
    final anthropicTools = tools.map((t) {
      final fn = t['function'] as Map<String, dynamic>;
      return {
        'name': fn['name'],
        'description': fn['description'],
        'input_schema': fn['parameters'],
      };
    }).toList();

    // Convert messages: merge system into top-level, adapt tool results
    final anthropicMessages = messages.map(_convertMessage).toList();

    final body = jsonEncode({
      'model': model,
      'max_tokens': 4096,
      'system': systemPrompt,
      'messages': anthropicMessages,
      if (anthropicTools.isNotEmpty) 'tools': anthropicTools,
    });

    final resp = await http.post(
      Uri.parse('$baseUrl/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Anthropic ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final content = data['content'] as List;

    String? textContent;
    final toolCalls = <ToolCall>[];

    for (final block in content) {
      if (block['type'] == 'text') {
        textContent = (textContent ?? '') + block['text'];
      } else if (block['type'] == 'tool_use') {
        toolCalls.add(ToolCall(
          id: block['id'],
          name: block['name'],
          arguments: Map<String, dynamic>.from(block['input']),
        ));
      }
    }

    return LlmResponse(
      content: textContent,
      toolCalls: toolCalls,
      rawAssistantMessage: {'role': 'assistant', 'content': content},
    );
  }

  Map<String, dynamic> _convertMessage(Map<String, dynamic> msg) {
    final role = msg['role'];
    // Tool result → Anthropic format
    if (role == 'tool') {
      return {
        'role': 'user',
        'content': [
          {
            'type': 'tool_result',
            'tool_use_id': msg['tool_call_id'],
            'content': msg['content'],
          }
        ],
      };
    }
    // Assistant with tool_calls → Anthropic content blocks
    if (role == 'assistant' && msg['content'] is List) {
      return msg;
    }
    return {'role': role, 'content': msg['content'] ?? ''};
  }

  @override
  Map<String, dynamic> buildToolResultMessage({
    required ToolCall toolCall,
    required String result,
  }) =>
      {
        'role': 'user',
        'content': [
          {
            'type': 'tool_result',
            'tool_use_id': toolCall.id,
            'content': result,
          }
        ],
      };
}
