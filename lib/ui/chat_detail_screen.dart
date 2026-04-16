import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/llm_service.dart';
import '../services/tool_registry.dart';
import '../services/chat_store.dart';
import '../services/db/database.dart' show ChatTopic;
import 'theme.dart';
import 'widgets/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final String? topicId;
  const ChatDetailScreen({super.key, this.topicId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _uuid = const Uuid();
  late final ToolRegistry _tools;
  late final LlmService _llm;
  late String _topicId;
  String _topicTitle = '新对话';
  List<Message> _messages = [];
  bool _loading = false;
  String _streamingContent = '';
  String _statusText = '';
  final _toolCalls = <_ToolCallEntry>[];
  final _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tools = ToolRegistry();
    _llm = LlmService(tools: _tools);
    _init();
  }

  Future<void> _init() async {
    if (widget.topicId != null) {
      _topicId = widget.topicId!;
      final topic = ChatStore.instance.topics.firstWhere((t) => t.id == _topicId);
      _topicTitle = topic.title;
    } else {
      final topic = await ChatStore.instance.create();
      _topicId = topic.id;
      _topicTitle = topic.title;
    }
    await _loadMessages();
    ChatStore.instance.watchMessages(_topicId).listen((dbMsgs) {
      if (!mounted) return;
      setState(() {
        _messages = dbMsgs.map((m) => Message(
          id: m.id,
          role: MessageRole.values.byName(m.role),
          content: m.content,
          toolName: m.toolName,
          toolCallId: m.toolCallId,
          timestamp: m.createdAt,
        )).toList();
        final topics = ChatStore.instance.topics;
        final t = topics.where((t) => t.id == _topicId).firstOrNull;
        if (t != null) _topicTitle = t.title;
      });
    });
  }

  Future<void> _loadMessages() async {
    final dbMsgs = await ChatStore.instance.getMessages(_topicId);
    setState(() {
      _messages = dbMsgs.map((m) => Message(
        id: m.id,
        role: MessageRole.values.byName(m.role),
        content: m.content,
        toolName: m.toolName,
        toolCallId: m.toolCallId,
        timestamp: m.createdAt,
      )).toList();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _inputCtrl.clear();

    final userMsg = Message(id: _uuid.v4(), role: MessageRole.user, content: text);
    await ChatStore.instance.addMessage(_topicId, userMsg);
    setState(() {
      _loading = true;
      _streamingContent = '';
      _statusText = '';
      _toolCalls.clear();
    });
    _scrollToBottom();

    final reply = await _llm.streamChat(
      _messages,
      onDelta: (delta) {
        setState(() {
          _streamingContent += delta;
          _statusText = '';
        });
        _scrollToBottom();
      },
      onStatus: (status) {
        setState(() => _statusText = status);
        _scrollToBottom();
      },
      onToolCall: (name, args, result, success) async {
        setState(() {
          _toolCalls.add(_ToolCallEntry(name: name, args: args, result: result, success: success));
        });
        // Persist tool call as a tool message
        final toolMsg = Message(
          id: _uuid.v4(),
          role: MessageRole.tool,
          content: result,
          toolName: name,
          toolCallId: name,
        );
        await ChatStore.instance.addMessage(_topicId, toolMsg);
        _scrollToBottom();
      },
    );

    // Save final assistant reply
    final assistantMsg = Message(id: _uuid.v4(), role: MessageRole.assistant, content: reply);
    await ChatStore.instance.addMessage(_topicId, assistantMsg);
    setState(() {
      _loading = false;
      _streamingContent = '';
      _statusText = '';
    });
    _scrollToBottom();
  }

  void _cancel() {
    _llm.cancel();
    setState(() {
      _loading = false;
      _statusText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: SelectionArea(child: _messageList())),
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
            child: Text(_topicTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PAColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _messageList() {
    final items = <Widget>[];

    // Persisted messages
    for (final m in _messages) {
      if (m.role == MessageRole.tool) {
        items.add(_toolResultBubble(m));
      } else {
        items.add(MessageBubble(message: m));
      }
    }

    // Streaming content
    if (_loading && _streamingContent.isNotEmpty) {
      items.add(MessageBubble(
        message: Message(id: 'streaming', role: MessageRole.assistant, content: _streamingContent),
      ));
    }

    // Tool calls in progress
    for (final tc in _toolCalls) {
      items.add(_toolCallBubble(tc));
    }

    // Status
    if (_loading && _statusText.isNotEmpty) {
      items.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: PAColors.accentCyan)),
          const SizedBox(width: 8),
          Text(_statusText, style: const TextStyle(fontSize: 13, color: PAColors.accentCyan)),
        ]),
      ));
    }

    // Initial spinner
    if (_loading && _streamingContent.isEmpty && _statusText.isEmpty && _toolCalls.isEmpty) {
      items.add(const Padding(
        padding: EdgeInsets.all(8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: PAColors.accent)),
          SizedBox(width: 8),
          Text('思考中...', style: TextStyle(color: PAColors.textSecondary)),
        ]),
      ));
    }

    if (items.isEmpty) {
      return const Center(child: Text('👋 说点什么吧', style: TextStyle(fontSize: 18, color: PAColors.textSecondary)));
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _toolCallBubble(_ToolCallEntry tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: PAColors.bgTertiary,
          borderRadius: BorderRadius.circular(PARadius.sm),
          border: Border.all(color: PAColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(tc.success ? Icons.check_circle : Icons.error, size: 14,
                color: tc.success ? PAColors.success : PAColors.accent),
            const SizedBox(width: 6),
            Text('🔧 ${tc.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.accentCyan)),
          ]),
          if (tc.result.length <= 200)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(tc.result, style: const TextStyle(fontSize: 11, color: PAColors.textMuted), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          if (tc.result.length > 200)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${tc.result.substring(0, 200)}...', style: const TextStyle(fontSize: 11, color: PAColors.textMuted)),
            ),
        ]),
      ),
    );
  }

  Widget _toolResultBubble(Message m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: PAColors.bgTertiary,
          borderRadius: BorderRadius.circular(PARadius.sm),
          border: Border.all(color: PAColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.build_outlined, size: 14, color: PAColors.accentCyan),
          const SizedBox(width: 6),
          Expanded(
            child: Text('🔧 ${m.toolName ?? "tool"}: ${m.content.length > 100 ? "${m.content.substring(0, 100)}..." : m.content}',
                style: const TextStyle(fontSize: 12, color: PAColors.textMuted)),
          ),
        ]),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      color: PAColors.bgPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Cancel or mic button
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: _loading ? _cancel : null,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _loading ? PAColors.accent : PAColors.bgTertiary,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Icon(_loading ? Icons.stop : Icons.mic, size: 20,
                    color: _loading ? Colors.white : PAColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: PAColors.bgInput,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PAColors.border),
              ),
              constraints: const BoxConstraints(maxHeight: 150),
              child: KeyboardListener(
                focusNode: _inputFocus,
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed &&
                      !_inputCtrl.value.composing.isValid) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
                  }
                },
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 15, color: PAColors.textPrimary),
                  decoration: const InputDecoration.collapsed(
                      hintText: '跟 AI 说话... (Shift+Enter 换行)',
                      hintStyle: TextStyle(color: PAColors.textMuted)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: _send,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: PAColors.gradientAccent,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Icon(Icons.arrow_upward, size: 20, color: Colors.white),
              ),
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
    _inputFocus.dispose();
    super.dispose();
  }
}

class _ToolCallEntry {
  final String name;
  final Map<String, dynamic> args;
  final String result;
  final bool success;
  _ToolCallEntry({required this.name, required this.args, required this.result, required this.success});
}
