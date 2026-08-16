import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/app_shell.dart';
import '../domain/task.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(localStoreProvider).tasks;
    return AppShell(
      currentIndex: 1,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('添加任务'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('任务', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          for (final task in tasks)
            _TaskCard(
              task: task,
              onStart: () => context.go('/focus?taskId=${task.id}'),
              onEdit: () => _showTaskSheet(context, ref, task: task),
              onDelete: () =>
                  ref.read(localStoreProvider.notifier).deleteTask(task.id),
              onToggle: () =>
                  ref.read(localStoreProvider.notifier).toggleTask(task.id),
            ),
        ],
      ),
    );
  }

  void _showTaskSheet(
    BuildContext context,
    WidgetRef ref, {
    FocusTask? task,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TaskForm(
        task: task,
        onSave: (savedTask) {
          ref.read(localStoreProvider.notifier).upsertTask(savedTask);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final FocusTask task;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(value: task.isCompleted, onChanged: (_) => onToggle()),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(task.priority.label),
              ],
            ),
            if (task.description?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 8),
                child: Text(task.description!),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: LinearProgressIndicator(value: task.progress),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: Text(
                '${task.completedFocusMinutes} / ${task.estimatedMinutes} min'
                '${task.deadline == null ? '' : ' · 今天截止'}',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: '编辑',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
                FilledButton.icon(
                  onPressed: task.isCompleted ? null : onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始专注'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({required this.onSave, this.task});

  final FocusTask? task;
  final ValueChanged<FocusTask> onSave;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late TaskPriority _priority;
  late int _estimatedMinutes;
  bool _todayDeadline = true;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _estimatedMinutes = task?.estimatedMinutes ?? 50;
    _todayDeadline = task?.deadline != null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: '任务名称'),
          ),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: '描述'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TaskPriority>(
            segments: [
              for (final priority in TaskPriority.values)
                ButtonSegment(value: priority, label: Text(priority.label)),
            ],
            selected: {_priority},
            onSelectionChanged: (value) =>
                setState(() => _priority = value.first),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('预计时间'),
              IconButton(
                onPressed: () => setState(() {
                  _estimatedMinutes =
                      (_estimatedMinutes - 5).clamp(5, 300).toInt();
                }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(formatMinutes(_estimatedMinutes)),
              IconButton(
                onPressed: () => setState(() {
                  _estimatedMinutes =
                      (_estimatedMinutes + 5).clamp(5, 300).toInt();
                }),
                icon: const Icon(Icons.add_circle_outline),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('今天截止'),
                selected: _todayDeadline,
                onSelected: (value) => setState(() => _todayDeadline = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (_title.text.trim().isEmpty) {
                return;
              }
              final existing = widget.task;
              widget.onSave(
                FocusTask(
                  id: existing?.id ?? createId(),
                  title: _title.text.trim(),
                  description: _description.text.trim(),
                  priority: _priority,
                  deadline: _todayDeadline ? DateTime.now() : null,
                  estimatedMinutes: _estimatedMinutes,
                  completedFocusMinutes: existing?.completedFocusMinutes ?? 0,
                  isCompleted: existing?.isCompleted ?? false,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                ),
              );
            },
            child: Text(widget.task == null ? '创建任务' : '保存修改'),
          ),
        ],
      ),
    );
  }
}
