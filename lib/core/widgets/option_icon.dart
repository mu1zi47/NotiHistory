import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OptionIcon extends StatelessWidget {
  const OptionIcon({super.key, required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: selected ? const Color(0xff7962c5) : ui(context).accentSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: selected ? Colors.white : ui(context).accent),
  );
}
