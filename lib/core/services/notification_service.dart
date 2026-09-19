import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';

/// Service de gestion des notifications locales et rappels quotidiens.
/// 100% autonome, local (sans serveur tiers) et respectueux du RGPD.
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int dailyReminderNotificationId = 1001;
  static const String channelId = 'sawki_daily_reminders';
  static const String channelName = 'Rappels Quotidiens Sawki';
  static const String channelDescription =
      'Rappels quotidiens pour préserver votre série et progresser en anglais américain.';

  /// Initialise le service de notifications locales et configure les fuseaux horaires
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint("Notification tapped: ${response.payload}");
        },
      );

      // Création du canal de notification Android
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
      debugPrint("✅ NotificationService successfully initialized.");

      // Si le rappel est activé en mémoire, on s'assure qu'il est bien programmé
      if (StorageService.isDailyReminderEnabled()) {
        final hour = StorageService.getDailyReminderHour();
        final minute = StorageService.getDailyReminderMinute();
        await scheduleDailyReminder(hour, minute);
      }
    } catch (e) {
      debugPrint("⚠️ Erreur d'initialisation de NotificationService: $e");
    }
  }

  /// Demande la permission système explicite (Android 13+ et iOS)
  Future<bool> requestPermission() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint("Erreur lors de la demande de permission de notification: $e");
      return false;
    }
  }

  /// Programme le rappel quotidien à l'heure et minute spécifiées
  Future<bool> scheduleDailyReminder(int hour, int minute) async {
    try {
      await cancelDailyReminder();

      final scheduledDate = _nextInstanceOfTime(hour, minute);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.zonedSchedule(
        id: dailyReminderNotificationId,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: '🔥 Votre flamme Sawki English vous attend !',
        body: '5 petites minutes aujourd\'hui pour perfectionner votre anglais américain.',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint("⏰ Rappel quotidien programmé à $hour:${minute.toString().padLeft(2, '0')}");
      return true;
    } catch (e) {
      debugPrint("❌ Erreur lors de la programmation du rappel quotidien: $e");
      return false;
    }
  }

  /// Calcule la prochaine occurrence de l'heure donnée dans le fuseau local
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Annule le rappel quotidien
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(id: dailyReminderNotificationId);
      debugPrint("🚫 Rappel quotidien annulé.");
    } catch (e) {
      debugPrint("Erreur lors de l'annulation du rappel: $e");
    }
  }

  /// Envoie une notification immédiate pour tester le fonctionnement
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: 999,
      title: '🇺🇸 Sawki English - Test de Notification',
      body: 'Votre système de rappel quotidien fonctionne parfaitement !',
      notificationDetails: details,
    );
  }
}
