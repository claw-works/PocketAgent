import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/message.dart';
import '../theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? PAColors.userBubble : PAColors.aiBubble,
          borderRadius: BorderRadius.circular(PARadius.lg).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: isUser ? null : Border.all(color: PAColors.border),
        ),
        child: message.role == MessageRole.tool
            ? Text(
                '🔧 ${message.toolName}: ${message.content}',
                style: const TextStyle(fontSize: 12, color: PAColors.textMuted),
              )
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    color: isUser ? Colors.white : PAColors.textPrimary,
                    height: 1.5,
                  ),
                  code: TextStyle(
                    fontSize: 13,
                    color: PAColors.accentCyan,
                    backgroundColor: PAColors.bgTertiary,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: PAColors.bgTertiary,
                    borderRadius: BorderRadius.circular(PARadius.sm),
                  ),
                ),
              ),
      ),
    );
  }
}
