import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ActivityDetailScreen extends StatefulWidget {
  static const routeName = '/activity-detail';
  final VoidCallback? onBack;

  const ActivityDetailScreen({super.key, this.onBack});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final List<Map<String, dynamic>> activities = [
    {
      'name': '🏃 Koşu',
      'icon': Icons.directions_run,
      'color': Colors.orange,
      'calories': 12,
    },
    {
      'name': '🚶 Yürüyüş',
      'icon': Icons.directions_walk,
      'color': Colors.blue,
      'calories': 5,
    },
    {
      'name': '🏊 Yüzme',
      'icon': Icons.pool,
      'color': Colors.cyan,
      'calories': 11,
    },
    {
      'name': '🚴 Bisiklet',
      'icon': Icons.two_wheeler,
      'color': Colors.green,
      'calories': 10,
    },
    {
      'name': '🧘 Yoga',
      'icon': Icons.self_improvement,
      'color': Colors.purple,
      'calories': 4,
    },
    {
      'name': '⛹️ Basketbol',
      'icon': Icons.sports_basketball,
      'color': Colors.amber,
      'calories': 8,
    },
  ];

  List<Map<String, dynamic>> addedActivities = [];

  void _showAddActivityDialog() {
    String selectedActivity = activities.first['name'];
    int duration = 30; // dakika

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Aktivite Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedActivity,
                isExpanded: true,
                items: activities.map((activity) {
                  return DropdownMenuItem<String>(
                    value: activity['name'],
                    child: Text(activity['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedActivity = value ?? 'Koşu';
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Süre (dk): '),
                  Expanded(
                    child: Slider(
                      value: duration.toDouble(),
                      min: 5,
                      max: 180,
                      divisions: 35,
                      label: '$duration dk',
                      onChanged: (value) {
                        setState(() {
                          duration = value.toInt();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Text(
                '$duration dakika',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final activity = activities.firstWhere(
                  (a) => a['name'] == selectedActivity,
                );
                final calories = (activity['calories'] * duration) ~/ 60;

                this.setState(() {
                  addedActivities.add({
                    'name': selectedActivity,
                    'duration': duration,
                    'calories': calories,
                    'icon': activity['icon'],
                    'color': activity['color'],
                  });
                });
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım: Geri butonu + Başlık
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_run,
                      color: Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Aktivite Detay',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Eklenen Aktiviteler Başlığı
                if (addedActivities.isNotEmpty)
                  Text(
                    'Bugünün Aktiviteleri',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                if (addedActivities.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz aktivite eklenmedi',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aktivite eklemek için butona basın',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Eklenen Aktiviteler Listesi
                ...addedActivities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: activity['color'].withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: activity['color'].withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              activity['icon'],
                              color: activity['color'],
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${activity['duration']} dakika',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${activity['calories']} kcal',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                addedActivities.removeAt(index);
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // Aktivite Ekleme Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddActivityDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Aktivite Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Aktivite İstatistikleri
                if (addedActivities.isNotEmpty) ...[
                  Text('Özet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ActivityStat(
                          label: 'Aktiviteler',
                          value: '${addedActivities.length}',
                          color: Colors.blue,
                        ),
                        _ActivityStat(
                          label: 'Toplam Süre',
                          value:
                              '${addedActivities.fold<int>(0, (sum, a) => sum + a['duration'] as int)} dk',
                          color: Colors.purple,
                        ),
                        _ActivityStat(
                          label: 'Toplam Kalori',
                          value:
                              '${addedActivities.fold<int>(0, (sum, a) => sum + a['calories'] as int)} kcal',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ActivityStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
