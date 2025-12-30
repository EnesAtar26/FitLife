class Activity {
  final int? id;
  final int userId;
  final String date;
  final String type;
  final int durationMinutes;
  final double distanceKm;
  final int calories;
  final int steps;
  final String? createdAt;

  Activity({
    this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.durationMinutes,
    required this.distanceKm,
    required this.calories,
    required this.steps,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'type': type,
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'calories': calories,
      'steps': steps,
      'created_at': createdAt,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      userId: map['user_id'],
      date: map['date'],
      type: map['type'],
      durationMinutes: map['duration_minutes'],
      distanceKm: map['distance_km'],
      calories: map['calories'],
      steps: map['steps'],
      createdAt: map['created_at'],
    );
  }
}
