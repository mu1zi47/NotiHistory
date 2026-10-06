import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/system_bars.dart';

class HistoryAppBar extends StatelessWidget {
  const HistoryAppBar({super.key});

  @override
  Widget build(BuildContext context) => SliverAppBar(
    pinned: true,
    toolbarHeight: 64,
    backgroundColor: paper,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: transparentSystemBars,
    title: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'NotiHistory',
          style: TextStyle(
            fontFamily: titleFont,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
