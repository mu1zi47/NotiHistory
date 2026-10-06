import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/history_sheet.dart';

Future<bool> confirmClearHistory(
  BuildContext context, {
  bool filtered = false,
}) async =>
    await showHistorySheet<bool>(
      context,
      (context) => HistorySheet(
        children: [
          Center(
            child: Text(
              filtered ? 'Очистить по фильтру?' : 'Очистить всю историю?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: titleFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            filtered
                ? 'Уведомления, соответствующие текущим фильтрам и поиску, будут удалены. Вернуть их не получится.'
                : 'Все сохранённые уведомления будут удалены с телефона. Вернуть их не получится. Новые уведомления продолжат сохраняться.',
            style: const TextStyle(
              color: muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(actionRadius),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(filtered ? 'Удалить' : 'Удалить всё'),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ??
    false;
