import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/capture_status.dart';

class AccessCard extends StatelessWidget {
  const AccessCard({super.key, required this.status, required this.onAccess});
  final CaptureStatus status;
  final VoidCallback onAccess;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !status.supported
                        ? 'Сохранение доступно на Android'
                        : status.error != null
                        ? 'Проверьте сохранение'
                        : status.granted
                        ? 'Ожидаем подключения Android'
                        : 'Разрешите сохранять уведомления',
                    style: const TextStyle(
                      fontFamily: titleFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    !status.supported
                        ? 'iOS, web и desktop не дают этому приложению доступ к уведомлениям других приложений.'
                        : status.error ??
                              (status.granted
                                  ? 'Если подключение не появилось, выключите и снова включите доступ для NotiHistory.'
                                  : 'NotiHistory будет читать и сохранять текст уведомлений других приложений, включая личные сообщения. История хранится только на телефоне и не отправляется на сервер. Сохранение продолжается после закрытия приложения. Вы можете удалить историю в приложении и отключить доступ в настройках Android.'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: muted,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (status.supported)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAccess,
                    child: Text(
                      status.granted
                          ? 'Проверить доступ'
                          : 'Включить сохранение',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
