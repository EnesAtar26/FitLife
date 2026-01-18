import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_6/services/session_manager.dart';

class UpdateProfileInfoScreen extends StatefulWidget {
  final bool isOffline;
  const UpdateProfileInfoScreen({super.key, this.isOffline = false});

  @override
  State<UpdateProfileInfoScreen> createState() => _UpdateProfileInfoScreenState();
}

class _UpdateProfileInfoScreenState extends State<UpdateProfileInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Kişisel
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController surnameCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController();
  String gender = 'Kadın';

  // Vücut
  final TextEditingController heightCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();

  // Hedefler
  final TextEditingController stepGoalCtrl = TextEditingController();
  final TextEditingController waterGoalCtrl = TextEditingController();
  final TextEditingController sleepGoalCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isOffline) {
      final user = await SessionManager.getOfflineUser();
      if (user != null) {
        setState(() {
          nameCtrl.text = user.firstName;
          surnameCtrl.text = user.lastName;
          ageCtrl.text = user.age?.toString() ?? '';
          gender = user.gender ?? 'Kadın';
          
          heightCtrl.text = user.heightCm?.toString() ?? '';
          weightCtrl.text = user.weightKg?.toString() ?? '';
          
          stepGoalCtrl.text = user.dailyStepGoal?.toString() ?? '10000';
          waterGoalCtrl.text = user.dailyWaterGoal?.toString() ?? '8';
          int hours = (user.sleepGoalMinutes ?? 480) ~/ 60;
          sleepGoalCtrl.text = hours.toString();
        });
      }
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            nameCtrl.text = data['Name'] ?? '';
            surnameCtrl.text = data['Surname'] ?? '';
            ageCtrl.text = data['Age']?.toString() ?? '';
            gender = data['Gender'] ?? 'Kadın';
            
            heightCtrl.text = data['heightCm']?.toString() ?? '';
            weightCtrl.text = data['weightKg']?.toString() ?? '';
            
            stepGoalCtrl.text = data['dailyStepGoal']?.toString() ?? '10000';
            waterGoalCtrl.text = data['dailyWaterGoal']?.toString() ?? '8';
            int hours = (data['sleepGoalMinutes'] ?? 480) ~/ 60;
            sleepGoalCtrl.text = hours.toString();
          });
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final fName = nameCtrl.text.trim();
      final lName = surnameCtrl.text.trim();
      final age = int.tryParse(ageCtrl.text);
      final height = int.tryParse(heightCtrl.text);
      final weight = int.tryParse(weightCtrl.text);
      
      final sGoal = int.tryParse(stepGoalCtrl.text);
      final wGoal = int.tryParse(waterGoalCtrl.text);
      final slGoalHours = int.tryParse(sleepGoalCtrl.text);
      final slGoalMin = (slGoalHours != null) ? slGoalHours * 60 : 480;

      if (widget.isOffline) {
        final user = await SessionManager.getOfflineUser();
        if (user != null) {
          final updated = user.copyWith(
            firstName: fName, lastName: lName, age: age, gender: gender,
            heightCm: height, weightKg: weight,
            dailyStepGoal: sGoal, dailyWaterGoal: wGoal, sleepGoalMinutes: slGoalMin,
          );
          await SessionManager.saveOfflineUser(updated);
        }
      } else {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'Name': fName, 'Surname': lName, 'Age': age, 'Gender': gender,
            'heightCm': height, 'weightKg': weight,
            'dailyStepGoal': sGoal, 'dailyWaterGoal': wGoal, 'sleepGoalMinutes': slGoalMin,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaydedildi')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header('Kişisel Bilgiler'),
              _input(nameCtrl, 'İsim'),
              const SizedBox(height: 12),
              _input(surnameCtrl, 'Soyisim'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _input(ageCtrl, 'Yaş', isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _dropdown()),
                ],
              ),
              const SizedBox(height: 24),
              
              _header('Vücut Bilgileri'),
              Row(
                children: [
                  Expanded(child: _input(heightCtrl, 'Boy (cm)', isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _input(weightCtrl, 'Kilo (kg)', isNum: true)),
                ],
              ),
              const SizedBox(height: 24),

              _header('Günlük Hedefler'),
              _input(stepGoalCtrl, 'Adım Hedefi', isNum: true),
              const SizedBox(height: 12),
              _input(waterGoalCtrl, 'Su Hedefi (Bardak)', isNum: true),
              const SizedBox(height: 12),
              _input(sleepGoalCtrl, 'Uyku Hedefi (Saat)', isNum: true),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Kaydet', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _input(TextEditingController ctrl, String lbl, {bool isNum = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: lbl,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dropdown() {
    return DropdownButtonFormField<String>(
      initialValue: gender,
      decoration: InputDecoration(
        labelText: 'Cinsiyet',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: ['Kadın', 'Erkek', 'Belirtilmedi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => setState(() => gender = v!),
    );
  }
}