import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_strings.dart';
import 'core/settings/app_preferences.dart';

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/history/data/platform_history_repository.dart';
import 'features/history/domain/history_repository.dart';
import 'features/history/presentation/history_screen.dart';

class NotiHistoryApp extends StatefulWidget {
  const NotiHistoryApp({super.key, this.repository, this.preferences});
  final AppPreferences? preferences;
  final HistoryRepository? repository;
  @override
  State<NotiHistoryApp> createState() => _NotiHistoryAppState();
}

class _NotiHistoryAppState extends State<NotiHistoryApp> {
  late final HistoryRepository _repository =
      widget.repository ?? PlatformHistoryRepository();
  late final AppPreferences _preferences =
      widget.preferences ?? AppPreferences();
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    _preferences.load().whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    if (widget.preferences == null) _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _preferences,
    builder: (context, _) => AppPreferencesScope(
      preferences: _preferences,
      child: MaterialApp(
        title: 'NotiHistory',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        darkTheme: buildAppTheme(brightness: Brightness.dark),
        themeMode: _preferences.themeMode,
        locale: _preferences.locale,
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _ready
            ? HistoryScreen(repository: _repository)
            : const SizedBox.shrink(),
      ),
    ),
  );
}
