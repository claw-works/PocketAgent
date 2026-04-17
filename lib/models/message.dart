enum MessageRole { user, assistant, system, tool }

class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String? toolName;
  final String? toolCallId;
  final String? imageBase64; // For vision: base64 PNG image

  Message({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.toolName,
    this.toolCallId,
    this.imageBase64,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toOpenAI() {
    if (imageBase64 != null && role == MessageRole.tool) {
      // Tool returned an image — format as vision content
      return {
        'role': 'tool',
        'tool_call_id': toolCallId,
        'content': [
          {'type': 'text', 'text': content},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/png;base64,$imageBase64'},
          },
        ],
      };
    }
    return {
      'role': role == MessageRole.tool ? 'tool' : role.name,
      'content': content,
      if (toolName != null) 'name': toolName,
      if (toolCallId != null && role == MessageRole.tool)
        'tool_call_id': toolCallId,
    };
  }
}
