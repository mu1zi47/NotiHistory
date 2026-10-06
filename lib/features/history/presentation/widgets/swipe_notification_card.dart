import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../domain/history_repository.dart';
import '../../domain/saved_notification.dart';
import 'notification_card.dart';

class SwipeNotificationCard extends StatefulWidget {
  const SwipeNotificationCard({
    super.key,
    required this.item,
    required this.repository,
    required this.openItem,
    required this.onTap,
    required this.onDelete,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.showTopBorder = true,
    this.bottomSpacing = 10,
  });

  final SavedNotification item;
  final HistoryRepository repository;
  final ValueNotifier<int?> openItem;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
  final BorderRadius borderRadius;
  final bool showTopBorder;
  final double bottomSpacing;

  @override
  State<SwipeNotificationCard> createState() => _SwipeNotificationCardState();
}

class _SwipeNotificationCardState extends State<SwipeNotificationCard>
    with TickerProviderStateMixin {
  late final AnimationController _slide;
  late final AnimationController _collapse;
  double _width = 1;
  bool _dragging = false;
  bool _deleting = false;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController.unbounded(vsync: this);
    _collapse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      value: 1,
    );
    widget.openItem.addListener(_handleOpenItemChanged);
  }

  @override
  void didUpdateWidget(covariant SwipeNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openItem != widget.openItem) {
      oldWidget.openItem.removeListener(_handleOpenItemChanged);
      widget.openItem.addListener(_handleOpenItemChanged);
    }
  }

  void _handleOpenItemChanged() {
    if (widget.openItem.value != widget.item.id && !_dragging && !_deleting) {
      _settle(0);
    }
  }

  Future<void> _settle(double target) async {
    if (!mounted || _deleting) return;
    final distance = (_slide.value - target).abs();
    final duration = Duration(
      milliseconds: (120 + distance.clamp(0, 180) * .45).round(),
    );
    await _slide.animateTo(
      target,
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  void _dragStart(DragStartDetails details) {
    if (_deleting) return;
    _slide.stop();
    _dragging = true;
    widget.openItem.value = widget.item.id;
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_deleting) return;
    final next = (_slide.value + details.delta.dx).clamp(-_width, _width);
    final armed = next.abs() >= _width * .26;
    if (armed && !_armed) HapticFeedback.selectionClick();
    _armed = armed;
    _slide.value = next;
  }

  void _dragEnd(DragEndDetails details) {
    if (_deleting) return;
    _dragging = false;
    final offset = _slide.value;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final direction = offset == 0 ? (velocity >= 0 ? 1.0 : -1.0) : offset.sign;
    final fullSwipe =
        offset.abs() >= _width * .26 ||
        (offset.abs() >= _width * .16 && velocity.abs() >= 900);
    _armed = false;
    if (fullSwipe) {
      _delete(direction);
    } else {
      widget.openItem.value = null;
      _settle(0);
    }
  }

  void _dragCancel() {
    _dragging = false;
    _armed = false;
    _settle(0);
  }

  void _handleTap() {
    if (_slide.value.abs() > 1) {
      widget.openItem.value = null;
      _settle(0);
    } else {
      widget.onTap();
    }
  }

  Future<void> _delete(double direction) async {
    if (_deleting) return;
    _deleting = true;
    widget.openItem.value = null;
    HapticFeedback.mediumImpact();
    await _slide.animateTo(
      direction * _width,
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeInCubic,
    );
    if (!mounted) return;
    await _collapse.animateTo(0, curve: Curves.easeInOutCubic);
    final deleted = await widget.onDelete();
    if (!deleted && mounted) {
      _deleting = false;
      _slide.value = 0;
      await _collapse.animateTo(1, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    widget.openItem.removeListener(_handleOpenItemChanged);
    _slide.dispose();
    _collapse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _collapse,
    alignment: Alignment.topCenter,
    child: Padding(
      padding: EdgeInsets.only(bottom: widget.bottomSpacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;
          return ClipRRect(
            borderRadius: widget.borderRadius,
            child: AnimatedBuilder(
              animation: _slide,
              builder: (context, child) {
                return Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(_slide.value, 0),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          gestureSettings: const DeviceGestureSettings(
                            touchSlop: 10,
                          ),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          dragStartBehavior: DragStartBehavior.down,
                          onHorizontalDragStart: _dragStart,
                          onHorizontalDragUpdate: _dragUpdate,
                          onHorizontalDragEnd: _dragEnd,
                          onHorizontalDragCancel: _dragCancel,
                          child: NotificationCard(
                            item: widget.item,
                            repository: widget.repository,
                            onTap: _handleTap,
                            borderRadius: widget.borderRadius,
                            showTopBorder: widget.showTopBorder,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    ),
  );
}
