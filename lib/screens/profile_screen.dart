import 'package:flutter/material.dart';
import 'package:flutter_application_6/services/session_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_6/widgets/step_recommender_form.dart';
import 'package:health/health.dart'; // <--- 1. BU EKLENDİ

import 'settings_screen.dart';
import 'update_profile_info_screen.dart';
import 'reminder_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  final bool isOffline; 

  const ProfileScreen({super.key, this.isOffline = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Veriler
  String name = 'Kullanıcı';
  String subtitle = 'Bilgi Yok';

  // Kullanıcı bilgileri
  int? age;
  int? heightCm;
  int? weightKg;
  String? gender;

  // Anlık veriler
  int steps = 0;
  int calories = 0;
  int waterGlasses = 0;
  Duration sleep = const Duration(hours: 0, minutes: 0);

  // Hedefler
  int stepGoal = 10000;
  int waterGoal = 8;
  Duration sleepGoal = const Duration(hours: 8, minutes: 0);

  // Health Nesnesi
  final Health health = Health(); // <--- 2. BU EKLENDİ

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _fetchUserData(); 
    await _fetchDailyStats();
    await _fetchSteps(); // <--- 3. ADIM ÇEKME EKLENDİ
  }

  // --- YENİ: ADIMLARI ÇEKEN FONKSİYON ---
  Future<void> _fetchSteps() async {
    try {
      // İzinleri kontrol et (Zaten ana sayfada alındıysa sormaz)
      bool requested = await health.requestAuthorization([HealthDataType.STEPS]);

      if (requested) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);

        // Adımları Telefondan Çek
        List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
          startTime: startOfDay,
          endTime: now,
          types: [HealthDataType.STEPS],
        );

        // Topla
        int totalSteps = 0;
        for (var data in stepsData) {
          if (data.value is NumericHealthValue) {
            totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
          }
        }

        if (mounted) {
          setState(() {
            steps = totalSteps;
          });
        }
      }
    } catch (e) {
      debugPrint("Profil Ekranı Adım Hatası: $e");
    }
  }
  // ---------------------------------------

  Future<void> _fetchUserData() async {
    if (widget.isOffline) {
      final user = await SessionManager.getOfflineUser();
      if (user != null) {
        if (mounted) {
          setState(() {
            name = "${user.firstName} ${user.lastName}";
            subtitle = "Yaş: ${user.age ?? '-'} • ${user.gender ?? '-'}";
            age = user.age;
            heightCm = user.heightCm;
            weightKg = user.weightKg;
            gender = user.gender;
            stepGoal = user.dailyStepGoal ?? 10000;
            waterGoal = user.dailyWaterGoal ?? 8;
            int sleepMin = user.sleepGoalMinutes ?? 480;
            sleepGoal = Duration(hours: sleepMin ~/ 60, minutes: sleepMin % 60);
          });
        }
      }
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              name = "${data['Name'] ?? ''} ${data['Surname'] ?? ''}";
              subtitle =
                  "Yaş: ${data['Age'] ?? '-'} • ${data['Gender'] ?? '-'}";
              age = data['Age'] as int?;
              heightCm = data['heightCm'] as int?;
              weightKg = data['weightKg'] as int?;
              gender = data['Gender'] as String?;
              stepGoal = data['dailyStepGoal'] ?? 10000;
              waterGoal = data['dailyWaterGoal'] ?? 8;
              int sleepMin = data['sleepGoalMinutes'] ?? 480;
              sleepGoal = Duration(
                hours: sleepMin ~/ 60,
                minutes: sleepMin % 60,
              );
            });
          }
        }
      }
    }
  }

  Map<String, dynamic> get userData {
    return {
      'age': age ?? 25,
      'weight': weightKg?.toDouble() ?? 70.0,
      'height': heightCm?.toDouble() ?? 175.0,
      'gender': gender ?? 'male',
    };
  }

  Future<void> _fetchDailyStats() async {
    final now = DateTime.now();
    String dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final waterMap = await SessionManager.getWaterLog();
    int todayWater = waterMap[dateKey] ?? 0;

    final sleepMap = await SessionManager.getSleepLog();
    double sleepHoursVal = sleepMap[dateKey] ?? 0.0;
    int sHours = sleepHoursVal.toInt();
    int sMinutes = ((sleepHoursVal - sHours) * 60).toInt();

    final activityMap = await SessionManager.getActivityMap();
    double todayCal = 0;
    for (var entry in activityMap.entries) {
      if (entry.key.day == now.day &&
          entry.key.month == now.month &&
          entry.key.year == now.year) {
        for (var act in entry.value) {
          if (act != null) todayCal += act.calories;
        }
      }
    }

    if (mounted) {
      setState(() {
        waterGlasses = todayWater;
        sleep = Duration(hours: sHours, minutes: sMinutes);
        calories = todayCal.toInt();
      });
    }
  }

  void _openStepRecommender() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StepRecommenderForm(
          currentUserData: userData,
          onTargetUpdated: (newGoal) {
            setState(() {
              stepGoal = newGoal;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person,color: Colors.green[500]),
            SizedBox(width: 12),
            Text('Profil', style: TextStyle(fontSize: 24)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            isOffline: widget.isOffline,
                          ),
                        ),
                      ).then(
                        (_) => _loadAllData(),
                      );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: 18),
            _buildStepRecommenderCard(),
            const SizedBox(height: 18),
            _buildPrimaryStatsCard(),
            const SizedBox(height: 16),
            _buildSmallStatsGrid(),
            const SizedBox(height: 18),
            _buildGoalsCard(),
            const SizedBox(height: 18),
            _buildRemindersCard(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRecommenderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB39DDB), Color(0xFF9575CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9575CD).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openStepRecommender,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Akıllı Hedef Önerisi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("Sana özel adım hedefini hesaplamak için dokun!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: null,
          child: const Icon(Icons.person, size: 44, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateProfileInfoScreen(
                            isOffline: widget.isOffline,
                          ),
                        ),
                      ).then(
                        (_) => _loadAllData(),
                      ); 
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.green[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Bilgileri Güncelle',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildStepsCircle(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba, ${name.split(' ')[0]}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _tinyStat('Kalori', '$calories kcal'),
                      _tinyStat('Su', '$waterGlasses/$waterGoal brd'),
                      _tinyStat(
                        'Uyku',
                        '${sleep.inHours}s ${sleep.inMinutes % 60}dk',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCircle() {
    final percent = (stepGoal > 0) ? (steps / stepGoal).clamp(0.0, 1.0) : 0.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              steps.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Text(
              'Adım',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tinyStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSmallStatsGrid() {
    return Row(
      children: [
        Expanded(child: _miniCard('Aktivite', 'Özet', '$calories kcal')),
        const SizedBox(width: 12),
        Expanded(
          child: _miniCard('Su Takibi', '$waterGlasses/$waterGoal', 'Günlük'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniCard(
            'Uyku Takibi',
            '${sleep.inHours}h ${sleep.inMinutes % 60}m',
            'Hedef: ${sleepGoal.inHours}h',
          ),
        ),
      ],
    );
  }

  Widget _miniCard(String title, String big, String small) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(big, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              small,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hedefler',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _goalRow('Adım Hedefi', '$stepGoal'),
            const SizedBox(height: 8),
            _goalRow('Su Hedefi', '$waterGoal bardak'),
            const SizedBox(height: 8),
            _goalRow(
              'Uyku Hedefi',
              '${sleepGoal.inHours} sa ${sleepGoal.inMinutes > 0 ? "${sleepGoal.inMinutes} dk" : ""}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalRow(String name, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRemindersCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hatırlatıcılar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            //  SU HATIRLATICISI
            Row(
              children: [
                const Icon(Icons.notifications_none),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Su içme hatırlatıcısı\nHer 2 saatte bir'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ReminderEditScreen(title: 'Su Hatırlatıcısı'),
                      ),
                    );
                  },
                  child: const Text('Düzenle'),
                ),
              ],
            ),

            const Divider(),

            //  UYKU HATIRLATICISI
            Row(
              children: [
                const Icon(Icons.bedtime_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Uyku hatırlatıcısı\nHedef uyku saati'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReminderEditScreen(
                          title: 'Uyku Hatırlatıcısı',
                        ),
                      ),
                    );
                  },
                  child: const Text('Güncelle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}