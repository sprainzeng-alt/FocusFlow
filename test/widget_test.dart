import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/app.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('shows the FocusFlow home dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FocusFlowApp()));
    await tester.pumpAndSettle();

    expect(find.text('FocusFlow'), findsOneWidget);
    expect(find.text('只学10分钟'), findsOneWidget);
    expect(find.text('今日任务'), findsWidgets);
  });
}
