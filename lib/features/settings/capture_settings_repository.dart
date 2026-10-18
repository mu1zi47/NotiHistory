import 'package:flutter/services.dart';

class CaptureApp {
  const CaptureApp(this.packageName, this.name, this.enabled);
  final String packageName, name;
  final bool enabled;
}

class CaptureSettingsRepository {
  const CaptureSettingsRepository();
  static const _channel = MethodChannel('notihistory/history');

  Future<List<CaptureApp>> apps() async {
    final rows = await _channel.invokeListMethod<dynamic>('captureApps');
    return (rows ?? [])
        .map(
          (row) => CaptureApp(
            row['packageName'] as String,
            row['name'] as String,
            row['enabled'] == true,
          ),
        )
        .toList();
  }

  Future<void> enableAll() =>
      _channel.invokeMethod<void>('enableAllCaptureApps');

  Future<void> setEnabled(String packageName, bool enabled) =>
      _channel.invokeMethod<void>('setCaptureEnabled', {
        'packageName': packageName,
        'enabled': enabled,
      });
}
