# FocusFlow Development Instructions

## Project Goal

FocusFlow is a distraction-free productivity and self-discipline app designed primarily for students.

The core experience should help users:

- Start tasks more easily.
- Maintain focus.
- Track real study time.
- Manage daily tasks.
- Reduce unnecessary distractions.

## Tech Stack

- Flutter
- Dart
- Riverpod
- go_router
- Local persistence with shared_preferences for V0.1, replaceable with Drift or Isar later
- fl_chart
- url_launcher

Do not introduce additional packages unless there is a clear technical reason.

## Architecture

Use feature-first project organization.

Keep these concerns separated:

- Presentation/UI
- Application/business logic
- Domain models
- Data persistence

Do not place significant business logic directly inside Flutter widgets.

Avoid unnecessarily complex abstractions.

Prefer readable and maintainable code over premature clean architecture.

## UI

- Chinese first.
- Minimal and low-distraction.
- Student-focused.
- No ads, feeds, social recommendations, or distracting animations.

## Focus Timer Rules

- Timer state must be based on `startTime + plannedDuration`.
- Do not trust `remainingSeconds--` as the source of truth.
- The UI may tick once per second, but each tick must recalculate remaining time from `DateTime.now()`.
- Early exits should save a real focus record with `completed = false`.
- Never shame the user for stopping early.

## Verification

After implementation changes, run:

- `flutter analyze`
- `flutter test`

If Flutter is not installed in the current environment, state that clearly and run any available non-Flutter checks.
