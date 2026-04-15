import 'package:flutter/material.dart';
import 'theme.dart';
import 'chat_detail_screen.dart';
import '../services/chat_store.dart';

class ChatTopicsScreen extends StatefulWidget {
  const ChatTopicsScreen({super.key});

  @override
  State<ChatTopicsScreen> createState() => _ChatTopicsScreenState();
}

class _ChatTopicsScreenState extends State<ChatTopicsScreen> {
  @override
  void initState() {
    super.initState();
    ChatStore.instance.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    ChatStore.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topics = ChatStore.instance.topics;
    return SafeArea(
      child: Column(
        children: [
          _header(context),
          Expanded(
            child: topics.isEmpty ? _empty() : _list(context, topics),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('PocketAgent 🐾',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: PAColors.textPrimary)),
          GestureDetector(
            onTap: () => _openChat(context, null),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: PAColors.gradientAccent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: PAColors.accentSoft,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                size: 40, color: PAColors.accent),
          ),
          const SizedBox(height: 24),
          const Text('👋 你好，我是 PocketAgent',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: PAColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('你的私人 AI 助手，直接操控你的手机。\n试试跟我说点什么吧！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: PAColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, List<ChatTopic> topics) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (_, i) => _topicTile(context, topics[i]),
    );
  }

  Widget _topicTile(BuildContext context, ChatTopic t) {
    final lastMsg = t.messages.isNotEmpty ? t.messages.last.content : '暂无消息';
    final timeStr = _formatTime(t.updatedAt);

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: PAColors.accent),
      ),
      onDismissed: (_) => ChatStore.instance.delete(t.id),
      child: GestureDetector(
        onTap: () => _openChat(context, t.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PAColors.accentSoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    size: 22, color: PAColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: PAColors.textPrimary)),
                        ),
                        Text(timeStr,
                            style: const TextStyle(
                                fontSize: 12, color: PAColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: PAColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context, String? topicId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(topicId: topicId),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}
