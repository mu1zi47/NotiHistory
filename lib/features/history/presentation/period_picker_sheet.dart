import 'package:noti_history/core/widgets/option_icon.dart';
import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/history_sheet.dart';

const periodLabels = ['Всё время', 'Сегодня', '7 дней'];

Future<int?> showPeriodPicker(BuildContext context, int selected) =>
    showHistorySheet<int>(context, (_) => _PeriodPicker(selected: selected));

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.selected});
  final int selected;
  static const _icons = [
    Icons.all_inclusive_rounded,
    Icons.today_outlined,
    Icons.date_range_rounded,
  ];

  @override
  Widget build(BuildContext context) => HistorySheet(
    header: Center(
      child: Text(
        tr(context, 'Период уведомлений'),
        style: const TextStyle(
          fontFamily: titleFont,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    children: [
      Material(
        color: ui(context).surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < periodLabels.length; index++) ...[
              if (index > 0)
                Divider(height: 1, thickness: 1, color: ui(context).divider),
              Semantics(
                selected: selected == index,
                button: true,
                child: InkWell(
                  onTap: () => Navigator.pop(context, index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        OptionIcon(
                          icon: _icons[index],
                          selected: selected == index,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr(context, periodLabels[index]),
                            style: TextStyle(
                              fontSize: 14,
                              color: selected == index
                                  ? ui(context).accent
                                  : ui(context).ink,
                            ),
                          ),
                        ),
                        if (selected == index)
                          Icon(
                            Icons.check_rounded,
                            color: ui(context).accent,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
