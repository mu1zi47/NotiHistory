import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Interactive back swipe across the page; nested horizontal controls retain
/// their own gestures (notification actions, text selection and switches).
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required super.builder, super.settings});
  AnimationController get dragController => controller!;

  final _contentKey = GlobalKey();

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final content = KeyedSubtree(key: _contentKey, child: child);
    return _PageBackSwipe<T>(
      route: this,
      normalTransition: super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        content,
      ),
      child: content,
    );
  }
}

class _PageBackSwipe<T> extends StatefulWidget {
  const _PageBackSwipe({
    required this.route,
    required this.child,
    required this.normalTransition,
  });
  final AppPageRoute<T> route;
  final Widget child;
  final Widget normalTransition;
  @override
  State<_PageBackSwipe<T>> createState() => _PageBackSwipeState<T>();
}

class _PageBackSwipeState<T> extends State<_PageBackSwipe<T>> {
  NavigatorState? _navigator;
  double _distance = 0;
  bool _dragging = false, _interactive = false;
  bool _pointerCancelled = false;

  void _start(DragStartDetails details) {
    final route = widget.route;
    final insets = MediaQuery.systemGestureInsetsOf(context);
    final width = MediaQuery.sizeOf(context).width;
    // Edge gestures belong to Android. Running our pop as well would make
    // the later system back event pop the next page a second time.
    if (details.localPosition.dx <= math.max(24.0, insets.left) ||
        details.localPosition.dx >= width - math.max(24.0, insets.right)) {
      return;
    }
    if (route.isFirst ||
        !route.isCurrent ||
        route.popDisposition != RoutePopDisposition.pop ||
        route.animation!.status != AnimationStatus.completed) {
      return;
    }
    setState(() => _interactive = true);
    _navigator = route.navigator;
    _navigator!.didStartUserGesture();
    _dragging = true;
    _distance = 0;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _update(DragUpdateDetails details) {
    if (!_dragging) return;
    final width = MediaQuery.sizeOf(context).width;
    _distance = (_distance + details.delta.dx).clamp(0, width);
    widget.route.dragController.value = 1 - _distance / width;
  }

  Future<void> _finish({double velocity = 0, bool cancelled = false}) async {
    if (!_dragging) return;
    _dragging = false;
    final route = widget.route;
    final navigator = _navigator!;
    final pop =
        !cancelled &&
        !_pointerCancelled &&
        route.isCurrent &&
        route.popDisposition == RoutePopDisposition.pop &&
        (velocity > 700 ||
            (velocity > -700 && route.dragController.value < .72));
    try {
      if (pop) {
        navigator.pop();
        await route.dragController
            .animateBack(
              0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      } else {
        await route.dragController
            .animateTo(
              1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      }
    } on TickerCanceled {
      // The route can disappear through the system back button.
    } finally {
      navigator.didStopUserGesture();
      _navigator = null;
      if (mounted) setState(() => _interactive = false);
    }
  }

  @override
  void dispose() {
    if (_dragging) {
      _navigator?.didStopUserGesture();
      _dragging = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _pointerCancelled = false,
    onPointerCancel: (_) => _pointerCancelled = true,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: _start,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: (details) =>
          _finish(velocity: details.primaryVelocity ?? 0),
      onHorizontalDragCancel: () => _finish(cancelled: true),
      child: _interactive
          ? SlideTransition(
              position: Tween(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(widget.route.animation!),
              child: widget.child,
            )
          : widget.normalTransition,
    ),
  );
}
