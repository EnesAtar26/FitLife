import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Günaydın, Ayşe ☀️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                      const SizedBox(height: 4),
                      Text('8 Kasım 2025, Cumartesi', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  CircleAvatar(backgroundColor: Colors.green[50], child: Icon(Icons.person, color: color)),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8))],
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: 0.62,
                            strokeWidth: 12,
                            color: color,
                            backgroundColor: color.withOpacity(0.12),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('7,236', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.grey[900])),
                        const SizedBox(height: 6),
                        Text('Adım', style: TextStyle(color: Colors.grey[600])),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _StatCard(title: 'Kalori', value: '1,840 kcal', icon: Icons.local_fire_department, color: Colors.orange),
                    _StatCard(
                      title: 'Su',
                      value: '6/8 bardak',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, '/water'); // 👈 yönlendirme
                      },
                    ),
                    _StatCard(title: 'Uyku', value: '7 sa 30 dk', icon: Icons.bedtime, color: Colors.purple),
                    _StatCard(title: 'Aktivite', value: '45 dk koşu', icon: Icons.directions_run, color: Colors.green),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap; // 👈 yeni eklendi

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // 👈 tıklama efekti için
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(
                        fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(value,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}