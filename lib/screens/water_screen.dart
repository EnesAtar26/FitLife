import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_6/services/session_manager.dart';

import '../database/firebase_dataBase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class WaterScreen extends StatefulWidget {
  static const routeName = '/water';
  final VoidCallback? onBack;

  const WaterScreen({super.key, this.onBack});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  // Son 7 günün verisi (0: 6 gün önce ... 6: Bugün)
  List<int> waterData = List.filled(7, 0);
  String unit = 'bardak';
  int goal = 8;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  // --- VERİLERİ YÜKLE ---
  Future<void> _loadWaterData() async {
    try {
      final waterMap = await SessionManager.getWaterLog();
      final savedGoal = await SessionManager.getWaterGoal();
      
      final now = DateTime.now();
      List<int> loadedList = [];

      // Son 7 günü hesapla (Bugünden geriye doğru)
      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String key = _formatDate(date);
        loadedList.add(waterMap[key] ?? 0);
      }

      if (mounted) {
        setState(() {
          waterData = loadedList;
          goal = savedGoal;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- SU EKLEME VE KAYDETME ---
  Future<void> _addWater() async {
    try {
      Map<String, int> waterMap = await SessionManager.getWaterLog();
      DateTime now = DateTime.now();
      String key = _formatDate(now);

      int currentVal = waterMap[key] ?? 0;
      waterMap[key] = currentVal + 1;

      await SessionManager.saveWaterLog(waterMap);
      _loadWaterData();

      final user = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((user) => user != null);

      final user_id = user!.uid;
      await FirebaseDatabaseService(uid: user_id).updateTodayWater(currentVal + 1, goal);
      NotificationService().showWaterProgressNotification(currentVal + 1, goal);
    } catch (e) {
      debugPrint("Su ekleme hatası: $e");
    }
  }

  // --- HEDEF KAYDETME ---
  Future<void> _saveGoal(int newGoal) async {
    await SessionManager.saveWaterGoal(newGoal);

    final user = await FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((user) => user != null);

    final user_id = user!.uid;
    await FirebaseDatabaseService(uid: user_id).updateTodayWater(waterData.last, newGoal);

    setState(() => goal = newGoal);
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int todayVal = waterData.last; 
    // Grafik tavanını hesapla (En yüksek veri veya hedef + biraz boşluk)
    int maxData = waterData.reduce((curr, next) => curr > next ? curr : next);
    double chartMaxY = (maxData > goal ? maxData : goal) + 2.0;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 248, 248, 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BAŞLIK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.onBack != null)
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
                  Icon(Icons.water_drop, color: Colors.blue[400], size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Su Takibi',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[900]),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ÖZET KARTI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.15), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // HEDEF
                    Column(
                      children: [
                        Icon(Icons.flag, color: Colors.blue[400], size: 28),
                        const SizedBox(height: 8),
                        Text('Hedef', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('$goal $unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                      ],
                    ),
                    Container(height: 60, width: 1, color: Colors.grey[200]),
                    // İÇİLEN
                    Column(
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: todayVal >= goal ? Colors.green : Colors.red[400],
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text('İçilen', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          '$todayVal $unit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: todayVal >= goal ? Colors.green[600] : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // GRAFİK ALANI
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('7 Günlük İstatistik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                          // Hedef Göstergesi (Lejant)
                          Row(
                            children: [
                              Container(width: 12, height: 2, color: Colors.green),
                              const SizedBox(width: 4),
                              const Text("Hedef", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 24), // Grafik üst boşluğu artırıldı
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            maxY: chartMaxY,
                            minY: 0,
                            alignment: BarChartAlignment.spaceAround,
                            
                            // Izgara Çizgileri
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 2, // 2'şer artan çizgiler
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withOpacity(0.1),
                                strokeWidth: 1,
                              ),
                            ),
                            
                            // Hedef Çizgisi (Extra Lines)
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: goal.toDouble(),
                                  color: Colors.green.withOpacity(0.6),
                                  strokeWidth: 2,
                                  dashArray: [5, 5], // Kesikli çizgi
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.only(right: 5, bottom: 5),
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                                    labelResolver: (line) => "Hedef: $goal",
                                  ),
                                ),
                              ],
                            ),

                            borderData: FlBorderData(show: false),
                            
                            // Dokunma Bilgisi
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Colors.blue.withOpacity(0.8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${rod.toY.toInt()} $unit',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  );
                                },
                              ),
                            ),

                            // Eksen Yazıları
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              
                              // SOL EKSEN (Sayılar)
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 2, // 0, 2, 4, 6...
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              
                              // ALT EKSEN (Günler)
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= 7) return const SizedBox.shrink();
                                    
                                    DateTime date = DateTime.now().subtract(Duration(days: 6 - i));
                                    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        days[date.weekday - 1],
                                        style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // ÇUBUKLAR
                            barGroups: List.generate(7, (i) {
                              bool isGoalReached = waterData[i] >= goal;
                              
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: waterData[i].toDouble(),
                                    // RENK MANTIĞI:
                                    // Hedefi geçenler -> MAVİ
                                    // Hedefi geçemeyenler -> SOLUK MAVİ (Opacity 0.3)
                                    color: isGoalReached 
                                        ? Colors.blue 
                                        : Colors.blue.withOpacity(0.3),
                                    width: 18,
                                    borderRadius: BorderRadius.circular(6),
                                    // Dolum animasyonu için arka plan
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: chartMaxY,
                                      color: Colors.grey.withOpacity(0.05),
                                    ),
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

              // BUTONLAR
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hedefi Düzenle'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: goalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Hedef',
                  suffixText: 'bardak',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal Et')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newGoal = int.tryParse(goalController.text);
              if (newGoal != null && newGoal > 0) {
                _saveGoal(newGoal);
            //     NotificationService().showWaterProgressNotification(
           //     currentVal + 1,
           //     goal,
            //  );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}