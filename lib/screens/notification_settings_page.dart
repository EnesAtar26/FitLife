import 'package:flutter/material.dart';
import 'package:flutter_application_6/services/session_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsPage extends StatefulWidget {
  final bool isOffline;
  const NotificationSettingsPage({super.key, this.isOffline = false});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  bool? waterReminder;
  bool? activityReminder;
  bool? sleepReminder;

  bool _isLoading = false;

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
          waterReminder = user.notifyW;
          activityReminder = user.notifyA;
          sleepReminder = user.notifyS;
        }
      } else {
        // ONLINE VERİ ÇEK (Firebase)
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection("notifications").doc("general").collection("logs").doc(user.uid).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            waterReminder = data['WaterNtf'] ?? true;
            activityReminder = data['ActivityNtf'] ?? false;
            sleepReminder = data['SleepNtf'] ?? true;
          }
        }
      }
    } catch (e) {
      debugPrint("Veri yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isOffline) {
        // --- OFFLINE KAYIT ---
        final user = await SessionManager.getOfflineUser();
        if (user != null) {
          final updated = user.copyWith(
            notifyW: waterReminder,
            notifyA: activityReminder,
            notifyS: sleepReminder
          );
          await SessionManager.saveOfflineUser(updated);
        }
      } else {
        // --- ONLINE KAYIT (Firebase) ---
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection("notifications").doc("general").collection("logs").doc(user.uid).update({
            'WaterNtf': waterReminder,
            'ActivityNtf': activityReminder,
            'SleepNtf': sleepReminder,
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Su İçme Hatırlatıcısı'),
            value: waterReminder ?? false,
            onChanged: (value) {
              setState(() {
                waterReminder = value;
                _saveData();
              });
            },
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Aktivite Hatırlatıcısı'),
            value: activityReminder ?? false,
            onChanged: (value) {
              setState(() {
                activityReminder = value;
                _saveData();
              });
            },
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Uyku Hatırlatıcısı'),
            value: sleepReminder ?? false,
            onChanged: (value) {
              setState(() {
                sleepReminder = value;
                _saveData();
              });
            },
          ),
        ],
      ),
    );
  }
}
