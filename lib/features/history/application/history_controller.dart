import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/capture_status.dart';
import '../domain/history_page.dart';
import '../domain/history_repository.dart';
import '../domain/saved_app.dart';
import '../domain/saved_notification.dart';

/// Owns queries and lifecycle; no BuildContext, navigation or platform channels.
class HistoryController extends ChangeNotifier {
  HistoryController(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final HistoryRepository repository;
  final DateTime Function() _now;
  StreamSubscription<void>? _subscription;
  Timer? _searchTimer, _changeTimer;
  int _generation = 0;
  bool _disposed = false, _foreground = true, _dirty = false, _started = false;
  bool _busy = false, _loadingMore = false, _clearing = false, _hasMore = false;
  bool _hasOverview = false;
  String _search = '';
  String? _error;
  Set<String> _packageNames = const {};
  int _period = 0, _since = 0, _matched = 0, _total = 0;
  CaptureStatus _status = const CaptureStatus();
  List<SavedNotification> _items = const [];
  List<SavedApp> _apps = const [];

  CaptureStatus get status => _status;
  List<SavedNotification> get items => _items;
  List<SavedApp> get apps => _apps;
  String get search => _search;
  Set<String> get packageNames => _packageNames;
  String? get error => _error;
  int get period => _period;
  int get matched => _matched;
  int get total => _total;
  bool get loading => _busy;
  bool get loadingMore => _loadingMore;
  bool get clearing => _clearing;
  bool get hasMore => _hasMore;
  bool get filtered =>
      _search.isNotEmpty || _packageNames.isNotEmpty || _period != 0;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscription = repository.changes.listen(
      (_) => _changed(),
      onError: (_) {
        _error =
            'Не удалось обновить историю. Потяните экран вниз для повтора.';
        _emit();
      },
    );
    await refresh();
  }

