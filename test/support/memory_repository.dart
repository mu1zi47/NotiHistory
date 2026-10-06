import 'dart:typed_data';

import 'package:noti_history/features/history/domain/capture_status.dart';
import 'package:noti_history/features/history/domain/history_page.dart';
import 'package:noti_history/features/history/domain/history_repository.dart';
import 'package:noti_history/features/history/domain/saved_app.dart';
import 'package:noti_history/features/history/domain/saved_notification.dart';

class MemoryRepository implements HistoryRepository {
  bool granted = true;
  int? openedNotification;
  bool notificationAvailable = true;
  @override
  Future<bool> canOpenNotification(int id, {String packageName = ''}) async =>
      notificationAvailable;
  @override
  Future<void> openNotification(int id, {String packageName = ''}) async {
    openedNotification = id;
  }

  int clearCalls = 0;
  String lastSearch = '';
  int lastSince = 0;
  Set<String> lastPackages = const {};
  final entries = [
    SavedNotification(
      id: 2,
      packageName: 'org.telegram',
      appName: 'Telegram',
      title: 'Аня',
      body: 'Встретимся у кофейни',
      subText: '',
      postedAt: DateTime.now(),
      savedAt: DateTime.now(),
    ),
    SavedNotification(
      id: 1,
      packageName: 'com.mail',
      appName: 'Почта',
      title: 'Билеты',
      body: 'Ваш рейс завтра',
      subText: '',
      postedAt: DateTime.now(),
      savedAt: DateTime.now(),
    ),
  ];
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<void> openAccess() async {}
  @override
  Future<void> reconnect() async {}
  @override
  Future<Uint8List?> image(int id) async => null;
  @override
  Future<Uint8List?> icon(String packageName) async => null;
  @override
  Future<CaptureStatus> status() async =>
      CaptureStatus(granted: granted, connected: granted);
  @override
  Future<void> clear({
    String search = '',
    Set<String> packageNames = const <String>{},
    int since = 0,
  }) async {
    clearCalls++;
    entries.removeWhere(
      (e) =>
          (packageNames.isEmpty || packageNames.contains(e.packageName)) &&
          e.savedAt.millisecondsSinceEpoch >= since &&
          '${e.appName}\n${e.packageName}\n${e.title}\n${e.body}\n${e.subText}'
              .toLowerCase()
              .contains(search.trim().toLowerCase()),
    );
  }

  @override
  Future<void> delete(int id) async {
    entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<HistoryPage> query({
    String search = '',
    Set<String> packageNames = const <String>{},
    int since = 0,
    int? beforeId,
    bool includeOverview = true,
  }) async {
    lastSearch = search;
    lastSince = since;
    lastPackages = Set.unmodifiable(packageNames);
    final matches = entries
        .where(
          (e) =>
              (packageNames.isEmpty || packageNames.contains(e.packageName)) &&
              e.savedAt.millisecondsSinceEpoch >= since &&
              '${e.appName} ${e.packageName} ${e.title} ${e.body} ${e.subText}'
                  .toLowerCase()
                  .contains(search.toLowerCase()),
        )
        .toList();
    return HistoryPage(
      items: matches,
      apps: entries.map((e) => SavedApp(e.packageName, e.appName, 1)).toList(),
      total: entries.length,
      today: entries.length,
      matched: matches.length,
    );
  }
}
