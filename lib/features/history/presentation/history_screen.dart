import 'package:noti_history/core/navigation/app_page_route.dart';
import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/system_bars.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/history_controller.dart';
import '../domain/history_repository.dart';
import 'app_filter_sheet.dart';
import 'clear_history_dialog.dart';
import 'notification_details.dart';
import 'widgets/history_actions.dart';
import 'widgets/history_feed.dart';
import '../domain/saved_notification.dart';
import '../../settings/capture_settings_repository.dart';
import 'notification_actions_menu.dart';
import '../../settings/settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.repository,
    this.archived = false,
  });
  final HistoryRepository repository;
  final bool archived;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  late final HistoryController _controller;
  final _search = TextEditingController();
  int _searchReset = 0;
  final _scroll = ScrollController();
  final _feedKey = GlobalKey<HistoryFeedState>();
  bool _actionInProgress = false;
  final _openSwipe = ValueNotifier<int?>(null);
  @override
  void initState() {
    super.initState();
    _controller = HistoryController(
      widget.repository,
      archived: widget.archived,
    )..start();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 350) _controller.loadMore();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.setForeground(state == AppLifecycleState.resumed);
  }

  void _toast(String message, {bool error = false}) {
    if (mounted) showAppToast(context, message, error: error);
  }

  Future<void> _access() async {
    try {
      await _controller.openAccess();
    } catch (_) {
      if (!mounted) return;
      _toast(tr(context, 'Не удалось открыть настройки Android.'), error: true);
    }
  }

  Future<void> _clear() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!await confirmClearHistory(
          context,
          filtered: _controller.filtered,
          archived: widget.archived,
        ) ||
        !mounted) {
      return;
    }
    try {
      await _controller.clear();
      if (!mounted) return;
      _toast(tr(context, 'История очищена'));
    } catch (_) {
      if (!mounted) return;
      _toast(
        tr(context, 'Не удалось очистить историю. Попробуйте снова.'),
        error: true,
      );
    }
  }

  Future<void> _filter() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showAppFilterSheet(
      context,
      apps: _controller.apps,
      selected: _controller.packageNames,
      repository: _controller.repository,
      archived: widget.archived,
      deleteApp: (app) async {
        await _controller.clear(packageName: app.packageName);
        if (mounted) {
          _toast(tr(context, 'Уведомления от «{0}» удалены', [app.name]));
        }
        return _controller.apps;
      },
    );
    if (selected != null && mounted) await _controller.setPackages(selected);
  }

  Future<bool> _archive(int id) async {
    try {
      await _controller.archive(id);
      return true;
    } catch (_) {
      if (mounted) {
        _toast(
          tr(context, 'Не удалось переместить уведомление. Попробуйте снова.'),
          error: true,
        );
      }
      return false;
    }
  }

  Future<bool> _delete(int id) async {
    try {
      await _controller.delete(id);
      return true;
    } catch (_) {
      if (!mounted) return false;
      _toast(
        tr(context, 'Не удалось удалить уведомление. Попробуйте снова.'),
        error: true,
      );
      return false;
    }
  }

  Future<void> _notificationActions(
    SavedNotification item,
    Offset position,
  ) async {
    if (_actionInProgress) return;
    final action = await showNotificationActionsMenu(
      context,
      position,
      item.appName,
      archived: widget.archived,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case NotificationAction.archive:
        _actionInProgress = true;
        try {
          final feed = _feedKey.currentState;
          if (feed != null) {
            await feed.archiveNotification(item.id);
          } else {
            await _archive(item.id);
          }
        } finally {
          _actionInProgress = false;
        }
      case NotificationAction.delete:
        _actionInProgress = true;
        try {
          final feed = _feedKey.currentState;
          if (feed != null) {
            await feed.deleteNotification(item.id);
          } else {
            await _delete(item.id);
          }
        } finally {
          _actionInProgress = false;
        }
      case NotificationAction.clearApp:
        if (!await confirmClearHistory(
              context,
              appName: item.appName,
              archived: widget.archived,
            ) ||
            !mounted) {
          return;
        }
        _actionInProgress = true;
        try {
          final feed = _feedKey.currentState;
          if (feed != null) {
            await feed.removeApp(
              item.packageName,
              () => _controller.clear(packageName: item.packageName),
            );
          } else {
            await _controller.clear(packageName: item.packageName);
          }
          if (mounted) {
            _toast(tr(context, 'Уведомления от «{0}» удалены', [item.appName]));
          }
        } catch (_) {
          if (!mounted) return;
          _toast(
            tr(context, 'Не удалось удалить уведомления. Попробуйте снова.'),
            error: true,
          );
        } finally {
          _actionInProgress = false;
        }
      case NotificationAction.disableApp:
        try {
          await CaptureSettingsRepository().setEnabled(item.packageName, false);
          if (mounted) {
            _toast(
              tr(context, 'Сохранение от «{0}» выключено', [item.appName]),
            );
          }
        } catch (_) {
          if (!mounted) return;
          _toast(
            tr(context, 'Не удалось изменить настройку. Попробуйте снова.'),
            error: true,
          );
        }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _search.dispose();
    _scroll.dispose();
    _openSwipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark
        ? transparentDarkSystemBars
        : transparentSystemBars,
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: AnimatedPadding(
        duration: Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Material(
            key: ValueKey('history-bottom-actions'),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 728),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => HistoryActions(
                      search: _search,
                      searchReset: _searchReset,
                      onSearchChanged: _controller.setSearch,
                      onFilter: _filter,
                      filterCount: _controller.packageNames.length,
                      onClearHistory: _clear,
                      canClearHistory:
                          _controller.matched > 0 &&
                          !_controller.clearing &&
                          !_controller.loading,
                      period: _controller.period,
                      onPeriodChanged: _controller.setPeriod,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 760),
            child: HistoryFeed(
              key: _feedKey,
              controller: _controller,
              scroll: _scroll,
              openSwipe: _openSwipe,
              onDelete: _delete,
              onArchive: _archive,
              onOpenArchive: widget.archived
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        AppPageRoute<void>(
                          builder: (_) => HistoryScreen(
                            repository: widget.repository,
                            archived: true,
                          ),
                        ),
                      );
                      if (mounted) await _controller.refresh();
                    },
              onLongPress: _notificationActions,
              onAccess: _access,
              onSettings: () => Navigator.of(context).push(
                AppPageRoute<void>(
                  builder: (_) =>
                      SettingsScreen(historyRepository: widget.repository),
                ),
              ),
              onResetFilters: () {
                setState(() => _searchReset++);
                _search.clear();
                _controller.resetFilters();
              },
              onDetails: (item) =>
                  showNotificationDetails(context, item, widget.repository),
            ),
          ),
        ),
      ),
    ),
  );
}
