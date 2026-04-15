import 'dart:convert';
import 'dart:async';
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
      headers: _headers(apiKey),
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('OpenAI ${resp.statusCode}: ${resp.body}');
    }

    return _parseResponse(jsonDecode(resp.body));
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
    final body = jsonEncode({
      'model': model,
      'stream': true,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
      if (tools.isNotEmpty) 'tools': tools,
    });

    final request = http.Request('POST', Uri.parse('$baseUrl/v1/chat/completions'))
      ..headers.addAll(_headers(apiKey))
      ..body = body;

    final streamed = await http.Client().send(request);
    if (streamed.statusCode != 200) {
      final respBody = await streamed.stream.bytesToString();
      throw Exception('OpenAI ${streamed.statusCode}: $respBody');
    }

    final fullContent = StringBuffer();
    final toolCallsMap = <int, _PartialToolCall>{};

    await for (final chunk in streamed.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (!chunk.startsWith('data: ') || chunk == 'data: [DONE]') continue;
      final data = jsonDecode(chunk.substring(6));
      final delta = data['choices']?[0]?['delta'];
      if (delta == null) continue;

      // Text content
      final content = delta['content'] as String?;
      if (content != null) {
        fullContent.write(content);
        onDelta(content);
      }

      // Tool calls (accumulated across chunks)
      final tcs = delta['tool_calls'] as List?;
      if (tcs != null) {
        for (final tc in tcs) {
          final idx = tc['index'] as int;
          toolCallsMap.putIfAbsent(idx, () => _PartialToolCall());
          final p = toolCallsMap[idx]!;
          if (tc['id'] != null) p.id = tc['id'];
          if (tc['function']?['name'] != null) p.name = tc['function']['name'];
          if (tc['function']?['arguments'] != null) {
            p.arguments.write(tc['function']['arguments']);
          }
        }
      }
    }

    final toolCalls = toolCallsMap.entries.map((e) {
      final p = e.value;
      return ToolCall(
        id: p.id,
        name: p.name,
        arguments: jsonDecode(p.arguments.toString()),
      );
    }).toList();

    final rawMsg = <String, dynamic>{
      'role': 'assistant',
      if (fullContent.isNotEmpty) 'content': fullContent.toString(),
      if (toolCalls.isNotEmpty)
        'tool_calls': toolCalls
            .map((tc) => {
                  'id': tc.id,
                  'type': 'function',
                  'function': {'name': tc.name, 'arguments': jsonEncode(tc.arguments)},
                })
            .toList(),
    };

    return LlmResponse(
      content: fullContent.isEmpty ? null : fullContent.toString(),
      toolCalls: toolCalls,
      rawAssistantMessage: rawMsg,
    );
  }

  @override
  Map<String, dynamic> buildToolResultMessage({
    required ToolCall toolCall,
    required String result,
  }) =>
      {'role': 'tool', 'tool_call_id': toolCall.id, 'content': result};

  Map<String, String> _headers(String apiKey) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

  LlmResponse _parseResponse(Map<String, dynamic> data) {
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
}

class _PartialToolCall {
  String id = '';
  String name = '';
  final arguments = StringBuffer();
}
