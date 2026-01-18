import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_6/services/session_manager.dart';
import '../database//firebase_dataBase.dart';

class SleepTrackerScreen extends StatefulWidget {
  static const routeName = '/sleep-tracker';
  final VoidCallback? onBack;

  const SleepTrackerScreen({super.key, this.onBack});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  // Grafik verisi: [6 gün önce, ..., Dün, Bugün]
  List<double> sleepData = List.filled(7, 0.0);
  double goal = 8.0; 
  bool isLoading = true;
  final double chartMaxY = 14.0; 

  @override
  void initState() {
    super.initState();
    _loadSleepData();
  }

  Future<void> _loadSleepData() async {
    setState(() => isLoading = true); // Yüklemeyi başlat

    try {
      // 1. Yerel veriyi çek
      final sleepMap = await SessionManager.getSleepLog();
      final now = DateTime.now();

      // 2. Firebase Kullanıcısını Kontrol Et (BEKLEMEDEN)
      final user = FirebaseAuth.instance.currentUser;

      // Firebase verisi için boş bir liste veya dolu liste hazırla
      List<double> firebaseData = List.filled(7, 0.0);

      // SADECE Kullanıcı varsa ve internet varsa Firebase'den çek
      if (user != null) {
        try {
          firebaseData = await FirebaseDatabaseService(uid: user.uid).getWeeklySleep();
          // Eğer firebase'den boş dönerse diye kontrol
          if (firebaseData.isEmpty) firebaseData = List.filled(7, 0.0);
        } catch (e) {
          debugPrint("Firebase veri çekme hatası (Önemli değil, yerel devam et): $e");
        }
      }

      // 3. Verileri Birleştir (Yerel + Firebase)
      // Mantık: Son 7 gün için döngü kuruyoruz.
      List<double> combinedData = [];

      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String key = _formatDate(date);
        
        // Yerelde veri var mı?
        double? localVal = sleepMap[key];
        
        // Firebase listesinden o güne denk gelen veri (Bu kısım Firebase servisin ne döndürdüğüne bağlı,
        // Basitlik adına burada çakışma olmaması için Yerel veriyi öncelikli kılıyoruz)
        
        if (localVal != null && localVal > 0) {
          combinedData.add(localVal);
        } else {
          // Yerelde yoksa Firebase'den gelen veriyi kullan (Eğer indeks uyuyorsa)
          // Not: FirebaseData genellikle sıralı gelir, burada basitçe 0 ekliyoruz veya
          // Firebase yapın gün bazlıysa onu maplemelisin.
          // Şimdilik çakışmayı önlemek için 0.0 ekliyorum, çünkü sleepMap zaten ana veri kaynağın.
          combinedData.add(0.0); 
        }
      }
      
      // NOT: Eğer Firebase servisiniz direkt son 7 günü veriyorsa, 
      // yukarıdaki döngü yerine direkt onu kullanıp yerel veriyi üzerine yazabilirsiniz.
      // Basit çözüm için: sleepMap (Yerel veri) en güncelidir.
      // Sadece sleepMap'ten grafiği doldurmak en garantisidir:
      
      List<double> finalData = [];
      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String key = _formatDate(date);
        // Yerelde varsa al, yoksa 0.0
        finalData.add(sleepMap[key] ?? 0.0);
      }

      if (mounted) {
        setState(() {
          sleepData = finalData;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Genel Hata: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

 Future<void> _saveSleepEntry(double hours) async {
    try {
      // 1. Önce Yerele Kaydet (Hızlı ve Garanti)
      final sleepMap = await SessionManager.getSleepLog();
      DateTime date = DateTime.now();
      String key = _formatDate(date);
      sleepMap[key] = hours;
      await SessionManager.saveSleepLog(sleepMap);

      // 2. Kullanıcı Online mı diye bak (Beklemeden)
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Online ise Firebase'e de yaz
        await FirebaseDatabaseService(uid: user.uid).updateTodaySleep(hours);
      }

      // 3. Ekranı yenile
      _loadSleepData();
      
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Sadece Bugün İçin Diyalog
  void _showTodaySleepDialog() {
    // Listenin son elemanı (index 6) bugündür
    double currentVal = sleepData.last; 
    double hours = currentVal.truncateToDouble();
    double minutes = ((currentVal % 1) * 60).roundToDouble();

    DateTime now = DateTime.now();
    String dateStr = "${now.day}.${now.month}.${now.year}";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('$dateStr\nUyku Süresi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${hours.toInt()} sa ${minutes.toInt()} dk', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 24),
              
              const Align(alignment: Alignment.centerLeft, child: Text("Saat", style: TextStyle(color: Colors.grey))),
              Slider(
                value: hours,
                min: 0, max: 16, divisions: 16,
                label: '${hours.toInt()}',
                onChanged: (v) => setDialogState(() => hours = v),
              ),
              
              const Align(alignment: Alignment.centerLeft, child: Text("Dakika", style: TextStyle(color: Colors.grey))),
              Slider(
                value: minutes,
                min: 0, max: 59, divisions: 60,
                label: '${minutes.toInt()}',
                onChanged: (v) => setDialogState(() => minutes = v),
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
                double total = hours + (minutes / 60.0);
                _saveSleepEntry(total);
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
    final double todaySleep = sleepData.isNotEmpty ? sleepData.last : 0.0;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ÜST BAŞLIK
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.onBack != null)
                      IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
                    Icon(Icons.bedtime, color: Colors.purple, size: 28),
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

                // ÖZET KARTI
                _buildSummaryCard(context, todaySleep),
                
                const SizedBox(height: 16),

                // --- BUGÜN VERİ EKLEME BUTONU ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showTodaySleepDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: const Text(
                      "Bugünün Uykusunu Gir",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // GRAFİK BAŞLIĞI
                const Text(
                  'Son 7 Günlük İstatistik',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // --- GRAFİK ---
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: BarChart(
                    BarChartData(
                      maxY: chartMaxY,
                      barTouchData: BarTouchData(
                        enabled: true, 
                        touchCallback: null, // Tıklama iptal edildi
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toStringAsFixed(1)} sa',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index < 0 || index >= 7) return const SizedBox();
                              
                              DateTime date = DateTime.now().subtract(Duration(days: 6 - index));
                              const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(days[date.weekday - 1], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      
                      // ÇUBUKLAR
                      barGroups: List.generate(7, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: sleepData[i],
                              color: i == 6 ? Colors.purple[400] : Theme.of(context).primaryColor.withOpacity(0.5),
                              width: 20,
                              borderRadius: BorderRadius.circular(6),
                              // Arka plan çizgisi (görsellik için kalsın)
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: chartMaxY,
                                color: Colors.grey[100],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                // İPUÇLARI
                const Text('Uyku İpuçları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _TipCard(title: '🛏️ Düzenli Saat', description: 'Her gün aynı saatte yatıp kalkmaya çalışın.'),
                const SizedBox(height: 8),
                _TipCard(title: '📵 Ekran Diyeti', description: 'Yatmadan 30 dk önce telefon kullanma.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double todaySleep) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 15, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dün Gece', style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(
                '${todaySleep.toStringAsFixed(1)} saat',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Hedef: ${goal.toInt()}s", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                todaySleep >= goal ? "Hedef Tamam! 🎉" : "${(goal - todaySleep).toStringAsFixed(1)}s eksik",
                style: TextStyle(
                  color: todaySleep >= goal ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12
                ),
              )
            ],
          )
        ],
      ),
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
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(description, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }
}