  void setForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (!foreground) {
      _changeTimer?.cancel();
      _changeTimer = null;
      _searchTimer?.cancel();
    } else {
      unawaited(refresh(preserveItems: true));
    }
  }

  void _changed() {
    _dirty = true;
    if (!_foreground ||
        _clearing ||
        _busy ||
        _loadingMore ||
        _searchTimer?.isActive == true) {
      return;
    }
    // Fixed window: a constant notification stream cannot postpone updates forever.
    _changeTimer ??= Timer(const Duration(milliseconds: 400), () {
      _changeTimer = null;
      if (!_disposed && _foreground) unawaited(refresh(preserveItems: true));
    });
  }

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;
    _invalidate();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 280), () {
      _searchTimer = null;
      unawaited(refresh(includeOverview: false, readStatus: false));
    });
  }

  Future<void> setPackage(String? value) async {
    await setPackages(value == null ? const {} : {value});
  }

  Future<void> setPackages(Set<String> values) async {
    if (_samePackages(_packageNames, values)) return;
    _packageNames = Set.unmodifiable(values);
    _searchTimer?.cancel();
    await refresh(includeOverview: false, readStatus: false);
  }

  Future<void> setPeriod(int value) async {
    if (_period == value) return;
    _period = value;
    _searchTimer?.cancel();
    await refresh(includeOverview: false, readStatus: false);
  }

  Future<void> resetFilters() async {
    _search = '';
    _packageNames = const {};
    _period = 0;
    _searchTimer?.cancel();
    await refresh(includeOverview: false, readStatus: false);
  }

  void _invalidate() {
    ++_generation;
    _busy = true;
    _loadingMore = false;
    _error = null;
    _emit();
  }

  Future<void> refresh({
    bool includeOverview = true,
    bool readStatus = true,
    bool preserveItems = false,
  }) async {
    if (_disposed) return;
    _changeTimer?.cancel();
    _changeTimer = null;
    final refreshOverview = includeOverview || _dirty || !_hasOverview;
    final refreshStatus = readStatus || _dirty || !_hasOverview;
    _dirty = false;
    final oldItems = _items;
    final oldHasMore = _hasMore;
    _invalidate();
    final generation = _generation;
    final now = _now();
    _since = switch (_period) {
      1 => DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
      2 => now.subtract(const Duration(days: 7)).millisecondsSinceEpoch,
      _ => 0,
    };
    try {
      // Start independent reads together, always await both (including failures).
      final results = await Future.wait<Object>([
        if (refreshStatus) repository.status(),
        repository.query(
          search: _search,
          packageNames: _packageNames,
          since: _since,
          includeOverview: refreshOverview,
        ),
      ]);
      if (!_current(generation)) return;
      if (refreshStatus) _status = results.first as CaptureStatus;
      final page = results.last as HistoryPage;
      final overlaps =
          page.items.isNotEmpty &&
          oldItems.any((old) => old.id == page.items.last.id);
      if (preserveItems && overlaps) {
        _items = List.unmodifiable([
          ...page.items,
          ...oldItems.where(
            (item) =>
                item.id < page.items.last.id &&
                item.savedAt.millisecondsSinceEpoch >= _since,
          ),
        ]);
        _hasMore = oldHasMore;
      } else {
        _items = List.unmodifiable(page.items);
        _hasMore = page.hasMore;
      }
      _matched = page.matched;
      if (refreshOverview) {
        _apps = List.unmodifiable(page.apps);
        _total = page.total;
        _hasOverview = true;
      }
    } catch (_) {
      if (_current(generation)) {
        _error = 'Не удалось загрузить историю. Попробуйте ещё раз.';
      }
    } finally {
      if (_current(generation)) {
        _busy = false;
        _emit();
        if (_dirty) _changed();
      }
    }
  }

  Future<void> loadMore() async {
    if (_disposed || _busy || _loadingMore || !_hasMore || _items.isEmpty) {
      return;
    }
    final generation = _generation;
    _loadingMore = true;
    _emit();
    try {
      final page = await repository.query(
        search: _search,
        packageNames: _packageNames,
        since: _since,
        beforeId: _items.last.id,
        includeOverview: false,
      );
      if (!_current(generation)) return;
      _items = List.unmodifiable([..._items, ...page.items]);
      _hasMore = page.hasMore;
    } catch (_) {
      if (_current(generation)) {
        _error = 'Не удалось загрузить следующую страницу.';
      }
    } finally {
      if (_current(generation)) {
        _loadingMore = false;
        _emit();
        if (_dirty) _changed();
      }
    }
  }

  Future<void> openAccess() async {
    if (_status.granted && !_status.connected) await repository.reconnect();
    await repository.openAccess();
  }

  Future<void> clear() async {
    if (_clearing || _disposed) return;
    _searchTimer?.cancel();
    _changeTimer?.cancel();
    _changeTimer = null;
    ++_generation; // Do not let a pre-clear response resurrect deleted entries.
    _clearing = true;
    _emit();
    try {
      await repository.clear(
        search: _search,
        packageNames: _packageNames,
        since: _since,
      );
      if (_disposed) return;
      _items = const [];
      _hasMore = false;
      await refresh();
    } finally {
      _clearing = false;
      _busy = false;
      _loadingMore = false;
      _emit();
      if (_dirty) _changed();
    }
  }

  Future<void> delete(int id) async {
    if (_disposed) return;
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final removed = _items[index];
    _searchTimer?.cancel();
    ++_generation;
    _busy = false;
    _loadingMore = false;
    await repository.delete(id);
    if (_disposed) return;
    _items = List.unmodifiable(_items.where((item) => item.id != id));
    if (_matched > 0) _matched--;
    if (_total > 0) _total--;
    _apps = List.unmodifiable([
      for (final app in _apps)
        if (app.packageName != removed.packageName)
          app
        else if (app.count > 1)
          SavedApp(app.packageName, app.name, app.count - 1),
    ]);
    if (!_apps.any((app) => app.packageName == removed.packageName)) {
      _packageNames = Set.unmodifiable(
        _packageNames.where((name) => name != removed.packageName),
      );
    }
    _emit();
  }

  bool _samePackages(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  bool _current(int generation) => !_disposed && generation == _generation;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchTimer?.cancel();
    _changeTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
