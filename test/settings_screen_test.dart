import 'package:noti_history/core/settings/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/core/theme/app_theme.dart';
import 'package:noti_history/features/settings/settings_screen.dart';
import 'package:noti_history/features/settings/capture_apps_screen.dart';
import 'package:noti_history/features/settings/capture_app_actions.dart';

import 'support/memory_repository.dart';

import 'package:noti_history/features/settings/feedback_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('notihistory/history');
  testWidgets('Feedback opens email and contacts destinations', (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: FeedbackBlock()),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('feedback-email')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('feedback-telegram')));
    await tester.pump();
    expect(calls.map((call) => call.method), ['openFeedback', 'openFeedback']);
    expect(calls.map((call) => (call.arguments as Map)['destination']), [
      'email',
      'telegram',
    ]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Search, persist selection, reopen and failed save', (
    tester,
  ) async {
    final preferences = AppPreferences(deviceLocales: const [Locale('ru')]);
    addTearDown(preferences.dispose);
    final enabled = {'telegram': true, 'mail': true};
    bool fail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'captureApps') {
            return enabled.entries
                .map(
                  (e) => {
                    'packageName': e.key,
                    'name': e.key == 'telegram' ? 'Telegram' : 'Почта',
                    'enabled': e.value,
                  },
                )
                .toList();
          }
          if (call.method == 'setCaptureEnabled') {
            if (fail) throw PlatformException(code: 'storage');
            enabled[call.arguments['packageName'] as String] =
                call.arguments['enabled'] as bool;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    Future<void> open() async {
      await tester.pumpWidget(
        AppPreferencesScope(
          preferences: preferences,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: SettingsScreen(historyRepository: MemoryRepository()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.byType(TextField).hitTestable(), findsNothing);
    await tester.tap(find.text('Сохранение уведомлений'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField).hitTestable(), findsNothing);
    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'TELE');
    await tester.pumpAndSettle();
    expect(find.text('Почта'), findsNothing);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(enabled['telegram'], false);
    expect(enabled['mail'], true);
    await tester.pumpWidget(const SizedBox());
    await open();
    await tester.tap(find.text('Сохранение уведомлений'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, false);
    fail = true;
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, false);
    expect(
      find.text('Не удалось сохранить настройку. Попробуйте снова.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsNothing);
  });
  testWidgets(
    'Scrollable apps and compact bottom search and enable-all actions',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final enabled = {for (var i = 0; i < 30; i++) 'app$i': i != 0 && i != 29};
      var fail = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'captureApps') {
              return enabled.entries
                  .map(
                    (e) => {
                      'packageName': e.key,
                      'name': e.key,
                      'enabled': e.value,
                    },
                  )
                  .toList();
            }
            if (call.method == 'enableAllCaptureApps') {
              if (fail) throw PlatformException(code: 'storage');
              enabled.updateAll((_, _) => true);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: CaptureAppsScreen(historyRepository: MemoryRepository()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('От каких приложений сохранять'), findsNothing);
      final firstApp = find.byKey(const ValueKey('capture-app-app0'));
      final secondApp = find.byKey(const ValueKey('capture-app-app1'));
      expect(
        tester.getBottomLeft(firstApp).dy,
        closeTo(tester.getTopLeft(secondApp).dy, .1),
      );
      expect(
        tester
            .widget<Material>(
              find
                  .descendant(of: firstApp, matching: find.byType(Material))
                  .first,
            )
            .borderRadius,
        const BorderRadius.vertical(top: Radius.circular(20)),
      );
      final decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: firstApp, matching: find.byType(DecoratedBox)),
          )
          .map((widget) => widget.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) => decoration.border != null);
      expect((decoration.border as Border).bottom.width, 1);
      expect((decoration.border as Border).left, BorderSide.none);
      final dock = tester.getRect(
        find.byKey(const ValueKey('capture-bottom-actions')),
      );
      final feed = find.byType(CustomScrollView);
      await tester.drag(feed, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.byType(TextField).hitTestable(), findsNothing);
      final rows = tester.getRect(find.byType(SwitchListTile).first);
      expect(rows.top, lessThan(100));
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('capture-count-header')))
            .dy,
        closeTo(56, .1),
      );
      expect(
        find.text('Сохранение включено: 28 из 30').hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('capture-bottom-actions'))),
        dock,
      );
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: feed, matching: find.byType(Scrollable)).first,
          )
          .position;
      position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Поиск'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'app0');
      await tester.pumpAndSettle();
      expect(find.text('app29'), findsNothing);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byType(TextField)).dy,
        lessThanOrEqualTo(564),
      );
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Закрыть поиск'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField).hitTestable(), findsNothing);
      expect(
        tester.getSize(find.byTooltip('Включить все')).width,
        lessThan(200),
      );
      await tester.tap(find.text('Включить все'));
      await tester.pumpAndSettle();
      expect(enabled['app0'], false);
      await tester.tap(find.widgetWithText(FilledButton, 'Включить все'));
      await tester.pumpAndSettle();
      expect(enabled['app0'], false);
      expect(
        find.text('Не удалось включить все приложения. Попробуйте снова.'),
        findsOneWidget,
      );
      fail = false;
      await tester.tap(find.text('Включить все'));
      await tester.pumpAndSettle();
      expect(enabled['app0'], false);
      await tester.tap(find.widgetWithText(FilledButton, 'Включить все'));
      await tester.pumpAndSettle();
      expect(enabled.values.every((value) => value), true);
      expect(find.text('Включить все'), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Enable-all button expands and fades in and out', (tester) async {
    var hasDisabled = false;
    late StateSetter update;
    final search = TextEditingController();
    addTearDown(search.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return CaptureAppActions(
                search: search,
                onSearchChanged: (_) {},
                hasDisabled: hasDisabled,
                busy: false,
                onEnableAll: () {},
              );
            },
          ),
        ),
      ),
    );
    final action = find.byKey(const ValueKey('capture-enable-all-action'));
    expect(action, findsNothing);
    update(() => hasDisabled = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final transition = find
        .ancestor(of: action, matching: find.byType(SizeTransition))
        .first;
    expect(
      tester.widget<SizeTransition>(transition).sizeFactor.value,
      inExclusiveRange(0, 1),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<SizeTransition>(transition).sizeFactor.value, 1);
    update(() => hasDisabled = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(action, findsOneWidget);
    expect(
      tester.widget<SizeTransition>(transition).sizeFactor.value,
      inExclusiveRange(0, 1),
    );
    await tester.pumpAndSettle();
    expect(action, findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Status filters combine with search and refresh after toggling', (
    tester,
  ) async {
    final enabled = {
      'Alpha': true,
      'Beta': false,
      'Gamma': true,
      'Delta': false,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'captureApps') {
            return enabled.entries
                .map(
                  (e) => {
                    'packageName': e.key.toLowerCase(),
                    'name': e.key,
                    'enabled': e.value,
                  },
                )
                .toList();
          }
          if (call.method == 'setCaptureEnabled') {
            final name = enabled.keys.firstWhere(
              (key) => key.toLowerCase() == call.arguments['packageName'],
            );
            enabled[name] = call.arguments['enabled'] as bool;
          }
          if (call.method == 'enableAllCaptureApps') {
            enabled.updateAll((_, _) => true);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: CaptureAppsScreen(historyRepository: MemoryRepository()),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> filter(String name) async {
      await tester.tap(find.byTooltip('Фильтр приложений'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('capture-filter-$name')));
      await tester.pumpAndSettle();
    }

    await filter('disabled');
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Delta'), findsOneWidget);
    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Delta'), findsNothing);
    await tester.tap(find.byTooltip('Закрыть поиск'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsNothing);
    final betaRow = find.byKey(const ValueKey('capture-app-beta'));
    final betaHeight = tester.getSize(betaRow).height;
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(enabled['Beta'], true);
    expect(find.text('Beta'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 140));
    expect(tester.getSize(betaRow).height, greaterThan(0));
    expect(tester.getSize(betaRow).height, lessThan(betaHeight));
    await tester.pumpAndSettle();
    expect(enabled['Beta'], true);
    expect(find.text('Beta'), findsNothing);
    expect(find.text('Сохранение включено: 3 из 4'), findsOneWidget);
    await filter('enabled');
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Delta'), findsNothing);
    await filter('disabled');
    await tester.tap(find.byTooltip('Включить все'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(enabled['Delta'], false);
    await tester.tap(find.byTooltip('Включить все'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Включить все'));
    await tester.pumpAndSettle();
    expect(find.text('Нет выключенных приложений'), findsOneWidget);
    expect(find.byTooltip('Включить все'), findsNothing);
    expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    expect(
      find.text('Попробуйте другой запрос или сбросьте фильтры.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Сбросить фильтры'));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
