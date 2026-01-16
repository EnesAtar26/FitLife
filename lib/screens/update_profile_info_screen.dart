import 'package:flutter/material.dart';

class UpdateProfileInfoScreen extends StatefulWidget {
  const UpdateProfileInfoScreen({super.key});

  @override
  State<UpdateProfileInfoScreen> createState() =>
      _UpdateProfileInfoScreenState();
}

class _UpdateProfileInfoScreenState extends State<UpdateProfileInfoScreen> {
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  bool smokes = false;
  bool drinksAlcohol = false;

  String bodyType = 'Az Hareketli';
  double bmi = 0;

  void calculateBMI() {
    final height = double.tryParse(heightController.text);
    final weight = double.tryParse(weightController.text);

    if (height != null && weight != null && height > 0) {
      final heightMeter = height / 100;
      setState(() {
        bmi = weight / (heightMeter * heightMeter);
      });
    }
  }

  String getBmiText() {
    if (bmi == 0) return '-';
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgilerini Güncelle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _textField(ageController, 'Yaş', TextInputType.number),
            _textField(heightController, 'Boy (cm)', TextInputType.number),
            _textField(weightController, 'Kilo (kg)', TextInputType.number),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: calculateBMI,
              child: const Text('VKİ Hesapla'),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                title: const Text('Vücut Kitle İndeksi'),
                subtitle: Text(
                  bmi == 0
                      ? '-'
                      : '${bmi.toStringAsFixed(1)} (${getBmiText()})',
                ),
              ),
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Sigara Kullanımı'),
              value: smokes,
              onChanged: (value) {
                setState(() {
                  smokes = value;
                });
              },
            ),

            SwitchListTile(
              title: const Text('Alkol Kullanımı'),
              value: drinksAlcohol,
              onChanged: (value) {
                setState(() {
                  drinksAlcohol = value;
                });
              },
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              initialValue: bodyType,
              decoration: const InputDecoration(
                labelText: 'Vücut Tipi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Az Hareketli',
                  child: Text('Az Hareketli'),
                ),
                DropdownMenuItem(
                  value: 'Orta Aktif',
                  child: Text('Orta Aktif'),
                ),
                DropdownMenuItem(
                  value: 'Sportif',
                  child: Text('Sportif'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  bodyType = value!;
                });
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'age': ageController.text,
                    'height': heightController.text,
                    'weight': weightController.text,
                    'bmi': bmi,
                    'smokes': smokes,
                    'drinksAlcohol': drinksAlcohol,
                    'bodyType': bodyType,
                  });
                },
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    TextInputType type,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
