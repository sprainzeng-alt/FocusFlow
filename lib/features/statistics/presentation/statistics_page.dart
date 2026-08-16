import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/date_utils.dart';
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
    final todayPomodoros = todayRecords.where((record) => record.completed).length;
    final completedTasks = state.tasks.where((task) => task.isCompleted).length;

    final lastSeven = List.generate(7, (index) {
      final day = startOfDay(now).subtract(Duration(days: 6 - index));
      return state.focusRecords
          .where((record) => isSameDay(record.endTime, day))
          .fold<int>(0, (sum, record) => sum + record.actualMinutes);
    });

    return AppShell(
      currentIndex: 3,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('统计', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatTile(label: '专注时间', value: formatMinutes(todayMinutes))),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(label: '番茄', value: '$todayPomodoros')),
              const SizedBox(width: 8),
              Expanded(child: _StatTile(label: '完成任务', value: '$completedTasks')),
            ],
          ),
          const SizedBox(height: 24),
          Text('最近7天', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: [
                  for (var index = 0; index < lastSeven.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: lastSeven[index].toDouble(),
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
          for (final task in state.tasks)
            ListTile(
              title: Text(task.title),
              trailing: Text(formatMinutes(task.completedFocusMinutes)),
            ),
        ],
      ),
    );
  }
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
