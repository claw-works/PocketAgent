import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';

class AnthropicProvider implements LlmProvider {
  Map<String, String> _headers(String apiKey) => {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      };

  Map<String, dynamic> _body({
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    bool stream = false,
  }) {
    final anthropicTools = tools.map((t) {
      final fn = t['function'] as Map<String, dynamic>;
      return {'name': fn['name'], 'description': fn['description'], 'input_schema': fn['parameters']};
    }).toList();
    return {
      'model': model,
      'max_tokens': 4096,
      'system': systemPrompt,
      'messages': messages.map(_convertMessage).toList(),
      if (anthropicTools.isNotEmpty) 'tools': anthropicTools,
      if (stream) 'stream': true,
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
      Uri.parse('$baseUrl/messages'),
      headers: _headers(apiKey),
      body: jsonEncode(_body(model: model, systemPrompt: systemPrompt, messages: messages, tools: tools)),
    );
    if (resp.statusCode != 200) throw Exception('Anthropic ${resp.statusCode}: ${resp.body}');
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
    final request = http.Request('POST', Uri.parse('$baseUrl/messages'))
      ..headers.addAll(_headers(apiKey))
      ..body = jsonEncode(_body(model: model, systemPrompt: systemPrompt, messages: messages, tools: tools, stream: true));

    final streamed = await http.Client().send(request);
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Anthropic ${streamed.statusCode}: $body');
    }

    final fullContent = StringBuffer();
    final contentBlocks = <Map<String, dynamic>>[];
    final toolCalls = <ToolCall>[];
    // Track current tool_use block being built
    String? currentToolId;
    String? currentToolName;
    final currentToolInput = StringBuffer();

    await for (final chunk in streamed.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (!chunk.startsWith('data: ')) continue;
      final data = jsonDecode(chunk.substring(6));
      final type = data['type'];

      if (type == 'content_block_start') {
        final block = data['content_block'];
        if (block['type'] == 'tool_use') {
          currentToolId = block['id'];
          currentToolName = block['name'];
          currentToolInput.clear();
        }
      } else if (type == 'content_block_delta') {
        final delta = data['delta'];
        if (delta['type'] == 'text_delta') {
          final text = delta['text'] as String;
          fullContent.write(text);
          onDelta(text);
        } else if (delta['type'] == 'input_json_delta') {
          currentToolInput.write(delta['partial_json']);
        }
      } else if (type == 'content_block_stop') {
        if (currentToolId != null) {
          toolCalls.add(ToolCall(
            id: currentToolId!,
            name: currentToolName!,
            arguments: currentToolInput.isEmpty ? {} : jsonDecode(currentToolInput.toString()),
          ));
          contentBlocks.add({'type': 'tool_use', 'id': currentToolId, 'name': currentToolName, 'input': currentToolInput.isEmpty ? {} : jsonDecode(currentToolInput.toString())});
          currentToolId = null;
          currentToolName = null;
        } else if (fullContent.isNotEmpty) {
          contentBlocks.add({'type': 'text', 'text': fullContent.toString()});
        }
      }
    }

    if (contentBlocks.isEmpty && fullContent.isNotEmpty) {
      contentBlocks.add({'type': 'text', 'text': fullContent.toString()});
    }

    return LlmResponse(
      content: fullContent.isEmpty ? null : fullContent.toString(),
      toolCalls: toolCalls,
      rawAssistantMessage: {'role': 'assistant', 'content': contentBlocks},
    );
  }

  LlmResponse _parseResponse(Map<String, dynamic> data) {
    final content = data['content'] as List;
    String? textContent;
    final toolCalls = <ToolCall>[];
    for (final block in content) {
      if (block['type'] == 'text') {
        textContent = (textContent ?? '') + block['text'];
      } else if (block['type'] == 'tool_use') {
        toolCalls.add(ToolCall(id: block['id'], name: block['name'], arguments: Map<String, dynamic>.from(block['input'])));
      }
    }
    return LlmResponse(content: textContent, toolCalls: toolCalls, rawAssistantMessage: {'role': 'assistant', 'content': content});
  }

  Map<String, dynamic> _convertMessage(Map<String, dynamic> msg) {
    final role = msg['role'];
    if (role == 'tool') {
      return {
        'role': 'user',
        'content': [{'type': 'tool_result', 'tool_use_id': msg['tool_call_id'], 'content': msg['content']}],
      };
    }
    if (role == 'assistant' && msg['content'] is List) return msg;
    return {'role': role, 'content': msg['content'] ?? ''};
  }

  @override
  Map<String, dynamic> buildToolResultMessage({required ToolCall toolCall, required String result}) => {
        'role': 'user',
        'content': [{'type': 'tool_result', 'tool_use_id': toolCall.id, 'content': result}],
      };
}
