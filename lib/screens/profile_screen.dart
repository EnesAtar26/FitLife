import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'update_profile_info_screen.dart';
import 'reminder_edit_screen.dart';


// Profile screen implementation approximating the provided mockup.
// Drop this file into `lib/profile_screen.dart` and use ProfileScreen() in your app.

// ---------------- SETTINGS SCREEN ----------------


// ---------------- PROFILE SCREEN ----------------
class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mocked user data
  String name = 'Ayşe Yılmaz';
  String subtitle = 'Yaş: 22 • Kadın';
  int steps = 7236;
  int calories = 1840;
  int waterGlasses = 6; // of 8
  Duration sleep = const Duration(hours: 7, minutes: 30);

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
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  },
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

  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: null, // replace with NetworkImage(...) if available
          child: const Icon(Icons.person, size: 44, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                 InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UpdateProfileInfoScreen(),
      ),
    );
  },
  borderRadius: BorderRadius.circular(8),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.edit, size: 18, color: Colors.green[700]),
        const SizedBox(width: 6),
        Text(
          'Bilgileri Güncelle',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
),

                ],
              )
            ],
          ),
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
            // Circular Steps Indicator (simple)
            _buildStepsCircle(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Günaydın, $name', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _tinyStat('Kalori', '$calories kcal'),
                      _tinyStat('Su', '$waterGlasses/8 bardak'),
                      _tinyStat('Uyku', '${sleep.inHours} sa ${sleep.inMinutes % 60} dk'),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCircle() {
    final percent = (steps / 10000).clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(steps.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            const Text('Adım', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _tinyStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

 
  Widget _buildSmallStatsGrid() {
    return Row(
      children: [
        Expanded(child: _miniCard('Aktivite', '45 dk', '45 dk koşu')),
        const SizedBox(width: 12),
        Expanded(child: _miniCard('Su Takibi', '$waterGlasses/8', 'Günlük')),        
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

  Widget _buildGoalsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hedefler', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _goalRow('Adım Hedefi', '10.000'),
            const SizedBox(height: 8),
            _goalRow('Su Hedefi', '8 bardak'),
            const SizedBox(height: 8),
            _goalRow('Uyku Hedefi', '7 sa 30 dk'),
          ],
        ),
      ),
    );
  }

  Widget _goalRow(String name, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

Widget _buildRemindersCard() {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hatırlatıcılar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          //  SU HATIRLATICISI
          Row(
            children: [
              const Icon(Icons.notifications_none),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Su içme hatırlatıcısı\nHer 2 saatte bir',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReminderEditScreen(
                        title: 'Su Hatırlatıcısı',
                      ),
                    ),
                  );
                },
                child: const Text('Düzenle'),
              ),
            ],
          ),

          const Divider(),

          //  UYKU HATIRLATICISI
          Row(
            children: [
              const Icon(Icons.bedtime_outlined),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Uyku hatırlatıcısı\nHedef uyku saati',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReminderEditScreen(
                        title: 'Uyku Hatırlatıcısı',
                      ),
                    ),
                  );
                },
                child: const Text('Güncelle'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

}
