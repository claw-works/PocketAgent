import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/message.dart';
import '../../services/agent_config.dart';
import '../theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isAssistant = message.role == MessageRole.assistant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isAssistant) _avatar(),
          if (isAssistant) const SizedBox(width: 8),
          Flexible(child: _bubble(context, isUser)),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _userIcon(),
        ],
      ),
    );
  }

  Widget _avatar() {
    final path = AgentConfig.instance.avatarPath;
    final hasAvatar = path != null && File(path).existsSync();
    return Container(
      width: 32, height: 32,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: PAColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        image: hasAvatar
            ? DecorationImage(image: FileImage(File(path!)), fit: BoxFit.cover)
            : null,
      ),
      child: hasAvatar ? null : const Icon(Icons.smart_toy, size: 18, color: PAColors.accent),
    );
  }

  Widget _userIcon() {
    return Container(
      width: 32, height: 32,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        gradient: PAColors.gradientAccent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.person, size: 18, color: Colors.white),
    );
  }

  Widget _bubble(BuildContext context, bool isUser) {
    return Container(
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
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
              '${message.toolName}: ${message.content}',
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
                blockquote: const TextStyle(fontSize: 14, color: PAColors.textSecondary, height: 1.5),
                blockquoteDecoration: BoxDecoration(
                  color: PAColors.bgTertiary,
                  borderRadius: BorderRadius.circular(PARadius.sm),
                  border: const Border(left: BorderSide(color: PAColors.accentPurple, width: 3)),
                ),
                blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                code: TextStyle(fontSize: 13, color: PAColors.accentCyan, backgroundColor: PAColors.bgTertiary),
                codeblockDecoration: BoxDecoration(
                  color: PAColors.bgTertiary,
                  borderRadius: BorderRadius.circular(PARadius.sm),
                ),
              ),
            ),
    );
  }
}
