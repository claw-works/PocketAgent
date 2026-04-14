import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';

class OpenAiProvider implements LlmProvider {
  @override
  Future<LlmResponse> call({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) async {
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
      if (tools.isNotEmpty) 'tools': tools,
    });

    final resp = await http.post(
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('OpenAI ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body);
    final msg = data['choices'][0]['message'];
    final calls = (msg['tool_calls'] as List?)
            ?.map((tc) => ToolCall(
                  id: tc['id'],
                  name: tc['function']['name'],
                  arguments: jsonDecode(tc['function']['arguments']),
                ))
            .toList() ??
        [];

    return LlmResponse(
      content: msg['content'],
      toolCalls: calls,
      rawAssistantMessage: Map<String, dynamic>.from(msg),
    );
  }

  @override
  Map<String, dynamic> buildToolResultMessage({
    required ToolCall toolCall,
    required String result,
  }) =>
      {'role': 'tool', 'tool_call_id': toolCall.id, 'content': result};
}
