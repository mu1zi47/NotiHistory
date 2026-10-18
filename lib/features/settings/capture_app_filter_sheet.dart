import 'package:noti_history/core/widgets/option_icon.dart';
import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../history/presentation/widgets/history_sheet.dart';
import 'capture_app_filter.dart';

Future<CaptureAppFilter?> showCaptureAppFilter(
  BuildContext context,
  CaptureAppFilter selected,
) => showHistorySheet<CaptureAppFilter>(
  context,
  (_) => _CaptureAppFilterPicker(selected: selected),
  enableDrag: false,
);

class _CaptureAppFilterPicker extends StatelessWidget {
  const _CaptureAppFilterPicker({required this.selected});
  final CaptureAppFilter selected;
  static const _icons = [
    Icons.apps_rounded,
    Icons.notifications_active_outlined,
    Icons.notifications_off_outlined,
  ];

  @override
  Widget build(BuildContext context) => HistorySheet(
    header: Center(
      child: Text(
        tr(context, 'Показывать приложения'),
        style: TextStyle(
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
            for (
              var index = 0;
              index < CaptureAppFilter.values.length;
              index++
            ) ...[
              if (index > 0)
                Divider(height: 1, thickness: 1, color: ui(context).divider),
              Semantics(
                selected: selected == CaptureAppFilter.values[index],
                button: true,
                child: InkWell(
                  key: ValueKey(
                    'capture-filter-${CaptureAppFilter.values[index].name}',
                  ),
                  onTap: () =>
                      Navigator.pop(context, CaptureAppFilter.values[index]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        OptionIcon(
                          icon: _icons[index],
                          selected: selected == CaptureAppFilter.values[index],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr(context, CaptureAppFilter.values[index].title),
                            style: TextStyle(
                              fontSize: 14,
                              color: selected == CaptureAppFilter.values[index]
                                  ? ui(context).accent
                                  : ui(context).ink,
                            ),
                          ),
                        ),
                        if (selected == CaptureAppFilter.values[index])
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
