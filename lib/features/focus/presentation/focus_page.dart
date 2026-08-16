import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/app_shell.dart';
import '../application/focus_timer_controller.dart';
import '../application/focus_timer_provider.dart';
import '../domain/focus_mode.dart';
import '../../tasks/domain/task.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key, this.taskId, this.useQuickStart = false});

  final String? taskId;
  final bool useQuickStart;

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  Timer? _ticker;
  FocusModePreset _selectedPreset = focusModePresets[1];

  @override
  void initState() {
    super.initState();
    if (widget.useQuickStart) {
      _selectedPreset = focusModePresets[0];
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(focusTimerProvider.notifier).sync();
      final snapshot = ref.read(focusTimerProvider);
      if (snapshot.status == FocusTimerStatus.completed) {
        _saveCompleted(snapshot);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(focusTimerProvider);
    final tasks = ref.watch(localStoreProvider).tasks;
    final task = _taskById(tasks, widget.taskId);
    final title = task?.title ?? '自由专注';
    final remaining = timer.remainingAt(DateTime.now());

    return AppShell(
      currentIndex: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(timer.status == FocusTimerStatus.idle ? '选择模式后开始' : '专注中'),
            const Spacer(),
            Center(
              child: Text(
                _formatDuration(remaining),
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const Spacer(),
            if (timer.status == FocusTimerStatus.idle) ...[
              SegmentedButton<FocusModePreset>(
                segments: [
                  for (final preset in focusModePresets)
                    ButtonSegment(value: preset, label: Text(preset.label)),
                ],
                selected: {_selectedPreset},
                onSelectionChanged: (value) =>
                    setState(() => _selectedPreset = value.first),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _start(widget.taskId),
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始专注'),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(
                        timer.status == FocusTimerStatus.paused
                            ? Icons.play_arrow
                            : Icons.pause,
                      ),
                      label: Text(
                        timer.status == FocusTimerStatus.paused ? '继续' : '暂停',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _confirmEarlyFinish(timer),
                      icon: const Icon(Icons.stop),
                      label: const Text('结束专注'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _start(String? taskId) {
    final notifier = ref.read(focusTimerProvider.notifier);
    notifier.controller.start(
      plannedMinutes: _selectedPreset.focusMinutes,
      breakMinutes: _selectedPreset.breakMinutes,
      mode: _selectedPreset.mode,
      taskId: taskId,
    );
    notifier.replaceState();
  }

  void _togglePause() {
    final notifier = ref.read(focusTimerProvider.notifier);
    final status = ref.read(focusTimerProvider).status;
    if (status == FocusTimerStatus.paused) {
      notifier.controller.resume();
    } else {
      notifier.controller.pause();
    }
    notifier.replaceState();
  }

  void _saveCompleted(FocusTimerSnapshot snapshot) {
    final notifier = ref.read(focusTimerProvider.notifier);
    final record = notifier.controller.finish(id: createId(), completed: true);
    ref.read(localStoreProvider.notifier).addFocusRecord(record);
    notifier.replaceState();
    if (!mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完成一次专注'),
        content: Text('已记录 ${snapshot.plannedMinutes} 分钟。现在休息 ${snapshot.breakMinutes} 分钟。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('跳过休息'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _start(snapshot.taskId);
            },
            child: const Text('开始下一轮'),
          ),
        ],
      ),
    );
  }

  void _confirmEarlyFinish(FocusTimerSnapshot snapshot) {
    final minutes = snapshot.actualMinutesAt(DateTime.now());
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确定结束本次专注？'),
        content: Text('你已经专注 $minutes 分钟。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续专注'),
          ),
          FilledButton(
            onPressed: () {
              final notifier = ref.read(focusTimerProvider.notifier);
              final record = notifier.controller.finish(
                id: createId(),
                completed: false,
              );
              ref.read(localStoreProvider.notifier).addFocusRecord(record);
              notifier.replaceState();
              Navigator.of(context).pop();
            },
            child: const Text('结束'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

FocusTask? _taskById(Iterable<FocusTask> tasks, String? taskId) {
  if (taskId == null) {
    return null;
  }
  for (final task in tasks) {
    if (task.id == taskId) {
      return task;
    }
  }
  return null;
}
