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
  const FocusPage({
    super.key,
    this.taskId,
    this.useQuickStart = false,
    this.useTaskDuration = false,
  });

  final String? taskId;
  final bool useQuickStart;
  final bool useTaskDuration;

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  Timer? _ticker;
  FocusModePreset _selectedPreset = focusModePresets[1];
  String? _selectedTaskId;
  int _customFocusMinutes = 30;
  int _customBreakMinutes = 5;
  bool _focusLockEnabled = false;
  bool _taskDurationStarted = false;

  @override
  void initState() {
    super.initState();
    _selectedTaskId = widget.taskId;
    if (widget.useQuickStart) {
      _selectedPreset = focusModePresets[0];
    }
    if (widget.useTaskDuration && widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startFromTaskIfNeeded();
      });
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(focusTimerProvider.notifier).sync();
      final snapshot = ref.read(focusTimerProvider);
      if (snapshot.status == FocusTimerStatus.focusCompleted) {
        _saveCompleted(snapshot);
      }
    });
  }

  @override
  void didUpdateWidget(covariant FocusPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) {
      _selectedTaskId = widget.taskId;
      _taskDurationStarted = false;
    }
    if (widget.useTaskDuration && widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startFromTaskIfNeeded();
      });
    }
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
    final availableTasks = tasks.where((task) => !task.isCompleted).toList();
    final task = _taskById(tasks, _selectedTaskId);
    final title = timer.isBreak ? '休息一下' : task?.title ?? '自由专注';
    final remaining = timer.remainingAt(DateTime.now());
    final canChangeSetup = timer.status == FocusTimerStatus.idle;
    final taskLaunchWaiting = widget.useTaskDuration &&
        widget.taskId != null &&
        timer.status == FocusTimerStatus.idle &&
        !_taskDurationStarted;
    final statusText = timer.status == FocusTimerStatus.idle
        ? widget.useTaskDuration
            ? '正在读取任务时间'
            : '选择模式后开始'
        : timer.isBreak
            ? '休息中'
            : '专注中';
    final focusLockActive = _focusLockEnabled &&
        timer.isFocus &&
        timer.status != FocusTimerStatus.focusCompleted;

    return AppShell(
      currentIndex: 2,
      navigationLocked: focusLockActive,
      onLockedNavigationAttempt: _showFocusLockMessage,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(statusText)),
                if (focusLockActive)
                  const Chip(
                    avatar: Icon(Icons.lock, size: 18),
                    label: Text('已锁定'),
                  ),
              ],
            ),
            const Spacer(),
            Center(
              child: Text(
                _formatDuration(remaining),
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const Spacer(),
            if (taskLaunchWaiting) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (timer.status == FocusTimerStatus.idle) ...[
              DropdownButtonFormField<String?>(
                initialValue: _selectedTaskId,
                decoration: const InputDecoration(labelText: '关联任务'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('自由专注'),
                  ),
                  for (final task in availableTasks)
                    DropdownMenuItem<String?>(
                      value: task.id,
                      child: Text(task.title),
                    ),
                ],
                onChanged: canChangeSetup
                    ? (value) => setState(() => _selectedTaskId = value)
                    : null,
              ),
              const SizedBox(height: 16),
              SegmentedButton<FocusModePreset>(
                segments: [
                  for (final preset in focusModePresets)
                    ButtonSegment(value: preset, label: Text(preset.label)),
                ],
                selected: {_selectedPreset},
                onSelectionChanged: (value) =>
                    setState(() => _selectedPreset = value.first),
              ),
              if (_selectedPreset.mode == FocusMode.custom) ...[
                const SizedBox(height: 16),
                _MinuteStepper(
                  label: '专注时长',
                  value: _customFocusMinutes,
                  min: 5,
                  max: 180,
                  onChanged: (value) =>
                      setState(() => _customFocusMinutes = value),
                ),
                const SizedBox(height: 8),
                _MinuteStepper(
                  label: '休息时长',
                  value: _customBreakMinutes,
                  min: 0,
                  max: 60,
                  onChanged: (value) =>
                      setState(() => _customBreakMinutes = value),
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _focusLockEnabled,
                onChanged: (value) => setState(() => _focusLockEnabled = value),
                secondary: const Icon(Icons.lock_outline),
                title: const Text('专注锁'),
                subtitle: const Text('开启后，倒计时结束前不能离开、暂停或提前结束。'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _start(_selectedTaskId),
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始专注'),
              ),
            ] else if (timer.isBreak) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(
                        timer.isPaused ? Icons.play_arrow : Icons.pause,
                      ),
                      label: Text(timer.isPaused ? '继续' : '暂停'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _skipBreak,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('跳过休息'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _start(timer.taskId),
                icon: const Icon(Icons.replay),
                label: const Text('开始下一轮'),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: focusLockActive
                          ? _showFocusLockMessage
                          : _togglePause,
                      icon: Icon(
                        focusLockActive
                            ? Icons.lock
                            : timer.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                      ),
                      label: Text(
                        focusLockActive
                            ? '已锁定'
                            : timer.isPaused
                                ? '继续'
                                : '暂停',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: focusLockActive
                          ? _showFocusLockMessage
                          : () => _confirmEarlyFinish(timer),
                      icon: const Icon(Icons.stop),
                      label: Text(focusLockActive ? '已锁定' : '结束专注'),
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
    final focusMinutes = _selectedPreset.mode == FocusMode.custom
        ? _customFocusMinutes
        : _selectedPreset.focusMinutes;
    final breakMinutes = _selectedPreset.mode == FocusMode.custom
        ? _customBreakMinutes
        : _selectedPreset.breakMinutes;
    notifier.controller.start(
      plannedMinutes: focusMinutes,
      breakMinutes: breakMinutes,
      mode: _selectedPreset.mode,
      taskId: taskId,
    );
    notifier.replaceState();
  }

  void _startFromTaskIfNeeded() {
    if (!mounted || _taskDurationStarted || !widget.useTaskDuration) {
      return;
    }
    final currentTimer = ref.read(focusTimerProvider);
    if (currentTimer.status != FocusTimerStatus.idle) {
      _taskDurationStarted = true;
      return;
    }
    final task = _taskById(ref.read(localStoreProvider).tasks, widget.taskId);
    if (task == null || task.isCompleted) {
      return;
    }
    final plannedMinutes =
        (task.estimatedMinutes - task.completedFocusMinutes).clamp(5, 300);
    final breakMinutes = plannedMinutes >= 50 ? 10 : 5;
    final notifier = ref.read(focusTimerProvider.notifier);
    notifier.controller.start(
      plannedMinutes: plannedMinutes,
      breakMinutes: breakMinutes,
      mode: FocusMode.custom,
      taskId: task.id,
    );
    notifier.replaceState();
    setState(() {
      _selectedTaskId = task.id;
      _customFocusMinutes = plannedMinutes;
      _customBreakMinutes = breakMinutes;
      _taskDurationStarted = true;
    });
  }

  void _togglePause() {
    final notifier = ref.read(focusTimerProvider.notifier);
    final timer = ref.read(focusTimerProvider);
    if (timer.isPaused) {
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
    notifier.controller.startBreak(
      breakMinutes: snapshot.breakMinutes,
      mode: snapshot.mode,
      taskId: snapshot.taskId,
    );
    notifier.replaceState();
    if (_focusLockEnabled) {
      setState(() => _focusLockEnabled = false);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已记录 ${snapshot.plannedMinutes} 分钟，进入休息。')),
    );
  }

  void _skipBreak() {
    final notifier = ref.read(focusTimerProvider.notifier);
    notifier.controller.skipBreak();
    notifier.replaceState();
  }

  void _showFocusLockMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('专注锁已开启，倒计时结束前不能离开、暂停或结束。')),
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

class _MinuteStepper extends StatelessWidget {
  const _MinuteStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: '减少',
          onPressed: value <= min ? null : () => onChanged(value - 5),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 72,
          child: Center(child: Text('$value min')),
        ),
        IconButton(
          tooltip: '增加',
          onPressed: value >= max ? null : () => onChanged(value + 5),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
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
