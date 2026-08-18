import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/focus/domain/focus_record.dart';
import '../../features/tasks/domain/task.dart';

class LocalStore extends StateNotifier<LocalStoreState> {
  LocalStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync(),
        super(LocalStoreState.seeded()) {
    _load();
  }

  static const _tasksKey = 'focusflow.tasks.v1';
  static const _focusRecordsKey = 'focusflow.focus_records.v1';
  static const _settingsKey = 'focusflow.settings.v1';

  final SharedPreferencesAsync _preferences;

  void upsertTask(FocusTask task) {
    final exists = state.tasks.any((item) => item.id == task.id);
    final tasks = exists
        ? [
            for (final item in state.tasks)
              if (item.id == task.id) task else item,
          ]
        : [...state.tasks, task];
    _setState(state.copyWith(tasks: _sortTasks(tasks)));
  }

  void deleteTask(String taskId) {
    _setState(state.copyWith(
      tasks: state.tasks.where((task) => task.id != taskId).toList(),
    ));
  }

  void toggleTask(String taskId) {
    final tasks = [
      for (final task in state.tasks)
        if (task.id == taskId)
          task.copyWith(isCompleted: !task.isCompleted)
        else
          task,
    ];
    _setState(state.copyWith(tasks: _sortTasks(tasks)));
  }

  void addFocusRecord(FocusRecord record) {
    final tasks = [
      for (final task in state.tasks)
        if (record.taskId == task.id)
          task.copyWith(
            completedFocusMinutes: task.completedFocusMinutes +
                (record.completed
                    ? record.plannedMinutes
                    : record.actualMinutes),
          )
        else
          task,
    ];
    _setState(state.copyWith(
      tasks: _sortTasks(tasks),
      focusRecords: [...state.focusRecords, record],
    ));
  }

  void updateSettings(AppSettings settings) {
    _setState(state.copyWith(settings: settings));
  }

  void recordSearchQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final recentSearches = [
      trimmed,
      for (final item in state.settings.recentSearches)
        if (item != trimmed) item,
    ].take(6).toList();
    updateSettings(state.settings.copyWith(recentSearches: recentSearches));
  }

  void clearRecentSearches() {
    updateSettings(state.settings.copyWith(recentSearches: const []));
  }

  void upsertStudyShortcut(StudyShortcut shortcut) {
    final exists =
        state.settings.studyShortcuts.any((item) => item.id == shortcut.id);
    final shortcuts = exists
        ? [
            for (final item in state.settings.studyShortcuts)
              if (item.id == shortcut.id) shortcut else item,
          ]
        : [shortcut, ...state.settings.studyShortcuts];
    updateSettings(state.settings.copyWith(studyShortcuts: shortcuts));
  }

  void deleteStudyShortcut(String shortcutId) {
    updateSettings(
      state.settings.copyWith(
        studyShortcuts: state.settings.studyShortcuts
            .where((shortcut) => shortcut.id != shortcutId)
            .toList(),
      ),
    );
  }

  void resetLocalData() {
    _setState(LocalStoreState.empty(settings: state.settings));
  }

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'settings': state.settings.toJson(),
      'tasks': state.tasks.map((task) => task.toJson()).toList(),
      'focusRecords':
          state.focusRecords.map((record) => record.toJson()).toList(),
    });
  }

  Future<void> _load() async {
    final tasksJson = await _preferences.getString(_tasksKey);
    final focusRecordsJson = await _preferences.getString(_focusRecordsKey);
    final settingsJson = await _preferences.getString(_settingsKey);
    if (tasksJson == null && focusRecordsJson == null && settingsJson == null) {
      await _persist(state);
      return;
    }

    try {
      final tasks = tasksJson == null
          ? state.tasks
          : (jsonDecode(tasksJson) as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(FocusTask.fromJson)
              .toList();
      final focusRecords = focusRecordsJson == null
          ? state.focusRecords
          : (jsonDecode(focusRecordsJson) as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(FocusRecord.fromJson)
              .toList();
      final settings = settingsJson == null
          ? state.settings
          : AppSettings.fromJson(
              (jsonDecode(settingsJson) as Map<String, dynamic>),
            );
      state = state.copyWith(
        tasks: _sortTasks(tasks),
        focusRecords: focusRecords,
        settings: settings,
        isLoaded: true,
      );
    } on FormatException {
      await _persist(state.copyWith(isLoaded: true));
    } on TypeError {
      await _persist(state.copyWith(isLoaded: true));
    }
  }

  void _setState(LocalStoreState nextState) {
    state = nextState.copyWith(isLoaded: true);
    _persist(state);
  }

  Future<void> _persist(LocalStoreState value) async {
    await _preferences.setString(
      _tasksKey,
      jsonEncode(value.tasks.map((task) => task.toJson()).toList()),
    );
    await _preferences.setString(
      _focusRecordsKey,
      jsonEncode(
        value.focusRecords.map((record) => record.toJson()).toList(),
      ),
    );
    await _preferences.setString(
      _settingsKey,
      jsonEncode(value.settings.toJson()),
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

class AppSettings {
  const AppSettings({
    required this.dailyGoalMinutes,
    required this.recentSearches,
    required this.studyShortcuts,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      dailyGoalMinutes: 120,
      recentSearches: [],
      studyShortcuts: [],
    );
  }

  final int dailyGoalMinutes;
  final List<String> recentSearches;
  final List<StudyShortcut> studyShortcuts;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      dailyGoalMinutes: (json['dailyGoalMinutes'] as int?) ?? 120,
      recentSearches: ((json['recentSearches'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toList(),
      studyShortcuts: ((json['studyShortcuts'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudyShortcut.fromJson)
          .toList(),
    );
  }

  AppSettings copyWith({
    int? dailyGoalMinutes,
    List<String>? recentSearches,
    List<StudyShortcut>? studyShortcuts,
  }) {
    return AppSettings(
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      recentSearches: recentSearches ?? this.recentSearches,
      studyShortcuts: studyShortcuts ?? this.studyShortcuts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyGoalMinutes': dailyGoalMinutes,
      'recentSearches': recentSearches,
      'studyShortcuts':
          studyShortcuts.map((shortcut) => shortcut.toJson()).toList(),
    };
  }
}

class StudyShortcut {
  const StudyShortcut({
    required this.id,
    required this.label,
    required this.url,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String url;
  final DateTime createdAt;

  factory StudyShortcut.fromJson(Map<String, dynamic> json) {
    return StudyShortcut(
      id: json['id'] as String,
      label: json['label'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class LocalStoreState {
  const LocalStoreState({
    required this.tasks,
    required this.focusRecords,
    required this.settings,
    required this.isLoaded,
  });

  factory LocalStoreState.empty({AppSettings? settings}) {
    return LocalStoreState(
      tasks: const [],
      focusRecords: const [],
      settings: settings ?? AppSettings.defaults(),
      isLoaded: true,
    );
  }

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
      settings: AppSettings.defaults(),
      isLoaded: false,
    );
  }

  final List<FocusTask> tasks;
  final List<FocusRecord> focusRecords;
  final AppSettings settings;
  final bool isLoaded;

  LocalStoreState copyWith({
    List<FocusTask>? tasks,
    List<FocusRecord>? focusRecords,
    AppSettings? settings,
    bool? isLoaded,
  }) {
    return LocalStoreState(
      tasks: tasks ?? this.tasks,
      focusRecords: focusRecords ?? this.focusRecords,
      settings: settings ?? this.settings,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

final localStoreProvider =
    StateNotifierProvider<LocalStore, LocalStoreState>((ref) => LocalStore());
