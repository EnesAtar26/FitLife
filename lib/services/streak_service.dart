import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_6/services/session_manager.dart';

class StreakService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  Future<Map<String, dynamic>> checkAndUpdateStreak() async {
    DateTime now = DateTime.now();
    // Saati sıfırla, sadece tarihi al (Bugün gece 00:00)
    DateTime today = DateTime(now.year, now.month, now.day); 

    DateTime? lastLoginDate;
    int currentStreak = 0;

    // 1. MEVCUT VERİYİ ÇEK (Online ise Firebase, Offline ise SessionManager)
    if (uid != null) {
      // --- ONLINE ---
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentStreak = data['streakCount'] ?? 0;
        Timestamp? ts = data['lastLogin'];
        if (ts != null) {
          DateTime d = ts.toDate();
          lastLoginDate = DateTime(d.year, d.month, d.day);
        }
      }
    } else {
      // --- OFFLINE ---
      final localData = await SessionManager.getStreakData();
      currentStreak = localData['count'];
      DateTime? d = localData['lastLogin'];
      if (d != null) {
        lastLoginDate = DateTime(d.year, d.month, d.day);
      }
    }

    // 2. HESAPLAMA
    bool hasIncreased = false;
    bool shouldUpdate = false;

    if (lastLoginDate == null) {
      // İlk giriş
      currentStreak = 1;
      hasIncreased = true;
      shouldUpdate = true;
    } else {
      // Bugün ile son giriş arasındaki fark
      int difference = today.difference(lastLoginDate).inDays;

      if (difference == 1) {
        // Dün girmiş, seri devam ediyor
        currentStreak++;
        hasIncreased = true;
        shouldUpdate = true;
      } else if (difference > 1) {
        // Gün kaçırmış, seri sıfırlandı
        currentStreak = 1;
        hasIncreased = false; // Sıfırlandığı için artış sayılmaz
        shouldUpdate = true;
      } else if (difference == 0) {
        // Bugün zaten girmiş, bir şey yapma
        shouldUpdate = false;
      }
    }

    // 3. VERİTABANINI GÜNCELLE (Eğer değişim varsa)
    if (shouldUpdate) {
      if (uid != null) {
        // Online Kayıt
        await _db.collection('users').doc(uid).update({
          'lastLogin': Timestamp.fromDate(today),
          'streakCount': currentStreak,
        });
      } else {
        // Offline Kayıt
        await SessionManager.saveStreak(today, currentStreak);
      }
    }

    return {
      'streak': currentStreak,
      'increased': hasIncreased, // Sadece seri arttıysa true döner
    };
  }
}