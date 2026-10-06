import 'dart:typed_data';

import 'capture_status.dart';
import 'history_page.dart';

/// Boundary between application logic and the Android platform.
abstract interface class HistoryRepository {
  Stream<void> get changes;
  Future<CaptureStatus> status();
  Future<HistoryPage> query({
    String search = '',
    Set<String> packageNames = const <String>{},
    int since = 0,
    int? beforeId,
    bool includeOverview = true,
  });
  Future<void> openAccess();
  Future<void> openNotification(int id, {String packageName = ''});
  Future<bool> canOpenNotification(int id, {String packageName = ''});
  Future<void> reconnect();
  Future<void> clear({
    String search = '',
    Set<String> packageNames = const <String>{},
    int since = 0,
  });
  Future<void> delete(int id);
  Future<Uint8List?> image(int id);
  Future<Uint8List?> icon(String packageName);
}
