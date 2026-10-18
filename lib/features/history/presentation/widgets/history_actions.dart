import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'period_filter_button.dart';
import '../../../../core/widgets/app_action_button.dart';

class HistoryActions extends StatefulWidget {
  const HistoryActions({
    super.key,
    required this.search,
    required this.onSearchChanged,
    required this.onFilter,
    required this.filterCount,
    required this.onClearHistory,
    required this.canClearHistory,
    required this.period,
    required this.onPeriodChanged,
  });

  final TextEditingController search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilter;
  final int filterCount;
  final VoidCallback onClearHistory;
  final bool canClearHistory;
  final int period;
  final ValueChanged<int> onPeriodChanged;

  @override
  State<HistoryActions> createState() => _HistoryActionsState();
}

class _HistoryActionsState extends State<HistoryActions> {
  static const _duration = Duration(milliseconds: 260);
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
      duration: _duration,
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
              key: ValueKey('search-field'),
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
                  hintText: tr(context, 'Поиск уведомлений'),
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
              key: ValueKey('visible-actions'),
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppActionButton(
                      key: ValueKey('search-button'),
                      tooltip: tr(context, 'Поиск'),
                      icon: Icons.search_rounded,
                      label: tr(context, 'Поиск'),
                      onTap: _openSearch,
                    ),
                    SizedBox(width: 6),
                    AppActionButton(
                      tooltip: tr(context, 'Фильтр приложений'),
                      icon: Icons.tune_rounded,
                      label: tr(context, 'Фильтр'),
                      badgeCount: widget.filterCount,
                      onTap: widget.onFilter,
                    ),
                    SizedBox(width: 6),
                    AppActionButton(
                      tooltip:
                          widget.filterCount > 0 ||
                              widget.period != 0 ||
                              widget.search.text.isNotEmpty
                          ? tr(context, 'Очистить по фильтру')
                          : tr(context, 'Очистить всё'),
                      icon: Icons.delete_outline_rounded,
                      label: tr(context, 'Очистить'),
                      onTap: widget.canClearHistory
                          ? widget.onClearHistory
                          : null,
                    ),
                    SizedBox(width: 6),
                    PeriodFilterButton(
                      selected: widget.period,
                      onSelected: widget.onPeriodChanged,
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
