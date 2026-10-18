import 'package:noti_history/core/theme/app_theme.dart';
import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../domain/history_repository.dart';
import '../../domain/saved_notification.dart';
import 'notification_card.dart';

/// Lets menu actions reuse the same animation as a swipe without deleting twice.
class SwipeNotificationHandle {
  _SwipeNotificationCardState? _state;
  bool get attached => _state?.mounted == true;
  Future<void> delete() async {
    await _state?._delete(-1);
  }

  Future<void> archive() async {
    await _state?._archive();
  }

  Future<void> animateOut(Duration delay) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    await _state?._animateOut(-1);
  }

  Future<void> restore() async {
    await _state?._restore();
  }
}

class SwipeNotificationCard extends StatefulWidget {
  const SwipeNotificationCard({
    super.key,
    required this.item,
    required this.repository,
    required this.openItem,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
    this.onArchive,
    this.archived = false,
    this.removal,
    this.borderRadius = BorderRadius.zero,
    this.showTopBorder = true,
    this.showBottomBorder = true,
    this.bottomSpacing = 10,
  });

  final SavedNotification item;
  final HistoryRepository repository;
  final ValueNotifier<int?> openItem;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
  final Future<bool> Function()? onArchive;
  final bool archived;
  final ValueChanged<Offset>? onLongPress;
  final SwipeNotificationHandle? removal;
  final BorderRadius borderRadius;
  final bool showTopBorder;
  final bool showBottomBorder;
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
      duration: Duration(milliseconds: 210),
      value: 1,
    );
    widget.openItem.addListener(_handleOpenItemChanged);
    widget.removal?._state = this;
  }

  @override
  void didUpdateWidget(covariant SwipeNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.removal != widget.removal) {
      if (oldWidget.removal?._state == this) oldWidget.removal?._state = null;
      widget.removal?._state = this;
    }
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
    if (distance < .1) return;
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
      if (direction > 0 && widget.onArchive != null) {
        _archive();
      } else {
        _delete(direction);
      }
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

  Future<void> _animateOut(double direction) async {
    if (_deleting || !mounted) return;
    _deleting = true;
    _dragging = false;
    widget.openItem.value = null;
    try {
      await _slide
          .animateTo(
            direction * _width,
            duration: Duration(milliseconds: 220),
            curve: Curves.easeInCubic,
          )
          .orCancel;
      if (mounted) {
        await _collapse.animateTo(0, curve: Curves.easeInOutCubic).orCancel;
      }
    } on TickerCanceled {
      /* The row disappeared during a live update. */
    }
  }

  Future<void> _restore() async {
    if (!mounted) return;
    _deleting = false;
    _slide.value = 0;
    await _collapse.animateTo(1, curve: Curves.easeOutCubic);
  }

  Future<void> _archive() async {
    if (_deleting || widget.onArchive == null) return;
    HapticFeedback.mediumImpact();
    final commit = widget.onArchive!;
    await _animateOut(1);
    final archived = await commit();
    if (!archived && mounted) await _restore();
  }

  Future<void> _delete(double direction) async {
    if (_deleting) return;
    HapticFeedback.mediumImpact();
    final commit = widget.onDelete;
    await _animateOut(direction);
    final deleted = await commit();
    if (!deleted && mounted) await _restore();
  }

  @override
  void dispose() {
    widget.openItem.removeListener(_handleOpenItemChanged);
    if (widget.removal?._state == this) widget.removal?._state = null;
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
              child: NotificationCard(
                item: widget.item,
                repository: widget.repository,
                onTap: _handleTap,
                borderRadius: widget.borderRadius,
                showTopBorder: false,
                showBottomBorder: widget.showBottomBorder,
              ),
              builder: (context, child) {
                return Stack(
                  children: [
                    if (_slide.value.abs() > .1)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(
                            key: ValueKey(
                              'swipe-delete-background-${widget.item.id}',
                            ),
                            color: _slide.value > 0 && widget.onArchive != null
                                ? ui(context).accentSurface
                                : ui(context).deleteSurface,
                            child: Align(
                              alignment: _slide.value > 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: SizedBox(
                                key: ValueKey(
                                  'swipe-action-region-${widget.item.id}',
                                ),
                                width: _slide.value.abs().clamp(0.0, _width),
                                height: double.infinity,
                                child: LayoutBuilder(
                                  builder: (context, exposed) {
                                    final width = exposed.maxWidth;
                                    final centered =
                                        _slide.value.abs() >= _width * .5;
                                    final archive =
                                        _slide.value > 0 &&
                                        widget.onArchive != null;
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(
                                        begin: 0,
                                        end: centered ? 1 : 0,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, progress, child) {
                                        // Animate distance from the outer edge, then mirror
                                        // the finished geometry. Never animate a width-dependent
                                        // absolute x coordinate: that lags only on the left swipe.
                                        final maxInset = (width - 28).clamp(
                                          0.0,
                                          width,
                                        );
                                        final edge = 20.0.clamp(0.0, maxInset);
                                        final center = maxInset / 2;
                                        final inset =
                                            edge + (center - edge) * progress;
                                        final left = _slide.value > 0
                                            ? inset
                                            : maxInset - inset;
                                        return Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Positioned(
                                              key: ValueKey(
                                                'swipe-delete-icon-position-${widget.item.id}',
                                              ),
                                              left: left,
                                              top: 0,
                                              bottom: 0,
                                              width: 28,
                                              child: Opacity(
                                                opacity:
                                                    (_slide.value.abs() / 64)
                                                        .clamp(0.0, 1.0),
                                                child: Icon(
                                                  archive
                                                      ? (widget.archived
                                                            ? Icons
                                                                  .unarchive_outlined
                                                            : Icons
                                                                  .archive_outlined)
                                                      : Icons
                                                            .delete_outline_rounded,
                                                  color: archive
                                                      ? ui(context).accent
                                                      : ui(context).deleteInk,
                                                  size: 28,
                                                  semanticLabel: tr(
                                                    context,
                                                    archive
                                                        ? (widget.archived
                                                              ? 'Вернуть из архива'
                                                              : 'Архивировать')
                                                        : 'Удалить уведомление',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset(_slide.value, 0),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          gestureSettings: DeviceGestureSettings(touchSlop: 10),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          dragStartBehavior: DragStartBehavior.down,
                          onHorizontalDragStart: _dragStart,
                          onHorizontalDragUpdate: _dragUpdate,
                          onHorizontalDragEnd: _dragEnd,
                          onHorizontalDragCancel: _dragCancel,
                          onLongPressStart: widget.onLongPress == null
                              ? null
                              : (details) {
                                  if (_deleting) return;
                                  HapticFeedback.selectionClick();
                                  widget.openItem.value = null;
                                  widget.onLongPress!(details.globalPosition);
                                },
                          child: child,
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
