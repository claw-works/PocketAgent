import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/llm_service.dart';
import '../services/tool_registry.dart';
import 'theme.dart';
import 'widgets/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final String? topicTitle;
  const ChatDetailScreen({super.key, this.topicTitle});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _uuid = const Uuid();
  final _messages = <Message>[];
  late final ToolRegistry _tools;
  late final LlmService _llm;
  bool _loading = false;
  bool _voiceOn = true;

  @override
  void initState() {
    super.initState();
    _tools = ToolRegistry();
    _llm = LlmService(tools: _tools);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add(Message(id: _uuid.v4(), role: MessageRole.user, content: text));
      _loading = true;
    });
    _scrollToBottom();
    final reply = await _llm.chat(_messages);
    setState(() {
      _messages.add(Message(id: _uuid.v4(), role: MessageRole.assistant, content: reply));
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _messageList()),
            if (_loading) _loadingIndicator(),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.chevron_left, size: 24, color: PAColors.accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(widget.topicTitle ?? '新对话',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: PAColors.textPrimary)),
          ),
          GestureDetector(
            onTap: () => setState(() => _voiceOn = !_voiceOn),
            child: Row(
              children: [
                const Icon(Icons.volume_up, size: 20, color: PAColors.accent),
                const SizedBox(width: 4),
                const Text('语音',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: PAColors.accent)),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _voiceOn ? PAColors.success : PAColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text('👋 说点什么吧', style: TextStyle(fontSize: 18, color: PAColors.textSecondary)),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => MessageBubble(message: _messages[i]),
    );
  }

  Widget _loadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('思考中...', style: TextStyle(color: PAColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      color: PAColors.bgPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PAColors.bgTertiary,
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(Icons.mic, size: 20, color: PAColors.textPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: PAColors.bgInput,
                borderRadius: BorderRadius.circular(PARadius.pill),
                border: Border.all(color: PAColors.border),
              ),
              child: TextField(
                controller: _inputCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: const TextStyle(fontSize: 15, color: PAColors.textPrimary),
                decoration: const InputDecoration.collapsed(hintText: '跟 AI 说话...', hintStyle: TextStyle(color: PAColors.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: PAColors.gradientAccent,
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(Icons.arrow_upward, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
