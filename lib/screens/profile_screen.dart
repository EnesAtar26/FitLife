import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_6/widgets/step_recommender_form.dart'; 
import 'settings_screen.dart';
import 'update_profile_info_screen.dart';
import 'reminder_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Varsayılan Değerler
  String name = 'Ayşe Yılmaz';
  String subtitle = 'Veriler yükleniyor...';
  int steps = 7236; 
  int calories = 1840;
  int waterGlasses = 6;
  Duration sleep = const Duration(hours: 7, minutes: 30);
  
  // Varsayılan Hedef
  int dailyStepGoal = 10000;
  
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            userData = data;
            if (data['name'] != null) {
              name = "${data['name']} ${data['surname'] ?? ''}";
            }
            if (data['age'] != null) {
              subtitle = "Yaş: ${data['age']} • ${data['weight'] ?? '-'} kg";
            }
            if (data['dailyStepGoal'] != null) {
              dailyStepGoal = (data['dailyStepGoal'] as num).toInt();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Profil verisi çekilemedi: $e");
    }
  }

  void _openStepRecommender() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StepRecommenderForm(
          currentUserData: userData,
          onTargetUpdated: (newGoal) {
            setState(() {
              dailyStepGoal = newGoal;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          )
        ],
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: 18),
            _buildStepRecommenderCard(),
            const SizedBox(height: 18),
            _buildPrimaryStatsCard(),
            const SizedBox(height: 16),
            _buildSmallStatsGrid(),
            const SizedBox(height: 18),
            _buildGoalsCard(),
            const SizedBox(height: 18),
            _buildRemindersCard(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRecommenderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB39DDB), Color(0xFF9575CD)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9575CD).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openStepRecommender,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Akıllı Hedef Önerisi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("Sana özel adım hedefini hesaplamak için dokun!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(radius: 40, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, size: 44, color: Colors.grey)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey[600])),
        ])),
        TextButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateProfileInfoScreen())),
          icon: Icon(Icons.edit, size: 18, color: Colors.green[700]),
          label: Text('Düzenle', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  Widget _buildPrimaryStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
             Stack(alignment: Alignment.center, children: [
               SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: (steps/dailyStepGoal).clamp(0.0, 1.0), strokeWidth: 8, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600))),
               const Icon(Icons.directions_walk, color: Colors.green)
             ]),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Güncel Hedefin', style: TextStyle(fontWeight: FontWeight.bold)),
              Text("$dailyStepGoal Adım", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ]))
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            const Text('Hedefler', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Adım Hedefi'), Text('$dailyStepGoal', style: const TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Su Hedefi'), const Text('8 bardak', style: TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Uyku Hedefi'), const Text('7 sa 30 dk', style: TextStyle(fontWeight: FontWeight.bold))]),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatsGrid() {
    return Row(
      children: [
        Expanded(child: _miniCard('Aktivite', '45 dk', '45 dk koşu')),
        const SizedBox(width: 12),
        Expanded(child: _miniCard('Uyku Takibi', '${sleep.inHours}h ${sleep.inMinutes % 60}m', 'Hedef: 7h 30m')),
      ],
    );
  }

  Widget _miniCard(String title, String big, String small) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(big, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(small, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hatırlatıcılar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.notifications_none), const SizedBox(width: 8), const Expanded(child: Text('Su içme hatırlatıcısı\nHer 2 saatte bir')), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderEditScreen(title: 'Su Hatırlatıcısı'))), child: const Text('Düzenle'))]),
            const Divider(),
            Row(children: [const Icon(Icons.bedtime_outlined), const SizedBox(width: 8), const Expanded(child: Text('Uyku hatırlatıcısı\nHedef uyku saati')), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderEditScreen(title: 'Uyku Hatırlatıcısı'))), child: const Text('Güncelle'))]),
          ],
        ),
      ),
    );
  }
}