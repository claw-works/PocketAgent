import 'package:flutter/material.dart';
import 'theme.dart';
import 'chat_detail_screen.dart';
import 'activity_screen.dart';
import 'settings/settings_screen.dart';
import 'widgets/new_chat_picker.dart';
import 'widgets/custom_title_bar.dart';
import '../services/chat_store.dart';
import '../services/db/database.dart' show ChatTopic;
import '../services/skill/harness_model.dart';
import '../services/skill/skill_registry.dart';
import '../services/skill/command_center.dart';

/// 指挥中心虚拟入口标识
const String _commandCenterId = '__command_center__';

/// 主 content 区域显示的视图
enum _MainView { chat, settings, allSkills }

/// Sidebar 面板
enum _SidebarPanel { topics, skills, activity }

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  _MainView _mainView = _MainView.chat;
  String? _selectedTopicId = _commandCenterId;
  HarnessSkill? _pendingSkill;

  _SidebarPanel? _activePanel = _SidebarPanel.topics;
  String _searchQuery = '';
  final _newChatBtnKey = GlobalKey();

  static const double _sidebarWidth = 280;
  static const double _activityBarWidth = 48;

  @override
  void initState() {
    super.initState();
    ChatStore.instance.addListener(_onStoreChanged);
    SkillRegistry.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    ChatStore.instance.removeListener(_onStoreChanged);
    SkillRegistry.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  // 点击 activity bar 图标：激活 → 隐藏；否则 → 切换
  void _togglePanel(_SidebarPanel panel) {
    setState(() {
      _activePanel = _activePanel == panel ? null : panel;
    });
  }

  void _openChatTopic(String topicId) {
    setState(() {
      _mainView = _MainView.chat;
      _selectedTopicId = topicId;
      _pendingSkill = null;
    });
  }

  void _openCommandCenter() {
    setState(() {
      _mainView = _MainView.chat;
      _selectedTopicId = _commandCenterId;
      _pendingSkill = null;
    });
  }

  void _openNewChatWithSkill(HarnessSkill? skill) {
    setState(() {
      _mainView = _MainView.chat;
      _selectedTopicId = null;
      _pendingSkill = skill;
    });
  }

  Future<void> _handleNewChat() async {
    Offset? anchor;
    final ctx = _newChatBtnKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final pos = box.localToGlobal(Offset.zero);
        anchor = Offset(pos.dx, pos.dy + box.size.height + 4);
      }
    }
    final skill = await NewChatPicker.show(context, anchor: anchor);
    if (!mounted) return;
    _openNewChatWithSkill(skill);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PAColors.bgPrimary,
      body: Column(children: [
        _titleBar(),
        Expanded(
          child: Row(children: [
            _activityBar(),
            if (_activePanel != null)
              SizedBox(width: _sidebarWidth, child: _sidebarPanel()),
            Expanded(child: _mainContent()),
          ]),
        ),
      ]),
    );
  }

  Widget _titleBar() {
    return CustomTitleBar(
      leading: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Text(
          'PocketAgent 🐾',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PAColors.textPrimary),
        ),
      ),
      actions: [
        GestureDetector(
          key: _newChatBtnKey,
          onTap: _handleNewChat,
          child: Tooltip(
            message: '新建对话',
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: PAColors.gradientAccent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ============ Activity Bar ============
  Widget _activityBar() {
    return Container(
      width: _activityBarWidth,
      decoration: const BoxDecoration(
        color: PAColors.bgSecondary,
        border: Border(right: BorderSide(color: PAColors.border)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        _activityIcon(
          panel: _SidebarPanel.topics,
          icon: Icons.chat_bubble_outline,
          tooltip: '对话',
        ),
        _activityIcon(
          panel: _SidebarPanel.skills,
          icon: Icons.auto_awesome_outlined,
          tooltip: '助手',
        ),
        _activityIcon(
          panel: _SidebarPanel.activity,
          icon: Icons.receipt_long_outlined,
          tooltip: '操作记录',
        ),
        const Spacer(),
        Tooltip(
          message: 'AI 指挥中心',
          child: GestureDetector(
            onTap: _openCommandCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [PAColors.accent, PAColors.accentPurple],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on, size: 16, color: Colors.white),
            ),
          ),
        ),
        _activityBottomIcon(
          icon: Icons.settings_outlined,
          tooltip: '设置',
          active: _mainView == _MainView.settings,
          onTap: () => setState(() => _mainView = _MainView.settings),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _activityIcon({
    required _SidebarPanel panel,
    required IconData icon,
    required String tooltip,
  }) {
    final active = _activePanel == panel;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _togglePanel(panel),
        child: Container(
          width: _activityBarWidth,
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: active ? PAColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: active ? PAColors.textPrimary : PAColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _activityBottomIcon({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: _activityBarWidth,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: active ? PAColors.textPrimary : PAColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ============ Sidebar Panels ============
  Widget _sidebarPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: PAColors.bgSecondary,
        border: Border(right: BorderSide(color: PAColors.border)),
      ),
      child: switch (_activePanel!) {
        _SidebarPanel.topics => _topicsPanel(),
        _SidebarPanel.skills => _skillsPanel(),
        _SidebarPanel.activity => _activityPanel(),
      },
    );
  }

  Widget _topicsPanel() {
    final allTopics = ChatStore.instance.topics
        .where((t) => t.id != _commandCenterId)
        .toList();
    final topics = _searchQuery.isEmpty
        ? allTopics
        : allTopics
            .where((t) =>
                t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    return Column(children: [
      _panelHeader('对话'),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: _commandCenterCard(),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        child: _searchBox(),
      ),
      Expanded(
        child: topics.isEmpty
            ? Center(
                child: Text(
                  _searchQuery.isEmpty ? '暂无对话' : '无匹配结果',
                  style: const TextStyle(color: PAColors.textMuted, fontSize: 13),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (_, i) => _topicItem(topics[i]),
              ),
      ),
    ]);
  }

  Widget _skillsPanel() {
    final skills = List<HarnessSkill>.from(SkillRegistry.instance.harnessSkills)
      ..sort((a, b) => b.totalRuns.compareTo(a.totalRuns));
    return Column(children: [
      _panelHeader(
        '助手',
        trailing: GestureDetector(
          onTap: () => setState(() => _mainView = _MainView.allSkills),
          child: const Text('全部 →',
              style: TextStyle(
                  fontSize: 11,
                  color: PAColors.accent,
                  fontWeight: FontWeight.w600)),
        ),
      ),
      Expanded(
        child: skills.isEmpty
            ? const Center(
                child: Text('暂无助手',
                    style: TextStyle(color: PAColors.textMuted, fontSize: 13)),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: skills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (_, i) => _skillItem(skills[i]),
              ),
      ),
    ]);
  }

  Widget _activityPanel() {
    return Column(children: [
      _panelHeader('操作记录'),
      const Expanded(child: ActivityScreen()),
    ]);
  }

  Widget _panelHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  color: PAColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: PAColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PAColors.border),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 12, color: PAColors.textPrimary),
        decoration: const InputDecoration(
          isDense: true,
          prefixIcon: Icon(Icons.search, size: 14, color: PAColors.textMuted),
          prefixIconConstraints: BoxConstraints(minWidth: 30, minHeight: 30),
          hintText: '搜索...',
          hintStyle: TextStyle(fontSize: 12, color: PAColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _commandCenterCard() {
    final active =
        _mainView == _MainView.chat && _selectedTopicId == _commandCenterId;
    return GestureDetector(
      onTap: _openCommandCenter,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PAColors.accent.withValues(alpha: 0.2),
                    PAColors.accentPurple.withValues(alpha: 0.2),
                  ],
                )
              : null,
          color: active ? null : PAColors.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? PAColors.accent : PAColors.border),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PAColors.accent, PAColors.accentPurple],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.flash_on, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('指挥中心',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PAColors.textPrimary)),
                Text('路由 · 创建 · 进化',
                    style: TextStyle(fontSize: 10, color: PAColors.textSecondary)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _topicItem(ChatTopic t) {
    final active = _mainView == _MainView.chat && t.id == _selectedTopicId;
    return GestureDetector(
      onTap: () => _openChatTopic(t.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? PAColors.bgTertiary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: PAColors.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                size: 14, color: PAColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                    color: PAColors.textPrimary)),
          ),
        ]),
      ),
    );
  }

  Widget _skillItem(HarnessSkill s) {
    return GestureDetector(
      onTap: () => _openNewChatWithSkill(s),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: PAColors.gradientAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: PAColors.textPrimary)),
                Text(
                  '${s.sops.length} SOP · 进化 ${s.evolutionCount}',
                  style: const TextStyle(fontSize: 10, color: PAColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.play_arrow, size: 14, color: PAColors.textMuted),
        ]),
      ),
    );
  }

  // ============ 主 Content ============
  Widget _mainContent() {
    return switch (_mainView) {
      _MainView.chat => _chatArea(),
      _MainView.settings => _settingsPanel(),
      _MainView.allSkills => _allSkillsPanel(),
    };
  }

  Widget _chatArea() {
    if (_selectedTopicId == _commandCenterId) {
      return ChatDetailScreen(
        key: const ValueKey(_commandCenterId),
        fixedTopicId: _commandCenterId,
        harnessSkill: CommandCenter.build(),
      );
    }
    if (_selectedTopicId != null || _pendingSkill != null) {
      return ChatDetailScreen(
        key: ValueKey(_selectedTopicId ?? _pendingSkill?.name ?? 'new'),
        topicId: _selectedTopicId,
        harnessSkill: _pendingSkill,
      );
    }
    return Container(
      color: PAColors.bgPrimary,
      alignment: Alignment.center,
      child: const Text('选择左侧对话或点击 + 新建',
          style: TextStyle(color: PAColors.textMuted, fontSize: 15)),
    );
  }

  Widget _settingsPanel() {
    return _embeddedPage(
      title: '设置',
      child: const SettingsMainScreen(),
    );
  }

  Widget _allSkillsPanel() {
    return _embeddedPage(
      title: '全部助手',
      child: _AllSkillsBrowser(onPick: _openNewChatWithSkill),
    );
  }

  Widget _embeddedPage({required String title, required Widget child}) {
    return Container(
      color: PAColors.bgPrimary,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: PAColors.border)),
          ),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: PAColors.textPrimary, size: 20),
              onPressed: () => setState(() => _mainView = _MainView.chat),
              tooltip: '返回对话',
            ),
            const SizedBox(width: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PAColors.textPrimary)),
          ]),
        ),
        Expanded(child: child),
      ]),
    );
  }
}

