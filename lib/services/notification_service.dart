import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// 👇 Veritabanı dosyalarını import et
import '../database/database_helper.dart';
import '../models/water_log_model.dart';

// --- ARKA PLAN İŞLEMCİSİ ---
@pragma('vm:entry-point')
void notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  print("🔔 BİLDİRİM BUTONUNA BASILDI: ${notificationResponse.actionId}");

  if (notificationResponse.actionId == 'add_water') {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      int userId = prefs.getInt('current_user_id') ?? 1;
      int goal = prefs.getInt('water_goal') ?? 8;

      final now = DateTime.now();
      String todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      WaterLog newLog = WaterLog(
        userId: userId,
        date: todayStr,
        amountGlasses: 1,
        timestamp: now.toIso8601String(),
      );

      await DatabaseHelper.instance.createWaterLog(newLog);

      List<WaterLog> allLogs = await DatabaseHelper.instance
          .getWaterLogsForUser(userId);
      int totalWaterToday = 0;
      for (var log in allLogs) {
        if (log.date == todayStr) {
          totalWaterToday += log.amountGlasses;
        }
      }

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // Arka plan için initialize (Android Ayarları)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'water_progress_channel',
            'Su Takibi',
            channelDescription: 'Bildirim çubuğunda su takibi',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            showProgress: true,
            maxProgress: goal,
            progress: totalWaterToday > goal ? goal : totalWaterToday,
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'add_water',
                '+1 Bardak Ekle',
                showsUserInterface: false,
                cancelNotification: false,
              ),
            ],
          );

      await flutterLocalNotificationsPlugin.show(
        888,
        'Su Hedefi: $totalWaterToday / $goal',
        'Hadi bir bardak daha iç!',
        NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      print("❌ Arka plan hatası: $e");
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    final MethodChannel platform = MethodChannel('flutter.native/helper');
    String timeZoneName;
    try {
      timeZoneName = await platform.invokeMethod('getLocalTimezone');
    } catch (e) {
      timeZoneName = 'Europe/Istanbul';
    }
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.actionId == 'add_water') {
          notificationTapBackground(details);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // --- ANA KURULUM FONKSİYONU ---
  // Uygulama açılınca Home Screen'den bu çağrılacak
  Future<void> setupDailyReminders() async {
    print("📅 Günlük hatırlatıcılar kuruluyor...");

    // Önce eski zamanlanmış bildirimleri temizle (Çakışma olmasın)
    // Not: ID 888 (Su barı) iptal edilmez çünkü o 'show' ile gösterildi, 'schedule' değil.
    await flutterLocalNotificationsPlugin.cancelAll();

    // 1. SU HATIRLATMA (Her gün 14:00)
    await _scheduleDaily(
      id: 101,
      title: "Su İçmeyi Unutma 💧",
      body: "Günlük hedefine ulaşmak için bir bardak su iç.",
      hour: 14,
      minute: 00,
    );

    // 2. AKTİVİTE HATIRLATMA (Her gün 20:00)
    await _scheduleDaily(
      id: 102,
      title: "Hareket Zamanı! 🏃",
      body: "Bugünkü egzersizlerini tamamladın mı?",
      hour: 20,
      minute: 00,
    );

    // 3. HAREKETSİZLİK HATIRLATMA (3 Gün Sonra)
    await _scheduleInactivity();

    // 4. Su Barını Güncelle (Kullanıcı görsün)
    await _refreshWaterProgress();

    print("✅ Tüm alarmlar başarıyla kuruldu.");
  }

  // Yardımcı: Günlük Alarm Kurma
  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders_channel', // Kanal ID
          'Günlük Hatırlatıcılar',
          channelDescription: 'Günlük su ve aktivite hatırlatmaları',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrarla
    );
  }

  // Yardımcı: Hareketsizlik Alarmı
  Future<void> _scheduleInactivity() async {
    // Şu andan 3 gün sonrası
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(days: 3));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999,
      'Seni Özledik! 🥺',
      '3 gündür FitLife\'a girmedin. Hadi geri dön!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_channel',
          'Hareketsizlik Bildirimi',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Yardımcı: Su barını veritabanından okuyup göster
  Future<void> _refreshWaterProgress() async {
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('current_user_id') ?? 1;
    int goal = prefs.getInt('water_goal') ?? 8;

    final now = DateTime.now();
    String todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    List<WaterLog> allLogs = await DatabaseHelper.instance.getWaterLogsForUser(
      userId,
    );
    int total = 0;
    for (var log in allLogs) {
      if (log.date == todayStr) total += log.amountGlasses;
    }

    // Su barını gösteren fonksiyonu çağır (kod tekrarını önlemek için showWater... fonksiyonunu kullanabilirsin ama burada direkt yazıyorum)
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'water_progress_channel',
          'Su Takibi',
          channelDescription: 'Bildirim çubuğunda su takibi',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showProgress: true,
          maxProgress: goal,
          progress: total > goal ? goal : total,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'add_water',
              '+1 Bardak Ekle',
              showsUserInterface: false,
              cancelNotification: false,
            ),
          ],
        );

    await flutterLocalNotificationsPlugin.show(
      888,
      'Su Hedefi: $total / $goal',
      'Hadi bir bardak daha iç!',
      NotificationDetails(android: androidDetails),
    );
  }

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
}
