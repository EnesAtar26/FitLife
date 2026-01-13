import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart'; // Servis yolunun doğru olduğundan emin olun

class WaterScreen extends StatefulWidget {
  static const routeName = '/water';
  final VoidCallback? onBack;

  const WaterScreen({super.key, this.onBack});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with WidgetsBindingObserver {
  // Grafik için varsayılan geçmiş verileri (Bugünü SharedPreferences'tan dolduracağız)
  List<int> waterData = [2, 4, 6, 5, 3, 0, 0];
  String unit = 'bardak';
  int goal = 8;
  int todayWater = 0; // Bugün içilen asıl sayaç

  @override
  void initState() {
    super.initState();
    // Uygulama yaşam döngüsünü dinle (Arka plandan dönünce güncellemek için)
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Kullanıcı bildirimden su ekleyip uygulamayı açarsa ekranı güncelle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  // Verileri ve Hedefi Yükle
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Tarih bazlı anahtar oluştur (örn: water_2025_1_9)
    final now = DateTime.now();
    String todayKey = "water_${now.year}_${now.month}_${now.day}";

    setState(() {
      // Kaydedilmiş veriyi çek, yoksa 0
      todayWater = prefs.getInt(todayKey) ?? 0;
      // Hedefi çek, yoksa 8
      goal = prefs.getInt('water_goal') ?? 8;
      unit = prefs.getString('water_unit') ?? 'bardak';

      // Grafik listesindeki bugünün indexini güncelle
      final idx = todayIndex;
      if (idx >= 0 && idx < waterData.length) {
        waterData[idx] = todayWater;
      }
    });

    // Bildirim barını senkronize et (Eğer yoksa oluşturur, varsa günceller)
    NotificationService().showWaterProgressNotification(todayWater, goal);
  }

  int get todayIndex {
    final wd = DateTime.now().weekday;
    return (wd - 1) % 7; // Pazartesi 0, Pazar 6
  }

  // Su Ekleme Fonksiyonu
  Future<void> _addWater() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    String todayKey = "water_${now.year}_${now.month}_${now.day}";

    setState(() {
      todayWater++;
      // Grafikteki veriyi de güncelle
      final idx = todayIndex;
      if (idx >= 0 && idx < waterData.length) {
        waterData[idx] = todayWater;
      }
    });

    // Telefona kaydet
    await prefs.setInt(todayKey, todayWater);

    // Bildirim barını güncelle
    NotificationService().showWaterProgressNotification(todayWater, goal);
  }

  @override
  Widget build(BuildContext context) {
    // Grafik max Y değeri hesaplama
    final maxVal =
        (waterData.isNotEmpty ? waterData.reduce((a, b) => a > b ? a : b) : 1)
            .ceil();
    final chartMaxY = (maxVal + 5).toDouble();
    final todayx = todayIndex;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 248, 248, 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst Başlık
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

              // Hedef ve İçilen Kartı
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

              // Grafik Alanı
              Expanded(
                child: Container(
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
                      Text(
                        'Bu Haftanın Su İçişi',
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
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 2,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.1),
                                strokeWidth: 1,
                              ),
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (BarChartGroupData group) {
                                  return Colors.blue.withValues(alpha: 0.8);
                                },
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${rod.toY.toInt()} $unit',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                              ),
                            ),
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
                                    if (i < 0 || i >= days.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        days[i],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                                    color:
                                        i == todayx &&
                                            waterData[i].toInt() >= goal
                                        ? Colors.green[500]
                                        : i == todayx
                                        ? Colors.orange[400]
                                        : waterData[i].toInt() <
                                              goal // Geçmiş günler ve hedef altı
                                        ? Colors.blue.withValues(alpha: 0.5)
                                        : Colors.green.withValues(
                                            alpha: 0.5,
                                          ), // Geçmiş günler ve hedef üstü
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

              // Alt Butonlar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addWater,
                      icon: const Icon(Icons.add),
                      label: Text('+1 $unit Ekle'),
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
                      label: const Text('Hedefi Düzenle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: goalController,
              decoration: InputDecoration(
                labelText: 'Hedef (sayı)',
                hintText: 'Örn: 8',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: 'Ölçek (birim)',
                hintText: 'Örn: bardak / litre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal Et'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final newGoal = int.tryParse(goalController.text);
              final newUnit = unitController.text.trim();

              setState(() {
                if (newGoal != null && newGoal > 0) {
                  goal = newGoal;
                }
                if (newUnit.isNotEmpty) {
                  unit = newUnit;
                }
              });

              // Hedefleri kaydet
              await prefs.setInt('water_goal', goal);
              await prefs.setString('water_unit', unit);

              // Bildirimdeki hedefi güncelle
              NotificationService().showWaterProgressNotification(
                todayWater,
                goal,
              );

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Tamam', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
