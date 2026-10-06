import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/history/data/platform_history_repository.dart';
import 'features/history/domain/history_repository.dart';
import 'features/history/presentation/history_screen.dart';

class NotiHistoryApp extends StatefulWidget {
  const NotiHistoryApp({super.key, this.repository});
  final HistoryRepository? repository;
  @override
  State<NotiHistoryApp> createState() => _NotiHistoryAppState();
}

class _NotiHistoryAppState extends State<NotiHistoryApp> {
  late final HistoryRepository _repository =
      widget.repository ?? PlatformHistoryRepository();
  late final ThemeData _theme = buildAppTheme();
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NotiHistory',
    debugShowCheckedModeBanner: false,
    theme: _theme,
    home: HistoryScreen(repository: _repository),
  );
}
