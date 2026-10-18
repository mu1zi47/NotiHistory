import 'package:noti_history/core/theme/app_theme.dart';
import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

class HistoryError extends StatelessWidget {
  const HistoryError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Material(
      color: ui(context).deleteSurface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(tr(context, message), style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(tr(context, 'Повторить')),
            ),
          ],
        ),
      ),
    ),
  );
}
