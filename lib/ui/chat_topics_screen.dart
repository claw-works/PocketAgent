import 'package:flutter/material.dart';
import 'theme.dart';
import 'chat_detail_screen.dart';

class ChatTopicsScreen extends StatelessWidget {
  const ChatTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = _demoTopics();
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
              child:
                  const Icon(Icons.add, size: 18, color: Colors.white),
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

  Widget _list(BuildContext context, List<_Topic> topics) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (_, i) => _topicTile(context, topics[i]),
    );
  }

  Widget _topicTile(BuildContext context, _Topic t) {
    return GestureDetector(
      onTap: () => _openChat(context, t.title),
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
              child: Icon(t.icon, size: 22, color: PAColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: PAColors.textPrimary)),
                      Text(t.time,
                          style: const TextStyle(
                              fontSize: 12, color: PAColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(t.summary,
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
    );
  }

  void _openChat(BuildContext context, String? title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(topicTitle: title),
      ),
    );
  }
}

class _Topic {
  final IconData icon;
  final String title;
  final String summary;
  final String time;
  const _Topic(this.icon, this.title, this.summary, this.time);
}

List<_Topic> _demoTopics() => const [
      _Topic(Icons.wb_sunny_outlined, '北京天气查询',
          '已设置提醒：下午 3:00 ⏰', '刚刚'),
      _Topic(Icons.translate, '翻译一段英文',
          '翻译完成，已复制到剪贴板 📋', '10分钟前'),
      _Topic(Icons.camera_alt_outlined, '拍照识别植物',
          '这是一株银杏树 🌿', '1小时前'),
      _Topic(Icons.calendar_today_outlined, '安排明天日程',
          '已添加 3 个日程到日历 📅', '昨天'),
      _Topic(Icons.terminal, '运行 Python 脚本',
          '脚本执行完成，输出已保存 💾', '昨天'),
    ];
