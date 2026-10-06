import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/saved_app.dart';
import '../../domain/history_repository.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.app,
    required this.repository,
    this.size = 40,
  });
  final SavedApp app;
  final HistoryRepository repository;
  final double size;
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: repository.icon(app.packageName),
    builder: (context, snapshot) {
      final colors = [
        const Color(0xFFE9E3FB),
        const Color(0xFFE0F1EC),
        const Color(0xFFE1EDFC),
        const Color(0xFFFFE9DE),
      ];
      final fallback = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color:
              colors[app.packageName.codeUnits.fold<int>(0, (a, b) => a + b) %
                  colors.length],
          borderRadius: BorderRadius.circular(size * .3),
        ),
        alignment: Alignment.center,
        child: Text(
          app.name.isEmpty ? '?' : app.name.characters.first.toUpperCase(),
          style: TextStyle(
            fontFamily: titleFont,
            color: accent,
            fontSize: size * .4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      if (snapshot.data == null) return fallback;
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * .26),
        child: Image.memory(
          snapshot.data!,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    },
  );
}
