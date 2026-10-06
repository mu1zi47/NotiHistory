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

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repository});
  final HistoryRepository repository;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  late final HistoryController _controller;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _openSwipe = ValueNotifier<int?>(null);
  @override
  void initState() {
    super.initState();
    _controller = HistoryController(widget.repository)..start();
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
      _toast('Не удалось открыть настройки Android.', error: true);
    }
  }

  Future<void> _clear() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!await confirmClearHistory(context, filtered: _controller.filtered) ||
        !mounted) {
      return;
    }
    try {
      await _controller.clear();
      if (!mounted) return;
      _toast('История очищена');
    } catch (_) {
      _toast('Не удалось очистить историю. Попробуйте снова.', error: true);
    }
  }

  Future<void> _filter() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showAppFilterSheet(
      context,
      apps: _controller.apps,
      selected: _controller.packageNames,
      repository: _controller.repository,
    );
    if (selected != null && mounted) await _controller.setPackages(selected);
  }

  Future<bool> _delete(int id) async {
    try {
      await _controller.delete(id);
      return true;
    } catch (_) {
      _toast('Не удалось удалить уведомление. Попробуйте снова.', error: true);
      return false;
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
    value: transparentSystemBars,
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Material(
            key: const ValueKey('history-bottom-actions'),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 728),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => HistoryActions(
                      search: _search,
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: HistoryFeed(
              controller: _controller,
              scroll: _scroll,
              openSwipe: _openSwipe,
              onDelete: _delete,
              onAccess: _access,
              onResetFilters: () {
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
