import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_application_6/models/activity_model.dart';
import 'package:flutter_application_6/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _userIdKey = 'logged_in_user_id';

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  static const _offlineUserKey = "offline_user_data";

  static Future<void> saveOfflineUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toMap());
    await prefs.setString(_offlineUserKey, userJson);
  }

  static Future<User?> getOfflineUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_offlineUserKey);
    if (userJson == null) {
      debugPrint("offline kullanıcı session null geldi");
      return null;
    }

    try {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      return User.fromMap(userMap);
    } catch (e) {
      debugPrint("offline kullanıcı session dönüştüremedi: $e");
      return null;
    }
  }

  static Future<void> clearOfflineUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineUserKey);
  }

  static const _activityMapKey="offline_activity_map";

  static Future<void> saveActivityMap(Map<DateTime, List<Activity?>> activityMap) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Map'i JSON uyumlu hale getir (Key: String, Value: List<Map>)
    Map<String, dynamic> jsonCompatibleMap = activityMap.map((dateKey, activityList) {
      // DateTime anahtarını String'e çevir
      String dateString = dateKey.toIso8601String();
      
      // Activity listesini Map listesine çevir (null kontrolü ile)
      List<Map<String, dynamic>?> mappedList = activityList
          .map((activity) => activity?.toMap())
          .toList();
          
      return MapEntry(dateString, mappedList);
    });

    // 2. Tüm yapıyı String'e sıkıştır
    String jsonString = jsonEncode(jsonCompatibleMap);
    
    // 3. Kaydet
    await prefs.setString(_activityMapKey, jsonString);
  }

  static Future<Map<DateTime, List<Activity?>>> getActivityMap() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_activityMapKey);

    if (jsonString == null) return {};

    try {
      // 1. String'i ham Map'e çevir
      Map<String, dynamic> decodedMap = jsonDecode(jsonString);

      // 2. Ham veriyi asıl türüne (DateTime, Activity) dönüştür
      Map<DateTime, List<Activity?>> finalMap = decodedMap.map((dateString, listDynamic) {
        
        // String -> DateTime
        DateTime dateKey = DateTime.parse(dateString);
        
        // List<dynamic> -> List<Activity?>
        List<dynamic> rawList = listDynamic as List;
        List<Activity?> activityList = rawList.map((item) {
          if (item == null) return null;
          return Activity.fromMap(item as Map<String, dynamic>);
        }).toList();

        return MapEntry(dateKey, activityList);
      });

      return finalMap;
    } catch (e) {
      debugPrint("Map Çevirme Hatası: $e");
      return {};
    }
  }

  static const _sleepDataKey = 'sleep_data_log';

  // --- UYKU VERİSİ KAYDET (Tarih: Saat) ---
  static Future<void> saveSleepLog(Map<String, double> sleepMap) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(sleepMap);
    await prefs.setString(_sleepDataKey, jsonString);
  }

  // --- UYKU VERİSİ OKU ---
  static Future<Map<String, double>> getSleepLog() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_sleepDataKey);
    
    if (jsonString == null) return {};

    try {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      // Double'a çevirerek map'le (JSON'dan dynamic gelebilir)
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return {};
    }
  }

  static const _waterDataKey = 'water_data_log';
  static const _waterGoalKey = 'water_daily_goal';

  // Su Logunu Kaydet
  static Future<void> saveWaterLog(Map<String, int> waterMap) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(waterMap);
    await prefs.setString(_waterDataKey, jsonString);
  }

  // Su Logunu Oku
  static Future<Map<String, int>> getWaterLog() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_waterDataKey);
    if (jsonString == null) return {};
    try {
      Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (e) {
      return {};
    }
  }

  // Hedefi Kaydet
  static Future<void> saveWaterGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterGoalKey, goal);
  }

  // Hedefi Oku
  static Future<int> getWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_waterGoalKey) ?? 8; // Varsayılan 8
  }

  static const _foodLogKey = 'daily_food_list';
  static const _foodDateKey = 'daily_food_date';

  // --- YEMEK LİSTESİNİ KAYDET ---
  static Future<void> saveFoodLog(List<Map<String, dynamic>> foods) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Listeyi JSON String'e çevir
    // (DateTime nesnelerini String'e çevirmemiz lazım)
    List<Map<String, dynamic>> jsonCompatibleList = foods.map((item) {
      return {
        'name': item['name'],
        'calories': item['calories'],
        'time': item['time'].toString(), // DateTime -> String
      };
    }).toList();

    String jsonString = jsonEncode(jsonCompatibleList);
    
    // 2. Veriyi ve Bugünün Tarihini Kaydet
    await prefs.setString(_foodLogKey, jsonString);
    
    DateTime now = DateTime.now();
    String todayStr = "${now.year}-${now.month}-${now.day}";
    await prefs.setString(_foodDateKey, todayStr);
  }

  // --- YEMEK LİSTESİNİ OKU (GÜN KONTROLÜ İLE) ---
  static Future<List<Map<String, dynamic>>> getFoodLog() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Tarih Kontrolü
    String? savedDate = prefs.getString(_foodDateKey);
    DateTime now = DateTime.now();
    String todayStr = "${now.year}-${now.month}-${now.day}";

    // Eğer tarih kayıtlı değilse veya eski bir tarihse -> BOŞ LİSTE DÖN (Sıfırla)
    if (savedDate != todayStr) {
      // İsteğe bağlı: Eski veriyi silebilirsiniz
      await prefs.remove(_foodLogKey); 
      return [];
    }

    // 2. Veriyi Çek
    String? jsonString = prefs.getString(_foodLogKey);
    if (jsonString == null) return [];

    try {
      List<dynamic> decoded = jsonDecode(jsonString);
      
      // JSON'dan geri List<Map>'e çevir
      return decoded.map((item) {
        return {
          'name': item['name'],
          'calories': item['calories'],
          'time': DateTime.parse(item['time']), // String -> DateTime
        };
      }).toList().cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // --- STREAK (SERİ) YÖNETİMİ ---
  static const _lastLoginKey = 'last_login_date';
  static const _streakCountKey = 'streak_count';

  // Streak Verisini Kaydet
  static Future<void> saveStreak(DateTime lastLogin, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginKey, lastLogin.toIso8601String());
    await prefs.setInt(_streakCountKey, count);
  }

  // Streak Verisini Oku
  static Future<Map<String, dynamic>> getStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    String? dateStr = prefs.getString(_lastLoginKey);
    int count = prefs.getInt(_streakCountKey) ?? 0;
    
    DateTime? lastLogin = dateStr != null ? DateTime.parse(dateStr) : null;
    
    return {'lastLogin': lastLogin, 'count': count};
  }

  static const _onboardingKey = 'is_onboarding_completed';

  // 1. Onboarding tamamlandı olarak işaretle
  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // 2. Onboarding tamamlanmış mı kontrol et
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
}
