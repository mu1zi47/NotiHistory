import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/capture_status.dart';

class HistoryEmpty extends StatelessWidget {
  const HistoryEmpty({
    super.key,
    required this.filtered,
    required this.status,
    required this.onAccess,
    required this.onReset,
  });
  final bool filtered;
  final CaptureStatus status;
  final VoidCallback onAccess;
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: filtered
          ? Icons.search_off_rounded
          : Icons.mark_email_read_outlined,
      title: filtered
          ? tr(context, 'Ничего не нашлось')
          : tr(context, 'Здесь начнётся ваша история'),
      message: filtered
          ? tr(context, 'Попробуйте другой запрос или сбросьте фильтры.')
          : status.active
          ? tr(context, 'Следующее уведомление появится здесь.')
          : tr(
              context,
              'Разрешите доступ — и новые уведомления будут сохраняться автоматически.',
            ),
      actions: [
        if (!status.active && status.supported) ...[
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
