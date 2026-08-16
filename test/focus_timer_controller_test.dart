import 'package:focusflow/features/focus/application/focus_timer_controller.dart';
import 'package:focusflow/features/focus/domain/focus_mode.dart';
import 'package:test/test.dart';

void main() {
  test('calculates remaining time from wall clock', () {
    var now = DateTime(2026, 8, 15, 9);
    final controller = FocusTimerController(now: () => now);

    controller.start(
      plannedMinutes: 25,
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
    );
    now = now.add(const Duration(minutes: 10));

    expect(controller.snapshot.remainingAt(now), const Duration(minutes: 15));
  });

  test('pause and resume extend the planned end time', () {
    var now = DateTime(2026, 8, 15, 9);
    final controller = FocusTimerController(now: () => now);

    controller.start(
      plannedMinutes: 25,
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
    );
    now = now.add(const Duration(minutes: 5));
    controller.pause();
    now = now.add(const Duration(minutes: 10));
    controller.resume();

    expect(
      controller.snapshot.plannedEndTime,
      DateTime(2026, 8, 15, 9, 35),
    );
  });

  test('background elapsed time completes timer on refresh', () {
    var now = DateTime(2026, 8, 15, 9);
    final controller = FocusTimerController(now: () => now);

    controller.start(
      plannedMinutes: 25,
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
    );
    now = now.add(const Duration(minutes: 40));

    expect(controller.refresh(), isTrue);
    expect(controller.snapshot.status, FocusTimerStatus.completed);
  });

  test('early finish records actual minutes and incomplete state', () {
    var now = DateTime(2026, 8, 15, 9);
    final controller = FocusTimerController(now: () => now);

    controller.start(
      plannedMinutes: 25,
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
      taskId: 'task-1',
    );
    now = now.add(const Duration(minutes: 17));

    final record = controller.finish(id: 'record-1', completed: false);

    expect(record.taskId, 'task-1');
    expect(record.actualMinutes, 17);
    expect(record.completed, isFalse);
  });

  test('completed finish creates a full focus record', () {
    var now = DateTime(2026, 8, 15, 9);
    final controller = FocusTimerController(now: () => now);

    controller.start(
      plannedMinutes: 25,
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
    );
    now = now.add(const Duration(minutes: 25));

    final record = controller.finish(id: 'record-1', completed: true);

    expect(record.plannedMinutes, 25);
    expect(record.actualMinutes, 25);
    expect(record.completed, isTrue);
    expect(record.mode, FocusMode.pomodoro);
  });
}
