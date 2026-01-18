import 'package:flutter/material.dart';
import 'package:flutter_application_6/services/step_recommender_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepRecommenderForm extends StatefulWidget {
  final Map<String, dynamic> currentUserData;
  final Function(int) onTargetUpdated;

  const StepRecommenderForm({
    super.key,
    required this.currentUserData,
    required this.onTargetUpdated,
  });

  @override
  State<StepRecommenderForm> createState() => _StepRecommenderFormState();
}

class _StepRecommenderFormState extends State<StepRecommenderForm> {
  double _sedentaryHours = 6.0;
  bool _doSport = false;
  int _healthRating = 3;
  bool _isLoading = false;
  bool _isSaving = false;

  final StepRecommenderService _service = StepRecommenderService();
  
  // 🎨 Pastel Renk Paleti
  final Color _pastelPurple = const Color(0xFFD1C4E9); // Açık Lavanta
  final Color _deepPastelPurple = const Color(0xFF9575CD); // Biraz daha koyu pastel

  @override
  void initState() {
    super.initState();
    _service.init();
  }

  Future<void> _calculateAndSave() async {
    setState(() => _isLoading = true);

    try {
      int age = widget.currentUserData['age'] ?? 25;
      double weight = (widget.currentUserData['weight'] as num? ?? 70).toDouble();
      double height = (widget.currentUserData['height'] as num? ?? 175).toDouble();
      String gender = widget.currentUserData['gender'] ?? 'male';

      int recommendedSteps = await _service.predictDailySteps(
        age: age,
        gender: gender,
        weightKg: weight,
        heightCm: height,
        sedentaryHours: _sedentaryHours,
        doSport: _doSport,
        healthRating: _healthRating,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showResultDialog(recommendedSteps);

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hesaplama Hatası: $e')),
        );
      }
    }
  }

  void _showResultDialog(int steps) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.auto_awesome, color: _deepPastelPurple),
                  const SizedBox(width: 10),
                  const Text("Yapay Zeka Önerisi"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Senin yaşam tarzına göre hesaplanan ideal günlük hedefin:"),
                  const SizedBox(height: 20),
                  Text(
                    "$steps Adım",
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.w900, 
                      color: _deepPastelPurple
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepPastelPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : () async {
                    setDialogState(() => _isSaving = true);
                    
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      
                      // 1. Veritabanı İşlemi (Sadece Gerçek Kullanıcı İse)
                      if (user != null && !user.isAnonymous) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'dailyStepGoal': steps});
                      } else {
                        // Misafir ise veritabanını atla, sadece UI güncelle
                        await Future.delayed(const Duration(milliseconds: 500)); // Küçük bir bekleme efekti
                      }

                      // 2. Ana Ekranı Güncelle
                      widget.onTargetUpdated(steps);

                      // 3. Pencereleri Kapat
                      if (context.mounted) {
                        Navigator.of(ctx).pop(); // Dialogu kapat
                        Navigator.of(this.context).pop(); // BottomSheet'i kapat
                        
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(user != null && !user.isAnonymous 
                                ? "Hedef Kaydedildi! 🎯" 
                                : "Misafir Modu: Hedef ekranınızda güncellendi! 👻"),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => _isSaving = false);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text("Hata: $e")),
                      );
                    }
                  },
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Hedefi Uygula"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("AI Hedef Sihirbazı 🪄", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          const Align(alignment: Alignment.centerLeft, child: Text("Günde ortalama kaç saat oturuyorsun?", style: TextStyle(fontWeight: FontWeight.w500))),
          Slider(
            value: _sedentaryHours,
            min: 0, max: 16, divisions: 16,
            label: "${_sedentaryHours.toInt()} Saat",
            activeColor: _deepPastelPurple,
            inactiveColor: _pastelPurple.withOpacity(0.3),
            onChanged: (val) => setState(() => _sedentaryHours = val),
          ),
          Text("${_sedentaryHours.toInt()} Saat", style: TextStyle(fontWeight: FontWeight.bold, color: _deepPastelPurple)),
          
          const SizedBox(height: 10),
          
          SwitchListTile(
            title: const Text("Düzenli spor yapıyor musun?", style: TextStyle(fontWeight: FontWeight.w500)),
            value: _doSport,
            activeColor: _deepPastelPurple,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _doSport = val),
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepPastelPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _isLoading ? null : _calculateAndSave,
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Hesapla ✨", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}