import 'dart:io'; // Platform kontrolü için şart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';

// Kendi servis ve ekranlarınızın importları
import 'package:flutter_application_6/services/streak_service.dart'; 
import 'calorie_camera_screen.dart';
import 'activity_detail_screen.dart';
import 'sleep_tracker_screen.dart';
import 'profile_screen.dart';
import 'water_screen.dart';
import "package:flutter_application_6/services/user_data_service.dart";

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Sağlık Verileri
  int _stepCount = 0;
  double _sleepHours = 7.5; // Varsayılan
  final Health health = Health();

  // Streak Verisi
  int _streakCount = 0;
  final StreakService _streakService = StreakService();

  // Kalori Grafiği Verileri
  int _dailyCalorieGoal = 2000; // Varsayılan, Firebase'den güncellenecek
  // Haftalık veriler (Pzt - Paz). Gerçekte veritabanından çekilmeli.
  List<double> _weeklyCalories = [1600, 1800, 1550, 1900, 2100, 1700, 2000];

  // Ekran Listesi
  late final List<Widget> _screens = [
    _buildDashboard(context), // 0: Dashboard
    const SleepTrackerScreen(), // 1: Uyku
    const ActivityDetailScreen(), // 2: Aktivite
    const WaterScreen(),          // 3: Su
    const FoodAnalysisScreen(),   // 4: Yemek
    const ProfileScreen(),        // 5: Profil
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndFetchData(); // Sağlık verilerini çek
    _checkStreak(); // Seriyi kontrol et
    _fetchUserData(); // Hedef kaloriyi çek
  }

  // --- 1. FIREBASE VERİ ÇEKME ---
  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          // Eğer veritabanında varsa çek, yoksa varsayılanda kal
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('dailyCalorieGoal')) {
            _dailyCalorieGoal = (data['dailyCalorieGoal'] as num).toInt();
          }
        });
      }
    } catch (e) {
      debugPrint("Kullanıcı verisi çekme hatası: $e");
    }
  }

  // --- 2. STREAK (SERİ) MANTIĞI ---
  Future<void> _checkStreak() async {
    try {
      // Servisten sonucu al: { 'streak': 5, 'increased': true }
      Map<String, dynamic> result = await _streakService.checkAndUpdateStreak();

      int newStreak = result['streak'];
      bool isIncreased = result['increased'];

      setState(() {
        _streakCount = newStreak;
      });

      // Eğer seri bugün arttıysa kutlama yap
      if (isIncreased && mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          _showStreakCelebration(context, newStreak);
        });
      }
    } catch (e) {
      debugPrint("Streak hatası: $e");
    }
  }

  // --- 3. HEALTH (SAĞLIK) VERİLERİ ---
  
  // Platforma göre uyku veri tipini seç
  HealthDataType get _sleepType => Platform.isAndroid
      ? HealthDataType.SLEEP_ASLEEP   // Android (Health Connect)
      : HealthDataType.SLEEP_IN_BED;  // iOS (HealthKit)

  Future<void> _requestPermissionsAndFetchData() async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        _sleepType, 
      ];

      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      bool requested = await health.requestAuthorization(types, permissions: permissions);

      if (requested) {
        await _fetchHealthData();
      }
    } catch (e) {
      debugPrint('İzin Hatası: $e');
    }
  }

  Future<void> _fetchHealthData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfYesterday = DateTime(now.year, now.month, now.day - 1);

      // Verileri çek
      List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
        startTime: startOfDay, endTime: now, types: [HealthDataType.STEPS],
      );
      
      List<HealthDataPoint> sleepData = await health.getHealthDataFromTypes(
        startTime: startOfYesterday, endTime: startOfDay, types: [_sleepType],
      );

      // Hesapla
      int totalSteps = 0;
      double totalSleepMinutes = 0;

      for (var data in stepsData) {
        if (data.value is NumericHealthValue) {
          totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }

      for (var data in sleepData) {
        if (data.value is NumericHealthValue) {
          totalSleepMinutes += (data.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      setState(() {
        _stepCount = totalSteps;
        if (totalSleepMinutes > 0) {
          _sleepHours = totalSleepMinutes / 60;
        }
      });
    } catch (e) {
      debugPrint('Veri çekme hatası: $e');
    }
  }

  // --- 4. DİYALOGLAR (POP-UP) ---

  // Hedef Kalori Düzenleme
  void _showEditGoalDialog() {
    TextEditingController controller = TextEditingController(text: _dailyCalorieGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Hedefi Düzenle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Hedef (kcal)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                int newGoal = int.tryParse(controller.text) ?? _dailyCalorieGoal;
                setState(() => _dailyCalorieGoal = newGoal);
                
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({'dailyCalorieGoal': newGoal});
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
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    TextEditingController controller = TextEditingController(text: _weeklyCalories[index].toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${days[index]} Verisi'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Alınan Kalori', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                double newVal = double.tryParse(controller.text) ?? _weeklyCalories[index];
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
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ÜST BİLGİ & STREAK
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Günaydın, Ayşe ☀️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                      const SizedBox(height: 4),
                      Text('Bugün harika görünüyorsun!', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  // Streak Rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                        const SizedBox(width: 4),
                        Text('$_streakCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/profile'),
                    child: CircleAvatar(backgroundColor: Colors.green[50], child: Icon(Icons.person, color: color)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            
            // ADIM SAYACI
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 180, height: 180,
                        child: CircularProgressIndicator(
                          value: (_stepCount / 10000).clamp(0.0, 1.0),
                          strokeWidth: 12,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_stepCount', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.grey[900])),
                      Text('Adım', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 18),
            
            // GRID MENÜ & GRAFİK
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 12, crossAxisSpacing: 12,
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatCard(title: 'Kalori', value: '1,840 kcal', icon: Icons.local_fire_department, color: Colors.orange),
                        _StatCard(title: 'Su', value: '6/8 bardak', icon: Icons.water_drop, color: Colors.blue, onTap: () => setState(() => _selectedIndex = 3)),
                        _StatCard(title: 'Uyku', value: '${_sleepHours.toStringAsFixed(1)} sa', icon: Icons.bedtime, color: Colors.purple, onTap: () => setState(() => _selectedIndex = 1)),
                        _StatCard(title: 'Aktivite', value: '45 dk koşu', icon: Icons.directions_run, color: Colors.green, onTap: () => setState(() => _selectedIndex = 2)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // GRAFİK KARTI
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık ve Düzenle Butonu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bu Haftanın Kalorisi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              InkWell(
                                onTap: _showEditGoalDialog,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100], borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 14, color: Colors.grey[700]),
                                      const SizedBox(width: 4),
                                      Text("Hedef: $_dailyCalorieGoal", style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // GRAFİK
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                barTouchData: barTouchData,
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: getTitles, reservedSize: 30)),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(show: false),
                                extraLinesData: ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(
                                      y: _dailyCalorieGoal.toDouble(),
                                      color: Colors.green.withValues(alpha: 0.5),
                                      strokeWidth: 2,
                                      dashArray: [5, 5],
                                      label: HorizontalLineLabel(show: true, labelResolver: (line) => "Hedef", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                barGroups: _getWeeklyCalorieData(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        return BarTooltipItem('${rod.toY.toInt()}\n(Düzenle)', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
      },
    ),
    touchCallback: (FlTouchEvent event, response) {
      if (event is FlTapUpEvent && response?.spot != null) {
        _showEditDayCalorieDialog(response!.spot!.touchedBarGroupIndex);
      }
    },
  );

  Widget getTitles(double value, TitleMeta meta) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return SideTitleWidget(meta: meta, child: Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 12)));
  }

  List<BarChartGroupData> _getWeeklyCalorieData() {
    return List.generate(7, (index) {
      final val = _weeklyCalories[index];
      final isMet = val >= _dailyCalorieGoal;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: val,
            color: isMet ? Colors.green : Colors.orange,
            width: 12,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(show: true, toY: _dailyCalorieGoal * 1.3, color: Colors.grey.withValues(alpha: 0.05)),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -4))]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[400],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.bedtime_outlined), activeIcon: Icon(Icons.bedtime), label: 'Uyku'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_run_outlined), activeIcon: Icon(Icons.directions_run), label: 'Aktivite'),
            BottomNavigationBarItem(icon: Icon(Icons.water_drop_outlined), activeIcon: Icon(Icons.water_drop), label: 'Su'),
            BottomNavigationBarItem(icon: Icon(Icons.food_bank_outlined), activeIcon: Icon(Icons.food_bank), label: 'Yemek'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// İstatistik Kartı Widget'ı
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.15))),
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Global Fonksiyon: Kutlama Diyaloğu
void _showStreakCelebration(BuildContext context, int days) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent, elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.local_fire_department, size: 60, color: Colors.orange)),
              const SizedBox(height: 20),
              Text("$days Günlük Seri! 🔥", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("İnanılmaz gidiyorsun! Disiplinini koruduğun için tebrikler.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Devam Et", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    },
  );
}