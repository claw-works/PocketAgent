import 'package:flutter/material.dart';
import 'theme.dart';
import '../services/activity_log.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    ActivityLog.instance.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    ActivityLog.instance.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ActivityLog.instance.entries;
    return SafeArea(
      child: Column(
        children: [
          _header(),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text('暂无操作记录',
                        style: TextStyle(fontSize: 15, color: PAColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      // Group by date
                      final showDate = i == 0 ||
                          !_sameDay(entries[i - 1].time, e.time);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate) _dateLabel(e.time),
                          _item(e),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('操作记录',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: PAColors.textPrimary)),
        ),
      );

  Widget _dateLabel(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (_sameDay(now, dt)) {
      label = '今天';
    } else if (_sameDay(now.subtract(const Duration(days: 1)), dt)) {
      label = '昨天';
    } else {
      label = '${dt.month}/${dt.day}';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PAColors.textMuted,
              letterSpacing: 1)),
    );
  }

  Widget _item(ActivityEntry e) {
    final time =
        '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
                color: e.success ? PAColors.success : PAColors.accent,
                shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(e.action,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: PAColors.textPrimary)),
                    ),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 12, color: PAColors.textMuted)),
                  ]),
              const SizedBox(height: 4),
              Text(e.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: PAColors.textSecondary)),
              const SizedBox(height: 4),
              Text(e.success ? '✅ 成功' : '❌ 失败',
                  style: TextStyle(
                      fontSize: 11,
                      color: e.success ? PAColors.success : PAColors.accent)),
            ])),
      ]),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
