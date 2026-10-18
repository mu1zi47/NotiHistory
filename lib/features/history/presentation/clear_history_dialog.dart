import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/history_sheet.dart';

Future<bool> confirmClearHistory(
  BuildContext context, {
  bool filtered = false,
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
                  ? tr(context, 'Удалить уведомления приложения?')
                  : filtered
                  ? tr(context, 'Очистить по фильтру?')
                  : tr(context, 'Очистить всю историю?'),
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
                    'Все сохранённые уведомления от «{0}» будут удалены. Вернуть их не получится.',
                    [appName],
                  )
                : filtered
                ? tr(
                    context,
                    'Уведомления, соответствующие текущим фильтрам и поиску, будут удалены. Вернуть их не получится.',
                  )
                : tr(
                    context,
                    'Все сохранённые уведомления будут удалены с телефона. Вернуть их не получится. Новые уведомления продолжат сохраняться.',
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
