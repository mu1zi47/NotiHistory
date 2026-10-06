import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 38),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEEE9FB),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              filtered
                  ? Icons.search_off_rounded
                  : Icons.mark_email_read_outlined,
              color: accent,
              size: 37,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            filtered ? 'Ничего не нашлось' : 'Здесь начнётся ваша история',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: titleFont,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Попробуйте другой запрос или сбросьте фильтры.'
                : status.active
                ? 'Следующее уведомление появится здесь.'
                : 'Разрешите доступ — и новые уведомления будут сохраняться автоматически.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          if (!status.active && status.supported) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAccess,
              child: Text(
                status.granted ? 'Проверить доступ' : 'Включить сохранение',
              ),
            ),
          ],
          if (filtered)
            TextButton(
              onPressed: onReset,
              child: const Text('Сбросить фильтры'),
            ),
        ],
      ),
    );
  }
}
