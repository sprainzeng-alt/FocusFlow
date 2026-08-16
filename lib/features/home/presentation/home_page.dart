import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../tasks/domain/task.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localStoreProvider);
    final todayRecords = state.focusRecords
        .where((record) => isSameDay(record.endTime, DateTime.now()))
        .toList();
    final todayMinutes = todayRecords.fold<int>(
      0,
      (sum, record) => sum + record.actualMinutes,
    );
    final completedTasks = state.tasks.where((task) => task.isCompleted).length;
    final nextTask = _firstIncompleteTask(state.tasks);

    return AppShell(
      currentIndex: 0,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('FocusFlow', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          const Text('今天先开始一小步。'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _Metric(label: '今日专注', value: formatMinutes(todayMinutes))),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: '今日任务',
                  value: '$completedTasks / ${state.tasks.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: nextTask == null
                ? null
                : () => context.go('/focus?taskId=${nextTask.id}&quick=true'),
            icon: const Icon(Icons.bolt),
            label: const Text('只学10分钟'),
          ),
          const SizedBox(height: 20),
          Text('正在进行', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (nextTask == null)
            const Text('今天的任务已经清空了。')
          else
            Card(
              child: ListTile(
                title: Text(nextTask.title),
                subtitle: Text(
                  '${nextTask.completedFocusMinutes} / '
                  '${nextTask.estimatedMinutes} min',
                ),
                trailing: FilledButton(
                  onPressed: () => context.go('/focus?taskId=${nextTask.id}'),
                  child: const Text('开始专注'),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text('今日任务', style: Theme.of(context).textTheme.titleLarge),
          for (final task in state.tasks.take(5))
            CheckboxListTile(
              value: task.isCompleted,
              onChanged: (_) =>
                  ref.read(localStoreProvider.notifier).toggleTask(task.id),
              title: Text(task.title),
              subtitle: Text('${task.priority.label} · ${formatMinutes(task.estimatedMinutes)}'),
            ),
          OutlinedButton.icon(
            onPressed: () => context.go('/tasks'),
            icon: const Icon(Icons.add),
            label: const Text('添加任务'),
          ),
        ],
      ),
    );
  }
}

FocusTask? _firstIncompleteTask(Iterable<FocusTask> tasks) {
  for (final task in tasks) {
    if (!task.isCompleted) {
      return task;
    }
  }
  return null;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
