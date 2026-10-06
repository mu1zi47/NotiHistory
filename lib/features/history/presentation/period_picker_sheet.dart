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
    children: [
      Row(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Период уведомлений',
                style: TextStyle(
                  fontFamily: titleFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      for (var index = 0; index < periodLabels.length; index++)
        Padding(
          padding: EdgeInsets.only(
            bottom: index == periodLabels.length - 1 ? 0 : 8,
          ),
          child: Semantics(
            selected: selected == index,
            button: true,
            child: Material(
              color: selected == index ? accentSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected == index
                      ? accent.withValues(alpha: .5)
                      : const Color(0xFFECE9F3),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context, index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected == index ? accent : paper,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _icons[index],
                          color: selected == index ? Colors.white : muted,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              periodLabels[index],
                              style: const TextStyle(
                                fontFamily: titleFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        selected == index ? Icons.check_rounded : null,
                        size: 24,
                        color: selected == index
                            ? accent
                            : const Color(0xFFDAD5E7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
