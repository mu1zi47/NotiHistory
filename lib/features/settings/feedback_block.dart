import 'package:flutter/material.dart';

import 'feedback/feedback_form.dart';
import 'feedback/feedback_repository.dart';

import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/option_icon.dart';

class FeedbackBlock extends StatefulWidget {
  const FeedbackBlock({
    super.key,
    this.repository = const FeedbackRepository(),
  });
  final FeedbackRepository repository;
  @override
  State<FeedbackBlock> createState() => _FeedbackBlockState();
}

class _FeedbackBlockState extends State<FeedbackBlock> {
  bool _expanded = false, _busy = false;

  Future<void> _open(BuildContext context, String destination) async {
    try {
      await const MethodChannel('notihistory/history')
          .invokeMethod<void>('openFeedback', {'destination': destination});
    } on PlatformException {
      if (context.mounted) {
        showAppToast(
          context,
          tr(
            context,
            destination == 'email'
                ? 'Не найдено почтовое приложение.'
                : 'Не удалось открыть страницу.',
          ),
          error: true,
        );
      }
    } on MissingPluginException {
      if (context.mounted) {
        showAppToast(
          context,
          tr(context, 'Не удалось открыть страницу.'),
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: ui(context).surface,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          key: const ValueKey('feedback-form'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: const OptionIcon(
            icon: Icons.edit_note_rounded,
            selected: false,
          ),
          title: Text(tr(context, 'Написать разработчику')),
          trailing: AnimatedRotation(
            key: const ValueKey('feedback-expand-arrow'),
            turns: _expanded ? .25 : 0,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            child: Icon(Icons.chevron_right_rounded, color: ui(context).muted),
          ),
          onTap: _busy
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _expanded = !_expanded);
                },
        ),
        AnimatedCrossFade(
          key: const ValueKey('feedback-expand-content'),
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            child: FeedbackForm(
              repository: widget.repository,
              onBusyChanged: (value) {
                if (mounted) setState(() => _busy = value);
              },
              onSent: () {
                if (mounted) setState(() => _expanded = false);
              },
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 280),
          sizeCurve: Curves.easeInOutCubic,
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeIn,
          alignment: Alignment.topCenter,
        ),
        Divider(height: 1, thickness: 1, color: ui(context).divider),
        ListTile(
          key: const ValueKey('feedback-email'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: const OptionIcon(
            icon: Icons.mail_outline_rounded,
            selected: false,
          ),
          title: Text(tr(context, 'Написать на почту')),
          trailing: Icon(Icons.chevron_right_rounded, color: ui(context).muted),
          onTap: () => _open(context, 'email'),
        ),
        Divider(height: 1, thickness: 1, color: ui(context).divider),
        ListTile(
          key: const ValueKey('feedback-telegram'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: const OptionIcon(icon: Icons.telegram, selected: false),
          title: Text(tr(context, 'Telegram')),
          trailing: Icon(Icons.chevron_right_rounded, color: ui(context).muted),
          onTap: () => _open(context, 'telegram'),
        ),
      ],
    ),
  );
}
