import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/focus/domain/focus_record.dart';
import '../../features/tasks/domain/task.dart';

class LocalStore extends StateNotifier<LocalStoreState> {
  LocalStore() : super(LocalStoreState.seeded());

  void upsertTask(FocusTask task) {
    final exists = state.tasks.any((item) => item.id == task.id);
    final tasks = exists
        ? [
            for (final item in state.tasks)
              if (item.id == task.id) task else item,
          ]
        : [...state.tasks, task];
    state = state.copyWith(tasks: _sortTasks(tasks));
  }

  void deleteTask(String taskId) {
    state = state.copyWith(
      tasks: state.tasks.where((task) => task.id != taskId).toList(),
    );
  }

  void toggleTask(String taskId) {
    final tasks = [
      for (final task in state.tasks)
        if (task.id == taskId)
          task.copyWith(isCompleted: !task.isCompleted)
        else
          task,
    ];
    state = state.copyWith(tasks: _sortTasks(tasks));
  }

  void addFocusRecord(FocusRecord record) {
    final tasks = [
      for (final task in state.tasks)
        if (record.taskId == task.id)
          task.copyWith(
            completedFocusMinutes: task.completedFocusMinutes +
                (record.completed ? record.plannedMinutes : record.actualMinutes),
          )
        else
          task,
    ];
    state = state.copyWith(
      tasks: _sortTasks(tasks),
      focusRecords: [...state.focusRecords, record],
    );
  }

  List<FocusTask> _sortTasks(List<FocusTask> tasks) {
    final sorted = [...tasks];
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      final aDeadline = a.deadline;
      final bDeadline = b.deadline;
      if (aDeadline != null && bDeadline != null) {
        return aDeadline.compareTo(bDeadline);
      }
      if (aDeadline != null) {
        return -1;
      }
      if (bDeadline != null) {
        return 1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }
}

class LocalStoreState {
  const LocalStoreState({
    required this.tasks,
    required this.focusRecords,
  });

  factory LocalStoreState.seeded() {
    final now = DateTime.now();
    return LocalStoreState(
      tasks: [
        FocusTask(
          id: 'seed-math',
          title: '数学作业',
          description: '完成今天的函数练习',
          priority: TaskPriority.high,
          deadline: now,
          estimatedMinutes: 60,
          completedFocusMinutes: 25,
          isCompleted: false,
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
        FocusTask(
          id: 'seed-english',
          title: '背英语单词',
          priority: TaskPriority.medium,
          deadline: now,
          estimatedMinutes: 30,
          completedFocusMinutes: 0,
          isCompleted: false,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ],
      focusRecords: const [],
    );
  }

  final List<FocusTask> tasks;
  final List<FocusRecord> focusRecords;

  LocalStoreState copyWith({
    List<FocusTask>? tasks,
    List<FocusRecord>? focusRecords,
  }) {
    return LocalStoreState(
      tasks: tasks ?? this.tasks,
      focusRecords: focusRecords ?? this.focusRecords,
    );
  }
}

final localStoreProvider =
    StateNotifierProvider<LocalStore, LocalStoreState>((ref) => LocalStore());
