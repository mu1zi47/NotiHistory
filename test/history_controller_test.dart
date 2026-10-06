import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/features/history/application/history_controller.dart';
import 'package:noti_history/features/history/domain/history_page.dart';
import 'package:noti_history/features/history/domain/saved_notification.dart';

import 'support/memory_repository.dart';

typedef Query = ({
  String search,
  Set<String> packageNames,
  int since,
  int? beforeId,
  bool includeOverview,
});

class ControlledRepository extends MemoryRepository {
  final events = StreamController<void>.broadcast(sync: true);
  final requests = <Query>[];
  final pending = <Completer<HistoryPage>>[];
  bool hold = false;
  HistoryPage Function(Query)? response;
  @override
  Stream<void> get changes => events.stream;
  @override
  Future<HistoryPage> query({
    String search = '',
    Set<String> packageNames = const <String>{},
    int since = 0,
    int? beforeId,
    bool includeOverview = true,
  }) {
    final request = (
      search: search,
      packageNames: packageNames,
      since: since,
      beforeId: beforeId,
      includeOverview: includeOverview,
    );
    requests.add(request);
    if (hold) {
      final completer = Completer<HistoryPage>();
      pending.add(completer);
      return completer.future;
    }
    if (response != null) return Future.value(response!(request));
    return super.query(
      search: search,
      packageNames: packageNames,
      since: since,
      beforeId: beforeId,
      includeOverview: includeOverview,
    );
  }
}

SavedNotification item(int id) => SavedNotification(
  id: id,
  packageName: 'test',
  appName: 'Test',
  title: '$id',
  body: 'body $id',
  subText: '',
  postedAt: DateTime(2026, 10, 3),
  savedAt: DateTime(2026, 10, 3),
);

void main() {
  testWidgets('Fast typing makes one query without recounting overview', (
    tester,
  ) async {
    final repo = ControlledRepository();
    final c = HistoryController(repo);
    addTearDown(c.dispose);
    addTearDown(repo.events.close);
    await c.start();
    c.setSearch('к');
    c.setSearch('ко');
    c.setSearch('кофе');
    expect(repo.requests.length, 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.requests.length, 2);
    expect(repo.requests.last.includeOverview, false);
    expect(repo.requests.last.search, 'кофе');
    expect(c.apps.length, 2);
  });

  test('Multiple applications are sent in one query', () async {
    final repo = ControlledRepository();
    final c = HistoryController(repo);
    addTearDown(c.dispose);
    addTearDown(repo.events.close);
    await c.start();

    await c.setPackages({'org.telegram', 'com.mail'});

    expect(repo.requests.last.packageNames, {'org.telegram', 'com.mail'});
    expect(c.packageNames, {'org.telegram', 'com.mail'});
  });

  testWidgets('An old response cannot replace results for a new search', (
    tester,
  ) async {
    final repo = ControlledRepository();
    final c = HistoryController(repo);
    addTearDown(c.dispose);
    addTearDown(repo.events.close);
    await c.start();
    repo.hold = true;
    final old = c.refresh();
    c.setSearch('new');
    await tester.pump(const Duration(milliseconds: 300));
    repo.pending[1].complete(HistoryPage(items: [item(9)], matched: 1));
    await tester.pump();
    repo.pending[0].complete(HistoryPage(items: [item(1)]));
    await old;
    expect(c.items.single.id, 9);
    expect(c.loading, false);
  });

  testWidgets('Clearing invalidates in-flight reads', (tester) async {
    final repo = ControlledRepository();
    final c = HistoryController(repo);
    addTearDown(c.dispose);
    addTearDown(repo.events.close);
    await c.start();
    repo.hold = true;
    final old = c.refresh();
    repo.hold = false;
    await c.clear();
    repo.pending.single.complete(HistoryPage(items: [item(1)]));
    await old;
    expect(c.items, isEmpty);
    expect(c.total, 0);
    expect(c.clearing, false);
  });

  test('Clear deletes only matching apps and preserves the filter', () async {
    final repo = MemoryRepository();
    final c = HistoryController(repo);
    addTearDown(c.dispose);
    await c.start();
    await c.setPackages({'org.telegram'});
    await c.clear();
    expect(repo.entries.map((entry) => entry.packageName), ['com.mail']);
    expect(c.packageNames, {'org.telegram'});
    expect(c.items, isEmpty);
    expect(c.total, 1);
    await c.resetFilters();
    expect(c.items.single.packageName, 'com.mail');
  });

  test('Deleting removes one item and updates overview counts', () async {
    final repo = MemoryRepository();
    final c = HistoryController(repo);
    addTearDown(c.dispose);
    await c.start();

    await c.delete(2);

    expect(c.items.map((entry) => entry.id), [1]);
    expect(c.total, 1);
    expect(c.matched, 1);
    expect(c.apps.where((app) => app.packageName == 'org.telegram'), isEmpty);
    expect(repo.entries.map((entry) => entry.id), [1]);
  });

  testWidgets(
    'Cursor pages omit overview and live updates preserve older pages',
    (tester) async {
      final repo = ControlledRepository();
      var latest = 3;
      repo.response = (q) => q.beforeId == null
          ? HistoryPage(
              items: [item(latest), item(2)],
              matched: 3,
              total: 3,
              hasMore: true,
            )
          : HistoryPage(items: [item(1)]);
      final c = HistoryController(repo);
      addTearDown(c.dispose);
      addTearDown(repo.events.close);
      await c.start();
      await c.loadMore();
      expect(repo.requests.last.beforeId, 2);
      expect(repo.requests.last.includeOverview, false);
      expect(c.matched, 3);
      latest = 4;
      await c.refresh(preserveItems: true);
      expect(c.items.map((e) => e.id), [4, 2, 1]);
      expect(c.hasMore, false);
    },
  );

  testWidgets('Events coalesce and do not query while the UI is backgrounded', (
    tester,
  ) async {
    final repo = ControlledRepository();
    final c = HistoryController(repo);
    addTearDown(c.dispose);
    addTearDown(repo.events.close);
    await c.start();
    for (var i = 0; i < 100; i++) {
      repo.events.add(null);
    }
    await tester.pump(const Duration(milliseconds: 450));
    expect(repo.requests.length, 2);
    c.setForeground(false);
    for (var i = 0; i < 100; i++) {
      repo.events.add(null);
    }
    await tester.pump(const Duration(seconds: 2));
    expect(repo.requests.length, 2);
    c.setForeground(true);
    await tester.pump();
    expect(repo.requests.length, 3);
  });

  testWidgets('Late results after dispose are ignored', (tester) async {
    final repo = ControlledRepository()..hold = true;
    final c = HistoryController(repo);
    addTearDown(repo.events.close);
    final started = c.start();
    c.dispose();
    repo.pending.single.complete(const HistoryPage());
    await started;
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pagination keeps the same time boundary', (tester) async {
    final repo = ControlledRepository()
      ..response = (_) => HistoryPage(items: [item(3)], hasMore: true);
    var now = DateTime(2026, 10, 3, 12);
    final c = HistoryController(repo, now: () => now);
    addTearDown(c.dispose);
    addTearDown(repo.events.close);
    await c.start();
    await c.setPeriod(2);
    final since = repo.requests.last.since;
    now = now.add(const Duration(hours: 1));
    await c.loadMore();
    expect(repo.requests.last.since, since);
  });
}
