import 'dart:io';
import 'dart:ui' as drawing;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/app.dart';
import 'package:noti_history/core/settings/app_preferences.dart';
import 'package:noti_history/core/theme/app_theme.dart';

import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    final headings = FontLoader(titleFont)
      ..addFont(rootBundle.load('assets/fonts/Exo2.ttf'));
    final body = FontLoader(bodyFont)
      ..addFont(rootBundle.load('assets/fonts/Manrope-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-ExtraBold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([headings.load(), body.load(), icons.load()]);
  });
  const channel = MethodChannel('notihistory/history');
  late Map<String, dynamic> stored;
  setUp(() {
    stored = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'appPreferences') {
            return Map<String, dynamic>.of(stored);
          }
          if (call.method == 'setAppPreferences') {
            stored = Map<String, dynamic>.from(call.arguments as Map);
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('First launch resolves device locale and preferences survive another device locale', () async {
    final first = AppPreferences(deviceLocales: const [Locale('ru', 'RU')]);
    await first.load();
    expect(first.language, 'ru');
    expect(stored['language'], 'ru');
    await first.setLanguage('en');
    await first.setTheme(ThemeMode.dark);
    first.dispose();
    final reopened = AppPreferences(deviceLocales: const [Locale('ru')]);
    await reopened.load();
    expect(reopened.language, 'en');
    expect(reopened.themeMode, ThemeMode.dark);
    reopened.dispose();
  });

  test('Unsupported device languages fall back to English', () async {
    final settings = AppPreferences(deviceLocales: const [Locale('uz')]);
    await settings.load();
    expect(settings.language, 'en');
    expect(settings.themeMode, ThemeMode.system);
    settings.dispose();
  });

  test('Failed persistence keeps the previous visible preference', () async {
    stored = {'language': 'ru', 'theme': 'light'};
    final settings = AppPreferences();
    await settings.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'storage');
        });
    await expectLater(
      settings.setTheme(ThemeMode.dark),
      throwsA(isA<PlatformException>()),
    );
    expect(settings.themeMode, ThemeMode.light);
    settings.dispose();
  });

  testWidgets(
    'System theme follows device brightness while explicit themes override it',
    (tester) async {
      final preferences = AppPreferences(deviceLocales: const [Locale('en')]);
      addTearDown(preferences.dispose);
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );
      await tester.pumpWidget(
        NotiHistoryApp(
          repository: MemoryRepository(),
          preferences: preferences,
        ),
      );
      await tester.pumpAndSettle();
      Brightness brightness() =>
          Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
      expect(brightness(), Brightness.dark);
      await preferences.setTheme(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.light);
      await preferences.setTheme(ThemeMode.dark);
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.light;
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.dark);
      await preferences.setTheme(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.light);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'English UI, dark cards and language switch update existing routes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const preview = ValueKey('theme-preview');
      final preferences = AppPreferences(deviceLocales: const [Locale('en')]);
      addTearDown(preferences.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: preview,
          child: NotiHistoryApp(
            repository: MemoryRepository(),
            preferences: preferences,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Search'), findsOneWidget);
      await tester.tap(find.byTooltip('App filter'));
      await tester.pumpAndSettle();
      expect(find.text('App filter'), findsOneWidget);
      await tester.tap(find.text('Show all'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('Clear all history?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('app-language')), findsOneWidget);
      expect(find.byKey(const ValueKey('app-theme')), findsOneWidget);
      expect(find.text('App settings'), findsOneWidget);
      expect(find.byKey(const ValueKey('app-settings-block')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('app-theme')));
      await tester.pumpAndSettle();
      await _snapshot(tester, preview, '/tmp/notihistory-theme-picker.png');
      await tester.tap(find.byKey(const ValueKey('theme-dark')));
      await tester.pumpAndSettle();
      final context = tester.element(
        find.byKey(const ValueKey('app-settings-block')),
      );
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(
        tester
            .widget<Material>(find.byKey(const ValueKey('app-settings-block')))
            .color,
        ui(context).surface,
      );
      expect(ui(context).surface, isNot(Colors.white));
      await _snapshot(tester, preview, '/tmp/notihistory-dark-settings.png');
      await tester.tap(find.byKey(const ValueKey('app-language')));
      await tester.pumpAndSettle();
      await _snapshot(tester, preview, '/tmp/notihistory-language-picker.png');
      await tester.tap(find.byKey(const ValueKey('language-ru')));
      await tester.pumpAndSettle();
      expect(find.text('Настройки приложения'), findsOneWidget);
      expect(find.text('Язык'), findsOneWidget);
      expect(find.text('Настройки'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Поиск'), findsOneWidget);
      final overlay = tester
          .widget<SliverAppBar>(find.byType(SliverAppBar))
          .systemOverlayStyle!;
      expect(overlay.statusBarIconBrightness, Brightness.light);
      expect(overlay.systemNavigationBarIconBrightness, Brightness.light);
      expect(stored, {'language': 'ru', 'theme': 'dark'});
      await _snapshot(tester, preview, '/tmp/notihistory-dark-history.png');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Future<void> _snapshot(WidgetTester tester, Key key, String path) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: drawing.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
