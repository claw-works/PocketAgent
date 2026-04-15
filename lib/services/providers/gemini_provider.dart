import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';

/// Gemini provider using generateContent / streamGenerateContent API.
class GeminiProvider implements LlmProvider {
  Map<String, dynamic> _buildBody({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) {
    final geminiTools = tools.isEmpty
        ? null
        : [
            {
              'function_declarations': tools.map((t) {
                final fn = t['function'] as Map<String, dynamic>;
                return {'name': fn['name'], 'description': fn['description'], 'parameters': fn['parameters']};
              }).toList(),
            }
          ];

    final contents = messages.map(_convertMessage).whereType<Map<String, dynamic>>().toList();

    return {
      'system_instruction': {'parts': [{'text': systemPrompt}]},
      'contents': contents,
      if (geminiTools != null) 'tools': geminiTools,
    };
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
    final resp = await http.post(
      Uri.parse('$baseUrl/v1beta/models/$model:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_buildBody(systemPrompt: systemPrompt, messages: messages, tools: tools)),
    );
    if (resp.statusCode != 200) throw Exception('Gemini ${resp.statusCode}: ${resp.body}');
    return _parseParts(jsonDecode(resp.body)['candidates'][0]['content']['parts'] as List);
  }

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
    // Gemini streaming: streamGenerateContent?alt=sse returns SSE with JSON chunks
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apiKey'),
    )
      ..headers.addAll({'Content-Type': 'application/json'})
      ..body = jsonEncode(_buildBody(systemPrompt: systemPrompt, messages: messages, tools: tools));

    final streamed = await http.Client().send(request);
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Gemini ${streamed.statusCode}: $body');
    }

    final fullContent = StringBuffer();
    final allParts = <Map<String, dynamic>>[];
    final toolCalls = <ToolCall>[];

    await for (final chunk in streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!chunk.startsWith('data: ')) continue;
      final jsonStr = chunk.substring(6).trim();
      if (jsonStr.isEmpty) continue;

      final Map<String, dynamic> data;
      try {
        data = jsonDecode(jsonStr);
      } catch (_) {
        continue;
      }

      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) continue;

      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null) continue;

      for (final part in parts) {
        if (part.containsKey('text')) {
          final text = part['text'] as String;
          fullContent.write(text);
          onDelta(text);
          allParts.add(Map<String, dynamic>.from(part));
        } else if (part.containsKey('functionCall')) {
          final fc = part['functionCall'];
          toolCalls.add(ToolCall(
            id: fc['name'],
            name: fc['name'],
            arguments: Map<String, dynamic>.from(fc['args'] ?? {}),
          ));
          allParts.add(Map<String, dynamic>.from(part));
        }
      }
    }

    return LlmResponse(
      content: fullContent.isEmpty ? null : fullContent.toString(),
      toolCalls: toolCalls,
      rawAssistantMessage: {'role': 'model', 'parts': allParts},
    );
  }

  LlmResponse _parseParts(List parts) {
    String? textContent;
    final toolCalls = <ToolCall>[];
    for (final part in parts) {
      if (part.containsKey('text')) {
        textContent = (textContent ?? '') + part['text'];
      } else if (part.containsKey('functionCall')) {
        final fc = part['functionCall'];
        toolCalls.add(ToolCall(id: fc['name'], name: fc['name'], arguments: Map<String, dynamic>.from(fc['args'] ?? {})));
      }
    }
    return LlmResponse(content: textContent, toolCalls: toolCalls, rawAssistantMessage: {'role': 'model', 'parts': parts});
  }

  Map<String, dynamic>? _convertMessage(Map<String, dynamic> msg) {
    final role = msg['role'];
    if (role == 'tool') {
      return {'role': 'user', 'parts': [{'functionResponse': {'name': msg['tool_call_id'], 'response': {'result': msg['content']}}}]};
    }
    if (role == 'model' && msg['parts'] != null) return msg;
    final geminiRole = (role == 'assistant') ? 'model' : 'user';
    final content = msg['content'];
    if (content == null || (content is String && content.isEmpty)) return null;
    return {'role': geminiRole, 'parts': [{'text': content}]};
  }

  @override
  Map<String, dynamic> buildToolResultMessage({required ToolCall toolCall, required String result}) => {
        'role': 'user',
        'parts': [{'functionResponse': {'name': toolCall.name, 'response': {'result': result}}}],
        'tool_call_id': toolCall.name,
      };
}
