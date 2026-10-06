import 'package:flutter/material.dart';

import '../../application/history_controller.dart';
import 'access_card.dart';
import 'history_error.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({
    super.key,
    required this.controller,
    required this.onAccess,
  });
  final HistoryController controller;
  final VoidCallback onAccess;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (controller.items.isNotEmpty &&
          !controller.status.active &&
          !controller.loading) ...[
        AccessCard(status: controller.status, onAccess: onAccess),
        const SizedBox(height: 18),
      ],
      if (controller.error != null)
        HistoryError(message: controller.error!, onRetry: controller.refresh),
    ],
  );
}
