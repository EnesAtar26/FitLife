import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';

class SleepTrackerScreen extends StatefulWidget {
  static const routeName = '/sleep-tracker';
  final VoidCallback? onBack;

  const SleepTrackerScreen({super.key, this.onBack});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  // Haftalık uyku süreleri (örnek veriler)
  List<double> sleepData = [7.2, 6.8, 8.1, 7.5, 6.9, 7.8, 7.0];
  double goal = 8.0;
  final Health health = Health();
  bool isLoading = true;
  bool hasHealthData = false; // Health verisi var mı

  @override
  void initState() {
    super.initState();
    _fetchSleepData();
  }

  Future<void> _fetchSleepData() async {
    try {
      // Varsayılan verilerle başla - timeout olursa bunları kullan
      List<double> weekData = [7.2, 6.8, 8.1, 7.5, 6.9, 7.8, 7.0];

      try {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

        // Timeout ile tüm veri çekme işlemini sarıp al
        await Future.delayed(
          const Duration(milliseconds: 100),
        ); // Permissionlar için zaman ver

        // Geçen 7 günün uyku verilerini al (timeout ile)
        for (int i = 0; i < 7; i++) {
          try {
            final dayStart = startOfWeek.add(Duration(days: i));
            final dayEnd = dayStart.add(const Duration(days: 1));

            final sleepPoints = await health
                .getHealthDataFromTypes(
                  startTime: dayStart,
                  endTime: dayEnd,
                  types: [HealthDataType.SLEEP_IN_BED],
                )
                .timeout(const Duration(seconds: 2));

            double dayMinutes = 0;
            for (var point in sleepPoints) {
              if (point.value is NumericHealthValue) {
                dayMinutes += (point.value as NumericHealthValue) as double;
              }
            }

            if (dayMinutes > 0) {
              weekData[i] = dayMinutes / 60;
            }
          } catch (e) {
            print('Gün $i uyku verisi hatası: $e');
            // Bu gün için varsayılan değeri kullan
          }
        }
      } catch (e) {
        print('Genel veri çekme hatası: $e');
        // Varsayılan verilerle devam et
      }

      if (mounted) {
        setState(() {
          sleepData = weekData;
          hasHealthData = false; // Varsayılan değerleri kullan
          isLoading = false;
        });
      }
    } catch (e) {
      print('Uyku verisi çekme hatası: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  int get todayIndex {
    final wd = DateTime.now().weekday;
    return (wd - 1) % 7;
  }

  void _showManualSleepDialog(int dayIndex) {
    double hours = sleepData[dayIndex];
    double minutes = ((sleepData[dayIndex] % 1) * 60).toInt().toDouble();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Uyku Süresi Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saat: ${hours.toInt()} sa'),
              Slider(
                value: hours,
                min: 0,
                max: 12,
                divisions: 24,
                label: '${hours.toStringAsFixed(1)} sa',
                onChanged: (value) {
                  setState(() {
                    hours = value;
                  });
                },
              ),
              Text('Dakika: ${minutes.toInt()} dk'),
              Slider(
                value: minutes,
                min: 0,
                max: 59,
                divisions: 59,
                label: '${minutes.toStringAsFixed(0)} dk',
                onChanged: (value) {
                  setState(() {
                    minutes = value;
                  });
                },
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
                setState(() {
                  sleepData[dayIndex] = hours + (minutes / 60);
                });
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = this.todayIndex;
    final todaySleep = sleepData[todayIndex];

    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

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
                    const Icon(Icons.bedtime, color: Colors.purple, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Uyku Takibi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bugünün uyku özeti kartı
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(156, 39, 176, 1),
                        Color.fromRGBO(142, 36, 170, 1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(156, 39, 176, 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dün Gece',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${todaySleep.toStringAsFixed(1)} saat',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bedtime,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SleepStat(
                            label: 'Hedef',
                            value: '${goal.toStringAsFixed(1)} sa',
                            color: Colors.white,
                          ),
                          _SleepStat(
                            label: 'Fark',
                            value: todaySleep >= goal
                                ? '+${(todaySleep - goal).toStringAsFixed(1)} sa'
                                : '-${(goal - todaySleep).toStringAsFixed(1)} sa',
                            color: todaySleep >= goal
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          _SleepStat(
                            label: 'Kalite',
                            value: 'İyi',
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Grafik başlığı ve rehber metni
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Haftalık Uyku Süresi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!hasHealthData)
                      Text(
                        'Çubuğa tıkla →',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Uyku grafiği
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        maxY: 10,
                        minY: 0,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toStringAsFixed(1)} sa',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          handleBuiltInTouches: true,
                          touchCallback: (event, response) {
                            if (response?.spot != null) {
                              final barIndex =
                                  response!.spot!.touchedBarGroupIndex;
                              if (!hasHealthData) {
                                _showManualSleepDialog(barIndex);
                              }
                            }
                          },
                        ),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 2,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          ),
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          sleepData.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: sleepData[i],
                                color: i == todayIndex
                                    ? Colors.purple[500]
                                    : Colors.purple[300],
                                width: 20,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Pzt',
                                  'Sal',
                                  'Çar',
                                  'Per',
                                  'Cum',
                                  'Cmt',
                                  'Paz',
                                ];
                                final index = value.toInt();
                                return Text(
                                  days[index],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toStringAsFixed(0)}h',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              interval: 2,
                              reservedSize: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Uyku aşamaları
                Text(
                  'Uyku Aşamaları',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SleepPhase(
                        label: 'Hafif Uyku',
                        duration: '2h 15m',
                        percentage: 32,
                        color: Colors.blue,
                      ),
                      const Divider(height: 20),
                      _SleepPhase(
                        label: 'Derin Uyku',
                        duration: '1h 45m',
                        percentage: 25,
                        color: Colors.purple,
                      ),
                      const Divider(height: 20),
                      _SleepPhase(
                        label: 'REM Uyku',
                        duration: '1h 30m',
                        percentage: 21,
                        color: Colors.orange,
                      ),
                      const Divider(height: 20),
                      _SleepPhase(
                        label: 'Uykusuzluk',
                        duration: '1h 30m',
                        percentage: 22,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // İpuçları
                Text(
                  'Uyku İyileştirme İpuçları',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _TipCard(
                  title: '🛏️ Düzenli Uyku Saati',
                  description: 'Her gün aynı saatte yatıp kalkmaya çalışın',
                ),
                const SizedBox(height: 8),
                _TipCard(
                  title: '📵 Ekran Kalması',
                  description: 'Yatışından 30 dakika önce telefon kullanmayın',
                ),
                const SizedBox(height: 8),
                _TipCard(
                  title: '🌡️ Oda Sıcaklığı',
                  description: 'Uyumak için ideal sıcaklık 16-19°C',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SleepStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        ),
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

class _SleepPhase extends StatelessWidget {
  final String label;
  final String duration;
  final int percentage;
  final Color color;

  const _SleepPhase({
    required this.label,
    required this.duration,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              duration,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '%$percentage',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;

  const _TipCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
