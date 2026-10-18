import 'package:noti_history/core/settings/app_preferences.dart';
import 'package:noti_history/features/history/domain/history_repository.dart';
import 'package:noti_history/features/history/domain/capture_status.dart';
import 'package:noti_history/features/history/domain/saved_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/app.dart';
import 'package:noti_history/core/theme/app_theme.dart';
import 'package:noti_history/features/history/presentation/history_screen.dart';
import 'package:noti_history/features/history/presentation/widgets/period_filter_button.dart';
import 'package:noti_history/features/history/presentation/widgets/swipe_notification_card.dart';
import 'package:noti_history/features/history/presentation/widgets/notification_card.dart';

import 'support/memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final titles = FontLoader(titleFont)
      ..addFont(rootBundle.load('assets/fonts/Exo2.ttf'));
    final body = FontLoader(bodyFont)
      ..addFont(rootBundle.load('assets/fonts/Manrope-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-ExtraBold.ttf'));
    await Future.wait([titles.load(), body.load()]);
  });
  testWidgets(
    'Archive and delete icons have mirrored positions throughout a swipe',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_russianApp(repository: MemoryRepository()));
      await tester.pumpAndSettle();
      final rightRow = find.byKey(const ValueKey('swipe-2'));
      final leftRow = find.byKey(const ValueKey('swipe-1'));
      final rightBounds = tester.getRect(rightRow);
      final leftBounds = tester.getRect(leftRow);
      final right = await tester.startGesture(
        tester.getCenter(rightRow),
        pointer: 1,
      );
      final left = await tester.startGesture(
        tester.getCenter(leftRow),
        pointer: 2,
      );
      Future<void> move(double distance) async {
        await right.moveBy(Offset(distance, 0));
        await left.moveBy(Offset(-distance, 0));
        await tester.pump();
      }

      void mirrored() {
        final archive = find.descendant(
          of: rightRow,
          matching: find.byIcon(Icons.archive_outlined),
        );
        final trash = find.descendant(
          of: leftRow,
          matching: find.byIcon(Icons.delete_outline_rounded),
        );
        expect(
          tester.getCenter(archive).dx - rightBounds.left,
          closeTo(leftBounds.right - tester.getCenter(trash).dx, .01),
        );
      }

      await move(70);
      mirrored();
      await move(30);
      await tester.pump(const Duration(milliseconds: 40));
      mirrored();
      await move(140);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        mirrored();
      }
      await move(-140);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        mirrored();
      }
      await right.cancel();
      await left.cancel();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Archive survives main clear, supports menu archive and restoration',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = MemoryRepository();
      await tester.pumpWidget(_russianApp(repository: repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open-archive')), findsNothing);
      await tester.longPress(find.byKey(const ValueKey('swipe-2')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('notification-action-archive')),
      );
      await tester.pumpAndSettle();
      expect(repo.archivedIds, {2});
      expect(find.text('Аня'), findsNothing);
      await tester.tap(find.byTooltip('Очистить всё'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить всё'));
      await tester.pumpAndSettle();
      expect(repo.entries.single.id, 2);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-archive')));
      await tester.pumpAndSettle();
      expect(find.text('Аня'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);
      final archiveBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(archiveBar.titleSpacing, 0);
      expect(archiveBar.leadingWidth, 48);
      // Free space navigates back, notification rows retain their swipe action.
      await tester.timedDragFrom(
        const Offset(180, 700),
        const Offset(220, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(repo.archivedIds, {2});
      expect(find.byKey(const ValueKey('open-archive')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('open-archive')))
            .style,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('open-archive')));
      await tester.pumpAndSettle();
      await tester.timedDrag(
        find.byKey(const ValueKey('swipe-2')),
        const Offset(210, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(repo.archivedIds, isEmpty);
      expect(find.text('Архив пуст'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open-archive')), findsNothing);
      expect(find.text('Аня'), findsOneWidget);
      await tester.timedDrag(
        find.byKey(const ValueKey('swipe-2')),
        const Offset(210, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-archive')));
      await tester.pumpAndSettle();
      await tester.timedDrag(
        find.byKey(const ValueKey('swipe-2')),
        const Offset(-210, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();
      expect(repo.entries, isEmpty);
      expect(find.text('Архив пуст'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open-archive')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Search, application filtering and full text work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: HistoryScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'КОФЕЙНИ');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(repo.lastSearch, 'КОФЕЙНИ');
    expect(find.text('Аня'), findsOneWidget);
    expect(find.text('Билеты'), findsNothing);
    await tester.tap(find.byTooltip('Закрыть поиск'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Фильтр приложений'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-option-com.mail')));
    await tester.pump();
    await tester.tap(find.text('Применить · 1'));
    await tester.pumpAndSettle();
    expect(repo.lastPackages, {'com.mail'});
    expect(find.text('Аня'), findsNothing);
    await tester.ensureVisible(find.text('Билеты'));
    await tester.tap(find.text('Билеты'));
    await tester.pumpAndSettle();
    expect(find.text('Скопировать текст'), findsOneWidget);
    expect(find.byType(SelectableText), findsWidgets);
  });

  testWidgets('Long press opens a menu and deletes only one notification', (
    tester,
  ) async {
    final repo = MemoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: HistoryScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Аня'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notification-action-delete')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification-action-clearApp')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification-action-disableApp')),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);
    final originalX = tester.getTopLeft(find.text('Аня')).dx;
    final originalHeight = tester
        .getSize(find.byKey(const ValueKey('swipe-2')))
        .height;
    await tester.tap(find.byKey(const ValueKey('notification-action-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(repo.entries.length, 2);
    expect(
      tester.getSize(find.byKey(const ValueKey('swipe-2'))).height,
      originalHeight,
    );
    expect(
      find.byKey(const ValueKey('swipe-delete-background-2')),
      findsOneWidget,
    );
    expect(tester.getTopLeft(find.text('Аня')).dx, lessThan(originalX));
    await tester.pumpAndSettle();
    expect(repo.entries.single.packageName, 'com.mail');
    expect(find.text('Билеты'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Menu disables capture without deleting history and confirms app clear',
    (tester) async {
      const channel = MethodChannel('notihistory/history');
      Map<dynamic, dynamic>? settings;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'setCaptureEnabled') {
              settings = Map<dynamic, dynamic>.from(call.arguments as Map);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final repo = MemoryRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HistoryScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> action(String name) async {
        await tester.longPress(find.text('Аня'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('notification-action-$name')));
        await tester.pumpAndSettle();
      }

      await action('disableApp');
      expect(settings, {'packageName': 'org.telegram', 'enabled': false});
      expect(repo.entries.length, 2);
      await action('clearApp');
      expect(find.text('Удалить уведомления приложения?'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(repo.entries.length, 2);
      await action('clearApp');
      await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
      await tester.pumpAndSettle();
      expect(repo.entries.single.packageName, 'com.mail');
      expect(find.text('Билеты'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'App deletion animates visible rows and restores them on failure',
    (tester) async {
      final repo = FailingAppClearRepository();
      final now = DateTime.now();
      repo.entries.add(
        SavedNotification(
          id: 3,
          packageName: 'org.telegram',
          appName: 'Телеграм',
          title: 'Второе сообщение',
          body: 'Body',
          subText: '',
          postedAt: now,
          savedAt: now,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HistoryScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      final initial = tester.getRect(find.byKey(const ValueKey('swipe-2')));
      Future<void> clearApp() async {
        await tester.longPress(find.text('Аня'));
        await tester.pumpAndSettle();
        expect(find.text('Удалить все уведомления'), findsOneWidget);
        expect(find.text('Отключить сохранение'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('notification-action-clearApp')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
      }

      await clearApp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 60));
      expect(repo.entries.length, 3);
      expect(
        find.byKey(const ValueKey('swipe-delete-background-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('swipe-delete-background-3')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(repo.entries.length, 3);
      expect(tester.getRect(find.byKey(const ValueKey('swipe-2'))), initial);
      expect(
        find.text('Не удалось удалить уведомления. Попробуйте снова.'),
        findsOneWidget,
      );
      repo.fail = false;
      await clearApp();
      await tester.pumpAndSettle();
      expect(repo.entries.single.packageName, 'com.mail');
      expect(find.text('Билеты'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Filtered clear confirms scope and keeps other apps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MemoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: HistoryScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Фильтр приложений'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-option-org.telegram')));
    await tester.pump();
    await tester.tap(find.text('Применить · 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Очистить по фильтру'));
    await tester.pumpAndSettle();
    expect(find.text('Очистить по фильтру?'), findsOneWidget);
    expect(find.text('Удалить всё'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(repo.entries.single.packageName, 'com.mail');
    expect(find.text('Ничего не нашлось'), findsNothing);
    expect(find.text('Фильтр'), findsOneWidget);
    expect(find.text('Билеты'), findsOneWidget);
  });

  testWidgets('Clear requires confirmation and empties history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: HistoryScreen(repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Очистить всё'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    final cancel = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Отмена'),
    );
    final cancelShape =
        cancel.style!.shape!.resolve({})! as RoundedRectangleBorder;
    expect(find.widgetWithText(FilledButton, 'Удалить всё'), findsOneWidget);
    final deleteShape =
        Theme.of(tester.element(find.byType(BottomSheet)))
                .filledButtonTheme
                .style!
                .shape!
                .resolve({})!
            as RoundedRectangleBorder;
    expect(cancelShape.borderRadius, deleteShape.borderRadius);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(repo.clearCalls, 0);
    await tester.tap(find.byTooltip('Очистить всё'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('Удалить всё'));
    await tester.pumpAndSettle();
    expect(repo.clearCalls, 1);
    expect(find.text('Здесь начнётся ваша история'), findsOneWidget);
  });

  testWidgets('Permission guidance fits a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository()..granted = false;
    await tester.pumpWidget(_russianApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Включить сохранение'), findsOneWidget);
  });

  testWidgets('A tap outside the search removes its focus', (tester) async {
    await tester.pumpWidget(_russianApp(repository: MemoryRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.tap(find.text('NotiHistory'));
    await tester.pump();
    expect(editable.focusNode.hasFocus, isFalse);
  });

  testWidgets('Application sheet applies multiple packages', (tester) async {
    final repo = MemoryRepository();
    await tester.pumpWidget(_russianApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Фильтр приложений'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).enableDrag,
      isFalse,
    );
    expect(find.text('Фильтр приложений'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Фильтр приложений'),
        matching: find.byKey(const ValueKey('history-sheet-scroll')),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('history-sheet-viewport')),
      findsOneWidget,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.apps_rounded)).color,
      Colors.white,
    );
    await tester.tap(find.byKey(const ValueKey('filter-option-org.telegram')));
    await tester.pump();
    expect(tester.widget<Icon>(find.byIcon(Icons.apps_rounded)).color, accent);
    await tester.tap(find.byKey(const ValueKey('filter-option-com.mail')));
    await tester.pump();
    expect(find.text('Применить · 2'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Применить · 2'),
        matching: find.byKey(const ValueKey('history-sheet-scroll')),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Применить · 2'));
    await tester.pumpAndSettle();

    expect(repo.lastPackages, {'org.telegram', 'com.mail'});
    expect(find.byType(BottomSheet), findsNothing);
    final count = tester.widget<Text>(
      find.byKey(const ValueKey('action-count-Фильтр приложений')),
    );
    expect(count.data, '2');
  });

  testWidgets(
    'Filter swipes confirm app-wide deletion and reopen after cancel or delete',
    (tester) async {
      final repo = MemoryRepository();
      await tester.pumpWidget(_russianApp(repository: repo));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Фильтр приложений'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('filter-option-org.telegram')),
      );
      await tester.pump();
      final row = find.byKey(const ValueKey('filter-swipe-org.telegram'));
      await tester.drag(row, const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(find.text('Фильтр приложений'), findsNothing);
      expect(find.text('Удалить уведомления приложения?'), findsOneWidget);
      expect(repo.clearCalls, 0);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(find.text('Фильтр приложений'), findsOneWidget);
      expect(find.text('Применить · 1'), findsOneWidget);
      expect(repo.entries.length, 2);
      await tester.drag(row, const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(find.text('Фильтр приложений'), findsNothing);
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(find.text('Фильтр приложений'), findsOneWidget);
      expect(row, findsNothing);
      expect(
        find.byKey(const ValueKey('filter-option-com.mail')),
        findsOneWidget,
      );
      expect(find.text('Показать все'), findsOneWidget);
      expect(repo.entries.single.packageName, 'com.mail');
      expect(repo.clearCalls, 1);
      await tester.tap(find.text('Показать все'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Filter groups apps in one block and long press applies the selected app',
    (tester) async {
      final repo = MemoryRepository();
      await tester.pumpWidget(_russianApp(repository: repo));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Фильтр приложений'));
      await tester.pumpAndSettle();
      final block = find.byKey(const ValueKey('filter-apps-block'));
      expect(block, findsOneWidget);
      expect(
        find.descendant(
          of: block,
          matching: find.byKey(const ValueKey('filter-option-org.telegram')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: block,
          matching: find.byKey(const ValueKey('filter-option-com.mail')),
        ),
        findsOneWidget,
      );
      final telegram = find.byKey(const ValueKey('filter-option-org.telegram'));
      await tester.tap(telegram);
      await tester.pumpAndSettle();
      expect(find.text('Применить · 1'), findsOneWidget);
      await tester.longPress(telegram);
      await tester.pumpAndSettle();
      expect(find.text('Фильтр приложений'), findsNothing);
      expect(repo.lastPackages, {'org.telegram'});
      expect(find.text('Аня'), findsOneWidget);
      expect(find.text('Билеты'), findsNothing);
      await tester.tap(find.byTooltip('Фильтр приложений'));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const ValueKey('filter-option-all')));
      await tester.pumpAndSettle();
      expect(repo.lastPackages, isEmpty);
      expect(find.text('Билеты'), findsOneWidget);
    },
  );

  testWidgets('Purple actions share the period button style', (tester) async {
    final theme = buildAppTheme();
    final filledStyle = theme.filledButtonTheme.style!;

    expect(filledStyle.backgroundColor!.resolve({}), accentSurface);
    expect(filledStyle.foregroundColor!.resolve({}), accent);
    final shape = filledStyle.shape!.resolve({})! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(actionRadius));

    await tester.pumpWidget(_russianApp(repository: MemoryRepository()));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history-bottom-actions')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('app-filter-__all__')), findsNothing);
  });

  testWidgets('Deleting the first row preserves a swipe on the next row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MemoryRepository();
    for (var i = 0; i < repo.entries.length; i++) {
      final item = repo.entries[i];
      repo.entries[i] = SavedNotification(
        id: item.id,
        packageName: item.packageName,
        appName: item.appName,
        title: item.title,
        body: item.body,
        subText: item.subText,
        postedAt: item.postedAt,
        savedAt: DateTime(2026, 10, 17, 12 - i),
      );
    }

    await tester.pumpWidget(_russianApp(repository: repo));
    await tester.pumpAndSettle();
    final first = find.byKey(const ValueKey('swipe-2'));
    final second = find.byKey(const ValueKey('swipe-1'));
    final firstGesture = await tester.startGesture(tester.getCenter(first));
    await firstGesture.moveBy(const Offset(-180, 0));
    await firstGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 50));
    final secondGesture = await tester.startGesture(tester.getCenter(second));
    await secondGesture.moveBy(const Offset(180, 0));
    await tester.pump();
    final state = tester.state(second);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(first, findsNothing);
    expect(tester.state(second), same(state));
    expect(
      find.byKey(const ValueKey('swipe-delete-background-1')),
      findsOneWidget,
    );
    await secondGesture.up();
    await tester.pumpAndSettle();
    expect(repo.entries.single.id, 1);
    expect(repo.archivedIds, {1});
    expect(tester.takeException(), isNull);
  });

  testWidgets('Short swipes reset, left deletes and right archives', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository();
    await tester.pumpWidget(_russianApp(repository: repo));
    await tester.pumpAndSettle();

    final first = find.ancestor(
      of: find.text('Аня'),
      matching: find.byType(SwipeNotificationCard),
    );
    for (final distance in [-70.0, 70.0]) {
      final gesture = await tester.startGesture(tester.getCenter(first));
      await gesture.moveBy(Offset(distance, 0));
      await tester.pump();
      final background = find.byKey(
        const ValueKey('swipe-delete-background-2'),
      );
      expect(background, findsOneWidget);
      expect(
        tester.widget<ColoredBox>(background).color,
        distance < 0 ? const Color(0xFFFBEAEC) : accentSurface,
      );
      expect(
        find.descendant(
          of: background,
          matching: find.byIcon(
            distance < 0
                ? Icons.delete_outline_rounded
                : Icons.archive_outlined,
          ),
        ),
        findsOneWidget,
      );
      final card = tester.widget<NotificationCard>(
        find.descendant(of: first, matching: find.byType(NotificationCard)),
      );
      expect(card.showTopBorder, isFalse);
      expect(card.showBottomBorder, isTrue);
      final iconPosition = find.byKey(
        const ValueKey('swipe-delete-icon-position-2'),
      );
      final region = find.byKey(const ValueKey('swipe-action-region-2'));
      expect(
        tester.widget<Positioned>(iconPosition).left,
        closeTo(distance < 0 ? tester.getSize(region).width - 48 : 20, .1),
      );
      await gesture.moveBy(Offset(distance.sign * 160, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<Positioned>(iconPosition).left,
        closeTo((tester.getSize(region).width - 28) / 2, .1),
      );
      await gesture.moveBy(Offset(-distance.sign * 160, 0));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(background, findsNothing);
      expect(repo.entries.length, 2);
    }
    await tester.timedDrag(
      first,
      const Offset(-20, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(repo.entries.length, 2);
    expect(find.text('Удалить'), findsNothing);
    await tester.timedDrag(
      first,
      const Offset(-150, 0),
      const Duration(milliseconds: 350),
    );
    await tester.pumpAndSettle();
    expect(repo.entries.map((entry) => entry.id), [1]);
    expect(find.text('Аня'), findsNothing);

    final second = find.ancestor(
      of: find.text('Билеты'),
      matching: find.byType(SwipeNotificationCard),
    );
    await tester.timedDrag(
      second,
      const Offset(210, 0),
      const Duration(milliseconds: 450),
    );
    await tester.pumpAndSettle();
    expect(repo.entries.single.id, 1);
    expect(repo.archivedIds, {1});
    expect(find.text('Билеты'), findsNothing);
  });

  testWidgets('Custom pull refresh lowers the feed and returns after loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_russianApp(repository: MemoryRepository()));
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsNothing);
    final first = find.byKey(const ValueKey('swipe-2'));
    final top = tester.getTopLeft(first).dy;
    final gesture = await tester.startGesture(tester.getCenter(first));
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();
    expect(tester.getTopLeft(first).dy, greaterThan(top + 20));
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('custom-refresh-gap'),
              skipOffstage: false,
            ),
          )
          .height,
      greaterThan(64),
    );
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('custom-refresh-gap'),
              skipOffstage: false,
            ),
          )
          .height,
      0,
    );
    expect(tester.getTopLeft(first).dy, closeTo(top, .5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pull refresh can be cancelled by reversing the drag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _RefreshCountingRepository();
    await tester.pumpWidget(_russianApp(repository: repo));
    await tester.pumpAndSettle();
    final calls = repo.statusCalls;
    final first = find.byKey(const ValueKey('swipe-2'));
    final gap = find.byKey(
      const ValueKey('custom-refresh-gap'),
      skipOffstage: false,
    );
    final gesture = await tester.startGesture(tester.getCenter(first));
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();
    expect(tester.getSize(gap).height, greaterThan(64));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(tester.getSize(gap).height, lessThan(64));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(tester.getSize(gap).height, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(repo.statusCalls, calls);
    expect(tester.getSize(gap).height, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toolbar morphs search and period opens in a bottom sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MemoryRepository();
    await tester.pumpWidget(_russianApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Ваша история'), findsNothing);
    expect(find.text('Лента уведомлений'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('Поиск'), findsOneWidget);
    expect(find.byTooltip('Фильтр приложений'), findsOneWidget);
    expect(find.byTooltip('Очистить всё'), findsOneWidget);
    expect(find.text('Поиск'), findsOneWidget);
    expect(find.text('Фильтр'), findsOneWidget);
    expect(find.text('Очистить'), findsOneWidget);
    expect(find.byType(PopupMenuButton<int>), findsNothing);

    final searchRect = tester.getRect(find.byTooltip('Поиск'));
    final filterRect = tester.getRect(find.byTooltip('Фильтр приложений'));
    final clearRect = tester.getRect(find.byTooltip('Очистить всё'));
    final periodRect = tester.getRect(find.byType(PeriodFilterButton));
    expect(filterRect.left - searchRect.right, closeTo(6, .1));
    expect(clearRect.left - filterRect.right, closeTo(6, .1));
    expect(periodRect.left - clearRect.right, closeTo(6, .1));
    expect(searchRect.bottom, periodRect.bottom);

    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Фильтр приложений'), findsNothing);
    expect(find.byTooltip('Очистить всё'), findsNothing);
    expect(find.byType(PeriodFilterButton), findsNothing);
    expect(
      tester.getRect(find.byType(TextField)).width,
      greaterThan(periodRect.right - searchRect.left),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(find.byType(TextField)).dy,
      lessThanOrEqualTo(520),
    );
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Закрыть поиск'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Всё время'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Период уведомлений'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Сегодня'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Сегодня'), findsWidgets);
    final now = DateTime.now();
    expect(
      repo.lastSince,
      DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
    );
    await tester.tap(find.byType(PeriodFilterButton));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      repo.lastSince,
      DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
    );
  });

  testWidgets('Previous day header leaves with its group while scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MemoryRepository();
    final today = DateTime.now();
    final yesterday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
    repo.entries.clear();
    for (var i = 0; i < 20; i++) {
      final date = i == 0 ? today : yesterday;
      repo.entries.add(
        SavedNotification(
          id: 100 - i,
          packageName: 'test',
          appName: 'Test',
          title: 'Notification $i',
          body: 'Body',
          subText: '',
          postedAt: date,
          savedAt: date,
        ),
      );
    }
    await tester.pumpWidget(_russianApp(repository: repo));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('day-header-Сегодня')).hitTestable(),
      findsOneWidget,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('day-header-Сегодня')).hitTestable(),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('day-header-outline')), findsNothing);
    expect(
      find.byKey(const ValueKey('day-header-Вчера')).hitTestable(),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('day-header-Вчера'))).dy,
      closeTo(64, 1),
    );
    expect(find.text('NotiHistory').hitTestable(), findsOneWidget);
    final feed = find.byType(CustomScrollView);
    final scroll = tester.widget<CustomScrollView>(feed).controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Вчера'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('swipe-99'))).dy,
      closeTo(106, 1),
    );
    expect(scroll.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Up button and app bar return to the start without blocking settings',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = MemoryRepository();
      final now = DateTime.now();
      repo.entries.clear();
      for (var i = 0; i < 20; i++) {
        repo.entries.add(
          SavedNotification(
            id: 100 - i,
            packageName: 'test',
            appName: 'Test',
            title: 'Notification $i',
            body: 'Body',
            subText: '',
            postedAt: now,
            savedAt: now,
          ),
        );
      }
      await tester.pumpWidget(_russianApp(repository: repo));
      await tester.pumpAndSettle();
      final up = find.byKey(const ValueKey('scroll-to-top'));
      final feed = find.byType(CustomScrollView);
      final scroll = tester.widget<CustomScrollView>(feed).controller!;
      expect(up.hitTestable(), findsNothing);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(up.hitTestable(), findsNothing);
      final viewport = tester.getRect(feed);
      expect(
        tester.getBottomLeft(find.byKey(const ValueKey('swipe-81'))).dy,
        closeTo(viewport.bottom, 1),
      );
      final lastCard = tester.widget<NotificationCard>(
        find.descendant(
          of: find.byKey(const ValueKey('swipe-81')),
          matching: find.byType(NotificationCard),
        ),
      );
      expect(lastCard.showBottomBorder, isFalse);
      scroll.jumpTo(scroll.position.maxScrollExtent - 60);
      await tester.pumpAndSettle();
      expect(up.hitTestable(), findsOneWidget);
      final button = tester.getRect(up);
      expect(viewport.right - 16 - button.right, closeTo(8, .1));
      expect(viewport.bottom - button.bottom, closeTo(8, .1));
      expect(
        scroll.offset,
        greaterThan(scroll.position.viewportDimension * 1.5),
      );
      await tester.tap(up);
      await tester.pump();
      expect(
        scroll.offset,
        lessThanOrEqualTo(scroll.position.viewportDimension * .75),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);
      expect(up.hitTestable(), findsNothing);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('NotiHistory'));
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      expect(find.text('Сохранение уведомлений'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('The feed stays above the docked actions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 28, bottom: 24);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_russianApp(repository: MemoryRepository()));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SliverAppBar>(find.byType(SliverAppBar)).pinned,
      isTrue,
    );
    expect(find.byType(SliverPersistentHeader), findsNWidgets(2));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-viewport-corners')),
      findsNothing,
    );
    final cards = tester
        .widgetList<SwipeNotificationCard>(find.byType(SwipeNotificationCard))
        .toList();
    expect(cards.first.borderRadius.topLeft.x, 20);
    expect(cards.first.borderRadius.bottomLeft.x, 0);
    expect(cards.first.bottomSpacing, 0);
    expect(cards.last.borderRadius.topLeft.x, 0);
    expect(cards.last.borderRadius.bottomLeft.x, 20);
    expect(cards.last.bottomSpacing, 0);
    expect(find.byKey(const ValueKey('day-header-Сегодня')), findsOneWidget);
    final viewport = tester.getRect(find.byType(CustomScrollView));
    final actions = tester.getRect(
      find.byKey(const ValueKey('history-bottom-actions')),
    );
    expect(viewport.top, 0);
    expect(viewport.bottom, lessThanOrEqualTo(actions.top));
    expect(actions.top, lessThan(844));
    expect(tester.getTopLeft(find.text('NotiHistory')).dy, greaterThan(28));
    expect(find.byKey(const ValueKey('app-filter-__all__')), findsNothing);
  });
}

class _RefreshCountingRepository extends MemoryRepository {
  int statusCalls = 0;
  @override
  Future<CaptureStatus> status() {
    statusCalls++;
    return super.status();
  }
}

class FailingAppClearRepository extends MemoryRepository {
  bool fail = true;
  @override
  Future<void> clear({
    String search = '',
    Set<String> packageNames = const {},
    int since = 0,
    bool archived = false,
  }) async {
    if (fail) throw StateError('Storage unavailable');
    await super.clear(search: search, packageNames: packageNames, since: since);
  }
}

Widget _russianApp({HistoryRepository? repository}) {
  final preferences = _RussianPreferences();
  addTearDown(preferences.dispose);
  return NotiHistoryApp(repository: repository, preferences: preferences);
}

class _RussianPreferences extends AppPreferences {
  _RussianPreferences() : super(deviceLocales: const [Locale('ru')]);
  @override
  Future<void> load() async {}
}
