import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models.dart';
import 'repo.dart';

/// Local notifications + Supabase realtime subscription so that any change
/// to the user's `notifications` row triggers an OS-level notification on the
/// phone (the bar / shade). Works while the app is in foreground, background,
/// or recently dismissed (within the 5-min window Android keeps the socket
/// alive). Full sleep-wake delivery would need FCM, which can be added later.
class Notify {
  static final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  static StreamSubscription? _sub;
  static bool _ready = false;
  static String? _watchingUserId;

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _fln.initialize(const InitializationSettings(android: android));
    final p = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await p?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> watchUser(String userId) async {
    await init();
    if (_watchingUserId == userId) return;
    _watchingUserId = userId;
    await _sub?.cancel();
    final seen = <String>{};
    _sub = Repo.instance.notificationsStream(userId).listen((list) {
      for (final n in list) {
        if (seen.add(n.id) && !n.read) {
          // Surface as OS notification.
          _fln.show(
            n.id.hashCode,
            n.title,
            n.body,
            const NotificationDetails(android: AndroidNotificationDetails(
              'yichalal', 'Yichalal Updates',
              channelDescription: 'Booking & service updates',
              importance: Importance.high, priority: Priority.high,
            )),
          );
        }
      }
    });
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _watchingUserId = null;
  }

  /// Convenience: locally pop a notification immediately (in addition to the
  /// row already being saved to Supabase).
  static Future<void> showLocal(String title, String body) async {
    await init();
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), title, body,
      const NotificationDetails(android: AndroidNotificationDetails(
        'yichalal', 'Yichalal Updates',
        channelDescription: 'Booking & service updates',
        importance: Importance.high, priority: Priority.high,
      )),
    );
  }
}
