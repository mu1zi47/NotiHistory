import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/list_corners_painter.dart';
import '../history/domain/history_repository.dart';
import '../history/domain/saved_app.dart';
import '../history/presentation/widgets/app_avatar.dart';
import 'capture_settings_repository.dart';
import 'capture_app_actions.dart';
import 'capture_app_filter.dart';
import 'capture_app_filter_sheet.dart';

class CaptureAppsScreen extends StatefulWidget {
  const CaptureAppsScreen({
    super.key,
    required this.historyRepository,
    this.settingsRepository = const CaptureSettingsRepository(),
  });
  final HistoryRepository historyRepository;
  final CaptureSettingsRepository settingsRepository;

  @override
  State<CaptureAppsScreen> createState() => _CaptureAppsScreenState();
}

class _CaptureAppsScreenState extends State<CaptureAppsScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  List<CaptureApp> _apps = [];
  CaptureAppFilter _filter = CaptureAppFilter.all;
  final _saving = <String>{};
  bool _loading = true, _failed = false, _enablingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final apps = await widget.settingsRepository.apps();
      if (mounted) {
        setState(() {
          _apps = apps;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggle(CaptureApp app, bool enabled) async {
    setState(() => _saving.add(app.packageName));
    try {
      await widget.settingsRepository.setEnabled(app.packageName, enabled);
      if (!mounted) return;
      setState(() {
        final index = _apps.indexWhere((a) => a.packageName == app.packageName);
        _apps[index] = CaptureApp(app.packageName, app.name, enabled);
      });
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          tr(context, 'Не удалось сохранить настройку. Попробуйте снова.'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(app.packageName));
    }
  }

  Future<void> _enableAll() async {
    setState(() => _enablingAll = true);
    try {
      await widget.settingsRepository.enableAll();
      if (!mounted) return;
      setState(
        () => _apps = _apps
            .map((app) => CaptureApp(app.packageName, app.name, true))
            .toList(),
      );
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          tr(context, 'Не удалось включить все приложения. Попробуйте снова.'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _enablingAll = false);
    }
  }

  Future<void> _chooseFilter() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showCaptureAppFilter(context, _filter);
    if (selected == null || !mounted) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _filter = selected);
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = _search.text.trim().toLowerCase();
    final visible = _apps
        .where(
          (app) =>
              _filter.matches(app.enabled) &&
              '${app.name}\n${app.packageName}'.toLowerCase().contains(search),
        )
        .toList();
    final hasDisabled = _apps.any((app) => !app.enabled);
    return Scaffold(
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
            key: ValueKey('capture-bottom-actions'),
            color: ui(context).paper,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 728),
                  child: CaptureAppActions(
                    search: _search,
                    onSearchChanged: (_) => setState(() {}),
                    hasDisabled: !_loading && !_failed && hasDisabled,
                    busy: _enablingAll || _saving.isNotEmpty,
                    onEnableAll: _enableAll,
                    filter: _filter,
                    onFilter: _chooseFilter,
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
            child: Stack(
              children: [
                CustomScrollView(
                  key: PageStorageKey('capture-apps'),
                  controller: _scroll,
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      title: Text(tr(context, 'Сохранение уведомлений')),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(
                                context,
                                'В историю попадают уведомления только от выбранных приложений.',
                              ),
                              style: TextStyle(
                                color: ui(context).muted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_loading && !_failed)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _CaptureCountHeader(
                          enabled: _apps.where((app) => app.enabled).length,
                          total: _apps.length,
                          rounded: visible.isNotEmpty,
                        ),
                      ),
                    if (_loading || _failed || visible.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: _loading
                              ? CircularProgressIndicator()
                              : _failed
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tr(
                                        context,
                                        'Не удалось загрузить приложения',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _load,
                                      child: Text(tr(context, 'Повторить')),
                                    ),
                                  ],
                                )
                              : AppEmptyState(
                                  icon: Icons.search_off_rounded,
                                  title:
                                      search.isNotEmpty ||
                                          _filter == CaptureAppFilter.all
                                      ? tr(context, 'Приложения не найдены')
                                      : _filter == CaptureAppFilter.enabled
                                      ? tr(context, 'Нет включённых приложений')
                                      : tr(
                                          context,
                                          'Нет выключенных приложений',
                                        ),
                                  message: tr(
                                    context,
                                    'Попробуйте другой запрос или сбросьте фильтры.',
                                  ),
                                  actions: [
                                    if (search.isNotEmpty ||
                                        _filter != CaptureAppFilter.all)
                                      TextButton(
                                        onPressed: () {
                                          _search.clear();
                                          setState(
                                            () =>
                                                _filter = CaptureAppFilter.all,
                                          );
                                        },
                                        child: Text(
                                          tr(context, 'Сбросить фильтры'),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final app = visible[index];
                            final saving =
                                _enablingAll ||
                                _saving.contains(app.packageName);
                            return Material(
                              key: ValueKey('capture-app-${app.packageName}'),
                              color: ui(context).surface,
                              borderRadius: BorderRadius.vertical(
                                top: index == 0
                                    ? Radius.circular(20)
                                    : Radius.zero,
                                bottom: index == visible.length - 1
                                    ? Radius.circular(20)
                                    : Radius.zero,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: index < visible.length - 1
                                      ? Border(
                                          bottom: BorderSide(
                                            color: ui(context).divider,
                                          ),
                                        )
                                      : null,
                                ),
                                child: SwitchListTile(
                                  value: app.enabled,
                                  onChanged: saving
                                      ? null
                                      : (value) => _toggle(app, value),
                                  secondary: AppAvatar(
                                    app: SavedApp(app.packageName, app.name, 0),
                                    repository: widget.historyRepository,
                                  ),
                                  title: Text(
                                    app.name,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    app.packageName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ui(context).muted,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                if (!_loading && !_failed && visible.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 0,
                    height: 20,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: ListCornersPainter(
                          ui(context).paper,
                          bottom: true,
                          scroll: _scroll,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureCountHeader extends SliverPersistentHeaderDelegate {
  const _CaptureCountHeader({
    required this.enabled,
    required this.total,
    required this.rounded,
  });
  final int enabled, total;
  final bool rounded;

  @override
  double get minExtent => 42;
  @override
  double get maxExtent => 42;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    key: ValueKey('capture-count-header'),
    color: ui(context).paper,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              tr(context, 'Сохранение включено: {0} из {1}', [enabled, total]),
              style: TextStyle(
                color: ui(context).muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (rounded)
          Positioned(
            left: 16,
            right: 16,
            bottom: -20,
            height: 20,
            child: IgnorePointer(
              child: CustomPaint(
                painter: ListCornersPainter(ui(context).paper),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant _CaptureCountHeader oldDelegate) =>
      enabled != oldDelegate.enabled ||
      total != oldDelegate.total ||
      rounded != oldDelegate.rounded;
}
