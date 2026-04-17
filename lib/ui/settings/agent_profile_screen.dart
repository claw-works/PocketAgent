import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'settings_detail_scaffold.dart';
import '../../services/agent_config.dart';
import '../../services/pa_paths.dart';
import '../../services/file_picker.dart';

class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _personaCtrl = TextEditingController();
  String _voiceId = 'alloy';
  double _voiceSpeed = 1.0;

  static const _voices = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'];

  @override
  void initState() {
    super.initState();
    final c = AgentConfig.instance;
    _nameCtrl.text = c.name;
    _personaCtrl.text = c.persona;
    _voiceId = c.voiceId;
    _voiceSpeed = c.voiceSpeed;
  }

  Future<void> _save() async {
    final c = AgentConfig.instance;
    await c.setName(_nameCtrl.text.trim());
    await c.setPersona(_personaCtrl.text.trim());
    await c.setVoiceId(_voiceId);
    await c.setVoiceSpeed(_voiceSpeed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已保存')));
    }
  }

  Future<void> _pickAvatar() async {
    final path = await pickImageFile();
    if (path == null) return;
    // Copy to data dir
    final dataDir = await PAPaths.dataDir;
    final dest = '$dataDir/avatar.png';
    await File(path).copy(dest);
    await AgentConfig.instance.setAvatarPath(dest);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final avatarPath = AgentConfig.instance.avatarPath;
    return SettingsDetailScaffold(title: 'Agent 形象', children: [
      Center(
        child: GestureDetector(
          onTap: _pickAvatar,
          child: Column(children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: PAColors.accentSoft,
                borderRadius: BorderRadius.circular(48),
                image: avatarPath != null && File(avatarPath).existsSync()
                    ? DecorationImage(image: FileImage(File(avatarPath)), fit: BoxFit.cover)
                    : null,
              ),
              child: avatarPath == null || !File(avatarPath).existsSync()
                  ? const Icon(Icons.smart_toy_outlined, size: 48, color: PAColors.accent)
                  : null,
            ),
            const SizedBox(height: 12),
            const Text('点击更换头像', style: TextStyle(fontSize: 13, color: PAColors.textMuted)),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      _section('基本信息'),
      _field(_nameCtrl, '名字', 'Agent 的名字'),
      const SizedBox(height: 8),
      _field(_personaCtrl, '人设 / 性格', '描述 Agent 的性格和风格', maxLines: 3),
      const SizedBox(height: 24),
      _section('语音设置'),
      const SizedBox(height: 8),
      _voiceSelector(),
      const SizedBox(height: 16),
      _speedSlider(),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: _save,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: PAColors.gradientAccent,
            borderRadius: BorderRadius.circular(PARadius.md),
          ),
          child: const Text('保存', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PAColors.textMuted, letterSpacing: 1)),
      );

  Widget _field(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: PAColors.bgSecondary,
        borderRadius: BorderRadius.circular(PARadius.md),
        border: Border.all(color: PAColors.border),
      ),
      child: TextField(
        controller: ctrl, maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: PAColors.textPrimary),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: PAColors.textMuted, fontSize: 13),
          hintText: hint, hintStyle: const TextStyle(color: PAColors.textMuted, fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _voiceSelector() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _voices.map((v) {
        final active = _voiceId == v;
        return GestureDetector(
          onTap: () => setState(() => _voiceId = v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? PAColors.gradientAccent : null,
              color: active ? null : PAColors.bgSecondary,
              borderRadius: BorderRadius.circular(PARadius.pill),
              border: active ? null : Border.all(color: PAColors.border),
            ),
            child: Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: active ? Colors.white : PAColors.textSecondary)),
          ),
        );
      }).toList(),
    );
  }

  Widget _speedSlider() {
    final label = _voiceSpeed == 1.0 ? '正常' : '${_voiceSpeed.toStringAsFixed(1)}x';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: PAColors.bgSecondary, borderRadius: BorderRadius.circular(PARadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('语速', style: TextStyle(fontSize: 15, color: PAColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 13, color: PAColors.textSecondary)),
        ]),
        Slider(value: _voiceSpeed, min: 0.5, max: 2.0, divisions: 6, activeColor: PAColors.accent,
            onChanged: (v) => setState(() => _voiceSpeed = v)),
      ]),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _personaCtrl.dispose();
    super.dispose();
  }
}
