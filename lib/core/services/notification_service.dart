import 'package:shared_preferences/shared_preferences.dart';

import 'notification_platform.dart';

class NotificationToggleResult {
  const NotificationToggleResult({
    required this.isEnabled,
    this.message,
  });

  final bool isEnabled;
  final String? message;
}

class NotificationService {
  NotificationService._();

  static const String notificationsEnabledKey = 'notifications_enabled';
  static final NotificationService instance = NotificationService._();

  final NotificationPlatform _platform = createNotificationPlatform();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await _platform.initialize();
    _initialized = true;
  }

  Future<bool> getNotificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(notificationsEnabledKey) ?? false;
  }

  Future<NotificationToggleResult> setNotificationsEnabled(bool value) async {
    await initialize();
    final preferences = await SharedPreferences.getInstance();

    if (!value) {
      await preferences.setBool(notificationsEnabledKey, false);
      return const NotificationToggleResult(
        isEnabled: false,
        message: 'Bildirimler kapatildi.',
      );
    }

    final granted = await _platform.requestPermission();
    if (!granted) {
      await preferences.setBool(notificationsEnabledKey, false);
      return const NotificationToggleResult(
        isEnabled: false,
        message: 'Bildirim izni verilmedi.',
      );
    }

    await preferences.setBool(notificationsEnabledKey, true);
    await _platform.showNotification(
      title: 'Vaveyla',
      body: 'Bildirimler acildi.',
    );
    return const NotificationToggleResult(
      isEnabled: true,
      message: 'Bildirimler acildi.',
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    final enabled = await getNotificationsEnabled();
    if (!enabled) {
      return;
    }
    await _platform.showNotification(title: title, body: body);
  }
}
