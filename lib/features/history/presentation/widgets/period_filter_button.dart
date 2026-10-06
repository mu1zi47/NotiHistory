import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../period_picker_sheet.dart';

class PeriodFilterButton extends StatelessWidget {
  const PeriodFilterButton({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Выбрать период',
    child: Material(
      color: accentSurface,
      borderRadius: BorderRadius.circular(actionRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(actionRadius),
        onTap: () async {
          final value = await showPeriodPicker(context, selected);
          if (value != null && context.mounted) onSelected(value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 4),
              Text(
                periodLabels[selected],
                style: const TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.expand_more_rounded, size: 16, color: accent),
            ],
          ),
        ),
      ),
    ),
  );
}
