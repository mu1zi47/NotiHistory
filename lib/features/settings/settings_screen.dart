import '../../core/theme/system_bars.dart';

import 'package:noti_history/core/navigation/app_page_route.dart';

import 'app_settings_block.dart';
import 'feedback_block.dart';

import 'package:flutter/services.dart';

import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../history/domain/history_repository.dart';
import 'capture_apps_screen.dart';
import 'capture_settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.historyRepository,
    this.settingsRepository = const CaptureSettingsRepository(),
  });

  final HistoryRepository historyRepository;
  final CaptureSettingsRepository settingsRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<String?> _version = _loadVersion();

  Future<String?> _loadVersion() async {
    try {
      return await const MethodChannel('notihistory/history')
          .invokeMethod<String>('appVersion');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark
        ? transparentDarkSystemBars
        : transparentSystemBars,
    child: Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Настройки'))),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    tr(context, 'Настройки приложения'),
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: ui(context).muted),
                  ),
                ),
                const AppSettingsBlock(),
                const SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    tr(context, 'Уведомления'),
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: ui(context).muted),
                  ),
                ),
                Material(
                  color: ui(context).surface,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ui(context).accentSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: ui(context).accent,
                      ),
                    ),
                    title: Text(tr(context, 'Сохранение уведомлений')),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        tr(
                          context,
                          'Выберите приложения для сохранения в историю',
                        ),
                        style: TextStyle(
                          color: ui(context).muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: ui(context).muted,
                    ),
                    onTap: () => Navigator.of(context).push(
                      AppPageRoute<void>(
                        builder: (_) => CaptureAppsScreen(
                          historyRepository: widget.historyRepository,
                          settingsRepository: widget.settingsRepository,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    tr(context, 'Обратная связь'),
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: ui(context).muted),
                  ),
                ),
                const FeedbackBlock(),
                const SizedBox(height: 24),
                FutureBuilder<String?>(
                  future: _version,
                  builder: (context, snapshot) => snapshot.data == null
                      ? const SizedBox.shrink()
                      : Text(
                          tr(context, 'Версия приложения: {0}', [
                            snapshot.data!,
                          ]),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ui(context).muted),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
