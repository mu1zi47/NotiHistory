import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noti_history/core/theme/app_theme.dart';
import 'package:noti_history/features/settings/feedback/feedback_form.dart';
import 'package:noti_history/features/settings/feedback/feedback_hint.dart';
import 'package:noti_history/features/settings/feedback_block.dart';
import 'package:noti_history/features/settings/feedback/feedback_repository.dart';

class FakeFeedbackRepository extends FeedbackRepository {
  final messages = <FeedbackMessage>[];
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<void> send(FeedbackMessage message) async {
    messages.add(message);
    if (fail) {
      throw const FeedbackException(
        'Не удалось подключиться. Проверьте интернет и попробуйте снова.',
      );
    }
    await pending?.future;
  }
}

void main() {
  testWidgets(
    'Every feedback input loses focus on an outside touch without clearing its text',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            appBar: AppBar(title: const Text('Outside')),
            body: const SingleChildScrollView(child: FeedbackBlock()),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('feedback-form')));
      await tester.pumpAndSettle();
      for (final key in [
        'feedback-name',
        'feedback-username',
        'feedback-message',
      ]) {
        final field = find.byKey(ValueKey(key));
        await tester.ensureVisible(field);
        await tester.enterText(
          field,
          key == 'feedback-username' ? '@test_user' : 'Draft',
        );
        await tester.pumpAndSettle();
        final input = tester.widget<TextField>(
          find.descendant(of: field, matching: find.byType(TextField)),
        );
        expect(input.focusNode!.hasFocus, true);
        final text = input.controller!.text;
        await tester.tap(find.text('Outside'));
        await tester.pumpAndSettle();
        expect(input.focusNode!.hasFocus, false);
        expect(input.controller!.text, text);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Telegram cloud remains visible until outside tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.only(top: 250),
            child: Align(
              alignment: Alignment.topLeft,
              child: FeedbackHint(
                message: 'Укажите username, чтобы разработчик мог с вами связаться. Без него ответить вам не получится.',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();
    final cloud = find.byKey(const ValueKey('feedback-telegram-hint'));
    expect(cloud, findsOneWidget);
    final bounds = tester.getRect(cloud);
    expect(bounds.left, greaterThanOrEqualTo(16));
    expect(bounds.right, lessThanOrEqualTo(344));
    expect(bounds.top, greaterThan(0));
    expect(bounds.bottom, lessThan(250));
    await tester.pump(const Duration(seconds: 10));
    expect(cloud, findsOneWidget);
    await tester.tap(cloud);
    await tester.pumpAndSettle();
    expect(cloud, findsOneWidget);
    await tester.tapAt(const Offset(330, 680));
    await tester.pumpAndSettle();
    expect(cloud, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Field errors require submit, retain borders, and focus clears until next submit',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(child: FeedbackBlock()),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('feedback-form')));
      await tester.pumpAndSettle();
      final name = find.byKey(const ValueKey('feedback-name'));
      await tester.enterText(name, '');
      await tester.tap(find.byKey(const ValueKey('feedback-topic')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feedback-topic-0')));
      await tester.pumpAndSettle();
      expect(find.text('Укажите имя'), findsNothing);
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-submit')));
      await tester.tap(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Укажите имя'), findsOneWidget);
      final field = tester.widget<TextFormField>(
        find.descendant(of: name, matching: find.byType(TextFormField)),
      );
      // The effective decoration is on the inner text field.
      final decoration = tester
          .widget<TextField>(
            find.descendant(of: name, matching: find.byType(TextField)),
          )
          .decoration!;
      expect(decoration.errorBorder, isA<OutlineInputBorder>());
      expect(
        (decoration.errorBorder! as OutlineInputBorder).borderSide.style,
        BorderStyle.solid,
      );
      expect(
        (decoration.focusedErrorBorder! as OutlineInputBorder).borderSide.width,
        greaterThan(0),
      );
      expect(field.autovalidateMode, AutovalidateMode.disabled);
      await tester.ensureVisible(name);
      await tester.enterText(name, 'temporary');
      await tester.pumpAndSettle();
      expect(find.text('Укажите имя'), findsNothing);
      await tester.enterText(name, '');
      await tester.tap(find.byKey(const ValueKey('feedback-topic')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feedback-topic-0')));
      await tester.pumpAndSettle();
      expect(find.text('Укажите имя'), findsNothing);
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-submit')));
      await tester.tap(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Укажите имя'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'No request before consent; cancel keeps fields; error keeps draft and retry sends only form',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = FakeFeedbackRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FeedbackBlock(repository: repository),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('feedback-form')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      expect(repository.messages, isEmpty);
      expect(find.text('Укажите имя'), findsOneWidget);
      expect(find.text('Отправить обращение?'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('feedback-name')),
        'Tester',
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-username')),
        'test_user',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('feedback-message')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-message')),
        'Only this message',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      expect(repository.messages, isEmpty);
      expect(find.text('Отправить обращение?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('feedback-confirm-cancel')));
      await tester.pumpAndSettle();
      expect(repository.messages, isEmpty);
      expect(find.text('Only this message'), findsOneWidget);
      repository.fail = true;
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feedback-confirm-send')));
      await tester.pumpAndSettle();
      expect(repository.messages.length, 1);
      expect(find.byKey(const ValueKey('feedback-error')), findsOneWidget);
      expect(find.text('Only this message'), findsOneWidget);
      expect(repository.messages.single.toJson(), {
        'name': 'Tester',
        'telegramUser': '@test_user',
        'topic': 'Что-то не работает',
        'message': 'Only this message',
        'source': 'app',
      });
      repository.fail = false;
      repository.pending = Completer<void>();
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feedback-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feedback-confirm-send')));
      // Dismiss the confirmation and begin the pending request (spinner never settles).
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(repository.messages.length, 2);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('feedback-submit')))
            .onPressed,
        isNull,
      );
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedCrossFade>(
              find.byKey(const ValueKey('feedback-expand-content')),
            )
            .crossFadeState,
        CrossFadeState.showFirst,
      );
      expect(find.text('Сообщение отправлено'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Accordion preserves draft, rotates arrow and topic opens a sheet',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(child: FeedbackBlock()),
          ),
        ),
      );
      final arrow = find.byKey(const ValueKey('feedback-expand-arrow'));
      expect(tester.widget<AnimatedRotation>(arrow).turns, 0);
      await tester.tap(find.byKey(const ValueKey('feedback-form')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.widget<AnimatedRotation>(arrow).turns, .25);
      await tester.enterText(
        find.byKey(const ValueKey('feedback-name')),
        'Draft',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-topic')));
      await tester.tap(find.byKey(const ValueKey('feedback-topic')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      await tester.tap(find.byKey(const ValueKey('feedback-topic-1')));
      await tester.pumpAndSettle();
      expect(find.text('Есть идея'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-form')));
      await tester.tap(find.byKey(const ValueKey('feedback-form')));
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedRotation>(arrow).turns, 0);
      await tester.tap(find.byKey(const ValueKey('feedback-form')));
      await tester.pumpAndSettle();
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Есть идея'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('feedback-submit')));
      await tester.tap(find.byKey(const ValueKey('feedback-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final error = find.widgetWithText(
        AnimatedFeedbackError,
        'Напишите сообщение',
      );
      expect(error, findsOneWidget);
      final fade = tester.widget<Opacity>(
        find.descendant(of: error, matching: find.byType(Opacity)).first,
      );
      expect(fade.opacity, greaterThan(0));
      expect(fade.opacity, lessThan(1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Form fits keyboard, small screen and dark theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.dark),
        home: const Scaffold(
          body: SingleChildScrollView(child: FeedbackBlock()),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('feedback-form')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('feedback-submit')));
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(find.byKey(const ValueKey('feedback-submit'))).dy,
      lessThanOrEqualTo(460),
    );
    expect(tester.takeException(), isNull);
  });
}
