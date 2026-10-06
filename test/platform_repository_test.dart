import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/features/history/data/platform_history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('notihistory/history');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'Icon cache coalesces requests and evicts the least recently used icon',
    () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) async {
        calls++;
        return Uint8List.fromList([1, 2, 3]);
      });
      final repo = PlatformHistoryRepository(supported: true);
      final first = repo.icon('app');
      final second = repo.icon('app');
      expect(identical(first, second), true);
      await first;
      expect(calls, 1);
      for (var i = 0; i < PlatformHistoryRepository.iconCacheCapacity; i++) {
        await repo.icon('app$i');
      }
      await repo.icon('app');
      expect(calls, 82);
    },
  );

  test(
    'A lightweight cursor response does not require overview fields',
    () async {
      MethodCall? request;
      messenger.setMockMethodCallHandler(channel, (call) async {
        request = call;
        return {'items': [], 'hasMore': false};
      });
      final repo = PlatformHistoryRepository(supported: true);
      final result = await repo.query(
        packageNames: {'one.app', 'two.app'},
        beforeId: 60,
        includeOverview: false,
      );
      expect(result.items, isEmpty);
      expect(result.apps, isEmpty);
      expect((request!.arguments as Map)['includeOverview'], false);
      expect((request!.arguments as Map)['beforeId'], 60);
      expect(
        (request!.arguments as Map)['packageNames'],
        containsAll(['one.app', 'two.app']),
      );
    },
  );

  test('Open uses the exact notification id', () async {
    MethodCall? request;
    messenger.setMockMethodCallHandler(channel, (call) async {
      request = call;
      return null;
    });
    await PlatformHistoryRepository(supported: true)
        .openNotification(42, packageName: 'org.telegram.messenger');
    expect(request!.method, 'openNotification');
    expect(
      (request!.arguments as Map)['packageName'],
      'org.telegram.messenger',
    );
    expect((request!.arguments as Map)['id'], 42);
  });

  test('Clear forwards all active filters to Android', () async {
    MethodCall? request;
    messenger.setMockMethodCallHandler(channel, (call) async {
      request = call;
      return null;
    });
    await PlatformHistoryRepository(supported: true).clear(
      search: 'file',
      packageNames: {'org.telegram', 'com.mail'},
      since: 123,
    );
    expect(request!.method, 'clear');
    expect(request!.arguments, {
      'search': 'file',
      'packageNames': ['org.telegram', 'com.mail'],
      'since': 123,
    });
  });

  test('Availability checks the exact notification id', () async {
    MethodCall? request;
    messenger.setMockMethodCallHandler(channel, (call) async {
      request = call;
      return false;
    });
    expect(
      await PlatformHistoryRepository(supported: true)
          .canOpenNotification(42, packageName: 'org.telegram.messenger'),
      false,
    );
    expect(request!.method, 'canOpenNotification');
    expect(
      (request!.arguments as Map)['packageName'],
      'org.telegram.messenger',
    );
    expect((request!.arguments as Map)['id'], 42);
  });

  test('Delete sends the notification id to Android', () async {
    MethodCall? request;
    messenger.setMockMethodCallHandler(channel, (call) async {
      request = call;
      return null;
    });
    final repo = PlatformHistoryRepository(supported: true);

    await repo.delete(42);

    expect(request!.method, 'delete');
    expect((request!.arguments as Map)['id'], 42);
  });
}
