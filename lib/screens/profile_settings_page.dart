import 'package:flutter/material.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController(text: 'Ayşe');
  final TextEditingController surnameController =
      TextEditingController(text: 'Yılmaz');
  final TextEditingController emailController =
      TextEditingController(text: 'ayseyilmaz@email.com');
  final TextEditingController passwordController =
      TextEditingController();

  DateTime? birthDate;
  String gender = 'Kadın';
  String selectedCountry = 'Türkiye';
  String selectedCity = 'İstanbul';

  final List<String> countries = ['Türkiye', 'Almanya', 'ABD'];
  final Map<String, List<String>> cities = {
    'Türkiye': ['İstanbul', 'Ankara', 'İzmir'],
    'Almanya': ['Berlin', 'Hamburg'],
    'ABD': ['New York', 'Los Angeles'],
  };

  Future<void> pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
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
      appBar: AppBar(title: const Text('Profil Bilgileri (yapım aşamasında)',style: TextStyle(fontSize: 16))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// İSİM
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'İsim',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              /// SOYİSİM
              TextFormField(
                controller: surnameController,
                decoration: const InputDecoration(
                  labelText: 'Soyisim',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              /// DOĞUM TARİHİ
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
              const SizedBox(height: 12),

              /// EMAIL
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Adresi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              /// ŞİFRE
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              /// CİNSİYET
              const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile(
                title: const Text('Kadın'),
                value: 'Kadın',
                groupValue: gender,
                onChanged: (value) {
                  setState(() {
                    gender = value!;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Erkek'),
                value: 'Erkek',
                groupValue: gender,
                onChanged: (value) {
                  setState(() {
                    gender = value!;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Belirtmek istemiyorum'),
                value: 'Belirtmek istemiyorum',
                groupValue: gender,
                onChanged: (value) {
                  setState(() {
                    gender = value!;
                  });
                },
              ),

              const SizedBox(height: 12),

              /// ÜLKE
              DropdownButtonFormField(
                initialValue: selectedCountry,
                decoration: const InputDecoration(
                  labelText: 'Ülke',
                  border: OutlineInputBorder(),
                ),
                items: countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCountry = value!;
                    selectedCity = cities[selectedCountry]!.first;
                  });
                },
              ),
              const SizedBox(height: 12),

              /// ŞEHİR
              DropdownButtonFormField(
                initialValue: selectedCity,
                decoration: const InputDecoration(
                  labelText: 'Şehir',
                  border: OutlineInputBorder(),
                ),
                items: cities[selectedCountry]!
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCity = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              /// KAYDET
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil bilgileri güncellendi'),
                      ),
                    );
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
