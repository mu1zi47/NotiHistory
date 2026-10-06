import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

Future<T?> showHistorySheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool enableDrag = true,
  double topRadius = 30,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  isDismissible: true,
  enableDrag: enableDrag,
  useSafeArea: true,
  showDragHandle: false,
  backgroundColor: paper,
  barrierColor: ink.withValues(alpha: .3),
  constraints: const BoxConstraints(maxWidth: 600),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
  ),
  builder: builder,
);

/// Shared geometry for period selection and notification details.
class HistorySheet extends StatefulWidget {
  const HistorySheet({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.controlledDismiss = false,
    this.viewportRadius = 20,
  });

  final List<Widget> children;
  final Widget? header;
  final Widget? footer;
  final bool controlledDismiss;
  final double viewportRadius;

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  static const _dismissDistance = 52.0;
  double _headerPull = 0;
  double _contentPull = 0;
  bool _contentDragStartedAtTop = false;

  void _dismiss() {
    if (mounted) Navigator.maybePop(context);
  }

  void _finishHeaderDrag(DragEndDetails details) {
    if (_headerPull >= _dismissDistance ||
        details.primaryVelocity != null && details.primaryVelocity! > 700) {
      _dismiss();
    }
    _headerPull = 0;
  }

  bool _handleScroll(ScrollNotification notification) {
    if (!widget.controlledDismiss) return false;
    if (notification is ScrollStartNotification) {
      _contentDragStartedAtTop =
          notification.metrics.pixels <=
          notification.metrics.minScrollExtent + .5;
      _contentPull = 0;
    } else if (notification is OverscrollNotification &&
        _contentDragStartedAtTop &&
        notification.overscroll < 0) {
      _contentPull += -notification.overscroll;
    } else if (notification is ScrollEndNotification) {
      final shouldDismiss =
          _contentDragStartedAtTop && _contentPull >= _dismissDistance;
      _contentDragStartedAtTop = false;
      _contentPull = 0;
      if (shouldDismiss) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _dismiss());
      }
    }
    return false;
  }

  Widget _handle() => Center(
    child: Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: muted.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.footer == null) {
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              const SizedBox(height: 12),
              ...widget.children,
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              key: const ValueKey('history-sheet-drag-header'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: widget.controlledDismiss
                  ? (_) => _headerPull = 0
                  : null,
              onVerticalDragUpdate: widget.controlledDismiss
                  ? (details) => _headerPull = (_headerPull + details.delta.dy)
                        .clamp(0, double.infinity)
                  : null,
              onVerticalDragEnd: widget.controlledDismiss
                  ? _finishHeaderDrag
                  : null,
              onVerticalDragCancel: widget.controlledDismiss
                  ? () => _headerPull = 0
                  : null,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _handle(),
                  ),
                  if (widget.header != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: widget.header,
                    ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  key: const ValueKey('history-sheet-viewport'),
                  borderRadius: BorderRadius.circular(widget.viewportRadius),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScroll,
                    child: SingleChildScrollView(
                      key: const ValueKey('history-sheet-scroll'),
                      physics: widget.controlledDismiss
                          ? const AlwaysScrollableScrollPhysics(
                              parent: ClampingScrollPhysics(),
                            )
                          : null,
                      padding: EdgeInsets.only(
                        top: widget.header == null ? 12 : 0,
                        bottom: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.children,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: paper,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: widget.footer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
