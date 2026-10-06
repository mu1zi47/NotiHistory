import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

OverlayEntry? _currentToast;

void showAppToast(BuildContext context, String message, {bool error = false}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _currentToast?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _AppToast(
      message: message,
      error: error,
      onDismiss: () {
        if (_currentToast == entry) {
          entry.remove();
          _currentToast = null;
        }
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.message,
    required this.error,
    required this.onDismiss,
  });
  final String message;
  final bool error;
  final VoidCallback onDismiss;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final _curve = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _animation.forward();
    _timer = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _animation.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.error ? const Color(0xFFB95068) : accent;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 20,
      right: 20,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FadeTransition(
            opacity: _curve,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -.35),
                end: Offset.zero,
              ).animate(_curve),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: color.withValues(alpha: .12)),
                      boxShadow: [
                        BoxShadow(
                          color: ink.withValues(alpha: .12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.error
                                ? Icons.priority_high_rounded
                                : Icons.check_rounded,
                            color: color,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              fontFamily: bodyFont,
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _dismiss,
                          tooltip: 'Закрыть',
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
