import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });
  final IconData icon;
  final String title, message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 32, 16, 38),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: ui(context).accentSurface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, color: ui(context).accent, size: 37),
        ),
        SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: titleFont,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ui(context).muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.6,
          ),
        ),
        ...actions,
      ],
    ),
  );
}
