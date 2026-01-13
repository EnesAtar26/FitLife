import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  bool waterReminder = true;
  bool activityReminder = false;
  bool sleepReminder = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Su İçme Hatırlatıcısı'),
            value: waterReminder,
            onChanged: (value) {
              setState(() {
                waterReminder = value;
              });
            },
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Aktivite Hatırlatıcısı'),
            value: activityReminder,
            onChanged: (value) {
              setState(() {
                activityReminder = value;
              });
            },
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Uyku Hatırlatıcısı'),
            value: sleepReminder,
            onChanged: (value) {
              setState(() {
                sleepReminder = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
