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

  factory FocusTask.fromJson(Map<String, dynamic> json) {
    return FocusTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.values.byName(json['priority'] as String),
      deadline: _dateTimeFromJson(json['deadline']),
      estimatedMinutes: json['estimatedMinutes'] as int,
      completedFocusMinutes: json['completedFocusMinutes'] as int,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'deadline': deadline?.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'completedFocusMinutes': completedFocusMinutes,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String);
}
