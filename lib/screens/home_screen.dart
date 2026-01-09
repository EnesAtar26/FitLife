import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'calorie_camera_screen.dart';
import 'package:health/health.dart';
import 'activity_detail_screen.dart';
import 'sleep_tracker_screen.dart';
import 'profile_screen.dart';
import 'water_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _stepCount = 0;
  double _sleepHours = 7.5; // Varsayılan uyku saati
  final Health health = Health();

  late final List<Widget> _screens = [
    _buildDashboard(context),
    SleepTrackerScreen(),
    ActivityDetailScreen(),
    WaterScreen(),
    FoodAnalysisScreen(),
    ProfileScreen()
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndFetchData();
  }

  Future<void> _requestPermissionsAndFetchData() async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.SLEEP_IN_BED,
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
      print('Hata: $e');
    }
  }

  Future<void> _fetchHealthData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Adım verisi al
      List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      // Kalori verisi al
      List<HealthDataPoint> caloriesData = await health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      // Uyku verisi al (dün gece)
      final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
      List<HealthDataPoint> sleepData = await health.getHealthDataFromTypes(
        startTime: startOfYesterday,
        endTime: startOfDay,
        types: [HealthDataType.SLEEP_IN_BED],
      );

      int totalSteps = 0;
      double totalSleepMinutes = 0;

      for (var data in stepsData) {
        if (data.value is NumericHealthValue) {
          totalSteps += ((data.value as NumericHealthValue) as double).toInt();
        }
      }

      // Uyku dakikalarını saat'e çevir
      for (var data in sleepData) {
        if (data.value is NumericHealthValue) {
          totalSleepMinutes += (data.value as NumericHealthValue) as double;
        }
      }
      double sleepHours = totalSleepMinutes / 60;

      setState(() {
        _stepCount = totalSteps;
        if (sleepHours > 0) {
          _sleepHours = sleepHours;
        }
      });
    } catch (e) {
      print('Veri çekme hatası: $e');
      // Varsayılan değerleri kullan
      setState(() {
        _stepCount = 7236;
        _sleepHours = 7.5;
      });
    }
  }

  Widget _buildDashboard(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  Text('Günaydın, Ayşe ☀️', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                  const SizedBox(height: 4),
                  Text('8 Kasım 2025, Cumartesi', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: _stepCount / 10000, // 10000 adım hedefi
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
                      const SizedBox(height: 6),
                      Text('Adım', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatCard(title: 'Kalori', value: '1,840 kcal', icon: Icons.local_fire_department, color: Colors.orange),
                        _StatCard(
                          title: 'Su',
                          value: '6/8 bardak',
                          icon: Icons.water_drop,
                          color: Colors.blue,
                          onTap: () {
                            setState(() {
                              _selectedIndex = 3;
                            });
                          },
                        ),
                        _StatCard(
                          title: 'Uyku',
                          value: '${_sleepHours.toStringAsFixed(1)} sa',
                          icon: Icons.bedtime,
                          color: Colors.purple,
                          onTap: () {
                            setState(() {
                              _selectedIndex = 1;
                            });
                          },
                        ),
                        _StatCard(
                          title: 'Aktivite',
                          value: '45 dk koşu',
                          icon: Icons.directions_run,
                          color: Colors.green,
                          onTap: () {
                            setState(() {
                              _selectedIndex = 2;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bu Haftanın Kalori İstatistiği', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                barTouchData: barTouchData,
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: getTitles,
                                      reservedSize: 38,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _getWeeklyCalorieData(),
                                gridData: FlGridData(show: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
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
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
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
            )
          ],
        ),
      ),
    );
  }

  BarTouchData get barTouchData => BarTouchData(
    enabled: true,
    touchTooltipData: BarTouchTooltipData(
      tooltipPadding: const EdgeInsets.all(8),
      tooltipMargin: 8,
      getTooltipColor: (BarChartGroupData group) {
        return Colors.orange.withValues(alpha: 0.9);
      },
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        return BarTooltipItem(
          '${rod.toY.toInt()} kcal',
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
      },
    ),
  );

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    return SideTitleWidget(
      meta: meta,
      child: Text(days[value.toInt()], style: style),
    );
  }

  List<BarChartGroupData> _getWeeklyCalorieData() {
    // Haftalık örnek kalori verisi
    final weeklyData = [1600, 1800, 1550, 1900, 1840, 1700, 2000];
    
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyData[index].toDouble(),
            color: Colors.orange.withValues(alpha: 0.8),
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap; // 👈 yeni eklendi

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.15), width: 1),
        ),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.2),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(
                        fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(value,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}