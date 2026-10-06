bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String notificationTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String fullDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
String dayLabel(DateTime date) {
  final now = DateTime.now();
  if (sameDay(date, now)) return 'Сегодня';
  if (sameDay(date, DateTime(now.year, now.month, now.day - 1))) {
    return 'Вчера';
  }
  return fullDate(date);
}
