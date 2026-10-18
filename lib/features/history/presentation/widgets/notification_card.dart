import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/saved_notification.dart';
import '../../domain/saved_app.dart';
import '../../domain/history_repository.dart';
import '../../../../core/formatting/notification_date.dart';
import 'app_avatar.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.repository,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.showTopBorder = false,
    this.showBottomBorder = true,
  });
  final SavedNotification item;
  final HistoryRepository repository;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final bool showTopBorder;
  final bool showBottomBorder;
  @override
  Widget build(BuildContext context) => Material(
    color: ui(context).surface,
    borderRadius: borderRadius,
    child: InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: showTopBorder
                ? BorderSide(color: ui(context).divider)
                : BorderSide.none,
            bottom: showBottomBorder
                ? BorderSide(color: ui(context).divider)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              app: SavedApp(item.packageName, item.appName, 0),
              repository: repository,
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: ui(context).muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        notificationTime(item.savedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: ui(context).muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    item.title.isEmpty ? item.appName : item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: titleFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    item.body.isEmpty
                        ? (item.hasImage
                              ? tr(context, 'Фотография')
                              : tr(
                                  context,
                                  'Уведомление без доступного текста',
                                ))
                        : item.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: ui(context).muted,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  if (item.hasImage && item.body.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        tr(context, 'Фотография'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: ui(context).muted,
                          fontWeight: FontWeight.w600,
                        ),
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
