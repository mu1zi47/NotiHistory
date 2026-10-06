import 'saved_notification.dart';
import 'saved_app.dart';

class HistoryPage {
  const HistoryPage({
    this.items = const [],
    this.apps = const [],
    this.total = 0,
    this.today = 0,
    this.matched = 0,
    this.hasMore = false,
  });
  final List<SavedNotification> items;
  final List<SavedApp> apps;
  final int total, today, matched;
  final bool hasMore;
}
