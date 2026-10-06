import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/core/theme/app_theme.dart';
import 'package:noti_history/features/history/domain/saved_notification.dart';
import 'package:noti_history/features/history/presentation/notification_details.dart';
import 'package:noti_history/features/history/presentation/widgets/copy_notification_button.dart';
import 'package:noti_history/features/history/presentation/widgets/notification_card.dart';

import 'support/memory_repository.dart';

void main() {
  testWidgets('Feed labels an image without a clickable preview', (
    tester,
  ) async {
    final repository = MemoryRepository();
    final original = repository.entries.first;
    final item = SavedNotification(
      id: original.id,
      packageName: original.packageName,
      appName: original.appName,
      title: original.title,
      body: '',
      subText: '',
      postedAt: original.postedAt,
      savedAt: original.savedAt,
      hasImage: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationCard(
            item: item,
            repository: repository,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Фотография'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'Details preserve content and copy feedback resets without a snackbar',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final item = SavedNotification(
        id: 1,
        packageName: 'test.app',
        appName: 'Тест',
        title: 'Заголовок',
        body: 'Полный текст\nВторая строка',
        subText: 'Дополнительный текст',
        postedAt: DateTime(2026, 10, 4, 12, 30),
        savedAt: DateTime(2026, 10, 4),
      );
      final repository = MemoryRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showNotificationDetails(context, item, repository),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      for (final text in [
        'Тест',
        'Заголовок',
        'Полный текст\nВторая строка',
        'test.app',
        '04.10.2026 · 12:30',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('Дополнительный текст'), findsNothing);
      await tester.tap(find.text('Перейти'));
      expect(repository.openedNotification, 1);
      final button = find.widgetWithText(FilledButton, 'Скопировать текст');
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(clipboard, 'Заголовок\nПолный текст\nВторая строка');
      expect(find.text('Скопировано'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.widgetWithText(FilledButton, 'Скопировано'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Скопировано'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Скопировать текст'), findsOneWidget);
    },
  );

  testWidgets('Unavailable notification has a disabled open button', (
    tester,
  ) async {
    final repository = MemoryRepository()..notificationAvailable = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showNotificationDetails(
                context,
                repository.entries.first,
                repository,
              ),
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Перейти'),
    );
    expect(button.onPressed, isNull);
    expect(
      find.widgetWithText(FilledButton, 'Скопировать текст'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Closing while clipboard is pending does not update a disposed widget',
    (tester) async {
      final copied = Completer<void>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') await copied.future;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CopyNotificationButton(text: 'Сообщение')),
        ),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      copied.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
