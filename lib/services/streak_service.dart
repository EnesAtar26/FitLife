import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> checkAndUpdateStreak() async {
    bool isLoggedIn = _auth.currentUser != null;
    
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    DateTime? lastLoginDate;
    int currentStreak = 0;

    // --- VERİYİ ÇEK ---
    if (isLoggedIn) {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['lastLogin'] != null) {
          lastLoginDate = (data['lastLogin'] as Timestamp).toDate();
        }
        currentStreak = data['streakCount'] ?? 0;
      }
    } else {
      // Misafir Modu
      final prefs = await SharedPreferences.getInstance();
      String? dateStr = prefs.getString('lastLogin');
      if (dateStr != null) lastLoginDate = DateTime.parse(dateStr);
      currentStreak = prefs.getInt('streakCount') ?? 0;
    }

    // --- HESAPLAMA ---
    bool hasIncreased = false;
    
    if (lastLoginDate != null) {
      DateTime lastDateOnly = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
      int difference = today.difference(lastDateOnly).inDays;

      if (difference == 1) {
        currentStreak++; // Dün girmiş, seri arttı
        hasIncreased = true;
      } else if (difference > 1) {
        currentStreak = 1; // Gün kaçırmış, sıfırlandı
        hasIncreased = false;
      } else if (difference == 0) {
        // Bugün zaten girmiş, değişiklik yok
        return {'streak': currentStreak, 'increased': false};
      }
    } else {
      currentStreak = 1; // İlk giriş
      hasIncreased = true;
    }

    // --- VERİYİ KAYDET ---
    if (isLoggedIn) {
      await _db.collection('users').doc(_auth.currentUser!.uid).update({
        'lastLogin': Timestamp.fromDate(today),
        'streakCount': currentStreak,
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastLogin', today.toIso8601String());
      await prefs.setInt('streakCount', currentStreak);
    }

    return {
      'streak': currentStreak,
      'increased': hasIncreased
    };
  }
}