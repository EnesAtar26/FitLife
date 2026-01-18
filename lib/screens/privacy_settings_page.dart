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
          SwitchListTile(
            title: const Text('Çerezleri Kabul Et'),
            value: profileVisible,
            onChanged: (value) {
              setState(() {
                profileVisible = value;
              });
            },
          ),
          const Divider(),
 const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        'Verileriniz aygıtınızda şifrelenir ve yalnızca izniniz alınarak paylaşılabilir.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    ),
          
        ],
      ),
    );
  }
}
