import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/history_sheet.dart';

Future<bool> confirmClearHistory(
  BuildContext context, {
  bool filtered = false,
  bool archived = false,
  String? appName,
  bool waitForDismiss = false,
}) async =>
    await showHistorySheet<bool>(
      context,
      waitForDismiss: waitForDismiss,
      (context) => HistorySheet(
        children: [
          Center(
            child: Text(
              appName != null
                  ? tr(
                      context,
                      archived
                          ? 'Удалить уведомления приложения из архива?'
                          : 'Удалить уведомления приложения?',
                    )
                  : filtered
                  ? tr(context, 'Очистить по фильтру?')
                  : tr(
                      context,
                      archived ? 'Очистить архив?' : 'Очистить всю историю?',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: titleFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            appName != null
                ? tr(
                    context,
                    archived
                        ? 'Все уведомления от «{0}» в архиве будут удалены. Вернуть их не получится.'
                        : 'Уведомления от «{0}» на главном экране будут удалены. Архив сохранится.',
                    [appName],
                  )
                : filtered
                ? tr(
                    context,
                    'Уведомления, соответствующие текущим фильтрам и поиску, будут удалены. Вернуть их не получится.',
                  )
                : tr(
                    context,
                    archived
                        ? 'Все уведомления в архиве будут удалены. Вернуть их не получится.'
                        : 'Уведомления на главном экране будут удалены. Архив сохранится. Вернуть удалённые уведомления не получится.',
                  ),
            style: TextStyle(
              color: ui(context).muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(actionRadius),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(tr(context, 'Отмена')),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    filtered || appName != null
                        ? tr(context, 'Удалить')
                        : tr(context, 'Удалить всё'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ??
    false;
