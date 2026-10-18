import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

Future<T?> showHistorySheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool enableDrag = true,
  double topRadius = 30,
  bool waitForDismiss = false,
}) async {
  ModalRoute<dynamic>? route;
  final result = await showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: enableDrag,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: ui(context).dark
        ? Colors.black.withValues(alpha: .6)
        : ink.withValues(alpha: .3),
    constraints: BoxConstraints(maxWidth: 600),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
    ),
    builder: (context) {
      route = ModalRoute.of(context);
      return builder(context);
    },
  );
  if (waitForDismiss) await route?.completed;
  return result;
}

/// Fits the actual content, keeping only the body scrollable when it overflows.
class HistorySheet extends StatefulWidget {
  const HistorySheet({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.viewportRadius = 20,
  });

  final List<Widget> children;
  final Widget? header;
  final Widget? footer;
  final double viewportRadius;

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet>
    with SingleTickerProviderStateMixin {
  late final _pull = AnimationController.unbounded(vsync: this);

  void _move(double delta) {
    _pull.stop();
    _pull.value = (_pull.value + delta).clamp(
      0,
      MediaQuery.sizeOf(context).height,
    );
  }

  void _finish([double velocity = 0]) {
    if (!mounted || _pull.value == 0) return;
    if (_pull.value >= 80 || velocity > 700) {
      Navigator.maybePop(context);
    } else {
      _pull.animateTo(
        0,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

  Widget _handle() => Center(
    child: Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: ui(context).muted.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pull,
    builder: (context, child) =>
        Transform.translate(offset: Offset(0, _pull.value), child: child),
    child: Material(
      color: ui(context).paper,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(widget.viewportRadius == 18 ? 18 : 30),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  key: ValueKey('history-sheet-drag-header'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) => _pull.stop(),
                  onVerticalDragUpdate: (details) => _move(details.delta.dy),
                  onVerticalDragEnd: (details) =>
                      _finish(details.primaryVelocity ?? 0),
                  onVerticalDragCancel: _finish,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _handle(),
                        if (widget.header != null) ...[
                          SizedBox(height: 12),
                          widget.header!,
                        ],
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      key: ValueKey('history-sheet-viewport'),
                      borderRadius: BorderRadius.circular(
                        widget.viewportRadius,
                      ),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.depth == 0 &&
                              notification is ScrollEndNotification) {
                            _finish(
                              notification.dragDetails?.primaryVelocity ?? 0,
                            );
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          key: ValueKey('history-sheet-scroll'),
                          physics: _PullToDismissPhysics(
                            pull: () => _pull.value,
                            move: _move,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: widget.children,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: widget.footer,
                  )
                else
                  SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Redirects a downward drag at the scroll start to the whole sheet.
class _PullToDismissPhysics extends ClampingScrollPhysics {
  const _PullToDismissPhysics({
    required this.pull,
    required this.move,
    super.parent,
  });
  final double Function() pull;
  final ValueChanged<double> move;

  @override
  _PullToDismissPhysics applyTo(ScrollPhysics? ancestor) =>
      _PullToDismissPhysics(
        pull: pull,
        move: move,
        parent: buildParent(ancestor),
      );

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (pull() > 0 ||
        (position.pixels <= position.minScrollExtent && offset > 0)) {
      move(offset);
      return 0;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}
