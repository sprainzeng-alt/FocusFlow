import '../domain/focus_mode.dart';
import '../domain/focus_record.dart';

typedef NowProvider = DateTime Function();

enum FocusTimerStatus {
  idle,
  running,
  paused,
  completed,
}

class FocusTimerSnapshot {
  const FocusTimerSnapshot({
    required this.status,
    required this.startTime,
    required this.plannedEndTime,
    required this.plannedMinutes,
    required this.breakMinutes,
    required this.mode,
    required this.pausedElapsed,
    this.taskId,
    this.pauseStartedAt,
  });

  factory FocusTimerSnapshot.idle() {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return FocusTimerSnapshot(
      status: FocusTimerStatus.idle,
      startTime: now,
      plannedEndTime: now,
      plannedMinutes: 0,
      breakMinutes: 0,
      mode: FocusMode.pomodoro,
      pausedElapsed: Duration.zero,
    );
  }

  final FocusTimerStatus status;
  final String? taskId;
  final DateTime startTime;
  final DateTime plannedEndTime;
  final DateTime? pauseStartedAt;
  final int plannedMinutes;
  final int breakMinutes;
  final FocusMode mode;
  final Duration pausedElapsed;

  Duration remainingAt(DateTime now) {
    if (status == FocusTimerStatus.idle) {
      return Duration.zero;
    }
    if (status == FocusTimerStatus.paused && pauseStartedAt != null) {
      final remaining = plannedEndTime.difference(pauseStartedAt!);
      return remaining.isNegative ? Duration.zero : remaining;
    }
    final remaining = plannedEndTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int actualMinutesAt(DateTime now) {
    final end = now.isBefore(startTime) ? startTime : now;
    final elapsed = end.difference(startTime) - pausedElapsed;
    return elapsed.inMinutes.clamp(0, plannedMinutes).toInt();
  }

  FocusTimerSnapshot copyWith({
    FocusTimerStatus? status,
    String? taskId,
    DateTime? startTime,
    DateTime? plannedEndTime,
    DateTime? pauseStartedAt,
    bool clearPauseStartedAt = false,
    int? plannedMinutes,
    int? breakMinutes,
    FocusMode? mode,
    Duration? pausedElapsed,
  }) {
    return FocusTimerSnapshot(
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      plannedEndTime: plannedEndTime ?? this.plannedEndTime,
      pauseStartedAt:
          clearPauseStartedAt ? null : pauseStartedAt ?? this.pauseStartedAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      mode: mode ?? this.mode,
      pausedElapsed: pausedElapsed ?? this.pausedElapsed,
    );
  }
}

class FocusTimerController {
  FocusTimerController({NowProvider? now}) : _now = now ?? DateTime.now;

  final NowProvider _now;
  FocusTimerSnapshot snapshot = FocusTimerSnapshot.idle();

  void start({
    required int plannedMinutes,
    required int breakMinutes,
    required FocusMode mode,
    String? taskId,
  }) {
    final now = _now();
    snapshot = FocusTimerSnapshot(
      status: FocusTimerStatus.running,
      taskId: taskId,
      startTime: now,
      plannedEndTime: now.add(Duration(minutes: plannedMinutes)),
      plannedMinutes: plannedMinutes,
      breakMinutes: breakMinutes,
      mode: mode,
      pausedElapsed: Duration.zero,
    );
  }

  void pause() {
    if (snapshot.status != FocusTimerStatus.running) {
      return;
    }
    snapshot = snapshot.copyWith(
      status: FocusTimerStatus.paused,
      pauseStartedAt: _now(),
    );
  }

  void resume() {
    if (snapshot.status != FocusTimerStatus.paused ||
        snapshot.pauseStartedAt == null) {
      return;
    }
    final now = _now();
    final pauseDuration = now.difference(snapshot.pauseStartedAt!);
    snapshot = snapshot.copyWith(
      status: FocusTimerStatus.running,
      plannedEndTime: snapshot.plannedEndTime.add(pauseDuration),
      pausedElapsed: snapshot.pausedElapsed + pauseDuration,
      clearPauseStartedAt: true,
    );
  }

  bool refresh() {
    if (snapshot.status != FocusTimerStatus.running) {
      return false;
    }
    if (snapshot.remainingAt(_now()) == Duration.zero) {
      snapshot = snapshot.copyWith(status: FocusTimerStatus.completed);
      return true;
    }
    return false;
  }

  FocusRecord finish({
    required String id,
    required bool completed,
  }) {
    final now = _now();
    final actualMinutes = completed
        ? snapshot.plannedMinutes
        : snapshot.actualMinutesAt(now);
    final record = FocusRecord(
      id: id,
      taskId: snapshot.taskId,
      startTime: snapshot.startTime,
      endTime: now,
      plannedMinutes: snapshot.plannedMinutes,
      actualMinutes: actualMinutes,
      completed: completed,
      mode: snapshot.mode,
    );
    snapshot = FocusTimerSnapshot.idle();
    return record;
  }
}
