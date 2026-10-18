import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/formatting/notification_date.dart';
import '../../domain/saved_notification.dart';

Future<void> openNotificationImageViewer(
  BuildContext context,
  Uint8List bytes,
  SavedNotification item, {
  Rect? sourceRect,
}) => Navigator.of(context).push<void>(
  PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => NotificationImageViewer(
      bytes: bytes,
      item: item,
      sourceRect: sourceRect,
    ),
    transitionsBuilder: (_, _, _, child) => child,
  ),
);

class NotificationImageViewer extends StatefulWidget {
  const NotificationImageViewer({
    super.key,
    required this.bytes,
    required this.item,
    this.sourceRect,
  });
  final Uint8List bytes;
  final SavedNotification item;
  final Rect? sourceRect;

  @override
  State<NotificationImageViewer> createState() =>
      _NotificationImageViewerState();
}

class _NotificationImageViewerState extends State<NotificationImageViewer>
    with TickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoomAnimation;
  late final AnimationController _motionAnimation;
  late final AnimationController _returnAnimation;
  late final AnimationController _entryAnimation;
  Animation<Rect?>? _returnRect;
  Animation<Matrix4>? _matrix;
  Animation<Offset>? _motion;
  Size _viewport = Size.zero;
  Offset? _doubleTap;
  Offset _drag = Offset.zero;
  bool _chrome = true,
      _zoomed = false,
      _baseGesture = false,
      _pinching = false,
      _closing = false;

  @override
  void initState() {
    super.initState();
    _zoomAnimation =
        AnimationController(vsync: this, duration: Duration(milliseconds: 280))
          ..addListener(() {
            if (_matrix != null) _transform.value = _matrix!.value;
          });
    _motionAnimation =
        AnimationController(vsync: this, duration: Duration(milliseconds: 220))
          ..addListener(() {
            if (_motion != null) setState(() => _drag = _motion!.value);
          });
    _returnAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 320),
    )..addListener(() => setState(() {}));
    _entryAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 320),
    )..addListener(() => setState(() {}));
    if (widget.sourceRect == null) {
      _entryAnimation.value = 1;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entryAnimation.forward();
      });
    }
    _transform.addListener(_scaleChanged);
    _systemBars(false);
  }

  Future<void> _systemBars(bool hidden) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      try {
        await MethodChannel('notihistory/history')
            .invokeMethod<void>('imageFullscreen', {'hidden': hidden});
      } on PlatformException {
        /* Keep the edge-to-edge viewer usable. */
      } on MissingPluginException {
        /* Non-Android preview. */
      }
    } else {
      await SystemChrome.setEnabledSystemUIMode(
        hidden ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    }
  }

  void _scaleChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _toggleChrome() {
    if (_closing) return;
    setState(() => _chrome = !_chrome);
    _systemBars(!_chrome);
  }

  void _zoom() {
    if (_closing) return;
    _zoomAnimation.stop();
    final scale = _zoomed ? 1.0 : 2.5;
    final focal = _doubleTap ?? _viewport.center(Offset.zero);
    final scene = _transform.toScene(focal);
    final target = scale == 1
        ? Matrix4.identity()
        : (Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(
            focal.dx - scene.dx * scale,
            focal.dy - scene.dy * scale,
            0,
          ));
    _matrix = Matrix4Tween(begin: _transform.value.clone(), end: target)
        .animate(
          CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeInOutCubic),
        );
    _zoomAnimation.forward(from: 0);
  }

  Future<void> _moveTo(Offset target, {bool close = false}) async {
    _motionAnimation.stop();
    _motion = Tween<Offset>(begin: _drag, end: target).animate(
      CurvedAnimation(parent: _motionAnimation, curve: Curves.easeOutCubic),
    );
    if (close) setState(() => _closing = true);
    try {
      await _motionAnimation.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (close && mounted) Navigator.pop(context);
  }

  Future<void> _closeToSource() async {
    if (_closing) return;
    _zoomAnimation.stop();
    _motionAnimation.stop();
    final scale = 1 - (_drag.distance / 350).clamp(0.0, 1.0) * .12;
    final entryRect = widget.sourceRect == null
        ? _imageRect
        : Rect.lerp(
            widget.sourceRect,
            _imageRect,
            Curves.easeInOutCubic.transform(_entryAnimation.value),
          )!;
    final fitted = _entryAnimation.isCompleted ? _imageRect : entryRect;
    _entryAnimation.stop();
    final transformed = MatrixUtils.transformRect(_transform.value, fitted);
    final center = _viewport.center(Offset.zero);
    final start = Rect.fromCenter(
      center: center + (transformed.center - center) * scale + _drag,
      width: transformed.width * scale,
      height: transformed.height * scale,
    );
    final target = widget.sourceRect;
    if (target == null) {
      setState(() => _closing = true);
      Navigator.pop(context);
      return;
    }
    setState(() => _closing = true);
    _systemBars(false);
    _returnRect = RectTween(begin: start, end: target).animate(
      CurvedAnimation(parent: _returnAnimation, curve: Curves.easeInOutCubic),
    );
    try {
      await _returnAnimation.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  void _start(ScaleStartDetails details) {
    if (_closing) return;
    _zoomAnimation.stop();
    _motionAnimation.stop();
    _baseGesture = !_zoomed;
    _pinching = details.pointerCount > 1;
  }

  void _update(ScaleUpdateDetails details) {
    if (_closing || !_baseGesture) return;
    if (details.pointerCount > 1 || (details.scale - 1).abs() > .01) {
      _pinching = true;
      if (_drag != Offset.zero) setState(() => _drag = Offset.zero);
    }
    if (!_pinching) setState(() => _drag += details.focalPointDelta);
  }

  void _end(ScaleEndDetails details) {
    if (_closing || !_baseGesture || _pinching) return;
    final velocity = details.velocity.pixelsPerSecond;
    if (_drag.distance > 90 ||
        (_drag.distance > 15 && velocity.distance > 700)) {
      _closeToSource();
    } else {
      _moveTo(Offset.zero);
    }
  }

  @override
  void dispose() {
    _entryAnimation.dispose();
    _returnAnimation.dispose();
    _zoomAnimation.dispose();
    _motionAnimation.dispose();
    _transform.removeListener(_scaleChanged);
    _transform.dispose();
    _systemBars(false);
    super.dispose();
  }

  Rect get _imageRect {
    final source = widget.sourceRect;
    if (source == null) return Offset.zero & _viewport;
    final fitted = applyBoxFit(
      BoxFit.contain,
      source.size,
      _viewport,
    ).destination;
    return Rect.fromCenter(
      center: _viewport.center(Offset.zero),
      width: fitted.width,
      height: fitted.height,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _closing,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _closeToSource();
    },
    child: _buildViewer(context),
  );

  Widget _buildViewer(BuildContext context) {
    _viewport = MediaQuery.sizeOf(context);
    final entry = Curves.easeInOutCubic.transform(_entryAnimation.value);
    final progress = (_drag.distance / 350).clamp(0.0, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha:
                      entry *
                      (1 - progress * .9) *
                      (1 - _returnAnimation.value),
                ),
              ),
            ),
            if (!_closing && _entryAnimation.isCompleted)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _viewport = constraints.biggest;
                    return Transform.translate(
                      offset: _drag,
                      child: Transform.scale(
                        scale: 1 - progress * .12,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleChrome,
                          onDoubleTapDown: (details) =>
                              _doubleTap = details.localPosition,
                          onDoubleTap: _zoom,
                          child: InteractiveViewer(
                            transformationController: _transform,
                            minScale: 1,
                            maxScale: 6,
                            panEnabled: _zoomed,
                            onInteractionStart: _start,
                            onInteractionUpdate: _update,
                            onInteractionEnd: _end,
                            child: SizedBox.expand(
                              child: Image.memory(
                                widget.bytes,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    tr(
                                      context,
                                      'Не удалось открыть изображение',
                                    ),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (!_closing &&
                !_entryAnimation.isCompleted &&
                widget.sourceRect != null)
              Positioned.fromRect(
                key: ValueKey('image-viewer-flight'),
                rect: Rect.lerp(widget.sourceRect, _imageRect, entry)!,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12 * (1 - entry)),
                  child: Image.memory(
                    widget.bytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            if (_closing && _returnRect?.value != null)
              Positioned.fromRect(
                key: ValueKey('image-viewer-flight'),
                rect: _returnRect!.value!,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    12 * _returnAnimation.value,
                  ),
                  child: Image.memory(
                    widget.bytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_chrome || _closing,
                child: AnimatedOpacity(
                  opacity: _chrome && !_closing ? entry * (1 - progress) : 0,
                  duration: Duration(milliseconds: 180),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xBB000000), Color(0x00000000)],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 12, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${fullDate(widget.item.postedAt)} · ${notificationTime(widget.item.postedAt)}',
                                    style: TextStyle(
                                      color: Color(0xFFCECAD8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: tr(context, 'Закрыть изображение'),
                              style: IconButton.styleFrom(
                                backgroundColor: Color(0x663C354D),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _closeToSource,
                              icon: Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
