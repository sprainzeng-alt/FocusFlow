import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'focus_timer_controller.dart';

class FocusTimerNotifier extends StateNotifier<FocusTimerSnapshot> {
  FocusTimerNotifier() : super(FocusTimerSnapshot.idle()) {
    _controller = FocusTimerController();
  }

  late final FocusTimerController _controller;

  FocusTimerController get controller => _controller;

  void sync() {
    _controller.refresh();
    state = _controller.snapshot;
  }

  void replaceState() {
    state = _controller.snapshot;
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerSnapshot>(
  (ref) => FocusTimerNotifier(),
);
