# Блокировка установки Google Play Защитой

Сообщение «Приложение заблокировано для защиты устройства» с упоминанием финансового мошенничества соответствует защите от установки приложений из интернет-источников с чувствительными разрешениями. Google прямо относит Notification Listener к таким возможностям.

Источник: https://developers.google.com/android/play-protect/warning-dev-guidance

NotiHistory использует NotificationListenerService для основной функции — локальной истории уведомлений. Удаление сервиса лишит приложение этой функции. Изменение имени пакета, подписи или версии SDK само по себе не гарантирует снятия блокировки.

## Проверенный локальный APK

Файл: `build/app/outputs/flutter-apk/NotiHistory-1.0.0-release.apk`.

- Package: `uz.mu1zi47.notihistory`.
- Version: `1.0.0` (1).
- minSdk: 24; targetSdk: 36.
- Разрешений INTERNET, SMS и Accessibility нет.
- Notification Listener объявлен как сервис с защитой `BIND_NOTIFICATION_LISTENER_SERVICE`.
- SHA-256: `a7bb5ff23672e5e58ecc7dc98c7c7edb03250026ac2045adf9d467cff32f707b`.

Это сведения о локальном APK, а не подтверждение, что сайт отдаёт тот же файл. Для обращения нужен именно APK, установка которого блокируется.

## Следующий шаг

1. Сверить скачиваемый с сайта APK с локальным по SHA-256.
2. Загрузить блокируемый APK на VirusTotal: форма Google запрашивает SHA-256 загруженного туда файла.
3. Подать апелляцию: https://support.google.com/googleplay/android-developer/contact/protectappeals
4. Приложить описание назначения, локального хранения и явного согласия пользователя; добавить ссылку на исходники и скриншот блокировки.

Черновик пояснения для формы (проверьте соответствие отправляемой сборке):

> NotiHistory is an Android notification history application. NotificationListenerService is required for its core functionality: saving notification content locally for the user to review. Notification access is enabled explicitly by the user in Android settings. The application stores history locally in SQLite, has no INTERNET permission in the release build, and does not transmit notification content to a server. Users can delete their history and revoke notification access in Android settings. Please review the installation block shown as “App blocked to protect your device”.

Release APK подписан отдельным постоянным ключом `android/keystore/notihistory-release.jks`. Настройки подписи — в `android/key.properties`. Оба файла исключены из Git; сохраните их резервную копию для будущих обновлений. Новый пакет устанавливается отдельно от прежнего `com.example.noti_history`; старая история автоматически не переносится. Смена пакета и подписи не гарантирует снятия Play Protect блокировки.
