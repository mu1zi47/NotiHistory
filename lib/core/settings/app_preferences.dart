import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences({List<Locale>? deviceLocales})
    : _deviceLocales =
          deviceLocales ?? WidgetsBinding.instance.platformDispatcher.locales;
  static const _channel = MethodChannel('notihistory/history');
  final List<Locale> _deviceLocales;
  String? _language;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  String get language => _language ?? _deviceLanguage;
  Locale get locale => Locale(language);
  String get _deviceLanguage {
    for (final locale in _deviceLocales) {
      if (['ru', 'en'].contains(locale.languageCode)) {
        return locale.languageCode;
      }
    }
    return 'en';
  }

  Future<void> load() async {
    try {
      final values = await _channel.invokeMapMethod<String, dynamic>(
        'appPreferences',
      );
      final savedLanguage = values?['language'] as String?;
      _language = ['ru', 'en'].contains(savedLanguage)
          ? savedLanguage
          : _deviceLanguage;
      _themeMode = switch (values?['theme']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      if (savedLanguage == null || savedLanguage.isEmpty) await _save();
    } on MissingPluginException {
      _language = _deviceLanguage;
    } on PlatformException {
      _language = _deviceLanguage;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    if (!['ru', 'en'].contains(value)) return;
    await _change(value, _themeMode);
  }

  Future<void> setTheme(ThemeMode value) => _change(language, value);
  Future<void> _change(String language, ThemeMode theme) async {
    await _persist(language, theme);
    _language = language;
    _themeMode = theme;
    if (!_disposed) notifyListeners();
  }

  Future<void> _save() => _persist(language, _themeMode);
  Future<void> _persist(String language, ThemeMode theme) async {
    try {
      await _channel.invokeMethod<void>('setAppPreferences', {
        'language': language,
        'theme': theme.name,
      });
    } on MissingPluginException {
      /* Local preview has no Android storage. */
    }
  }
}

class AppPreferencesScope extends InheritedNotifier<AppPreferences> {
  const AppPreferencesScope({
    super.key,
    required AppPreferences preferences,
    required super.child,
  }) : super(notifier: preferences);
  static AppPreferences of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppPreferencesScope>()!
      .notifier!;
}
