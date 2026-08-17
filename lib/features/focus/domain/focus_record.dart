import 'focus_mode.dart';

class FocusRecord {
  const FocusRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.completed,
    required this.mode,
    this.taskId,
  });

  final String id;
  final String? taskId;
  final DateTime startTime;
  final DateTime endTime;
  final int plannedMinutes;
  final int actualMinutes;
  final bool completed;
  final FocusMode mode;

  factory FocusRecord.fromJson(Map<String, dynamic> json) {
    return FocusRecord(
      id: json['id'] as String,
      taskId: json['taskId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      plannedMinutes: json['plannedMinutes'] as int,
      actualMinutes: json['actualMinutes'] as int,
      completed: json['completed'] as bool,
      mode: FocusMode.values.byName(json['mode'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'plannedMinutes': plannedMinutes,
      'actualMinutes': actualMinutes,
      'completed': completed,
      'mode': mode.name,
    };
  }
}
