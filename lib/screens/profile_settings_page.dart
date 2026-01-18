import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_6/services/session_manager.dart';

class ProfileSettingsPage extends StatefulWidget {
  final bool isOffline;
  const ProfileSettingsPage({super.key, this.isOffline = false});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // YENİ: Offline mod için yaş kontrolcüsü
  final TextEditingController ageController = TextEditingController();

  DateTime? birthDate;
  String gender = 'Kadın';
  String selectedCountry = 'Türkiye';
  String selectedCity = 'İstanbul';
  bool _isLoading = false;

  final List<String> countries = ['Türkiye', 'Almanya', 'ABD'];
  final Map<String, List<String>> cities = {
    'Türkiye': ['İstanbul', 'Ankara', 'İzmir'],
    'Almanya': ['Berlin', 'Hamburg'],
    'ABD': ['New York', 'Los Angeles'],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- 1. VERİLERİ ÇEKME ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isOffline) {
        // OFFLINE VERİ ÇEK
        final user = await SessionManager.getOfflineUser();
        if (user != null) {
          nameController.text = user.firstName;
          surnameController.text = user.lastName;
          emailController.text = "offline@user.com";
          gender = user.gender ?? 'Kadın';
          
          // YENİ: Offline ise yaşı direkt kutuya yaz
          if (user.age != null) {
            ageController.text = user.age.toString();
          }
        }
      } else {
        // ONLINE VERİ ÇEK (Firebase)
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          emailController.text = user.email ?? '';
          
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            nameController.text = data['Name'] ?? '';
            surnameController.text = data['Surname'] ?? '';
            gender = data['Gender'] ?? 'Kadın';
            if (data.containsKey('Country')) selectedCountry = data['Country'];
            if (data.containsKey('City')) selectedCity = data['City'];
            
            // Online ise doğum tarihini çek
            if (data.containsKey('BirthDate')) {
              birthDate = DateTime.tryParse(data['BirthDate']);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. VERİLERİ KAYDETME ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final fName = nameController.text.trim();
      final lName = surnameController.text.trim();
      
      // YAŞ HESAPLAMA MANTIĞI
      int? finalAge;
      
      if (widget.isOffline) {
        // Offline: Yaşı direkt kutudan al
        if (ageController.text.isNotEmpty) {
          finalAge = int.tryParse(ageController.text);
        }
      } else {
        // Online: Doğum tarihinden hesapla
        if (birthDate != null) {
          finalAge = DateTime.now().year - birthDate!.year;
        }
      }

      if (widget.isOffline) {
        // --- OFFLINE KAYIT ---
        final user = await SessionManager.getOfflineUser();
        if (user != null) {
          final updated = user.copyWith(
            firstName: fName,
            lastName: lName,
            gender: gender,
            age: finalAge ?? user.age, // Kutudan gelen yaş veya eski yaş
          );
          await SessionManager.saveOfflineUser(updated);
        }
      } else {
        // --- ONLINE KAYIT (Firebase) ---
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'Name': fName,
            'Surname': lName,
            'Gender': gender,
            'Country': selectedCountry,
            'City': selectedCity,
            if (finalAge != null) 'Age': finalAge,
            if (birthDate != null) 'BirthDate': birthDate!.toIso8601String(),
          });

          // Şifre Güncelleme
          if (passwordController.text.isNotEmpty) {
            if (passwordController.text.length < 6) throw "Şifre en az 6 karakter olmalı";
            await user.updatePassword(passwordController.text);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre güncellendi')));
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgileri', style: TextStyle(fontSize: 18)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// İSİM
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'İsim', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'İsim boş olamaz' : null,
              ),
              const SizedBox(height: 12),

              /// SOYİSİM
              TextFormField(
                controller: surnameController,
                decoration: const InputDecoration(labelText: 'Soyisim', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Soyisim boş olamaz' : null,
              ),
              const SizedBox(height: 12),

              // --- DEĞİŞİKLİK BURADA: OFFLINE İSE YAŞ, ONLINE İSE TARİH ---
              if (widget.isOffline)
                // OFFLINE: Yaş Girişi (Manuel)
                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Yaş',
                    border: OutlineInputBorder(),
                    hintText: 'Örn: 25'
                  ),
                )
              else
                // ONLINE: Doğum Tarihi Seçici
                InkWell(
                  onTap: pickBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Doğum Tarihi',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      birthDate == null
                          ? 'Tarih seçiniz'
                          : '${birthDate!.day}.${birthDate!.month}.${birthDate!.year}',
                    ),
                  ),
                ),
              // -------------------------------------------------------------
              
              const SizedBox(height: 12),

              /// EMAIL
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: widget.isOffline, 
                decoration: InputDecoration(
                  labelText: 'Email Adresi',
                  border: const OutlineInputBorder(),
                  filled: widget.isOffline,
                ),
              ),
              const SizedBox(height: 12),

              /// ŞİFRE (Sadece Online)
              if (!widget.isOffline)
                Column(
                  children: [
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Yeni Şifre (Boş bırakılabilir)',
                        border: OutlineInputBorder(),
                        helperText: "En az 6 karakter",
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              /// CİNSİYET
              const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kadın'),
                      value: 'Kadın', groupValue: gender, onChanged: (v) => setState(() => gender = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Erkek'),
                      value: 'Erkek', groupValue: gender, onChanged: (v) => setState(() => gender = v!),
                    ),
                  ),
                ],
              ),
              RadioListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Belirtmek istemiyorum'),
                value: 'Belirtmek istemiyorum', groupValue: gender, onChanged: (v) => setState(() => gender = v!),
              ),
              const SizedBox(height: 12),

              /// ÜLKE & ŞEHİR
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: countries.contains(selectedCountry) ? selectedCountry : countries.first,
                      decoration: const InputDecoration(labelText: 'Ülke', border: OutlineInputBorder()),
                      items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCountry = value!;
                          selectedCity = cities[selectedCountry]!.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: cities[selectedCountry]!.contains(selectedCity) ? selectedCity : cities[selectedCountry]!.first,
                      decoration: const InputDecoration(labelText: 'Şehir', border: OutlineInputBorder()),
                      items: cities[selectedCountry]!.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (value) => setState(() => selectedCity = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              /// KAYDET BUTONU
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
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kaydet', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}