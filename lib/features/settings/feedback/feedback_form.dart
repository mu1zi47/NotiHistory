import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../history/presentation/widgets/history_sheet.dart';
import 'feedback_repository.dart';
import 'feedback_hint.dart';
import '../../../core/widgets/option_icon.dart';

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({
    super.key,
    this.repository = const FeedbackRepository(),
    this.onSent,
    this.onBusyChanged,
  });
  final FeedbackRepository repository;
  final VoidCallback? onSent;
  final ValueChanged<bool>? onBusyChanged;
  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _telegram = TextEditingController();
  final _message = TextEditingController();
  final _nameState = GlobalKey<FormFieldState<String>>();
  final _telegramState = GlobalKey<FormFieldState<String>>();
  final _messageState = GlobalKey<FormFieldState<String>>();
  final _nameFocus = FocusNode();
  final _telegramFocus = FocusNode();
  final _messageFocus = FocusNode();
  bool _validating = false;
  String _topic = feedbackTopics.first;

  @override
  void initState() {
    super.initState();
    for (final pair in [
      (_nameFocus, _nameState),
      (_telegramFocus, _telegramState),
      (_messageFocus, _messageState),
    ]) {
      pair.$1.addListener(() {
        if (pair.$1.hasFocus) pair.$2.currentState?.validate();
      });
    }
  }

  bool _busy = false, _sending = false;
  String? _error;

  @override
  void dispose() {
    _nameFocus.dispose();
    _telegramFocus.dispose();
    _messageFocus.dispose();
    _name.dispose();
    _telegram.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _validating = true;
    final valid = _form.currentState!.validate();
    _validating = false;
    if (!valid) return;
    final message = FeedbackMessage(
      name: _name.text,
      telegramUser: _telegram.text,
      topic: _topic,
      message: _message.text,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusyChanged?.call(true);
    final confirmed = await showHistorySheet<bool>(
      context,
      (context) => HistorySheet(
        viewportRadius: 0,
        header: Center(
          child: Text(
            tr(context, 'Отправить обращение?'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: titleFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        footer: Row(
          children: [
            Expanded(
              child: TextButton(
                key: const ValueKey('feedback-confirm-cancel'),
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr(context, 'Отмена')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                key: const ValueKey('feedback-confirm-send'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr(context, 'Отправить')),
              ),
            ),
          ],
        ),
        children: [
          Text(
            tr(
              context,
              'Для отправки потребуется подключение к интернету. На сервер сайта NotiHistory и в Telegram разработчику будут отправлены заполненные поля формы: имя, Telegram, тема и сообщение, а также отметка об отправке из приложения. История уведомлений, архив и другие данные приложения не отправляются.',
            ),
            style: TextStyle(color: ui(context).muted, height: 1.5),
          ),
        ],
      ),
      enableDrag: false,
      waitForDismiss: true,
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _busy = false);
      widget.onBusyChanged?.call(false);
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.repository.send(message);
      if (mounted) {
        setState(() {
          _busy = false;
          _sending = false;
          _error = null;
        });
        _message.clear();
        _form.currentState?.reset();
        widget.onBusyChanged?.call(false);
        showAppToast(context, tr(context, 'Сообщение отправлено'));
        widget.onSent?.call();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _sending = false;
          _error = error is FeedbackException
              ? error.message
              : 'Не удалось отправить сообщение. Попробуйте снова.';
        });
        widget.onBusyChanged?.call(false);
      }
    }
  }

  OutlineInputBorder _errorBorder(BuildContext context) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: ui(context).deleteInk.withValues(alpha: .7)),
  );

  Widget _field(String label, Widget input, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              tr(context, label),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            if (hint != null) ...[
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: tr(context, 'Зачем указывать Telegram'),
                child: FeedbackHint(message: tr(context, hint)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        input,
      ],
    ),
  );

  Future<void> _chooseTopic() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showHistorySheet<String>(
      context,
      (context) => HistorySheet(
        header: Center(
          child: Text(
            tr(context, 'Тема обращения'),
            style: const TextStyle(
              fontFamily: titleFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        children: [
          Material(
            color: ui(context).surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < feedbackTopics.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: ui(context).divider,
                    ),
                  Semantics(
                    selected: _topic == feedbackTopics[index],
                    button: true,
                    child: InkWell(
                      key: ValueKey('feedback-topic-$index'),
                      onTap: () =>
                          Navigator.pop(context, feedbackTopics[index]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            OptionIcon(
                              icon: const [
                                Icons.bug_report_outlined,
                                Icons.lightbulb_outline_rounded,
                                Icons.install_mobile_rounded,
                                Icons.chat_bubble_outline_rounded,
                                Icons.more_horiz_rounded,
                              ][index],
                              selected: _topic == feedbackTopics[index],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tr(context, feedbackTopics[index]),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _topic == feedbackTopics[index]
                                      ? ui(context).accent
                                      : ui(context).ink,
                                ),
                              ),
                            ),
                            if (_topic == feedbackTopics[index])
                              Icon(
                                Icons.check_rounded,
                                color: ui(context).accent,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      enableDrag: false,
    );
    if (selected != null && mounted) setState(() => _topic = selected);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: IgnorePointer(
      ignoring: _busy,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              'Имя',
              KeyedSubtree(
                key: const ValueKey('feedback-name'),
                child: TextFormField(
                  key: _nameState,
                  focusNode: _nameFocus,
                  onTapOutside: (_) => _nameFocus.unfocus(),
                  controller: _name,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    errorBorder: _errorBorder(context),
                    focusedErrorBorder: _errorBorder(context),
                    hintText: tr(context, 'Как к вам обращаться'),
                    counterText: '',
                  ),
                  errorBuilder: (context, error) =>
                      AnimatedFeedbackError(message: error),
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (value) =>
                      _validating && (value == null || value.trim().isEmpty)
                      ? tr(context, 'Укажите имя')
                      : null,
                ),
              ),
            ),
            _field(
              'Telegram',
              KeyedSubtree(
                key: const ValueKey('feedback-username'),
                child: TextFormField(
                  key: _telegramState,
                  focusNode: _telegramFocus,
                  onTapOutside: (_) => _telegramFocus.unfocus(),
                  controller: _telegram,
                  maxLength: 33,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[@a-zA-Z0-9_]')),
                  ],
                  decoration: InputDecoration(
                    errorBorder: _errorBorder(context),
                    focusedErrorBorder: _errorBorder(context),
                    hintText: tr(context, '@username (необязательно)'),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    final user = value.replaceAll('@', '');
                    final normalized = user.isEmpty ? '' : '@$user';
                    if (value != normalized) {
                      _telegram.value = TextEditingValue(
                        text: normalized,
                        selection: TextSelection.collapsed(
                          offset: normalized.length,
                        ),
                      );
                    }
                  },
                  errorBuilder: (context, error) =>
                      AnimatedFeedbackError(message: error),
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (value) =>
                      _validating &&
                          value != null &&
                          value.isNotEmpty &&
                          !RegExp(r'^@[a-zA-Z0-9_]{5,32}$').hasMatch(value)
                      ? tr(
                          context,
                          'Введите @username: от 5 до 32 букв, цифр или подчёркиваний',
                        )
                      : null,
                ),
              ),
              hint: 'Укажите username, чтобы разработчик мог с вами связаться. Без него ответить вам не получится.',
            ),
            _field(
              'Тема обращения',
              InkWell(
                key: const ValueKey('feedback-topic'),
                borderRadius: BorderRadius.circular(18),
                onTap: _chooseTopic,
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    children: [
                      Expanded(child: Text(tr(context, _topic))),
                      Icon(
                        Icons.expand_more_rounded,
                        color: ui(context).accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _field(
              'Сообщение',
              KeyedSubtree(
                key: const ValueKey('feedback-message'),
                child: TextFormField(
                  key: _messageState,
                  focusNode: _messageFocus,
                  onTapOutside: (_) => _messageFocus.unfocus(),
                  controller: _message,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    errorBorder: _errorBorder(context),
                    focusedErrorBorder: _errorBorder(context),
                    hintText: tr(context, 'Напишите, что случилось'),
                  ),
                  errorBuilder: (context, error) =>
                      AnimatedFeedbackError(message: error),
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (value) =>
                      _validating && (value == null || value.trim().isEmpty)
                      ? tr(context, 'Напишите сообщение')
                      : null,
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.topCenter,
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedFeedbackError(
                        key: const ValueKey('feedback-error'),
                        message: tr(context, _error!),
                      ),
                    ),
            ),
            FilledButton(
              key: const ValueKey('feedback-submit'),
              onPressed: _busy ? null : _submit,
              child: _sending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(tr(context, 'Отправляем…')),
                      ],
                    )
                  : Text(tr(context, 'Отправить')),
            ),
          ],
        ),
      ),
    ),
  );
}

class AnimatedFeedbackError extends StatelessWidget {
  const AnimatedFeedbackError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(message),
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        heightFactor: value,
        child: Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -4 * (1 - value)),
            child: child,
          ),
        ),
      ),
    ),
    child: Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: ui(context).deleteSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: ui(context).deleteInk,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ui(context).deleteInk,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
