import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // DÜZELTME 1: Dönüş tipi 'Future<void>' yerine 'Future<Map<String, dynamic>>' yapıldı
  Future<Map<String, dynamic>> checkAndUpdateStreak() async {
    // Kullanıcı yoksa boş değer dön
    if (uid == null) return {'streak': 0, 'increased': false};

    DocumentReference userRef = _db.collection('users').doc(uid);
    DocumentSnapshot doc = await userRef.get();

    if (!doc.exists) return {'streak': 0, 'increased': false};

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    // Verileri al
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    Timestamp? lastLoginTs = data?['lastLogin'];
    int currentStreak = data?['streakCount'] ?? 0;
    
    bool hasIncreased = false; 

    if (lastLoginTs != null) {
      DateTime lastLogin = lastLoginTs.toDate();
      DateTime lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);

      int difference = today.difference(lastLoginDate).inDays;

      if (difference == 1) {
        // Seri devam ediyor
        currentStreak++;
        hasIncreased = true; 
      } else if (difference > 1) {
        // Gün kaçmış, sıfırlandı
        currentStreak = 1;
        hasIncreased = false;
      } else if (difference == 0) {
        // Bugün zaten girilmiş
        return {'streak': currentStreak, 'increased': false};
      }
    } else {
      // İlk giriş
      currentStreak = 1;
      hasIncreased = true; 
    }

    // Veritabanını güncelle
    await userRef.update({
      'lastLogin': Timestamp.fromDate(today),
      'streakCount': currentStreak,
    });
    
    // DÜZELTME 2: Hesaplanan sonucu UI tarafına döndürüyoruz
    return {
      'streak': currentStreak,
      'increased': hasIncreased
    };
  }
}