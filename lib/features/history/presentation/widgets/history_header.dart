import 'package:noti_history/core/widgets/applied_filters.dart';

import '../period_picker_sheet.dart';

import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../application/history_controller.dart';
import 'access_card.dart';
import 'history_error.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({
    super.key,
    required this.controller,
    required this.onAccess,
    this.onOpenArchive,
    required this.onResetFilters,
  });
  final HistoryController controller;
  final VoidCallback onAccess, onResetFilters;
  final VoidCallback? onOpenArchive;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!controller.archived &&
          controller.archivedCount > 0 &&
          onOpenArchive != null)
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('open-archive'),
              onPressed: onOpenArchive,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.archive_outlined, size: 21),
                  const SizedBox(width: 10),
                  Text(tr(context, 'Архив уведомлений')),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      AppliedFilters(
        key: const ValueKey('history-applied-filters'),
        onReset: onResetFilters,
        filters: [
          if (controller.packageNames.isNotEmpty)
            (
              icon: Icons.apps_rounded,
              text: tr(context, 'Приложения: {0}', [
                controller.packageNames
                    .map(
                      (package) =>
                          controller.apps
                              .where((app) => app.packageName == package)
                              .map((app) => app.name)
                              .firstOrNull ??
                          package,
                    )
                    .join(', '),
              ]),
            ),
          if (controller.search.trim().isNotEmpty)
            (
              icon: Icons.search_rounded,
              text: tr(context, 'Поиск: {0}', [controller.search.trim()]),
            ),
          if (controller.period != 0)
            (
              icon: Icons.date_range_rounded,
              text: tr(context, 'Период: {0}', [
                tr(context, periodLabels[controller.period]),
              ]),
            ),
        ],
      ),
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
