import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/formatting/notification_date.dart';
import '../domain/saved_notification.dart';
import '../domain/saved_app.dart';
import '../domain/history_repository.dart';
import 'widgets/app_avatar.dart';
import 'widgets/copy_notification_button.dart';
import 'widgets/history_sheet.dart';
import 'widgets/notification_image.dart';

void showNotificationDetails(
  BuildContext context,
  SavedNotification item,
  HistoryRepository repository,
) {
  showHistorySheet<void>(
    context,
    (_) => _NotificationDetails(item: item, repository: repository),
  );
}

class _NotificationDetails extends StatefulWidget {
  const _NotificationDetails({required this.item, required this.repository});
  final SavedNotification item;
  final HistoryRepository repository;

  @override
  State<_NotificationDetails> createState() => _NotificationDetailsState();
}

class _NotificationDetailsState extends State<_NotificationDetails>
    with WidgetsBindingObserver {
  bool _available = false;
  bool _opening = false;
  int _checkGeneration = 0;
  StreamSubscription<void>? _changes;
  SavedNotification get item => widget.item;
  HistoryRepository get repository => widget.repository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _changes = repository.changes.listen(
      (_) => _checkAvailability(),
      onError: (_) {},
    );
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final generation = ++_checkGeneration;
    bool available;
    try {
      available = await repository.canOpenNotification(
        item.id,
        packageName: item.packageName,
      );
    } catch (_) {
      available = false;
    }
    if (mounted && generation == _checkGeneration) {
      setState(() => _available = available);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAvailability();
  }

  Future<void> _open() async {
    setState(() => _opening = true);
    try {
      await repository.openNotification(item.id, packageName: item.packageName);
      await _checkAvailability();
    } catch (error) {
      if (!mounted) return;
      ++_checkGeneration;
      setState(() => _available = false);
      showAppToast(
        context,
        error is PlatformException
            ? error.message ?? 'Переход недоступен.'
            : 'Переход недоступен.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _changes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HistorySheet(
    children: [
      Row(
        children: [
          AppAvatar(
            app: SavedApp(item.packageName, item.appName, 0),
            repository: repository,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.appName,
                      style: const TextStyle(
                        fontFamily: titleFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.packageName,
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${fullDate(item.postedAt)} · ${notificationTime(item.postedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      SelectableText(
        item.title.isEmpty ? item.appName : item.title,
        style: const TextStyle(
          fontFamily: titleFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 8),
      SelectableText(
        item.body.isEmpty
            ? 'Android не передал текст этого уведомления.'
            : item.body,
        style: const TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
      if (item.hasImage) NotificationImage(item: item, repository: repository),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: CopyNotificationButton(
              text: [
                item.title,
                item.body,
              ].where((s) => s.isNotEmpty).join('\n'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _available && !_opening ? _open : null,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Перейти'),
            ),
          ),
        ],
      ),
    ],
  );
}
