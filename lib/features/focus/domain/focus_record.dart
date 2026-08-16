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
}
