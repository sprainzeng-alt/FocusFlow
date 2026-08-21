import 'package:focusflow/features/focus/application/focus_timer_controller.dart';
import 'package:focusflow/features/focus/application/focus_timer_provider.dart';
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

  test('start creates an explicit focus running state', () {
    final controller = FocusTimerController();

    controller.start(
      plannedMinutes: 25,
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
    );

    expect(controller.snapshot.status, FocusTimerStatus.focusRunning);
    expect(controller.snapshot.isFocus, isTrue);
    expect(controller.snapshot.isBreak, isFalse);
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
    expect(controller.snapshot.status, FocusTimerStatus.focusPaused);
    now = now.add(const Duration(minutes: 10));
    controller.resume();

    expect(controller.snapshot.status, FocusTimerStatus.focusRunning);
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
    expect(controller.snapshot.status, FocusTimerStatus.focusCompleted);
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

  test('starts a break timer after a completed focus record', () {
    var now = DateTime(2026, 8, 15, 9);
    final controller = FocusTimerController(now: () => now);

    controller.start(
      plannedMinutes: 25,
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
      taskId: 'task-1',
    );
    now = now.add(const Duration(minutes: 25));
    final record = controller.finish(id: 'record-1', completed: true);
    controller.startBreak(
      breakMinutes: record.mode == FocusMode.pomodoro ? 5 : 0,
      mode: record.mode,
      taskId: record.taskId,
    );

    expect(controller.snapshot.isBreak, isTrue);
    expect(controller.snapshot.status, FocusTimerStatus.breakRunning);
    expect(controller.snapshot.remainingAt(now), const Duration(minutes: 5));
    expect(controller.snapshot.taskId, 'task-1');
  });

  test('break timer returns to idle when elapsed', () {
    var now = DateTime(2026, 8, 15, 9);
    final controller = FocusTimerController(now: () => now);

    controller.startBreak(
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
      taskId: 'task-1',
    );
    now = now.add(const Duration(minutes: 6));

    expect(controller.refresh(), isTrue);
    expect(controller.snapshot.status, FocusTimerStatus.idle);
    expect(controller.snapshot.isBreak, isFalse);
  });

  test('break timer can be skipped', () {
    final controller = FocusTimerController();

    controller.startBreak(
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
      taskId: 'task-1',
    );
    controller.skipBreak();

    expect(controller.snapshot.status, FocusTimerStatus.idle);
  });

  test('pause and resume extend a break timer', () {
    var now = DateTime(2026, 8, 15, 9);
    final controller = FocusTimerController(now: () => now);

    controller.startBreak(
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
      taskId: 'task-1',
    );
    now = now.add(const Duration(minutes: 2));
    controller.pause();
    expect(controller.snapshot.status, FocusTimerStatus.breakPaused);
    now = now.add(const Duration(minutes: 10));
    controller.resume();

    expect(controller.snapshot.isBreak, isTrue);
    expect(controller.snapshot.status, FocusTimerStatus.breakRunning);
    expect(controller.snapshot.plannedEndTime, DateTime(2026, 8, 15, 9, 15));
  });

  test('zero minute break returns to idle', () {
    final controller = FocusTimerController();

    controller.startBreak(
      breakMinutes: 0,
      mode: FocusMode.custom,
      taskId: 'task-1',
    );

    expect(controller.snapshot.status, FocusTimerStatus.idle);
  });

  test('notifier sync publishes a new snapshot for UI refreshes', () {
    final notifier = FocusTimerNotifier();

    notifier.controller.start(
      plannedMinutes: 25,
      breakMinutes: 5,
      mode: FocusMode.pomodoro,
    );
    notifier.replaceState();
    final before = notifier.state;

    notifier.sync();

    expect(identical(notifier.state, before), isFalse);
  });
}
