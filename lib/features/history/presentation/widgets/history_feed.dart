import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
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
  });
  final HistoryController controller;
  final ScrollController scroll;
  final ValueNotifier<int?> openSwipe;
  final VoidCallback onAccess, onResetFilters;
  final Future<bool> Function(int id) onDelete;
  final ValueChanged<SavedNotification> onDetails;

  @override
  State<HistoryFeed> createState() => _HistoryFeedState();
}

class _HistoryFeedState extends State<HistoryFeed>
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
      duration: const Duration(milliseconds: 900),
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
          duration: const Duration(milliseconds: 220),
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
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
          )
          .orCancel;
      await controller.refresh(preserveItems: true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    } on TickerCanceled {
      return;
    } finally {
      if (mounted) {
        await _refreshOffset.animateTo(
          0,
          duration: const Duration(milliseconds: 240),
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
      key: const ValueKey('custom-refresh-gap'),
      height: _refreshOffset.value,
      child: Center(
        child: Transform.scale(
          scale: (_refreshOffset.value / 60).clamp(0.0, 1.0),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
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
        groups.add(_NotificationDay(item.savedAt, [item]));
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
      return NotificationListener<ScrollNotification>(
        onNotification: _handlePull,
        child: Stack(
          children: [
            CustomScrollView(
              key: const PageStorageKey('history'),
              controller: scroll,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                const HistoryAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                for (final group in _groupedItems())
                  SliverMainAxisGroup(
                    key: ValueKey(
                      'day-${group.date.year}-${group.date.month}-${group.date.day}',
                    ),
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _DayHeaderDelegate(dayLabel(group.date)),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: DecoratedSliver(
                          position: DecorationPosition.foreground,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                            border: Border(
                              left: BorderSide(color: Color(0xFFEEECF4)),
                              right: BorderSide(color: Color(0xFFEEECF4)),
                              bottom: BorderSide(color: Color(0xFFEEECF4)),
                            ),
                          ),
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
                              final first = index == 0;
                              final last = index == group.items.length - 1;
                              final borderRadius = BorderRadius.only(
                                topLeft: first
                                    ? const Radius.circular(18)
                                    : Radius.zero,
                                topRight: first
                                    ? const Radius.circular(18)
                                    : Radius.zero,
                                bottomLeft: last
                                    ? const Radius.circular(20)
                                    : Radius.zero,
                                bottomRight: last
                                    ? const Radius.circular(20)
                                    : Radius.zero,
                              );
                              return NotificationArrival(
                                key: ValueKey('arrival-${item.id}'),
                                animate: _pending.remove(item.id),
                                child: SwipeNotificationCard(
                                  key: ValueKey('swipe-${item.id}'),
                                  item: item,
                                  repository: controller.repository,
                                  openItem: openSwipe,
                                  borderRadius: borderRadius,
                                  showTopBorder: false,
                                  bottomSpacing: 0,
                                  onTap: () => onDetails(item),
                                  onDelete: () => onDelete(item.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ],
                  ),
                if (controller.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Center(
                        child: controller.loadingMore
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : controller.hasMore
                            ? TextButton(
                                onPressed: controller.loadMore,
                                child: const Text('Показать ещё'),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
            if (controller.items.isNotEmpty &&
                controller.status.active &&
                controller.error == null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('notification-viewport-corners'),
                    painter: _NotificationViewportPainter(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      scroll: scroll,
                      footerExtent: controller.hasMore || controller.loadingMore
                          ? 84
                          : 36,
                    ),
                  ),
                ),
              ),
          ],
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
  const _DayHeaderDelegate(this.label);

  static const extent = 42.0;
  final String label;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Stack(
      key: ValueKey('day-header-corners-$label'),
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: muted,
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: -18,
          child: _DayHeaderCorner(
            color: Theme.of(context).scaffoldBackgroundColor,
            left: true,
          ),
        ),
        Positioned(
          right: 16,
          bottom: -18,
          child: _DayHeaderCorner(
            color: Theme.of(context).scaffoldBackgroundColor,
            left: false,
          ),
        ),
        const Positioned(
          left: 16,
          right: 16,
          bottom: -18,
          height: 18,
          child: IgnorePointer(
            child: CustomPaint(
              key: ValueKey('day-header-outline'),
              painter: _DayHeaderOutlinePainter(),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant _DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

class _DayHeaderCorner extends StatelessWidget {
  const _DayHeaderCorner({required this.color, required this.left});

  final Color color;
  final bool left;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: CustomPaint(painter: _DayHeaderCornerPainter(color, left)),
  );
}

class _DayHeaderCornerPainter extends CustomPainter {
  const _DayHeaderCornerPainter(this.color, this.left);

  final Color color;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (left) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..arcTo(
          Rect.fromLTWH(0, 0, size.width * 2, size.height * 2),
          -math.pi / 2,
          -math.pi / 2,
          false,
        );
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, 0)
        ..arcTo(
          Rect.fromLTWH(-size.width, 0, size.width * 2, size.height * 2),
          -math.pi / 2,
          math.pi / 2,
          false,
        );
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DayHeaderCornerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.left != left;
}

class _DayHeaderOutlinePainter extends CustomPainter {
  const _DayHeaderOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 18.0;
    final path = Path()
      ..moveTo(.5, radius)
      ..arcTo(
        Rect.fromLTWH(.5, .5, radius * 2, radius * 2),
        math.pi,
        math.pi / 2,
        false,
      )
      ..lineTo(size.width - radius - .5, .5)
      ..arcTo(
        Rect.fromLTWH(size.width - radius * 2 - .5, .5, radius * 2, radius * 2),
        -math.pi / 2,
        math.pi / 2,
        false,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFEEECF4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DayHeaderOutlinePainter oldDelegate) => false;
}

class _NotificationViewportPainter extends CustomPainter {
  _NotificationViewportPainter({
    required this.color,
    required this.scroll,
    required this.footerExtent,
  }) : super(repaint: scroll);

  final ScrollController scroll;
  final double footerExtent;

  static const _inset = 16.0;
  static const _radius = 20.0;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The list already draws its own bottom once it is visible. Only add a
    // fixed edge when cards continue beyond the viewport.
    if (!scroll.hasClients ||
        scroll.position.extentAfter <= footerExtent + 12) {
      return;
    }
    final paint = Paint()..color = color;
    const left = _inset;
    final right = size.width - _inset;
    final bottom = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom)
        ..lineTo(left + _radius, bottom)
        ..quadraticBezierTo(left, bottom, left, bottom - _radius)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom)
        ..lineTo(right - _radius, bottom)
        ..quadraticBezierTo(right, bottom, right, bottom - _radius)
        ..close(),
      paint,
    );
    // Draw above the scrolling cards, along the fixed viewport edge.
    canvas.drawPath(
      Path()
        ..moveTo(left + .5, bottom - _radius)
        ..quadraticBezierTo(left + .5, bottom - .5, left + _radius, bottom - .5)
        ..lineTo(right - _radius, bottom - .5)
        ..quadraticBezierTo(
          right - .5,
          bottom - .5,
          right - .5,
          bottom - _radius,
        ),
      Paint()
        ..color = const Color(0xFFEEECF4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _NotificationViewportPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.footerExtent != footerExtent;
}
