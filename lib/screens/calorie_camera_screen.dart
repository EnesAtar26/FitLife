import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_application_6/services/session_manager.dart'; // SessionManager importu

class FoodAnalysisScreen extends StatefulWidget {
  const FoodAnalysisScreen({super.key});

  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _resultText;

  String? _detectedFoodName;
  int? _detectedCalories;

  // Listeyi final yapmıyoruz, çünkü veritabanından dolacak
  List<Map<String, dynamic>> _eatenFoods = [];

  int get _totalCalories =>
      _eatenFoods.fold(0, (sum, item) => sum + (item['calories'] as int));

  final String apiKey = dotenv.env["API_KEY"] ?? "";

  @override
  void initState() {
    super.initState();
    _loadDailyFoods(); // Uygulama açılınca verileri yükle
  }

  // --- VERİ YÜKLEME ---
  Future<void> _loadDailyFoods() async {
    final foods = await SessionManager.getFoodLog();
    if (mounted) {
      setState(() {
        _eatenFoods = foods;
      });
    }
  }

  // --- VERİ KAYDETME YARDIMCISI ---
  Future<void> _saveData() async {
    await SessionManager.saveFoodLog(_eatenFoods);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _resultText = null;
        _detectedFoodName = null;
        _detectedCalories = null;
      });
      _analyzeFood(File(pickedFile.path));
    }
  }

  Future<void> _analyzeFood(File image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = TextPart(
        "Bu fotoğraftaki yemeği analiz et. Yemeğin ne olduğunu tahmin et ve tahmini kalorisini hesapla. "
        "Cevabı şu formatta, sade ve net ver:(başka bir şey yazma) \n"
        "Yemek: [Yemek Adı] \n"
        "Porsiyon: [Tahmini Porsiyon] \n"
        "Kalori: [Sayı] kcal \n"
        "Makrolar: [Protein, Karbonhidrat, Yağ]"
        "\nEğer resimde yemek yoksa sadece 'Yemek tespit edilemedi' yaz.",
      );

      final imageBytes = await image.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final text = response.text ?? "";

      String foodName = "Bilinmeyen Yemek";
      int calories = 0;

      final nameMatch = RegExp(r"Yemek:\s*(.*)").firstMatch(text);
      final calMatch = RegExp(r"Kalori:\s*(\d+)").firstMatch(text);

      if (nameMatch != null) foodName = nameMatch.group(1) ?? "";
      if (calMatch != null) {
        calories = int.tryParse(calMatch.group(1) ?? "0") ?? 0;
      }

      setState(() {
        _resultText = response.text;
        _detectedFoodName = foodName;
        _detectedCalories = calories;
      });
    } catch (e) {
      setState(() {
        _resultText = "Hata: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- LİSTEYE EKLEME ---
  void _addFoodToList() {
    if (_detectedFoodName != null && _detectedCalories != null) {
      setState(() {
        _eatenFoods.add({
          'name': _detectedFoodName,
          'calories': _detectedCalories,
          'time': DateTime.now(),
        });
      });
      
      _saveData(); // <--- VERİYİ KAYDET

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_detectedFoodName listeye eklendi!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- LİSTEDEN SİLME ---
  void _removeFood(int index) {
    setState(() {
      _eatenFoods.removeAt(index);
    });
    _saveData(); // <--- GÜNCEL HALİNİ KAYDET
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: Colors.orange[400],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Kalori Takip',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ÖZET KARTI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bugün Alınan',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toplam Kalori',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$_totalCalories kcal',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // KAMERA/FOTOĞRAF
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 50,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Yemeğini çek, analizi gör',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
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
                      child: _buildActionButton(
                        context,
                        icon: Icons.camera_alt,
                        label: 'Kamera',
                        color: Colors.orangeAccent,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.photo_library,
                        label: 'Galeri',
                        color: Colors.blueAccent,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // YÜKLENİYOR / SONUÇ
                if (_isLoading)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.orange),
                        const SizedBox(height: 12),
                        Text(
                          "Yapay zeka hesaplıyor...",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                else if (_resultText != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analiz Sonucu',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _resultText!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_detectedFoodName != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _addFoodToList,
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('Bu Yemeği Listeye Ekle'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 30),
                const Divider(),

                // BUGÜN YENİLENLER LİSTESİ
                if (_eatenFoods.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Bugün Yenilenler',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _eatenFoods.length,
                    itemBuilder: (context, index) {
                      final food = _eatenFoods[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key("${food['name']}_${food['time']}"), // Benzersiz key
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _removeFood(index),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    food['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '+${food['calories']} kcal',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}