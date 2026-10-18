import 'package:noti_history/core/l10n/app_strings.dart';

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
    enableDrag: false,
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
  late SavedNotification item;
  HistoryRepository get repository => widget.repository;

  @override
  void initState() {
    super.initState();
    item = widget.item;
    WidgetsBinding.instance.addObserver(this);
    _changes = repository.changes.listen(
      (_) => _checkAvailability(refreshContent: true),
      onError: (_) {},
    );
    _checkAvailability(refreshContent: true);
  }

  Future<void> _checkAvailability({bool refreshContent = false}) async {
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
    SavedNotification? updated;
    if (refreshContent) {
      try {
        updated = await repository.notification(item.id);
      } catch (_) {}
    }
    if (mounted && generation == _checkGeneration) {
      setState(() {
        _available = available;
        if (updated != null && updated.packageName == item.packageName) {
          item = updated;
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAvailability(refreshContent: true);
    }
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
            ? tr(context, error.message ?? 'Переход недоступен.')
            : tr(context, 'Переход недоступен.'),
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
    viewportRadius: 0,
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppAvatar(
              app: SavedApp(item.packageName, item.appName, 0),
              repository: repository,
            ),
            SizedBox(width: 10),
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
                        style: TextStyle(
                          fontFamily: titleFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.packageName,
                        style: TextStyle(
                          fontSize: 11,
                          color: ui(context).muted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${fullDate(item.postedAt)} · ${notificationTime(item.postedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: ui(context).muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        SelectableText(
          item.title.isEmpty ? item.appName : item.title,
          style: TextStyle(
            fontFamily: titleFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        SizedBox(height: 8),
      ],
    ),
    footer: Row(
      children: [
        Expanded(
          flex: 3,
          child: CopyNotificationButton(
            text: [item.title, item.body].where((s) => s.isNotEmpty).join('\n'),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _available && !_opening ? _open : null,
            icon: Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(tr(context, 'Перейти')),
          ),
        ),
      ],
    ),
    children: [
      for (
        var index = 0;
        index < (item.messages.isEmpty ? 1 : item.messages.length);
        index++
      ) ...[
        if (index > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              key: ValueKey('message-divider-$index'),
              height: 1,
              thickness: 1,
              color: ui(context).divider,
            ),
          ),
        SelectableText(
          item.messages.isNotEmpty
              ? item.messages[index]
              : item.body.isEmpty
              ? tr(context, 'Android не передал текст этого уведомления.')
              : item.body,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ],
      if (item.hasImage) NotificationImage(item: item, repository: repository),
    ],
  );
}
