import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'period_filter_button.dart';

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
              key: const ValueKey('search-field'),
              width: double.infinity,
              height: 42,
              child: TextField(
                controller: widget.search,
                focusNode: _focus,
                onChanged: widget.onSearchChanged,
                onTapOutside: (_) => _focus.unfocus(),
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Поиск уведомлений',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(actionRadius),
                    borderSide: const BorderSide(color: Color(0xFFECEAF3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(actionRadius),
                    borderSide: const BorderSide(color: Color(0xFFECEAF3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(actionRadius),
                    borderSide: const BorderSide(color: accent),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: muted,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Закрыть поиск',
                    onPressed: _closeSearch,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            )
          : Align(
              key: const ValueKey('visible-actions'),
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconActionButton(
                      key: const ValueKey('search-button'),
                      tooltip: 'Поиск',
                      icon: Icons.search_rounded,
                      label: 'Поиск',
                      onTap: _openSearch,
                    ),
                    const SizedBox(width: 6),
                    _IconActionButton(
                      tooltip: 'Фильтр приложений',
                      icon: Icons.tune_rounded,
                      label: 'Фильтр',
                      badgeCount: widget.filterCount,
                      onTap: widget.onFilter,
                    ),
                    const SizedBox(width: 6),
                    _IconActionButton(
                      tooltip:
                          widget.filterCount > 0 ||
                              widget.period != 0 ||
                              widget.search.text.isNotEmpty
                          ? 'Очистить по фильтру'
                          : 'Очистить всё',
                      icon: Icons.delete_outline_rounded,
                      label: 'Очистить',
                      onTap: widget.canClearHistory
                          ? widget.onClearHistory
                          : null,
                    ),
                    const SizedBox(width: 6),
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

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    this.label,
    this.badgeCount = 0,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final String? label;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: onTap == null
          ? accentSurface.withValues(alpha: .55)
          : accentSurface,
      borderRadius: BorderRadius.circular(actionRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(actionRadius),
        child: SizedBox(
          height: 42,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: 10,
              end: label == null ? 10 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: onTap == null ? accent.withValues(alpha: .45) : accent,
                ),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    label!,
                    style: TextStyle(
                      color: onTap == null
                          ? accent.withValues(alpha: .45)
                          : accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (badgeCount > 0) ...[
                  const SizedBox(width: 3),
                  Text(
                    '$badgeCount',
                    key: ValueKey('action-count-$tooltip'),
                    style: TextStyle(
                      color: onTap == null
                          ? accent.withValues(alpha: .45)
                          : accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
