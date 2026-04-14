import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';

/// Gemini provider using the generateContent API with function calling.
/// Endpoint: https://generativelanguage.googleapis.com
class GeminiProvider implements LlmProvider {
  @override
  Future<LlmResponse> call({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async {
    final geminiTools = tools.isEmpty
        ? null
        : [
            {
              'function_declarations': tools.map((t) {
                final fn = t['function'] as Map<String, dynamic>;
                return {
                  'name': fn['name'],
                  'description': fn['description'],
                  'parameters': fn['parameters'],
                };
              }).toList(),
            }
          ];

    final contents = messages.map(_convertMessage).whereType<Map<String, dynamic>>().toList();

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': systemPrompt}]
      },
      'contents': contents,
      if (geminiTools != null) 'tools': geminiTools,
    });

    final resp = await http.post(
      Uri.parse('$baseUrl/v1beta/models/$model:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('Gemini ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final parts = data['candidates'][0]['content']['parts'] as List;

    String? textContent;
    final toolCalls = <ToolCall>[];

    for (final part in parts) {
      if (part.containsKey('text')) {
        textContent = (textContent ?? '') + part['text'];
      } else if (part.containsKey('functionCall')) {
        final fc = part['functionCall'];
        toolCalls.add(ToolCall(
          id: fc['name'], // Gemini uses function name as ID
          name: fc['name'],
          arguments: Map<String, dynamic>.from(fc['args'] ?? {}),
        ));
      }
    }

    return LlmResponse(
      content: textContent,
      toolCalls: toolCalls,
      rawAssistantMessage: {'role': 'model', 'parts': parts},
    );
  }

  Map<String, dynamic>? _convertMessage(Map<String, dynamic> msg) {
    final role = msg['role'];
    if (role == 'tool') {
      return {
        'role': 'user',
        'parts': [
          {
            'functionResponse': {
              'name': msg['tool_call_id'], // we stored name as id
              'response': {'result': msg['content']},
            }
          }
        ],
      };
    }
    if (role == 'model' && msg['parts'] != null) return msg;
    final geminiRole = (role == 'assistant') ? 'model' : 'user';
    final content = msg['content'];
    if (content == null || (content is String && content.isEmpty)) return null;
    return {
      'role': geminiRole,
      'parts': [{'text': content}],
    };
  }

  @override
  Map<String, dynamic> buildToolResultMessage({
    required ToolCall toolCall,
    required String result,
  }) =>
      {
        'role': 'user',
        'parts': [
          {
            'functionResponse': {
              'name': toolCall.name,
              'response': {'result': result},
            }
          }
        ],
        // Store for _convertMessage passthrough
        'tool_call_id': toolCall.name,
      };
}
