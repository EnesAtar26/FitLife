import 'package:flutter/material.dart';
import '../services/user_data_service.dart';
import 'home_screen.dart';

class OfflineSetupScreen extends StatefulWidget {
  static const routeName = '/offline-setup';
  const OfflineSetupScreen({super.key});

  @override
  State<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
}

class _OfflineSetupScreenState extends State<OfflineSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Kadın';

  final UserDataService _dataService = UserDataService();

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      // Verileri servise gönderip Local'e kaydet
      await _dataService.saveUserProfile({
        'first_name': _nameController.text.trim(),
        'weight_kg': _weightController.text.trim(),
        'height_cm': _heightController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _gender,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hızlı Kurulum")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Seni daha iyi tanımamız için\nlütfen bilgilerini gir.",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Adın", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Ad gerekli" : null,
              ),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Yaş", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Gerekli" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Kilo (kg)", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Gerekli" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Boy (cm)", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Gerekli" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              const Text("Cinsiyet", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Kadın"),
                      value: "Kadın",
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v.toString()),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Erkek"),
                      value: "Erkek",
                      groupValue: _gender,
                      onChanged: (v) => setState(() => _gender = v.toString()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("KAYDET VE BAŞLA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}