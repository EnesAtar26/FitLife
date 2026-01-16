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
            title: const Text('Profilimi Herkese Göster'),
            value: profileVisible,
            onChanged: (value) {
              setState(() {
                profileVisible = value;
              });
            },
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Aktivitelerimi Göster'),
            value: activityVisible,
            onChanged: (value) {
              setState(() {
                activityVisible = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
