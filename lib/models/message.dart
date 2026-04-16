enum MessageRole { user, assistant, system, tool }

class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String? toolName;
  final String? toolCallId;

  Message({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.toolName,
    this.toolCallId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toOpenAI() {
    return {
      'role': role == MessageRole.tool ? 'tool' : role.name,
      'content': content,
      if (toolName != null) 'name': toolName,
      if (toolCallId != null && role == MessageRole.tool)
        'tool_call_id': toolCallId,
    };
  }
}
