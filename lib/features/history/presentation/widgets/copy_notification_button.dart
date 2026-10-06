import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyNotificationButton extends StatefulWidget {
  const CopyNotificationButton({super.key, required this.text});
  final String text;

  @override
  State<CopyNotificationButton> createState() => _CopyNotificationButtonState();
}

class _CopyNotificationButtonState extends State<CopyNotificationButton> {
  Timer? _resetTimer;
  bool _copying = false;
  bool _copied = false;
  bool _failed = false;

  Future<void> _copy() async {
    if (_copying) return;
    _resetTimer?.cancel();
    setState(() => _copying = true);
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));
      if (!mounted) return;
      setState(() {
        _copied = true;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _copied = false;
        _failed = true;
      });
    } finally {
      if (mounted) {
        setState(() => _copying = false);
        _resetTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _copied = false;
              _failed = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Semantics(
      liveRegion: true,
      child: FilledButton.icon(
        onPressed: _copying ? null : _copy,
        icon: Icon(
          _copied
              ? Icons.check_rounded
              : _failed
              ? Icons.error_outline_rounded
              : Icons.copy_rounded,
          size: 18,
        ),
        label: Text(
          _copied
              ? 'Скопировано'
              : _failed
              ? 'Не удалось скопировать'
              : 'Скопировать текст',
        ),
      ),
    ),
  );
}
