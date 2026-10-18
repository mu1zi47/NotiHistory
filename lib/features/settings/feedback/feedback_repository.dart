import 'dart:async';
import 'dart:convert';
import 'dart:io';

const feedbackTopics = [
  'Что-то не работает',
  'Есть идея',
  'Не получается установить',
  'Вопрос о приложении',
  'Другое',
];

class FeedbackMessage {
  const FeedbackMessage({
    required this.name,
    required this.telegramUser,
    required this.topic,
    required this.message,
  });
  final String name, telegramUser, topic, message;

  Map<String, String> toJson() => {
    'name': name.trim(),
    'telegramUser': telegramUser.trim(),
    'topic': topic,
    'message': message.trim(),
    'source': 'app',
  };
}

class FeedbackException implements Exception {
  const FeedbackException(this.message);
  final String message;
}

class FeedbackRepository {
  const FeedbackRepository();
  static final endpoint = Uri.parse(
    'https://notihistory.vercel.app/api/send-message',
  );

  Future<void> send(FeedbackMessage message) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      await _send(client, message).timeout(const Duration(seconds: 25));
    } on FeedbackException {
      rethrow;
    } on TimeoutException {
      throw const FeedbackException(
        'Сервер не ответил вовремя. Текст сохранён в форме. Попробуйте позже.',
      );
    } on SocketException {
      throw const FeedbackException(
        'Не удалось подключиться. Проверьте интернет и попробуйте снова.',
      );
    } on HandshakeException {
      throw const FeedbackException(
        'Не удалось установить защищённое соединение. Попробуйте позже.',
      );
    } catch (_) {
      throw const FeedbackException(
        'Не удалось отправить сообщение. Попробуйте снова.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _send(HttpClient client, FeedbackMessage message) async {
    final request = await client.postUrl(endpoint);
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    // Form fields and a fixed source marker. No history, device identifiers or logs.
    request.write(jsonEncode(message.toJson()));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw FeedbackException(switch (response.statusCode) {
        400 => 'Проверьте заполненные поля формы.',
        429 => 'Слишком много обращений. Попробуйте позже.',
        503 => 'Отправка пока не настроена. Напишите разработчику на почту или в Telegram.',
        _ => 'Не удалось отправить сообщение. Попробуйте снова.',
      });
    }
    final text = await utf8.decoder.bind(response).join();
    final result = jsonDecode(text);
    if (result is! Map || result['success'] != true) {
      throw const FeedbackException(
        'Не удалось отправить сообщение. Попробуйте снова.',
      );
    }
  }
}
