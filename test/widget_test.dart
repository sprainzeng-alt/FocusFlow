import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/app.dart';

void main() {
  testWidgets('shows the FocusFlow home dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FocusFlowApp()));
    await tester.pumpAndSettle();

    expect(find.text('FocusFlow'), findsOneWidget);
    expect(find.text('只学10分钟'), findsOneWidget);
    expect(find.text('今日任务'), findsWidgets);
  });
}
