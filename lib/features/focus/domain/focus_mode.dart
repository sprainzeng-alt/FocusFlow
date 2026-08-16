enum FocusMode {
  quick,
  pomodoro,
  deepFocus,
  custom;

  String get label => switch (this) {
        FocusMode.quick => '快速启动',
        FocusMode.pomodoro => '经典番茄',
        FocusMode.deepFocus => '深度专注',
        FocusMode.custom => '自定义',
      };
}

class FocusModePreset {
  const FocusModePreset({
    required this.mode,
    required this.focusMinutes,
    required this.breakMinutes,
  });

  final FocusMode mode;
  final int focusMinutes;
  final int breakMinutes;

  String get label => '${mode.label} $focusMinutes + $breakMinutes';
}

const focusModePresets = [
  FocusModePreset(mode: FocusMode.quick, focusMinutes: 10, breakMinutes: 2),
  FocusModePreset(mode: FocusMode.pomodoro, focusMinutes: 25, breakMinutes: 5),
  FocusModePreset(mode: FocusMode.deepFocus, focusMinutes: 50, breakMinutes: 10),
];
