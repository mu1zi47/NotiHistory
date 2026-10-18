import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class FeedbackHint extends StatefulWidget {
  const FeedbackHint({super.key, required this.message});
  final String message;
  @override
  State<FeedbackHint> createState() => _FeedbackHintState();
}

class _FeedbackHintState extends State<FeedbackHint> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _anchor = GlobalKey();
  final _group = Object();
  double _width = 280, _dx = 0, _pointer = 24;
  bool _below = false;

  void _close() {
    if (_portal.isShowing) setState(_portal.hide);
  }

  void _toggle() {
    if (_portal.isShowing) {
      _close();
      return;
    }
    final box = _anchor.currentContext!.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    _width = math.min(300, media.size.width - 32);
    final center = origin.dx + box.size.width / 2;
    final left = (center - _width + 24).clamp(
      16.0,
      media.size.width - _width - 16,
    );
    _dx = left - origin.dx;
    _pointer = (center - left).clamp(16, _width - 16);
    final painter = TextPainter(
      text: TextSpan(
        text: widget.message,
        style: const TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: _width - 32);
    _below = origin.dy < media.padding.top + painter.height + 52;
    painter.dispose();
    setState(_portal.show);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_portal.isShowing,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: TapRegion(
      groupId: _group,
      onTapOutside: (_) => _close(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: _below ? Alignment.bottomLeft : Alignment.topLeft,
              followerAnchor: _below ? Alignment.topLeft : Alignment.bottomLeft,
              offset: Offset(_dx, _below ? 8 : -8),
              child: Align(
                alignment: Alignment.topLeft,
                widthFactor: 1,
                heightFactor: 1,
                child: TapRegion(
                  groupId: _group,
                  child: SizedBox(
                    width: _width,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (_below ? -4 : 4) * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _HintPainter(pointer: _pointer, below: _below),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            _below ? 25 : 16,
                            16,
                            _below ? 16 : 25,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.message,
                              key: const ValueKey('feedback-telegram-hint'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: bodyFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: IconButton(
            key: _anchor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 20, height: 20),
            style: IconButton.styleFrom(
              minimumSize: const Size.square(20),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: _toggle,
            icon: Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: _portal.isShowing ? ui(context).accent : ui(context).muted,
            ),
            tooltip: null,
            isSelected: _portal.isShowing,
          ),
        ),
      ),
    ),
  );
}

class _HintPainter extends CustomPainter {
  const _HintPainter({required this.pointer, required this.below});
  final double pointer;
  final bool below;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, below ? 9 : 0, size.width, size.height - 9);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    final edge = below ? rect.top : rect.bottom;
    path.moveTo(pointer - 9, edge);
    path.lineTo(pointer, below ? 0 : size.height);
    path.lineTo(pointer + 9, edge);
    path.close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: .2), 8, false);
    canvas.drawPath(path, Paint()..color = const Color(0xff211b31));
  }

  @override
  bool shouldRepaint(covariant _HintPainter oldDelegate) =>
      pointer != oldDelegate.pointer || below != oldDelegate.below;
}
