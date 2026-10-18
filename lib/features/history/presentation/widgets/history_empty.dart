import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/capture_status.dart';

class HistoryEmpty extends StatelessWidget {
  const HistoryEmpty({
    super.key,
    required this.filtered,
    this.archived = false,
    required this.status,
    required this.onAccess,
    required this.onReset,
  });
  final bool filtered;
  final bool archived;
  final CaptureStatus status;
  final VoidCallback onAccess;
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: filtered
          ? Icons.search_off_rounded
          : archived
          ? Icons.archive_outlined
          : Icons.mark_email_read_outlined,
      title: filtered
          ? tr(context, 'Ничего не нашлось')
          : tr(
              context,
              archived ? 'Архив пуст' : 'Здесь начнётся ваша история',
            ),
      message: filtered
          ? tr(context, 'Попробуйте другой запрос или сбросьте фильтры.')
          : archived
          ? tr(
              context,
              'Смахните уведомление вправо, чтобы сохранить его в архиве.',
            )
          : status.active
          ? tr(context, 'Следующее уведомление появится здесь.')
          : tr(
              context,
              'Разрешите доступ — и новые уведомления будут сохраняться автоматически.',
            ),
      actions: [
        if (!archived && !status.active && status.supported) ...[
          SizedBox(height: 16),
          FilledButton(
            onPressed: onAccess,
            child: Text(
              status.granted
                  ? tr(context, 'Проверить доступ')
                  : tr(context, 'Включить сохранение'),
            ),
          ),
        ],
        if (filtered)
          TextButton(
            onPressed: onReset,
            child: Text(tr(context, 'Сбросить фильтры')),
          ),
      ],
    );
  }
}
