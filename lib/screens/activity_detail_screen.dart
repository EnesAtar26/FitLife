import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_6/models/activity_model.dart';
import 'package:flutter_application_6/services/session_manager.dart';

import '../database/firebase_dataBase.dart';

class ActivityDetailScreen extends StatefulWidget {
  static const routeName = '/activity-detail';
  final VoidCallback? onBack;

  const ActivityDetailScreen({super.key, this.onBack});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  // 1. DÜZELTME: Tek bir tanım listesi kullanıyoruz.
  final List<Map<String, dynamic>> activityDefinitions = [
    {'name': 'Koşu', 'icon': Icons.directions_run, 'color': Colors.orange, 'calPerMin': 12},
    {'name': 'Yürüyüş', 'icon': Icons.directions_walk, 'color': Colors.blue, 'calPerMin': 5},
    {'name': 'Yüzme', 'icon': Icons.pool, 'color': Colors.cyan, 'calPerMin': 11},
    {'name': 'Bisiklet', 'icon': Icons.two_wheeler, 'color': Colors.green, 'calPerMin': 10},
    {'name': 'Yoga', 'icon': Icons.self_improvement, 'color': Colors.purple, 'calPerMin': 4},
    {'name': 'Basketbol', 'icon': Icons.sports_basketball, 'color': Colors.amber, 'calPerMin': 8},
  ];

  List<Activity> addedActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities(); // 2. DÜZELTME: Sayfa açılınca verileri yükle
  }

  // --- VERİ YÜKLEME ---
  Future<void> _loadActivities() async {
    // SessionManager'dan tüm haritayı çek
    Map<DateTime, List<Activity?>> allActivities = await SessionManager.getActivityMap();
    
    // Bugünün tarihini anahtar olarak bul (Saat bilgisini sıfırlayarak)
    final now = DateTime.now();
    final todayKey = allActivities.keys.firstWhere(
      (k) => k.year == now.year && k.month == now.month && k.day == now.day,
      orElse: () => DateTime(now.year, now.month, now.day),
    );

    if (mounted) {
      setState(() {
        // Null olmayanları listeye ekle
        addedActivities = (allActivities[todayKey] ?? [])
            .whereType<Activity>()
            .toList();
        _isLoading = false;
      });
    }
  }

  // --- VERİ KAYDETME ---
  Future<void> _saveActivities() async {
    // 1. Mevcut tüm haritayı çek (Eski verileri ezmemek için)
    Map<DateTime, List<Activity?>> allActivities = await SessionManager.getActivityMap();

    // 2. Bugünün tarihini oluştur
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    // 3. Haritayı güncelle: Bugünün anahtarına güncel listeyi koy
    // Not: SessionManager Activity? tipinde tuttuğu için cast ediyoruz.
    allActivities[todayKey] = addedActivities;

    // 4. Kaydet
    await SessionManager.saveActivityMap(allActivities);

    final user = await FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((user) => user != null);

    final user_id = user!.uid;
    await FirebaseDatabaseService(uid: user_id).updateActivityInfo(addedActivities);
  }

  Map<String, dynamic> _getActivityDef(String type) {
    return activityDefinitions.firstWhere(
      (element) => element['name'] == type,
      orElse: () => activityDefinitions.first,
    );
  }

  void _showAddActivityDialog() {
    String selectedActivityName = activityDefinitions.first['name'];
    int duration = 30; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Aktivite Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedActivityName,
                isExpanded: true,
                items: activityDefinitions.map((def) {
                  return DropdownMenuItem<String>(
                    value: def['name'],
                    child: Row(
                      children: [
                        Icon(def['icon'], color: def['color'], size: 20),
                        const SizedBox(width: 10),
                        Text(def['name']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedActivityName = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Süre: '),
                  Expanded(
                    child: Slider(
                      value: duration.toDouble(),
                      min: 5,
                      max: 180,
                      divisions: 35,
                      label: '$duration dk',
                      onChanged: (value) => setState(() => duration = value.toInt()),
                    ),
                  ),
                ],
              ),
              Text('$duration dakika', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                // 3. DÜZELTME: Kalori hesabı ve Activity oluşturma
                final def = _getActivityDef(selectedActivityName);
                
                // Kalori Hesabı: (Dakika Başı Kalori * Süre)
                final calculatedCalories = (def['calPerMin'] as int) * duration;

                final newActivity = Activity(
                  userId: 1, // Offline mod için sabit ID
                  date: DateTime.now().toIso8601String(),
                  type: selectedActivityName,
                  durationMinutes: duration,
                  distanceKm: 0.0,
                  calories: calculatedCalories,
                  steps: 0,
                  createdAt: DateTime.now().toIso8601String(),
                );

                this.setState(() {
                  addedActivities.add(newActivity);
                });

                // Veriyi diske kaydet
                _saveActivities();

                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Üst Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: Colors.green[400],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Aktiviteler',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Başlık veya Boş Durum
                if (addedActivities.isNotEmpty)
                  Text('Bugünün Aktiviteleri', style: Theme.of(context).textTheme.titleMedium)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Henüz aktivite eklenmedi', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    ),
                  ),

                // Liste
                ...addedActivities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final Activity activity = entry.value;
                  final def = _getActivityDef(activity.type);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (def['color'] as Color).withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (def['color'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(def['icon'], color: def['color'], size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(activity.type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('${activity.durationMinutes} dakika', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${activity.calories} kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.orange)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                addedActivities.removeAt(index);
                              });
                              // Silince de kaydetmeyi unutma
                              _saveActivities();
                            },
                            child: Icon(Icons.close, color: Colors.grey[400], size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Ekle Butonu
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddActivityDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Aktivite Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // İstatistikler
                if (addedActivities.isNotEmpty) ...[
                  Text('Özet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ActivityStat(label: 'Aktiviteler', value: '${addedActivities.length}', color: Colors.blue),
                        _ActivityStat(
                          label: 'Toplam Süre',
                          value: '${addedActivities.fold<int>(0, (sum, a) => sum + a.durationMinutes)} dk',
                          color: Colors.purple,
                        ),
                        _ActivityStat(
                          label: 'Toplam Kalori',
                          value: '${addedActivities.fold<int>(0, (sum, a) => sum + a.calories)} kcal',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Alt widgetlar aynı kalabilir...
class _ActivityStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ActivityStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}