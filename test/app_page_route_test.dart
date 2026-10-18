import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/core/navigation/app_page_route.dart';

void main() {
  testWidgets(
    'System edge drag does not pop before system back, cancellation never pops',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  AppPageRoute<void>(
                    builder: (context) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            AppPageRoute<void>(
                              builder: (_) => const Scaffold(
                                body: Center(child: Text('Third')),
                              ),
                            ),
                          ),
                          child: const Text('Second'),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Root'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Root'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      final edge = await tester.startGesture(const Offset(1, 300));
      await edge.moveBy(const Offset(200, 0));
      await tester.pump();
      await edge.up();
      await tester.pumpAndSettle();
      expect(find.text('Third'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Third'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      final cancelled = await tester.startGesture(const Offset(150, 300));
      await cancelled.moveBy(const Offset(30, 0));
      await tester.pump();
      await cancelled.moveBy(const Offset(160, 0));
      await tester.pump();
      await cancelled.cancel();
      await tester.pumpAndSettle();
      expect(find.text('Third'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Normal opening uses the same transition as MaterialPageRoute', (
    tester,
  ) async {
    Future<Rect> opening(bool custom) async {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Widget screen(BuildContext context) => Scaffold(
                    appBar: AppBar(title: const Text('Target')),
                    body: const Text('Body'),
                  );
                  Navigator.push(
                    context,
                    custom
                        ? AppPageRoute<void>(builder: screen)
                        : MaterialPageRoute<void>(builder: screen),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final rect = tester.getRect(find.text('Target'));
      await tester.pumpAndSettle();
      return rect;
    }

    final material = await opening(false);
    final actual = await opening(true);
    expect(actual.left, closeTo(material.left, .01));
    expect(actual.top, closeTo(material.top, .01));
    expect(actual.width, closeTo(material.width, .01));
    expect(actual.height, closeTo(material.height, .01));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Back swipe starts in the center, follows the finger, cancels or pops',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  AppPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Second')),
                      body: ListView(
                        children: [
                          for (var i = 0; i < 20; i++)
                            ListTile(title: Text('Row $i')),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final short = await tester.startGesture(const Offset(180, 300));
      await short.moveBy(const Offset(25, 0));
      await tester.pump();
      await short.moveBy(const Offset(45, 0));
      await tester.pump();
      expect(tester.getTopLeft(find.text('Second')).dx, greaterThan(70));
      await tester.pump(const Duration(milliseconds: 400));
      await short.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      await tester.timedDragFrom(
        const Offset(180, 300),
        const Offset(220, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
