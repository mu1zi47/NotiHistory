import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/theme/system_bars.dart';
import 'core/settings/app_preferences.dart';

import 'package:flutter/material.dart' show ThemeMode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Exo2', 'Manrope']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/OFL-$font.txt'));
    }
  });
  final preferences = AppPreferences();
  await preferences.load();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    (preferences.themeMode == ThemeMode.dark ||
            (preferences.themeMode == ThemeMode.system &&
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark))
        ? transparentDarkSystemBars
        : transparentSystemBars,
  );
  runApp(NotiHistoryApp(preferences: preferences, preferencesLoaded: true));
}
