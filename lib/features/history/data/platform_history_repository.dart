import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/capture_status.dart';
import '../domain/history_page.dart';
import '../domain/history_repository.dart';
import '../domain/saved_app.dart';
import '../domain/saved_notification.dart';

class PlatformHistoryRepository implements HistoryRepository {
  PlatformHistoryRepository({
    this._channel = const MethodChannel('notihistory/history'),
    this._events = const EventChannel('notihistory/changes'),
    bool? supported,
  }) : _supported =
           supported ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final MethodChannel _channel;
  final EventChannel _events;
  final bool _supported;
  // Bounded LRU cache also coalesces simultaneous requests for the same icon.
  final _icons = <String, Future<Uint8List?>>{};
  static const iconCacheCapacity = 80;

  @override
  late final Stream<void> changes = _supported
      ? _events.receiveBroadcastStream().map((_) {})
      : const Stream.empty();

  @override
  Future<CaptureStatus> status() async {
    if (!_supported) return const CaptureStatus(supported: false);
    final map = (await _channel.invokeMapMethod<String, dynamic>('status'))!;
    return CaptureStatus(
      granted: map['granted'] == true,
      connected: map['connected'] == true,
      error: map['error'] as String?,
    );
  }

  @override
  Future<HistoryPage> query({
    String search = '',
    Set<String> packageNames = const <String>{},
    int since = 0,
    int? beforeId,
    bool includeOverview = true,
  }) async {
    if (!_supported) return const HistoryPage();
    final map = (await _channel.invokeMapMethod<String, dynamic>('query', {
      'search': search,
      'packageNames': packageNames.toList(growable: false),
      'since': since,
      'beforeId': beforeId,
      'includeOverview': includeOverview,
    }))!;
    final stats = map['stats'] as Map?;
    return HistoryPage(
      items: (map['items'] as List)
          .map(
            (e) =>
                SavedNotification.fromMap(Map<Object?, Object?>.from(e as Map)),
          )
          .toList(growable: false),
      apps: ((map['apps'] as List?) ?? const [])
          .map(
            (e) => SavedApp(
              e['packageName'] as String,
              e['appName'] as String,
              e['count'] as int,
            ),
          )
          .toList(growable: false),
      total: stats?['total'] as int? ?? 0,
      today: stats?['today'] as int? ?? 0,
      matched: map['matched'] as int? ?? 0,
      hasMore: map['hasMore'] == true,
    );
  }

  @override
  Future<void> openAccess() async {
    if (_supported) await _channel.invokeMethod<void>('openAccess');
  }

  @override
  Future<bool> canOpenNotification(int id, {String packageName = ''}) async {
    if (!_supported) return false;
    return await _channel.invokeMethod<bool>('canOpenNotification', {
          'id': id,
          'packageName': packageName,
        }) ??
        false;
  }

  @override
  Future<void> openNotification(int id, {String packageName = ''}) async {
    if (!_supported) throw UnsupportedError('Android only');
    await _channel.invokeMethod<void>('openNotification', {
      'id': id,
      'packageName': packageName,
    });
  }

  @override
  Future<void> reconnect() async {
    if (_supported) await _channel.invokeMethod<void>('reconnect');
  }

  @override
  Future<void> clear({
    String search = '',
    Set<String> packageNames = const <String>{},
    int since = 0,
  }) async {
    if (_supported) {
      await _channel.invokeMethod<void>('clear', {
        'search': search,
        'packageNames': packageNames.toList(growable: false),
        'since': since,
      });
    }
  }

  @override
  Future<void> delete(int id) async {
    if (_supported) {
      await _channel.invokeMethod<void>('delete', {'id': id});
    }
  }

  @override
  Future<Uint8List?> image(int id) async {
    if (!_supported) return null;
    return _channel.invokeMethod<Uint8List>('image', {'id': id});
  }

  @override
  Future<Uint8List?> icon(String packageName) {
    final cached = _icons.remove(packageName);
    if (cached != null) {
      _icons[packageName] = cached;
      return cached;
    }
    final future = _loadIcon(packageName);
    _icons[packageName] = future;
    if (_icons.length > iconCacheCapacity) _icons.remove(_icons.keys.first);
    return future;
  }

  Future<Uint8List?> _loadIcon(String packageName) async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('icon', {
        'packageName': packageName,
      });
    } on PlatformException {
      return null;
    }
  }
}
