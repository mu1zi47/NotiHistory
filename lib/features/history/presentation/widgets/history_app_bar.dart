import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/system_bars.dart';

class HistoryAppBar extends StatelessWidget {
  const HistoryAppBar({super.key, this.onSettings, this.onScrollToTop});
  final VoidCallback? onSettings;
  final VoidCallback? onScrollToTop;

  @override
  Widget build(BuildContext context) => SliverAppBar(
    pinned: true,
    toolbarHeight: 64,
    backgroundColor: ui(context).paper,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
        ? transparentDarkSystemBars
        : transparentSystemBars,
    flexibleSpace: Semantics(
      button: true,
      label: tr(context, 'Прокрутить наверх'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onScrollToTop,
        child: SizedBox.expand(),
      ),
    ),
    actions: [
      IconButton(
        onPressed: onSettings,
        tooltip: tr(context, 'Настройки'),
        icon: Icon(Icons.settings_outlined),
      ),
      SizedBox(width: 8),
    ],
    title: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onScrollToTop,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'NotiHistory',
            style: TextStyle(
              fontFamily: titleFont,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
