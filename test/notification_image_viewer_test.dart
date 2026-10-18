import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/features/history/presentation/widgets/notification_image_viewer.dart';

import 'support/memory_repository.dart';

void main() {
  testWidgets(
    'Image grows from its left preview and returns to the same bounds',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const source = Rect.fromLTWH(16, 350, 90, 180);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openNotificationImageViewer(
                  context,
                  base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAoAAAAUCAIAAAA7jDsBAAAAFUlEQVR4nGNY0HAAD2IYlR6VppY0AB4GdxCRJqSvAAAAAElFTkSuQmCC',
                  ),
                  MemoryRepository().entries.first,
                  sourceRect: source,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      final flight = find.byKey(const ValueKey('image-viewer-flight'));
      expect(tester.getRect(flight), source);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.getSize(flight).width, greaterThan(source.width));
      expect(tester.getSize(flight).width, lessThan(320));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Закрыть изображение'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(flight).left, closeTo(source.left, 1));
      expect(tester.getRect(flight).width, closeTo(source.width, 1));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationImageViewer), findsNothing);
    },
  );

  testWidgets(
    'Gallery animates zoom, toggles chrome and dismisses only at base scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openNotificationImageViewer(
                  context,
                  base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAoAAAAUCAIAAAA7jDsBAAAAFUlEQVR4nGNY0HAAD2IYlR6VppY0AB4GdxCRJqSvAAAAAElFTkSuQmCC',
                  ),
                  MemoryRepository().entries.first,
                  sourceRect: const Rect.fromLTWH(16, 350, 90, 180),
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Увеличить'), findsNothing);
      expect(find.text('Двойное нажатие — увеличить'), findsNothing);
      final image = find.byType(InteractiveViewer);
      TransformationController transform() =>
          tester.widget<InteractiveViewer>(image).transformationController!;
      final point = tester.getCenter(image);
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(point);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(transform().value.getMaxScaleOnAxis(), greaterThan(1));
      expect(transform().value.getMaxScaleOnAxis(), lessThan(2.5));
      await tester.pumpAndSettle();
      expect(transform().value.getMaxScaleOnAxis(), closeTo(2.5, .01));
      await tester.drag(image, const Offset(0, 180));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationImageViewer), findsOneWidget);
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(transform().value.getMaxScaleOnAxis(), closeTo(1, .01));
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      final chrome = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(chrome.opacity, 0);
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      await tester.drag(image, const Offset(160, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NotificationImageViewer), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationImageViewer), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
