import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';
import '../aws/event_stream_decoder.dart';

/// Bedrock provider using Converse / ConverseStream API with Bearer Token auth.
class BedrockProvider implements LlmProvider {
  Map<String, String> _headers(String apiKey) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

  Map<String, dynamic> _buildBody({
    required String model,
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
  }) {
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

    final bedrockMessages = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final converted = _convertMessage(msg);
      if (converted != null) bedrockMessages.add(converted);
    }

    return {
      'system': [{'text': systemPrompt}],
      'messages': bedrockMessages,
      if (bedrockTools.isNotEmpty) 'toolConfig': {'tools': bedrockTools},
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
      Uri.parse('$baseUrl/model/$model/converse'),
      headers: _headers(apiKey),
      body: jsonEncode(_buildBody(model: model, systemPrompt: systemPrompt, messages: messages, tools: tools)),
    );
    if (resp.statusCode != 200) {
      debugPrint('[Bedrock] ❌ converse ${resp.statusCode}: ${resp.body}');
      throw Exception('Bedrock ${resp.statusCode}: ${resp.body}');
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
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/model/$model/converse-stream'),
    )
      ..headers.addAll(_headers(apiKey))
      ..body = jsonEncode(_buildBody(
          model: model, systemPrompt: systemPrompt, messages: messages, tools: tools));

    final streamed = await http.Client().send(request);

    // For non-200, read the full body (may be in stream or empty)
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      debugPrint('[Bedrock] ❌ ${streamed.statusCode}: $body');
      debugPrint('[Bedrock] Request URL: $baseUrl/model/$model/converse-stream');
      throw Exception('Bedrock ${streamed.statusCode}: ${body.isEmpty ? "Empty response body" : body}');
    }

    debugPrint('[Bedrock] ✅ Stream connected');

    final fullContent = StringBuffer();
    final contentBlocks = <Map<String, dynamic>>[];
    final toolCalls = <ToolCall>[];
    String? currentToolId;
    String? currentToolName;
    final currentToolInput = StringBuffer();

    await for (final msg in streamed.stream.transform(const EventStreamDecoder())) {
      final eventType = msg.eventType;
      if (eventType == null) continue;

      final Map<String, dynamic> payload;
      try {
        payload = jsonDecode(msg.payloadString);
      } catch (_) {
        continue;
      }

      switch (eventType) {
        case 'contentBlockStart':
          final start = payload['start'];
          if (start != null && start.containsKey('toolUse')) {
            currentToolId = start['toolUse']['toolUseId'];
            currentToolName = start['toolUse']['name'];
            currentToolInput.clear();
          }
          break;

        case 'contentBlockDelta':
          final delta = payload['delta'];
          if (delta != null) {
            if (delta.containsKey('text')) {
              final text = delta['text'] as String;
              fullContent.write(text);
              onDelta(text);
            } else if (delta.containsKey('toolUse')) {
              currentToolInput.write(delta['toolUse']['input'] ?? '');
            }
          }
          break;

        case 'contentBlockStop':
          if (currentToolId != null) {
            final input = currentToolInput.isEmpty
                ? <String, dynamic>{}
                : jsonDecode(currentToolInput.toString()) as Map<String, dynamic>;
            toolCalls.add(ToolCall(id: currentToolId!, name: currentToolName!, arguments: input));
            contentBlocks.add({'toolUse': {'toolUseId': currentToolId, 'name': currentToolName, 'input': input}});
            currentToolId = null;
            currentToolName = null;
          }
          break;

        case 'messageStop':
          // Stream complete
          break;
      }
    }

    if (fullContent.isNotEmpty) {
      contentBlocks.insert(0, {'text': fullContent.toString()});
    }

    return LlmResponse(
      content: fullContent.isEmpty ? null : fullContent.toString(),
      toolCalls: toolCalls,
      rawAssistantMessage: {'role': 'assistant', 'content': contentBlocks},
    );
  }

  LlmResponse _parseResponse(Map<String, dynamic> data) {
    final contentBlocks = data['output']['message']['content'] as List;
    String? textContent;
    final toolCalls = <ToolCall>[];
    for (final block in contentBlocks) {
      if (block.containsKey('text')) {
        textContent = (textContent ?? '') + block['text'];
      } else if (block.containsKey('toolUse')) {
        final tu = block['toolUse'];
        toolCalls.add(ToolCall(id: tu['toolUseId'], name: tu['name'], arguments: Map<String, dynamic>.from(tu['input'])));
      }
    }
    return LlmResponse(content: textContent, toolCalls: toolCalls, rawAssistantMessage: {'role': 'assistant', 'content': contentBlocks});
  }

  Map<String, dynamic>? _convertMessage(Map<String, dynamic> msg) {
    final role = msg['role'];
    if (role == 'tool') {
      return {'role': 'user', 'content': [{'toolResult': {'toolUseId': msg['tool_call_id'], 'content': [{'text': msg['content']}]}}]};
    }
    if (role == 'assistant' && msg['content'] is List) return msg;
    final content = msg['content'];
    if (content == null || (content is String && content.isEmpty)) return null;
    return {'role': role, 'content': [{'text': content}]};
  }

  @override
  Map<String, dynamic> buildToolResultMessage({required ToolCall toolCall, required String result}) =>
      {'role': 'user', 'content': [{'toolResult': {'toolUseId': toolCall.id, 'content': [{'text': result}]}}]};
}
