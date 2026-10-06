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
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.showTopBorder = true,
  });
  final SavedNotification item;
  final HistoryRepository repository;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final bool showTopBorder;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: borderRadius,
    child: InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border(
            top: showTopBorder
                ? const BorderSide(color: Color(0xFFEEECF4))
                : BorderSide.none,

            bottom: const BorderSide(color: Color(0xFFEEECF4)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              app: SavedApp(item.packageName, item.appName, 0),
              repository: repository,
            ),
            const SizedBox(width: 13),
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        notificationTime(item.savedAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title.isEmpty ? item.appName : item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: titleFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.body.isEmpty
                        ? (item.hasImage
                              ? 'Фотография'
                              : 'Уведомление без доступного текста')
                        : item.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: muted,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  if (item.hasImage && item.body.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Фотография',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: muted,
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
