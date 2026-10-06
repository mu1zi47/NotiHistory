import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/history_repository.dart';
import '../../domain/saved_notification.dart';
import 'notification_image_viewer.dart';

class NotificationImage extends StatefulWidget {
  const NotificationImage({
    super.key,
    required this.item,
    required this.repository,
    this.compact = false,
  });
  final SavedNotification item;
  final HistoryRepository repository;
  final bool compact;

  @override
  State<NotificationImage> createState() => _NotificationImageState();
}

class _NotificationImageState extends State<NotificationImage> {
  late Future<Uint8List?> _image;
  final _previewKey = GlobalKey();
  bool _viewing = false;

  @override
  void initState() {
    super.initState();
    _image = widget.repository.image(widget.item.id);
  }

  @override
  void didUpdateWidget(covariant NotificationImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.savedAt != widget.item.savedAt) {
      _image = widget.repository.image(widget.item.id);
    }
  }

  Future<void> _show(Uint8List bytes) async {
    final box = _previewKey.currentContext?.findRenderObject() as RenderBox?;
    final rect = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _viewing = true);
    await openNotificationImageViewer(
      context,
      bytes,
      widget.item,
      sourceRect: rect,
    );
    if (mounted) setState(() => _viewing = false);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _image,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null || bytes.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Semantics(
          label: 'Изображение из уведомления',
          button: true,
          child: InkWell(
            onTap: () => _show(bytes),
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: _viewing ? 0 : 1,
              child: ClipRRect(
                key: _previewKey,
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  width: double.infinity,
                  height: widget.compact ? 150 : 280,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
