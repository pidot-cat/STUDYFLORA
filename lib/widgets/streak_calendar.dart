import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/game_provider.dart';
import 'common.dart';

/// Month calendar that highlights the days the app was used, with the current
/// study streak and the last time the user was active.
class StreakCalendar extends StatefulWidget {
  const StreakCalendar({super.key});
  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  String _lastActiveLabel(GameProvider g) {
    final last = g.lastActiveBeforeToday;
    if (last == null) return 'First day — welcome!';
    final days = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(last).inDays;
    if (days == 1) return 'Last active: yesterday';
    return 'Last active: ${_months[last.month - 1].substring(0, 3)} ${last.day} ($days days ago)';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final g = context.watch<GameProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7; // Sunday-first grid
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    final activeThisMonth = [for (var d = 1; d <= daysInMonth; d++) if (g.isActiveOn(DateTime(_month.year, _month.month, d))) d].length;
    final streak = g.streak;

    return SfCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: c.terracottaSoft, borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.local_fire_department_rounded, color: c.terracotta),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(streak == 1 ? '1-day streak' : '$streak-day streak', style: context.tt.titleMedium),
              Text(_lastActiveLabel(g), style: context.tt.bodySmall),
            ]),
          ),
          StatusBadge(activeThisMonth == 1 ? '1 active day' : '$activeThisMonth active days', tone: Tone.green, dense: true),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _NavBtn(icon: Icons.chevron_left_rounded, onTap: () => _shift(-1)),
          Expanded(
            child: Text('${_months[_month.month - 1]} ${_month.year}',
                textAlign: TextAlign.center, style: context.tt.titleSmall),
          ),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: isCurrentMonth ? null : () => _shift(1)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (final w in _weekdays)
            Expanded(child: Text(w, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.muted))),
        ]),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, box) {
          final cell = box.maxWidth / 7;
          final total = lead + daysInMonth;
          final rows = (total / 7).ceil();
          return SizedBox(
            height: rows * cell * 0.86,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1 / 0.86),
              itemCount: rows * 7,
              itemBuilder: (_, i) {
                final day = i - lead + 1;
                if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
                final date = DateTime(_month.year, _month.month, day);
                final active = g.isActiveOn(date);
                final isToday = date == today;
                final future = date.isAfter(today);
                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: cell * 0.72,
                    height: cell * 0.72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? c.accent : Colors.transparent,
                      border: isToday ? Border.all(color: active ? c.brand : c.accent, width: 2) : null,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: active || isToday ? FontWeight.w700 : FontWeight.w500,
                        color: active ? (context.isDark ? c.onBrand : Colors.white) : (future ? c.muted.withValues(alpha: 0.45) : c.ink),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: c.surfaceAlt, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: onTap == null ? c.line : c.brand),
      ),
    );
  }
}
