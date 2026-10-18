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
      for (var index = 0; index < CaptureAppFilter.values.length; index++)
        Padding(
          padding: EdgeInsets.only(
            bottom: index == CaptureAppFilter.values.length - 1 ? 0 : 8,
          ),
          child: Semantics(
            selected: selected == CaptureAppFilter.values[index],
            button: true,
            child: Material(
              key: ValueKey(
                'capture-filter-${CaptureAppFilter.values[index].name}',
              ),
              color: selected == CaptureAppFilter.values[index]
                  ? ui(context).accentSurface
                  : ui(context).surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected == CaptureAppFilter.values[index]
                      ? ui(context).accent.withValues(alpha: .5)
                      : ui(context).divider,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () =>
                    Navigator.pop(context, CaptureAppFilter.values[index]),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected == CaptureAppFilter.values[index]
                              ? ui(context).accent
                              : ui(context).paper,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _icons[index],
                          color: selected == CaptureAppFilter.values[index]
                              ? ui(context).paper
                              : ui(context).muted,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, CaptureAppFilter.values[index].title),
                              style: TextStyle(
                                fontFamily: titleFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        selected == CaptureAppFilter.values[index]
                            ? Icons.check_rounded
                            : null,
                        size: 24,
                        color: selected == CaptureAppFilter.values[index]
                            ? ui(context).accent
                            : ui(context).divider,
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
