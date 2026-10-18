import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    this.label,
    this.badgeCount = 0,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final String? label;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: onTap == null
          ? ui(context).accentSurface.withValues(alpha: .55)
          : ui(context).accentSurface,
      borderRadius: BorderRadius.circular(actionRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(actionRadius),
        child: SizedBox(
          height: 42,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: 10,
              end: label == null ? 10 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: onTap == null
                      ? ui(context).accent.withValues(alpha: .45)
                      : ui(context).accent,
                ),
                if (label != null) ...[
                  SizedBox(width: 4),
                  Text(
                    label!,
                    style: TextStyle(
                      color: onTap == null
                          ? ui(context).accent.withValues(alpha: .45)
                          : ui(context).accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (badgeCount > 0) ...[
                  SizedBox(width: 3),
                  Text(
                    '$badgeCount',
                    key: ValueKey('action-count-$tooltip'),
                    style: TextStyle(
                      color: onTap == null
                          ? ui(context).accent.withValues(alpha: .45)
                          : ui(context).accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
