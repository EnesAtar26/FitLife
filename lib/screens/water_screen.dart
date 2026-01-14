import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class WaterScreen extends StatefulWidget {
  static const routeName = '/water';
  final VoidCallback? onBack;

  const WaterScreen({super.key, this.onBack});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with WidgetsBindingObserver {
  List<int> waterData = [0, 0, 0, 0, 0, 0, 0];
  String unit = 'bardak';
  int goal = 8;
  int todayWater = 0;

  @override
  void initState() {
    super.initState();
    // Yaşam döngüsünü dinle (Bildirimden dönünce güncellemek için)
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Uygulama arka plandan öne gelince çalışır
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("🔄 Uygulama öne geldi, veriler yenileniyor...");
      _loadData();
    }
  }

  // Verileri Yükle
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 👇👇👇 KRİTİK EKLEME BURASI 👇👇👇
    // Hafızayı temizle ve diskteki en güncel veriyi (bildirimden gelen) zorla oku
    await prefs.reload();
    // 👆👆👆 BU SATIR OLMADAN EKRAN GÜNCELLENMEZ 👆👆👆

    final now = DateTime.now();
    String todayKey = "water_${now.year}_${now.month}_${now.day}";

    if (!mounted) return;

    setState(() {
      todayWater = prefs.getInt(todayKey) ?? 0;
      goal = prefs.getInt('water_goal') ?? 8;
      unit = prefs.getString('water_unit') ?? 'bardak';

      final idx = todayIndex;
      if (idx >= 0 && idx < waterData.length) {
        waterData[idx] = todayWater;
      }
    });

    // Veritabanı ve bildirim barını da senkronize et (Tutarlılık için)
    NotificationService().showWaterProgressNotification(todayWater, goal);
  }

  int get todayIndex {
    // Pazartesi'yi 0 kabul eden indeksleme
    final wd = DateTime.now().weekday;
    return (wd - 1) % 7;
  }

  Future<void> _addWater() async {
    final prefs = await SharedPreferences.getInstance();
    // Yazmadan önce de yenilemekte fayda var
    await prefs.reload();

    final now = DateTime.now();
    String todayKey = "water_${now.year}_${now.month}_${now.day}";

    setState(() {
      todayWater++;
      final idx = todayIndex;
      if (idx >= 0 && idx < waterData.length) {
        waterData[idx] = todayWater;
      }
    });

    await prefs.setInt(todayKey, todayWater);
    NotificationService().showWaterProgressNotification(todayWater, goal);
  }

  @override
  Widget build(BuildContext context) {
    // Grafik max Y değeri (En az hedef kadar olsun)
    int maxVal = goal;
    if (waterData.isNotEmpty) {
      final currentMax = waterData.reduce((a, b) => a > b ? a : b);
      if (currentMax > maxVal) maxVal = currentMax;
    }

    final chartMaxY = (maxVal + 2).toDouble();
    final todayx = todayIndex;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 248, 248, 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Su Takibi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Kart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // HEDEF
                    Column(
                      children: [
                        const Icon(Icons.flag, color: Colors.blue, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'Hedef',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$goal $unit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    Container(height: 60, width: 1, color: Colors.grey[200]),
                    // İÇİLEN
                    Column(
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: todayWater >= goal ? Colors.green : Colors.red,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İçilen',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$todayWater $unit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: todayWater >= goal
                                ? Colors.green[600]
                                : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Grafik
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haftalık Özet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            maxY: chartMaxY,
                            minY: 0,
                            alignment: BarChartAlignment.spaceAround,
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: const AxisTitles(
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
                                    final i = value.toInt();
                                    if (i < 0 || i >= days.length)
                                      return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        days[i],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(waterData.length, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: waterData[i].toDouble(),
                                    color: i == todayx
                                        ? (waterData[i] >= goal
                                              ? Colors.green
                                              : Colors.orange)
                                        : Colors.blue.withValues(alpha: 0.3),
                                    width: 18,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addWater,
                      icon: const Icon(Icons.add),
                      label: Text('+1 $unit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showGoalDialog,
                      icon: const Icon(Icons.edit),
                      label: const Text('Hedef'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalDialog() {
    final goalController = TextEditingController(text: goal.toString());
    final unitController = TextEditingController(text: unit);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hedefi Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: goalController,
              decoration: const InputDecoration(labelText: 'Hedef (sayı)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Birim'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.reload(); // İşlem öncesi yenile

              final newGoal = int.tryParse(goalController.text);
              final newUnit = unitController.text.trim();

              setState(() {
                if (newGoal != null && newGoal > 0) goal = newGoal;
                if (newUnit.isNotEmpty) unit = newUnit;
              });

              await prefs.setInt('water_goal', goal);
              await prefs.setString('water_unit', unit);
              NotificationService().showWaterProgressNotification(
                todayWater,
                goal,
              );

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
