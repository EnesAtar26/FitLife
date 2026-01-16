import 'package:flutter/material.dart';

class ReminderEditScreen extends StatefulWidget {
  final String title;

  const ReminderEditScreen({super.key, required this.title});

  @override
  State<ReminderEditScreen> createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen> {
  bool isEnabled = true;

  // 💧 Su
  int waterInterval = 2;
  TimeOfDay waterStartTime = const TimeOfDay(hour: 9, minute: 0);

  // 😴 Uyku
  TimeOfDay sleepTime = const TimeOfDay(hour: 23, minute: 0);
  int sleepHours = 7;
  int sleepMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final isWater = widget.title.contains('Su');
    final isSleep = widget.title.contains('Uyku');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// AKTİF / PASİF
            SwitchListTile(
              title: const Text('Hatırlatıcı Aktif'),
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  isEnabled = value;
                });
              },
            ),

            const Divider(),

            /// 💧 SU HATIRLATICISI
            if (isWater) ...[
              const Text('İlk Hatırlatma Saati',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              _timePickerTile(
                icon: Icons.water_drop,
                time: waterStartTime,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: waterStartTime,
                  );
                  if (picked != null) {
                    setState(() => waterStartTime = picked);
                  }
                },
              ),

              const SizedBox(height: 16),

              const Text('Hatırlatma Aralığı',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              DropdownButtonFormField<int>(
                initialValue: waterInterval,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Her 1 saatte')),
                  DropdownMenuItem(value: 2, child: Text('Her 2 saatte')),
                  DropdownMenuItem(value: 3, child: Text('Her 3 saatte')),
                  DropdownMenuItem(value: 4, child: Text('Her 4 saatte')),
                ],
                onChanged: (value) {
                  setState(() => waterInterval = value!);
                },
              ),
            ],

            /// 😴 UYKU HATIRLATICISI
            if (isSleep) ...[
              const Text('Uykuya Gitme Saati',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              _timePickerTile(
                icon: Icons.bedtime,
                time: sleepTime,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: sleepTime,
                  );
                  if (picked != null) {
                    setState(() => sleepTime = picked);
                  }
                },
              ),

              const SizedBox(height: 16),

              const Text('Hedef Uyku Süresi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: sleepHours,
                      decoration:
                          const InputDecoration(labelText: 'Saat'),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 4,
                          child: Text('${i + 4} saat'),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => sleepHours = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: sleepMinutes,
                      decoration:
                          const InputDecoration(labelText: 'Dakika'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('0 dk')),
                        DropdownMenuItem(value: 15, child: Text('15 dk')),
                        DropdownMenuItem(value: 30, child: Text('30 dk')),
                        DropdownMenuItem(value: 45, child: Text('45 dk')),
                      ],
                      onChanged: (value) {
                        setState(() => sleepMinutes = value!);
                      },
                    ),
                  ),
                ],
              ),
            ],

            const Spacer(),

            /// KAYDET
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧩 ORTAK TIME TILE
  Widget _timePickerTile({
    required IconData icon,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.grey),
      ),
      leading: Icon(icon),
      title: Text(
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      ),
      trailing: const Icon(Icons.edit),
      onTap: onTap,
    );
  }
}