/// 嵌入式全部助手浏览器
class _AllSkillsBrowser extends StatefulWidget {
  final void Function(HarnessSkill) onPick;
  const _AllSkillsBrowser({required this.onPick});

  @override
  State<_AllSkillsBrowser> createState() => _AllSkillsBrowserState();
}

class _AllSkillsBrowserState extends State<_AllSkillsBrowser> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = SkillRegistry.instance.harnessSkills;
    final filtered = _query.isEmpty
        ? all
        : all
            .where((s) =>
                s.displayName.toLowerCase().contains(_query.toLowerCase()) ||
                s.description.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 13, color: PAColors.textPrimary),
          decoration: InputDecoration(
            hintText: '搜索助手...',
            hintStyle: const TextStyle(color: PAColors.textMuted),
            prefixIcon: const Icon(Icons.search, size: 16, color: PAColors.textMuted),
            filled: true,
            fillColor: PAColors.bgInput,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PAColors.border),
            ),
          ),
        ),
      ),
      Expanded(
        child: filtered.isEmpty
            ? const Center(
                child: Text('无匹配助手',
                    style: TextStyle(color: PAColors.textMuted)))
            : GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 150,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _card(filtered[i]),
              ),
      ),
    ]);
  }

  Widget _card(HarnessSkill s) {
    final rate = s.totalRuns > 0 ? '${(s.successRate * 100).toInt()}%' : '新';
    final rateColor = s.totalRuns == 0
        ? PAColors.accent
        : s.successRate > 0.8
            ? PAColors.success
            : PAColors.accent;

    return GestureDetector(
      onTap: () => widget.onPick(s),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: PAColors.gradientCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PAColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: PAColors.gradientAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PAColors.bgPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(rate,
                    style: TextStyle(
                        fontSize: 10,
                        color: rateColor,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(s.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PAColors.textPrimary)),
            if (s.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(s.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: PAColors.textSecondary, height: 1.4)),
            ],
            const Spacer(),
            Text('${s.sops.length} SOP · 进化 ${s.evolutionCount} 次',
                style: const TextStyle(fontSize: 10, color: PAColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
