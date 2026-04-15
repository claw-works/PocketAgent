import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';

/// Bedrock provider using the Converse API with Bearer Token auth.
/// Base URL example: https://bedrock-runtime.us-east-1.amazonaws.com
class BedrockProvider implements LlmProvider {
  @override
  Future<LlmResponse> stream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required void Function(String delta) onDelta,
  }) async {
    // Bedrock converseStream uses event-stream encoding; fallback to non-stream for now
    final resp = await call(apiKey: apiKey, baseUrl: baseUrl, model: model, systemPrompt: systemPrompt, messages: messages, tools: tools);
    if (resp.content != null) onDelta(resp.content!);
    return resp;
  }

  @override
  Future<LlmResponse> call({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async {
    // Convert tools to Bedrock Converse toolConfig
    final bedrockTools = tools.map((t) {
      final fn = t['function'] as Map<String, dynamic>;
      return {
        'toolSpec': {
          'name': fn['name'],
          'description': fn['description'],
          'inputSchema': {'json': fn['parameters']},
        },
      };
    }).toList();

    // Convert messages to Bedrock Converse format
    final bedrockMessages = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final converted = _convertMessage(msg);
      if (converted != null) bedrockMessages.add(converted);
    }

    final body = jsonEncode({
      'modelId': model,
      'system': [
        {'text': systemPrompt}
      ],
      'messages': bedrockMessages,
      if (bedrockTools.isNotEmpty)
        'toolConfig': {'tools': bedrockTools},
    });

    // baseUrl example: https://bedrock-runtime.us-east-1.amazonaws.com
    final resp = await http.post(
      Uri.parse('$baseUrl/model/$model/converse'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Bedrock ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final output = data['output']['message'];
    final contentBlocks = output['content'] as List;

    String? textContent;
    final toolCalls = <ToolCall>[];

    for (final block in contentBlocks) {
      if (block.containsKey('text')) {
        textContent = (textContent ?? '') + block['text'];
      } else if (block.containsKey('toolUse')) {
        final tu = block['toolUse'];
        toolCalls.add(ToolCall(
          id: tu['toolUseId'],
          name: tu['name'],
          arguments: Map<String, dynamic>.from(tu['input']),
        ));
      }
    }

    return LlmResponse(
      content: textContent,
      toolCalls: toolCalls,
      rawAssistantMessage: {'role': 'assistant', 'content': contentBlocks},
    );
  }

  Map<String, dynamic>? _convertMessage(Map<String, dynamic> msg) {
    final role = msg['role'];
    if (role == 'tool') {
      return {
        'role': 'user',
        'content': [
          {
            'toolResult': {
              'toolUseId': msg['tool_call_id'],
              'content': [
                {'text': msg['content']}
              ],
            }
          }
        ],
      };
    }
    if (role == 'assistant' && msg['content'] is List) {
      return msg; // already in Bedrock format
    }
    final content = msg['content'];
    if (content == null || (content is String && content.isEmpty)) return null;
    return {
      'role': role,
      'content': [
        {'text': content}
      ],
    };
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
            'toolResult': {
              'toolUseId': toolCall.id,
              'content': [
                {'text': result}
              ],
            }
          }
        ],
      };
}
