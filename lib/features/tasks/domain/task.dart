enum TaskPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
        TaskPriority.low => '低',
        TaskPriority.medium => '中',
        TaskPriority.high => '高',
      };
}

class FocusTask {
  const FocusTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.estimatedMinutes,
    required this.completedFocusMinutes,
    required this.isCompleted,
    required this.createdAt,
    this.description,
    this.deadline,
  });

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? deadline;
  final int estimatedMinutes;
  final int completedFocusMinutes;
  final bool isCompleted;
  final DateTime createdAt;

  double get progress {
    if (estimatedMinutes <= 0) {
      return 0;
    }
    return (completedFocusMinutes / estimatedMinutes).clamp(0, 1).toDouble();
  }

  FocusTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? deadline,
    int? estimatedMinutes,
    int? completedFocusMinutes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return FocusTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      completedFocusMinutes:
          completedFocusMinutes ?? this.completedFocusMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
