import 'package:noti_history/core/l10n/app_strings.dart';
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
    label: tr(context, 'Выбрать период'),
    child: Material(
      color: ui(context).accentSurface,
      borderRadius: BorderRadius.circular(actionRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(actionRadius),
        onTap: () async {
          final value = await showPeriodPicker(context, selected);
          if (value != null && context.mounted) onSelected(value);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: ui(context).accent,
              ),
              SizedBox(width: 4),
              Text(
                tr(context, periodLabels[selected]),
                style: TextStyle(
                  color: ui(context).accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 3),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: ui(context).accent,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
