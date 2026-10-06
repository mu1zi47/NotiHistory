import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/history_repository.dart';
import '../domain/saved_app.dart';
import 'widgets/app_avatar.dart';
import 'widgets/history_sheet.dart';

Future<Set<String>?> showAppFilterSheet(
  BuildContext context, {
  required List<SavedApp> apps,
  required Set<String> selected,
  required HistoryRepository repository,
}) => showHistorySheet<Set<String>>(
  context,
  (_) =>
      _AppFilterSheet(apps: apps, selected: selected, repository: repository),
  enableDrag: false,
  topRadius: 18,
);

class _AppFilterSheet extends StatefulWidget {
  const _AppFilterSheet({
    required this.apps,
    required this.selected,
    required this.repository,
  });

  final List<SavedApp> apps;
  final Set<String> selected;
  final HistoryRepository repository;

  @override
  State<_AppFilterSheet> createState() => _AppFilterSheetState();
}

class _AppFilterSheetState extends State<_AppFilterSheet> {
  late final Set<String> _selected = {...widget.selected};

  void _toggle(String packageName) {
    setState(() {
      if (!_selected.add(packageName)) _selected.remove(packageName);
    });
  }

  @override
  Widget build(BuildContext context) => HistorySheet(
    controlledDismiss: true,
    viewportRadius: 18,
    header: const Center(
      child: Text(
        'Фильтр приложений',
        style: TextStyle(
          fontFamily: titleFont,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    footer: SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () =>
            Navigator.pop(context, Set<String>.unmodifiable(_selected)),
        child: Text(
          _selected.isEmpty
              ? 'Показать все'
              : 'Применить · ${_selected.length}',
        ),
      ),
    ),
    children: [
      _FilterOption(
        key: const ValueKey('filter-option-all'),
        title: 'Все приложения',
        subtitle: 'Показывать уведомления от всех приложений',
        selected: _selected.isEmpty,
        leading: Icon(
          Icons.apps_rounded,
          color: _selected.isEmpty ? accent : ink,
          size: 22,
        ),
        onTap: () => setState(_selected.clear),
      ),
      for (final app in widget.apps) ...[
        const SizedBox(height: 8),
        _FilterOption(
          key: ValueKey('filter-option-${app.packageName}'),
          title: app.name,
          subtitle: '${app.count} уведомлений',
          selected: _selected.contains(app.packageName),
          leading: AppAvatar(app: app, repository: widget.repository, size: 34),
          onTap: () => _toggle(app.packageName),
        ),
      ],
    ],
  );
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.leading,
    required this.onTap,
  });

  final String title, subtitle;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? accentSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected
              ? accent.withValues(alpha: .28)
              : const Color(0xFFECE9F3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox.square(dimension: 36, child: Center(child: leading)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: titleFont,
                        color: selected ? accent : ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey(true),
                        color: accent,
                        size: 22,
                      )
                    : const SizedBox.square(
                        key: ValueKey(false),
                        dimension: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
