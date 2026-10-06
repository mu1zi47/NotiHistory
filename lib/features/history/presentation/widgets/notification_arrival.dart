import 'package:flutter/material.dart';

class NotificationArrival extends StatefulWidget {
  const NotificationArrival({
    super.key,
    required this.animate,
    required this.child,
  });
  final bool animate;
  final Widget child;

  @override
  State<NotificationArrival> createState() => _NotificationArrivalState();
}

class _NotificationArrivalState extends State<NotificationArrival>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: widget.animate ? 0 : 1,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _animation,
    alignment: Alignment.topCenter,
    child: FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -.12),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    ),
  );
}
