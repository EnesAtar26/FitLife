// Platform kontrolü için şart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_6/database/firebase_database.dart';
import 'package:flutter_application_6/services/session_manager.dart';
import 'package:health/health.dart';

// Kendi servis ve ekranlarınızın importları
import 'package:flutter_application_6/services/streak_service.dart';

import 'calorie_camera_screen.dart';
import 'activity_detail_screen.dart';
import 'sleep_tracker_screen.dart';
import 'profile_screen.dart';
import 'water_screen.dart';
import 'package:flutter_application_6/models/user_model.dart' as local_user;
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  final bool isOffline;
  const HomeScreen({super.key, this.isOffline = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _userName = "";

  // Sağlık Verileri
  int _stepCount = 0;
  int _stepGoal = 10055;
  double _sleepHours = -1; // Varsayılan
  final Health health = Health();

  int _stepBurnedCalories = 0;

  // Streak Verisi
  int _streakCount = 0;

  // Kalori Grafiği Verileri
  int _dailyCalorieGoal = 2000; // Varsayılan, Firebase'den güncellenecek
  int _todaysCalorie = -1;
  int _todaysWater = -1;
  List<double> _weeklyCalories = List.filled(7, 0.0);

  int _lastActivityDurationMinutes = 45;
  String _lastActivityName = "koşu";

  Future<void> _refreshAllData() async {
    await _fetchUserData(); // İsim ve Hedefleri çek
    await _requestPermissionsAndFetchData(); // Sadece Adım (Health API)
    await _fetchWeeklyCalories(); // Kalori hesapla
    await _fetchTodaysSleep(); // Uyku
    await _fetchTodaysWater(); // Su
    await _fetchLastActivity(); // Son Aktivite
    await _checkStreak(); // Streak
  }

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndFetchData(); // Sağlık verilerini çek
    _checkStreak(); // Seriyi kontrol et
    _fetchUserData(); // Hedef kaloriyi çek
    _fetchWeeklyCalories();
    _fetchTodaysSleep();
    _fetchTodaysWater();
    _fetchLastActivity();
    _fetchHealthData();
    _initAppLogic();
  }

  Future<void> _initAppLogic() async {
    // 1. İzinleri ve Verileri Al (Bildirim, Alarm, Sağlık)
    await _requestPermissionsAndFetchData();

    // 2. Gerçek Günlük Hatırlatıcıları Kur (14:00 ve 20:00)
    await NotificationService().setupDailyReminders();

    // 3. 🚀 OTOMATİK TEST (10 SANİYE SONRA)
    // Uygulama her açıldığında 10 saniye sonrasına test alarmı kurar.
    // Test başarılı olduktan sonra bu satırı silebilirsiniz.
    await NotificationService().scheduleAllSimulations();
  }

  Future<void> _fetchLastActivity() async {
    try {
      final activityMap = await SessionManager.getActivityMap();

      // Tarihleri yeniden eskiye sırala (Bugün -> Dün -> ...)
      final sortedDates = activityMap.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      for (var date in sortedDates) {
        final activities = activityMap[date];

        // Eğer o gün aktivite varsa ve liste boş değilse
        if (activities != null && activities.isNotEmpty) {
          // Listenin son elemanı en son eklenendir
          final lastActivity = activities.last;

          if (lastActivity != null) {
            if (mounted) {
              setState(() {
                _lastActivityDurationMinutes = lastActivity.durationMinutes;
                _lastActivityName = lastActivity.type;
              });
            }
            return; // Son aktiviteyi bulduk, döngüyü bitir.
          }
        }
      }

      // Hiç aktivite bulunamazsa
      if (mounted) {
        setState(() {
          _lastActivityDurationMinutes = 0;
          _lastActivityName = "Yok";
        });
      }
    } catch (e) {
      debugPrint("Son aktivite hatası: $e");
    }
  }

  // Aktivite tipine göre İkon ve Renk getiren yardımcı fonksiyon
  Map<String, dynamic> _getActivityStyle(String type) {
    switch (type) {
      case 'Koşu':
        return {'icon': Icons.directions_run, 'color': Colors.orange};
      case 'Yürüyüş':
        return {'icon': Icons.directions_walk, 'color': Colors.blue};
      case 'Yüzme':
        return {'icon': Icons.pool, 'color': Colors.cyan};
      case 'Bisiklet':
        return {'icon': Icons.two_wheeler, 'color': Colors.green};
      case 'Yoga':
        return {'icon': Icons.self_improvement, 'color': Colors.purple};
      case 'Basketbol':
        return {'icon': Icons.sports_basketball, 'color': Colors.amber};
      default:
        return {'icon': Icons.fitness_center, 'color': Colors.grey};
    }
  }

  Future<void> _fetchWeeklyCalories() async {
    try {
      final activityMap = await SessionManager.getActivityMap();

      List<double> newWeeklyData = [];
      DateTime now = DateTime.now();

      // 1. Son 7 günü hesapla
      for (int i = 6; i >= 0; i--) {
        DateTime targetDate = now.subtract(Duration(days: i));
        double dailyTotal = 0;

        // Akıllı Eşleşme (Saat farkını yoksay)
        for (var entry in activityMap.entries) {
          DateTime recordedDate = entry.key;
          bool isSameDay =
              recordedDate.year == targetDate.year &&
              recordedDate.month == targetDate.month &&
              recordedDate.day == targetDate.day;

          if (isSameDay) {
            final activities = entry.value;
            for (var activity in activities) {
              if (activity != null) {
                dailyTotal += activity.calories;
              }
            }
          }
        }
        newWeeklyData.add(dailyTotal);
      }

      // 2. UI GÜNCELLEME (Burası Çok Önemli)
      if (mounted) {
        setState(() {
          // A) Grafiği güncelle
          _weeklyCalories = newWeeklyData;

          // B) "BUGÜN" KARTINI GÜNCELLE (Eksik olan parça buydu!)
          // Listenin son elemanı (index 6) bugündür.
          if (widget.isOffline) {
            _todaysCalorie = newWeeklyData.last.toInt();
          }
        });
        debugPrint(
          "✅ Grafik ve Kart Verisi Güncellendi. Bugün: $_todaysCalorie kcal",
        );
      }
    } catch (e) {
      debugPrint("❌ Veri hesaplama hatası: $e");
    }
  }

  // --- 1. VERİ ÇEKME (ONLINE + OFFLINE - GÜNCELLENDİ) ---
  Future<void> _fetchUserData() async {
    // A) ÇEVRİMDIŞI MOD
    if (widget.isOffline) {
      try {
        local_user.User? user = await SessionManager.getOfflineUser();

        if (user != null) {
          if (mounted) {
            setState(() {
              // İsim boş gelirse "Kullanıcı" yazsın
              _userName = (user.firstName.isNotEmpty)
                  ? user.firstName
                  : "Kullanıcı";

              // Hedef kalori 0 veya null ise 2000 olsun
              _dailyCalorieGoal =
                  (user.dailyCalorieGoal != null && user.dailyCalorieGoal! > 0)
                  ? user.dailyCalorieGoal!
                  : 2000;

              _stepGoal = user.dailyStepGoal ?? 10000;
            });
          }
        }
      } catch (e) {
        debugPrint("Offline User Hatası: $e");
      }
      return;
    }

    // B) ONLINE MOD (FIREBASE)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint(
        "❌ HATA: Firebase kullanıcısı (currentUser) null! Oturum açılmamış olabilir.",
      );
      return;
    }

    final uid = currentUser.uid;
    debugPrint("--- Online modda veri çekiliyor. UID: $uid ---");

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        debugPrint("✅ Firebase'den ham veri geldi: $data");

        String fetchedName = "";

        // İsim alanını farklı anahtarlarla kontrol et (Büyük/Küçük harf duyarlılığı için)
        if (data.containsKey('Name')) {
          fetchedName = data['Name'];
        } else if (currentUser.displayName != null &&
            currentUser.displayName!.isNotEmpty) {
          fetchedName = currentUser.displayName!;
        }

        if (mounted) {
          setState(() {
            // Eğer isim bulunduysa güncelle
            if (fetchedName.isNotEmpty) {
              _userName = fetchedName;
            }

            // Kalori hedefini güncelle
            if (data.containsKey('dailyCalorieGoal')) {
              _dailyCalorieGoal = (data['dailyCalorieGoal'] as num).toInt();
            }
          });
        }
      } else {
        debugPrint(
          "⚠️ Firebase'de bu UID ($uid) için 'users' koleksiyonunda doküman YOK!",
        );
      }
    } catch (e) {
      debugPrint("❌ Firebase Veri Çekme Hatası: $e");
    }
  }

  // --- 2. STREAK (SERİ) MANTIĞI ---
  Future<void> _checkStreak() async {
    StreakService streakService = StreakService();
    // Hesaplamayı yap
    Map<String, dynamic> result = await streakService.checkAndUpdateStreak();

    if (mounted) {
      setState(() {
        _streakCount = result['streak'];
      });

      // KUTLAMA MANTIĞI
      // Eğer seri arttıysa (increased == true) VE Seri 2 veya daha fazlaysa
      if (result['increased'] == true && _streakCount >= 2) {
        _showCelebrationDialog(_streakCount);
      }
    }
  }

  void _showCelebrationDialog(int days) {
    showDialog(
      context: context,
      barrierDismissible: false, // Dışarı tıklayınca kapanmasın
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🔥",
                style: TextStyle(fontSize: 60),
              ), // Büyük Ateş Emojisi
              const SizedBox(height: 16),
              const Text(
                "Tebrikler!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$days gündür seriyi bozmuyorsun!\nHarika gidiyorsun.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Devam Et"),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. ADIM VE KALORİ VERİLERİ ---
  Future<void> _requestPermissionsAndFetchData() async {
    debugPrint("🔍 [DEBUG] Adım izni isteme süreci başlatılıyor...");

    try {
      final types = [HealthDataType.STEPS];
      final permissions = [HealthDataAccess.READ];

      // İzin istemeden önce kontrol
      bool requested = await health.requestAuthorization(
        types,
        permissions: permissions,
      );

      debugPrint("🔍 [DEBUG] İzin penceresi sonucu: $requested");

      if (requested) {
        debugPrint(
          "✅ [DEBUG] İzin verildi veya zaten var. Veri çekmeye gidiliyor...",
        );
        await _fetchHealthData();
      } else {
        debugPrint("⚠️ [DEBUG] Kullanıcı izni reddetti veya izin alınamadı.");
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] İzin Hatası: $e');
    }
  }

  Future<void> _fetchHealthData() async {
    debugPrint("👣 [DEBUG] _fetchHealthData fonksiyonuna girildi.");

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      debugPrint("⏳ [DEBUG] Sorgu Zaman Aralığı: $startOfDay  --->  $now");

      // 1. ADIMLARI TELEFONDAN ÇEK (OFFLINE/ONLINE FARK ETMEZ)
      List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      debugPrint(
        "📦 [DEBUG] Health API'den dönen veri parçası sayısı: ${stepsData.length}",
      );

      // Adımları topla
      int totalSteps = 0;
      for (var data in stepsData) {
        if (data.value is NumericHealthValue) {
          int val = (data.value as NumericHealthValue).numericValue.toInt();
          totalSteps += val;
        }
      }

      // Kalori Hesabı (Formül: Adım * 0.045)
      int calculatedCalories = (totalSteps * 0.045).toInt();
      debugPrint("∑ [DEBUG] Hesaplanan TOPLAM ADIM: $totalSteps");

      // 2. FIREBASE HEDEF VERİLERİNİ ÇEK (SADECE ONLINE İSE)
      // Bu kısmı try-catch içine alıyoruz ki hata verirse adımları ekrana basmayı engellemesin.
      if (!widget.isOffline) {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final uid = currentUser.uid;
            // Veritabanı yolu ve koleksiyon isimlerinin doğruluğundan emin olun
            DocumentSnapshot mdoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection("misc") // "misc" koleksiyonun var mı?
                .doc(uid) // Doküman ID'si uid mi?
                .get();

            if (mdoc.exists && mdoc.data() != null) {
              var data = mdoc.data() as Map<String, dynamic>;
              // Verileri güncelle (setState içinde değil, aşağıda toplu yapacağız)
              if (data.containsKey('CaloryTarget')) {
                _dailyCalorieGoal = (data['CaloryTarget'] as num).toInt();
              }
              if (data.containsKey('StepsTarget')) {
                _stepGoal = (data['StepsTarget'] as num).toInt();
              }
            }
          }
        } catch (firebaseError) {
          // Firebase hatası olursa sadece log düş, fonksiyonu durdurma!
          debugPrint(
            "⚠️ [UYARI] Firebase verisi çekilemedi (Ama adımlar gösterilecek): $firebaseError",
          );
        }
      } else {
        // OFFLINE İSE: Hedefleri yerel veritabanından (SessionManager) çekebilirsin
        // Şimdilik mevcut değerleri koruyoruz.
        debugPrint("ℹ️ [INFO] Offline mod: Firebase sorgusu atlandı.");
      }

      // 3. EKRANI GÜNCELLE (HER DURUMDA ÇALIŞIR)
      if (mounted) {
        setState(() {
          _stepCount = totalSteps;
          _stepBurnedCalories = calculatedCalories;
          // _stepGoal ve _dailyCalorieGoal yukarıda güncellendiyse onlar da yansır
        });
      }

      debugPrint("✅ [DEBUG] UI güncellendi (_stepCount: $_stepCount)");
    } catch (e) {
      // Burası sadece Health API (Adım sensörü) hatası verirse çalışır
      debugPrint('❌ [DEBUG] Kritik Hata (Adımlar çekilemedi): $e');
    }
  }

  // --- BUGÜNÜN UYKU VERİSİNİ ÇEK ---
  Future<void> _fetchTodaysSleep() async {
    try {
      // 1. Kayıtlı tüm uyku verilerini al
      final sleepMap = await SessionManager.getSleepLog();

      // 2. Bugünün tarihini anahtar formatına çevir (YYYY-MM-DD)
      final now = DateTime.now();
      String todayKey =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 3. Veriyi çek, yoksa 0.0 yap
      double sleepVal = sleepMap[todayKey] ?? 0.0;

      if (mounted) {
        setState(() {
          _sleepHours = sleepVal;
        });
        debugPrint("Uyku Verisi Güncellendi: $_sleepHours saat");
      }
    } catch (e) {
      debugPrint("Uyku verisi çekme hatası: $e");
    }
  }

  // --- BUGÜNÜN SU MİKTARINI ÇEK ---
  Future<void> _fetchTodaysWater() async {
    try {
      final waterMap = await SessionManager.getWaterLog();
      final now = DateTime.now();
      String key =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      int todayVal = waterMap[key] ?? 0;

      if (mounted) {
        setState(() {
          _todaysWater = todayVal;
        });
      }
    } catch (e) {
      debugPrint("Su verisi çekme hatası: $e");
    }
  }

  // --- 4. DİYALOGLAR (POP-UP) ---

  void _showStepGoalDialog() {
    TextEditingController controller = TextEditingController(
      text: _stepGoal.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adım Hedefi"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Yeni Hedef",
            border: OutlineInputBorder(),
            suffixText: "adım",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              int? newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                setState(() => _stepGoal = newGoal);
                final fireUser = await FirebaseAuth.instance
                    .authStateChanges()
                    .firstWhere((fireUser) => fireUser != null);

                final user_id = fireUser!.uid;
                await FirebaseDatabaseService(uid: user_id).updateMiscInfo(
                  _stepCount,
                  newGoal,
                  _streakCount,
                  _dailyCalorieGoal,
                );

                // Eğer Offline kullanıcı ise veriyi kaydet
                final user = await SessionManager.getOfflineUser();
                if (user != null) {
                  await SessionManager.saveOfflineUser(
                    user.copyWith(dailyStepGoal: newGoal),
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // Hedef Kalori Düzenleme
  void _showEditGoalDialog() {
    TextEditingController controller = TextEditingController(
      text: _dailyCalorieGoal.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Hedefi Düzenle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hedef (kcal)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                int newGoal =
                    int.tryParse(controller.text) ?? _dailyCalorieGoal;
                setState(() => _dailyCalorieGoal = newGoal);

                if (widget.isOffline) {
                  // --- SQLITE GÜNCELLEME ---
                  local_user.User? existingUser =
                      await SessionManager.getOfflineUser();

                  if (existingUser != null) {
                    // Mevcut user nesnesini kopyalayıp sadece hedefi değiştiriyoruz
                    // Not: User modelinizde copyWith metodu yoksa, tüm alanları elle girmeniz gerekir.
                    // Aşağıdaki örnek, User modelinizi yeniden oluşturarak yapılmıştır:
                    local_user.User updatedUser = existingUser.copyWith(
                      dailyCalorieGoal: newGoal,
                    );
                    await SessionManager.saveOfflineUser(updatedUser);
                  }
                } else {
                  // --- FIREBASE GÜNCELLEME ---
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    final user = await FirebaseAuth.instance
                        .authStateChanges()
                        .firstWhere((user) => user != null);

                    final user_id = user!.uid;
                    await FirebaseDatabaseService(uid: user_id).updateMiscInfo(
                      _stepCount,
                      _stepGoal,
                      _streakCount,
                      newGoal,
                    );
                  }
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Grafik Üzerindeki Günü Düzenleme
  void _showEditDayCalorieDialog(int index) {
    TextEditingController controller = TextEditingController(
      text: _weeklyCalories[index].toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Veriyi değiştir"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Alınan Kalori',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                double newVal =
                    double.tryParse(controller.text) ?? _weeklyCalories[index];
                setState(() => _weeklyCalories[index] = newVal);
                Navigator.pop(context);
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  // --- 5. ARAYÜZ (UI) ---

  Widget _buildDashboard(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ÜST BİLGİ & STREAK
            topBar(color),
            const SizedBox(height: 18),

            // ADIM SAYACI
            stepCircle(color),
            const SizedBox(height: 18),

            // GRID MENÜ & GRAFİK
            quickInfoGrid(),
            const SizedBox(height: 18),

            // GRAFİK KARTI
            calorieGraph(),
          ],
        ),
      ),
    );
  }

  Widget quickInfoGrid() {
    final activityStyle = _getActivityStyle(_lastActivityName);
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard(
          title: 'Kalori',
          value:
              "${(_todaysCalorie != -1 ? _todaysCalorie : 0) + _stepBurnedCalories} kcal",
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
        _statCard(
          title: 'Su',
          value: '${_todaysWater != -1 ? _todaysWater : 6} bardak',
          icon: Icons.water_drop,
          color: Colors.blue,
          onTap: () => setState(() => _selectedIndex = 3),
        ),
        _statCard(
          title: 'Uyku',
          value: '${_sleepHours.toStringAsFixed(1)} sa',
          icon: Icons.bedtime,
          color: Colors.purple,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        _statCard(
          title: 'Son Aktivite',
          value: _lastActivityDurationMinutes > 0
              ? '$_lastActivityDurationMinutes dk $_lastActivityName'
              : 'Aktivite Yok',
          icon: activityStyle['icon'],
          color: activityStyle['color'],
          onTap: () => setState(() => _selectedIndex = 2),
        ),
      ],
    );
  }

  Container calorieGraph() {
    // 1. Grafiğin Y ekseni için maksimum değeri hesapla
    // Verilerdeki en büyük sayı ile Hedef Kalori'yi karşılaştırıp büyük olanı alıyoruz.
    double maxDataValue = _weeklyCalories.reduce(max);
    double maxY =
        max(maxDataValue, _dailyCalorieGoal.toDouble()) *
        1.2; // %20 boşluk bırak

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Hedef Göstergesi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son 7 Günlük Kalori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: _showEditGoalDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        "Hedef: $_dailyCalorieGoal",
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GRAFİK ALANI
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY, // <-- KRİTİK NOKTA: Ölçeği burası belirler
                barTouchData: barTouchData,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: getTitles,
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _dailyCalorieGoal.toDouble(),
                      color: Colors.green.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (line) => "Hedef",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                barGroups: _createWeeklyCalorieDataGraph(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Center stepCircle(Color color) {
    return Center(
      // Tıklayınca hedefi düzenle
      child: InkWell(
        onTap: _showStepGoalDialog,
        borderRadius: BorderRadius.circular(
          100,
        ), // Tıklama efekti yuvarlak olsun
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arka plan gölgeli daire
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    // Dinamik hedefe göre hesaplama
                    value: (_stepCount / _stepGoal).clamp(0.0, 1.0),
                    strokeWidth: 12,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),

            // Ortadaki Yazılar
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                // Mevcut Adım Sayısı
                Text(
                  '$_stepCount',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[900],
                    height: 1.0,
                  ),
                ),
                const Text("Adım"),
                // --- İSTEĞİN: Gri şekilde hedef yazısı ---
                Text(
                  'Hedef: $_stepGoal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                // Ufak bir ipucu (Opsiyonel, tıklanabildiğini belli eder)
                Icon(Icons.edit, size: 16, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Center topBar(Color color) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Günaydın ${_userName.isNotEmpty ? _userName : ""}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bugün harika görünüyorsun!',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          // Streak Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey, width: 2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_outlined,
                  color: Color.fromARGB(255, 251, 255, 0),
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_streakCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color.fromARGB(255, 251, 255, 0),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            //profil ikonu
            onTap: () => setState(() {
              _selectedIndex = 5;
            }),
            child: CircleAvatar(
              backgroundColor: Colors.green[50],
              child: Icon(Icons.person, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // Grafik Helperları
  BarTouchData get barTouchData => BarTouchData(
    enabled: true,
    touchTooltipData: BarTouchTooltipData(
      tooltipPadding: const EdgeInsets.all(8),
      tooltipMargin: 8,
      getTooltipColor: (group) => Colors.blueGrey,
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        return BarTooltipItem(
          '${rod.toY.toInt()}\n(Düzenle)',
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        );
      },
    ),
    touchCallback: (FlTouchEvent event, response) {
      if (event is FlTapUpEvent && response?.spot != null) {
        _showEditDayCalorieDialog(response!.spot!.touchedBarGroupIndex);
      }
    },
  );

  Widget getTitles(double value, TitleMeta meta) {
    final int index = value.toInt();
    if (index < 0 || index >= 7) return const SizedBox();

    DateTime date = DateTime.now().subtract(Duration(days: 6 - index));

    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    // DateTime.weekday 1(Pzt) ile 7(Paz) arası değer döner
    String dayName = days[date.weekday - 1];

    return SideTitleWidget(
      meta: meta,
      child: Text(
        dayName,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  List<BarChartGroupData> _createWeeklyCalorieDataGraph() {
    return List.generate(7, (index) {
      final val = _weeklyCalories[index];
      final isMet = val >= _dailyCalorieGoal;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: val,
            color: isMet ? Colors.green : Colors.green.withValues(alpha: 0.5),
            width: 12,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _dailyCalorieGoal * 1.3,
              color: Colors.grey.withValues(alpha: 0.05),
            ),
          ),
        ],
      );
    });
  }

  // YENİ EKLENECEK FONKSİYON
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(context); // Ana Ekran (Artık anlık güncellenir)
      case 1:
        return const SleepTrackerScreen();
      case 2:
        return ActivityDetailScreen(
          onBack: () => setState(() => _selectedIndex = 0),
        );
      case 3:
        return const WaterScreen();
      case 4:
        return const FoodAnalysisScreen();
      case 5:
        return ProfileScreen(isOffline: widget.isOffline);
      default:
        return _buildDashboard(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 0) {
              _fetchWeeklyCalories();
              _fetchUserData();
              _requestPermissionsAndFetchData();
              _fetchTodaysSleep();
              _fetchTodaysWater();
              _fetchLastActivity();
              _checkStreak();
              _fetchHealthData();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[400],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bedtime_outlined),
              activeIcon: Icon(Icons.bedtime),
              label: 'Uyku',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run_outlined),
              activeIcon: Icon(Icons.directions_run),
              label: 'Aktivite',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_outlined),
              activeIcon: Icon(Icons.water_drop),
              label: 'Su',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.food_bank_outlined),
              activeIcon: Icon(Icons.food_bank),
              label: 'Yemek',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// İstatistik Kartı Widget'ı
Widget _statCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ), // Padding biraz azaltıldı (daha fazla yer kalsın)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // İkon ve metinleri dikeyde ortala
        children: [
          // --- SOL KISIM: İKON ---
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(width: 12), // Ara boşluk
          // --- SAĞ KISIM: İÇERİK ---
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // İçerik kadar yer kapla, zorlama
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. BAŞLIK (Flexible ile sarmalandı)
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13, // Biraz küçültüldü
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 6), // Boşluğu azalttık
                // 2. DEĞER (Flexible ile sarmalandı)
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16, // Biraz küçültüldü ki sığsın
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                      height: 1.1, // Satır aralığı sıkılaştırıldı
                    ),
                    maxLines: 2, // 3 satır çok geliyorsa 2'ye düşürelim
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
