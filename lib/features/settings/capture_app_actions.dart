import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_action_button.dart';
import 'capture_app_filter.dart';

class CaptureAppActions extends StatefulWidget {
  const CaptureAppActions({
    super.key,
    required this.search,
    required this.onSearchChanged,
    required this.hasDisabled,
    required this.busy,
    required this.onEnableAll,
    this.filter = CaptureAppFilter.all,
    this.onFilter,
  });
  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final bool hasDisabled, busy;
  final VoidCallback onEnableAll;
  final CaptureAppFilter filter;
  final VoidCallback? onFilter;

  @override
  State<CaptureAppActions> createState() => _CaptureAppActionsState();
}

class _CaptureAppActionsState extends State<CaptureAppActions> {
  final _focus = FocusNode();
  bool _searching = false;

  void _openSearch() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _closeSearch() {
    _focus.unfocus();
    widget.search.clear();
    widget.onSearchChanged('');
    setState(() => _searching = false);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: AnimatedSwitcher(
      duration: Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerRight,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: .94, end: 1.0).animate(animation),
          alignment: Alignment.centerRight,
          child: child,
        ),
      ),
      child: _searching
          ? SizedBox(
              key: ValueKey('capture-search-field'),
              width: double.infinity,
              height: 42,
              child: TextField(
                controller: widget.search,
                focusNode: _focus,
                onChanged: widget.onSearchChanged,
                onTapOutside: (_) => _focus.unfocus(),
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: tr(context, 'Найти приложение'),
                  filled: true,
                  fillColor: ui(context).surface,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(actionRadius),
                    borderSide: BorderSide(color: ui(context).divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(actionRadius),
                    borderSide: BorderSide(color: ui(context).divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(actionRadius),
                    borderSide: BorderSide(color: ui(context).accent),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: ui(context).muted,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    tooltip: tr(context, 'Закрыть поиск'),
                    onPressed: _closeSearch,
                    icon: Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            )
          : Align(
              key: ValueKey('capture-visible-actions'),
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppActionButton(
                      tooltip: tr(context, 'Поиск'),
                      icon: Icons.search_rounded,
                      label: tr(context, 'Поиск'),
                      onTap: _openSearch,
                    ),
                    SizedBox(width: 6),
                    AppActionButton(
                      tooltip: tr(context, 'Фильтр приложений'),
                      icon: Icons.tune_rounded,
                      label: tr(context, widget.filter.label),
                      badgeCount: widget.filter == CaptureAppFilter.all ? 0 : 1,
                      onTap: widget.onFilter,
                    ),
                    IgnorePointer(
                      ignoring: !widget.hasDisabled,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => SizeTransition(
                          sizeFactor: animation,
                          axis: Axis.horizontal,
                          alignment: Alignment.centerRight,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                        child: widget.hasDisabled
                            ? Padding(
                                key: ValueKey('capture-enable-all-action'),
                                padding: EdgeInsets.only(left: 6),
                                child: AppActionButton(
                                  tooltip: tr(context, 'Включить все'),
                                  icon: Icons.done_all_rounded,
                                  label: widget.busy
                                      ? tr(context, 'Включаем…')
                                      : tr(context, 'Включить все'),
                                  onTap: widget.busy
                                      ? null
                                      : widget.onEnableAll,
                                ),
                              )
                            : SizedBox.shrink(
                                key: ValueKey('capture-all-enabled'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
