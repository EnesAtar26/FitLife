import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/water_log_model.dart';

// --- ARKA PLAN İŞLEMCİSİ ---
@pragma('vm:entry-point')
void notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  // 1. Motoru Başlat
  WidgetsFlutterBinding.ensureInitialized();

  print("🔔 BİLDİRİM BUTONUNA BASILDI: ${notificationResponse.actionId}");

  if (notificationResponse.actionId == 'add_water') {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // En güncel veriyi al

      int userId = prefs.getInt('current_user_id') ?? 1;
      int goal = prefs.getInt('water_goal') ?? 8;

      final now = DateTime.now();
      String todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // WaterScreen'in kullandığı anahtar yapısı (water_2025_1_14 gibi)
      String todayKey = "water_${now.year}_${now.month}_${now.day}";

      // 2. Veritabanına Ekle (Kalıcı Kayıt)
      WaterLog newLog = WaterLog(
        userId: userId,
        date: todayStr,
        amountGlasses: 1,
        timestamp: now.toIso8601String(),
      );

      await DatabaseHelper.instance.createWaterLog(newLog);
      print("✅ Veritabanına eklendi (Arka Plan)");

      // 3. Yeni Toplamı Hesapla
      List<WaterLog> allLogs = await DatabaseHelper.instance
          .getWaterLogsForUser(userId);
      int totalWaterToday = 0;
      for (var log in allLogs) {
        if (log.date == todayStr) {
          totalWaterToday += log.amountGlasses;
        }
      }

      // 👇👇👇 KRİTİK DÜZELTME BURADA 👇👇👇
      // WaterScreen ekranının okuduğu yeri de güncelliyoruz!
      await prefs.setInt(todayKey, totalWaterToday);
      // 👆👆👆 ARTIK EKRAN GÜNCEL SAYIYI BİLECEK 👆👆👆

      // 4. Bildirimi Güncelle
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      int progress = totalWaterToday > goal ? goal : totalWaterToday;

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
            progress: progress,
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
        'Su Hedefi: $totalWaterToday / $goal 💧',
        'Harikasın! Bir bardak daha içmeye ne dersin? 💧',
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
        // Uygulama ön plandayken butona basılırsa
        if (details.actionId == 'add_water') {
          notificationTapBackground(details);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // ==========================================
  // 1. GERÇEK SİSTEM (Üretim Modu) 📅
  // ==========================================
  Future<void> setupDailyReminders() async {
    print("📅 Gerçek zamanlı hatırlatıcılar kuruluyor...");

    await flutterLocalNotificationsPlugin.cancel(101);
    await flutterLocalNotificationsPlugin.cancel(102);
    await flutterLocalNotificationsPlugin.cancel(999);

    await _scheduleDaily(
      id: 101,
      title: "Su İçme Zamanı 💧",
      body: "Vücudunun suya ihtiyacı var. Bir bardak su içme vakti! 💧",
      hour: 14,
      minute: 00,
    );

    await _scheduleDaily(
      id: 102,
      title: "Hareket Vakti 🏃",
      body: "Bugünkü hedeflerini tamamladın mı? Hadi biraz hareket edelim! 🏃",
      hour: 20,
      minute: 00,
    );

    await _scheduleInactivity();
    await _refreshWaterProgressFromDB();

    print("✅ Gerçek sistem aktif: Metinler güncellendi.");
  }

  // ==========================================
  // 2. SİMÜLASYON MODU (30 Saniye Sonra) 🚀
  // ==========================================
  Future<void> scheduleAllSimulations() async {
    print("🧪 Simülasyon Modu: 30 saniye sonra örnekler gelecek...");

    final now = tz.TZDateTime.now(tz.UTC);
    final triggerTime = now.add(const Duration(seconds: 30));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      201,
      'DEMO: Su İçme Zamanı 💧',
      'Vücudunun suya ihtiyacı var. Bir bardak su içme vakti! 💧',
      triggerTime,
      _simulationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      202,
      'DEMO: Hareket Vakti 🏃',
      'Bugünkü hedeflerini tamamladın mı? Hadi biraz hareket edelim! 🏃',
      triggerTime,
      _simulationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      203,
      'DEMO: Seni Çok Özledik 🥺',
      '3 gündür FitLife\'a uğramadın. Sağlığın için geri dönmeye ne dersin? 🥺',
      triggerTime,
      _simulationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  NotificationDetails _simulationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'simulation_channel',
        'Test Bildirimleri',
        channelDescription: '30 saniyelik testler',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  // ==========================================
  // YARDIMCI METOTLAR
  // ==========================================

  Future<void> showWaterProgressNotification(int current, int goal) async {
    int progress = current > goal ? goal : current;
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
          progress: progress,
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
      'Su Hedefi: $current / $goal 💧',
      'Harikasın! Bir bardak daha içmeye ne dersin? 💧',
      NotificationDetails(android: androidDetails),
    );
  }

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
          'daily_reminders_channel',
          'Günlük Hatırlatıcılar',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleInactivity() async {
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(days: 3));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      999,
      'Seni Çok Özledik 🥺',
      '3 gündür FitLife\'a uğramadın. Sağlığın için geri dönmeye ne dersin? 🥺',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_channel',
          'Hareketsizlik Bildirimi',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _refreshWaterProgressFromDB() async {
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
    await showWaterProgressNotification(total, goal);
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
    if (scheduledDate.isBefore(now))
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    return scheduledDate;
  }
}
