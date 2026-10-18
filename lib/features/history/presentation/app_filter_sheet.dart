import 'package:noti_history/core/widgets/option_icon.dart';
import 'package:noti_history/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/app_toast.dart';
import 'clear_history_dialog.dart';

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
  bool archived = false,
  Future<List<SavedApp>> Function(SavedApp app)? deleteApp,
}) async {
  var currentApps = apps;
  var draft = Set<String>.of(selected);
  while (true) {
    if (!context.mounted) return null;
    final result = await showHistorySheet<Object>(
      context,
      (_) => _AppFilterSheet(
        apps: currentApps,
        selected: draft,
        repository: repository,
      ),
      enableDrag: false,
      topRadius: 18,
      waitForDismiss: true,
    );
    if (result is! _DeleteAppRequest) return result as Set<String>?;
    draft = result.selected;
    if (!context.mounted) return null;
    final confirmed = await confirmClearHistory(
      context,
      appName: result.app.name,
      archived: archived,
      waitForDismiss: true,
    );
    if (!context.mounted) return null;
    if (confirmed) {
      try {
        if (deleteApp != null) {
          currentApps = await deleteApp(result.app);
        } else {
          await repository.clear(
            packageNames: {result.app.packageName},
            archived: archived,
          );
          currentApps = (await repository.query(archived: archived)).apps;
        }
        final available = currentApps.map((app) => app.packageName).toSet();
        draft.removeWhere((name) => !available.contains(name));
      } catch (_) {
        if (context.mounted) {
          showAppToast(
            context,
            tr(context, 'Не удалось удалить уведомления. Попробуйте снова.'),
            error: true,
          );
        }
      }
    }
  }
}

class _DeleteAppRequest {
  _DeleteAppRequest(this.app, this.selected);
  final SavedApp app;
  final Set<String> selected;
}

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

  bool _requestPending = false;

  void _requestDelete(SavedApp app) {
    if (_requestPending) return;
    _requestPending = true;
    Navigator.pop(context, _DeleteAppRequest(app, Set<String>.of(_selected)));
  }

  void _applyApp(String? packageName) {
    if (_requestPending) return;
    HapticFeedback.mediumImpact();
    if (packageName == null) {
      _selected.clear();
    } else {
      _selected.add(packageName);
    }
    Navigator.pop(context, Set<String>.unmodifiable(_selected));
  }

  void _toggle(String packageName) {
    setState(() {
      if (!_selected.add(packageName)) _selected.remove(packageName);
    });
  }

  @override
  Widget build(BuildContext context) => HistorySheet(
    viewportRadius: 20,
    header: Center(
      child: Text(
        tr(context, 'Фильтр приложений'),
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
              ? tr(context, 'Показать все')
              : tr(context, 'Применить · {0}', [_selected.length]),
        ),
      ),
    ),
    children: [
      ClipRRect(
        key: ValueKey('filter-apps-block'),
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: ui(context).surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterOption(
                key: ValueKey('filter-option-all'),
                showBottomBorder: widget.apps.isNotEmpty,
                onLongPress: () => _applyApp(null),
                title: tr(context, 'Все приложения'),
                subtitle: tr(
                  context,
                  'Показывать уведомления от всех приложений',
                ),
                selected: _selected.isEmpty,
                leading: OptionIcon(
                  icon: Icons.apps_rounded,
                  selected: _selected.isEmpty,
                ),
                onTap: () => setState(_selected.clear),
              ),
              for (final app in widget.apps) ...[
                _SwipeFilterApp(
                  key: ValueKey('filter-swipe-${app.packageName}'),
                  onDelete: () => _requestDelete(app),
                  child: _FilterOption(
                    key: ValueKey('filter-option-${app.packageName}'),
                    showBottomBorder: app != widget.apps.last,
                    onLongPress: () => _applyApp(app.packageName),
                    title: app.name,
                    subtitle: tr(context, '{0} уведомлений', [app.count]),
                    selected: _selected.contains(app.packageName),
                    leading: AppAvatar(
                      app: app,
                      repository: widget.repository,
                      size: 40,
                    ),
                    onTap: () => _toggle(app.packageName),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
    required this.onLongPress,
    required this.showBottomBorder,
  });

  final String title, subtitle;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: ui(context).surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            border: showBottomBorder
                ? Border(bottom: BorderSide(color: ui(context).divider))
                : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox.square(dimension: 40, child: Center(child: leading)),
              SizedBox(width: 10),
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
                        color: selected ? ui(context).accent : ui(context).ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ui(context).muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              AnimatedSwitcher(
                duration: Duration(milliseconds: 180),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        key: ValueKey(true),
                        color: ui(context).accent,
                        size: 22,
                      )
                    : SizedBox.square(key: ValueKey(false), dimension: 22),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SwipeFilterApp extends StatefulWidget {
  const _SwipeFilterApp({
    super.key,
    required this.child,
    required this.onDelete,
  });
  final Widget child;
  final VoidCallback onDelete;
  @override
  State<_SwipeFilterApp> createState() => _SwipeFilterAppState();
}

class _SwipeFilterAppState extends State<_SwipeFilterApp> {
  double _progress = 0;

  Widget _background(bool right) => LayoutBuilder(
    builder: (context, constraints) => ColoredBox(
      color: ui(context).deleteSurface,
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          width: constraints.maxWidth * _progress,
          child: AnimatedAlign(
            duration: Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: _progress >= .5
                ? Alignment.center
                : right
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                Icons.delete_outline_rounded,
                color: ui(context).deleteInk.withValues(
                  alpha: (_progress * constraints.maxWidth / 64).clamp(0, 1),
                ),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ObjectKey(this),
    direction: DismissDirection.horizontal,
    dismissThresholds: {
      DismissDirection.startToEnd: .26,
      DismissDirection.endToStart: .26,
    },
    movementDuration: Duration(milliseconds: 220),
    background: _background(false),
    secondaryBackground: _background(true),
    onUpdate: (details) {
      if (details.progress >= .26 && _progress < .26) {
        HapticFeedback.selectionClick();
      }
      setState(() => _progress = details.progress);
    },
    confirmDismiss: (_) async {
      HapticFeedback.mediumImpact();
      widget.onDelete();
      return false;
    },
    child: widget.child,
  );
}
