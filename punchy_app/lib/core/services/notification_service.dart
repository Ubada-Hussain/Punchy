import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(const AndroidNotificationChannel(
    'punchy_alerts_v2', 'Punchy notifications',
    description: 'Account, punch and support notifications', importance: Importance.high,
    playSound: true, enableVibration: true,
  ));
  await plugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
    message.notification?.title ?? message.data['title'] ?? 'Punchy',
    message.notification?.body ?? message.data['body'] ?? '',
    const NotificationDetails(android: AndroidNotificationDetails(
      'punchy_alerts_v2', 'Punchy notifications',
      channelDescription: 'Account, punch and support notifications', importance: Importance.high,
      priority: Priority.high, playSound: true, enableVibration: true,
      visibility: NotificationVisibility.public, icon: '@mipmap/ic_launcher',
    )),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _localNotifications.initialize(settings);
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true, provisional: false);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'punchy_alerts_v2',
      'Punchy notifications',
      description: 'Account, punch and support notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
    FirebaseMessaging.onMessage.listen((message) async {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        message.notification?.title ?? 'Punchy',
        message.notification?.body ?? '',
        const NotificationDetails(android: AndroidNotificationDetails(
          'punchy_alerts_v2', 'Punchy notifications',
          channelDescription: 'Account, punch and support notifications',
          importance: Importance.high, priority: Priority.high,
          playSound: true, enableVibration: true, visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
        )),
      );
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('latest_fcm_token', token);
      } catch (_) {}
    });
    _initialized = true;
  }

  /// Check if user has push notifications enabled in Settings
  Future<bool> isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('push_notifications_enabled') ?? true;
  }

  /// Toggle push notifications setting
  Future<void> setPushEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', enabled);
  }

  /// Show in-app notification banner / snackbar respecting user settings
  Future<void> showInAppNotification(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color? iconColor,
  }) async {
    final enabled = await isPushEnabled();
    if (!enabled) return; // User opted out of push/alerts

    if (!context.mounted) return;

    await initialize();
    if (!context.mounted) return;
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'punchy_alerts_v2',
          'Punchy notifications',
          channelDescription: 'Account, punch and support notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'Punchy notification',
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.teal).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
