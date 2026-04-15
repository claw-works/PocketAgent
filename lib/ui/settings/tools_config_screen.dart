import 'package:flutter/material.dart';
import '../widgets/setting_item.dart';
import 'settings_detail_scaffold.dart';

class ToolsConfigScreen extends StatelessWidget {
  const ToolsConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsDetailScaffold(title: '本机工具', children: [
      SettingItem(
          icon: Icons.camera_alt_outlined,
          label: '相机',
          value: '拍照 / 读取照片库 / 图像分析',
          showChevron: false),
      SizedBox(height: 8),
      SettingItem(
          icon: Icons.location_on_outlined,
          label: 'GPS 定位',
          value: '获取当前位置信息',
          showChevron: false),
      SizedBox(height: 8),
      SettingItem(
          icon: Icons.content_paste,
          label: '剪贴板',
          value: '读写剪贴板内容',
          showChevron: false),
      SizedBox(height: 8),
      SettingItem(
          icon: Icons.calendar_today_outlined,
          label: '日历 / 提醒事项',
          value: '读写日历和提醒',
          showChevron: false),
      SizedBox(height: 8),
      SettingItem(
          icon: Icons.notifications_outlined,
          label: '本地通知',
          value: '发送设备通知',
          showChevron: false),
      SizedBox(height: 8),
      SettingItem(
          icon: Icons.language,
          label: '打开网页 / 唤起 App',
          value: '浏览器和应用跳转',
          showChevron: false),
      SizedBox(height: 8),
      SettingItem(
          icon: Icons.mic,
          label: '语音识别 / TTS',
          value: '语音输入和朗读',
          showChevron: false),
      SizedBox(height: 8),
      SettingItem(
          icon: Icons.terminal,
          label: 'Termux 互操作',
          value: 'Android · Linux Shell',
          showChevron: false),
    ]);
  }
}
