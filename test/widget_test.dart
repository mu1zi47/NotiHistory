import 'package:noti_history/features/history/domain/capture_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/app.dart';
import 'package:noti_history/core/theme/app_theme.dart';
import 'package:noti_history/features/history/presentation/history_screen.dart';
import 'package:noti_history/features/history/presentation/widgets/period_filter_button.dart';
import 'package:noti_history/features/history/presentation/widgets/swipe_notification_card.dart';

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
    expect(find.text('Ничего не нашлось'), findsOneWidget);
    await tester.tap(find.text('Сбросить фильтры'));
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(NotiHistoryApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Включить сохранение'), findsOneWidget);
  });

  testWidgets('A tap outside the search removes its focus', (tester) async {
    await tester.pumpWidget(NotiHistoryApp(repository: MemoryRepository()));
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
    await tester.pumpWidget(NotiHistoryApp(repository: repo));
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
    expect(tester.widget<Icon>(find.byIcon(Icons.apps_rounded)).color, accent);
    await tester.tap(find.byKey(const ValueKey('filter-option-org.telegram')));
    await tester.pump();
    expect(tester.widget<Icon>(find.byIcon(Icons.apps_rounded)).color, ink);
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

  testWidgets('Purple actions share the period button style', (tester) async {
    final theme = buildAppTheme();
    final filledStyle = theme.filledButtonTheme.style!;

    expect(filledStyle.backgroundColor!.resolve({}), accentSurface);
    expect(filledStyle.foregroundColor!.resolve({}), accent);
    final shape = filledStyle.shape!.resolve({})! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(actionRadius));

    await tester.pumpWidget(NotiHistoryApp(repository: MemoryRepository()));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history-bottom-actions')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('app-filter-__all__')), findsNothing);
  });

  testWidgets(
    'Short swipes reset and longer swipes immediately delete in both directions',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryRepository();
      await tester.pumpWidget(NotiHistoryApp(repository: repo));
      await tester.pumpAndSettle();

      final first = find.ancestor(
        of: find.text('Аня'),
        matching: find.byType(SwipeNotificationCard),
      );
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
      expect(repo.entries, isEmpty);
      expect(find.text('Билеты'), findsNothing);
    },
  );

  testWidgets('Custom pull refresh lowers the feed and returns after loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NotiHistoryApp(repository: MemoryRepository()));
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
    await tester.pumpWidget(NotiHistoryApp(repository: repo));
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
    await tester.pumpWidget(NotiHistoryApp(repository: repo));
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

  testWidgets('The feed stays above the docked actions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 28, bottom: 24);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NotiHistoryApp(repository: MemoryRepository()));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SliverAppBar>(find.byType(SliverAppBar)).pinned,
      isTrue,
    );
    expect(find.byType(SliverPersistentHeader), findsNWidgets(2));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-viewport-corners')),
      findsOneWidget,
    );
    final cards = tester
        .widgetList<SwipeNotificationCard>(find.byType(SwipeNotificationCard))
        .toList();
    expect(cards.first.borderRadius.topLeft.x, 0);
    expect(cards.first.borderRadius.bottomLeft.x, 0);
    expect(cards.first.bottomSpacing, 0);
    expect(cards.last.borderRadius.topLeft.x, 0);
    expect(cards.last.borderRadius.bottomLeft.x, 20);
    expect(cards.last.bottomSpacing, 12);
    expect(
      find.byKey(const ValueKey('day-header-corners-Сегодня')),
      findsOneWidget,
    );
    final viewport = tester.getRect(find.byType(CustomScrollView));
    final actions = tester.getRect(
      find.byKey(const ValueKey('history-bottom-actions')),
    );
    expect(viewport.top, 0);
    expect(viewport.bottom, lessThanOrEqualTo(actions.top));
    expect(actions.top, lessThan(844));
    expect(
      tester.getTopLeft(find.text('NotiHistory')).dy,
      greaterThan(28),
    );
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
