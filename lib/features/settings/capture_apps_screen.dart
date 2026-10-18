import 'package:flutter/services.dart';

import '../../core/theme/system_bars.dart';

import 'package:noti_history/core/widgets/applied_filters.dart';

import '../history/presentation/widgets/history_sheet.dart';

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
  int _searchReset = 0;
  final _scroll = ScrollController();
  List<CaptureApp> _apps = [];
  CaptureAppFilter _filter = CaptureAppFilter.all;
  final _saving = <String>{};
  final _departing = <String>{};
  final _departureTokens = <String, Object>{};
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

  void _depart(String packageName) {
    _departing.add(packageName);
    final token = Object();
    _departureTokens[packageName] = token;
    // A row may leave the viewport before its animation can report completion.
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted || _departureTokens[packageName] != token) return;
      _departureTokens.remove(packageName);
      if (_departing.contains(packageName)) {
        setState(() => _departing.remove(packageName));
      }
    });
  }

  Future<void> _toggle(CaptureApp app, bool enabled) async {
    setState(() => _saving.add(app.packageName));
    try {
      await widget.settingsRepository.setEnabled(app.packageName, enabled);
      if (!mounted) return;
      setState(() {
        final index = _apps.indexWhere((a) => a.packageName == app.packageName);
        if (!_filter.matches(enabled)) _depart(app.packageName);
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
    if (_enablingAll) return;
    final confirmed = await showHistorySheet<bool>(
      context,
      (context) => HistorySheet(
        viewportRadius: 0,
        header: Center(
          child: Text(
            tr(context, 'Включить сохранение для всех?'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: titleFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        footer: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr(context, 'Отмена')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr(context, 'Включить все')),
              ),
            ),
          ],
        ),
        children: [
          Text(
            tr(
              context,
              'Уведомления всех приложений будут сохраняться в историю, включая ранее выключенные.',
            ),
            style: TextStyle(color: ui(context).muted, height: 1.5),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
    setState(() {
      _departing.clear();
      _departureTokens.clear();
      _filter = selected;
    });
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
              (_filter.matches(app.enabled) ||
                  _departing.contains(app.packageName)) &&
              '${app.name}\n${app.packageName}'.toLowerCase().contains(search),
        )
        .toList();
    final hasDisabled = _apps.any((app) => !app.enabled);
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                      searchReset: _searchReset,
                      onSearchChanged: (_) => setState(() {}),
                      hasDisabled: !_loading && !_failed && hasDisabled,
                      busy:
                          _enablingAll ||
                          _saving.isNotEmpty ||
                          _departing.isNotEmpty,
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AppliedFilters(
                              key: const ValueKey('capture-applied-filters'),
                              onReset: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                _search.clear();
                                setState(() {
                                  _searchReset++;
                                  _departing.clear();
                                  _departureTokens.clear();
                                  _filter = CaptureAppFilter.all;
                                });
                              },
                              filters: [
                                if (_filter != CaptureAppFilter.all)
                                  (
                                    icon: Icons.tune_rounded,
                                    text: tr(context, _filter.title),
                                  ),
                                if (_search.text.trim().isNotEmpty)
                                  (
                                    icon: Icons.search_rounded,
                                    text: tr(context, 'Поиск: {0}', [
                                      _search.text.trim(),
                                    ]),
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
                                        ? tr(
                                            context,
                                            'Нет включённых приложений',
                                          )
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
                                            setState(() {
                                              _searchReset++;
                                              _departing.clear();
                                              _departureTokens.clear();
                                              _filter = CaptureAppFilter.all;
                                            });
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
                            findChildIndexCallback: (key) {
                              if (key is! ValueKey<String>) return null;
                              final index = visible.indexWhere(
                                (app) =>
                                    key.value ==
                                    'capture-app-${app.packageName}',
                              );
                              return index < 0 ? null : index;
                            },
                            itemBuilder: (context, index) {
                              final app = visible[index];
                              final saving =
                                  _enablingAll ||
                                  _saving.contains(app.packageName) ||
                                  _departing.contains(app.packageName);
                              return TweenAnimationBuilder<double>(
                                key: ValueKey('capture-app-${app.packageName}'),
                                tween: Tween(
                                  begin: 1,
                                  end: _departing.contains(app.packageName)
                                      ? 0
                                      : 1,
                                ),
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeInOutCubic,
                                onEnd: () {
                                  if (mounted &&
                                      _departing.contains(app.packageName)) {
                                    setState(
                                      () => _departing.remove(app.packageName),
                                    );
                                  }
                                },
                                builder: (context, value, child) => ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: value,
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  ),
                                ),
                                child: Material(
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
                                        app: SavedApp(
                                          app.packageName,
                                          app.name,
                                          0,
                                        ),
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
