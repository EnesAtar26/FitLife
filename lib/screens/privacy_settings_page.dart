import 'package:flutter/material.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool profileVisible = true;
  bool activityVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik')),
      body: ListView(
        children: [
          const Divider(),
 const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        'Sağlık verileriniz ve profil bilgileriniz gizli tutulur. Fitlife, verilerinizi yalnızca uygulama deneyimini iyileştirmek için kullanır.',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    ),
          
        ],
      ),
    );
  }
}
