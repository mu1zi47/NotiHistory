class SavedNotification {
  const SavedNotification({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.body,
    required this.subText,
    required this.postedAt,
    required this.savedAt,
    this.hasImage = false,
  });
  factory SavedNotification.fromMap(Map<Object?, Object?> map) =>
      SavedNotification(
        id: map['id'] as int,
        hasImage: map['hasImage'] == true,
        packageName: map['packageName'] as String,
        appName: map['appName'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        subText: map['subText'] as String,
        postedAt: DateTime.fromMillisecondsSinceEpoch(map['postedAt'] as int),
        savedAt: DateTime.fromMillisecondsSinceEpoch(map['savedAt'] as int),
      );
  final int id;
  final bool hasImage;
  final String packageName, appName, title, body, subText;
  final DateTime postedAt, savedAt;
}
