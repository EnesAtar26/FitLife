import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_6/database/database_helper.dart';
import 'package:flutter_application_6/models/activity_model.dart';
import 'package:flutter_application_6/models/sleep_log_model.dart';
import 'package:flutter_application_6/models/water_log_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseHelper _sqlite = DatabaseHelper.instance;

  // Kullanıcı giriş yapmış mı kontrolü
  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --- 1. KULLANICI PROFİL İŞLEMLERİ (YENİ) ---

  // Çevrimdışı profil var mı kontrolü
  Future<bool> hasOfflineProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('offline_first_name');
  }

  // Profil Bilgilerini Getir (Ad, Soyad, Kilo, Boy vb.)
  Future<Map<String, dynamic>> getUserProfile() async {
    if (_isLoggedIn) {
      // --- FIREBASE ---
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(_uid).get();
        if (doc.exists && doc.data() != null) {
          return doc.data() as Map<String, dynamic>;
        }
      } catch (e) {
        print("Firebase profil hatası: $e");
      }
    } else {
      // --- LOCAL (ÇEVRİMDIŞI) ---
      final prefs = await SharedPreferences.getInstance();
      return {
        'first_name': prefs.getString('offline_first_name') ?? 'Misafir',
        'last_name': prefs.getString('offline_last_name') ?? '',
        'weight_kg': prefs.getInt('offline_weight') ?? 70,
        'height_cm': prefs.getInt('offline_height') ?? 170,
        'age': prefs.getInt('offline_age') ?? 25,
        'gender': prefs.getString('offline_gender') ?? 'Erkek',
        'daily_water_goal': prefs.getInt('daily_water_goal') ?? 8,
        'daily_step_goal': prefs.getInt('daily_step_goal') ?? 10000,
        'sleep_goal_minutes': prefs.getInt('sleep_goal_minutes') ?? 450,
      };
    }
    return {};
  }

  // Profil Bilgilerini Kaydet
  Future<void> saveUserProfile(Map<String, dynamic> data) async {
    if (_isLoggedIn) {
      // --- FIREBASE ---
      await _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
    } else {
      // --- LOCAL (ÇEVRİMDIŞI) ---
      final prefs = await SharedPreferences.getInstance();
      if (data.containsKey('first_name')) await prefs.setString('offline_first_name', data['first_name']);
      if (data.containsKey('last_name')) await prefs.setString('offline_last_name', data['last_name']);
      if (data.containsKey('weight_kg')) await prefs.setInt('offline_weight', int.parse(data['weight_kg'].toString()));
      if (data.containsKey('height_cm')) await prefs.setInt('offline_height', int.parse(data['height_cm'].toString()));
      if (data.containsKey('age')) await prefs.setInt('offline_age', int.parse(data['age'].toString()));
      if (data.containsKey('gender')) await prefs.setString('offline_gender', data['gender']);
    }
  }

  // --- 1. HEDEF KALORİ (Guest & Firebase) ---
  Future<int> getDailyCalorieGoal() async {
    if (_isLoggedIn) {
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(_uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['daily_calorie_goal'] ?? 2000) as int;
        }
      } catch (e) {
        print("Firebase okuma hatası: $e");
      }
    } else {
      // Misafir: Yerel hafızadan oku
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('daily_calorie_goal') ?? 2000;
    }
    return 2000;
  }

  Future<void> saveDailyCalorieGoal(int goal) async {
    if (_isLoggedIn) {
      await _db.collection('users').doc(_uid).update({'daily_calorie_goal': goal});
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_calorie_goal', goal);
    }
  }

  // --- 2. HAFTALIK KALORİ VERİLERİ (Guest & Firebase) ---
  // Varsayılan boş veri
  final List<double> _defaultWeeklyData = [0, 0, 0, 0, 0, 0, 0];

  Future<List<double>> getWeeklyCalories() async {
    if (_isLoggedIn) {
      try {
        DocumentSnapshot doc = await _db.collection('users').doc(_uid).get();
        if (doc.exists) {
           var data = doc.data() as Map<String, dynamic>;
           if (data.containsKey('weekly_calories')) {
             return List<double>.from(data['weekly_calories']);
           }
        }
      } catch (e) {
        print("Firebase veri hatası: $e");
      }
    } else {
      // Misafir
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString('weekly_calories');
      if (jsonString != null) {
        List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => (e as num).toDouble()).toList();
      }
    }
    return _defaultWeeklyData;
  }

  Future<void> saveWeeklyCalories(List<double> data) async {
    if (_isLoggedIn) {
      await _db.collection('users').doc(_uid).set(
        {'weekly_calories': data}, 
        SetOptions(merge: true) // Mevcut veriyi ezmeden güncelle
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      String jsonString = jsonEncode(data);
      await prefs.setString('weekly_calories', jsonString);
    }
  }

  Future<int> getTodayWaterCount() async {
    String todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (_isLoggedIn) {
      // FIREBASE: 'water_logs' koleksiyonunu sorgula
      QuerySnapshot snapshot = await _db
          .collection('users').doc(_uid)
          .collection('water_logs')
          .where('date', isEqualTo: todayStr)
          .get();
      
      // Doküman sayısını değil, içindeki 'amount' değerlerini topla
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data() as Map)['amount_glasses'] as int? ?? 0;
      }
      return total;
    } else {
      // SQLITE: Veritabanından sorgula
      // Not: DatabaseHelper'a özel bir sorgu eklemek gerekebilir veya tüm logları çekip filtreleriz.
      // Şimdilik varsayılan SQLite yapına uygun olarak:
      // user_id = -1 (Misafir ID'si olarak kabul edelim)
      List<WaterLog> logs = await _sqlite.getWaterLogsForUser(-1);
      int total = 0;
      for (var log in logs) {
        if (log.date == todayStr) {
          total += log.amountGlasses;
        }
      }
      return total;
    }
  }

  Future<void> addWaterLog(int amount) async {
    String todayStr = DateTime.now().toIso8601String().split('T')[0];
    
    if (_isLoggedIn) {
      await _db.collection('users').doc(_uid).collection('water_logs').add({
        'date': todayStr,
        'amount_glasses': amount,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      await _sqlite.createWaterLog(WaterLog(
        userId: -1, // Misafir ID
        date: todayStr,
        amountGlasses: amount,
        timestamp: DateTime.now().toIso8601String(),
      ));
    }
  }

  Future<List<double>> getWeeklySleepData() async {
    // Burası biraz karmaşık olduğu için şimdilik özet mantığı kuruyorum.
    // Gerçek uygulamada son 7 günün verisini sorgulayıp listeye dönüştürmelisin.
    return [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]; // Placeholder
  }

  Future<void> saveSleepLog(double hours) async {
    String todayStr = DateTime.now().toIso8601String().split('T')[0];
    int minutes = (hours * 60).toInt();

    if (_isLoggedIn) {
      await _db.collection('users').doc(_uid).collection('sleep_logs').add({
        'date': todayStr,
        'duration_minutes': minutes,
      });
    } else {
      await _sqlite.createSleepLog(SleepLog(
        userId: -1,
        date: todayStr,
        durationMinutes: minutes,
        startTime: '', endTime: '' // Detay yoksa boş
      ));
    }
  }

  Future<List<Map<String, dynamic>>> getTodayActivities() async {
    String todayStr = DateTime.now().toIso8601String().split('T')[0];
    List<Map<String, dynamic>> activities = [];

    if (_isLoggedIn) {
      QuerySnapshot snapshot = await _db
          .collection('users').doc(_uid)
          .collection('activities')
          .where('date', isEqualTo: todayStr)
          .get();
          
      for (var doc in snapshot.docs) {
        activities.add(doc.data() as Map<String, dynamic>);
      }
    } else {
      List<Activity> logs = await _sqlite.getActivitiesForUser(-1);
      for (var log in logs) {
        if (log.date == todayStr) {
          activities.add({
            'name': log.type,
            'duration': log.durationMinutes,
            'calories': log.calories,
            // Renk ve icon bilgisi DB'de yoksa UI tarafında eşleşmeli
          });
        }
      }
    }
    return activities;
  }

  Future<void> addActivity(String name, int duration, int calories) async {
    String todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (_isLoggedIn) {
      await _db.collection('users').doc(_uid).collection('activities').add({
        'date': todayStr,
        'type': name,
        'duration_minutes': duration,
        'calories': calories,
        'distance_km': 0.0,
        'steps': 0
      });
    } else {
      await _sqlite.createActivity(Activity(
        userId: -1,
        date: todayStr,
        type: name,
        durationMinutes: duration,
        calories: calories,
        distanceKm: 0,
        steps: 0,
      ));
    }
  }
}
