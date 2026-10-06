import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/features/history/application/history_controller.dart';
import 'package:noti_history/features/history/domain/saved_notification.dart';
import 'package:noti_history/features/history/presentation/widgets/history_feed.dart';
import 'package:noti_history/features/history/presentation/widgets/notification_arrival.dart';

import 'support/memory_repository.dart';

void main() {
  testWidgets('Only a newly inserted notification animates in the feed', (
    tester,
  ) async {
    final repo = MemoryRepository();
    final controller = HistoryController(repo);
    final scroll = ScrollController();
    final swipe = ValueNotifier<int?>(null);
    addTearDown(controller.dispose);
    addTearDown(scroll.dispose);
    addTearDown(swipe.dispose);
    await controller.start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryFeed(
            controller: controller,
            scroll: scroll,
            openSwipe: swipe,
            onDelete: (_) async => true,
            onAccess: () {},
            onResetFilters: () {},
            onDetails: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    repo.entries.insert(
      0,
      SavedNotification(
        id: 3,
        packageName: 'org.telegram',
        appName: 'Telegram',
        title: 'Новое',
        body: 'Сообщение',
        subText: '',
        postedAt: DateTime.now(),
        savedAt: DateTime.now(),
      ),
    );
    await controller.refresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final arrival = find.byKey(const ValueKey('arrival-3'));
    final factor = tester
        .widget<SizeTransition>(
          find.descendant(of: arrival, matching: find.byType(SizeTransition)).first,
        )
        .sizeFactor;
    expect(factor.value, greaterThan(0));
    expect(factor.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(factor.value, 1);
    await controller.refresh();
    await tester.pump();
    expect(
      tester
          .widget<SizeTransition>(
            find.descendant(of: arrival, matching: find.byType(SizeTransition)).first,
          )
          .sizeFactor
          .value,
      1,
    );
    expect(find.byType(NotificationArrival), findsWidgets);
  });
}
