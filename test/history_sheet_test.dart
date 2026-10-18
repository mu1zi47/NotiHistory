import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/features/history/presentation/widgets/history_sheet.dart';

void main() {
  for (final long in [false, true]) {
    testWidgets(
      'Sheet fits ${long ? "long" : "short"} content and only pulls to dismiss',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showHistorySheet<void>(
                    context,
                    (_) => HistorySheet(
                      header: const Text('Header'),
                      footer: const Text('Footer'),
                      children: [
                        SizedBox(
                          height: long ? 3000 : 60,
                          child: const Text('Body'),
                        ),
                      ],
                    ),
                    enableDrag: false,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final header = find.byKey(const ValueKey('history-sheet-drag-header'));
        final before = tester.getTopLeft(find.text('Header'));
        expect(before.dy, long ? lessThan(60) : greaterThan(500));
        await tester.drag(header, const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Header')), before);
        final viewport = find.byKey(const ValueKey('history-sheet-scroll'));
        final pull = await tester.startGesture(tester.getCenter(viewport));
        await pull.moveBy(const Offset(0, 100));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Header'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Header')).dy,
          greaterThan(before.dy),
        );
        await pull.up();
        await tester.pumpAndSettle();
        expect(find.text('Header'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
