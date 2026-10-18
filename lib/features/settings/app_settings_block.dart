import 'package:noti_history/core/widgets/option_icon.dart';
import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../history/presentation/widgets/history_sheet.dart';

class AppSettingsBlock extends StatelessWidget {
  const AppSettingsBlock({super.key});

  Future<void> _language(BuildContext context) async {
    final preferences = AppPreferencesScope.of(context);
    final result = await showHistorySheet<String>(
      context,
      (sheetContext) => HistorySheet(
        header: Center(
          child: Text(
            tr(sheetContext, 'Язык'),
            style: const TextStyle(
              fontFamily: titleFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        children: [
          _optionBlock(sheetContext, [
            for (final language in ['ru', 'en'])
              _PreferenceOption(
                key: ValueKey('language-$language'),
                label: language == 'ru' ? 'Русский' : 'English',
                icon: Icons.language_rounded,
                selected: preferences.language == language,
                showDivider: language == 'ru',
                onTap: () => Navigator.pop(sheetContext, language),
              ),
          ]),
        ],
      ),
      enableDrag: false,
    );
    if (result == null) return;
    try {
      await preferences.setLanguage(result);
    } catch (_) {
      if (context.mounted) {
        showAppToast(
          context,
          tr(context, 'Не удалось сохранить настройку. Попробуйте снова.'),
          error: true,
        );
      }
    }
  }

  Future<void> _theme(BuildContext context) async {
    final preferences = AppPreferencesScope.of(context);
    final result = await showHistorySheet<ThemeMode>(
      context,
      (sheetContext) => HistorySheet(
        header: Center(
          child: Text(
            tr(sheetContext, 'Тема'),
            style: const TextStyle(
              fontFamily: titleFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        children: [
          _optionBlock(sheetContext, [
            for (final mode in ThemeMode.values)
              _PreferenceOption(
                key: ValueKey('theme-${mode.name}'),
                label: _themeName(sheetContext, mode),
                icon: switch (mode) {
                  ThemeMode.system => Icons.brightness_auto_rounded,
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                },
                selected: preferences.themeMode == mode,
                showDivider: mode != ThemeMode.values.last,
                onTap: () => Navigator.pop(sheetContext, mode),
              ),
          ]),
        ],
      ),
      enableDrag: false,
    );
    if (result == null) return;
    try {
      await preferences.setTheme(result);
    } catch (_) {
      if (context.mounted) {
        showAppToast(
          context,
          tr(context, 'Не удалось сохранить настройку. Попробуйте снова.'),
          error: true,
        );
      }
    }
  }

  String _themeName(BuildContext context, ThemeMode mode) =>
      tr(context, switch (mode) {
        ThemeMode.system => 'Как на устройстве',
        ThemeMode.light => 'Светлая',
        ThemeMode.dark => 'Тёмная',
      });

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesScope.of(context);
    return Material(
      key: const ValueKey('app-settings-block'),
      color: ui(context).surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const ValueKey('app-language'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: _settingIcon(context, Icons.language_rounded),
            title: Text(tr(context, 'Язык')),
            subtitle: Text(
              preferences.language == 'ru' ? 'Русский' : 'English',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _language(context),
          ),
          Divider(height: 1, thickness: 1, color: ui(context).divider),
          ListTile(
            key: const ValueKey('app-theme'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: _settingIcon(context, Icons.palette_outlined),
            title: Text(tr(context, 'Тема')),
            subtitle: Text(_themeName(context, preferences.themeMode)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _theme(context),
          ),
        ],
      ),
    );
  }
}

Widget _settingIcon(BuildContext context, IconData icon) => Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: ui(context).accentSurface,
    borderRadius: BorderRadius.circular(14),
  ),
  child: Icon(icon, color: ui(context).accent),
);

Widget _optionBlock(BuildContext context, List<Widget> options) => Material(
  color: ui(context).surface,
  borderRadius: BorderRadius.circular(20),
  clipBehavior: Clip.antiAlias,
  child: Column(mainAxisSize: MainAxisSize.min, children: options),
);

class _PreferenceOption extends StatelessWidget {
  const _PreferenceOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected, showDivider;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: ui(context).divider))
              : null,
        ),
        child: Row(
          children: [
            OptionIcon(icon: icon, selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: selected ? ui(context).accent : ui(context).ink,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: ui(context).accent, size: 22),
          ],
        ),
      ),
    ),
  );
}
