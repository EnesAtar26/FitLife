import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_screen.dart';

class WaterScreen extends StatefulWidget {
  static const routeName = '/water';
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  // Haftalık içilen bardak sayıları (örnek veriler). Index 0 = Pazartesi ... 6 = Pazar
  List<int> waterData = [-1, 3, 5, 8, 6, 10, 3];
  String unit = 'bardak';
  int goal = 7;

  int get todayIndex {
    final wd = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    return (wd - 1) % 7;
  }

  void _addWater() {
    setState(() {
      final idx = todayIndex;
      waterData[idx] = (waterData[idx] + 1); //.clamp(0, goal.toInt());
    });
  }

  // Dinamik olarak sol eksen için gösterilecek integer etiketleri hesapla
  List<double> _computeLabelHeight() {
    if (waterData.isEmpty) {
      return [0];
    }

    // waterData'daki değerleri double yap ve tekrar edenleri kaldır
    List<double> heights = waterData.map((d) => d.toDouble()).toList();
    heights.sort();

    double maxHeight = heights.last;

    double k = 1;
    if (maxHeight > 7) {
      k = maxHeight / 7;
    }

    heights = waterData.map((h) => h / k).toList();
    heights[0] = heights[0];
    return heights;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // maxY grafiğin üst sınırı: en büyük değerden 1 fazlası (min 1)
    final maxVal = (waterData.isNotEmpty ? waterData.reduce((a, b) => a > b ? a : b) : 1).ceil();
    final chartMaxY = (maxVal + 5).toDouble();
    final todayx = todayIndex;

    final labelsHeight = _computeLabelHeight();


    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Üst kısım: Geri butonu + Başlık (orta) + boşluk
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Su Takibi',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.water_drop, color: Colors.blueAccent, size: 28),
                    ],
                  ),
                  const SizedBox(width: 48), // denge için boşluk
                ],
              ),

              const SizedBox(height: 24),

              // Hedef ve İçilen
              Text(
                'Hedef → $goal $unit Su',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.amber[800]),
              ),
              const SizedBox(height: 10),
              Text(
                'İçilen → ${waterData[todayIndex].toInt()} $unit Su',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: waterData[todayIndex].toInt() >= goal
                      ? Colors.green[600] // hedefe ulaştı veya geçti → yeşil
                      : Colors.red[600],   // henüz ulaşmadı → kırmızı
                ),
              ),

              const SizedBox(height: 24),

              // Grafik konteyneri
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [

                      const SizedBox(width: 8),

                      // SAĞ: BarChart (esnek)
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            maxY: chartMaxY,
                            minY: 0,
                            alignment: BarChartAlignment.spaceAround,
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withOpacity(0.22),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                // Tooltip arka plan rengini dinamik belirle
                                getTooltipColor: (BarChartGroupData group) {
                                  // group.x bugünün indexi ile eşleşiyorsa gold, değilse blueGrey
                                  return group.x == todayIndex ? Colors.blueGrey : Colors.black54;
                                },
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${rod.toY.toInt()}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // biz sol etiketleri manuel gösteriyoruz
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                                    final i = value.toInt();
                                    if (i < 0 || i >= days.length) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(days[i], style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(
                              waterData.length,
                                  (i) {
                                // Eğer veri -1 ise, o günü çizme (boş grup döndür)
                                if (waterData[i] == -1) {
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [],
                                  );
                                }

                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: waterData[i].toDouble(),
                                      color: i == todayx && waterData[i].toInt() >= goal
                                          ? Colors.green[500]
                                          : i == todayx
                                          ? Colors.red[300]
                                          : waterData[i].toInt() < goal
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                      width: 22,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                  showingTooltipIndicators: [0],
                                );
                              },
                            ),
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 600),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // +1 Bardak Ekle butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addWater,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('+1 $unit Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 12),

              // Hedefi Düzenle butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
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
                              decoration: const InputDecoration(
                                labelText: 'Hedef (sayı)',
                                hintText: 'Örn: 8',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: unitController,
                              decoration: const InputDecoration(
                                labelText: 'Ölçek (birim)',
                                hintText: 'Örn: bardak / litre',
                                border: OutlineInputBorder(),
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
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () {
                              setState(() {
                                final newGoal = int.tryParse(goalController.text);
                                if (newGoal != null && newGoal > 0) {
                                  goal = newGoal;
                                }
                                unit = unitController.text.trim().isEmpty ? unit : unitController.text.trim();
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Tamam'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Hedefi Düzenle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}