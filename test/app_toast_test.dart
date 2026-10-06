import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noti_history/core/widgets/app_toast.dart';

void main() {
  testWidgets('Custom messages replace one another and dismiss automatically', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const Scaffold();
          },
        ),
      ),
    );
    showAppToast(context, 'История очищена');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('История очищена'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    showAppToast(context, 'Ошибка', error: true);
    await tester.pump();
    expect(find.text('История очищена'), findsNothing);
    expect(find.text('Ошибка'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(find.text('Ошибка'), findsNothing);
  });
}
