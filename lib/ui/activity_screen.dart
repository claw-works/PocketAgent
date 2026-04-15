import 'package:flutter/material.dart';
import 'theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _header(),
          Expanded(
              child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _sectionLabel('今天'),
              _item('设置提醒', '已添加提醒：下午 3:00 开会 ⏰', '14:32', true),
              _item('查询天气', '获取北京实时天气：晴 18-26°C 🌤️', '14:30', true),
              _item('复制到剪贴板', '翻译结果已复制到剪贴板 📋', '13:45', true),
              _item('拍照', '调用相机拍摄照片并识别植物 📷', '12:10', true),
              const SizedBox(height: 12),
              _sectionLabel('昨天'),
              _item('写入日历', '添加 3 个日程到系统日历 📅', '22:15', true),
              _item('执行 Termux 脚本', '运行 Python 脚本，输出已保存 💾', '20:30', false),
            ],
          )),
        ],
      ),
    );
  }

  Widget _header() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('操作记录',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PAColors.textPrimary)),
            Icon(Icons.tune, size: 22, color: PAColors.textSecondary),
          ],
        ),
      );

  static Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PAColors.textMuted,
                letterSpacing: 1)),
      );

  static Widget _item(String action, String detail, String time, bool ok) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                  color: ok ? PAColors.success : PAColors.accent,
                  shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(action,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: PAColors.textPrimary)),
                      Text(time,
                          style: const TextStyle(
                              fontSize: 12, color: PAColors.textMuted)),
                    ]),
                const SizedBox(height: 4),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 13, color: PAColors.textSecondary)),
                const SizedBox(height: 4),
                Text(ok ? '✅ 成功' : '⚠️ 超时重试后成功',
                    style: TextStyle(
                        fontSize: 11,
                        color: ok ? PAColors.success : PAColors.accent)),
              ])),
        ]),
      );
}
