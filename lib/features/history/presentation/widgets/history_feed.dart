import 'package:noti_history/core/l10n/app_strings.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/list_corners_painter.dart';
import '../../../../core/formatting/notification_date.dart';
import '../../application/history_controller.dart';
import '../../domain/saved_notification.dart';
import 'history_empty.dart';
import 'history_header.dart';
import 'history_app_bar.dart';
import 'swipe_notification_card.dart';
import 'notification_arrival.dart';

class HistoryFeed extends StatefulWidget {
  const HistoryFeed({
    super.key,
    required this.controller,
    required this.scroll,
    required this.openSwipe,
    required this.onDelete,
    required this.onAccess,
    required this.onResetFilters,
    required this.onDetails,
    this.onSettings,
    this.onLongPress,
  });
  final HistoryController controller;
  final ScrollController scroll;
  final ValueNotifier<int?> openSwipe;
  final VoidCallback onAccess, onResetFilters;
  final VoidCallback? onSettings;
  final void Function(SavedNotification item, Offset position)? onLongPress;
  final Future<bool> Function(int id) onDelete;
  final ValueChanged<SavedNotification> onDetails;

  @override
  State<HistoryFeed> createState() => HistoryFeedState();
}

class HistoryFeedState extends State<HistoryFeed>
    with TickerProviderStateMixin {
  late final AnimationController _refreshOffset;
  late final AnimationController _refreshSpin;
  bool _refreshing = false, _pullArmed = false;

  @override
  void initState() {
    super.initState();
    _refreshOffset = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _refreshSpin = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
  }

  bool _handlePull(ScrollNotification notification) {
    if (notification.depth != 0 || _refreshing) return false;
    final drag = switch (notification) {
      OverscrollNotification() => notification.dragDetails,
      ScrollUpdateNotification() => notification.dragDetails,
      _ => null,
    };
    final delta = drag?.primaryDelta ?? 0;
    // Use finger movement: clamped scrolling can report zero scrollDelta,
    // especially when the entire list fits inside the viewport.
    if (drag != null && _refreshOffset.value > 0 && delta < 0) {
      _refreshOffset.stop();
      _refreshOffset.value = (_refreshOffset.value + delta * .55).clamp(0, 100);
      _pullArmed = _refreshOffset.value >= 64;
    } else if (notification is OverscrollNotification &&
        drag != null &&
        notification.metrics.extentBefore == 0 &&
        notification.overscroll < 0 &&
        delta > 0) {
      _refreshOffset.stop();
      _refreshOffset.value = (_refreshOffset.value + delta * .55).clamp(0, 100);
      final armed = _refreshOffset.value >= 64;
      if (armed && !_pullArmed) HapticFeedback.selectionClick();
      _pullArmed = armed;
    } else if (notification is ScrollEndNotification &&
        _refreshOffset.value > 0) {
      if (_pullArmed) {
        _refresh();
      } else {
        _refreshOffset.animateTo(
          0,
          duration: Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
      _pullArmed = false;
    }
    return false;
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _refreshSpin.repeat();
    try {
      await _refreshOffset
          .animateTo(
            60,
            duration: Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
          )
          .orCancel;
      await controller.refresh(preserveItems: true);
      await Future<void>.delayed(Duration(milliseconds: 200));
    } on TickerCanceled {
      return;
    } finally {
      if (mounted) {
        await _refreshOffset.animateTo(
          0,
          duration: Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
        );
        if (mounted) {
          _refreshSpin.stop();
          setState(() => _refreshing = false);
        }
      }
    }
  }

  Widget _refreshIndicator() => ClipRect(
    child: SizedBox(
      key: ValueKey('custom-refresh-gap'),
      height: _refreshOffset.value,
      child: Center(
        child: Transform.scale(
          scale: (_refreshOffset.value / 60).clamp(0.0, 1.0),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ui(context).surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ui(context).accent.withValues(alpha: .12),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: RotationTransition(
              turns: _refreshSpin,
              child: CustomPaint(
                painter: _RefreshRingPainter(
                  progress: _refreshing
                      ? .75
                      : (_refreshOffset.value / 64).clamp(0.0, 1.0),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _refreshOffset.dispose();
    _refreshSpin.dispose();
    super.dispose();
  }

  final _cards = <int, SwipeNotificationHandle>{};
  bool _removingApp = false;

  Future<void> deleteNotification(int id) async {
    final card = _cards[id];
    if (card?.attached == true) {
      await card!.delete();
    } else {
      await widget.onDelete(id);
    }
  }

  Future<void> removeApp(
    String packageName,
    Future<void> Function() commit,
  ) async {
    if (_removingApp) return;
    final cards = [
      for (final item in controller.items)
        if (item.packageName == packageName &&
            _cards[item.id]?.attached == true)
          _cards[item.id]!,
    ];
    setState(() => _removingApp = true);
    try {
      await Future.wait([
        for (var i = 0; i < cards.length; i++)
          cards[i].animateOut(Duration(milliseconds: (i * 35).clamp(0, 140))),
      ]);
      await commit();
    } catch (_) {
      await Future.wait(cards.map((card) => card.restore()));
      rethrow;
    } finally {
      if (mounted) setState(() => _removingApp = false);
    }
  }

  final _dayKeys = <int, GlobalKey>{};
  int _scrollRequest = 0;

  void _scrollToTop() => _scrollTo(0);

  void _scrollToDay(int id) {
    final group = _dayKeys[id]?.currentContext?.findRenderObject();
    if (group is RenderSliver) {
      // Group constraints retain the content offset even while its header is pinned.
      _scrollTo(group.constraints.precedingScrollExtent - 64);
    }
  }

  Future<void> _scrollTo(double target) async {
    if (!scroll.hasClients) return;
    final request = ++_scrollRequest;
    FocusManager.instance.primaryFocus?.unfocus();
    openSwipe.value = null;
    target = target.clamp(0.0, scroll.position.maxScrollExtent);
    final viewport = scroll.position.viewportDimension;
    if (scroll.offset - target > viewport * 1.5) {
      scroll.jumpTo(
        (target + viewport * .75).clamp(0.0, scroll.position.maxScrollExtent),
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !scroll.hasClients || request != _scrollRequest) return;
    }
    await scroll.animateTo(
      target.clamp(0.0, scroll.position.maxScrollExtent),
      duration: Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  int _highestId = 0;
  bool _initialized = false;
  final _pending = <int>{};
  HistoryController get controller => widget.controller;
  ScrollController get scroll => widget.scroll;
  ValueNotifier<int?> get openSwipe => widget.openSwipe;
  VoidCallback get onAccess => widget.onAccess;
  VoidCallback get onResetFilters => widget.onResetFilters;
  ValueChanged<SavedNotification> get onDetails => widget.onDetails;
  Future<bool> Function(int) get onDelete => widget.onDelete;

  void _observeItems() {
    if (controller.loading) return;
    for (final item in controller.items) {
      if (_initialized && item.id > _highestId) _pending.add(item.id);
    }
    for (final item in controller.items) {
      if (item.id > _highestId) _highestId = item.id;
    }
    _initialized = true;
    _pending.removeWhere(
      (id) => !controller.items.any((item) => item.id == id),
    );
  }

  List<_NotificationDay> _groupedItems() {
    final groups = <_NotificationDay>[];
    for (final item in controller.items) {
      if (groups.isEmpty || !sameDay(groups.last.date, item.savedAt)) {
        final date = item.savedAt;
        groups.add(
          _NotificationDay(DateTime(date.year, date.month, date.day), [item]),
        );
      } else {
        groups.last.items.add(item);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      _observeItems();
      final groups = _groupedItems();
      final ids = controller.items.map((item) => item.id).toSet();
      _cards.removeWhere((id, _) => !ids.contains(id));
      final groupIds = groups.map((g) => g.date.millisecondsSinceEpoch).toSet();
      _dayKeys.removeWhere((id, _) => !groupIds.contains(id));
      return IgnorePointer(
        ignoring: _removingApp,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handlePull,
          child: Stack(
            children: [
              CustomScrollView(
                key: PageStorageKey('history'),
                controller: scroll,
                physics: AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  HistoryAppBar(
                    onSettings: widget.onSettings,
                    onScrollToTop: _scrollToTop,
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: HistoryHeader(
                        controller: controller,
                        onAccess: onAccess,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _refreshIndicator()),
                  if (controller.items.isEmpty && !controller.loading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: HistoryEmpty(
                          filtered: controller.filtered,
                          status: controller.status,
                          onAccess: onAccess,
                          onReset: onResetFilters,
                        ),
                      ),
                    ),
                  for (final group in groups)
                    SliverMainAxisGroup(
                      key: _dayKeys.putIfAbsent(
                        group.date.millisecondsSinceEpoch,
                        () => GlobalKey(),
                      ),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _DayHeaderDelegate(
                            tr(context, dayLabel(group.date)),
                            () =>
                                _scrollToDay(group.date.millisecondsSinceEpoch),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList.builder(
                            itemCount: group.items.length,
                            findChildIndexCallback: (key) {
                              if (key is! ValueKey<String>) return null;
                              final index = group.items.indexWhere(
                                (item) => key.value == 'arrival-${item.id}',
                              );
                              return index < 0 ? null : index;
                            },
                            itemBuilder: (context, index) {
                              final item = group.items[index];
                              return NotificationArrival(
                                key: ValueKey('arrival-${item.id}'),
                                animate: _pending.remove(item.id),
                                child: SwipeNotificationCard(
                                  key: ValueKey('swipe-${item.id}'),
                                  removal: _cards.putIfAbsent(
                                    item.id,
                                    () => SwipeNotificationHandle(),
                                  ),
                                  item: item,
                                  repository: controller.repository,
                                  openItem: openSwipe,
                                  borderRadius: BorderRadius.only(
                                    topLeft: index == 0
                                        ? Radius.circular(20)
                                        : Radius.zero,
                                    topRight: index == 0
                                        ? Radius.circular(20)
                                        : Radius.zero,
                                    bottomLeft: index == group.items.length - 1
                                        ? Radius.circular(20)
                                        : Radius.zero,
                                    bottomRight: index == group.items.length - 1
                                        ? Radius.circular(20)
                                        : Radius.zero,
                                  ),
                                  showTopBorder: false,
                                  showBottomBorder:
                                      index < group.items.length - 1,
                                  bottomSpacing: 0,
                                  onTap: () => onDetails(item),
                                  onDelete: () => onDelete(item.id),
                                  onLongPress: widget.onLongPress == null
                                      ? null
                                      : (position) =>
                                            widget.onLongPress!(item, position),
                                ),
                              );
                            },
                          ),
                        ),
                        if (group != groups.last)
                          SliverToBoxAdapter(child: SizedBox(height: 12)),
                      ],
                    ),
                  if (controller.items.isNotEmpty &&
                      (controller.hasMore || controller.loadingMore))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Center(
                          child: controller.loadingMore
                              ? CircularProgressIndicator(strokeWidth: 2)
                              : controller.hasMore
                              ? TextButton(
                                  onPressed: controller.loadMore,
                                  child: Text(tr(context, 'Показать ещё')),
                                )
                              : SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
              if (controller.items.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  height: 20,
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: ValueKey('feed-bottom-rounding'),
                      painter: ListCornersPainter(
                        Theme.of(context).scaffoldBackgroundColor,
                        bottom: true,
                        scroll: scroll,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 16 + 8, // List inset + the same inner gap as below.
                bottom: 8,
                child: AnimatedBuilder(
                  animation: scroll,
                  builder: (context, _) {
                    final visible =
                        scroll.hasClients &&
                        scroll.offset > 160 &&
                        scroll.position.extentAfter > 24;
                    return IgnorePointer(
                      ignoring: !visible,
                      child: ExcludeSemantics(
                        excluding: !visible,
                        child: AnimatedSlide(
                          offset: visible ? Offset.zero : Offset(0, .3),
                          duration: Duration(milliseconds: 180),
                          child: AnimatedOpacity(
                            opacity: visible ? 1 : 0,
                            duration: Duration(milliseconds: 180),
                            child: FloatingActionButton.small(
                              key: ValueKey('scroll-to-top'),
                              heroTag: null,
                              tooltip: tr(context, 'Наверх'),
                              backgroundColor: ui(context).accentSurface,
                              foregroundColor: ui(context).accent,
                              elevation: 2,
                              onPressed: _scrollToTop,
                              child: Icon(Icons.arrow_upward_rounded),
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
        ),
      );
    },
  );
}

class _RefreshRingPainter extends CustomPainter {
  const _RefreshRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: 10,
    );
    canvas.drawCircle(
      size.center(Offset.zero),
      10,
      Paint()
        ..color = accent.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawArc(
      bounds,
      -math.pi / 2,
      math.pi * 1.75 * progress,
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RefreshRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _NotificationDay {
  _NotificationDay(this.date, this.items);

  final DateTime date;
  final List<SavedNotification> items;
}

class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DayHeaderDelegate(this.label, this.onTap);
  final VoidCallback onTap;
  final String label;

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
    key: ValueKey('day-header-$label'),
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Semantics(
            button: true,
            label: tr(context, 'К началу дня: {0}', [label]),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ui(context).muted,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -20,
          height: 20,
          child: IgnorePointer(
            child: CustomPaint(
              painter: ListCornersPainter(
                Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant _DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label || oldDelegate.onTap != onTap;
}
