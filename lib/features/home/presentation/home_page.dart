import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../tasks/domain/task.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final Set<String> _pendingCompletedTaskIds = {};

  Future<void> _toggleTask(FocusTask task) async {
    if (task.isCompleted) {
      ref.read(localStoreProvider.notifier).toggleTask(task.id);
      return;
    }

    setState(() => _pendingCompletedTaskIds.add(task.id));
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }
    ref.read(localStoreProvider.notifier).toggleTask(task.id);
    setState(() => _pendingCompletedTaskIds.remove(task.id));
  }

  @override
  Widget build(BuildContext context) {
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
    final todayTasks =
        state.tasks.where(_isTodayOrOverdueTask).take(5).toList();

    return AppShell(
      currentIndex: 0,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'FocusFlow',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton(
                tooltip: '设置',
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('今天先开始一小步。'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _Metric(
                      label: '今日专注', value: formatMinutes(todayMinutes))),
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
          if (todayTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('今天没有到期任务，可以从任务页添加一个。'),
            )
          else
            for (final task in todayTasks)
              CheckboxListTile(
                value: task.isCompleted ||
                    _pendingCompletedTaskIds.contains(task.id),
                onChanged: _pendingCompletedTaskIds.contains(task.id)
                    ? null
                    : (_) => _toggleTask(task),
                title: Text(task.title),
                subtitle: Text(
                  '${task.priority.label} · ${formatMinutes(task.estimatedMinutes)}'
                  ' · ${formatDeadline(task.deadline)}',
                ),
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

bool _isTodayOrOverdueTask(FocusTask task) {
  final deadline = task.deadline;
  if (task.isCompleted || deadline == null) {
    return false;
  }
  return !startOfDay(deadline).isAfter(startOfDay(DateTime.now()));
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
