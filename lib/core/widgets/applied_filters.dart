import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

typedef _Filter = ({IconData icon, String text});

class AppliedFilters extends StatefulWidget {
  const AppliedFilters({
    super.key,
    required this.filters,
    required this.onReset,
  });
  final List<({IconData icon, String text})> filters;
  final VoidCallback onReset;

  @override
  State<AppliedFilters> createState() => _AppliedFiltersState();
}

class _AppliedFiltersState extends State<AppliedFilters>
    with TickerProviderStateMixin {
  final _entries =
      <IconData, ({_Filter filter, AnimationController controller})>{};

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(AppliedFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final active = widget.filters.map((filter) => filter.icon).toSet();
    for (final filter in widget.filters) {
      final existing = _entries[filter.icon];
      final controller =
          existing?.controller ??
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 260),
            reverseDuration: const Duration(milliseconds: 200),
          );
      _entries[filter.icon] = (filter: filter, controller: controller);
      controller.forward();
    }
    for (final icon in _entries.keys.toList()) {
      if (active.contains(icon)) continue;
      final controller = _entries[icon]!.controller;
      controller.reverse().then((_) {
        if (!mounted ||
            _entries[icon]?.controller != controller ||
            controller.value != 0 ||
            widget.filters.any((filter) => filter.icon == icon)) {
          return;
        }
        setState(() => _entries.remove(icon));
        controller.dispose();
      });
    }
  }

  @override
  void dispose() {
    for (final entry in _entries.values) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeInOutCubic,
    alignment: Alignment.topLeft,
    child: _entries.isEmpty
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('applied-filters-scroll'),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final entry in _entries.values)
                          SizeTransition(
                            key: ValueKey(entry.filter.icon),
                            axis: Axis.horizontal,
                            alignment: Alignment.centerLeft,
                            sizeFactor: entry.controller.drive(
                              CurveTween(curve: Curves.easeInOutCubic),
                            ),
                            child: FadeTransition(
                              opacity: entry.controller,
                              child: ScaleTransition(
                                scale: entry.controller.drive(
                                  Tween(begin: .92, end: 1.0).chain(
                                    CurveTween(curve: Curves.easeOutCubic),
                                  ),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ui(context).accentSurface,
                                      borderRadius: BorderRadius.circular(
                                        actionRadius,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          entry.filter.icon,
                                          size: 17,
                                          color: ui(context).accent,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          entry.filter.text,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: ui(context).accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('reset-applied-filters'),
                  tooltip: tr(context, 'Сбросить всё'),
                  onPressed: widget.filters.isEmpty
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          widget.onReset();
                        },
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: ui(context).accent,
                  ),
                ),
              ],
            ),
          ),
  );
}
