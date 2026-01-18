import 'package:flutter/material.dart';
import 'package:flutter_application_6/models/user_model.dart' as local_user;
import 'package:flutter_application_6/services/session_manager.dart';
import 'home_screen.dart';

class OfflineUserCreationScreen extends StatefulWidget {
  const OfflineUserCreationScreen({super.key});

  @override
  State<OfflineUserCreationScreen> createState() => _OfflineUserCreationScreenState();
}

class _OfflineUserCreationScreenState extends State<OfflineUserCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Kontrolcüleri
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _calorieGoalCtrl = TextEditingController(text: '2000');

  bool _isLoading = false;

  Future<void> _saveOfflineUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Kullanıcı Modelini Oluştur
      local_user.User newUser = local_user.User(
        id: 1234, 
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: "offline@fitlife.local", // Zorunlu alan için sahte veri
        passwordHash: "", // Zorunlu alan için boş veri
        age: int.tryParse(_ageCtrl.text) ?? 1800,
        weightKg: int.tryParse(_weightCtrl.text) ?? 7000,
        heightCm: int.tryParse(_heightCtrl.text) ?? 17000,
        dailyCalorieGoal: int.tryParse(_calorieGoalCtrl.text) ?? 200000,
        gender: "Belirtilmedi", // İsterseniz Dropdown ekleyebilirsiniz
        dailyWaterGoal: 8,
        dailyStepGoal: 10000,
        sleepGoalMinutes: 450, // 7.5 saat
        createdAt: DateTime.now().toIso8601String(),
      );

      // 2. SQLite Veritabanına Kaydet
      await SessionManager.saveOfflineUser(newUser);

      // 3. Ana Ekrana Git (Geçmişi temizleyerek)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(isOffline: true),
          ),
          (route) => false, // Geri tuşuyla login'e dönülmesin
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profilini Oluştur")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 20),
              const Text(
                "Çevrimdışı kullanım için bilgilerinizi girin.\nBu bilgiler sadece telefonunuzda saklanır.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Ad Soyad
              Row(
                children: [
                  Expanded(child: _buildTextField(_firstNameCtrl, "Ad", TextInputType.name)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_lastNameCtrl, "Soyad", TextInputType.name)),
                ],
              ),
              const SizedBox(height: 12),

              // Yaş - Kilo - Boy
              Row(
                children: [
                  Expanded(child: _buildTextField(_ageCtrl, "Yaş", TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_weightCtrl, "Kilo (kg)", TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_heightCtrl, "Boy (cm)", TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),

              // Hedef Kalori
              _buildTextField(_calorieGoalCtrl, "Günlük Hedef Kalori (kcal)", TextInputType.number),
              
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveOfflineUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Kaydet ve Başla", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (value) => value == null || value.isEmpty ? '$label giriniz' : null,
    );
  }
}