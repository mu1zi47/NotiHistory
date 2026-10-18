import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings(this.language);
  final String language;
  static const delegate = _AppStringsDelegate();
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override
  bool isSupported(Locale locale) => ['ru', 'en'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale.languageCode));
  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

String tr(
  BuildContext context,
  String key, [
  List<Object?> arguments = const [],
]) {
  final language =
      Localizations.of<AppStrings>(context, AppStrings)?.language ?? 'ru';
  var value = language == 'en' ? english[key] ?? key : key;
  if (language == 'en' &&
      key == '{0} уведомлений' &&
      arguments.firstOrNull == 1) {
    value = '{0} notification';
  }
  for (var i = 0; i < arguments.length; i++) {
    value = value.replaceAll('{$i}', '${arguments[i]}');
  }
  return value;
}

const english = <String, String>{
  'Закрыть': 'Close',
  'Настройки': 'Settings',
  'Уведомления': 'Notifications',
  'Сохранение уведомлений': 'Notification capture',
  'Выберите приложения для сохранения в историю':
      'Choose which apps to save in your history',
  'Показывать приложения': 'Show apps',
  'Найти приложение': 'Search apps',
  'Закрыть поиск': 'Close search',
  'Поиск': 'Search',
  'Фильтр приложений': 'App filter',
  'Включить все': 'Enable all',
  'Включаем…': 'Enabling…',
  'Не удалось сохранить настройку. Попробуйте снова.':
      'Could not save this setting. Try again.',
  'Не удалось включить все приложения. Попробуйте снова.':
      'Could not enable all apps. Try again.',
  'В историю попадают уведомления только от выбранных приложений.':
      'Only notifications from selected apps are saved to your history.',
  'Не удалось загрузить приложения': 'Could not load apps',
  'Повторить': 'Retry',
  'Приложения не найдены': 'No apps found',
  'Нет включённых приложений': 'No enabled apps',
  'Нет выключенных приложений': 'No disabled apps',
  'Попробуйте другой запрос или сбросьте фильтры.':
      'Try another search or reset your filters.',
  'Сбросить фильтры': 'Reset filters',
  'Сохранение включено: {0} из {1}': 'Capture enabled: {0} of {1}',
  'Закрыть меню': 'Close menu',
  'Удалить уведомление': 'Delete notification',
  'Только выбранное сообщение': 'Only this message',
  'Удалить все уведомления': 'Delete all notifications',
  'Вся история этого приложения': 'All history for this app',
  'Отключить сохранение': 'Disable capture',
  'Не сохранять новые уведомления': 'Stop saving new notifications',
  'Не удалось удалить уведомления. Попробуйте снова.':
      'Could not delete notifications. Try again.',
  'Показать все': 'Show all',
  'Применить · {0}': 'Apply · {0}',
  'Все приложения': 'All apps',
  'Показывать уведомления от всех приложений':
      'Show notifications from all apps',
  '{0} уведомлений': '{0} notifications',
  'Не удалось открыть настройки Android.': 'Could not open Android settings.',
  'История очищена': 'History cleared',
  'Не удалось очистить историю. Попробуйте снова.':
      'Could not clear history. Try again.',
  'Уведомления от «{0}» удалены': 'Notifications from “{0}” deleted',
  'Не удалось удалить уведомление. Попробуйте снова.':
      'Could not delete the notification. Try again.',
  'Сохранение от «{0}» выключено': 'Capture disabled for “{0}”',
  'Не удалось изменить настройку. Попробуйте снова.':
      'Could not change this setting. Try again.',
  'Переход недоступен.': 'This destination is unavailable.',
  'Перейти': 'Open',
  'Android не передал текст этого уведомления.':
      'Android did not provide any text for this notification.',
  'Период уведомлений': 'Notification period',
  'Удалить уведомления приложения?': 'Delete this app’s notifications?',
  'Очистить по фильтру?': 'Clear filtered notifications?',
  'Очистить всю историю?': 'Clear all history?',
  'Все сохранённые уведомления от «{0}» будут удалены. Вернуть их не получится.': 'All saved notifications from “{0}” will be deleted. This cannot be undone.',
  'Уведомления, соответствующие текущим фильтрам и поиску, будут удалены. Вернуть их не получится.': 'Notifications matching your current filters and search will be deleted. This cannot be undone.',
  'Все сохранённые уведомления будут удалены с телефона. Вернуть их не получится. Новые уведомления продолжат сохраняться.': 'All saved notifications will be deleted from this phone. This cannot be undone. New notifications will still be saved.',
  'Отмена': 'Cancel',
  'Удалить': 'Delete',
  'Удалить всё': 'Delete all',
  'Скопировано': 'Copied',
  'Не удалось скопировать': 'Could not copy',
  'Скопировать текст': 'Copy text',
  'Показать ещё': 'Load more',
  'Наверх': 'Back to top',
  'К началу дня: {0}': 'Go to the start of {0}',
  'Фотография': 'Photo',
  'Уведомление без доступного текста': 'Notification text is unavailable',
  'Выбрать период': 'Choose period',
  'Изображение из уведомления': 'Notification image',
  'Не удалось открыть изображение': 'Could not open the image',
  'Закрыть изображение': 'Close image',
  'Ничего не нашлось': 'Nothing found',
  'Здесь начнётся ваша история': 'Your history starts here',
  'Следующее уведомление появится здесь.':
      'Your next notification will appear here.',
  'Разрешите доступ — и новые уведомления будут сохраняться автоматически.':
      'Allow notification access to automatically save new notifications.',
  'Проверить доступ': 'Check access',
  'Включить сохранение': 'Enable capture',
  'Поиск уведомлений': 'Search notifications',
  'Фильтр': 'Filter',
  'Очистить по фильтру': 'Clear filtered notifications',
  'Очистить всё': 'Clear all',
  'Очистить': 'Clear',
  'Прокрутить наверх': 'Scroll to top',
  'Сохранение доступно на Android': 'Capture is available on Android',
  'Проверьте сохранение': 'Check notification capture',
  'Ожидаем подключения Android': 'Waiting for Android to connect',
  'Разрешите сохранять уведомления': 'Allow notification capture',
  'iOS, web и desktop не дают этому приложению доступ к уведомлениям других приложений.': 'iOS, web and desktop do not give this app access to other apps’ notifications.',
  'Если подключение не появилось, выключите и снова включите доступ для NotiHistory.': 'If capture does not connect, turn notification access for NotiHistory off and on again.',
  'NotiHistory будет читать и сохранять текст уведомлений других приложений, включая личные сообщения. История хранится только на телефоне и не отправляется на сервер. Сохранение продолжается после закрытия приложения. Вы можете удалить историю в приложении и отключить доступ в настройках Android.': 'NotiHistory reads and saves notification text from other apps, including private messages. History stays on your phone and is never uploaded. Capture continues when the app is closed. You can delete your history in the app and revoke access in Android settings.',
  'Не удалось прочитать или изменить историю.':
      'Could not read or update history.',
  'Всё время': 'All time',
  'Сегодня': 'Today',
  'Вчера': 'Yesterday',
  '7 дней': '7 days',
  'Включённые': 'Enabled',
  'Выключенные': 'Disabled',
  'Настройки приложения': 'App settings',
  'Версия приложения: {0}': 'App version: {0}',
  'Язык': 'Language',
  'Тема': 'Theme',
  'Русский': 'Русский',
  'Английский': 'English',
  'Как на устройстве': 'System default',
  'Светлая': 'Light',
  'Тёмная': 'Dark',
  'Не удалось обновить историю. Потяните экран вниз для повтора.':
      'Could not refresh history. Pull down to retry.',
  'Не удалось загрузить историю. Попробуйте ещё раз.':
      'Could not load history. Try again.',
  'Не удалось загрузить следующую страницу.': 'Could not load the next page.',
  'Не удалось сохранить уведомление. Проверьте свободное место на телефоне.': 'Could not save the notification. Check the available storage on your phone.',
  'Не удалось открыть настройки доступа.':
      'Could not open notification access settings.',
  'Уведомление и приложение недоступны.':
      'The notification and app are unavailable.',
};
