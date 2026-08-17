import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/date_utils.dart';
import '../../../features/focus/domain/focus_record.dart';
import '../../../shared/widgets/app_shell.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localStoreProvider);
    final now = DateTime.now();
    final todayRecords =
        state.focusRecords.where((record) => isSameDay(record.endTime, now));
    final todayMinutes =
        todayRecords.fold<int>(0, (sum, record) => sum + record.actualMinutes);
    final todayPomodoros =
        todayRecords.where((record) => record.completed).length;
    final completedTasks = state.tasks.where((task) => task.isCompleted).length;
    const dailyGoalMinutes = 120;
    final goalProgress =
        (todayMinutes / dailyGoalMinutes).clamp(0, 1).toDouble();

    final lastSevenDays = List.generate(7, (index) {
      final day = startOfDay(now).subtract(Duration(days: 6 - index));
      final minutes = state.focusRecords
          .where((record) => isSameDay(record.endTime, day))
          .fold<int>(0, (sum, record) => sum + record.actualMinutes);
      return _DailyFocus(day: day, minutes: minutes);
    });
    final maxDayMinutes = lastSevenDays.fold<int>(
      0,
      (max, day) => day.minutes > max ? day.minutes : max,
    );
    final taskMinutes = _minutesByTask(state.focusRecords);

    return AppShell(
      currentIndex: 3,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('统计', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatTile(
                      label: '专注时间', value: formatMinutes(todayMinutes))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(label: '番茄', value: '$todayPomodoros')),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatTile(label: '完成任务', value: '$completedTasks')),
            ],
          ),
          const SizedBox(height: 24),
          Text('今日目标', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: goalProgress),
          const SizedBox(height: 8),
          Text(
            '${formatMinutes(todayMinutes)} / ${formatMinutes(dailyGoalMinutes)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('最近7天', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (maxDayMinutes == 0)
            const _EmptyText('完成一次专注后，这里会显示最近 7 天趋势。')
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxDayMinutes * 1.2).clamp(30, 600).toDouble(),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= lastSevenDays.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child:
                                Text(_weekdayLabel(lastSevenDays[index].day)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < lastSevenDays.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: lastSevenDays[index].minutes.toDouble(),
                            width: 18,
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('任务专注分布', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (taskMinutes.isEmpty)
            const _EmptyText('关联任务完成专注后，这里会按任务汇总时间。')
          else
            for (final entry in taskMinutes.entries)
              ListTile(
                title: Text(
                  state.tasks
                          .where((task) => task.id == entry.key)
                          .firstOrNull
                          ?.title ??
                      '已删除任务',
                ),
                trailing: Text(formatMinutes(entry.value)),
              ),
        ],
      ),
    );
  }
}

class _DailyFocus {
  const _DailyFocus({required this.day, required this.minutes});

  final DateTime day;
  final int minutes;
}

Map<String, int> _minutesByTask(Iterable<FocusRecord> records) {
  final minutesByTask = <String, int>{};
  for (final record in records) {
    final taskId = record.taskId;
    if (taskId == null) {
      continue;
    }
    minutesByTask[taskId] = (minutesByTask[taskId] ?? 0) + record.actualMinutes;
  }
  final entries = minutesByTask.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

String _weekdayLabel(DateTime day) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[day.weekday - 1];
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
