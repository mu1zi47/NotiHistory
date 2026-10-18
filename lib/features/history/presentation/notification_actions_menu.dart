import 'package:noti_history/core/l10n/app_strings.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum NotificationAction { delete, clearApp, disableApp }

Future<NotificationAction?> showNotificationActionsMenu(
  BuildContext context,
  Offset position,
  String appName,
) => showGeneralDialog<NotificationAction>(
  context: context,
  barrierDismissible: true,
  barrierLabel: tr(context, 'Закрыть меню'),
  barrierColor: ui(context).dark
      ? Colors.black.withValues(alpha: .45)
      : ink.withValues(alpha: .16),
  transitionDuration: Duration(milliseconds: 200),
  pageBuilder: (context, _, _) {
    final screen = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final width = math.min(326.0, screen.width - 24);
    final height = math.min(310.0, screen.height - safe.top - safe.bottom - 24);
    final left = (position.dx - width + 24).clamp(
      12.0,
      screen.width - width - 12,
    );
    final top = (position.dy + 8).clamp(
      safe.top + 12,
      screen.height - safe.bottom - height - 12,
    );
    Widget action(
      NotificationAction value,
      IconData icon,
      String title,
      String subtitle, {
      bool destructive = false,
    }) {
      final color = destructive ? ui(context).deleteInk : ui(context).accent;
      return Material(
        key: ValueKey('notification-action-${value.name}'),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(value),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: destructive
                        ? ui(context).deleteSurface
                        : ui(context).accentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 21, color: color),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: ui(context).ink,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: ui(context).muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: Material(
              key: ValueKey('notification-actions-menu'),
              color: ui(context).surface,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Text(
                        appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: titleFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ui(context).ink,
                        ),
                      ),
                    ),
                    action(
                      NotificationAction.delete,
                      Icons.delete_outline_rounded,
                      tr(context, 'Удалить уведомление'),
                      tr(context, 'Только выбранное сообщение'),
                      destructive: true,
                    ),
                    action(
                      NotificationAction.clearApp,
                      Icons.delete_sweep_outlined,
                      tr(context, 'Удалить все уведомления'),
                      tr(context, 'Вся история этого приложения'),
                      destructive: true,
                    ),
                    action(
                      NotificationAction.disableApp,
                      Icons.notifications_off_outlined,
                      tr(context, 'Отключить сохранение'),
                      tr(context, 'Не сохранять новые уведомления'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  },
  transitionBuilder: (context, animation, _, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Transform the positioned menu without moving its screen-space anchor.
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, -.012),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);
